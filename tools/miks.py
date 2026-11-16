#!/usr/bin/env python3
"""Renders the effect bed of a busy fight with the game's own gains and prints where it sits against the music.
usage: python3 tools/miks.py [out base path] [name=target,...]   then measure the wavs with tools/lufs.sh
The optional second argument overrides target levels, to try a setting before writing it into audio.gd.
Rates: "busy" is a fight as the bot telemetry shows it, "max" is every effect at its minimum gap."""
import re, sys, wave, pathlib
import numpy as np

root = pathlib.Path(__file__).resolve().parent.parent
src = (root / "scripts" / "audio.gd").read_text()
sfx = {m[1]: (float(m[2]), float(m[3]), float(m[4])) for m in re.finditer(r'"(\w+)": \[(-?[\d.]+), (-?[\d.]+), ([\d.]+)\]', src)}
RATE = 44100

def load(name):
    with wave.open(str(root / "assets" / "audio" / (name + ".wav"))) as w:
        a = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(np.float64) / 32768.0
        if w.getnchannels() == 2:
            a = a.reshape(-1, 2).mean(axis=1)
        if w.getframerate() != RATE:
            a = np.interp(np.arange(0, len(a), w.getframerate() / RATE), np.arange(len(a)), a)
        return a

# the trims the game applies on top of the table when it plays each sound (fx.hit, the bee shot, weapon blasts)
EXTRA = {"hit": -3.0, "shoot": -6.0, "explosion": -5.0}

def bed(gaps, secs=20.0, extra=EXTRA):
    out = np.zeros(int(secs * RATE) + RATE)
    for name, gap in gaps.items():
        clip = load(name) * 10 ** ((sfx[name][1] - sfx[name][0] + extra.get(name, 0.0)) / 20.0)
        t = 0.0
        while t < secs:
            i = int(t * RATE)
            out[i:i + len(clip)] += clip[:len(out) - i]
            t += gap
    return out

def write(path, a):
    with wave.open(path, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(RATE)
        w.writeframes((np.clip(a, -1, 1) * 32767).astype(np.int16).tobytes())

base = sys.argv[1] if len(sys.argv) > 1 else "/var/tmp/kovan/miks"
if len(sys.argv) > 2:
    for pair in sys.argv[2].split(","):
        k, v = pair.split("=")
        sfx[k] = (sfx[k][0], float(v), sfx[k][2])
pathlib.Path(base).parent.mkdir(parents=True, exist_ok=True)
write(base + "_busy.wav", bed({"hit": 0.12, "kill": 0.14, "gem": 0.12, "shoot": 0.3, "explosion": 0.8}))
write(base + "_max.wav", bed({k: sfx[k][2] for k in ["hit", "kill", "gem", "shoot", "explosion"]}))
print("wrote", base + "_busy.wav", base + "_max.wav")
