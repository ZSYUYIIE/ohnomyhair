"""Render the pitch and master its audio (loudness -16 LUFS, AAC 48 kHz, fast start).
Run: python render.py   ->  out/Oh_No_My_Hair_Pitch.mp4
Needs `npm install` in editor/ first, and timeline/Root.tsx from build_timeline.py.
"""
import subprocess
from pathlib import Path

import imageio_ffmpeg

ROOT = Path(__file__).resolve().parent
OUT = ROOT / "out"


def main():
    OUT.mkdir(exist_ok=True)
    raw = OUT / "render_raw.mp4"
    subprocess.run(["npx", "remotion", "render", "OhNoMyHairPitch", str(raw)], cwd=ROOT / "editor", check=True, shell=True)
    master = OUT / "Oh_No_My_Hair_Pitch.mp4"
    subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(), "-y", "-v", "error", "-i", str(raw), "-c:v", "copy",
                    "-af", "loudnorm=I=-16:TP=-1.5:LRA=11", "-c:a", "aac", "-b:a", "192k", "-ar", "48000",
                    "-metadata", "title=Oh No My Hair - Prototype Pitch", "-metadata", "artist=NPC Union",
                    "-metadata", "comment=https://chenhongshan333.itch.io/ohnomyhair",
                    "-movflags", "+faststart", str(master)], check=True)
    raw.unlink()
    print("->", master)


if __name__ == "__main__":
    main()
