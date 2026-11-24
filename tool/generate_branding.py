"""Generates Bloxie branding assets: master app icon and splash logo.

Run: python tool/generate_branding.py

Outputs:
  assets/branding/icon_master.png     (1024x1024 master launcher icon)
  assets/branding/icon_foreground.png (1024x1024 adaptive foreground, content in center 66%)
  assets/branding/icon_monochrome.png (1024x1024 white alpha mask for themed icons)
  assets/branding/logo.png            (512x512 in-app logo, transparent bg)
  assets/branding/splash_logo.png     (1152x1152 Android 12+ splash icon, fits the 2/3 circle mask)
  store/play_icon_512.png             (Play Store hi-res icon, not bundled)
  store/feature_graphic_1024x500.png  (Play Store feature graphic, not bundled)
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "branding"
STORE = ROOT / "store"

# Theme palette from lib/core/theme/skins.dart (default skin)
BG_TOP = (27, 20, 70)      # 0xFF1B1446
BG_BOTTOM = (10, 10, 31)   # 0xFF0A0A1F
ACCENT = (124, 92, 255)    # 0xFF7C5CFF
BLOCK_COLORS = [
    (255, 92, 138),   # pink   0xFFFF5C8A
    (255, 184, 77),   # amber  0xFFFFB84D
    (77, 224, 168),   # mint   0xFF4DE0A8
    (77, 184, 255),   # blue   0xFF4DB8FF
]

SIZE = 1024
CORNER = int(SIZE * 0.09)  # squircle-ish rounded corner radius for tiles


def rounded_tile(draw, box, radius, fill):
    draw.rounded_rectangle(box, radius=radius, fill=fill)


def draw_blocks(draw, cx, cy, unit, gap, colors, radius):
    """Draw a 2x2 cluster of rounded tiles centered at (cx, cy)."""
    total = unit * 2 + gap
    left = cx - total / 2
    top = cy - total / 2
    positions = [
        (left, top),
        (left + unit + gap, top),
        (left, top + unit + gap),
        (left + unit + gap, top + unit + gap),
    ]
    for (x, y), color in zip(positions, colors):
        rounded_tile(draw, (x, y, x + unit, y + unit), radius, color)


def gradient_bg(size, top, bottom, height=None):
    """Vertical gradient, one row at a time."""
    height = height or size
    img = Image.new("RGB", (size, height))
    draw = ImageDraw.Draw(img)
    for y in range(height):
        t = y / (height - 1)
        color = tuple(round(a + (b - a) * t) for a, b in zip(top, bottom))
        draw.line((0, y, size, y), fill=color)
    return img


def make_master():
    img = gradient_bg(SIZE, BG_TOP, BG_BOTTOM).convert("RGBA")

    # Subtle accent glow ring behind the blocks
    glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse((212, 212, 812, 812), fill=ACCENT + (70,))
    glow = glow.filter(ImageFilter.GaussianBlur(90))
    img = Image.alpha_composite(img, glow)

    blocks = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    bd = ImageDraw.Draw(blocks)
    draw_blocks(bd, SIZE / 2, SIZE / 2, unit=250, gap=36, colors=BLOCK_COLORS, radius=CORNER)

    # Drop shadow under blocks
    shadow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    draw_blocks(sd, SIZE / 2, SIZE / 2 + 18, unit=250, gap=36, colors=[(0, 0, 0, 120)] * 4, radius=CORNER)
    shadow = shadow.filter(ImageFilter.GaussianBlur(24))
    img = Image.alpha_composite(img, shadow)
    img = Image.alpha_composite(img, blocks)

    img.save(OUT / "icon_master.png")
    return img


def make_foreground():
    """Adaptive foreground: blocks scaled to fit safe zone (the generator already insets it 16%)."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    bd = ImageDraw.Draw(img)
    draw_blocks(bd, SIZE / 2, SIZE / 2, unit=300, gap=32, colors=BLOCK_COLORS, radius=int(300 * 0.09))
    img.save(OUT / "icon_foreground.png")


def make_monochrome():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    bd = ImageDraw.Draw(img)
    draw_blocks(bd, SIZE / 2, SIZE / 2, unit=300, gap=32, colors=[(255, 255, 255, 255)] * 4, radius=int(300 * 0.09))
    img.save(OUT / "icon_monochrome.png")


def make_logo():
    """In-app logo: blocks only on transparent background."""
    img = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    bd = ImageDraw.Draw(img)
    draw_blocks(bd, 256, 256, unit=128, gap=18, colors=BLOCK_COLORS, radius=int(128 * 0.09))
    img.save(OUT / "logo.png")


def make_splash_logo():
    """Android 12+ splash icon (1152px canvas, cropped to a circle of 2/3 width).

    The cluster's corners must sit inside radius 384, so its half-diagonal is
    kept at ~300px: half-side 212 * sqrt(2) = 300.
    """
    size = 1152
    unit, gap = 196, 32
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    bd = ImageDraw.Draw(img)
    draw_blocks(bd, size / 2, size / 2, unit=unit, gap=gap, colors=BLOCK_COLORS, radius=int(unit * 0.09))
    img.save(OUT / "splash_logo.png")


def make_store_assets(master):
    STORE.mkdir(parents=True, exist_ok=True)
    master.resize((512, 512), Image.LANCZOS).convert("RGB").save(STORE / "play_icon_512.png")
    graphic = gradient_bg(1024, BG_TOP, BG_BOTTOM, height=500)
    draw_blocks(ImageDraw.Draw(graphic), 200, 250, unit=110, gap=16, colors=BLOCK_COLORS, radius=20)
    graphic.save(STORE / "feature_graphic_1024x500.png")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    master = make_master()
    make_foreground()
    make_monochrome()
    make_logo()
    make_splash_logo()
    make_store_assets(master)
    print(f"Branding assets written to {OUT} and {STORE}")


if __name__ == "__main__":
    main()
