from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np

from .datasets import discover_idmt, discover_mafaulda, read_idmt, read_mafaulda_microphone, windows
from .features import fft128, logmel32


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dataset", choices=["mafaulda", "idmt"], required=True)
    parser.add_argument("--root", type=Path, required=True)
    parser.add_argument("--feature", choices=["fft128", "spectrum32"], required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--max-recordings-per-class", type=int)
    args = parser.parse_args()
    records = discover_mafaulda(args.root) if args.dataset == "mafaulda" else discover_idmt(args.root)
    if not records:
        raise SystemExit(f"No supported recordings found below {args.root}")
    class_names = sorted({r.label for r in records})
    class_to_id = {name: i for i, name in enumerate(class_names)}
    used = {name: 0 for name in class_names}
    xs: list[np.ndarray] = []
    ys: list[int] = []
    groups: list[str] = []
    for number, record in enumerate(records, start=1):
        if args.max_recordings_per_class is not None and used[record.label] >= args.max_recordings_per_class:
            continue
        if args.dataset == "mafaulda":
            audio, sample_rate = read_mafaulda_microphone(record.path), 50_000
        else:
            audio, sample_rate = read_idmt(record.path)
        used[record.label] += 1
        for window in windows(audio, sample_rate):
            xs.append(fft128(window) if args.feature == "fft128" else logmel32(window, sample_rate))
            ys.append(class_to_id[record.label])
            groups.append(record.group)
        if number % 25 == 0:
            print(f"processed {number}/{len(records)} recordings")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    np.savez_compressed(args.output, x=np.stack(xs), y=np.asarray(ys), group=np.asarray(groups),
                        class_names=np.asarray(class_names), recording_count=np.asarray(sum(used.values())))
    print(f"wrote {args.output}: recordings={used}, windows={len(xs)}, shape={xs[0].shape}")


if __name__ == "__main__":
    main()
