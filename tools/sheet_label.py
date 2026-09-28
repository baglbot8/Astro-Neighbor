#!/usr/bin/env python3
"""Overlay sight names on a contact sheet written by showcase/safari_sheet.gd.

Reads manifest_<tag>.json next to sheet_<tag>.png and writes sheet_<tag>_labelled.png.
Scratch-only spike tool (2026-09-21).
"""
import json
import sys
from PIL import Image, ImageDraw, ImageFont

FONTS = [
    "/System/Library/Fonts/SFNSMono.ttf",
    "/System/Library/Fonts/Supplemental/Arial.ttf",
    "/Library/Fonts/Arial.ttf",
]


def font(sz):
    for f in FONTS:
        try:
            return ImageFont.truetype(f, sz)
        except OSError:
            continue
    return ImageFont.load_default()


def main(outdir, tag, title):
    man = json.load(open(f"{outdir}/manifest_{tag}.json"))
    im = Image.open(f"{outdir}/sheet_{tag}.png").convert("RGB")
    d = ImageDraw.Draw(im)
    f_big = font(26)
    f_lab = font(19)
    f_sub = font(16)
    d.text((10, 8), title, fill=(230, 226, 214), font=f_big)
    for t in man["tiles"]:
        y = t["y"] + t["h"] + 3
        name = t["name"]
        if len(name) > 40:
            name = name[:39] + "…"
        head = f'{t["i"]+1:02d} {name}'
        d.text((t["x"] + 2, y), head, fill=(235, 232, 222), font=f_lab)
        sub = f'{t["id"]}  draw={t["draw"]}'
        if t["tag"]:
            sub += f'  [{t["tag"]}]'
        d.text((t["x"] + 2, y + 18), sub, fill=(150, 160, 180), font=f_sub)
    out = f"{outdir}/sheet_{tag}_labelled.png"
    im.save(out)
    print("wrote", out, im.size)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else sys.argv[2])
