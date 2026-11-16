"""Render ACEkanner raster icons (legacy launcher PNGs and the Play Store icon).

The vector source of truth is app/android/app/src/main/res/drawable/ic_launcher_foreground.xml
(108x108 viewport). This script redraws the same geometry with Pillow.

Usage (from the repository root):
    python3 -I tools/brand/generate_icons.py
"""
import os
import sys

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
RES = os.path.join(ROOT, "app", "android", "app", "src", "main", "res")
STORE = os.path.join(ROOT, "store")

BLUE = (29, 78, 216, 255)       # #1D4ED8
WHITE = (255, 255, 255, 255)
SS = 8                          # supersampling factor


def draw_mark(d, s, ox=0.0, oy=0.0):
    """Draw the mark using 108-unit geometry scaled by s."""
    def p(x, y):
        return (ox + x * s, oy + y * s)

    w = 5 * s
    brackets = [
        [(32, 43), (32, 32), (43, 32)],
        [(65, 32), (76, 32), (76, 43)],
        [(76, 65), (76, 76), (65, 76)],
        [(43, 76), (32, 76), (32, 65)],
    ]
    for pts in brackets:
        d.line([p(*a) for a in pts], fill=WHITE, width=round(w), joint="curve")
        for a in (pts[0], pts[-1], pts[1]):
            cx, cy = p(*a)
            d.ellipse([cx - w / 2, cy - w / 2, cx + w / 2, cy + w / 2], fill=WHITE)
    cx, cy = p(54, 54)
    r = 13 * s
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=WHITE)
    cw = 3.6 * s
    check = [p(47.5, 54.5), p(52, 59), p(61, 50)]
    d.line(check, fill=BLUE, width=round(cw), joint="curve")
    for x, y in (check[0], check[-1]):
        d.ellipse([x - cw / 2, y - cw / 2, x + cw / 2, y + cw / 2], fill=BLUE)


def render(size, shape):
    big = size * SS
    img = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if shape == "square":          # Play Store: full-bleed square, Play applies the mask
        d.rectangle([0, 0, big, big], fill=BLUE)
        scale = big / 108 * 1.25   # mark fills more of the tile
        off = (big - 108 * scale) / 2
        draw_mark(d, scale, off, off)
    else:
        if shape == "round":
            d.ellipse([0, 0, big - 1, big - 1], fill=BLUE)
        else:                      # legacy rounded square
            d.rounded_rectangle([0, 0, big - 1, big - 1], radius=big * 0.2, fill=BLUE)
        scale = big / 108 * 1.3
        off = (big - 108 * scale) / 2
        draw_mark(d, scale, off, off)
    return img.resize((size, size), Image.LANCZOS)


def main():
    densities = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
    for name, px in densities.items():
        folder = os.path.join(RES, f"mipmap-{name}")
        os.makedirs(folder, exist_ok=True)
        render(px, "rounded").save(os.path.join(folder, "ic_launcher.png"))
        render(px, "round").save(os.path.join(folder, "ic_launcher_round.png"))
    os.makedirs(STORE, exist_ok=True)
    render(512, "square").convert("RGB").save(os.path.join(STORE, "play_icon_512.png"))
    print("icons written")


if __name__ == "__main__":
    sys.exit(main())
