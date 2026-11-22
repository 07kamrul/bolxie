#!/usr/bin/env python3
"""Generates placeholder sound effects into assets/audio/. Replace freely."""
import math
import struct
import wave
from pathlib import Path

RATE = 22050
OUT = Path(__file__).resolve().parent.parent / "assets" / "audio"


def tone(freqs, dur, vol=0.4, decay=6.0):
    n = int(RATE * dur)
    out = []
    for i in range(n):
        t = i / RATE
        f = freqs[min(int(i / n * len(freqs)), len(freqs) - 1)]
        out.append(int(32767 * vol * math.exp(-decay * t / dur)
                       * math.sin(2 * math.pi * f * t)))
    return out


def save(name, samples):
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", s) for s in samples))


save("place.wav", tone([330], 0.08))
save("clear.wav", tone([523, 659, 784], 0.25))
save("combo.wav", tone([523, 659, 784, 1046], 0.4))
save("game_over.wav", tone([392, 330, 262, 196], 0.7, decay=3.0))
