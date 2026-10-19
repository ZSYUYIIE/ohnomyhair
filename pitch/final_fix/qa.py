"""Look for picture jumps inside scenes: frame-to-frame change in the gameplay box (game scenes)
or above the caption strip (other scenes), away from the scene fades. Compares with the original.
Run: pitch/.venv-v3/Scripts/python.exe pitch/final_fix/qa.py
"""
import json
import subprocess
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parent
PITCH = ROOT.parent
W, H = 320, 180
LIMIT = 6.0  # mean absolute change per pixel (0-255) between two frames
EDGE = 14  # frames at each scene edge belong to the fade in/out
BOX = (slice(135 * H // 1080, 935 * H // 1080), slice(249 * W // 1920, 1671 * W // 1920))
SLIDE = (slice(0, 940 * H // 1080), slice(0, W))
# Scene starts in the original Final.mp4 (see build.py) and which scenes are gameplay.
FINAL_STARTS = [0, 321, 836, 1297, 1723, 2234, 2710, 3231, 3804, 4200, 4577, 5102, 5608, 6111, 6529, 7092, 7548, 7951]
GAME = {2, 3, 4, 5, 6, 7}


def frames(path):
    p = subprocess.Popen(["ffmpeg", "-v", "error", "-i", str(path), "-vf", f"scale={W}:{H}", "-f", "rawvideo", "-pix_fmt", "gray", "-"], stdout=subprocess.PIPE)
    out = []
    while chunk := p.stdout.read(W * H):
        out.append(np.frombuffer(chunk, np.uint8).reshape(H, W))
    return out


def jumps(video, starts, total, cuts=()):
    f = frames(video)
    total = min(total, len(f))
    found = []
    for n, a in enumerate(starts):
        b = starts[n + 1] if n + 1 < len(starts) else total
        region = BOX if n in GAME else SLIDE
        for i in range(a + EDGE, b - EDGE):
            if i + 1 in cuts:
                continue
            d = float(np.abs(f[i + 1][region].astype(np.int16) - f[i][region]).mean())
            if d > LIMIT:
                found.append((n, i + 1, round(d, 1)))
    return found


def report(name, found):
    scenes = sorted({n for n, _, _ in found})
    print(f"{name}: {len(found)} jump frames in {len(scenes)} scenes")
    for n in scenes:
        hits = [(i, d) for m, i, d in found if m == n]
        print(f"  scene {n:2}: {len(hits)} frames, e.g. " + ", ".join(f"{i / 30:.2f}s ({d})" for i, d in hits[:4]))


def main():
    data = (PITCH / "editor" / "src" / "final" / "data.ts").read_text(encoding="utf-8")
    scenes = json.loads(data[data.index("{"):data.rindex("}") + 1])["scenes"]
    # Story art changes are deliberate cuts, as in the original.
    cuts = {s["from"] + c for s in scenes for c in s.get("storyCuts", [])}
    original = jumps(PITCH / "videos" / "Oh_No_My_Hair_Pitch_Final.mp4", FINAL_STARTS, 8290, {321 + 247, 321 + 371})
    fixed = jumps(PITCH / "videos" / "Oh_No_My_Hair_Pitch_Final_Fixed.mp4", [s["from"] for s in scenes], scenes[-1]["from"] + scenes[-1]["frames"], cuts)
    report("Original Final.mp4", original)
    report("Final_Fixed.mp4", fixed)


if __name__ == "__main__":
    main()
