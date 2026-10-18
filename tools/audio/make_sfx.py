"""Synthesizes every sound effect into assets/audio/sfx/<name>.wav (44.1 kHz mono).

Doodle-salon palette: soft boingy movement, metallic scissor "shing"s, a buzzing clipper,
squelchy gel, a bright service bell. Each sound is a short recipe below; change a number
and rerun. The game plays them through Sound.play("<name>") (scenes/systems/sound.gd).
Run: python -I tools/audio/make_sfx.py
"""
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))  # synth.py lives next to this file
from synth import (SR, bandpass, echo, env, fade, highpass, lowpass, midi, mix, noise, normalize,
                   perc, room, saw, sine, square, sweep, t_axis, triangle, write_wav)

OUT = Path(__file__).resolve().parents[2] / "assets" / "audio" / "sfx"
SOUNDS = {}


def sound(fn):
    SOUNDS[fn.__name__] = fn
    return fn


def blip(f0, f1, seconds, wave=square, duty=0.5, decay=0.08):
    f = sweep(f0, f1, seconds)
    osc = wave(f, seconds, duty) if wave is square else wave(f, seconds)
    return osc * perc(seconds, decay)


def metal(freq, seconds, decay=0.12, seed=1):
    """Inharmonic partials: a scissor blade / bell-ish ring."""
    t = t_axis(seconds)
    rng = np.random.default_rng(seed)
    out = np.zeros(len(t))
    for ratio, g in ((1.0, 1.0), (2.76, 0.6), (5.4, 0.4), (8.93, 0.25)):
        f = freq * ratio * (1 + rng.uniform(-0.004, 0.004))
        out += g * np.sin(2 * np.pi * f * t) * np.exp(-t / (decay / ratio ** 0.4))
    return out


def snip(seconds=0.09, pitch=5200, seed=3):
    """One scissor snip: a click of filtered noise plus a short metallic ring."""
    click = bandpass(noise(seconds, seed=seed), pitch * 0.6, pitch * 1.6) * perc(seconds, 0.012)
    return click * 1.4 + metal(pitch * 0.55, seconds, 0.03, seed) * 0.25


# --- movement -------------------------------------------------------------------------

@sound
def jump():
    return blip(330, 620, 0.13, square, 0.25, 0.07) * 0.6 + blip(165, 310, 0.13, triangle, decay=0.08) * 0.5


@sound
def land():
    s = 0.09
    thud = sine(sweep(140, 60, s), s) * perc(s, 0.03)
    dust = lowpass(noise(s, seed=4), 900) * perc(s, 0.025) * 0.6
    return thud + dust


@sound
def glide():
    s = 0.35  # a soft whoosh of hair opening up
    n = bandpass(noise(s, seed=5), 500, 2400) * env(s, attack=0.08, decay=0.15, sustain=0.2, release=0.1)
    return n * 0.9


@sound
def grab():
    return mix(blip(520, 380, 0.09, triangle, decay=0.05), blip(780, 600, 0.06, square, 0.3, 0.03) * 0.3)


@sound
def launch():
    s = 0.32  # boing
    f = 180 * (1 + 1.6 * (1 - np.exp(-t_axis(s) / 0.05))) * (1 + 0.06 * np.sin(2 * np.pi * 18 * t_axis(s)))
    return triangle(f, s) * perc(s, 0.16) + square(f * 2, s, 0.2) * perc(s, 0.06) * 0.2


@sound
def dash():
    s = 0.22
    whoosh = bandpass(noise(s, seed=6), 900, 5000) * env(s, attack=0.01, decay=0.06, sustain=0.0, release=0.05)
    zip_ = saw(sweep(260, 900, s), s) * perc(s, 0.05) * 0.35
    return whoosh * 1.1 + zip_


@sound
def sling():
    return mix(dash() * 0.8, blip(400, 1400, 0.25, square, 0.3, 0.12) * 0.35)


# --- combat ---------------------------------------------------------------------------

@sound
def parry():
    s = 0.35  # bright "shing!"
    ring = metal(1900, s, 0.18, seed=7)
    clang = bandpass(noise(0.05, seed=8), 2500, 9000) * perc(0.05, 0.01)
    return room(mix(ring * 0.7, clang * 1.2), 0.03, 0.2)


@sound
def scissor_fire():
    return mix(snip(0.09, 5600, 9), np.concatenate([np.zeros(int(0.07 * SR)), snip(0.09, 6200, 10)]))


@sound
def catch():
    return mix(blip(600, 900, 0.08, triangle, decay=0.05), metal(2600, 0.15, 0.06, 11) * 0.3)


