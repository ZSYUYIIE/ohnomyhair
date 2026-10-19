"""Timeline, captions, Root.tsx and SRT for the pitch video (gameplay clips, art and voice
files live in editor/public).
Run: python -I build_timeline.py   (after make_voice.py)
"""
import json
import math
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PUB = ROOT / "editor" / "public"
FFPROBE = str(ROOT / "editor" / "node_modules" / "@remotion" / "compositor-win32-x64-msvc" / "ffprobe.exe")
SRT_OUT = ROOT / "out" / "Oh_No_My_Hair_Pitch.en.srt"
TAIL = 0.85  # seconds of breathing room after each scene's narration


def duration(path):
    return float(subprocess.check_output([FFPROBE, "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(path)], text=True).strip())


def norm(text):
    return re.sub(r"[^a-z0-9]", "", text.lower())


def main():
    scenes = [s for s in json.loads((ROOT / "script_v2.json").read_text(encoding="utf-8")) if s["lines"]]
    clock = 0
    allcaps = []
    for s in scenes:
        dur = duration(PUB / f"{s['id']}.mp3")
        s["voiceSeconds"] = dur
        s["frames"] = math.ceil((dur + TAIL) * 30)
        s["from"] = clock
        words = json.loads((PUB / f"{s['id']}-words.json").read_text(encoding="utf-8"))
        # Put the script's punctuation back on the spoken words (TTS boundaries drop it).
        original = s["text"].split()
        if len(original) == len(words) and all(norm(a) == norm(b["text"]) for a, b in zip(original, words)):
            for a, b in zip(original, words):
                b["text"] = a
        caps, group = [], []
        for i, w in enumerate(words):
            group.append(w)
            last = i == len(words) - 1
            speaker_change = not last and words[i + 1].get("speaker") != w.get("speaker")
            if len(group) >= 9 or (len(group) >= 4 and w["text"].endswith((".", "?", "!", ";"))) or last or speaker_change:
                text = " ".join(x["text"] for x in group)
                a = group[0]["offset"] / 10000 + 200
                b = (group[-1]["offset"] + group[-1]["duration"]) / 10000 + 300
                caps.append({"text": text, "startMs": a, "endMs": b, "timestampMs": a, "confidence": None})
                allcaps.append({"text": text, "start": clock / 30 + a / 1000, "end": clock / 30 + b / 1000})
                group = []
        s["captions"] = caps
        clock += s["frames"]

    def stamp(t):
        ms = round(t * 1000)
        h, ms = divmod(ms, 3600000)
        m, ms = divmod(ms, 60000)
        sec, ms = divmod(ms, 1000)
        return f"{h:02}:{m:02}:{sec:02},{ms:03}"

    SRT_OUT.parent.mkdir(exist_ok=True)
    SRT_OUT.write_text("\n\n".join(f"{i + 1}\n{stamp(c['start'])} --> {stamp(c['end'])}\n{c['text']}" for i, c in enumerate(allcaps)) + "\n", encoding="utf-8")
    (PUB / "timeline.json").write_text(json.dumps({"fps": 30, "frames": clock, "scenes": scenes}, indent=2), encoding="utf-8")

    # Root.tsx, same structure as v1's generated one.
    lines = ['import {Composition,Track,staticFile,interpolate,useCurrentFrame} from "remotion";',
             'import {Audio} from "@remotion/media";',
             'import {PitchScene,BasicCaptions} from "./PitchScene";',
             'export const Pitch=()=>{ const f=useCurrentFrame();return <><Track name="Pitch chapters">']
    for s in scenes:
        props = " ".join(f"{k}={{{json.dumps(s[k])}}}" for k in ["id", "title", "eyebrow", "kind"] + (["clip"] if "clip" in s else []))
        lines.append(f'<PitchScene name={{{json.dumps(s["title"])}}} from={{{s["from"]}}} durationInFrames={{{s["frames"]}}} endFrames={{{s["frames"]}}} {props}><BasicCaptions captions={{{json.dumps(s["captions"])}}}/></PitchScene>')
    n = clock
    lines += ['</Track><Audio name="Salon music bed" src={staticFile("calm.wav")} loop durationInFrames={' + str(n) + '} volume={interpolate(f,[0,60,' + str(n - 60) + ',' + str(n) + '],[0,0.07,0.07,0],{extrapolateLeft:"clamp",extrapolateRight:"clamp"})}/></>;};',
              f'export const RemotionRoot=()=><><Composition id="OhNoMyHairPitch" component={{Pitch}} durationInFrames={{{n}}} fps={{30}} width={{1920}} height={{1080}}/></>;']
    (ROOT / "editor" / "src" / "Root.tsx").write_text("\n".join(lines), encoding="utf-8")
    print(f"{len(scenes)} scenes, {n} frames = {n / 30:.1f} s; {len(allcaps)} captions; SRT -> {SRT_OUT}")


if __name__ == "__main__":
    main()
