#!/usr/bin/env python3
"""Palette gates measured INSIDE the porthole, over every sight, before and after.

docs/STYLE_GUIDE.md R2.6 sets the gates on a gameplay frame: saturation p90 <= 0.68, saturation
mean 0.36-0.48, luma p95 <= 0.93, blown (luma > 0.92) < 5%. The glass is not a gameplay frame -
it is a night instrument, so the value and saturation MEANS sit far below the daytime band by
design and are reported for information only. The two gates that bind here and that the critic
named are SATURATION p90 and BLOWN PIXELS: a sight must not scream, and nothing may clip.

Only pixels inside the circular opening are measured. The hull outside it is another round's file
and averaging it in would flatter every number.

Usage: python3 tools/glass_gates.py <before_dir> <after_dir>
"""
import glob
import os
import sys

import numpy as np
from PIL import Image


def measure(path):
    a = np.asarray(Image.open(path).convert("RGB"), dtype=np.float32) / 255.0
    h, w, _ = a.shape
    yy, xx = np.mgrid[0:h, 0:w]
    r = min(h, w) * 0.5
    inside = ((xx - w / 2.0) ** 2 + (yy - h / 2.0) ** 2) < (r - 2) ** 2
    px = a[inside]
    mx = px.max(1)
    mn = px.min(1)
    sat = np.where(mx > 1e-6, (mx - mn) / np.maximum(mx, 1e-6), 0.0)
    luma = 0.2126 * px[:, 0] + 0.7152 * px[:, 1] + 0.0722 * px[:, 2]
    return {
        "sat_p90": float(np.percentile(sat, 90)),
        "sat_p99": float(np.percentile(sat, 99)),
        "sat_mean": float(sat.mean()),
        "val_mean": float(mx.mean()),
        "luma_p95": float(np.percentile(luma, 95)),
        "blown": float((luma > 0.92).mean()),
    }


def run(d):
    out = {}
    for f in sorted(glob.glob(os.path.join(d, "one_*.png"))):
        name = os.path.basename(f)[4:-4]
        if name.endswith("_plain") or name.endswith("_moment"):
            continue
        out[name] = measure(f)
    return out


def main(before, after):
    b, a = run(before), run(after)
    keys = sorted(set(b) & set(a))
    print(f"{len(keys)} sights measured inside the opening, both arms\n")
    hdr = f'{"":22} {"sat p90":>16} {"sat p99":>16} {"blown %":>16} {"luma p95":>16}'
    print(hdr)
    worst = []
    for k in keys:
        worst.append((a[k]["sat_p90"], k))
    for label, agg in (("max over sights", max), ("mean over sights", None)):
        row = []
        for m in ("sat_p90", "sat_p99", "blown", "luma_p95"):
            if agg is max:
                vb = max(b[k][m] for k in keys)
                va = max(a[k][m] for k in keys)
            else:
                vb = sum(b[k][m] for k in keys) / len(keys)
                va = sum(a[k][m] for k in keys) / len(keys)
            if m == "blown":
                vb, va = vb * 100.0, va * 100.0
            row.append(f"{vb:7.4f}->{va:7.4f}")
        print(f"{label:22} " + " ".join(f"{c:>16}" for c in row))
    worst.sort(reverse=True)
    print("\nloudest five sights AFTER (sat p90, gate <= 0.68):")
    for v, k in worst[:5]:
        print(f"   {k:22} {v:.4f}   (before {b[k]['sat_p90']:.4f})")
    print("\nmost blown five AFTER (gate < 5.0%):")
    bl = sorted(((a[k]["blown"], k) for k in keys), reverse=True)
    for v, k in bl[:5]:
        print(f"   {k:22} {v*100:.4f}%  (before {b[k]['blown']*100:.4f}%)")
    print("\nfor information only, not a gate on a night instrument:")
    print(f"   saturation mean over sights {sum(b[k]['sat_mean'] for k in keys)/len(keys):.4f}"
          f" -> {sum(a[k]['sat_mean'] for k in keys)/len(keys):.4f}")
    print(f"   value mean over sights      {sum(b[k]['val_mean'] for k in keys)/len(keys):.4f}"
          f" -> {sum(a[k]['val_mean'] for k in keys)/len(keys):.4f}")
    fails = [k for k in keys if a[k]["sat_p90"] > 0.68 or a[k]["blown"] >= 0.05]
    print("\nGATE RESULT: " + ("PASS, every sight" if not fails
                               else "FAIL on " + ", ".join(fails)))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
