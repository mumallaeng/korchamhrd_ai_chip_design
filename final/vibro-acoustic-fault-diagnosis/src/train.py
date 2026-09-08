from __future__ import annotations

import argparse
import json
import random
from pathlib import Path

import numpy as np
import torch
from sklearn.metrics import accuracy_score, confusion_matrix, f1_score, recall_score
from torch import nn
from torch.utils.data import DataLoader, TensorDataset

from .models import make_model


def seed_all(seed: int) -> None:
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)


def grouped_split(groups: np.ndarray, labels: np.ndarray, seed: int) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """Split recording groups within each class so every partition retains classes."""
    buckets: list[list[int]] = [[], [], []]
    for label in np.unique(labels):
        label_indexes = np.flatnonzero(labels == label)
        unique_groups = np.unique(groups[label_indexes])
        rng = np.random.default_rng(seed + int(label))
        rng.shuffle(unique_groups)
        n = len(unique_groups)
        train_end = max(1, int(n * 0.70))
        valid_end = min(n - 1, max(train_end + 1, int(n * 0.85))) if n >= 3 else train_end
        partitions = (unique_groups[:train_end], unique_groups[train_end:valid_end], unique_groups[valid_end:])
        for bucket, selected in zip(buckets, partitions):
            bucket.extend(label_indexes[np.isin(groups[label_indexes], selected)].tolist())
    if any(len(bucket) == 0 for bucket in buckets):
        raise ValueError("Each class needs at least three recording groups for train/validation/test")
    return tuple(np.asarray(bucket, dtype=int) for bucket in buckets)  # type: ignore[return-value]


def standardize(train: np.ndarray, *others: np.ndarray) -> tuple[tuple[np.ndarray, ...], np.ndarray, np.ndarray]:
    axes = tuple(range(train.ndim - 1)) if train.ndim > 2 else (0,)
    mean = train.mean(axis=axes, keepdims=True)
    std = train.std(axis=axes, keepdims=True) + 1e-6
    values = tuple(((x - mean) / std).astype(np.float32) for x in (train,) + others)
    return values, mean.astype(np.float32), std.astype(np.float32)


def metrics(model: nn.Module, x: np.ndarray, y: np.ndarray, classes: int) -> dict:
    model.eval()
    with torch.no_grad():
        pred = model(torch.from_numpy(x)).argmax(1).numpy()
    return {
        "accuracy": float(accuracy_score(y, pred)),
        "macro_f1": float(f1_score(y, pred, average="macro", zero_division=0)),
        "recall_per_class": recall_score(y, pred, labels=list(range(classes)), average=None, zero_division=0).tolist(),
        "confusion_matrix": confusion_matrix(y, pred, labels=list(range(classes))).tolist(),
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("dataset", type=Path, help="NPZ with x, y, group and class_names")
    parser.add_argument("--model", choices=["mlp", "cnn1d", "dscnn"], required=True)
    parser.add_argument("--epochs", type=int, default=40)
    parser.add_argument("--seed", type=int, default=7)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    seed_all(args.seed)
    data = np.load(args.dataset, allow_pickle=True)
    x, y, groups = data["x"], data["y"].astype(np.int64), data["group"]
    class_names = data["class_names"].tolist()
    train_i, valid_i, test_i = grouped_split(groups, y, args.seed)
    (train_x, valid_x, test_x), feature_mean, feature_std = standardize(x[train_i], x[valid_i], x[test_i])
    model = make_model(args.model, len(class_names))
    optimizer = torch.optim.Adam(model.parameters(), lr=1e-3)
    counts = np.bincount(y[train_i], minlength=len(class_names))
    criterion = nn.CrossEntropyLoss(weight=torch.tensor(len(train_i) / np.maximum(counts, 1), dtype=torch.float32))
    loader = DataLoader(TensorDataset(torch.from_numpy(train_x), torch.from_numpy(y[train_i])), batch_size=64, shuffle=True)
    best_state, best_f1 = None, -1.0
    for _ in range(args.epochs):
        model.train()
        for bx, by in loader:
            optimizer.zero_grad()
            loss = criterion(model(bx), by)
            loss.backward()
            optimizer.step()
        score = metrics(model, valid_x, y[valid_i], len(class_names))["macro_f1"]
        if score > best_f1:
            best_f1 = score
            best_state = {k: v.detach().clone() for k, v in model.state_dict().items()}
    assert best_state is not None
    model.load_state_dict(best_state)
    result = {
        "model": args.model, "classes": class_names, "parameters": sum(p.numel() for p in model.parameters()),
        "split_samples": {"train": len(train_i), "validation": len(valid_i), "test": len(test_i)},
        "validation": metrics(model, valid_x, y[valid_i], len(class_names)),
        "test": metrics(model, test_x, y[test_i], len(class_names)),
    }
    args.output.mkdir(parents=True, exist_ok=True)
    torch.save({
        "state_dict": model.state_dict(), "result": result,
        "feature_mean": torch.from_numpy(feature_mean), "feature_std": torch.from_numpy(feature_std),
        "split_indices": {"train": train_i, "validation": valid_i, "test": test_i},
    }, args.output / "model.pt")
    (args.output / "metrics.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
