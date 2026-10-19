"""One frame-based edit manifest for the preview, final export and voice replacement."""
import importlib.util,json,math,subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parent; PUB=ROOT.parent/'editor/public'; FPS=30
def probe(path):
    return json.loads(subprocess.check_output(['ffprobe','-v','error','-show_format','-show_streams','-of','json',str(path)],text=True))
def stamp(t):
    n=round(t*1000); h,n=divmod(n,3600000); m,n=divmod(n,60000); s,n=divmod(n,1000)
    return f'{h:02}:{m:02}:{s:02},{n:03}'
def cuts(scene):
    i=scene['id']; d=scene['frames']; plan=[]; clock=0
    def spoken(word,default):
        return next((w['start']+.5 for w in scene['word_timing'] if w['text'].lower().strip('.,?!')==word.lower()),default)
    def add(src,start,seconds,label,rate=1,audio=True,end=None,rail=-1):
        nonlocal clock
        frames=min(d-clock,round(seconds*30) if seconds is not None else d-clock)
        if frames<=0:return
        plan.append(dict(src='v4/'+src+'.mp4',start=start,frames=frames,from_frame=clock,label=label,rate=rate,audio=audio,end=end,rail=rail)); clock+=frames
    if i=='roles':
        switch=spoken('Pompadour',5); launch=spoken('launch',9)
        add('roles',2,switch,'TWIN-TAILS · Glide + carry'); add('sling',3.3,launch-switch,'POMPADOUR · Dash through gel'); add('roles',4.5,5.7,'POMPADOUR · Launch your friend'); add('roles',1.8,None,'REPLAY · Complementary powers',audio=False)
    elif i=='sling':
        add('failure',.8,spoken('So',8.4),'THE PROBLEM · Regrowing gel'); add('sling',3,7.4,'THE SLING · Carry → dash → follow'); add('sling',4.4,None,'REPLAY · 0.8×',.8,False)
    elif i=='parry':
        add('parry',1.8,max(4,spoken('catches',9.24)-1.8),'THE PROBLEM · A horizontal parry'); start=15.5
        for seconds,rail in [(1.8,0),(.5,1),(2/3,2),(None,3)]:
            add('parry',start,seconds,'RETURN TO SENDER',end=29.4,rail=rail)
            if seconds:start+=round(seconds*30)/30
    elif i=='salon':
        add('water',1,spoken('Warm',6.6),'WET HAIR · No glide. No gel smash.'); add('dryer',1,3.4,'WARM AIR · Dry off'); add('dryer',7.4,6.1,'RISE TOGETHER'); add('wet_coop',5,None,'WAIT FOR THE SHOWER GAP')
    elif i=='swap':add('swap',0,None,'HAIRCUT SWAP · Switch jobs')
    elif i=='boss':
        later=spoken('Later',6.9); stun=spoken('Stun',11)
        add('boss_wide',1,later,'THE ASSISTANT · Scissors + pressure'); add('boss_wide',6,stun-later,'PHASE TWO · Showers + reinforcements'); add('boss',.6,4.2,'STUN → LAUNCH → STOMP'); add('boss',1.3,None,'REPLAY · Finish the combo',.8,False)
    return plan
def main():
    spec=importlib.util.spec_from_file_location('v3build',ROOT.parent/'v3/build.py'); old=importlib.util.module_from_spec(spec); spec.loader.exec_module(old)
    scenes=json.loads((ROOT/'script.json').read_text(encoding='utf-8')); allcaps=[]; clock=0
    for s in scenes:
        timing=json.loads((PUB/f'v4/voice/{s["id"]}.json').read_text(encoding='utf-8'))
        s.update(lead=.5,voice_seconds=timing['seconds'],voice=f'v4/voice/{s["id"]}.wav')
        s['frames']=math.ceil(max(s['minimum'],s['voice_seconds']+1.8)*30); s['from_frame']=clock
        words=timing['words']; original=s['text'].split()
        import re
        norm=lambda x:re.sub('[^a-z0-9]','',x.lower())
        if len(words)==len(original) and all(norm(w['text'])==norm(t) for w,t in zip(words,original)):
            words=[{**w,'text':t,'speaker':'narrator'} for w,t in zip(words,original)]
        else:words=[{**w,'speaker':'narrator'} for w in words]
        s['word_timing']=words; s['captions']=old.captions(words,.5); s['clips']=cuts(s)
        for cap in s['captions']: allcaps.append({**cap,'start':clock/30+cap['startMs']/1000,'end':clock/30+cap['endMs']/1000})
        clock+=s['frames']
    if not 180<=clock/30<=300:raise ValueError(f'Pitch length {clock/30:.2f}s outside 3–5 minutes')
    media={}
    for path in (PUB/'v4').glob('*.mp4'):
        p=probe(path); media['v4/'+path.name]={'seconds':float(p['format']['duration']),'audio':any(x['codec_type']=='audio' for x in p['streams'])}
    data={'fps':30,'frames':clock,'panel':{'x':240,'y':150,'width':1440,'height':810},'scenes':scenes,'media':media,'captions':allcaps}
    (ROOT/'timeline.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    (PUB/'v4/timeline.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    src=ROOT.parent/'editor/src/v4'; src.mkdir(exist_ok=True)
    (src/'data.ts').write_text('export const DATA = '+json.dumps(data,ensure_ascii=False)+';\n',encoding='utf-8')
    (ROOT.parent/'videos/Oh_No_My_Hair_Pitch_v4.en.srt').write_text('\n\n'.join(f"{n+1}\n{stamp(c['start'])} --> {stamp(c['end'])}\n{c['text']}" for n,c in enumerate(allcaps))+'\n',encoding='utf-8')
    (ROOT/'storyboard.txt').write_text('\n\n'.join(f"{stamp(s['from_frame']/30)} | {s['id']} | {s['frames']/30:.2f}s\n{s['text']}\n" for s in scenes),encoding='utf-8')
    print(f'{len(scenes)} scenes / {clock} frames / {clock/30:.2f}s',flush=True)
if __name__=='__main__':main()
