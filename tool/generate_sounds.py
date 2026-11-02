"""Synthesizes Gridwell's sounds into assets/sounds/.

The sound is part of the calm: every fill is a note, not a click.

- Fills pluck a soft kalimba-like tine from the D major pentatonic scale.
  A dragged run walks up the scale, so painting a line plays a little
  melody. Pentatonic has no clashing intervals: any run sounds consonant.
- Crosses are the same scale an octave lower, muted and short, like a
  finger resting on the tine.
- A finished line plays a gentle rolled chord; the puzzle's completion
  plays a short phrase that resolves home to D.
- A proven mistake is a low, soft wooden knock: noticeable, never harsh.

A small synthetic room reverb gives every sound the same quiet space.
Deterministic, so the committed WAVs regenerate exactly:

    python tool/generate_sounds.py
"""
import math
import os
import random
import struct
import wave

RATE = 22050
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'sounds')

# D major pentatonic: D E F# A B, across two octaves (D5..E6..).
SCALE_HZ = [587.33, 659.25, 739.99, 880.00, 987.77, 1174.66, 1318.51, 1479.98]


def write(name, samples, level=0.7):
    os.makedirs(OUT, exist_ok=True)
    peak = max(1e-9, max(abs(s) for s in samples))
    scale = level / peak
    with wave.open(os.path.join(OUT, name), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b''.join(
            struct.pack('<h', int(max(-1.0, min(1.0, s * scale)) * 32767)) for s in samples))


def reverb(dry, wet=0.22, tail=0.9):
    """A tiny Schroeder reverb: parallel combs into series allpasses."""
    n = len(dry) + int(RATE * tail)
    x = dry + [0.0] * (n - len(dry))
    combs = [(0.0297, 0.77), (0.0371, 0.75), (0.0411, 0.73), (0.0437, 0.71)]
    acc = [0.0] * n
    for delay_s, fb in combs:
        d = int(RATE * delay_s)
        buf = [0.0] * n
        for i in range(n):
            buf[i] = x[i] + (buf[i - d] * fb if i >= d else 0.0)
            acc[i] += buf[i] / len(combs)
    for delay_s, g in [(0.005, 0.7), (0.0017, 0.7)]:
        d = int(RATE * delay_s)
        out = [0.0] * n
        for i in range(n):
            xd = acc[i - d] if i >= d else 0.0
            yd = out[i - d] if i >= d else 0.0
            out[i] = -g * acc[i] + xd + g * yd
        acc = out
    return [x[i] * (1 - wet) + acc[i] * wet for i in range(n)]


def tine(freq, length, decay, brightness=1.0, seed=0, muted=False):
    """A kalimba-like pluck: fundamental, an inharmonic tine partial that dies
    fast, and a soft attack transient."""
    rnd = random.Random(seed)
    n = int(RATE * length)
    out = []
    lp = 0.0
    for i in range(n):
        t = i / RATE
        attack = min(1.0, t / 0.003)
        body = math.exp(-t / decay)
        v = math.sin(2 * math.pi * freq * t)
        # The metallic "ping": partial near 5.4x that fades in ~40 ms.
        v += 0.28 * brightness * math.sin(2 * math.pi * freq * 5.4 * t) * math.exp(-t / 0.04)
        v += 0.12 * math.sin(2 * math.pi * freq * 2 * t) * math.exp(-t / (decay * 0.5))
        # A breath of thumb-on-tine noise at the very start.
        lp += 0.3 * (rnd.uniform(-1, 1) - lp)
        v += 0.25 * lp * math.exp(-t / 0.006)
        if muted:
            body *= math.exp(-t / 0.05)
        out.append(attack * body * v)
    return out


def mix(parts, length):
    n = int(RATE * length)
    out = [0.0] * n
    for start_s, samples, gain in parts:
        s = int(RATE * start_s)
        for i, v in enumerate(samples):
            if s + i < n:
                out[s + i] += v * gain
    return out


def knock(length):
    n = int(RATE * length)
    rnd = random.Random(9)
    out = []
    lp = 0.0
    for i in range(n):
        t = i / RATE
        f = 196 - 40 * min(1.0, t / 0.08)
        lp += 0.15 * (rnd.uniform(-1, 1) - lp)
        v = math.sin(2 * math.pi * f * t) * math.exp(-t / 0.045) + 0.6 * lp * math.exp(-t / 0.012)
        out.append(min(1.0, t / 0.002) * v)
    return out


def main():
    # Fill notes: one file per scale degree; the game walks up the scale.
    for k, f in enumerate(SCALE_HZ):
        write(f'fill_{k}.wav', reverb(tine(f, 0.7, 0.32, seed=k), wet=0.18, tail=0.5), level=0.6)
    # Cross notes: an octave lower, muted.
    for k, f in enumerate(SCALE_HZ):
        write(f'cross_{k}.wav', tine(f / 2, 0.18, 0.12, brightness=0.4, seed=20 + k, muted=True), level=0.45)

    # Line complete: a rolled D major add9 chord (D A F# E), soft.
    chord = [(0.000, 1174.66), (0.045, 880.00), (0.090, 1479.98), (0.135, 1318.51)]
    line = mix([(s, tine(f, 1.0, 0.45, seed=40 + i), 0.8) for i, (s, f) in enumerate(chord)], 1.2)
    write('line.wav', reverb(line, wet=0.25, tail=0.8), level=0.55)

    # Completion: a short phrase that climbs and resolves home.
    phrase = [
        (0.00, 587.33), (0.16, 739.99), (0.32, 880.00), (0.48, 1174.66),
        (0.72, 987.77), (0.88, 1174.66), (1.10, 1479.98),
        (1.10, 880.00), (1.10, 587.33),  # final chord
    ]
    complete = mix([(s, tine(f, 1.6 if s >= 1.1 else 0.9, 0.7 if s >= 1.1 else 0.35, seed=60 + i),
                     0.7 if s >= 1.1 else 0.85) for i, (s, f) in enumerate(phrase)], 2.6)
    write('complete.wav', reverb(complete, wet=0.3, tail=1.4), level=0.65)

    write('mistake.wav', reverb(knock(0.2), wet=0.15, tail=0.3), level=0.5)
    write('tap.wav', tine(1174.66, 0.08, 0.03, brightness=0.3, seed=99, muted=True), level=0.35)


if __name__ == '__main__':
    main()
