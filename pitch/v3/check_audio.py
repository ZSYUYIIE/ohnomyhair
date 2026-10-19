"""Check encoded narration / game-cue timing and measure the actual master mix."""
import argparse
import json
from pathlib import Path
import re
import subprocess
import numpy as np

ROOT=Path(__file__).resolve().parent
PUB=ROOT.parent/'editor/public/v3'
SR=8000


def decode(path):
    return np.frombuffer(subprocess.check_output(['ffmpeg','-v','error','-i',str(path),'-f','f32le','-ac','1','-ar',str(SR),'-']),dtype='<f4').astype(float)


def match(audio,template,expected):
    lo=max(0,round((expected-.2)*SR))
    hi=min(len(audio),round((expected+.2)*SR)+len(template))
    clip=audio[lo:hi]
    size=1<<(len(clip)+len(template)-1).bit_length()
    corr=np.fft.irfft(np.fft.rfft(clip,size)*np.conj(np.fft.rfft(template,size)),size)[:len(clip)-len(template)+1]
    energy=np.r_[0.,np.cumsum(clip*clip)]
    denom=np.sqrt(np.maximum((energy[len(template):]-energy[:-len(template)])*np.sum(template*template),1e-12))
    scores=corr/denom
    at=int(np.argmax(scores))
    found=(lo+at)/SR
    return {'expected_seconds':round(expected,4),'found_seconds':round(found,4),'offset_ms':round((found-expected)*1000,2),'correlation':round(float(scores[at]),4)}


def main(nobgm=False):
    timeline=json.loads((ROOT/'timeline.json').read_text(encoding='utf-8'))
    movie=ROOT.parent/('videos/Oh_No_My_Hair_Pitch_v3_NoBGM.mp4' if nobgm else 'videos/Oh_No_My_Hair_Pitch_v3.mp4')
    audio=decode(movie)
    result={'method':'Normalized waveform correlation in the final encoded mix, +/-200ms search; no subjective listening claim.','criteria':'Source-locked SFX: <=1 frame. Non-lip-synced spoken captions: <=80ms. Report actual offsets separately; these are not zero-offset claims.','checks':[]}
    def check(name,item,tolerance_ms=1000/30):
        item.update(name=name,tolerance_ms=round(tolerance_ms,3),passed=abs(item['offset_ms'])<=tolerance_ms and item['correlation']>=.45)
        result['checks'].append(item)
        print(name,item,flush=True)
    for name in ['story','roles','proof','plan','budget','end']:
        scene=timeline['scenes'][name]
        source=decode(PUB/f'voice/{name}.mp3')
        clip=source[round(.8*SR):round(1.8*SR)]
        expected=scene['from_frame']/30+scene['lead']+.8
        check('narration / '+name,match(audio,clip,expected),80)
    for name,source_at,movie_at in [('opening gel smash',5.5267,5.5267-2.3),('opening grab',4.7266,4.7266-2.3)]:
        source=decode(PUB/'sling.mp4')
        clip=source[round(source_at*SR):round((source_at+.24)*SR)]
        check(name,match(audio,clip,movie_at))
    parry=timeline['scenes']['parry']
    demo=max(8,round((parry['lines_timing'][1]['start']+parry['lead'])*30)/30)
    source=decode(PUB/'parry.mp4')
    source_at=18.445
    check('relay bell',match(audio,source[round(source_at*SR):round((source_at+.3)*SR)],parry['from_frame']/30+demo+source_at-15.5))
    measured=subprocess.run(['ffmpeg','-hide_banner','-i',str(movie),'-af','loudnorm=I=-16:TP=-1.5:LRA=11:print_format=json','-f','null','-'],capture_output=True,text=True,check=True)
    level=json.loads(re.findall(r'\{[^{}]+\}',measured.stderr)[-1])
    result['loudness']=level
    result['loudness_passed']=-18<=float(level['input_i'])<=-14 and float(level['input_tp'])<=-.8
    tail=audio[250*SR:252*SR]
    result['quiet_tail_dbfs']=round(float(20*np.log10(max(np.sqrt(np.mean(tail*tail)),1e-12))),2)
    if nobgm:
        result['no_music_tail_passed']=result['quiet_tail_dbfs'] < -80
    else:
        holds=[14.,26.5,43.5,71.5,98.5,118.5,128.633,142.633,161.167,179.467,195.1,219.633,238.133,251.]
        result['music_coverage_dbfs']={str(t):round(float(20*np.log10(max(np.sqrt(np.mean(audio[round(t*SR):round((t+.3)*SR)]**2)),1e-12))),2) for t in holds}
        result['music_coverage_passed']=all(value > -65 for value in result['music_coverage_dbfs'].values())
    print('Loudness',level['input_i'],'LUFS; true peak',level['input_tp'],'dBTP',flush=True)
    (ROOT/('review/audio_checks_nobgm.json' if nobgm else 'review/audio_checks.json')).write_text(json.dumps(result,indent=2),encoding='utf-8')
    if not all(c['passed'] for c in result['checks']) or not result['loudness_passed'] or result.get('no_music_tail_passed') is False or result.get('music_coverage_passed') is False:
        raise SystemExit(1)


if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--nobgm',action='store_true')
    main(parser.parse_args().nobgm)
