"""Inspect the encoded delivery, including source corners, PCM timing and music."""
import hashlib,io,json,subprocess
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw,ImageFont
from build import probe
ROOT=Path(__file__).resolve().parent; PUB=ROOT.parent/'editor/public'; REVIEW=ROOT/'review'
def frame(path,t,scale=False):
    cmd=['ffmpeg','-v','error','-threads','2','-ss',str(t),'-i',str(path),'-frames:v','1','-threads','2']
    if scale:cmd+=['-vf','scale=1440:810:flags=lanczos']
    return Image.open(io.BytesIO(subprocess.check_output(cmd+['-f','image2pipe','-vcodec','png','-']))).convert('RGB')
def audio(path,sr=8000):
    return np.frombuffer(subprocess.check_output(['ffmpeg','-v','error','-i',str(path),'-f','f32le','-ar',str(sr),'-ac','1','-']),dtype='<f4').astype(float)
def correlate(x,y,expected,sr=8000):
    lo=max(0,round((expected-.15)*sr)); a=x[lo:round((expected+.15)*sr)+len(y)]; size=1<<(len(a)+len(y)-1).bit_length()
    c=np.fft.irfft(np.fft.rfft(a,size)*np.conj(np.fft.rfft(y,size)),size)[:len(a)-len(y)+1]; e=np.r_[0.,np.cumsum(a*a)]
    score=c/np.sqrt(np.maximum((e[len(y):]-e[:-len(y)])*sum(y*y),1e-12)); j=int(np.argmax(score)); return {'offset_ms':round(((lo+j)/sr-expected)*1000,3),'correlation':round(float(score[j]),4)}
