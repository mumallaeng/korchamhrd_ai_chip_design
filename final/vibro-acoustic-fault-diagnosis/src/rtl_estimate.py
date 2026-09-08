from __future__ import annotations

import argparse
import json
from dataclasses import asdict, dataclass


Z7020 = {"lut": 53200, "ff": 106400, "bram36": 140, "dsp": 220}
BRAM36_BYTES = 36 * 1024 // 8


@dataclass
class Estimate:
    model: str
    parameters: int
    weight_bytes_int8: int
    macs_per_inference: int
    peak_activation_bytes_int8: int
    rtl_datapath: list[str]
    implementation_risk: str


def estimates(classes: int) -> list[Estimate]:
    mlp_params = 128 * 64 + 64 + 64 * 32 + 32 + 32 * classes + classes
    mlp_macs = 128 * 64 + 64 * 32 + 32 * classes

    cnn_params = (7 * 1 * 8 + 8) + (5 * 8 * 16 + 16) + (3 * 16 * 24 + 24) + (24 * classes + classes)
    # same padding: lengths 128 -> conv 64 -> pool 32 -> conv 32 -> pool 16 -> conv 16
    cnn_macs = 64 * 7 * 1 * 8 + 32 * 5 * 8 * 16 + 16 * 3 * 16 * 24 + 24 * classes

    ds_params = (3 * 3 * 1 * 8 + 8) + (3 * 3 * 8 + 8) + (8 * 16 + 16) + (3 * 3 * 16 + 16) + (16 * 24 + 24) + (24 * classes + classes)
    # 32x32 -> stride-2 16x16, then spatial dimensions remain 16x16.
    ds_macs = 16 * 16 * 3 * 3 * 1 * 8 + 16 * 16 * 3 * 3 * 8 + 16 * 16 * 8 * 16 + 16 * 16 * 3 * 3 * 16 + 16 * 16 * 16 * 24 + 24 * classes

    return [
        Estimate("MLP-128-64-32-C", mlp_params, 128 * 64 + 64 * 32 + 32 * classes, mlp_macs, 128,
                 ["AXI-stream input FIFO", "shared dense MAC array", "weight/bias BRAM", "ReLU/saturator", "argmax"], "low"),
        Estimate("TinySpecCNN-1D-v0", cnn_params, 7 * 1 * 8 + 5 * 8 * 16 + 3 * 16 * 24 + 24 * classes, cnn_macs, 64 * 8,
                 ["AXI-stream feature FIFO", "K-sample shift register", "shared Conv1D MAC array", "max-pool", "GAP accumulator", "dense/argmax"], "medium"),
        Estimate("DS-CNN-Tiny", ds_params, 3 * 3 * 1 * 8 + 3 * 3 * 8 + 8 * 16 + 3 * 3 * 16 + 16 * 24 + 24 * classes, ds_macs, 16 * 16 * 24,
                 ["2-D line buffer", "3x3 depthwise MAC", "1x1 pointwise MAC", "feature-map ping-pong BRAM", "GAP", "dense/argmax"], "medium-high"),
    ]


def mlp_memory(classes: int) -> dict[str, int | float]:
    weights = 128 * 64 + 64 * 32 + 32 * classes
    biases_int32 = (64 + 32 + classes) * 4
    per_channel_requant = (64 + 32 + classes) * 5  # INT32 multiplier + shift byte
    activation_ping_pong = 128 + 64
    logits_int32 = classes * 4
    logical_total = weights + biases_int32 + per_channel_requant + activation_ping_pong + logits_int32
    # Three BRAM36 blocks hold packed weights; one combined block is enough for
    # bias, scale, activation and result storage. Use six as integration budget.
    allocated_bram36 = 4
    budget_bram36 = 6
    return {
        "weights_int8_bytes": weights,
        "bias_int32_bytes": biases_int32,
        "per_channel_requant_bytes": per_channel_requant,
        "activation_buffers_bytes": activation_ping_pong,
        "logits_int32_bytes": logits_int32,
        "logical_total_bytes": logical_total,
        "minimum_packed_bram36": allocated_bram36,
        "conservative_core_budget_bram36": budget_bram36,
        "conservative_core_budget_percent": budget_bram36 / Z7020["bram36"] * 100,
        "bram36_bytes": BRAM36_BYTES,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--classes", type=int, default=4)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    rows = estimates(args.classes)
    if args.json:
        print(json.dumps({"device": Z7020, "classes": args.classes, "models": [asdict(x) for x in rows],
                          "mlp_memory": mlp_memory(args.classes)}, indent=2))
        return
    print(f"Target XC7Z020: {Z7020}")
    for row in rows:
        print(f"{row.model}: params={row.parameters:,}, INT8 weights={row.weight_bytes_int8:,} B, "
              f"MACs={row.macs_per_inference:,}, peak activation={row.peak_activation_bytes_int8:,} B, risk={row.implementation_risk}")
    print(f"MLP memory: {mlp_memory(args.classes)}")


if __name__ == "__main__":
    main()
