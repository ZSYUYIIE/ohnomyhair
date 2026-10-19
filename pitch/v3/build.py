"""Build a single v3 timing source, editable JSX, SRT and media inventory."""
import argparse
import json
import math
from pathlib import Path
import re
import shutil
import subprocess

ROOT = Path(__file__).resolve().parent
PITCH = ROOT.parent
PROJECT = PITCH.parent
PUB = PITCH / "editor/public"
SRC = PITCH / "editor/src/v3"
FPS = 30


def probe(path):
    return json.loads(subprocess.check_output(["ffprobe", "-v", "error", "-show_entries", "format=duration:stream=codec_type,width,height", "-of", "json", str(path)], text=True))


def captions(words, lead):
    result, group = [], []
    for i, word in enumerate(words):
        group.append(word)
        last = i == len(words) - 1
        changed = not last and words[i + 1]["speaker"] != word["speaker"]
        text = " ".join(w["text"] for w in group)
        if len(text) >= 44 or len(group) >= 8 or (len(group) >= 3 and re.search(r"[.!?]$", word["text"])) or changed or last:
            result.append({"text": text, "startMs": round((group[0]["start"] + lead) * 1000),
                           "endMs": round((word["end"] + lead + .10) * 1000), "timestampMs": None, "confidence": None})
            group = []
    # Keep a sentence's final one or two words with the preceding phrase.
    # The panel can wrap to two lines; a lone "gaps." is harder to read.
    merged = []
    for item in result:
        if (merged and len(item['text'].split()) <= 2
            and not re.search(r'[.!?]$', merged[-1]['text'])
            and item['startMs'] - merged[-1]['endMs'] < 400
            and len(merged[-1]['text'] + ' ' + item['text']) <= 64):
            merged[-1]['text'] += ' ' + item['text']
            merged[-1]['endMs'] = item['endMs']
        else:
            merged.append(item)
    result = merged
    for a, b in zip(result, result[1:]):
        a["endMs"] = min(a["endMs"], b["startMs"])
    return result


def stamp(seconds):
    value = round(seconds * 1000)
    h, value = divmod(value, 3600000)
    m, value = divmod(value, 60000)
    s, value = divmod(value, 1000)
    return f"{h:02}:{m:02}:{s:02},{value:03}"


