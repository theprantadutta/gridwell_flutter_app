"""YouTube thumbnail (1280x720) from the Play feature graphic (1024x500).

The feature graphic is left untouched. Its art is scaled to 1280 wide and laid
over a blurred, darkened copy of itself, with the top and bottom edges
feathered in, so the 16:9 frame has no bars or stretched streaks. Same method
as Snake Classic's thumb.py. Run from the app root: python store_listings/play-store-video/tools/thumb.py
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[3]
SRC = ROOT / "brand" / "store" / "feature-graphic" / "gridwell-feature-graphic-1024x500.png"
OUT = ROOT / "store_listings" / "play-store-video" / "youtube-thumbnail-1280x720.png"
W, H = 1280, 720
FEATHER = 70
BG = (7, 26, 19)  # Tally green, the feature graphic's own ground

src = Image.open(SRC).convert("RGB")
scaled = src.resize((W, round(src.height * W / src.width)), Image.LANCZOS)  # 1280x625
top = (H - scaled.height) // 2

base = scaled.filter(ImageFilter.GaussianBlur(80)).resize((W, H), Image.LANCZOS)
base = Image.blend(base, Image.new("RGB", (W, H), BG), 0.35)

mask = Image.new("L", scaled.size, 255)
md = ImageDraw.Draw(mask)
for i in range(FEATHER):
    a = round(255 * (i / FEATHER) ** 1.4)
    md.line([(0, i), (W, i)], fill=a)
    md.line([(0, scaled.height - 1 - i), (W, scaled.height - 1 - i)], fill=a)
base.paste(scaled, (0, top), mask)
base.save(OUT, optimize=True)
print(OUT, base.size)