@sound
def toss():
    return mix(blip(300, 1500, 0.22, square, 0.25, 0.1) * 0.45, metal(2400, 0.25, 0.1, 12) * 0.25)


@sound
def whip():
    s = 0.14
    return bandpass(noise(s, seed=13), 1500, 7000) * env(s, attack=0.02, decay=0.03, sustain=0, release=0.03) * 1.2


@sound
def hurt():
    """A snip of hair + a little 'oof' pitch drop."""
    return mix(snip(0.1, 4800, 14) * 1.2, blip(520, 200, 0.18, square, 0.4, 0.07) * 0.35)


@sound
def death():
    s = 0.7
    fall = square(sweep(660, 90, s), s, 0.35) * env(s, attack=0.005, decay=0.35, sustain=0.0, release=0.1)
    return room(mix(fall * 0.5, snip(0.1, 4400, 15), np.concatenate([np.zeros(int(0.12 * SR)), snip(0.1, 3800, 16)])), 0.05, 0.25)


@sound
def robot_break():
    s = 0.4
    crunch = lowpass(noise(s, seed=17), 2500) * perc(s, 0.08)
    bits = [blip(f, f * 0.6, 0.06, square, 0.5, 0.03) for f in (900, 700, 1200)]
    out = crunch * 0.8
    for i, b in enumerate(bits):
        out[int((0.03 + i * 0.06) * SR):int((0.03 + i * 0.06) * SR) + len(b)] += b * 0.4
    return out


@sound
def robot_drop():
    """The ceiling vent warning: two short alarm beeps."""
    beep = square(880, 0.08, 0.5) * env(0.08, release=0.02) * 0.5
    gap = np.zeros(int(0.07 * SR))
    return np.concatenate([beep, gap, square(660, 0.08, 0.5) * env(0.08, release=0.02) * 0.5])


@sound
def boss_charge():
    s = 0.6  # clipper revving up
    f = sweep(70, 160, s)
    buzz = saw(f, s) * 0.6 + square(f * 2, s, 0.3) * 0.3
    return lowpass(buzz, 2200) * env(s, attack=0.08, decay=None, sustain=1.0, release=0.12)


@sound
def boss_stomp():
    s = 0.45
    boom = sine(sweep(120, 40, s), s) * perc(s, 0.18)
    clank = metal(700, s, 0.12, 18) * 0.35
    return room(mix(boom * 1.2, clank), 0.05, 0.2)


@sound
def boss_daze():
    s = 0.6  # little spinning-stars warble
    f = 1200 + 300 * np.sin(2 * np.pi * 9 * t_axis(s))
    return triangle(f, s) * perc(s, 0.3) * 0.5 + metal(2200, s, 0.2, 19) * 0.2


@sound
def wave_alarm():
    out = []
    for i in range(3):
        b = square(sweep(500, 900, 0.18), 0.18, 0.5) * env(0.18, release=0.03) * 0.45
        out += [b, np.zeros(int(0.06 * SR))]
    return np.concatenate(out)


# --- props ----------------------------------------------------------------------------

@sound
def bell():
    s = 1.2  # reception service bell: ding!
    t = t_axis(s)
    out = np.zeros(len(t))
    for ratio, g, d in ((1.0, 1.0, 0.9), (2.0, 0.35, 0.5), (2.76, 0.45, 0.4), (5.4, 0.2, 0.2)):
        out += g * np.sin(2 * np.pi * 2093 * ratio * t) * np.exp(-t / d)
    return room(out * perc(s, 0.6, attack=0.001) ** 0.2 * 0.6, 0.04, 0.25)


@sound
def lever():
    s = 0.16
    click = bandpass(noise(0.03, seed=20), 1500, 6000) * perc(0.03, 0.006)
    clunk = sine(sweep(320, 180, s), s) * perc(s, 0.05)
    out = mix(click, clunk * 0.7)
    out[int(0.08 * SR):int(0.08 * SR) + len(click)] += click * 0.7
    return out


@sound
def door():
    s = 0.5
    slide = lowpass(noise(s, seed=21), 700) * env(s, attack=0.05, decay=0.2, sustain=0.3, release=0.1)
    chime = sine(midi(76), 0.3) * perc(0.3, 0.12) * 0.3
    return mix(slide, np.concatenate([np.zeros(int(0.25 * SR)), chime]))


@sound
def gel_smash():
    s = 0.35  # squelchy splat
    sq = sine(sweep(500, 90, s) * (1 + 0.15 * np.sin(2 * np.pi * 35 * t_axis(s))), s) * perc(s, 0.1)
    splat = lowpass(noise(s, seed=22), 1800) * perc(s, 0.06)
    return mix(sq * 0.8, splat * 0.7)


