"""Launcher icons (API 24-25 fallback PNGs), the Play icon and the feature graphic.

Usage (from the repository root):  python3 -I acekor/tools/generate_brand.py
Writes acekor/app/android/app/src/main/res/mipmap-*/ic_launcher.png and acekor/store/*.png.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, "app/android/app/src/main/res")
STORE = os.path.join(ROOT, "store")
BG = (11, 11, 12)
GREEN = (19, 165, 124)
TEAL = (44, 197, 160)
WHITE = (255, 255, 255)
KEY = (42, 42, 44)
MUTED = (161, 161, 166)
RED = (255, 90, 82)
SS = 4


def mark(draw, cx, cy, r, stroke):
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=GREEN)
    pts = [(cx - 0.47 * r, cy + 0.03 * r), (cx - 0.13 * r, cy + 0.37 * r), (cx + 0.5 * r, cy - 0.3 * r)]
    draw.line(pts, fill=WHITE, width=int(stroke), joint="curve")
    for p in (pts[0], pts[2]):
        draw.ellipse([p[0] - stroke / 2, p[1] - stroke / 2, p[0] + stroke / 2, p[1] + stroke / 2], fill=WHITE)


def icon(size, rounded=True):
    s = size * SS
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if rounded:
        d.rounded_rectangle([0, 0, s - 1, s - 1], radius=int(s * 0.22), fill=BG)
    else:
        d.rectangle([0, 0, s, s], fill=BG)
    mark(d, s / 2, s / 2, s * 0.34, s * 0.075)
    return img.resize((size, size), Image.LANCZOS)


def font(size, bold=False):
    for path in [
        "/usr/share/fonts/opentype/inter/Inter-Bold.otf" if bold else "/usr/share/fonts/opentype/inter/Inter-Regular.otf",
        os.path.join(ROOT, "app/assets/fonts/Roboto-Bold.ttf" if bold else "app/assets/fonts/Roboto-Regular.ttf"),
    ]:
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def feature_graphic():
    W, H = 1024, 500
    img = Image.new("RGB", (W * SS, H * SS), BG)
    d = ImageDraw.Draw(img)
    # Left: wordmark and tagline.
    mark(d, 120 * SS, 150 * SS, 52 * SS, 9 * SS)
    d.text((70 * SS, 230 * SS), "ACEKOR", font=font(92 * SS, True), fill=WHITE)
    d.text((74 * SS, 330 * SS), "C A L C U L A T O R", font=font(30 * SS, True), fill=TEAL)
    d.text((74 * SS, 390 * SS), "Search. Score. Save. Offline.", font=font(30 * SS), fill=MUTED)
    # Right: the academic calculator.
    x0 = 610 * SS
    d.text((x0 + 10 * SS, 40 * SS), "STUDENT: JUAN DELA CRUZ", font=font(20 * SS, True), fill=WHITE)
    d.text((x0 + 10 * SS, 70 * SS), "QUIZ 1", font=font(26 * SS, True), fill=WHITE)
    d.text((x0 + 70 * SS, 104 * SS), "42/50", font=font(70 * SS), fill=WHITE)
    d.text((x0 + 140 * SS, 186 * SS), "84%", font=font(40 * SS), fill=TEAL)
    keys = [["7", "8", "9"], ["4", "5", "6"], ["1", "2", "3"], ["<", "0", "ok"]]
    r = 27 * SS
    for i, row in enumerate(keys):
        for j, k in enumerate(row):
            cx = x0 + (75 + j * 110) * SS
            cy = (268 + i * 62) * SS
            d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=GREEN if k == "ok" else KEY)
            if k == "ok":
                d.line([(cx - 10 * SS, cy), (cx - 3 * SS, cy + 8 * SS), (cx + 11 * SS, cy - 8 * SS)], fill=WHITE, width=5 * SS)
            elif k == "<":
                d.line([(cx + 9 * SS, cy - 8 * SS), (cx - 6 * SS, cy), (cx + 9 * SS, cy + 8 * SS)], fill=RED, width=4 * SS)
            else:
                f = font(26 * SS)
                w = d.textlength(k, font=f)
                d.text((cx - w / 2, cy - 16 * SS), k, font=f, fill=WHITE)
    return img.resize((W, H), Image.LANCZOS)


def main():
    sizes = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
    for density, px in sizes.items():
        path = os.path.join(RES, f"mipmap-{density}", "ic_launcher.png")
        os.makedirs(os.path.dirname(path), exist_ok=True)
        icon(px).save(path)
    os.makedirs(STORE, exist_ok=True)
    icon(512, rounded=False).convert("RGB").save(os.path.join(STORE, "play_icon_512.png"))
    feature_graphic().save(os.path.join(STORE, "feature_graphic_1024x500.png"))
    print("icons and store graphics written")


if __name__ == "__main__":
    main()
