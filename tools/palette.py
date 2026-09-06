#!/usr/bin/env python3
"""Measure the colour/contrast character of an image (or a crop) so art direction is numeric, not vibes.

Usage:
  python3 tools/palette.py "label=path[:x0,y0,x1,y1]" ["label=path[:crop]" ...]

Prints per image: mean/median HSV saturation & value, the 8 dominant colours (k-means-ish
bucket centroids) with hex + HSV + coverage, the 5th/95th percentile luma (contrast range),
and the fraction of pixels above 92% luma (blown highlights).

Use it to compare our renders against reference/ Animal Crossing screenshots.
"""
import sys, os, colorsys
from PIL import Image
import numpy as np


def load(spec):
    label, rest = spec.split("=", 1)
    crop = None
    if rest.count(":") >= 1 and rest.rsplit(":", 1)[1].count(",") == 3:
        rest, c = rest.rsplit(":", 1)
        crop = tuple(int(v) for v in c.split(","))
    im = Image.open(os.path.expanduser(rest)).convert("RGB")
    if crop:
        im = im.crop(crop)
    return label, im


def dominant(arr, k=8):
    """Cheap k-means on a subsample."""
    px = arr.reshape(-1, 3).astype(np.float32)
    if len(px) > 40000:
        idx = np.random.default_rng(7).choice(len(px), 40000, replace=False)
        px = px[idx]
    rng = np.random.default_rng(3)
    cent = px[rng.choice(len(px), k, replace=False)]
    for _ in range(14):
        d = ((px[:, None, :] - cent[None, :, :]) ** 2).sum(2)
        lab = d.argmin(1)
        for i in range(k):
            m = lab == i
            if m.any():
                cent[i] = px[m].mean(0)
    d = ((px[:, None, :] - cent[None, :, :]) ** 2).sum(2)
    lab = d.argmin(1)
    out = []
    for i in range(k):
        cov = float((lab == i).mean())
        if cov < 0.01:
            continue
        r, g, b = [float(v) for v in cent[i]]
        h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
        out.append((cov, (int(r), int(g), int(b)), h * 360, s, v))
    out.sort(reverse=True)
    return out


def report(label, im):
    arr = np.asarray(im)
    r, g, b = arr[..., 0] / 255.0, arr[..., 1] / 255.0, arr[..., 2] / 255.0
    mx, mn = np.maximum(np.maximum(r, g), b), np.minimum(np.minimum(r, g), b)
    v = mx
    s = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0)
    luma = 0.2126 * r + 0.7152 * g + 0.0722 * b
    print(f"\n=== {label}  ({im.width}x{im.height}) ===")
    print(f"  saturation  mean {s.mean():.3f}  median {np.median(s):.3f}  p90 {np.percentile(s,90):.3f}")
    print(f"  value/brt   mean {v.mean():.3f}  median {np.median(v):.3f}")
    print(f"  luma        p05 {np.percentile(luma,5):.3f}  p50 {np.median(luma):.3f}  p95 {np.percentile(luma,95):.3f}  range {np.percentile(luma,95)-np.percentile(luma,5):.3f}")
    print(f"  blown (luma>0.92): {float((luma>0.92).mean())*100:.1f}%   dark (luma<0.15): {float((luma<0.15).mean())*100:.1f}%")
    print("  dominant colours:")
    for cov, rgb, h, ss, vv in dominant(arr):
        print(f"    {cov*100:5.1f}%  #{rgb[0]:02x}{rgb[1]:02x}{rgb[2]:02x}  rgb{rgb}  H{h:6.1f} S{ss:.2f} V{vv:.2f}")


def main():
    if len(sys.argv) < 2:
        print(__doc__); sys.exit(1)
    for spec in sys.argv[1:]:
        label, im = load(spec)
        report(label, im)


if __name__ == "__main__":
    main()
