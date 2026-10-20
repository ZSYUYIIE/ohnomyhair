"""Render the glitch-fixed Final pitch and mix the human narration with the original music bed.
Run after build.py:  pitch/.venv-v3/Scripts/python.exe pitch/final_fix/render.py
-> pitch/videos/Oh_No_My_Hair_Pitch_Final_Fixed.mp4 (+ .en.srt)
"""
import json
import os
import re
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PITCH = ROOT.parent
CACHE = ROOT / "cache"
OUT = PITCH / "videos" / "Oh_No_My_Hair_Pitch_Final_Fixed.mp4"
MUSIC = PITCH / "editor" / "public" / "calm.wav"
MUSIC_GAIN = 0.07  # same bed level as the original Final
VOICE_LUFS = -17


def run(cmd, **kw):
    print(">", " ".join(str(c) for c in cmd)[:160], flush=True)
    return subprocess.run(cmd, check=True, **kw)


def main():
    data = (PITCH / "editor" / "src" / "final" / "data.ts").read_text(encoding="utf-8")
    frames = json.loads(data[data.index("{"):data.rindex("}") + 1])["frames"]
    seconds = frames / 30
    raw = CACHE / "picture.mp4"
    # Remotion keeps frames in the temp folder; keep them on this drive (C: is often nearly full).
    tmp = CACHE / "tmp"
    tmp.mkdir(parents=True, exist_ok=True)
    env = {**os.environ, "TEMP": str(tmp), "TMP": str(tmp)}
    run(["npx", "remotion", "render", "src/final/Root.tsx", "OhNoMyHairPitchFinalFixed", str(raw), "--muted", "--concurrency=4", "--log=error"],
        cwd=PITCH / "editor", shell=True, env=env)

    # Narration: high-pass, then a linear gain to VOICE_LUFS (measured first, so no pumping).
    narration = CACHE / "narration.wav"
    probe = subprocess.run(["ffmpeg", "-hide_banner", "-i", str(narration), "-af", "highpass=f=70,loudnorm=print_format=json", "-f", "null", "-"], capture_output=True, text=True).stderr
    measured = float(json.loads(re.findall(r"\{[^{}]*\}", probe)[-1])["input_i"])
    gain = VOICE_LUFS - measured
    mix = CACHE / "mix.wav"
    run(["ffmpeg", "-y", "-v", "error", "-i", str(narration), "-stream_loop", "-1", "-i", str(MUSIC), "-filter_complex",
         f"[0:a]highpass=f=70,volume={gain:.2f}dB,aformat=channel_layouts=stereo,apad=whole_dur={seconds}[v];"
         f"[1:a]volume={MUSIC_GAIN},atrim=0:{seconds},afade=t=in:d=2,afade=t=out:st={seconds - 2}:d=2,aformat=channel_layouts=stereo[m];"
         f"[v][m]amix=inputs=2:normalize=0:duration=first,loudnorm=I=-16:TP=-1.5:LRA=11,aresample=48000[a]",
         "-map", "[a]", "-t", f"{seconds}", str(mix)])
    run(["ffmpeg", "-y", "-v", "error", "-i", str(raw), "-i", str(mix), "-map", "0:v", "-map", "1:a", "-c:v", "copy",
         "-c:a", "aac", "-b:a", "192k", "-ar", "48000", "-shortest",
         "-metadata", "title=Oh No My Hair - Prototype Pitch", "-metadata", "artist=NPC Union",
         "-metadata", "comment=https://chenhongshan333.itch.io/ohnomyhair", "-movflags", "+faststart", str(OUT)])
    shutil.copy2(CACHE / "captions.srt", OUT.with_suffix(".en.srt"))
    print(f"-> {OUT} ({seconds:.1f} s, voice gain {gain:+.1f} dB)")


if __name__ == "__main__":
    main()
