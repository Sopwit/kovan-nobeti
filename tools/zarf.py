import sys, wave
import numpy as np
# Print a coarse loudness envelope (dB per 50 ms) and spectral centroid for each WAV.
for p in sys.argv[1:]:
    w = wave.open(p); sr = w.getframerate()
    a = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(np.float32) / 32768.0
    hop = sr // 20
    env = [20 * np.log10(np.sqrt(np.mean(a[i:i + hop] ** 2)) + 1e-6) for i in range(0, len(a) - hop, hop)]
    spec = np.abs(np.fft.rfft(a)); f = np.fft.rfftfreq(len(a), 1 / sr)
    cen = float((spec * f).sum() / (spec.sum() + 1e-9))
    print(p.split('/')[-1].ljust(16), 'centroid=%5d Hz' % cen, ' '.join('%d' % e for e in env[:24]))
