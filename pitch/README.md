# Pitch video

The pitch video for Oh No My Hair, and everything needed to change and re-render it. This folder has a `.gdignore`, so Godot skips it.

## What's here

| Path | What it is |
|---|---|
| `videos/Oh_No_My_Hair_Pitch_v3.mp4` | Current version: gameplay-first pitch, two temporary AI voices, captions and game audio (4:13) |
| `v3/README.txt` | v3 editing, AI voice replacement, rebuild commands, capture provenance and review notes |
| `videos/Oh_No_My_Hair_Pitch_v3_Clean.mp4` | Silent v3 picture without burned-in subtitles, for replacing narration |
| `videos/Oh_No_My_Hair_Pitch_v3_NoBGM.mp4` | v3 with voices and game SFX, without background music |
| `videos/Oh_No_My_Hair_Pitch_v2.mp4` | Previous version: two voices, rewritten script, sourced USD budget (3:59) |
| `videos/Oh_No_My_Hair_Pitch_Final.mp4` | First version (one AI voice), kept for comparison |
| `docs/Oh_No_My_Hair_Pitch_Script_v2.txt` | The v2 script as a read-aloud script (A = ZSYUYIIE, B = ChenHongshan333) |
| `docs/Oh_No_My_Hair_Pitch_v2_Notes.md` | Why v1 sounded like AI, what changed, tips for recording yourselves |
| `docs/Oh No My Hair global USD budget.md` | Budget research behind scenes 13 and 14, with sources (notes in `docs/research_notes/`) |
| `script_v2.py`, `budget_lines.json` | The script as data: scenes, on-screen titles, who says each line |
| `make_voice.py` | Narration with Microsoft Edge TTS voices (what v2 uses) |
| `make_voice_cb.py` | Narration in voices cloned from a short sample of each of you (Chatterbox, local GPU) |
| `build_timeline.py` | Scene lengths, captions and `editor/src/Root.tsx` from the voice files |
| `render.py` | Renders the video and masters the audio into `out/` |
| `editor/` | The Remotion project: slide layouts in `src/PitchScene.tsx`, clips, art, music and voice files in `public/` |

The videos are stored with Git LFS. Run `git lfs install` once before cloning or pulling, or you'll get small pointer files instead of the videos.

## Setup

Needs Node 20+ and Python 3.10+.

```
cd pitch/editor
npm install
cd ..
pip install -r requirements.txt
```

## Re-render without changes

The voice files and timeline are committed, so this reproduces `videos/Oh_No_My_Hair_Pitch_v2.mp4`:

```
python render.py
```

To preview and click through scenes instead, run `npm run dev` in `editor/`.

## Change the words

1. Edit the lines in `script_v2.py` (budget scenes: `budget_lines.json`). Write numbers as words ("seventeen thousand two hundred"), so the voices read them naturally.
2. `python script_v2.py` writes `script_v2.json`.
3. Re-voice only the scenes you changed: `python make_voice.py hook story` (scene ids are in `script_v2.py`). With no ids it re-voices everything. Edge TTS sometimes drops a request; the script retries.
4. `python build_timeline.py` updates scene lengths and captions.
5. `python render.py`.

Slide text and layout are in `editor/src/PitchScene.tsx`. Each slide is a `kind==='...'` block.

## Use your own voices

Recording yourselves still sounds best. Record each scene, put the files in `editor/public/<scene id>.mp3`, and make captions from the recording (see the notes doc). You'll need `<id>-words.json` word timings; `make_voice_cb.py` shows how to get them with faster-whisper.

Or clone your voices (needs an NVIDIA GPU; tested on an RTX 5060 Laptop, 8 GB):

1. Set up the clone venv as described at the top of `requirements-clone.txt` (about 3 GB of downloads, plus the model on first run).
2. Record 10 to 20 seconds of each person talking naturally, like explaining the game to a friend, in a quiet room. Any phone format works. Save them as `voice_samples/ZSYUYIIE.m4a` and `voice_samples/ChenHongshan333.m4a` (this folder is git-ignored).
3. Run:
   ```
   .venv-clone\Scripts\python -I make_voice_cb.py --ref A=voice_samples/ZSYUYIIE.m4a --ref B=voice_samples/ChenHongshan333.m4a
   python build_timeline.py
   python render.py
   ```

Each line is transcribed after it's generated, and takes that drop words are redone (up to three tries). Lines it prints as "listen to this one" are worth a listen. `--exaggeration` (default 0.6) makes the delivery more or less animated.

## Still open

- Re-voice with your real or cloned voices. The Edge TTS voices in v2 still sound synthetic.
- Check how the TTS says your handles in the first scene, and swap in real names if you'd rather.
- Scene 14 mentions a Kickstarter. One of you needs to live in one of Kickstarter's supported countries; if not, change the line to pre-orders and itch.io sales.
- The prototype scene says four chapters and twelve rooms. Update it if the game has changed.
