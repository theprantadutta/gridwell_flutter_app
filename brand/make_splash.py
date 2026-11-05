"""Regenerates brand/splash/ from the mark's geometry. Run from the app root.

Cream mark with a coral cross on full transparency, so the ink ground in
flutter_native_splash.yaml shows through. Same shapes as GridwellMarkPainter
with knockout: true. Needs Pillow.
"""
from PIL import Image, ImageDraw

ROWS = ['.####', '#....', '#..##', '#...#', '.###.']
UNITS, CELL, GAP, FRAME = 131.0, 24.0, 1.5, 2.5
CREAM, CROSS = (0xE7, 0xE1, 0xD3, 255), (0xEB, 0x7A, 0x52, 255)
SS = 8  # supersampling


def mark(size):
    px = size * SS
    u = px / UNITS
    im = Image.new('RGBA', (px, px), (0xE7, 0xE1, 0xD3, 0))
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, px, px], fill=CREAM)
    d.rectangle([FRAME * u, FRAME * u, (UNITS - FRAME) * u, (UNITS - FRAME) * u], fill=(0xE7, 0xE1, 0xD3, 0))
    for r in range(5):
        for c in range(5):
            if ROWS[r][c] == '#':
                x, y = (FRAME + c * (CELL + GAP)) * u, (FRAME + r * (CELL + GAP)) * u
                d.rectangle([x, y, x + CELL * u, y + CELL * u], fill=CREAM)
    cx = (FRAME + 1 * (CELL + GAP) + CELL / 2) * u
    cy = (FRAME + 2 * (CELL + GAP) + CELL / 2) * u
    h = 16 / 2 / 1.41421356 * u
    w = round(2.5 * u)
    d.line([cx - h, cy - h, cx + h, cy + h], fill=CROSS, width=w)
    d.line([cx + h, cy - h, cx - h, cy + h], fill=CROSS, width=w)
    return im.resize((size, size), Image.LANCZOS)


m = mark(512)
m.save('brand/splash/splash.png')
canvas = Image.new('RGBA', (1152, 1152), (0, 0, 0, 0))
canvas.paste(m, (320, 320))
canvas.save('brand/splash/android12.png')
