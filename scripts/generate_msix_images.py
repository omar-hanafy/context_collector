#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
flutter_win_iconkit.py — Generate Windows/MSIX tile/logo PNGs, a multi-size ICO,
and Partner Center images for any Flutter Windows app.

Usage examples:
  # Generate everything using defaults (run from project root)
  ./flutter_win_iconkit.py --src icons/ContextCollector.png

  # From anywhere (explicit project root), and write a manifest snippet
  ./flutter_win_iconkit.py --src /path/to/logo.png --project-root /path/to/app \
      --write-manifest-snippet

  # Partner Center only (fast re-gen for store resubmission)
  ./flutter_win_iconkit.py --src icons/app.png --no-tiles --no-ico \
      --partner-sizes 1024,300,150,71

  # Use 'cover' fit with a small safe padding and a white background
  ./flutter_win_iconkit.py --src logo.svg.png --fit cover --pad 0.06 --bg "#FFFFFF"

Requirements:
  - Python 3.8+
  - ImageMagick available as `magick` or `convert` in PATH
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, List, Tuple


# ------------------------- Configuration Defaults -------------------------

# VisualElements / Tile definitions used by Windows/MSIX
DEFAULT_TILES: Dict[str, Tuple[int, int]] = {
    "Square44x44Logo":    (44, 44),    # app list / small surfaces
    "Square71x71Logo":    (71, 71),    # small Start tile
    "Square150x150Logo":  (150, 150),  # medium Start tile
    "Wide310x150Logo":    (310, 150),  # wide Start tile
    "Square310x310Logo":  (310, 310),  # large Start tile
    "StoreLogo":          (50, 50),    # used in some store/package surfaces
}

DEFAULT_SCALES = (100, 200, 400)  # Windows scale factors

DEFAULT_ICO_SIZES = (256, 128, 64, 48, 32, 24, 16)

DEFAULT_PARTNER_SIZES = (
    (1024, 1024),  # marketing + source-of-truth big square
    (300, 300),    # Partner Center 1:1 tile icon
    (150, 150),    # sometimes requested explicitly
    (71, 71),      # sometimes requested explicitly
)

# Output locations relative to --project-root
DEFAULT_IMAGES_DIR = Path("windows/runner/resources/Images")
DEFAULT_ICO_PATH = Path("windows/runner/resources/app_icon.ico")
DEFAULT_PARTNER_DIR = Path("icons/generated")


# ----------------------------- Helpers ------------------------------------

def which_magick() -> List[str]:
    """
    Find the right ImageMagick entry point. Prefer `magick` (IM 7+),
    fall back to `convert` (older IM). Returns the base command list.
    """
    for cmd in ("magick", "convert"):
        exe = shutil.which(cmd)
        if not exe:
            continue
        try:
            # Make sure it runs
            subprocess.run([exe, "-version"], stdout=subprocess.DEVNULL,
                           stderr=subprocess.DEVNULL, check=True)
            return [exe]
        except Exception:
            continue
    sys.exit("ERROR: ImageMagick not found. Install it and ensure `magick` or `convert` is on PATH.")


MAGICK = which_magick()


def ensure_dir(p: Path) -> None:
    p.mkdir(parents=True, exist_ok=True)


def parse_sizes_csv(csv: str) -> Tuple[int, ...]:
    vals = []
    for part in csv.split(","):
        part = part.strip()
        if not part:
            continue
        try:
            vals.append(int(part))
        except ValueError:
            sys.exit(f"Invalid size value: {part!r}")
    if not vals:
        sys.exit("At least one size must be provided.")
    return tuple(sorted(set(vals)))


def parse_scale_csv(csv: str) -> Tuple[int, ...]:
    scales = parse_sizes_csv(csv)
    for s in scales:
        if s not in (100, 200, 300, 350, 400, 500, 600):
            # 100/200/400 are standard; allow others but warn
            pass
    return scales


@dataclass
class RenderSettings:
    fit: str = "contain"          # 'contain' | 'cover'
    bg: str = "none"              # 'none' or color (#RRGGBB or named)
    filter_name: str = "Lanczos"
    filter_blur: float = 0.9
    unsharp: str = "0x0.6+0.8+0.02"  # radiusxsigma+amount+threshold
    trim: bool = False
    trim_fuzz: str = "0%"         # e.g., "2%"
    pad: float = 0.0              # 0.0 .. 0.4 (percentage of box, applied symmetrically)
    verbose: bool = False


