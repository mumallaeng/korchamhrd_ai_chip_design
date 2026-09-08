# Vibro-acoustic fault diagnosis

Software golden models and RTL-feasibility artifacts for the Korcham final project.

See `HANDOFF.md` for verified local state, unfinished work, and exact continuation commands.

The first experiment matrix is:

| ID | Dataset | Feature | Model |
| --- | --- | --- | --- |
| GM-01 | MaFaulDa 4-class | 128 FFT bands | MLP 128-64-32-C |
| GM-02 | MaFaulDa 4-class | 128 FFT bands | TinySpecCNN-1D-v0 |
| GM-03 | MaFaulDa 4-class | 32x32 log spectrum | DS-CNN-Tiny |
| GM-04 | IDMT Electric Engine 3-state | 128 FFT bands | TinySpecCNN-1D-v0 |

Dataset files and generated artifacts are intentionally ignored by Git.

## Setup

```bash
/opt/homebrew/bin/python3.10 -m venv .venv
.venv/bin/pip install -r requirements.txt
```

## Static model/RTL report

```bash
.venv/bin/python -m src.rtl_estimate --classes 4
```

This report is an analytical bound, not a Vivado utilization result. Board fit is
confirmed only after the selected fixed-point RTL is synthesized and implemented.