def main(draft):
    SRC.mkdir(parents=True, exist_ok=True)
    media = PUB / "v3"
    media.mkdir(exist_ok=True)
    audio = media / "audio"
    audio.mkdir(exist_ok=True)
    for path in (PROJECT / "assets/audio/sfx").glob("*.wav"):
        shutil.copy2(path, audio / path.name)
    for path in (PROJECT / "assets/audio/music").glob("*.wav"):
        shutil.copy2(path, audio / f"music-{path.name}")
    scenes = json.loads((ROOT / "script.json").read_text(encoding="utf-8"))
    clock, allcaps, inventory, data = 0, [], {}, {}
    for path in list(PUB.glob("*.mp4")) + list(media.glob("*.mp4")):
        p = probe(path)
        inventory[path.relative_to(PUB).as_posix()] = {
            "seconds": float(p["format"]["duration"]),
            "audio": any(s["codec_type"] == "audio" for s in p["streams"]),
        }
    for scene in scenes:
        timing_path = media / "voice" / f"{scene['id']}-timing.json"
        if timing_path.exists():
            timing = json.loads(timing_path.read_text(encoding="utf-8"))
        elif draft:
            timing = {"seconds": scene["minimum"] - 2, "words": [], "lines": []}
        else:
            raise FileNotFoundError(timing_path)
        duration = max(scene["minimum"], timing["seconds"] + scene["lead"] + 1.3)
        # A complete clean replay has room after the explanation.
        if scene["id"] in ("sling", "parry"):
            duration = max(duration, timing["seconds"] + scene["lead"] + 5)
        frames = math.ceil(duration * FPS)
        words = timing["words"]
        original = " ".join(l["text"] for l in scene["lines"]).split()
        normalize = lambda text: re.sub(r"[^a-z0-9]", "", text.lower())
        if len(original) == len(words) and all(normalize(a) == normalize(b["text"]) for a,b in zip(original,words)):
            words = [{**word, "text": token} for token,word in zip(original,words)]
        caps = captions(words, scene["lead"])
        scene.update(from_frame=clock, frames=frames, captions=caps,
                     voice_seconds=timing["seconds"], lines_timing=timing["lines"])
        data[scene["id"]] = scene
        allcaps.extend({**c, "start": clock / FPS + c["startMs"] / 1000,
                        "end": clock / FPS + c["endMs"] / 1000} for c in caps)
        clock += frames
    if not draft and not 180 <= clock / FPS <= 300:
        raise ValueError(f"Video must be 3–5 minutes, got {clock/FPS:.2f}s")
    timeline = {"fps": FPS, "frames": clock, "scenes": data, "clips": inventory}
    (ROOT / "timeline.json").write_text(json.dumps(timeline, indent=2, ensure_ascii=False), encoding="utf-8")
    (media / "timeline.json").write_text(json.dumps(timeline, indent=2, ensure_ascii=False), encoding="utf-8")
    types = 'export type Section = {id:string;title:string;kind:string;minimum:number;lead:number;lines:{speaker:string;text:string;at?:number}[];from_frame:number;frames:number;voice_seconds:number;lines_timing:{line:number;start:number;end:number;speaker:string;text:string}[];captions:{text:string;startMs:number;endMs:number;timestampMs:null;confidence:null}[]};\n'
    (SRC / "data.ts").write_text(types + "export const TOTAL = " + str(clock) + ";\nexport const SECTIONS:Record<string,Section> = " + json.dumps(data, ensure_ascii=False) + ";\nexport const CLIPS:Record<string,{seconds:number;audio:boolean}> = " + json.dumps(inventory) + ";\n", encoding="utf-8")
    lines = ["// Generated by pitch/v3/build.py; scene instances are individually editable.",
             "import {Track,Sequence} from 'remotion';", "import {Audio} from '@remotion/media';",
             "import {staticFile} from 'remotion';", "import {V3Scene,V3Captions,MusicBed,V3AudioMode} from './Scenes';",
             "export type PitchV3Props={bgm?:boolean;narration?:boolean;gameAudio?:boolean;captions?:boolean;audioOnly?:boolean};",
             "export const PitchV3=({bgm=true,narration=true,gameAudio=true,captions=true,audioOnly=false}:PitchV3Props)=> <V3AudioMode.Provider value={audioOnly}>",
             '<Track name="v3 · Story and gameplay">']
    for s in scenes:
        lines.append(f'<V3Scene name={{{json.dumps(s["title"])}}} from={{{s["from_frame"]}}} durationInFrames={{{s["frames"]}}} id="{s["id"]}" title={{{json.dumps(s["title"])}}} duration={{{s["frames"]}}} gameAudio={{gameAudio}}/>')
    lines.append('</Track>{narration&&<Track name="v3 · Replaceable narration">')
    for s in scenes:
        if (media / "voice" / f"{s['id']}.mp3").exists():
            start = s["from_frame"] + round(s["lead"] * FPS)
            lines.append(f'<Audio name="{s["id"]} · AI placeholder" src={{staticFile("v3/voice/{s["id"]}.mp3")}} from={{{start}}} durationInFrames={{{math.ceil(s["voice_seconds"]*FPS)}}} volume={{1}}/>')
    lines.append('</Track>}{captions&&<Track name="v3 · English captions">')
    for s in scenes:
        lines.append(f'<Sequence name="{s["id"]} captions" from={{{s["from_frame"]}}} durationInFrames={{{s["frames"]}}}><V3Captions captions={{{json.dumps(s["captions"])}}}/></Sequence>')
    lines += ['</Track>}{bgm&&<MusicBed/>}</V3AudioMode.Provider>;']
    (SRC / "PitchV3.tsx").write_text("\n".join(lines), encoding="utf-8")
    # v3 has a separate entry point: v1/v2's registered root remains reproducible.
    (SRC / "Root.tsx").write_text("import {Composition,Folder,registerRoot} from 'remotion';\nimport {PitchV3} from './PitchV3';\nimport {V3Scene} from './Scenes';\nexport const V3Root=()=> <>\n" +
        f'<Composition id="OhNoMyHairPitchV3" component={{PitchV3}} width={{1920}} height={{1080}} fps={{30}} durationInFrames={{{clock}}} defaultProps={{{{bgm:true,narration:true,gameAudio:true,captions:true}}}}/>\n' +
        '<Folder name="V3-Scenes"><Composition id="V3-Scene" component={V3Scene} width={1920} height={1080} fps={30} durationInFrames={450} defaultProps={{id:"hook",title:"Throw me!",duration:450,gameAudio:true}}/></Folder>\n</>;\nregisterRoot(V3Root);\n', encoding="utf-8")
    srt = "\n\n".join(f"{i+1}\n{stamp(c['start'])} --> {stamp(c['end'])}\n{c['text']}" for i,c in enumerate(allcaps)) + "\n"
    (PITCH / "videos/Oh_No_My_Hair_Pitch_v3.en.srt").write_text(srt, encoding="utf-8")
    (ROOT / "props-nobgm.json").write_text(json.dumps({"bgm": False,"audioOnly":True,"captions":False}), encoding="utf-8")
    (ROOT / "props-voiceonly.json").write_text(json.dumps({"bgm": False, "gameAudio": False, "captions": False,"audioOnly":True}), encoding="utf-8")
    (ROOT / "props-music-effects.json").write_text(json.dumps({"narration": False, "captions": False,"audioOnly":True}), encoding="utf-8")
    (ROOT / "props-musiconly.json").write_text(json.dumps({"narration":False,"gameAudio":False,"captions":False,"audioOnly":True}),encoding="utf-8")
    (ROOT / "props-clean.json").write_text(json.dumps({"narration": False, "captions": False, "bgm": False, "gameAudio": False}), encoding="utf-8")
    storyboard = "OH NO MY HAIR / v3 EDIT TIMELINE\n\n"
    for s in scenes:
        storyboard += f"{stamp(s['from_frame']/FPS)}  {s['id'].upper()}  ({s['frames']/FPS:.2f}s)\n{s['title']}\n"
        storyboard += f"Voice: editor/public/v3/voice/{s['id']}.mp3; start +{s['lead']:.2f}s\n"
        storyboard += "\n".join(f"{l['speaker']}: {l['text']}" for l in s['lines']) + "\n\n"
    (ROOT / "storyboard.txt").write_text(storyboard, encoding="utf-8")
    manifest = '''// Single timing source shared with the v3 composition.
import {PitchV3} from './v3/PitchV3';
import {V3Visual,V3Captions,MusicBed} from './v3/Scenes';
import {SECTIONS,TOTAL} from './v3/data';
export const WORKBENCH={
 name:'Oh No My Hair · pitch v3',fps:30,width:1920,height:1080,total:TOTAL,background:'#fff5df',
 shots:Object.values(SECTIONS).map(s=>({id:s.id,label:s.title,from:s.from_frame,duration:s.frames,component:V3Visual,props:{id:s.id,title:s.title,duration:s.frames,gameAudio:true},durationProp:'duration',schema:[{type:'text',key:'title',label:'Heading',default:s.title}],cardId:'v3-'+s.id})),
 captions:Object.values(SECTIONS).map(s=>({id:s.id+'-captions',label:s.id+' · English captions',from:s.from_frame,duration:s.frames,component:V3Captions,props:{captions:s.captions}})),
 overlays:[{id:'music-bed',label:'Salon music · ducking under speech',from:0,duration:TOTAL,component:MusicBed}],
 sfx:Object.values(SECTIONS).map(s=>({from:s.from_frame+Math.round(s.lead*30),duration:Math.ceil(s.voice_seconds*30),src:'v3/voice/'+s.id+'.mp3',volume:1})),
 transitions:[],bgm:[],order:['captions','overlays'],original:PitchV3,
};
'''
    (PITCH / "editor/src/workbench.ts").write_text(manifest, encoding="utf-8")
    print(f"{'DRAFT ' if draft else ''}{len(scenes)} sections, {clock} frames, {clock/FPS:.2f}s, {len(allcaps)} captions")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--draft", action="store_true")
    main(parser.parse_args().draft)
