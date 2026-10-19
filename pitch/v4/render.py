"""Hybrid export: Remotion graphics + uncropped FFmpeg footage + replaceable PCM mix."""
import argparse,json,os,shutil,subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parent; EDITOR=ROOT.parent/'editor'; PUB=EDITOR/'public'; CACHE=ROOT/'cache'; VIDEOS=ROOT.parent/'videos'
CLI=EDITOR/'node_modules/@remotion/cli/remotion-cli.js'; ENTRY='src/v4/Root.tsx'; CHROME='C:/Program Files/Google/Chrome/Application/chrome.exe'
BUNDLE=ROOT.parent.parent/'build/pitch-v4-bundle'
def run(cmd,cwd=None):
    logs=ROOT/'review/logs'; logs.mkdir(parents=True,exist_ok=True); log=logs/f'job-{len(list(logs.glob("job-*.log"))):04}.log'
    with log.open('w',encoding='utf-8') as f:
        r=subprocess.run(list(map(str,cmd)),cwd=cwd,stdout=f,stderr=subprocess.STDOUT,env={**os.environ,'RAYON_NUM_THREADS':'1','UV_THREADPOOL_SIZE':'2'})
    if r.returncode:raise RuntimeError(log.read_text(encoding='utf-8',errors='replace')[-3000:])
def still(s,index=-1,frame=80,force=False):
    out=CACHE/f"{s['id']}-bg-{index}-{frame}.png"
    if force or not out.exists():
        props=CACHE/'still-props.json'; props.write_text(json.dumps({'id':s['id'],'blankVideo':True,'clipIndex':index}),encoding='utf-8')
        run(['node',CLI,'still',ENTRY,'V4Scene',out,f'--frame={frame}',f'--props={props}',f'--browser-executable={CHROME}','--offthreadvideo-cache-size-in-bytes=33554432','--offthreadvideo-video-threads=1'],EDITOR)
    return out
def ffmpeg(args):run(['ffmpeg','-y','-v','error',*args])
def part(bg,out,frames,clip=None,media=None):
    duration=frames/30
    args=['-loop','1','-framerate','30','-i',bg]
    if clip:
        args+=['-ss',str(clip['start']),'-i',PUB/clip['src']]
        available=min((clip['end'] or media['seconds']),media['seconds'])-clip['start']
        filt=f"[1:v]trim=duration={available:.6f},setpts=(PTS-STARTPTS)/{clip['rate']},fps=30,scale=1440:810:flags=lanczos,tpad=stop_mode=clone:stop_duration={duration+1}[v];[0:v][v]overlay=240:150:shortest=1,format=yuv420p[out]"
        args+=['-filter_complex',filt,'-map','[out]']
    else:args+=['-vf','format=yuv420p']
    args+=['-frames:v',str(frames),'-an','-c:v','libx264','-preset','fast','-crf','18','-threads','4','-r','30','-video_track_timescale','90000',out]
    ffmpeg(args)
def ass(d):
    def t(x):
        n=round(x*100); h,n=divmod(n,360000); m,n=divmod(n,6000); s,n=divmod(n,100); return f'{h}:{m:02}:{s:02}.{n:02}'
    txt='[Script Info]\nScriptType: v4.00+\nPlayResX: 1920\nPlayResY: 1080\nWrapStyle: 0\n\n[V4+ Styles]\nFormat: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding\nStyle: Default,Nunito,56,&H00F0FAFF,&H00FFFFFF,&H003F2030,&H003F2030,-1,0,0,0,100,100,0,0,1,0,0,2,100,100,40,1\n\n[Events]\nFormat: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text\n'
    for c in d['captions']:txt+=f"Dialogue: 0,{t(c['start'])},{t(c['end'])},Default,,0,0,0,,{c['text']}\n"
    path=ROOT/'captions.ass'; path.write_text(txt,encoding='utf-8-sig'); return path
