#!/usr/bin/env python3
"""
현재 SPI/I2C UVM smoke simulation 구조를 한 장짜리 SVG로 생성한다.

이 스크립트는 Verdi나 Vivado를 대체하지 않는다.
시뮬레이션을 열기 전에 어떤 testbench, interface, DUT, UVM component가
연결되는지 빠르게 확인하기 위한 프로젝트 구조도 생성기다.
"""

from pathlib import Path
from typing import Tuple
from xml.sax.saxutils import escape


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "docs" / "diagrams"
OUT_FILE = OUT_DIR / "sim_structure.svg"
OUT_HTML = OUT_DIR / "sim_structure.html"


BOXES = {
    "tb": (360, 30, 360, 56, "tb_SPI_I2C_UVM", "#e8f1ff"),
    "smoke_if": (390, 115, 300, 56, "serial_smoke_if", "#fff5d8"),
    "uvm_cfg": (760, 115, 260, 56, "uvm_config_db", "#f5f0ff"),
    "spi": (70, 230, 310, 70, "u_spi : SPI DUT", "#e9fff1"),
    "i2c": (70, 360, 310, 70, "u_i2c : I2C DUT", "#e9fff1"),
    "test": (760, 230, 260, 56, "serial_smoke_test", "#f5f0ff"),
    "env": (760, 315, 260, 56, "serial_env", "#f5f0ff"),
    "seq": (600, 415, 190, 56, "sequencer / sequence", "#f5f0ff"),
    "drv": (820, 415, 170, 56, "driver", "#f5f0ff"),
    "mon": (1030, 415, 170, 56, "monitor", "#f5f0ff"),
    "scb": (730, 535, 170, 56, "scoreboard", "#ffecec"),
    "cov": (930, 535, 170, 56, "coverage", "#ffecec"),
    "col": (1130, 535, 170, 56, "collector", "#ffecec"),
    "spi_tb": (70, 535, 260, 56, "tb_SPI directed TB", "#eef7ff"),
    "i2c_tb": (370, 535, 260, 56, "tb_I2C directed TB", "#eef7ff"),
}

EDGES = [
    ("tb", "smoke_if", "instantiates"),
    ("tb", "spi", "instantiates"),
    ("tb", "i2c", "instantiates"),
    ("tb", "uvm_cfg", "virtual interface set"),
    ("uvm_cfg", "test", "vif 전달"),
    ("test", "env", "build"),
    ("env", "seq", "agent"),
    ("seq", "drv", "transaction"),
    ("drv", "smoke_if", "pin-level drive"),
    ("smoke_if", "spi", "SPI signals"),
    ("smoke_if", "i2c", "I2C signals"),
    ("smoke_if", "mon", "observe"),
    ("mon", "scb", "analysis_port"),
    ("mon", "cov", "analysis_port"),
    ("mon", "col", "analysis_port"),
]


def center(name: str) -> Tuple[int, int]:
    x, y, w, h, _, _ = BOXES[name]
    return x + w // 2, y + h // 2


def draw_box(name: str) -> str:
    x, y, w, h, label, color = BOXES[name]
    return "\n".join(
        [
            f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="8" fill="{color}" stroke="#344054" stroke-width="1.4"/>',
            f'<text x="{x + w / 2}" y="{y + h / 2 + 5}" text-anchor="middle" font-size="16" font-family="Menlo, Consolas, monospace" fill="#101828">{escape(label)}</text>',
        ]
    )


def draw_edge(src: str, dst: str, label: str) -> str:
    sx, sy = center(src)
    dx, dy = center(dst)
    mx = (sx + dx) // 2
    my = (sy + dy) // 2
    return "\n".join(
        [
            f'<line x1="{sx}" y1="{sy}" x2="{dx}" y2="{dy}" stroke="#667085" stroke-width="1.2" marker-end="url(#arrow)"/>',
            f'<text x="{mx}" y="{my - 6}" text-anchor="middle" font-size="11" font-family="Menlo, Consolas, monospace" fill="#475467">{escape(label)}</text>',
        ]
    )


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    svg = [
        '<svg xmlns="http://www.w3.org/2000/svg" width="1360" height="650" viewBox="0 0 1360 650">',
        "<defs>",
        '<marker id="arrow" markerWidth="10" markerHeight="10" refX="9" refY="3" orient="auto" markerUnits="strokeWidth">',
        '<path d="M0,0 L0,6 L9,3 z" fill="#667085"/>',
        "</marker>",
        "</defs>",
        '<rect width="1360" height="650" fill="#ffffff"/>',
        '<text x="30" y="32" font-size="22" font-family="Menlo, Consolas, monospace" font-weight="700" fill="#101828">SPI/I2C Simulation Structure</text>',
        '<text x="30" y="58" font-size="13" font-family="Menlo, Consolas, monospace" fill="#667085">VCS 실행 전후에 TB, DUT, UVM component 연결을 빠르게 확인하는 프로젝트 구조도</text>',
    ]

    svg.extend(draw_edge(src, dst, label) for src, dst, label in EDGES)
    svg.extend(draw_box(name) for name in BOXES)

    svg.extend(
        [
            '<text x="70" y="505" font-size="15" font-family="Menlo, Consolas, monospace" font-weight="700" fill="#101828">개별 directed TB</text>',
            '<text x="760" y="505" font-size="15" font-family="Menlo, Consolas, monospace" font-weight="700" fill="#101828">UVM 결과 수집 경로</text>',
            "</svg>",
        ]
    )

    svg_text = "\n".join(svg) + "\n"
    html_text = "\n".join(
        [
            "<!doctype html>",
            '<html lang="ko">',
            "<head>",
            '<meta charset="utf-8">',
            "<title>SPI/I2C Simulation Structure</title>",
            '<meta name="viewport" content="width=device-width, initial-scale=1">',
            "<style>",
            "body { margin: 0; background: #f8fafc; }",
            "main { padding: 24px; }",
            "svg { max-width: 100%; height: auto; background: white; box-shadow: 0 8px 24px rgba(16, 24, 40, 0.08); }",
            "</style>",
            "</head>",
            "<body>",
            "<main>",
            svg_text,
            "</main>",
            "</body>",
            "</html>",
            "",
        ]
    )

    OUT_FILE.write_text(svg_text, encoding="utf-8")
    OUT_HTML.write_text(html_text, encoding="utf-8")
    print(OUT_FILE)
    print(OUT_HTML)


if __name__ == "__main__":
    main()
