#!/usr/bin/env python3
"""Side-by-side comparison sheet builder.
Usage:
  python3 tools/compare.py OUT.png "label=path[:x0,y0,x1,y1]" "label=path[:crop]" ...
Each argument is an image (optionally cropped to x0,y0,x1,y1 in source pixels). All tiles are
resized to the same height and laid out in a row with labels, so a builder/critic can Read ONE
image and judge "does our character look like an Animal Crossing character?" side by side.
Example:
  python3 tools/compare.py ~/.astro_captures/cmp/astro_vs_ac.png \
     "OURS=$HOME/.astro_captures/orch_face/f00000029.png:380,120,900,700" \
     "AC player=reference/AC Reference 2 copy.jpg:780,380,1080,760" \
     "AC Rosie=reference/AC Reference 4 copy.jpg:600,180,900,640"
"""
import sys, os
from PIL import Image, ImageDraw, ImageFont

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

def main():
    if len(sys.argv) < 3:
        print(__doc__); sys.exit(1)
    out = os.path.expanduser(sys.argv[1])
    tiles = [load(s) for s in sys.argv[2:]]
    H = 520
    resized = []
    for label, im in tiles:
        w = int(im.width * H / im.height)
        resized.append((label, im.resize((w, H), Image.LANCZOS)))
    pad = 16
    W = sum(w for _, im in resized for w in [im.width]) + pad * (len(resized) + 1)
    sheet = Image.new("RGB", (W, H + 60), (250, 245, 232))
    d = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Rounded Bold.ttf", 26)
    except Exception:
        font = ImageFont.load_default()
    x = pad
    for label, im in resized:
        sheet.paste(im, (x, 50))
        d.text((x + 6, 12), label, fill=(107, 82, 50), font=font)
        x += im.width + pad
    os.makedirs(os.path.dirname(out), exist_ok=True)
    sheet.save(out)
    print("wrote", out, sheet.size)

if __name__ == "__main__":
    main()
