"""Delivery checks: media decode, time bounds, picture parity, captions and QA frames."""
import argparse
import hashlib
import io
import json
from pathlib import Path
import subprocess
from PIL import Image,ImageDraw,ImageFont

ROOT=Path(__file__).resolve().parent
VIDEOS=ROOT.parent/'videos'
REVIEW=ROOT/'review'


def probe(path):
    return json.loads(subprocess.check_output(['ffprobe','-v','error','-show_streams','-show_format','-of','json',str(path)],text=True))


def frame(path,seconds,width=None):
    cmd=['ffmpeg','-v','error','-threads','2','-ss',str(seconds),'-i',str(path),'-frames:v','1','-threads','2']
    if width:
        cmd+=['-vf',f'scale={width}:-1']
    return Image.open(io.BytesIO(subprocess.check_output(cmd+['-f','image2pipe','-vcodec','png','-']))).convert('RGB')


def main(decode,main_only=False):
    REVIEW.mkdir(exist_ok=True)
    data=json.loads((ROOT/'timeline.json').read_text(encoding='utf-8'))
    expected=data['frames']/data['fps']
    result={'scope':'main-only' if main_only else 'all-deliverables','expected_seconds':expected,'checks':[],'files':{}}
    def check(condition,label):
        result['checks'].append({'pass':bool(condition),'check':label})
        print(('PASS ' if condition else 'FAIL ')+label,flush=True)
    paths={name:VIDEOS/f'Oh_No_My_Hair_Pitch_v3{suffix}.mp4' for name,suffix in [('main',''),('nobgm','_NoBGM'),('clean','_Clean')]}
    if main_only:
        paths={'main':paths['main']}
    for name,path in paths.items():
        if not path.exists():
            check(False,f'{name} exists')
            continue
        info=probe(path)
        video=next(s for s in info['streams'] if s['codec_type']=='video')
        duration=float(info['format']['duration'])
        result['files'][name]={'path':str(path),'bytes':path.stat().st_size,'seconds':duration,'video_codec':video['codec_name'],'width':video['width'],'height':video['height'],'fps':video['r_frame_rate']}
        check(180<=duration<=300,f'{name} duration within 3–5 minutes')
        check(abs(duration-expected)<.15,f'{name} follows the authored timeline')
        check(video['width']==1920 and video['height']==1080 and video['r_frame_rate']=='30/1',f'{name} is 1080p / 30fps')
        if name=='clean':
            check(not any(s['codec_type']=='audio' for s in info['streams']),'clean picture has no audio')
        else:
            audio=next(s for s in info['streams'] if s['codec_type']=='audio')
            check(audio['codec_name']=='aac' and audio['sample_rate']=='48000',f'{name} has AAC / 48kHz audio')
        if decode:
            r=subprocess.run(['ffmpeg','-v','error','-threads','2','-i',str(path),'-f','null','-'],capture_output=True,text=True)
            check(r.returncode==0 and not r.stderr.strip(),f'{name} fully decodes without errors')
    if not main_only:
        for name in ('Voiceover','Music_Effects','Music'):
            path=ROOT/f'Oh_No_My_Hair_v3_{name}.wav'
            if not path.exists():
                check(False,f'{name} stem exists')
                continue
            info=probe(path)
            stream=next(s for s in info['streams'] if s['codec_type']=='audio')
            duration=float(info['format']['duration'])
            check(abs(duration-expected)<.05,f'{name} stem starts at zero and covers the complete timeline')
            check(stream['sample_rate']=='48000',f'{name} stem uses 48kHz')
            result['files'][name]={'seconds':duration,'sample_rate':stream['sample_rate'],'channels':stream['channels'],'bytes':path.stat().st_size}
    caps=[]
    for s in data['scenes'].values():
        caps += [(s['from_frame']/30+c['startMs']/1000,s['from_frame']/30+c['endMs']/1000) for c in s['captions']]
    check(all(a>=0 and a<b<=expected for a,b in caps),'all captions have valid time bounds')
    check(all(a[1]<=b[0]+.002 for a,b in zip(caps,caps[1:])),'caption phrases do not overlap')
    if paths['main'].exists():
        shots=[]
        for name,s in data['scenes'].items():
            for phase,relative in [('entry',.6),('middle',s['frames']/60),('hold',s['frames']/30-1)]:
                sec=s['from_frame']/30+relative
                picture=frame(paths['main'],sec)
                out=REVIEW/f'final-{name}-{phase}.jpg'
                picture.save(out,quality=91)
                shots.append((name,phase,round(sec*30),picture))
        font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',18)
        sheet=Image.new('RGB',(1920,((len(shots)+3)//4)*300),'#dedede')
        draw=ImageDraw.Draw(sheet)
        for i,(name,phase,f,picture) in enumerate(shots):
            x,y=i%4*480,i//4*300
            sheet.paste(picture.resize((480,270)),(x,y))
            draw.text((x+8,y+275),f'{name} / {phase} / f{f}',font=font,fill='black')
        sheet.save(REVIEW/'final-contact.jpg',quality=92)
        # Exact shared H.264 stream, independently verified by extracted bitstream hash.
        if 'nobgm' in paths and paths['nobgm'].exists():
            hashes=[]
            for name in ('main','nobgm'):
                raw=subprocess.check_output(['ffmpeg','-v','error','-i',str(paths[name]),'-map','0:v:0','-c:v','copy','-f','h264','-'])
                hashes.append(hashlib.sha256(raw).hexdigest())
            check(hashes[0]==hashes[1],'main and NoBGM share a bit-identical picture stream')
            result['picture_sha256']=hashes
        # QR is checked using the project's existing jsQR dependency.
        end=data['scenes']['end']
        qr=frame(paths['main'],end['from_frame']/30+7).crop((1380,240,1820,730)).convert('RGBA')
        qr.save(REVIEW/'final-qr.png')
        raw=REVIEW/'qr.rgba'
        raw.write_bytes(qr.tobytes())
        js="const fs=require('fs');const qr=require('./pitch/editor/node_modules/jsqr');const a=fs.readFileSync(process.argv[1]);const r=qr(new Uint8ClampedArray(a),440,490);console.log(r?r.data:'NO_QR');"
        r=subprocess.run(['node','-e',js,str(raw)],cwd=ROOT.parent.parent,capture_output=True,text=True)
        result['qr_destination']=r.stdout.strip()
        check(r.returncode==0 and r.stdout.strip()=='https://chenhongshan333.itch.io/ohnomyhair','final frame QR decodes to the public prototype')
    (REVIEW/'technical_checks.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    if any(not x['pass'] for x in result['checks']):
        raise SystemExit(1)


if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--decode',action='store_true')
    parser.add_argument('--main-only',action='store_true')
    args=parser.parse_args()
    main(args.decode,args.main_only)
