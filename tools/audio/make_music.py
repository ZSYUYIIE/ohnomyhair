"""Composes and renders the background music loops into assets/audio/music/<track>.wav.

Each track is a seamless loop (note and echo tails wrap round to the start), written as
chords + bass + drums + a generated melody over a fixed progression. The melody is made
from a seeded motif (chord tones on strong beats, scale steps between), repeated as
A A' B A' so it sounds composed rather than random. 32 kHz mono keeps the files small.

  menu   - cozy salon bossa, F major, 92 bpm        (title screen)
  calm   - bouncy, C major, 116 bpm                 (levels 1 and 3)
  tense  - scissor-ticking, A minor, 126 bpm        (level 2, the finale's first rooms)
  boss   - driving, E minor, 148 bpm                (the barber bot)

Run: python -I tools/audio/make_music.py
"""
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from synth import bandpass, highpass, lowpass, midi, noise, normalize, place, room, square, triangle, saw, sine, sweep, write_wav

SR = 32000
OUT = Path(__file__).resolve().parents[2] / "assets" / "audio" / "music"

MAJOR = [0, 2, 4, 5, 7, 9, 11]
MINOR = [0, 2, 3, 5, 7, 8, 10]


# --- instruments ----------------------------------------------------------------------

def _t(seconds):
    return np.arange(int(seconds * SR)) / SR


def adsr(seconds, a=0.01, d=0.2, s=0.6, r=0.08):
    n = int(seconds * SR)
    t = np.arange(n) / SR
    e = np.where(t < a, t / max(a, 1e-4), s + (1 - s) * np.exp(-(t - a) / d))
    rn = min(n, int(r * SR))
    e[-rn:] *= np.linspace(1, 0, rn)
    return e


def epiano(note, seconds, vel=1.0):
    f = midi(note)
    t = _t(seconds)
    body = np.sin(2 * np.pi * f * t) + 0.25 * np.sin(2 * np.pi * 2 * f * t)
    tine = 0.35 * np.sin(2 * np.pi * 4.02 * f * t) * np.exp(-t / 0.05)
    trem = 1 + 0.08 * np.sin(2 * np.pi * 4.5 * t)
    return (body + tine) * trem * adsr(seconds, 0.004, 0.6, 0.15, 0.12) * vel


def pluck(note, seconds, vel=1.0):
    f = midi(note)
    x = triangle(f, seconds, SR) + 0.3 * square(f, seconds, 0.3, SR)
    return lowpass(x, 2600, sr=SR) * adsr(seconds, 0.002, 0.12, 0.0, 0.03) * vel


def lead(note, seconds, vel=1.0, duty=0.25, bright=4200):
    f = midi(note)
    t = _t(seconds)
    vib = 1 + 0.006 * np.sin(2 * np.pi * 5.5 * t) * np.clip((t - 0.12) / 0.15, 0, 1)
    x = square(f * vib, seconds, duty, SR) * 0.8 + triangle(f * vib, seconds, SR) * 0.4
    return lowpass(x, bright, sr=SR) * adsr(seconds, 0.008, 0.25, 0.55, 0.06) * vel


def bass(note, seconds, vel=1.0, kind="tri"):
    f = midi(note)
    if kind == "saw":
        x = lowpass(saw(f, seconds, SR), 900, sr=SR) * 1.2 + sine(f, seconds, SR) * 0.4
    else:
        x = triangle(f, seconds, SR) * 0.9 + sine(f, seconds, SR) * 0.5
    return x * adsr(seconds, 0.005, 0.18, 0.5, 0.05) * vel


def kick(vel=1.0):
    s = 0.28
    return sine(sweep(150, 42, s, sr=SR), s, SR) * adsr(s, 0.002, 0.09, 0.0, 0.03) * vel


def snare(vel=1.0, seed=1):
    s = 0.18
    n = bandpass(noise(s, SR, seed), 1200, 7000, sr=SR) * adsr(s, 0.001, 0.05, 0.0, 0.03)
    body = sine(190, s, SR) * adsr(s, 0.001, 0.03, 0.0, 0.02)
    return (n * 0.9 + body * 0.5) * vel


