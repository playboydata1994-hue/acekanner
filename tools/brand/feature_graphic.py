"""Render the Google Play feature graphic (1024 x 500, RGB, no transparency).

Usage (from the repository root):
    python3 -I tools/brand/feature_graphic.py
Writes store/feature_graphic_1024x500.png.
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from generate_icons import BLUE, STORE, draw_mark  # noqa: E402

W, H, SS = 1024, 500, 4
FONT_DIR = "/usr/share/fonts/opentype/inter"
WHITE = (255, 255, 255)
SOFT = (219, 234, 254)          # light blue text
INK = (17, 24, 39)
LINE = (148, 163, 184)
DEEP = (30, 64, 175)            # #1E40AF


def font(name, size):
    return ImageFont.truetype(os.path.join(FONT_DIR, name), size * SS)


def main():
    img = Image.new("RGB", (W * SS, H * SS), BLUE[:3])
    d = ImageDraw.Draw(img)

    # Soft diagonal band for depth.
    d.polygon([(560 * SS, 0), (W * SS, 0), (W * SS, H * SS), (430 * SS, H * SS)], fill=DEEP)

    # Logo mark + name + tagline (left, vertically centred).
    s = 1.35 * SS
    draw_mark(d, s, 64 * SS - 32 * s, 150 * SS - 32 * s)
    d.text((64 * SS, 228 * SS), "ACEkanner", font=font("Inter-Bold.otf", 64), fill=WHITE)
    tag = font("Inter-Medium.otf", 27)
    d.text((66 * SS, 318 * SS), "Check shaded answer sheets", font=tag, fill=SOFT)
    d.text((66 * SS, 354 * SS), "with your phone camera.", font=tag, fill=SOFT)
    d.text((66 * SS, 410 * SS), "Works offline  ·  Data stays on your phone",
           font=font("Inter-Regular.otf", 19), fill=SOFT)

    # Answer-sheet card (right), drawn upright then rotated slightly.
    cw, ch = 300, 360
    card = Image.new("RGBA", (cw * SS, ch * SS), (0, 0, 0, 0))
    c = ImageDraw.Draw(card)
    c.rounded_rectangle([0, 0, cw * SS, ch * SS], radius=18 * SS, fill=(255, 255, 255, 255))
    for x, y in ((18, 18), (cw - 38, 18), (18, ch - 38), (cw - 38, ch - 38)):   # corner markers
        c.rectangle([x * SS, y * SS, (x + 20) * SS, (y + 20) * SS], fill=INK)
    c.text((60 * SS, 20 * SS), "ANSWER SHEET", font=font("Inter-Bold.otf", 17), fill=INK)
    c.text((60 * SS, 44 * SS), "SET  A", font=font("Inter-SemiBold.otf", 13), fill=INK)
    small = font("Inter-SemiBold.otf", 12)
    shaded = [1, 3, 0, 2, 4, 1, 2, 0]
    r = 9
    for row in range(8):
        y = 88 + row * 30
        c.text((52 * SS, y * SS), str(row + 1), font=small, fill=INK, anchor="rm")
        for k, letter in enumerate("ABCDE"):
            x = 80 + k * 40
            box = [(x - r) * SS, (y - r) * SS, (x + r) * SS, (y + r) * SS]
            if shaded[row] == k:
                c.ellipse(box, fill=INK)
            else:
                c.ellipse(box, outline=LINE, width=2 * SS)
                c.text((x * SS, y * SS), letter, font=font("Inter-Medium.otf", 9), fill=LINE, anchor="mm")
    card = card.rotate(-6, resample=Image.BICUBIC, expand=True)
    shadow = Image.new("RGBA", card.size, (0, 0, 0, 0))
    shadow.paste((0, 0, 0, 70), mask=card.split()[3])
    ox, oy = 600 * SS, 52 * SS
    img.paste(shadow, (ox + 10 * SS, oy + 14 * SS), shadow)
    img.paste(card, (ox, oy), card)

    # Score badge over the card.
    bx, by, bw, bh = 800, 394, 140, 78
    d.rounded_rectangle([bx * SS, by * SS, (bx + bw) * SS, (by + bh) * SS], radius=14 * SS, fill=WHITE)
    d.text(((bx + bw / 2) * SS, (by + 31) * SS), "48/50", font=font("Inter-Bold.otf", 30), fill=BLUE[:3], anchor="mm")
    d.text(((bx + bw / 2) * SS, (by + 59) * SS), "Checked", font=font("Inter-Medium.otf", 14), fill=INK, anchor="mm")

    out = img.resize((W, H), Image.LANCZOS)
    os.makedirs(STORE, exist_ok=True)
    path = os.path.join(STORE, "feature_graphic_1024x500.png")
    out.save(path, optimize=True)
    print(path, out.size, out.mode, os.path.getsize(path), "bytes")


if __name__ == "__main__":
    main()
