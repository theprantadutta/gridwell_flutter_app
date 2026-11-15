"""Gridwell Play Store promo video, LANDSCAPE 1920x1080, light Tally look.

Captions on the left, the phone recording on the right. Square corners,
one accent (lime), no glows or gradients, matching the app's Tally design.
Adapted from Snake Classic's render_landscape.py.
Usage: python render_landscape.py <ffmpeg.exe> <scenes.json> <music> <out.mp4>
Recordings (rec*.mp4) and the PNGs this writes live next to this script.
"""

import json
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

D = Path(__file__).parent
ROOT = D.parents[2]
W, H = 1920, 1080
BG = (246, 248, 240)
SURFACE = (231, 235, 225)
INK = (13, 31, 22)
INK2 = (71, 91, 80)
LIME = (193, 238, 102)
ON_LIME = (15, 25, 12)
CORAL = (224, 92, 69)
SEA = (0, 128, 150)

INTRO, OUTRO, FADE = 3.0, 4.5, 0.3

PH = 960
PW = round(PH * 1080 / 2340 / 2) * 2
PX, PY = 1240, (H - PH) // 2
RADIUS = 40
CAP_X, CAP_W = 150, 940

CHIP_COLORS = {"lime": (LIME, ON_LIME), "ink": (INK, BG), "coral": (CORAL, (255, 255, 255)),
               "sea": (SEA, (255, 255, 255))}


def font(weight, size):
    return ImageFont.truetype(str(ROOT / "assets" / "fonts" / f"SchibstedGrotesk-{weight}.ttf"), size)


def wrap(draw, text, f, width):
    lines, cur = [], ""
    for word in text.split():
        trial = f"{cur} {word}".strip()
        if draw.textlength(trial, font=f) <= width:
            cur = trial
        else:
            lines.append(cur)
            cur = word
    return lines + [cur]


def spaced(draw, xy, text, f, fill, spacing, anchor="lm"):
    x, y = xy
    for ch in text:
        draw.text((x, y), ch, font=f, fill=fill, anchor=anchor)
        x += draw.textlength(ch, font=f) + spacing
    return x


def spaced_width(draw, text, f, spacing):
    return sum(draw.textlength(c, font=f) + spacing for c in text) - spacing


def chip(draw, x, y, label, color, size=30):
    fill, ink = CHIP_COLORS.get(color, CHIP_COLORS["lime"])
    f = font("Black", size)
    tw = spaced_width(draw, label, f, 5)
    h = size + 30
    draw.rectangle((x, y, x + tw + 48, y + h), fill=fill)
    spaced(draw, (x + 24, y + h / 2), label, f, ink, 5)
    return y + h


def caption_png(i, label, color, title, sub):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    ft, fs = font("Black", 88), font("Medium", 44)
    tlines = wrap(d, title, ft, CAP_W)
    slines = wrap(d, sub, fs, CAP_W - 40)[:3]
    block = 60 + 40 + len(tlines) * 100 + 30 + len(slines) * 60
    y = (H - block) // 2
    y = chip(d, CAP_X, y, label, color) + 40
    for line in tlines:
        d.text((CAP_X - 4, y), line, font=ft, fill=INK)
        y += 100
    y += 30
    for line in slines:
        d.text((CAP_X, y), line, font=fs, fill=INK2)
        y += 60
    p = D / f"lcap{i}.png"
    img.save(p)
    return p


def background(grid=True):
    img = Image.new("RGB", (W, H), BG)
    if grid:  # faint board grid behind the phone
        d = ImageDraw.Draw(img)
        for x in range(1080, W + 1, 60):
            d.line([(x, 0), (x, H)], fill=SURFACE, width=2)
        for y in range(0, H + 1, 60):
            d.line([(1080, y), (W, y)], fill=SURFACE, width=2)
    return img


def phone_assets():
    bg = background()
    ImageDraw.Draw(bg).rounded_rectangle(
        (PX - 12, PY - 12, PX + PW + 11, PY + PH + 11), radius=RADIUS + 12, fill=INK)
    bg.save(D / "lstage.png")
    mask = Image.new("L", (PW, PH), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, PW - 1, PH - 1), radius=RADIUS, fill=255)
    mask.save(D / "lmask.png")


def mark(size):
    return Image.open(ROOT / "brand" / "01-mark" / "png" / "gridwell-mark-light-1024.png").convert(
        "RGBA").resize((size, size), Image.LANCZOS)


def card(name, build):
    img = background(grid=False)
    build(img, ImageDraw.Draw(img))
    p = D / f"{name}.png"
    img.save(p)
    return p


def wordmark(d, x, y, size, center=False):
    """'Gridwell' with the lime-dot i, as in the app's wordmark. y is the baseline."""
    f = font("Black", size)
    text = "Grıdwell"
    w = d.textlength(text, font=f)
    if center:
        x -= w / 2
    d.text((x, y), text, font=f, fill=INK, anchor="ls")
    pre, iw = d.textlength("Gr", font=f), d.textlength("ı", font=f)
    r = size * 0.075
    cx, cy = x + pre + iw / 2, y - size * 0.80
    d.rectangle((cx - r, cy - r, cx + r, cy + r), fill=LIME)


