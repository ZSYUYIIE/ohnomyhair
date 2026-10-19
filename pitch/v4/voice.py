"""One AI narrator, cached sections, PCM WAVs, original word boundaries."""
import asyncio,hashlib,json,subprocess,sys
from pathlib import Path
import edge_tts
ROOT=Path(__file__).resolve().parent
PUB=ROOT.parent/'editor/public/v4/voice'
VOICE='en-US-AnaNeural'
async def main():
    PUB.mkdir(parents=True,exist_ok=True)
    for s in json.loads((ROOT/'script.json').read_text(encoding='utf-8')):
        key=hashlib.sha256((VOICE+'+2%|+1Hz|'+s['text']).encode()).hexdigest()
        meta=PUB/f"{s['id']}.json"; mp3=PUB/f"{s['id']}.mp3"; wav=PUB/f"{s['id']}.wav"
        if meta.exists() and wav.exists() and json.loads(meta.read_text())['key']==key:
            print('CACHED',s['id'],flush=True); continue
        for attempt in range(10):
            try:
                words=[]; chunks=[]
                async for c in edge_tts.Communicate(s['text'],VOICE,rate='+2%',pitch='+1Hz',boundary='WordBoundary').stream():
                    if c['type']=='audio': chunks.append(c['data'])
                    elif c['type']=='WordBoundary': words.append({'text':c['text'],'start':c['offset']/1e7,'end':(c['offset']+c['duration'])/1e7})
                if not chunks or not words: raise RuntimeError('No audio/word timing')
                mp3.write_bytes(b''.join(chunks))
                subprocess.run(['ffmpeg','-y','-v','error','-i',str(mp3),'-ac','2','-ar','48000',str(wav)],check=True)
                seconds=float(subprocess.check_output(['ffprobe','-v','error','-show_entries','format=duration','-of','csv=p=0',str(wav)],text=True))
                meta.write_text(json.dumps({'key':key,'voice':VOICE,'seconds':seconds,'words':words},indent=2)+'\n',encoding='utf-8')
                print('VOICE',s['id'],round(seconds,2),flush=True); break
            except Exception as e:
                print('RETRY',s['id'],attempt+1,type(e).__name__,flush=True)
                if attempt==9: raise
                await asyncio.sleep(min(2+attempt,10))
if __name__=='__main__': asyncio.run(main())
