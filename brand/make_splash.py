"""Regenerates brand/splash/ from the Tally mark's geometry. Run from the app root.

The 2 x 2 mark (logo kit v2.0) on full transparency, one image per theme, so
the --bg color in flutter_native_splash.yaml shows through. Same shapes and
colors as GridwellMarkPainter. Images are 4x: the 416 px mark renders at
104 dp, exactly where lib/ui/screens/splash_screen.dart paints it. Needs Pillow.
"""
from PIL import Image, ImageDraw

UNITS, CELL, GAP = 21.5, 10.0, 1.5
LIME = (0xC1, 0xEE, 0x66, 255)
THEMES = {
    # name: (ink, track)
    'light': ((0x0D, 0x1F, 0x16, 255), (0xD2, 0xDB, 0xCE, 255)),
    'dark': ((0xF0, 0xF3, 0xE8, 255), (0x1C, 0x33, 0x29, 255)),
}
MARK = 416  # 104 dp at 4x
SS = 4  # supersampling


def mark(size, ink, track):
    px = size * SS
    u = px / UNITS
    im = Image.new('RGBA', (px, px), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    for r, c, color in [(0, 0, ink), (0, 1, track), (1, 0, track), (1, 1, LIME)]:
        x, y = c * (CELL + GAP) * u, r * (CELL + GAP) * u
        d.rectangle([x, y, x + CELL * u - 1, y + CELL * u - 1], fill=color)
    return im.resize((size, size), Image.LANCZOS)


for name, (ink, track) in THEMES.items():
    m = mark(MARK, ink, track)
    m.save(f'brand/splash/splash-{name}.png')
    # Android 12+ crops the icon to a circle 2/3 of a 1152 px canvas (radius
    # 384 px); the mark's half-diagonal is 294 px, well inside.
    canvas = Image.new('RGBA', (1152, 1152), (0, 0, 0, 0))
    off = (1152 - MARK) // 2
    canvas.paste(m, (off, off))
    canvas.save(f'brand/splash/android12-{name}.png')
