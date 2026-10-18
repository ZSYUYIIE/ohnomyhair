"""Tiny synthesizer for the game's sound effects and music (numpy + scipy, no samples).

Everything is made from oscillators, noise, envelopes and a few filters, so the sounds
are ours, reproducible and easy to tweak: change a number, rerun the generator.
Used by make_sfx.py and make_music.py.
"""
import wave

import numpy as np
from scipy import signal

SR = 44100


def t_axis(seconds, sr=SR):
    return np.arange(int(seconds * sr)) / sr


# --- oscillators ------------------------------------------------------------------

def phase_of(freq, seconds, sr=SR):
    """Phase (cycles) for a constant or per-sample frequency."""
    n = int(seconds * sr)
    f = np.broadcast_to(np.asarray(freq, dtype=float), (n,)) if np.ndim(freq) == 0 else np.asarray(freq, dtype=float)[:n]
    return np.cumsum(f) / sr


def sine(freq, seconds, sr=SR):
    return np.sin(2 * np.pi * phase_of(freq, seconds, sr))


def square(freq, seconds, duty=0.5, sr=SR):
    ph = phase_of(freq, seconds, sr) % 1.0
    # Centred on zero: a narrow pulse would otherwise carry a DC offset.
    return (np.where(ph < duty, 1.0, -1.0) - (2 * duty - 1)) * 0.7


def triangle(freq, seconds, sr=SR):
    ph = phase_of(freq, seconds, sr) % 1.0
    return 4 * np.abs(ph - 0.5) - 1


def saw(freq, seconds, sr=SR):
    ph = phase_of(freq, seconds, sr) % 1.0
    return (2 * ph - 1) * 0.6


def noise(seconds, sr=SR, seed=0):
    return np.random.default_rng(seed).uniform(-1, 1, int(seconds * sr))


def sweep(f0, f1, seconds, curve="exp", sr=SR):
    """Per-sample frequency gliding from f0 to f1."""
    x = np.linspace(0, 1, int(seconds * sr))
    if curve == "exp":
        return f0 * (f1 / f0) ** x
    return f0 + (f1 - f0) * x


# --- envelopes & filters ----------------------------------------------------------

def env(seconds, attack=0.005, decay=None, sustain=1.0, release=0.05, sr=SR):
    """Linear attack, exponential decay to sustain, linear release at the end."""
    n = int(seconds * sr)
    out = np.ones(n) * sustain
    a = max(1, int(attack * sr))
    out[:a] = np.linspace(0, 1, a)
    if decay:
        d = np.arange(n - a) / sr
        out[a:] = sustain + (1 - sustain) * np.exp(-d / decay)
    r = min(n, max(1, int(release * sr)))
    out[-r:] *= np.linspace(1, 0, r)
    return out


def perc(seconds, decay, attack=0.002, sr=SR):
    """Percussive: quick attack, exponential decay to silence."""
    return env(seconds, attack=attack, decay=decay, sustain=0.0, release=min(0.02, seconds / 4), sr=sr)


def lowpass(x, cutoff, order=2, sr=SR):
    b, a = signal.butter(order, min(cutoff, sr * 0.45) / (sr / 2), "low")
    return signal.lfilter(b, a, x)


def highpass(x, cutoff, order=2, sr=SR):
    b, a = signal.butter(order, cutoff / (sr / 2), "high")
    return signal.lfilter(b, a, x)


def bandpass(x, lo, hi, order=2, sr=SR):
    b, a = signal.butter(order, [lo / (sr / 2), min(hi, sr * 0.45) / (sr / 2)], "band")
    return signal.lfilter(b, a, x)


def echo(x, delay=0.09, feedback=0.35, taps=3, sr=SR):
    d = int(delay * sr)
    out = np.concatenate([x, np.zeros(d * taps)])
    for k in range(1, taps + 1):
        out[d * k:d * k + len(x)] += x * feedback ** k
    return out


def room(x, size=0.06, mix=0.18, sr=SR):
    """A small, cheap 'salon' reverb: a few comb echoes, low-passed."""
    wet = np.zeros(len(x) + int(size * 6 * sr))
    for k, (d, g) in enumerate(((1.0, 0.5), (1.37, 0.4), (1.79, 0.32), (2.33, 0.25), (3.1, 0.17))):
        off = int(size * d * sr)
        wet[off:off + len(x)] += x * g
    wet = lowpass(wet, 3500)
    dry = np.concatenate([x, np.zeros(len(wet) - len(x))])
    return dry * (1 - mix) + wet * mix


def mix(*parts):
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[:len(p)] += p
    return out


def place(buf, x, at_seconds, gain=1.0, sr=SR):
    """Add x into buf starting at at_seconds (wraps past the end, for seamless loops)."""
    i = int(at_seconds * sr) % len(buf)
    end = i + len(x)
    if end <= len(buf):
        buf[i:end] += x * gain
    else:
        k = len(buf) - i
        buf[i:] += x[:k] * gain
        rest = x[k:] * gain
        while len(rest):
            m = min(len(rest), len(buf))
            buf[:m] += rest[:m]
            rest = rest[m:]


def normalize(x, peak=0.89):
    m = np.max(np.abs(x)) or 1.0
    return x * (peak / m)


def fade(x, fin=0.003, fout=0.01, sr=SR):
    a, b = int(fin * sr), int(fout * sr)
    x = x.copy()
    if a:
        x[:a] *= np.linspace(0, 1, a)
    if b:
        x[-b:] *= np.linspace(1, 0, b)
    return x


def write_wav(path, x, sr=SR):
    data = (np.clip(x, -1, 1) * 32767).astype("<i2")
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(data.tobytes())


def midi(note):
    return 440.0 * 2 ** ((note - 69) / 12)
