"""Sample-based music loops and source-locked SFX from the shared cut manifest."""
import json,subprocess,wave
from pathlib import Path
import numpy as np
ROOT=Path(__file__).resolve().parent; PUB=ROOT.parent/'editor/public'; SR=48000
def read(path):
    return np.frombuffer(subprocess.check_output(['ffmpeg','-v','error','-i',str(path),'-f','f32le','-ar',str(SR),'-ac','2','-']),dtype='<f4').reshape(-1,2).copy()
def write(path,x,floating=False):
    path.parent.mkdir(parents=True,exist_ok=True)
    if floating:
        subprocess.run(['ffmpeg','-y','-v','error','-f','f32le','-ar',str(SR),'-ac','2','-i','-','-c:a','pcm_f32le',str(path)],input=x.astype('<f4').tobytes(),check=True)
    else:
        with wave.open(str(path),'wb') as f:
            f.setparams((2,2,SR,0,'NONE','not compressed')); f.writeframes((np.clip(x,-1,1)*32767).astype('<i2').tobytes())
def main():
    d=json.loads((ROOT/'timeline.json').read_text(encoding='utf-8')); count=round(d['frames']/30*SR)
    voice=np.zeros((count,2),np.float32); sfx=np.zeros_like(voice); cache={}; gains={}
    for s in d['scenes']:
        v=read(PUB/s['voice']); gain=min(2.,.8/max(float(np.max(np.abs(v))),.01)); gains[s['id']]=gain
        at=round((s['from_frame']/30+s['lead'])*SR); n=min(len(v),count-at); voice[at:at+n]+=v[:n]*gain
        for c in s['clips']:
            if not c['audio'] or not d['media'][c['src']]['audio']:continue
            if c['src'] not in cache:cache[c['src']]=read(PUB/c['src'])
            source=cache[c['src']]; start=round(c['start']*SR); end=round(min(c['end'] or len(source)/SR,len(source)/SR)*SR)
            samples=min(round(c['frames']/30*SR),max(0,round((end-start)/c['rate'])))
            pos=start+np.arange(samples)*c['rate']; x=np.stack([np.interp(pos,np.arange(len(source)),source[:,j]) for j in range(2)],axis=1).astype(np.float32)
            at=round((s['from_frame']+c['from_frame'])/30*SR); sfx[at:at+samples]+=.7*x[:min(samples,count-at)]
    music_source=read(ROOT.parent.parent/'assets/audio/music/calm.wav')
    music=np.tile(music_source,(int(np.ceil(count/len(music_source))),1))[:count].copy()
    t=np.arange(count,dtype=np.float32)/SR; envelope=np.minimum(np.clip(t,0,1),np.clip((count/SR-t)/2,0,1))*.13
    for s in d['scenes']:
        a=s['from_frame']/30+s['lead']; b=a+s['voice_seconds']
        duck=np.interp(t,[a-.18,a+.03,b,b+.35],[1,.5,.5,1]).astype(np.float32); envelope*=duck
    music*=envelope[:,None]
    boss=next(s for s in d['scenes'] if s['id']=='boss'); src=read(ROOT.parent.parent/'assets/audio/music/boss.wav'); at=round(boss['from_frame']/30*SR); n=round(boss['frames']/30*SR)
    music[at:at+n]+=.035*np.tile(src,(int(np.ceil(n/len(src))),1))[:n]
    out=PUB/'v4/audio'
    for name,x in [('Narration',voice),('SFX',sfx),('Music',music),('Music_Effects',music+sfx)]:write(out/f'{name}.wav',x)
    write(ROOT/'cache/main-mix.wav',voice+sfx+music,True); write(ROOT/'cache/no-bgm-mix.wav',voice+sfx,True)
    (ROOT/'review').mkdir(exist_ok=True)
    (ROOT/'review/audio_mix.json').write_text(json.dumps({'sample_rate':SR,'samples':count,'seconds':count/SR,'voice_gains':gains,'music_loop_samples':len(music_source),'music_loop_method':'repeat exact PCM samples, then duck under each voice interval','peaks':{'voice':float(np.max(np.abs(voice))),'effects':float(np.max(np.abs(sfx))),'music':float(np.max(np.abs(music)))}},indent=2)+'\n',encoding='utf-8')
    print('PCM stems and two source mixes ready',flush=True)
if __name__=='__main__':main()