def main(mode,force=False):
    global ENTRY
    CACHE.mkdir(exist_ok=True); d=json.loads((ROOT/'timeline.json').read_text(encoding='utf-8'))
    if force or not (BUNDLE/'index.html').exists():
        run(['node',CLI,'bundle','src/v4/Root.tsx',f'--out-dir={BUNDLE}',f'--public-dir={PUB}'],EDITOR)
    ENTRY=str(BUNDLE)
    pieces=[]
    for s in d['scenes']:
        if s['kind']=='game':
            for i,c in enumerate(s['clips']):
                bg=still(s,i,80,force); dest=CACHE/f"{s['id']}-{i}.mp4"
                if mode!='graphics':part(bg,dest,c['frames'],c,d['media'][c['src']]); pieces.append(dest)
        elif s['id']=='story':
            for j,(start,n,f) in enumerate([(0,135,50),(135,120,170),(255,s['frames']-255,300)]):
                bg=still(s,j,f,force); dest=CACHE/f'story-{j}.mp4'
                if mode!='graphics':part(bg,dest,n); pieces.append(dest)
        elif s['id']=='end':
            # Preserve the recipe's actual 32–42f draw, then hold its resting frame.
            intro=CACHE/'end-marker.mp4'; props=CACHE/'end-props.json'; props.write_text(json.dumps({'id':'end','blankVideo':True}),encoding='utf-8')
            if force or not intro.exists():
                raw=CACHE/'end-marker-raw.mp4'
                run(['node',CLI,'render',ENTRY,'V4Scene',raw,'--frames=0-44','--concurrency=2',f'--props={props}',f'--browser-executable={CHROME}','--muted','--crf=18'],EDITOR)
                ffmpeg(['-i',raw,'-an','-c:v','libx264','-preset','fast','-crf','18','-threads','4','-r','30','-video_track_timescale','90000',intro])
            bg=still(s,-1,80,force); hold=CACHE/'end-hold.mp4'
            if mode!='graphics':part(bg,hold,s['frames']-45); pieces += [intro,hold]
        else:
            bg=still(s,-1,80,force); dest=CACHE/f"{s['id']}.mp4"
            if mode!='graphics':part(bg,dest,s['frames']); pieces.append(dest)
        print('GRAPHICS' if mode=='graphics' else 'SCENE',s['id'],flush=True)
    if mode=='graphics':return
    concat=CACHE/'concat.txt'; concat.write_text('\n'.join("file '"+p.as_posix()+"'" for p in pieces)+'\n',encoding='utf-8')
    clean=VIDEOS/'Oh_No_My_Hair_Pitch_v4_Clean.mp4'; ffmpeg(['-f','concat','-safe','0','-i',concat,'-an','-c:v','copy','-movflags','+faststart',clean])
    subtitle=ass(d).as_posix().replace(':','\\:'); fonts=PUB.as_posix().replace(':','\\:')
    mainfile=VIDEOS/'Oh_No_My_Hair_Pitch_v4.mp4'
    ffmpeg(['-i',clean,'-i',CACHE/'main-mix.wav','-map','0:v:0','-map','1:a:0','-vf',f"ass=filename='{subtitle}':fontsdir='{fonts}'",'-c:v','libx264','-preset','fast','-crf','18','-threads','4','-af','loudnorm=I=-16:TP=-1.5:LRA=11','-c:a','aac','-b:a','192k','-ar','48000','-movflags','+faststart',mainfile])
    ffmpeg(['-i',mainfile,'-i',CACHE/'no-bgm-mix.wav','-map','0:v:0','-map','1:a:0','-c:v','copy','-af','loudnorm=I=-16:TP=-1.5:LRA=11','-c:a','aac','-b:a','192k','-ar','48000','-movflags','+faststart',VIDEOS/'Oh_No_My_Hair_Pitch_v4_NoBGM.mp4'])
    print('DELIVERED',mainfile,flush=True)
if __name__=='__main__':
    p=argparse.ArgumentParser(); p.add_argument('mode',choices=['graphics','final']); p.add_argument('--force',action='store_true'); a=p.parse_args(); main(a.mode,a.force)