def hat(vel=1.0, open_=False, seed=2):
    s = 0.2 if open_ else 0.045
    return highpass(noise(s, SR, seed), 7000, sr=SR) * adsr(s, 0.001, 0.08 if open_ else 0.012, 0.0, 0.01) * vel


def brush(vel=1.0, seed=3):
    s = 0.12
    return bandpass(noise(s, SR, seed), 2500, 9000, sr=SR) * adsr(s, 0.01, 0.04, 0.0, 0.03) * vel


def snip_tick(vel=1.0, seed=4):
    """A scissor snip as percussion (the tense track's signature)."""
    s = 0.07
    click = bandpass(noise(s, SR, seed), 3500, 10000, sr=SR) * adsr(s, 0.001, 0.01, 0.0, 0.01)
    ring = sine(3100, s, SR) * adsr(s, 0.001, 0.02, 0.0, 0.01) * 0.25
    return (click + ring) * vel


# --- composition ----------------------------------------------------------------------

class Track:
    def __init__(self, bpm, bars, key, scale, chords, seed):
        self.bpm, self.bars, self.key, self.scale, self.chords = bpm, bars, key, scale, chords
        self.beat = 60.0 / bpm
        self.step = self.beat / 4  # 16th
        self.length = self.beat * 4 * bars
        self.buf = {name: np.zeros(int(self.length * SR)) for name in ("chords", "bass", "lead", "drums")}
        self.rng = np.random.default_rng(seed)

    def at(self, bar, step):
        return (bar * 16 + step) * self.step

    def chord(self, bar):
        return self.chords[bar % len(self.chords)]

    def add(self, part, x, bar, step, gain=1.0):
        place(self.buf[part], x, self.at(bar, step), gain, SR)

    def degree_note(self, degree, octave):
        """Scale degree (0-based, may exceed 6) -> MIDI note in this key."""
        o, d = divmod(degree, 7)
        return self.key + 12 * (octave + o) + self.scale[d]

    def chord_tones(self, bar):
        root = self.chord(bar)
        return [root, root + 2, root + 4]  # triad degrees

    def melody(self, rhythm_a, rhythm_b, octave=1, inst=lead, gain=0.32, **kw):
        """A A' B A' over the progression; each phrase is two bars of 16ths."""
        def phrase(bar0, rhythm, vary):
            prev = None
            notes = []
            for bar_off in range(2):
                bar = bar0 + bar_off
                tones = self.chord_tones(bar)
                for step, length in rhythm[bar_off]:
                    strong = step % 4 == 0
                    if strong or prev is None:
                        cands = [t + 7 * k for t in tones for k in (0, 1)]
                    else:
                        cands = [prev - 1, prev + 1, prev + 2, prev - 2]
                    cands = [c for c in cands if 0 <= c <= 9]  # about an octave and a half
                    if prev is not None:
                        cands.sort(key=lambda c: abs(c - prev) + self.rng.uniform(0, 1.6))
                        deg = cands[0] if self.rng.uniform() > 0.25 else cands[min(1, len(cands) - 1)]
                    else:
                        deg = cands[self.rng.integers(len(cands))]
                    if vary and bar_off == 1 and step == rhythm[1][-1][0]:
                        deg = tones[0]  # resolve the varied phrase on the root
                    prev = deg
                    notes.append((bar, step, length, deg))
            return notes

        a = phrase(0, rhythm_a, False)
        a2 = phrase(0, rhythm_a, True)
        b = phrase(0, rhythm_b, False)
        plan = [a, a2, b, a2]
        for rep in range(self.bars // 8):
            for i, ph in enumerate(plan):
                for bar, step, length, deg in ph:
                    target_bar = rep * 8 + i * 2 + bar
                    note = self.degree_note(deg, octave)
                    self.add("lead", inst(note, length * self.step * 0.95, **kw), target_bar, step, gain)

    def render(self, levels, reverb=(0.06, 0.2)):
        out = np.zeros(int(self.length * SR))
        for part, buf in self.buf.items():
            out += buf * levels.get(part, 1.0)
        wet = room(out, reverb[0], reverb[1], SR)
        loop = wet[:len(out)].copy()
        tail = wet[len(out):]
        loop[:len(tail)] += tail  # reverb tail wraps into the loop start
        loop = highpass(loop, 35, sr=SR)
        # Gentle soft-clip so peaks stay round.
        loop = np.tanh(normalize(loop, 1.0) * 1.2) / np.tanh(1.2)
        return normalize(loop, 0.82)


def rhythm(*bars):
    """bars of (step, length-in-16ths)."""
    return [list(b) for b in bars]


# --- tracks -----------------------------------------------------------------------------

def menu():
    # Fmaj7 Dm7 Gm7 C7 (degrees I vi ii V), bossa: brushes, epiano comping, walking bass.
    tr = Track(92, 16, 65, MAJOR, [0, 5, 1, 4], seed=11)
    for bar in range(tr.bars):
        root = tr.chord(bar)
        voicing = [tr.degree_note(root + k, 0) for k in (0, 2, 4, 6)]  # 7th chords
        for step, vel in ((0, 0.8), (6, 0.55), (10, 0.65)):
            for n in voicing:
                tr.add("chords", epiano(n, tr.step * 5, vel), bar, step, 0.22)
        for step, deg in ((0, 0), (6, 4), (8, 2), (14, 4)):
            tr.add("bass", bass(tr.degree_note(root + deg, -1), tr.step * 3.5, 0.9), bar, step, 0.45)
        for step in range(0, 16, 2):
            tr.add("drums", brush(0.5 if step % 4 else 0.8, seed=bar * 16 + step), bar, step, 0.35)
        tr.add("drums", kick(0.5), bar, 0, 0.6)
        tr.add("drums", kick(0.4), bar, 10, 0.6)
    tr.melody(rhythm([(0, 3), (4, 2), (6, 2), (10, 6)], [(0, 4), (6, 2), (8, 8)]),
              rhythm([(2, 2), (4, 2), (6, 2), (8, 4), (12, 4)], [(0, 6), (8, 2), (10, 6)]),
              octave=0, inst=epiano, gain=0.3)
    return tr.render({"chords": 1.0, "bass": 1.0, "lead": 0.9, "drums": 0.8}, (0.07, 0.28))


def calm():
    # C G Am F (I V vi IV), bouncy plucks, square lead, four-on-the-floor-lite.
    tr = Track(116, 16, 60, MAJOR, [0, 4, 5, 3], seed=21)
    for bar in range(tr.bars):
        root = tr.chord(bar)
        triad = [tr.degree_note(root + k, 0) for k in (0, 2, 4)]
        for step in (2, 6, 10, 14):
            for n in triad:
                tr.add("chords", pluck(n, tr.step * 2, 0.8), bar, step, 0.2)
        for step, deg, ln in ((0, 0, 3), (4, 4, 2), (8, 0, 3), (12, 4, 2), (14, 5, 2)):
            tr.add("bass", bass(tr.degree_note(root + deg, -1), tr.step * ln, 1.0), bar, step, 0.45)
        tr.add("drums", kick(0.9), bar, 0, 0.7)
        tr.add("drums", kick(0.7), bar, 8, 0.7)
        tr.add("drums", snare(0.7, bar), bar, 4, 0.45)
        tr.add("drums", snare(0.7, bar + 99), bar, 12, 0.45)
        for step in range(2, 16, 4):
            tr.add("drums", hat(0.6, seed=bar * 7 + step), bar, step, 0.3)
    tr.melody(rhythm([(0, 2), (2, 2), (4, 4), (10, 2), (12, 4)], [(0, 2), (2, 2), (4, 2), (6, 2), (8, 8)]),
              rhythm([(0, 3), (3, 1), (4, 4), (8, 3), (11, 1), (12, 4)], [(0, 4), (4, 4), (8, 8)]),
              octave=1, inst=lead, gain=0.28, duty=0.25)
    return tr.render({"chords": 1.0, "bass": 1.0, "lead": 1.0, "drums": 0.9})


def tense():
    # Am F C G (i VI III VII) with ticking scissor snips on the 16ths.
    tr = Track(126, 16, 57, MINOR, [0, 5, 2, 6], seed=31)
    for bar in range(tr.bars):
        root = tr.chord(bar)
        for step in range(0, 16, 2):
            deg = 0 if step % 8 < 6 else 4
            tr.add("bass", bass(tr.degree_note(root + deg, -1), tr.step * 1.6, 0.9, kind="saw"), bar, step, 0.42)
        for n in [tr.degree_note(root + k, 0) for k in (0, 2, 4)]:
            tr.add("chords", lead(n, tr.step * 14, 0.5, duty=0.5, bright=1500), bar, 0, 0.1)
        for step in range(16):
            v = 0.9 if step % 4 == 2 else 0.45
            tr.add("drums", snip_tick(v, seed=bar * 16 + step), bar, step, 0.28)
        tr.add("drums", kick(1.0), bar, 0, 0.7)
        tr.add("drums", kick(0.8), bar, 6, 0.6)
        tr.add("drums", kick(0.8), bar, 10, 0.6)
        tr.add("drums", snare(0.8, bar), bar, 4, 0.45)
        tr.add("drums", snare(0.8, bar + 50), bar, 12, 0.45)
    tr.melody(rhythm([(0, 2), (3, 1), (4, 4), (12, 2), (14, 2)], [(0, 6), (8, 2), (10, 2), (12, 4)]),
              rhythm([(0, 1), (2, 1), (4, 2), (6, 2), (8, 6)], [(0, 3), (3, 3), (6, 2), (8, 8)]),
              octave=1, inst=lead, gain=0.26, duty=0.125, bright=3600)
    return tr.render({"chords": 1.0, "bass": 1.0, "lead": 1.0, "drums": 1.0}, (0.05, 0.15))


def boss():
    # Em C D Em / Am C B7: driving 8th bass, four-on-the-floor, snips on the off-beats.
    tr = Track(148, 16, 52, MINOR, [0, 5, 6, 0, 3, 5, 4, 4], seed=41)
    for bar in range(tr.bars):
        root = tr.chord(bar)
        for step in range(0, 16, 2):
            oct_ = -1 if step % 4 == 0 else 0
            tr.add("bass", bass(tr.degree_note(root, oct_), tr.step * 1.7, 1.0, kind="saw"), bar, step, 0.45)
        for n in [tr.degree_note(root + k, 1) for k in (0, 2, 4)]:
            for step in (0, 3, 6, 10):
                tr.add("chords", lead(n, tr.step * 1.5, 0.6, duty=0.5, bright=2500), bar, step, 0.08)
        for step in (0, 4, 8, 12):
            tr.add("drums", kick(1.0), bar, step, 0.75)
        tr.add("drums", snare(1.0, bar), bar, 4, 0.5)
        tr.add("drums", snare(1.0, bar + 70), bar, 12, 0.5)
        for step in range(2, 16, 4):
            tr.add("drums", hat(0.8, open_=True, seed=bar * 5 + step), bar, step, 0.22)
            tr.add("drums", snip_tick(0.8, seed=bar * 3 + step), bar, step + 1, 0.22)
    tr.melody(rhythm([(0, 3), (3, 3), (6, 2), (8, 4), (12, 4)], [(0, 2), (2, 2), (4, 4), (8, 8)]),
              rhythm([(0, 4), (4, 2), (6, 2), (8, 2), (10, 2), (12, 4)], [(0, 6), (6, 2), (8, 8)]),
              octave=1, inst=lead, gain=0.3, duty=0.25, bright=5200)
    return tr.render({"chords": 1.0, "bass": 1.0, "lead": 1.0, "drums": 1.0}, (0.05, 0.14))


TRACKS = {"menu": menu, "calm": calm, "tense": tense, "boss": boss}


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    only = sys.argv[1:]
    for name, fn in TRACKS.items():
        if only and name not in only:
            continue
        x = fn()
        write_wav(OUT / f"{name}.wav", x, SR)
        print(f"{name:6s} {len(x) / SR:5.1f}s loop")


if __name__ == "__main__":
    main()
