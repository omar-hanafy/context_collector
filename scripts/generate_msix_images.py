#!/usr/bin/env python3
"""Generate Windows tile/logo PNG assets for MSIX packaging."""
from __future__ import annotations

import math
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "icons" / "ContextCollector.png"
OUT = ROOT / "windows" / "runner" / "resources" / "Images"
PARTNER_CENTER_DIR = ROOT / "icons" / "generated"

if not SRC.exists():
    raise SystemExit(f"Source image not found: {SRC}")

OUT.mkdir(parents=True, exist_ok=True)
PARTNER_CENTER_DIR.mkdir(parents=True, exist_ok=True)

# Tile/logo definitions (width, height)
TILES = {
    "Square44x44Logo": (44, 44),
    "Square71x71Logo": (71, 71),
    "Square150x150Logo": (150, 150),
    "Wide310x150Logo": (310, 150),
    "Square310x310Logo": (310, 310),
    "StoreLogo": (50, 50),
}

SCALES = [1, 2, 4]  # 100%, 200%, 400%


def run_magick(dest: Path, width: int, height: int) -> None:
    """Resize SRC to width/height with high-quality settings."""
    resize_arg = f"{width}x{height}"
    cmd = [
        "magick",
        str(SRC),
        "-resize",
        resize_arg,
        "-filter",
        "Lanczos",
        "-define",
        "filter:blur=0.9",
        "-unsharp",
        "0x0.6+0.8+0.02",
        "-gravity",
        "center",
        "-background",
        "none",
        "-extent",
        resize_arg,
        str(dest),
    ]
    subprocess.run(cmd, check=True)


for name, (base_w, base_h) in TILES.items():
    # Base (scale-100)
    dest_base = OUT / f"{name}.png"
    run_magick(dest_base, base_w, base_h)

    for scale in SCALES:
        width = base_w * scale
        height = base_h * scale
        dest = OUT / f"{name}.scale-{scale * 100}.png"
        run_magick(dest, width, height)

PARTNER_VARIANTS = {
    "app_icon_1024.png": (1024, 1024),
    "app_icon_300.png": (300, 300),
    "app_icon_150.png": (150, 150),
    "app_icon_71.png": (71, 71),
}

for filename, (w, h) in PARTNER_VARIANTS.items():
    run_magick(PARTNER_CENTER_DIR / filename, w, h)

print(f"Generated tiles in {OUT}")
print(f"Generated Partner Center variants in {PARTNER_CENTER_DIR}")
