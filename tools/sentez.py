"""Synthesise the short gameplay sound effects as mono 16-bit WAV files."""
import sys, wave
import numpy as np
from scipy.signal import butter, lfilter

SR = 44100
rng = np.random.default_rng(7)

def t(d): return np.arange(int(SR * d)) / SR
def env(n, a=0.003, k=18.0):
    x = np.arange(n) / SR
    return np.minimum(1.0, x / a) * np.exp(-k * x)
def sweep(d, f0, f1, shape=1.0):
    x = t(d); f = f0 + (f1 - f0) * (x / d) ** shape
    return np.sin(2 * np.pi * np.cumsum(f) / SR)
def noise(d): return rng.uniform(-1, 1, int(SR * d))
def bp(x, lo, hi):
    b, a = butter(2, [lo / (SR / 2), hi / (SR / 2)], btype='band'); return lfilter(b, a, x)
def lp(x, hi):
    b, a = butter(2, hi / (SR / 2)); return lfilter(b, a, x)
def save(name, x, peak=0.85):
    x = x / (np.max(np.abs(x)) + 1e-9) * peak
    n = len(x); f = min(n, int(SR * 0.01)); x[-f:] *= np.linspace(1, 0, f)
    w = wave.open(f"{sys.argv[1]}/{name}.wav", 'wb'); w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
    w.writeframes((x * 32767).astype(np.int16).tobytes()); w.close()

# pickup: two quick bell tones
a = np.sin(2 * np.pi * 1320 * t(0.16)) + 0.5 * np.sin(2 * np.pi * 2640 * t(0.16))
b = np.sin(2 * np.pi * 1760 * t(0.16)) + 0.5 * np.sin(2 * np.pi * 3520 * t(0.16))
g = np.zeros(int(SR * 0.22)); g[:len(a)] += a * env(len(a), k=26); o = int(SR * 0.055); g[o:o + len(b)] += b * env(len(b), k=22)
save('gem', g, 0.6)
# enemy pop
k = sweep(0.11, 620, 110, 0.6) * env(int(SR * 0.11), k=30) + 0.5 * bp(noise(0.11), 900, 5000) * env(int(SR * 0.11), k=60)
save('kill', k, 0.8)
# soft hit
h = sweep(0.07, 320, 120) * env(int(SR * 0.07), k=45) + 0.7 * bp(noise(0.07), 1500, 7000) * env(int(SR * 0.07), k=90)
save('hit', h, 0.7)
# spark
z = np.sign(sweep(0.2, 2400, 300, 0.5)) * 0.4 + bp(noise(0.2), 2500, 9000)
z *= env(len(z), k=16) * (0.6 + 0.4 * np.sign(np.sin(2 * np.pi * 55 * t(0.2))))
save('zap', z, 0.7)
# jump: rising whoosh
j = 0.6 * sweep(0.17, 240, 620, 0.7) * env(int(SR * 0.17), a=0.01, k=14) + bp(noise(0.17), 700, 3500) * np.sin(np.pi * t(0.17) / 0.17) * 0.5
save('jump', j, 0.6)
# landing thump
l = sweep(0.16, 130, 55) * env(int(SR * 0.16), k=22) + 0.5 * lp(noise(0.16), 900) * env(int(SR * 0.16), k=40)
save('land', l, 0.8)
# slide: grass swoosh
s = bp(noise(0.42), 500, 4200) * np.sin(np.pi * (t(0.42) / 0.42) ** 0.6) ** 2
s += 0.4 * bp(noise(0.42), 2500, 8000) * np.exp(-9 * t(0.42))
save('slide', s, 0.7)
# enemy spit
p = sweep(0.16, 900, 220, 0.5) * env(int(SR * 0.16), k=18) + 0.5 * bp(noise(0.16), 600, 2600) * env(int(SR * 0.16), k=28)
save('spit', p, 0.6)
# player hurt
u = np.tanh(3 * sweep(0.24, 170, 60)) * env(int(SR * 0.24), k=13) + 0.8 * bp(noise(0.24), 300, 2200) * env(int(SR * 0.24), k=30)
save('hurt', u, 0.9)
# warning horn for elites and the boss
x = t(0.9); horn = (np.sign(np.sin(2 * np.pi * 147 * x)) * 0.5 + np.sin(2 * np.pi * 220.5 * x)) * np.minimum(1, x / 0.05) * np.minimum(1, (0.9 - x) / 0.25)
save('horn', lp(horn, 1800), 0.7)
print('ok')
# level up: rising bell arpeggio
notes = [523.25, 659.25, 783.99, 1046.5, 1318.5]
lv = np.zeros(int(SR * 1.1))
for i, f in enumerate(notes):
    d = 0.6; x = t(d); tone = (np.sin(2 * np.pi * f * x) + 0.4 * np.sin(2 * np.pi * 2 * f * x) + 0.2 * np.sin(2 * np.pi * 3 * f * x)) * env(len(x), k=7)
    o = int(SR * 0.075 * i); n = min(len(tone), len(lv) - o); lv[o:o + n] += tone[:n]
save('levelup', lv, 0.75)
