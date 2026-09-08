from __future__ import annotations

import numpy as np
from scipy.signal import stft


def normalize_audio(x: np.ndarray) -> np.ndarray:
    x = np.asarray(x, dtype=np.float32)
    x = x - np.mean(x)
    scale = np.sqrt(np.mean(x * x) + 1e-12)
    return x / scale


def fft128(x: np.ndarray) -> np.ndarray:
    """RTL-friendly 128 contiguous power bands averaged over 1024-point frames."""
    x = normalize_audio(x)
    frame = 1024
    count = max(1, len(x) // frame)
    x = np.pad(x[: count * frame], (0, max(0, frame - len(x))))
    frames = x.reshape(-1, frame) * np.hanning(frame).astype(np.float32)
    power = np.abs(np.fft.rfft(frames, axis=1)) ** 2
    # Drop Nyquist and average each group of four bins: 512 -> 128.
    bands = power[:, :512].reshape(-1, 128, 4).mean(axis=2)
    return np.log1p(bands).mean(axis=0).astype(np.float32)


def logmel32(x: np.ndarray, sample_rate: int = 50_000) -> np.ndarray:
    """32 time frames x 32 mel bands; coefficients can later become an RTL ROM."""
    x = normalize_audio(x)
    _, _, z = stft(x, nperseg=512, noverlap=256, nfft=512, boundary=None)
    power = np.abs(z) ** 2
    hz_to_mel = lambda hz: 2595.0 * np.log10(1.0 + hz / 700.0)
    mel_to_hz = lambda mel: 700.0 * (10.0 ** (mel / 2595.0) - 1.0)
    points = mel_to_hz(np.linspace(hz_to_mel(0), hz_to_mel(sample_rate / 2), 34))
    bins = np.floor((512 + 1) * points / sample_rate).astype(int)
    bank = np.zeros((32, power.shape[0]), dtype=np.float32)
    for band in range(32):
        left, center, right = bins[band : band + 3]
        if center > left:
            bank[band, left:center] = np.arange(center - left) / (center - left)
        if right > center:
            bank[band, center:right] = np.arange(right - center, 0, -1) / (right - center)
    mel_power = bank @ power
    if mel_power.shape[1] < 32:
        mel_power = np.pad(mel_power, ((0, 0), (0, 32 - mel_power.shape[1])), mode="edge")
    indexes = np.linspace(0, mel_power.shape[1] - 1, 32).round().astype(int)
    return np.log1p(mel_power[:, indexes].T).astype(np.float32)
