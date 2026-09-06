#!/usr/bin/env python3
"""Measure high-frequency luma energy (dithering / shadow acne / stipple) in a PNG crop.

The metric is the same one the NPC critic used to size the soft-shadow penumbra dithering:
take the luma channel, blur it with a 3x3 box, and look at how far the original deviates.
A smooth toon surface should be nearly identical to its own blur; a dot-grid stipple is
pure high-frequency energy and shows up immediately.

Usage:
  python3 tools/hf_noise.py "label=path[:x0,y0,x1,y1]" ["label=path[:crop]" ...]

Prints per crop: HF rms, HF p99, HF max, plus the crop's mean luma and luma sigma so a
bright-but-clean surface is not confused with a dark one.

Reference points (measured at noon, 1152x648 gameplay frames):
  ACNH Rosie's head (JPEG reference) 0.0175  <- the bar
  a shadowless showcase head         0.0023
"""
import os
import sys

import numpy as np
from PIL import Image

# Rec. 709 luma weights, matching tools/palette.py.
_LUMA = np.array([0.2126, 0.7152, 0.0722], dtype=np.float32)


def load(spec: str) -> tuple[str, Image.Image]:
    """Parse `label=path[:x0,y0,x1,y1]` the same way palette.py / compare.py do."""
    label, rest = spec.split("=", 1)
    crop = None
    if rest.count(":") >= 1 and rest.rsplit(":", 1)[1].count(",") == 3:
        rest, c = rest.rsplit(":", 1)
        crop = tuple(int(v) for v in c.split(","))
    im = Image.open(os.path.expanduser(rest)).convert("RGB")
    if crop:
        im = im.crop(crop)
    return label, im


def box3(a: np.ndarray) -> np.ndarray:
    """3x3 box blur with edge clamping, implemented as two separable passes."""
    p = np.pad(a, 1, mode="edge")
    h = (p[:, :-2] + p[:, 1:-1] + p[:, 2:]) / 3.0
    v = (h[:-2, :] + h[1:-1, :] + h[2:, :]) / 3.0
    return v


def hf_stats(im: Image.Image) -> dict[str, float]:
    """High-frequency luma statistics for one crop, in 0..1 luma units."""
    arr = np.asarray(im, dtype=np.float32) / 255.0
    luma = arr @ _LUMA
    d = np.abs(luma - box3(luma))
    return {
        "rms": float(np.sqrt(np.mean(d * d))),
        "p99": float(np.percentile(d, 99)),
        "max": float(d.max()),
        "mean_luma": float(luma.mean()),
        "sigma": float(luma.std()),
        "px": int(luma.size),
    }


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 1
    print(f"{'label':<26}{'HF rms':>9}{'HF p99':>9}{'HF max':>9}{'luma':>8}{'sigma':>8}{'px':>9}")
    for spec in sys.argv[1:]:
        label, im = load(spec)
        s = hf_stats(im)
        print(
            f"{label:<26}{s['rms']:>9.4f}{s['p99']:>9.4f}{s['max']:>9.4f}"
            f"{s['mean_luma']:>8.3f}{s['sigma']:>8.4f}{s['px']:>9d}"
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