def main():
    REVIEW.mkdir(exist_ok=True); d=json.loads((ROOT/'timeline.json').read_text(encoding='utf-8')); result={'checks':[],'seconds':d['frames']/30,'files':{},'corner_checks':[]}
    def check(ok,label):
        print(('PASS ' if ok else 'FAIL ')+label,flush=True); result['checks'].append({'check':label,'pass':bool(ok)})
    movies={name:ROOT.parent/f'videos/Oh_No_My_Hair_Pitch_v4{suffix}.mp4' for name,suffix in [('main',''),('nobgm','_NoBGM'),('clean','_Clean')]}
    for name,path in movies.items():
        info=probe(path); v=next(x for x in info['streams'] if x['codec_type']=='video'); duration=float(info['format']['duration'])
        result['files'][name]={'bytes':path.stat().st_size,'seconds':duration,'frames':v.get('nb_frames'),'width':v['width'],'height':v['height']}
        check(180<=duration<=300 and abs(duration-d['frames']/30)<.15,f'{name}: authored 3–5 minute duration')
        check(v['width']==1920 and v['height']==1080 and v['r_frame_rate']=='30/1' and int(v['nb_frames'])==d['frames'],f'{name}: 1080p / 30fps / exact frame count')
        check((name=='clean')==(not any(x['codec_type']=='audio' for x in info['streams'])),f'{name}: expected audio presence')
        r=subprocess.run(['ffmpeg','-v','error','-threads','2','-i',str(path),'-f','null','-'],capture_output=True,text=True)
        check(r.returncode==0 and not r.stderr.strip(),f'{name}: full decode without errors')
    check(next(i for i,s in enumerate(d['scenes']) if s['id']=='team')<min(i for i,s in enumerate(d['scenes']) if s['kind']=='game'),'team before every gameplay section')
    check(all(0<=c['start']<c['end']<=d['frames']/30 for c in d['captions']),'caption bounds valid')
    check(all(a['end']<=b['start']+.002 for a,b in zip(d['captions'],d['captions'][1:])),'captions do not overlap')
    pictures=[]
    for s in d['scenes']:
        for phase,t in [('entry',.7),('middle',s['frames']/60),('hold',s['frames']/30-.8)]:
            sec=s['from_frame']/30+t; im=frame(movies['main'],sec); im.save(REVIEW/f"final-{s['id']}-{phase}.jpg",quality=91); pictures.append((s['id'],phase,round(sec*30),im))
        for j,c in enumerate(s['clips']):
            relative=min(.2,(c['frames']-1)/30); sec=(s['from_frame']+c['from_frame'])/30+relative
            main_im=frame(movies['main'],sec).crop((240,150,1680,960))
            source_time=min(c['start']+relative*c['rate'],(c['end'] or d['media'][c['src']]['seconds'])-.05)
            source=frame(PUB/c['src'],source_time,True)
            a=np.asarray(main_im,dtype=float); b=np.asarray(source,dtype=float); values=[]
            for x,y in [(0,0),(1376,0),(0,746),(1376,746)]:
                mse=np.mean((a[y:y+64,x:x+64]-b[y:y+64,x:x+64])**2); values.append(round(float(10*np.log10(255**2/max(mse,1e-10))),2))
            result['corner_checks'].append({'scene':s['id'],'clip':j,'source_time':source_time,'corner_psnr_db':values})
            check(min(values)>28,f"{s['id']} clip {j}: all four source corners retained")
    font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',18); sheet=Image.new('RGB',(1920,((len(pictures)+3)//4)*300),'#e8d9ef'); draw=ImageDraw.Draw(sheet)
    for i,(name,phase,f,im) in enumerate(pictures):
        x=i%4*480;y=i//4*300;sheet.paste(im.resize((480,270)),(x,y));draw.text((x+8,y+275),f'{name} / {phase} / f{f}',font=font,fill='#30203f')
    sheet.save(REVIEW/'final-contact.jpg',quality=92)
    hashes={n:hashlib.sha256(subprocess.check_output(['ffmpeg','-v','error','-i',str(movies[n]),'-map','0:v:0','-c:v','copy','-f','h264','-'])).hexdigest() for n in ['main','nobgm']}
    result['picture_hashes']=hashes; check(len(set(hashes.values()))==1,'main and NoBGM pictures bit-identical')
    end=d['scenes'][-1]; qr=frame(movies['main'],end['from_frame']/30+7).crop((1380,240,1820,730)).convert('RGBA'); qr.save(REVIEW/'final-qr.png'); raw=ROOT/'cache/qr.rgba';raw.write_bytes(qr.tobytes())
    js="const fs=require('fs'),q=require('./pitch/editor/node_modules/jsqr');const r=q(new Uint8ClampedArray(fs.readFileSync(process.argv[1])),440,490);console.log(r?r.data:'NO_QR')"
    dest=subprocess.check_output(['node','-e',js,str(raw)],cwd=ROOT.parent.parent,text=True).strip();result['qr']=dest;check(dest=='https://chenhongshan333.itch.io/ohnomyhair','encoded QR opens the correct prototype')
    for name in ['Narration','Music','SFX','Music_Effects']:
        p=probe(PUB/f'v4/audio/{name}.wav'); a=p['streams'][0]; check(a['sample_rate']=='48000' and a['channels']==2 and abs(float(p['format']['duration'])-d['frames']/30)<.01,f'{name}: replaceable 48kHz stereo full-length stem')
    main_audio=audio(movies['main']); no_audio=audio(movies['nobgm']); voice=audio(PUB/'v4/audio/Narration.wav'); probes=[]
    for s in [d['scenes'][1],d['scenes'][4],d['scenes'][-2]]:
        t=s['from_frame']/30+s['lead']+1; temp=voice[round(t*8000):round((t+1)*8000)]; r=correlate(main_audio,temp,t); probes.append({'scene':s['id'],**r});check(abs(r['offset_ms'])<34 and r['correlation']>.7,f"{s['id']}: final voice matches the replacement stem")
    result['voice_alignment']=probes; coverage={}
    for s in d['scenes']:
        t=(s['from_frame']+s['frames'])/30-.7; x=main_audio[round(t*8000):round((t+.25)*8000)]; coverage[s['id']]=round(float(20*np.log10(max(np.sqrt(np.mean(x*x)),1e-12))),2)
    result['music_coverage_dbfs']=coverage;check(all(v>-70 for v in coverage.values()),'background music covers every section including final hold')
    tail=no_audio[round((d['frames']/30-.7)*8000):round((d['frames']/30-.4)*8000)];result['nobgm_tail_dbfs']=float(20*np.log10(max(np.sqrt(np.mean(tail*tail)),1e-12)));check(result['nobgm_tail_dbfs']<-80,'NoBGM final hold is silent')
    measured=subprocess.run(['ffmpeg','-hide_banner','-i',str(movies['main']),'-af','loudnorm=I=-16:TP=-1.5:LRA=11:print_format=json','-f','null','-'],capture_output=True,text=True,check=True)
    import re
    level=json.loads(re.findall(r'\{[^{}]+\}',measured.stderr)[-1]); result['loudness']=level;check(-18<=float(level['input_i'])<=-14 and float(level['input_tp'])<=-1,'encoded loudness and true peak acceptable')
    report=ROOT/'cache/replacements/7b145100c352/alignment_report.json'
    if report.exists():
        test=json.loads(report.read_text(encoding='utf-8'));(REVIEW/'replacement_alignment_test.json').write_text(json.dumps(test,indent=2)+'\n',encoding='utf-8');check(test['matched_fraction']>.7 and 180<=test['proposed_film_seconds']<=300,'single full-recording alignment rehearsal passed (AI stand-in, no human file yet)')
        sections=test['sections'];check(test['disjoint_sections'] and all(a['recording_end']<=b['recording_start'] for a,b in zip(sections,sections[1:])) and all(s['matched_fraction']>=.45 for s in sections),'replacement section crops are disjoint and confidently anchored')
    (REVIEW/'technical_checks.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    if any(not x['pass'] for x in result['checks']):raise SystemExit(1)
if __name__=='__main__':main()