@sound
def gel_regrow():
    s = 0.5
    return sine(sweep(120, 380, s) * (1 + 0.1 * np.sin(2 * np.pi * 14 * t_axis(s))), s) * env(s, attack=0.15, decay=0.2, sustain=0.3, release=0.15) * 0.5


@sound
def splash():
    s = 0.5  # into the dye
    sp = bandpass(noise(s, seed=23), 300, 3500) * env(s, attack=0.005, decay=0.12, sustain=0.0, release=0.1)
    bloop = sine(sweep(400, 120, 0.2), 0.2) * perc(0.2, 0.06)
    return mix(sp, bloop * 0.6)


@sound
def tonic():
    notes = (72, 76, 79, 84)  # sparkly arpeggio
    out = np.zeros(int(0.5 * SR))
    for i, n in enumerate(notes):
        b = (triangle(midi(n), 0.2) * perc(0.2, 0.08) + sine(midi(n) * 2, 0.2) * perc(0.2, 0.05) * 0.3) * 0.5
        out[int(i * 0.06 * SR):int(i * 0.06 * SR) + len(b)] += b
    return room(out, 0.03, 0.25)


@sound
def iron_hiss():
    s = 0.6
    return highpass(noise(s, seed=24), 3000) * env(s, attack=0.04, decay=0.25, sustain=0.2, release=0.15) * 0.6


@sound
def soak():
    s = 0.35  # drip-drip
    drops = np.zeros(int(s * SR))
    for i, f in enumerate((1300, 1000, 1150)):
        d = sine(sweep(f, f * 1.8, 0.06), 0.06) * perc(0.06, 0.02) * 0.6
        drops[int(i * 0.1 * SR):int(i * 0.1 * SR) + len(d)] += d
    return drops


@sound
def swap():
    """The barber's chair: snip-snip, then a rising 'wait, what?'"""
    rise = square(sweep(300, 900, 0.4), 0.4, 0.3) * env(0.4, attack=0.02, decay=0.25, sustain=0.2, release=0.08) * 0.35
    s1 = snip(0.1, 5000, 25)
    return mix(s1, np.concatenate([np.zeros(int(0.12 * SR)), snip(0.1, 5400, 26)]),
               np.concatenate([np.zeros(int(0.25 * SR)), rise]))


# --- flow & UI -------------------------------------------------------------------------

def arpeggio(notes, step=0.09, length=0.3, wave=square):
    out = np.zeros(int((step * len(notes) + length + 0.4) * SR))
    for i, n in enumerate(notes):
        b = (wave(midi(n), length, 0.25) if wave is square else wave(midi(n), length)) * env(length, attack=0.005, decay=0.12, sustain=0.3, release=0.06)
        b += triangle(midi(n - 12), length) * env(length, decay=0.15, sustain=0.2, release=0.06) * 0.5
        out[int(i * step * SR):int(i * step * SR) + len(b)] += b * 0.5
    return room(out, 0.05, 0.25)


@sound
def room_clear():
    return arpeggio((72, 76, 79, 84), 0.08, 0.25)


@sound
def level_clear():
    return arpeggio((67, 72, 76, 79, 84, 88), 0.1, 0.5)


@sound
def ui_move():
    return blip(900, 1100, 0.05, square, 0.25, 0.025) * 0.4


@sound
def ui_confirm():
    return mix(blip(700, 700, 0.07, square, 0.25, 0.05) * 0.4,
               np.concatenate([np.zeros(int(0.06 * SR)), blip(1050, 1050, 0.1, square, 0.25, 0.06) * 0.4]))


@sound
def ui_back():
    return mix(blip(800, 800, 0.07, square, 0.25, 0.05) * 0.35,
               np.concatenate([np.zeros(int(0.06 * SR)), blip(560, 560, 0.1, square, 0.25, 0.06) * 0.35]))


# Loudness (RMS) ceilings, so a pure square beep doesn't drown a soft whoosh. UI clicks sit
# well under the game sounds; alarms are loud on purpose but not painful.
LOUDNESS = {"ui_move": 0.06, "ui_confirm": 0.07, "ui_back": 0.07, "robot_drop": 0.16, "wave_alarm": 0.18}
DEFAULT_LOUDNESS = 0.2


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for name, fn in SOUNDS.items():
        x = highpass(fn(), 30)  # no DC, no sub-rumble
        x = normalize(x, 0.8)
        rms = np.sqrt(np.mean(x ** 2))
        target = LOUDNESS.get(name, DEFAULT_LOUDNESS)
        if rms > target:
            x *= target / rms
        x = fade(x)
        write_wav(OUT / f"{name}.wav", x)
        print(f"{name:14s} {len(x) / SR:.2f}s")


if __name__ == "__main__":
    main()
