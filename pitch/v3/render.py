"""Render the v3 composition, review frames, and replacement audio stems."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parent
EDITOR = ROOT.parent / "editor"
VIDEOS = ROOT.parent / "videos"
NODE = shutil.which("node")
CLI = EDITOR / "node_modules/@remotion/cli/remotion-cli.js"
CHROME = "C:/Program Files/Google/Chrome/Application/chrome.exe"
ENTRY = "src/v3/Root.tsx"
SOURCE_ENTRY = ENTRY
COMP = "OhNoMyHairPitchV3"
BUNDLE = ROOT.parent.parent / 'build/pitch-v3-bundle'


def run(args):
    cmd = [NODE, str(CLI), *map(str, args), f"--browser-executable={CHROME}", "--offthreadvideo-cache-size-in-bytes=33554432", "--media-cache-size-in-bytes=251658240", "--offthreadvideo-video-threads=1", "--log=warn"]
    if Path(str(args[3])).suffix.lower() == '.wav':
        cmd.append('--concurrency=2')
    print("REMOTION", " ".join(map(str, args[:4])), flush=True)
    logs = ROOT / 'review/logs'
    logs.mkdir(parents=True,exist_ok=True)
    stem = f"{args[0]}-{Path(str(args[3])).stem}"
    log = logs / f"{stem}.log"
    attempt = 1
    while log.exists():
        attempt += 1
        log = logs / f"{stem}.attempt-{attempt}.log"
    print('LOG',log,flush=True)
    with log.open('w',encoding='utf-8') as stream:
        env={**os.environ,"RAYON_NUM_THREADS":"1","UV_THREADPOOL_SIZE":"2"}
        result = subprocess.run(cmd, cwd=EDITOR, stdout=stream,stderr=subprocess.STDOUT,env=env)
    if result.returncode:
        print(log.read_text(encoding='utf-8',errors='replace')[-5000:],flush=True)
        raise subprocess.CalledProcessError(result.returncode,cmd)
    print('OK',log.name,flush=True)


def main(mode, sections):
    global ENTRY,BUNDLE
    if mode == 'bundle':
        subprocess.run([NODE,str(CLI),'bundle',SOURCE_ENTRY,f'--out-dir={BUNDLE}',f'--public-dir={EDITOR / "public"}','--log=warn'],cwd=EDITOR,check=True,env={**os.environ,'RAYON_NUM_THREADS':'1','UV_THREADPOOL_SIZE':'2'})
        return
    timeline = json.loads((ROOT / "timeline.json").read_text(encoding="utf-8"))
    review = ROOT / "review"
    review.mkdir(exist_ok=True)
    if mode == 'fixmusic':
        # Separate bundle: a clean-picture export may still be reading BUNDLE.
        BUNDLE = ROOT.parent.parent / 'build/pitch-v3-audio-bundle'
        main('bundle', [])
        ENTRY = str(BUNDLE)
        music = ROOT / 'Oh_No_My_Hair_v3_Music.wav'
        run(['render',ENTRY,COMP,music,'--codec=wav','--sample-rate=48000',f'--props={ROOT / "props-musiconly.json"}'])
        corrected = review / 'render-remastered.mp4'
        subprocess.run(['ffmpeg','-y','-v','error','-i',str(VIDEOS/'Oh_No_My_Hair_Pitch_v3_NoBGM.mp4'),'-i',str(review/'no-bgm.wav'),'-i',str(music),'-filter_complex','[1:a][2:a]amix=inputs=2:normalize=0:duration=longest,loudnorm=I=-16:TP=-1.5:LRA=11[a]','-map','0:v:0','-map','[a]','-c:v','copy','-c:a','aac','-b:a','192k','-ar','48000','-movflags','+faststart','-metadata','title=Oh No My Hair - Pitch v3',str(corrected)],check=True)
        corrected.replace(VIDEOS/'Oh_No_My_Hair_Pitch_v3.mp4')
        run(['render',ENTRY,COMP,ROOT/'Oh_No_My_Hair_v3_Music_Effects.wav','--codec=wav','--sample-rate=48000',f'--props={ROOT / "props-music-effects.json"}'])
        return
    if mode == "stills":
        for name, scene in timeline["scenes"].items():
            if sections and name not in sections:
                continue
            relative = 9 if name == "hook" else min(scene["frames"] / 30 - 2, scene["frames"] / 60)
            frame = scene["from_frame"] + round(relative * 30)
            run(["still", ENTRY, COMP, review / f"{name}.png", f"--frame={frame}"])
        print("Review frames:", review)
        return
    if mode == "sample":
        run(["render", ENTRY, COMP, review / "opening-sample.mp4", "--frames=0-449", "--concurrency=3", "--crf=20"])
        return
    if mode == "probe":
        run(["render", ENTRY, COMP, review / "decode-probe.mp4", "--frames=1020-1319", "--concurrency=3", "--crf=20"])
        return
    if mode in ("final","extras"):
        # Keep a persistent, inspectable bundle throughout the long export.
        main('bundle', [])
        ENTRY = str(BUNDLE)
        dest = VIDEOS / "Oh_No_My_Hair_Pitch_v3.mp4"
        if mode == 'final':
            raw = review / "render.mp4"
            run(["render", ENTRY, COMP, raw, "--concurrency=2", "--crf=18", "--codec=h264", "--audio-codec=aac", "--audio-bitrate=192k", "--sample-rate=48000"])
            subprocess.run(["ffmpeg", "-y", "-v", "error", "-i", str(raw), "-c:v", "copy", "-af", "loudnorm=I=-16:TP=-1.5:LRA=11", "-c:a", "aac", "-b:a", "192k", "-ar", "48000", "-movflags", "+faststart", "-metadata", "title=Oh No My Hair - Pitch v3", str(dest)], check=True)
            print("DELIVERED", dest, flush=True)
        # Re-render the NoBGM audio from the same composition and bgm inputProp.
        # Reuse the exact picture stream; do not try to subtract/extract music.
        no_bgm = review / "no-bgm.wav"
        run(["render", ENTRY, COMP, no_bgm, "--codec=wav", "--sample-rate=48000", f"--props={ROOT / 'props-nobgm.json'}"])
        subprocess.run(["ffmpeg", "-y", "-v", "error", "-i", str(dest), "-i", str(no_bgm), "-map", "0:v:0", "-map", "1:a:0", "-c:v", "copy", "-af", "loudnorm=I=-16:TP=-1.5:LRA=11", "-c:a", "aac", "-b:a", "192k", "-ar", "48000", "-movflags", "+faststart", str(VIDEOS / "Oh_No_My_Hair_Pitch_v3_NoBGM.mp4")], check=True)
        main('audio', [])
        run(["render", ENTRY, COMP, VIDEOS / "Oh_No_My_Hair_Pitch_v3_Clean.mp4", "--concurrency=3", "--crf=18", "--muted", f"--props={ROOT / 'props-clean.json'}"])
    if mode == "audio":
        for name, props in [("Voiceover", "props-voiceonly.json"), ("Music_Effects", "props-music-effects.json"),('Music','props-musiconly.json')]:
            run(["render", ENTRY, COMP, ROOT / f"Oh_No_My_Hair_v3_{name}.wav", "--codec=wav", "--sample-rate=48000", f"--props={ROOT / props}"])


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=["stills", "sample", "probe", "final", "extras", "audio", "bundle", "fixmusic"])
    parser.add_argument("sections", nargs="*")
    args = parser.parse_args()
    if args.mode != 'bundle' and BUNDLE.exists():
        ENTRY = str(BUNDLE)
    main(args.mode, args.sections)
