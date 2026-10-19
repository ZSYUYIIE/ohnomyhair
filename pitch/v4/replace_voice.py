"""One full recording in; aligned paragraphs, retimed film and captions out."""
import argparse,difflib,hashlib,json,re,shutil,subprocess,sys
import numpy as np
from pathlib import Path
ROOT=Path(__file__).resolve().parent; PUB=ROOT.parent/'editor/public/v4/voice'
def normalize(x):return re.sub(r'[^a-z0-9]','',x.lower())
def prepare(recording,check_only=False):
    from faster_whisper import WhisperModel
    from build import probe
    recording=Path(recording).resolve()
    key=hashlib.sha256(recording.read_bytes()).hexdigest(); work=ROOT/'cache/replacements'/key[:12]; work.mkdir(parents=True,exist_ok=True)
    transcript=work/'transcript.json'
    if transcript.exists():words=json.loads(transcript.read_text(encoding='utf-8'))
    else:
        model=WhisperModel('base.en',device='cpu',compute_type='int8',cpu_threads=4,num_workers=1,download_root=str(ROOT.parent.parent/'build/pitch-v4-models'))
        # FFmpeg decoding also accepts phone M4A files and avoids PyAV-version coupling.
        audio=np.frombuffer(subprocess.check_output(['ffmpeg','-v','error','-i',str(recording),'-f','f32le','-ar','16000','-ac','1','-']),dtype='<f4')
        segments,_=model.transcribe(audio,language='en',beam_size=5,word_timestamps=True,vad_filter=True,condition_on_previous_text=False)
        words=[{'text':w.word.strip(),'start':w.start,'end':w.end} for s in segments for w in s.words]
        transcript.write_text(json.dumps(words,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    scenes=json.loads((ROOT/'script.json').read_text(encoding='utf-8')); tokens=[]; ranges=[]
    for s in scenes:
        start=len(tokens); tokens+=s['text'].split(); ranges.append((start,len(tokens)))
    # Match hyphenated words as subwords, while keeping script-token ownership.
    def expand(items):
        units=[]; owners=[]
        for i,text in enumerate(items):
            for part in re.findall(r"[A-Za-z0-9]+(?:'[A-Za-z]+)?",text):
                units.append(normalize(part)); owners.append(i)
        return units,owners
    left,li=expand(tokens); right,ri=expand([w['text'] for w in words]); anchors={}
    for block in difflib.SequenceMatcher(None,left,right,autojunk=False).get_matching_blocks():
        for n in range(block.size):
            i=li[block.a+n]; w=words[ri[block.b+n]]
            if i in anchors:anchors[i]={'start':min(anchors[i]['start'],w['start']),'end':max(anchors[i]['end'],w['end'])}
            else:anchors[i]={'start':w['start'],'end':w['end']}
    coverage=len(anchors)/len(tokens)
    if coverage<.70:raise ValueError(f'Only {coverage:.0%} of the script matched; inspect {transcript}. Original film untouched.')
    aligned=[None]*len(tokens); section_spans=[]
    for a,b in ranges:
        local=[i for i in anchors if a<=i<b]
        if not local:raise ValueError('A paragraph has no confident spoken anchors. Original film untouched.')
        first,last=min(local),max(local)
        if first-a>2 or b-1-last>2:raise ValueError('A paragraph edge is uncertain. Original film untouched; inspect transcript.')
        section_spans.append((max(0,anchors[first]['start']-.18*(first-a)),anchors[last]['end']+.18*(b-1-last)))
        for i in range(a,b):
            if i in anchors:aligned[i]={'text':tokens[i],**anchors[i]};continue
            l=max((j for j in local if j<i),default=None); r=min((j for j in local if j>i),default=None)
            if l is None:start=max(0,anchors[r]['start']-.18*(r-i)); end=start+.16
            elif r is None:start=anchors[l]['end']+.18*(i-l-1); end=start+.16
            else:
                start=anchors[l]['end']+(anchors[r]['start']-anchors[l]['end'])*(i-l-1)/(r-l-1)
                end=anchors[l]['end']+(anchors[r]['start']-anchors[l]['end'])*(i-l)/(r-l-1)
            aligned[i]={'text':tokens[i],'start':start,'end':max(start+.02,end)}
    duration=float(probe(recording)['format']['duration'])
    boundaries=[0]+[(a[1]+b[0])/2 for a,b in zip(section_spans,section_spans[1:])]+[duration]
    report={'recording':str(recording),'sha256':key,'matched_fraction':coverage,'sections':[],'check_only':check_only}
    for index,(s,(a,b)) in enumerate(zip(scenes,ranges)):
        matched=sum(i in anchors for i in range(a,b))/(b-a)
        if matched<.45:raise ValueError(f"Section {s['id']} did not match confidently. Original film untouched.")
        block=aligned[a:b]; start=max(boundaries[index],section_spans[index][0]-.15); end=min(boundaries[index+1],section_spans[index][1]+.25)
        wav=work/f"{s['id']}.wav"
        subprocess.run(['ffmpeg','-y','-v','error','-i',str(recording),'-ss',str(start),'-to',str(end),'-ac','2','-ar','48000',str(wav)],check=True)
        seconds=float(probe(wav)['format']['duration'])
        data={'key':'human:'+key,'voice':'user full recording','seconds':seconds,'words':[{'text':w['text'],'start':max(0,w['start']-start),'end':min(seconds,w['end']-start)} for w in block]}
        (work/f"{s['id']}.json").write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
        report['sections'].append({'id':s['id'],'recording_start':start,'recording_end':end,'matched_fraction':matched,'speech_seconds':seconds,'film_seconds':max(s['minimum'],seconds+1.8)})
    report['proposed_film_seconds']=sum(s['film_seconds'] for s in report['sections'])
    report['disjoint_sections']=all(a['recording_end']<=b['recording_start'] for a,b in zip(report['sections'],report['sections'][1:]))
    if not report['disjoint_sections']:raise ValueError('Paragraph crops overlap; original film untouched.')
    (work/'alignment_report.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print('Matched',round(coverage*100,1),'%; retimed length',round(report['proposed_film_seconds'],2),'s; report:',work/'alignment_report.json',flush=True)
    if not 180<=report['proposed_film_seconds']<=300:raise ValueError('Recording would put the film outside 3–5 minutes. Original film untouched; alignment report is saved.')
    if check_only:return
    backup=ROOT/'cache/voice-before-replacement'; backup.mkdir(exist_ok=True)
    for s in scenes:
        for suffix in ('.wav','.json'):
            name=s['id']+suffix
            if not (backup/name).exists():shutil.copy2(PUB/name,backup/name)
            shutil.copy2(work/name,PUB/name)
    # No TTS generation: all later steps use the user's recording.
    for command in [['build.py'],['mix_audio.py'],['render.py','final','--force'],['qa.py']]:
        subprocess.run([sys.executable,str(ROOT/command[0]),*command[1:]],check=True,cwd=ROOT.parent.parent)
if __name__=='__main__':
    p=argparse.ArgumentParser(); p.add_argument('recording'); p.add_argument('--check-only',action='store_true'); a=p.parse_args(); prepare(a.recording,a.check_only)
