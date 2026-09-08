from __future__ import annotations

import csv
from dataclasses import dataclass
from pathlib import Path
from typing import Iterator

import numpy as np
import soundfile as sf


@dataclass(frozen=True)
class Recording:
    path: Path
    label: str
    group: str


MAFAULDA_LABELS = {
    "normal": "normal",
    "imbalance": "imbalance",
    "horizontal-misalignment": "horizontal_misalignment",
    "vertical-misalignment": "vertical_misalignment",
}


def discover_mafaulda(root: Path) -> list[Recording]:
    rows: list[Recording] = []
    for folder, label in MAFAULDA_LABELS.items():
        for path in sorted((root / folder).rglob("*.csv")):
            rows.append(Recording(path, label, str(path.relative_to(root))))
    return rows


def read_mafaulda_microphone(path: Path) -> np.ndarray:
    # Official files have no header and microphone is column eight.
    return np.loadtxt(path, delimiter=",", usecols=(7,), dtype=np.float32)


def discover_idmt(root: Path) -> list[Recording]:
    rows: list[Recording] = []
    aliases = {"good": "good", "broken": "broken", "heavyload": "heavy_load", "heavy_load": "heavy_load"}
    for path in sorted(root.rglob("*.wav")):
        lowered = "/".join(path.parts).lower().replace("-", "").replace(" ", "")
        label = next((value for key, value in aliases.items() if key in lowered), None)
        if label is not None:
            # Keep the physical motor or top-level recording subtree together when possible.
            group = path.parent.name
            rows.append(Recording(path, label, group))
    return rows


def read_idmt(path: Path) -> tuple[np.ndarray, int]:
    audio, sample_rate = sf.read(path, dtype="float32", always_2d=False)
    if audio.ndim == 2:
        audio = audio.mean(axis=1)
    return audio, sample_rate


def windows(x: np.ndarray, sample_rate: int, seconds: float = 1.0) -> Iterator[np.ndarray]:
    size = int(sample_rate * seconds)
    for start in range(0, len(x) - size + 1, size):
        yield x[start : start + size]