def build_resize_ops(width: int, height: int, rs: RenderSettings) -> List[str]:
    """
    Build ImageMagick resize ops for a single output.
    - 'contain': letterbox/extend to fit without cropping
    - 'cover': fill and crop centered to cover the box
    """
    W, H = int(width), int(height)
    if W <= 0 or H <= 0:
        raise ValueError("width/height must be > 0")

    ops: List[str] = []

    # Optional trim of transparent borders before we scale
    if rs.trim:
        ops += ["-alpha", "on", "-fuzz", rs.trim_fuzz, "-trim", "+repage"]

    # Quality filter & unsharp
    ops += ["-filter", rs.filter_name, "-define", f"filter:blur={rs.filter_blur}"]
    if rs.unsharp and rs.unsharp.lower() != "none":
        ops += ["-unsharp", rs.unsharp]

    # Fit strategy
    if rs.fit == "cover":
        # Scale up to cover, then center crop/extend to final box
        ops += ["-resize", f"{W}x{H}^", "-gravity", "center", "-background", rs.bg,
                "-extent", f"{W}x{H}"]
    else:
        # contain (default): scale to fit within the box, then extend to final box
        if rs.pad:
            inner_w = max(1, int(round(W * (1.0 - rs.pad))))
            inner_h = max(1, int(round(H * (1.0 - rs.pad))))
        else:
            inner_w, inner_h = W, H
        ops += ["-resize", f"{inner_w}x{inner_h}", "-gravity", "center",
                "-background", rs.bg, "-extent", f"{W}x{H}"]

    # Strip metadata
    ops += ["-strip"]

    return ops


def run_magick_resize(src: Path, dest: Path, width: int, height: int, rs: RenderSettings) -> None:
    ensure_dir(dest.parent)
    cmd = MAGICK + [str(src)] + build_resize_ops(width, height, rs) + [str(dest)]
    if rs.verbose:
        print(" ", " ".join(map(str, cmd)))
    subprocess.run(cmd, check=True)


def build_ico(src: Path, dest_ico: Path, sizes: Iterable[int], rs: RenderSettings) -> None:
    """
    Build a multi-size .ico by generating temporary PNGs with our
    high-quality resampling and then packing them into one ICO.
    """
    ensure_dir(dest_ico.parent)
    sizes = sorted(set(int(s) for s in sizes if s > 0), reverse=True)
    with tempfile.TemporaryDirectory() as td:
        tmp_pngs: List[Path] = []
        for s in sizes:
            p = Path(td) / f"ico_{s}.png"
            run_magick_resize(src, p, s, s, rs)
            tmp_pngs.append(p)

        # Pack into ICO: magick in1.png in2.png ... -colors 256 dest.ico
        cmd = MAGICK + [*(str(p) for p in tmp_pngs), "-colors", "256", str(dest_ico)]
        if rs.verbose:
            print(" ", " ".join(map(str, cmd)))
        subprocess.run(cmd, check=True)


# ----------------------------- Main Work -----------------------------------

def generate_tiles(src: Path, images_dir: Path, tiles: Dict[str, Tuple[int, int]],
                   scales: Iterable[int], rs: RenderSettings) -> List[Path]:
    outputs: List[Path] = []
    for name, (w, h) in tiles.items():
        # Base (un-suffixed) file is handy for referencing in the manifest.
        base = images_dir / f"{name}.png"
        run_magick_resize(src, base, w, h, rs)
        outputs.append(base)

        for sc in sorted(set(int(s) for s in scales)):
            ww, hh = w * sc // 100, h * sc // 100
            out = images_dir / f"{name}.scale-{sc}.png"
            run_magick_resize(src, out, ww, hh, rs)
            outputs.append(out)
    return outputs


def generate_partner(src: Path, partner_dir: Path,
                     sizes: Iterable[Tuple[int, int]], rs: RenderSettings) -> List[Path]:
    outputs: List[Path] = []
    for (w, h) in sizes:
        out = partner_dir / f"app_icon_{w}.png" if w == h else partner_dir / f"app_icon_{w}x{h}.png"
        run_magick_resize(src, out, w, h, rs)
        outputs.append(out)
    return outputs


def write_manifest_snippet(images_dir: Path, out_file: Path) -> None:
    # Windows will auto-pick scale-200/400 variants when present.
    xml = f"""\
<!-- Save into your Package.appxmanifest under <uap:VisualElements> or use the msix plugin's build→edit→pack flow. -->
<uap:VisualElements
  DisplayName="YOUR_APP_NAME"
  BackgroundColor="transparent"
  Square44x44Logo="{images_dir.name}/Square44x44Logo.png"
  Square150x150Logo="{images_dir.name}/Square150x150Logo.png">
  <uap:DefaultTile
    Wide310x150Logo="{images_dir.name}/Wide310x150Logo.png"
    Square310x310Logo="{images_dir.name}/Square310x310Logo.png" />
</uap:VisualElements>
"""
    ensure_dir(out_file.parent)
    out_file.write_text(xml, encoding="utf-8")


