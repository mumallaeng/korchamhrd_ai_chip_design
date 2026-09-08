# Golden-model experiment handoff

Last updated: 2026-09-08 (Asia/Seoul)

## 1. Canonical locations

- Implementation workspace: this directory
- Planning documents: `/Users/mumallaeng/repo/core_repo/Vault/projects/vibro-acoustic-fault-diagnosis`
- Team status: `technical-research/06-evaluation-demo/golden-model-experiment-status.md` in the Vault project
- Target: Zybo Z7-20 / XC7Z020

Do not put Python, SystemVerilog, Vivado, Vitis, or UVM products in the Vault. The Vault holds specifications, research, decisions, and measured summaries.

## 2. Scope decision

The unverified Kaggle Car Diagnostics dataset is excluded. Do not train on it.

1. GM-01: MaFaulDa 4-class + FFT128 + MLP-128-64-32-4
2. GM-02: same features and split + TinySpecCNN-1D-v0
3. GM-03: MaFaulDa + 32x32 log-mel + DS-CNN only if GM-01/02 recall is insufficient
4. GM-04: IDMT 3-state + TinySpecCNN-1D as a secondary check
5. GM-05: ToyADMOS2 deferred until the proposed 5-class reconstruction is proven

MaFaulDa and IDMT must never be merged into one classifier or leaderboard.

## 3. Verified local state

- Working Python environment: `.venv`, Python 3.10.
- `.venv-py314-failed` is a preserved and ignored failed environment; SciPy did not support the system Python 3.14 pin.
- MLP, CNN1D, and DS-CNN forward passes and one-epoch synthetic training smoke tests passed.
- Official MaFaulDa archives are downloaded and extracted below `data/raw/mafaulda`.

| Class directory | Original CSV recordings |
| --- | ---: |
| `normal` | 49 |
| `horizontal-misalignment` | 197 |
| `vertical-misalignment` | 301 |
| `imbalance` | 333 |
| Total | 880 |

An actual CSV has no header, 8 numeric columns, 250,000 rows, and microphone data in column 8. Each recording becomes five non-overlapping one-second windows at 50kHz.

The raw directory is about 20GB including archives and extracted CSVs. Raw and processed data are Git-ignored.

IDMT's Zenodo endpoint initially returned HTTP 504 and then downloaded slowly. It was stopped to prioritize MaFaulDa. A partial file may exist at `data/raw/idmt/IDMT-ISA-ELECTRIC-ENGINE.zip`; resume with `curl --continue-at -`.

## 4. Completed FP32 execution

FFT128 preprocessing completed successfully. The NPZ is `data/processed/mafaulda-4class-fft128.npz`: shape `(4400, 128)`, float32, all finite, and five windows per recording.

GM-01 and GM-02 ran for 40 epochs at seeds 7, 17, and 27. Each seed uses a recording-safe split; both models share that split within the seed.

| Model | Test accuracy mean ± sample SD | Test macro-F1 mean ± sample SD | Mean recall: horizontal / imbalance / normal / vertical |
| --- | ---: | ---: | --- |
| GM-01 MLP | 0.9567 ± 0.0068 | 0.9267 ± 0.0217 | 0.973 / 0.949 / 0.800 / 0.981 |
| GM-02 CNN1D | 0.6358 ± 0.0142 | 0.5722 ± 0.0257 | 0.718 / 0.531 / 0.442 / 0.730 |

Seed 7 artifacts are in `artifacts/gm01-mafaulda-mlp` and `artifacts/gm02-mafaulda-cnn1d`; repeats are under `artifacts/repeats`.

Current decision: TinySpecCNN-1D-v0 is not competitive on the time-averaged FFT128 vector. MLP is now the primary RTL candidate unless time-preserving GM-03 gives a justified improvement. This is not evidence that CNNs are generally unsuitable for sound.

The completed preprocessing command was:

```bash
.venv/bin/python -m src.preprocess \
  --dataset mafaulda --root data/raw/mafaulda --feature fft128 \
  --output data/processed/mafaulda-4class-fft128.npz
```

## 5. Exact continuation commands

Run GM-03 next because MLP normal-class recall remains lower and the tested CNN discarded time information:

```bash
.venv/bin/python -m src.preprocess \
  --dataset mafaulda --root data/raw/mafaulda --feature spectrum32 \
  --output data/processed/mafaulda-4class-logmel32.npz

.venv/bin/python -m src.train data/processed/mafaulda-4class-logmel32.npz \
  --model dscnn --epochs 40 --seed 7 --output artifacts/gm03-mafaulda-dscnn
```

Static report: `.venv/bin/python -m src.rtl_estimate --classes 4`.

## 6. Evaluation contract

- Split at original CSV recording level before windowing; never random-split derived windows.
- Report accuracy, macro-F1, per-class recall, and confusion matrix.
- Compare GM-01 and GM-02 directly; they share features and split.
- Add INT8 evaluation and layer-level golden vectors before RTL.
- Confirm board fit with Vivado synthesis and implementation including AXI, FFT, ILA, and WNS/TNS.
- Benchmark PS, accelerator-only PL, and end-to-end paths with identical decoded PCM.

## 7. RTL decision state

| Model | Parameters | MAC/inference | Peak INT8 activation | Judgment |
| --- | ---: | ---: | ---: | --- |
| MLP-128-64-32-4 | 10,468 | 10,368 | 128B | easiest fallback |
| TinySpecCNN-1D-v0 | 1,996 | 42,592 | 512B | rejected in current FFT128 form |
| DS-CNN-Tiny | 972 | 204,896 | 6,144B | analytically small; higher control risk |

Start RTL estimates with PE=4, SIMD=1, INT8 weight/activation, INT32 accumulator, and one shared compute engine. These are assumptions, not frozen requirements.

Detailed MLP memory planning:

- Logical INT8 MLP storage including INT32 bias, per-channel requant parameters, activations and logits: 11,476B.
- Packed theoretical allocation: 4 BRAM36.
- Conservative MLP-core budget: 6/140 BRAM36 = 4.29%.
- PS preprocessing + PL MLP planning range: 8-12 BRAM36.
- PL FFT path plus development ILA/FIFOs: reserve up to 40/140 BRAM36 (28.6%) until Vivado reports replace this estimate.
- Keep the 100KB one-second PCM and 200KB DMA double buffer in PS DDR, not PL BRAM.

Python equivalence warning: the current FP32 preprocessing includes RMS normalization, floating-point FFT power, `log1p`, and train-set standardization. R1 must use PS preprocessing and compare the same 128 INT8 features at the PL boundary. Full PL preprocessing is R2 and requires a new fixed-point numerical contract and accuracy rerun. The MLP `Linear/ReLU/argmax` portion is directly implementable in SystemVerilog after PTQ/QAT and golden-vector export.

Pending: GM-03, PTQ/QAT, INT8 loss measurement, weight/scale/layer-vector export, fixed-point contract, SystemVerilog/UVM, AXI integration, and Vivado synthesis/implementation.

## 8. Repository hygiene

- Unrelated changes exist in both repositories; do not commit them accidentally.
- No commit was requested for this work.
- Run scoped `git status` and `git diff --check` before a future commit.