def intro(img, d):
    m = mark(280)
    img.paste(m, ((W - 280) // 2, 200), m)
    wordmark(d, W / 2, 690, 150, center=True)
    f = font("Bold", 40)
    w = spaced_width(d, "NONOGRAM PUZZLES", f, 8)
    spaced(d, (W / 2 - w / 2, 790), "NONOGRAM PUZZLES", f, INK2, 8)


def outro(img, d):
    m = mark(200)
    img.paste(m, (180, 160), m)
    wordmark(d, 420, 320, 120)
    items = ["150 picture puzzles", "No guessing, ever", "Plays fully offline", "A new daily puzzle"]
    fi = font("Bold", 50)
    y = 470
    for t in items:
        d.rectangle((190, y, 228, y + 38), fill=LIME)
        d.text((265, y + 19), t, font=fi, fill=INK, anchor="lm")
        y += 95
    bw, bh, bx, by = 620, 150, 1140, 420
    d.rectangle((bx, by, bx + bw, by + bh), fill=LIME)
    f = font("Black", 58)
    w = spaced_width(d, "PLAY FREE", f, 6)
    spaced(d, (bx + bw / 2 - w / 2, by + bh / 2), "PLAY FREE", f, ON_LIME, 6)
    f2 = font("Bold", 36)
    w2 = spaced_width(d, "ON GOOGLE PLAY", f2, 8)
    spaced(d, (bx + bw / 2 - w2 / 2, by + bh + 64), "ON GOOGLE PLAY", f2, INK2, 8)


def main():
    ff, scenes_path, music, out = sys.argv[1:5]
    scenes = json.loads(Path(scenes_path).read_text(encoding="utf-8"))["segments"]
    phone_assets()
    caps = [caption_png(i, s["chip"], s.get("color", "lime"), s["title"], s["sub"])
            for i, s in enumerate(scenes)]
    intro_p, outro_p = card("lintro", intro), card("loutro", outro)

    durs = [s["b"] - s["a"] for s in scenes]
    demo_len = sum(durs)
    total = INTRO + demo_len + OUTRO

    srcs = sorted({s["src"] for s in scenes})
    inputs, idx = [], {}
    for sp in srcs:
        idx[sp] = len(inputs) // 2
        inputs += ["-i", str(D / sp)]
    n_src = len(srcs)
    inputs += ["-loop", "1", "-i", str(D / "lstage.png")]
    inputs += ["-i", str(D / "lmask.png")]
    inputs += ["-loop", "1", "-t", str(INTRO), "-i", str(intro_p)]
    inputs += ["-loop", "1", "-t", str(OUTRO), "-i", str(outro_p)]
    cap0 = n_src + 4
    for p, du in zip(caps, durs):
        inputs += ["-loop", "1", "-t", f"{du:.3f}", "-i", str(p)]
    music_i = cap0 + len(scenes)
    inputs += ["-i", music]

    fc = []
    uses = {sp: [i for i, s in enumerate(scenes) if s["src"] == sp] for sp in srcs}
    for sp, ids in uses.items():
        k = idx[sp]
        outs = "".join(f"[r{i}]" for i in ids)
        fc.append(f"[{k}:v]fps=30,split={len(ids)}{outs}" if len(ids) > 1 else f"[{k}:v]fps=30{outs}")
    for i, s in enumerate(scenes):
        fc.append(f"[r{i}]trim={s['a']}:{s['b']},setpts=PTS-STARTPTS[t{i}]")
    fc.append("".join(f"[t{i}]" for i in range(len(scenes))) + f"concat=n={len(scenes)}:v=1:a=0[rec]")
    fc.append(f"[rec]scale={PW}:{PH}:flags=lanczos,format=rgba[ph]")
    fc.append(f"[{n_src + 1}:v]format=gray[mk]")
    fc.append("[ph][mk]alphamerge[phr]")
    fc.append(f"[{n_src}:v]fps=30,trim=0:{demo_len:.3f},setpts=PTS-STARTPTS[stg]")
    fc.append(f"[stg][phr]overlay={PX}:{PY}:shortest=1[a0]")
    last, t = "a0", 0.0
    for i, du in enumerate(durs):
        fades = f"fade=in:st=0:d={FADE}:alpha=1,fade=out:st={du - FADE:.3f}:d={FADE}:alpha=1"
        fc.append(f"[{cap0 + i}:v]format=rgba,{fades},setpts=PTS-STARTPTS+{t:.3f}/TB[c{i}]")
        fc.append(f"[{last}][c{i}]overlay=0:0:eof_action=pass[b{i}]")
        last, t = f"b{i}", t + du
    fc.append(f"color=c=0xC1EE66:s={W}x8:r=30:d={demo_len:.3f}[bar]")
    fc.append(f"[{last}][bar]overlay=x='-{W}+{W}*t/{demo_len:.3f}':y={H - 8}:shortest=1,"
              f"format=yuv420p,setsar=1[demo]")
    fc.append(f"[{n_src + 2}:v]fps=30,format=yuv420p,fade=in:st=0:d=0.35:c=0xF6F8F0,"
              f"fade=out:st={INTRO - 0.35}:d=0.35:c=0xF6F8F0,setsar=1[in]")
    fc.append(f"[{n_src + 3}:v]fps=30,format=yuv420p,fade=in:st=0:d=0.35:c=0xF6F8F0,"
              f"fade=out:st={OUTRO - 0.6}:d=0.6,setsar=1[out]")
    fc.append("[in][demo][out]concat=n=3:v=1:a=0[v]")
    fc.append(f"[{music_i}:a]atrim=0:{total:.3f},asetpts=PTS-STARTPTS,volume=0.8,"
              f"afade=in:st=0:d=0.6,afade=out:st={total - 1.8:.3f}:d=1.8[aud]")

    cmd = [ff, "-hide_banner", "-loglevel", "error", "-y", *inputs, "-filter_complex", ";".join(fc),
           "-map", "[v]", "-map", "[aud]", "-t", f"{total:.2f}", "-c:v", "libx264", "-crf", "19",
           "-preset", "slow", "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "192k",
           "-movflags", "+faststart", out]
    subprocess.run(cmd, check=True)
    print("done", round(total, 2))


if __name__ == "__main__":
    main()