def parse_args(argv: List[str]) -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Generate Windows tile/logo PNGs, a multi-size ICO, and Partner Center assets from a single source image.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    p.add_argument("--src", required=True, type=Path, help="Source image (PNG with transparency recommended).")
    p.add_argument("--project-root", type=Path, default=Path.cwd(),
                   help="Project root (where windows/ and icons/ live).")
    p.add_argument("--images-dir", type=Path, default=DEFAULT_IMAGES_DIR,
                   help="Output directory for Windows tile/logo PNGs (relative to project root or absolute).")
    p.add_argument("--ico-out", type=Path, default=DEFAULT_ICO_PATH,
                   help="Output path for the .ico file (relative to project root or absolute).")
    p.add_argument("--partner-dir", type=Path, default=DEFAULT_PARTNER_DIR,
                   help="Output directory for Partner Center PNGs (relative to project root or absolute).")

    p.add_argument("--scales", type=parse_scale_csv, default="100,200,400",
                   help="Comma-separated list of scale factors to generate for tiles.")
    p.add_argument("--ico-sizes", type=parse_sizes_csv,
                   default="256,128,64,48,32,24,16",
                   help="Comma-separated list of ICO sizes (square).")
    p.add_argument("--partner-sizes", default="1024,300,150,71",
                   help="Comma-separated list of square sizes for Partner Center (e.g. 1024,512,300,150,71).")

    p.add_argument("--fit", choices=("contain", "cover"), default="contain",
                   help="Scaling mode: 'contain' preserves full image with padding; 'cover' fills and crops.")
    p.add_argument("--bg", default="none",
                   help="Background for letterboxing/extent (e.g., 'none', '#FFFFFF').")
    p.add_argument("--pad", type=float, default=0.0,
                   help="Safe padding as a fraction of the box (0.0..0.40). Applied in 'contain' mode.")
    p.add_argument("--trim", action="store_true", help="Trim transparent edges before scaling.")
    p.add_argument("--trim-fuzz", default="0%",
                   help="Fuzz factor used by trim (e.g., '2%').")
    p.add_argument("--filter", dest="filter_name", default="Lanczos",
                   help="ImageMagick filter (Lanczos, Mitchell, etc.).")
    p.add_argument("--filter-blur", type=float, default=0.9,
                   help="Filter blur factor (lower is crisper).")
    p.add_argument("--unsharp", default="0x0.6+0.8+0.02",
                   help="Unsharp params 'radiusxsigma+amount+threshold' or 'none' to disable.")
    p.add_argument("--write-manifest-snippet", action="store_true",
                   help="Write a helper XML snippet referencing the generated assets.")

    p.add_argument("--no-tiles", action="store_true", help="Skip generating Windows tile/logo PNGs.")
    p.add_argument("--no-ico", action="store_true", help="Skip generating .ico.")
    p.add_argument("--no-partner", action="store_true", help="Skip generating Partner Center PNGs.")
    p.add_argument("--verbose", action="store_true", help="Verbose commands.")

    args = p.parse_args(argv)

    if not args.src.exists():
        sys.exit(f"Source image not found: {args.src}")

    if args.pad < 0.0 or args.pad > 0.4:
        sys.exit("--pad must be between 0.0 and 0.40")

    return args


def main(argv: List[str]) -> int:
    args = parse_args(argv)

    # Resolve output locations
    project_root: Path = args.project_root.resolve()
    images_dir: Path = (args.images_dir if args.images_dir.is_absolute()
                        else project_root / args.images_dir)
    ico_out: Path = (args.ico_out if args.ico_out.is_absolute()
                     else project_root / args.ico_out)
    partner_dir: Path = (args.partner_dir if args.partner_dir.is_absolute()
                         else project_root / args.partner_dir)

    ensure_dir(images_dir)
    ensure_dir(partner_dir)
    ensure_dir(ico_out.parent)

    # Parse Partner Center sizes (square list like "1024,300,150,71")
    partner_sizes = tuple((s, s) for s in parse_sizes_csv(args.partner_sizes))

    rs = RenderSettings(
        fit=args.fit,
        bg=args.bg,
        filter_name=args.filter_name,
        filter_blur=args.filter_blur,
        unsharp=args.unsharp,
        trim=bool(args.trim),
        trim_fuzz=args.trim_fuzz,
        pad=float(args.pad),
        verbose=bool(args.verbose),
    )

    generated: List[Path] = []

    if not args.no_tiles:
        print(f"• Generating Windows tile/logo PNGs → {images_dir}")
        gen = generate_tiles(
            src=args.src,
            images_dir=images_dir,
            tiles=DEFAULT_TILES,
            scales=args.scales,
            rs=rs,
        )
        generated.extend(gen)

    if not args.no_ico:
        print(f"• Building multi-size ICO → {ico_out}")
        build_ico(args.src, ico_out, args.ico_sizes, rs)
        generated.append(ico_out)

    if not args.no_partner:
        print(f"• Generating Partner Center PNGs → {partner_dir}")
        gen = generate_partner(args.src, partner_dir, partner_sizes, rs)
        generated.extend(gen)

    if args.write_manifest_snippet:
        snippet = images_dir / "_manifest_snippet.xml"
        print(f"• Writing helper manifest snippet → {snippet}")
        write_manifest_snippet(images_dir, snippet)

    # Summary
    print("\nGenerated assets:")
    for p in sorted(set(generated)):
        print("  -", p.relative_to(project_root) if str(p).startswith(str(project_root)) else p)

    print("\nDone.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
