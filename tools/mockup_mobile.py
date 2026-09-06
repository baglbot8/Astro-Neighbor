#!/usr/bin/env python3
"""Composites a mock mobile touch UI over a real game frame, so a layout can be judged
before it is built. Draws a left thumbstick, right action cluster, and a slim top bar.
Usage: python3 tools/mockup_mobile.py IN.png OUT.png [landscape|portrait]
"""
import sys, os
from PIL import Image, ImageDraw, ImageFont

CREAM = (235, 228, 207, 235)
CREAM_SOLID = (235, 228, 207, 255)
EDGE = (196, 178, 138, 255)
BROWN = (107, 82, 50, 255)
YELLOW = (240, 196, 62, 255)


def font(px):
    for p in ("/System/Library/Fonts/Supplemental/Arial Rounded Bold.ttf",):
        try:
            return ImageFont.truetype(p, px)
        except Exception:
            pass
    return ImageFont.load_default()


def pill(d, box, r, fill=CREAM, outline=EDGE, w=3):
    d.rounded_rectangle(box, radius=r, fill=fill, outline=outline, width=w)


def main():
    src, out, mode = sys.argv[1], sys.argv[2], (sys.argv[3] if len(sys.argv) > 3 else "landscape")
    im = Image.open(os.path.expanduser(src)).convert("RGBA")
    W, H = im.size
    ov = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(ov)
    u = H / 720.0 if mode == "landscape" else W / 720.0   # one scale unit

    # --- thumbstick, bottom-left ---
    r_out = int(96 * u)
    cx, cy = int(150 * u), H - int(150 * u)
    d.ellipse([cx - r_out, cy - r_out, cx + r_out, cy + r_out], fill=(30, 26, 45, 90), outline=(235, 228, 207, 140), width=int(4 * u))
    r_in = int(44 * u)
    d.ellipse([cx - r_in, cy - r_in, cx + r_in, cy + r_in], fill=(235, 228, 207, 210), outline=EDGE, width=int(3 * u))

    # --- action cluster, bottom-right ---
    big = int(64 * u)
    bx, by = W - int(130 * u), H - int(130 * u)
    d.ellipse([bx - big, by - big, bx + big, by + big], fill=(240, 196, 62, 235), outline=(150, 110, 30, 255), width=int(4 * u))
    f = font(int(38 * u))
    d.text((bx, by), "E", font=f, fill=BROWN, anchor="mm")
    for dx, dy, lab in ((-1.75, 0.05, "↑"), (-0.55, -1.35, "▲")):
        sx, sy = int(bx + dx * big * 1.25), int(by + dy * big * 1.25)
        rs = int(46 * u)
        d.ellipse([sx - rs, sy - rs, sx + rs, sy + rs], fill=CREAM, outline=EDGE, width=int(3 * u))
        d.text((sx, sy), lab, font=font(int(30 * u)), fill=BROWN, anchor="mm")

    # --- top bar: stardust + clock ---
    ph = int(52 * u)
    pill(d, [int(20 * u), int(20 * u), int(20 * u) + int(150 * u), int(20 * u) + ph], int(26 * u))
    d.ellipse([int(34 * u), int(32 * u), int(34 * u) + int(28 * u), int(32 * u) + int(28 * u)], fill=YELLOW)
    d.text((int(78 * u), int(20 * u) + ph // 2), "120", font=font(int(28 * u)), fill=BROWN, anchor="lm")
    cw = int(190 * u)
    pill(d, [W - int(20 * u) - cw, int(20 * u), W - int(20 * u), int(20 * u) + ph], int(26 * u))
    d.text((W - int(20 * u) - cw // 2, int(20 * u) + ph // 2), "1:12 PM · Day 1", font=font(int(23 * u)), fill=BROWN, anchor="mm")

    # --- bag / journal, top-right under the clock ---
    for i, lab in enumerate(("Bag", "★")):
        sw = int(88 * u)
        x0 = W - int(20 * u) - sw - i * int(100 * u)
        pill(d, [x0, int(88 * u), x0 + sw, int(88 * u) + int(48 * u)], int(22 * u))
        d.text((x0 + sw // 2, int(88 * u) + int(24 * u)), lab, font=font(int(22 * u)), fill=BROWN, anchor="mm")

    im = Image.alpha_composite(im, ov)
    # safe-area guides
    g = ImageDraw.Draw(im)
    inset = int(24 * u)
    g.rectangle([inset, inset, W - inset, H - inset], outline=(255, 90, 90, 110), width=2)
    im.convert("RGB").save(os.path.expanduser(out), quality=94)
    print("wrote", out, im.size)


if __name__ == "__main__":
    main()
