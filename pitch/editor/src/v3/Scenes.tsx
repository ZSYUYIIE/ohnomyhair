import React,{createContext,useContext} from 'react';
import {AbsoluteFill,Audio as ClipAudio,CanvasImage,Easing,Freeze,Interactive,Loop,OffthreadVideo as Video,Sequence,interpolate,staticFile,useCurrentFrame,useVideoConfig} from 'remotion';
import {loadFont} from '@remotion/fonts';
import type {Caption} from '@remotion/captions';
import {CLIPS,SECTIONS,TOTAL} from './data';
import {MarkerUnderline} from './Marker';

loadFont({family:'Fredoka',url:staticFile('Fredoka.ttf')});
loadFont({family:'Nunito',url:staticFile('Nunito.ttf')});
const INK='#30203f',CREAM='#fff5df',GOLD='#ffdd47',PINK='#f65a9d',BLUE='#74c7e5',LILAC='#e8d9ef';
export const V3AudioMode=createContext(false);
const ease=Easing.bezier(.16,1,.3,1);
const clamped={extrapolateLeft:'clamp' as const,extrapolateRight:'clamp' as const};
const entrance=(f:number,delay=0)=>interpolate(f,[delay,delay+22],[0,1],{...clamped,easing:ease});
const panel:React.CSSProperties={border:`5px solid ${INK}`,borderRadius:28,boxShadow:`0 9px 0 ${INK}`};

const Paper=()=> <AbsoluteFill style={{background:CREAM}}><div style={{position:'absolute',right:-180,top:-350,width:1250,height:1250,borderRadius:'50%',background:LILAC,opacity:.65}}/><div style={{position:'absolute',left:-250,bottom:-500,width:1100,height:1100,borderRadius:'50%',background:'#ffe3b9',opacity:.65}}/><div style={{position:'absolute',right:0,top:0,bottom:0,width:22,background:`repeating-linear-gradient(150deg,${PINK} 0 28px,${CREAM} 28px 56px,${BLUE} 56px 84px,${CREAM} 84px 112px)`}}/></AbsoluteFill>;
const Header=({number,title,dark=false}:{number:string;title:string;dark?:boolean})=>{
 const f=useCurrentFrame(),p=entrance(f);
 return <div style={{position:'absolute',left:80,top:60,display:'flex',gap:22,alignItems:'center',opacity:p,translate:`0 ${(1-p)*20}px`,color:dark?CREAM:INK}}><div style={{fontFamily:'Nunito',fontSize:32,fontWeight:900,letterSpacing:3,color:dark?GOLD:'#8b698d'}}>{number}</div><div style={{fontSize:61,fontWeight:650,lineHeight:1.1}}>{title}</div></div>;
};
const Label=({children,color=GOLD,style={}}:{children:React.ReactNode;color?:string;style?:React.CSSProperties})=><div style={{...panel,boxShadow:`0 5px 0 ${INK}`,background:color,padding:'12px 24px',fontFamily:'Nunito',fontSize:36,fontWeight:900,lineHeight:1.2,display:'inline-block',color:INK,...style}}>{children}</div>;
const Friends=({width=800,height=470}:{width?:number;height?:number})=>{
 const s=Math.min(width/456,height/255);
 return <div style={{position:'relative',width,height,overflow:'hidden'}}><CanvasImage src={staticFile('map_friends.png')} style={{position:'absolute',width:1280*s,height:720*s,left:(width-456*s)/2-412*s,top:(height-255*s)/2-280*s}}/></div>;
};

type ClipProps={src:string;start?:number;end?:number;rate?:number;zoom?:number;focusX?:number;focusY?:number;gameAudio?:boolean;tag?:string};
const Footage=({src,start=0,end,rate=1,zoom=1,focusX=.5,focusY=.5,gameAudio=true,tag}:ClipProps)=>{
 const f=useCurrentFrame(),{fps}=useVideoConfig(),meta=CLIPS[src]??{seconds:10,audio:false};
 const last=Math.max(0,Math.floor(((end?Math.min(end,meta.seconds):meta.seconds)-start)*fps/rate)-2);
 const audioOnly=useContext(V3AudioMode);
 // Audio exports keep the same clip boundaries without decoding unused pictures.
 if(audioOnly) return gameAudio&&meta.audio?<Sequence durationInFrames={last+1}><ClipAudio src={staticFile(src)} trimBefore={Math.round(start*fps)} playbackRate={rate}/></Sequence>:null;
 const video=<Video name="Real Godot capture" src={staticFile(src)} trimBefore={Math.round(start*fps)} playbackRate={rate} muted={!gameAudio||!meta.audio} style={{width:1920,height:1080,objectFit:'contain'}}/>;
 return <AbsoluteFill style={{background:INK,overflow:'hidden'}}><AbsoluteFill style={{scale:zoom,transformOrigin:`${focusX*100}% ${focusY*100}%`}}>{f<=last?video:<Freeze frame={last}><Video src={staticFile(src)} trimBefore={Math.round(start*fps)} playbackRate={rate} muted style={{width:1920,height:1080,objectFit:'contain'}}/></Freeze>}</AbsoluteFill>{tag&&<div style={{position:'absolute',right:70,top:48}}><Label style={{fontSize:32,background:CREAM}}>{tag}</Label></div>}</AbsoluteFill>;
};
const GameClip=Interactive.create({Component:Footage,layout:'absolute-fill',schema:{src:{type:'string',default:'v3/sling.mp4',description:'Public media path'},start:{type:'number',hiddenFromList:false,default:0,description:'Source in-point (seconds)'},rate:{type:'number',hiddenFromList:false,default:1,description:'Playback speed'},zoom:{type:'number',hiddenFromList:false,default:1,description:'Editorial crop scale'}}});
const ImageShot=({src,scale=1.03}:{src:string;scale?:number})=>{
 const f=useCurrentFrame();
 return <AbsoluteFill style={{overflow:'hidden',background:CREAM}}><CanvasImage src={staticFile(src)} style={{width:'100%',height:'100%',objectFit:'cover',scale:interpolate(f,[0,420],[1,scale],clamped)}}/></AbsoluteFill>;
};

const Hero=()=>{
 const f=useCurrentFrame(),p=entrance(f);
 return <AbsoluteFill><CanvasImage src={staticFile("title_cover.png")} style={{position:"absolute",inset:0,width:1920,height:1080,objectFit:"cover"}}/><AbsoluteFill style={{background:'linear-gradient(90deg,#30203f 0%,#30203f 45%,rgba(48,32,63,.92) 53%,rgba(48,32,63,.15) 77%,transparent)'}}/><div style={{position:'absolute',left:100,top:120,color:CREAM,fontFamily:'Nunito',fontSize:34,fontWeight:900,letterSpacing:5,opacity:p}}>NPC UNION</div><div style={{position:'absolute',left:94,top:240,color:GOLD,fontSize:176,fontWeight:700,lineHeight:.98,opacity:p,translate:`0 ${(1-p)*40}px`}}>OH NO<br/>MY HAIR!</div><div style={{position:'absolute',left:104,top:690,color:CREAM,fontFamily:'Nunito',fontSize:53,fontWeight:850,lineHeight:1.25,opacity:entrance(f,12)}}>A two-player<br/>puzzle platformer</div><div style={{position:'absolute',right:100,bottom:160}}><Label color={GOLD}>Bad hair. Good friends.</Label></div></AbsoluteFill>;
};

// Local caption presentation: large, calm phrase groups; no karaoke motion.
export const V3Captions=({captions}:{captions:Caption[]})=>{
 const f=useCurrentFrame(),{fps}=useVideoConfig(),ms=f/fps*1000,c= captions.find(x=>ms>=x.startMs&&ms<x.endMs);
 return c?<div style={{position:'absolute',left:90,right:90,bottom:80,minHeight:86,padding:'14px 26px',borderRadius:20,background:'rgba(38,24,51,.96)',color:'#fffaf0',fontFamily:'Nunito',fontSize:56,fontWeight:800,lineHeight:1.16,textAlign:'center',display:'flex',justifyContent:'center',alignItems:'center'}}>{c.text}</div>:null;
};

const ProcessRail=({step}:{step:number})=> <div style={{position:'absolute',left:120,right:120,top:170,display:'flex',gap:18,justifyContent:'center'}}>{['PARRY','CATCH','TOSS','DING!'].map((text,i)=><div key={text} style={{...panel,boxShadow:'none',padding:'10px 25px',fontFamily:'Nunito',fontSize:35,fontWeight:950,color:INK,background:i<=step?[BLUE,PINK,GOLD,GOLD][i]:CREAM,opacity:i<=step?1:.6}}>{i+1} · {text}</div>)}</div>;

type SceneProps={id:string;title:string;duration:number;gameAudio?:boolean};
export const V3Visual=({id,title,duration,gameAudio=true}:SceneProps)=>{
 const f=useCurrentFrame(),{fps}=useVideoConfig(),s=SECTIONS[id],n=duration,second=Math.round(((s?.lines_timing[1]?.start??7)+(s?.lead??.5))*fps);
 const sling=CLIPS['v3/sling.mp4']?'v3/sling.mp4':'sling_gel.mp4';
 const parry=CLIPS['v3/parry.mp4']?'v3/parry.mp4':'parry_catch.mp4';
 const dryer=CLIPS['v3/dryer.mp4']?'v3/dryer.mp4':'dryer.mp4';
 const swap=CLIPS['v3/swap.mp4']?'v3/swap.mp4':'fresh_cut.mp4';
 const boss=CLIPS['v3/boss.mp4']?'v3/boss.mp4':'boss.mp4';
 let visual:React.ReactNode;
 if(id==='hook') visual=<><GameClip name="Opening · complete sling" durationInFrames={7*fps} src={sling} start={2.3} zoom={1.12} focusY={.6} gameAudio={gameAudio}/><Sequence from={.5*fps} durationInFrames={2.4*fps}><div style={{position:'absolute',left:95,top:90}}><Label color={PINK}>“Ready?”</Label></div></Sequence><Sequence from={2*fps} durationInFrames={2.6*fps}><div style={{position:'absolute',right:105,top:190}}><Label color={BLUE}>“Throw me!”</Label></div></Sequence><Sequence from={7*fps}><Hero/></Sequence></>;
 else if(id==='story') visual=<><Sequence durationInFrames={4.5*fps}><ImageShot src="cutscene_02_robot_assistant.png"/></Sequence><Sequence from={4.5*fps} durationInFrames={4*fps}><ImageShot src="cutscene_05_hair_burst.png"/></Sequence><Sequence from={8.5*fps}><ImageShot src="cutscene_11_escape_together.png"/></Sequence><div style={{position:'absolute',left:80,top:60}}><Label color={CREAM}>One snip too many.</Label></div></>;
 else if(id==='roles') visual=<><GameClip name="Twin-Tails · glide and carry" durationInFrames={second} src="carry_launch.mp4" start={1.4} zoom={1.1} gameAudio={gameAudio}/><GameClip name="Pompadour · dash" from={second} durationInFrames={Math.round(4.1*fps)} src="fresh_cut.mp4" start={0} zoom={1.05} gameAudio={gameAudio}/><GameClip name="Pompadour · launch" from={second+Math.round(4.1*fps)} durationInFrames={n-second-Math.round(4.1*fps)} src="carry_launch.mp4" start={5.1} zoom={1.16} focusX={.65} gameAudio={gameAudio}/><div style={{position:'absolute',left:80,top:58}}><Label color={f<second?PINK:BLUE}>{f<second?'TWIN-TAILS · Glide + carry':'POMPADOUR · Dash + parry + launch'}</Label></div></>;
 else if(id==='sling'){
  const demo=Math.max(8*fps,second);
  visual=<><GameClip name="A carry alone cannot pass" durationInFrames={demo} src={CLIPS['v3/failure.mp4']?'v3/failure.mp4':sling} start={.8} zoom={1.1} gameAudio={gameAudio}/><GameClip name="The complete cooperation" from={demo} durationInFrames={Math.min(Math.round(7.4*fps),n-demo)} src={sling} start={3.0} zoom={1.07} gameAudio={gameAudio}/><GameClip name="Replay · focus on the hand-off" from={demo+Math.round(7.4*fps)} durationInFrames={Math.max(1,n-demo-Math.round(7.4*fps))} src={sling} start={4.4} rate={.8} zoom={1.32} focusX={.57} focusY={.59} gameAudio={false} tag="REPLAY · 0.8×"/><div style={{position:'absolute',left:80,top:58}}><Label color={f<demo?CREAM:GOLD}>{f<demo?'THE PROBLEM · Regrowing gel':'THE SLING · Carry → dash → follow'}</Label></div>{f<demo&&<div style={{position:'absolute',right:90,top:240}}><Label color={PINK}>The wall comes back.</Label></div>}</>;
 }
 else if(id==='parry'){
  const demo=Math.max(second,8*fps),source=15.5;
  visual=<><GameClip name="Parry alone · horizontal return" durationInFrames={demo} src={parry} start={1.8} zoom={1.12} focusY={.6} gameAudio={gameAudio}/><GameClip name="Full scissor relay and bell" from={demo} durationInFrames={n-demo} src={parry} start={source} end={29.4} zoom={1.06} gameAudio={gameAudio}/><div style={{position:'absolute',left:80,top:54}}><Label color={CREAM}>RETURN TO SENDER</Label></div>{f>=demo&&<ProcessRail step={f<demo+1.8*fps?0:f<demo+2.3*fps?1:f<demo+2.95*fps?2:3}/>}</>;
 }
 else if(id==='salon') visual=<><GameClip name="Shampoo · wet hair" durationInFrames={second} src="water.mp4" start={6.7} zoom={1.1} focusX={.7} gameAudio={gameAudio}/><GameClip name="Dryer · a solo lift" from={second} durationInFrames={Math.round(3.4*fps)} src={dryer} start={1.0} zoom={1.05} gameAudio={gameAudio}/><GameClip name="Dryer · rising together" from={second+Math.round(3.4*fps)} durationInFrames={Math.max(1,n-second-Math.round(7.4*fps))} src={dryer} start={7.4} zoom={1.05} gameAudio={gameAudio}/><GameClip name="Choose the shower gap" from={n-4*fps} durationInFrames={4*fps} src="wet_coop.mp4" start={7} zoom={1.08} gameAudio={gameAudio}/><div style={{position:'absolute',left:80,top:58}}><Label color={f<second?BLUE:GOLD}>{f<second?'WET HAIR · No glide. No gel smash.':f>=n-4*fps?'WAIT FOR A GAP':'WARM AIR · Dry off + rise together'}</Label></div></>;
 else if(id==='swap') visual=<><GameClip name="Actual chair role reversal" durationInFrames={n} src={swap} start={0} zoom={1.08} focusY={.57} gameAudio={gameAudio}/><div style={{position:'absolute',left:80,top:58}}><Label color={LILAC}>HAIRCUT SWAP · Switch jobs.</Label></div><Sequence from={4*fps}><div style={{position:'absolute',left:90,top:180,display:'flex',gap:18}}><Label color={BLUE}>P1 → Pompadour</Label><Label color={PINK}>P2 → Twin-Tails</Label></div></Sequence></>;
 else if(id==='boss') visual=<><GameClip name="Assistant · attacks" durationInFrames={6.5*fps} src="boss.mp4" start={0} zoom={1.06} gameAudio={gameAudio}/><GameClip name="Real parry, launch and stomp" from={6.5*fps} durationInFrames={n-6.5*fps} src={boss==='boss.mp4'?'stomp.mp4':boss} start={0} zoom={1.1} focusY={.6} gameAudio={gameAudio}/><div style={{position:'absolute',left:80,top:58}}><Label color={CREAM}>THE ASSISTANT · Put it all together.</Label></div></>;
 else if(id==='audience') visual=<><GameClip name="Co-op play · audience context" durationInFrames={n} src="wet_coop.mp4" start={0} zoom={1.03} gameAudio={gameAudio}/><div style={{position:'absolute',left:80,top:70}}><Label color={CREAM}>2 PLAYERS · 1 KEYBOARD · BROWSER</Label></div><Sequence from={second}><div style={{position:'absolute',left:80,top:220,...panel,background:CREAM,padding:'22px 32px',width:690}}><div style={{fontFamily:'Nunito',fontWeight:900,fontSize:32,letterSpacing:2,color:'#806383'}}>CO-OP REFERENCE POINTS</div><div style={{fontSize:56,marginTop:10}}>PICO PARK · ibb & obb</div><div style={{fontFamily:'Nunito',fontSize:37,fontWeight:800,lineHeight:1.25,marginTop:15}}>Our focus: hair-powered combos<br/>inside one mischievous salon.</div></div></Sequence></>;
 else if(id==='proof') visual=<><Paper/><Header number="PLAYABLE NOW" title={title}/><div style={{position:'absolute',left:80,top:205,width:1115,height:627,...panel,overflow:'hidden',background:INK}}><CanvasImage src={staticFile('v3/chapters.png')} style={{width:'100%',height:'100%',objectFit:'contain'}}/></div><div style={{position:'absolute',left:1250,right:90,top:235,display:'flex',flexDirection:'column',gap:20}}>{[['4','chapters'],['12','rooms'],['3','boss phases']].map(([v,label])=><div key={label} style={{display:'flex',gap:28,alignItems:'center',borderBottom:`3px solid ${INK}`,paddingBottom:17}}><span style={{fontSize:105,color:'#cb347a',fontWeight:650,lineHeight:1}}>{v}</span><span style={{fontFamily:'Nunito',fontSize:43,fontWeight:850}}>{label}</span></div>)}<div style={{fontFamily:'Nunito',fontSize:36,fontWeight:850,marginTop:20}}>Saved progress<br/>Both friends at every exit</div></div></>;
 else if(id==='team') visual=<><Paper/><Header number="THE DEVELOPERS" title="NPC Union"/><div style={{position:'absolute',left:70,top:275}}><Friends width={790} height={490}/></div><div style={{position:'absolute',left:930,top:300,right:90,opacity:entrance(f,7),translate:`0 ${(1-entrance(f,7))*24}px`}}><div style={{fontFamily:'Nunito',fontSize:35,letterSpacing:2,fontWeight:900,color:'#896989'}}>THE TWO-PERSON TEAM</div><div style={{fontSize:69,fontWeight:650,lineHeight:1.2,marginTop:30}}>ChenHongshan333</div><div style={{fontSize:69,fontWeight:650,lineHeight:1.2,marginTop:16}}>ZSYUYIIE</div><div style={{marginTop:50}}><Label color={GOLD}>Started in a 48-hour jam</Label></div><div style={{fontFamily:'Nunito',fontSize:39,fontWeight:800,marginTop:25}}>Better Together → continued iteration</div></div></>;
 else if(id==='plan'){
  const roadmap=f>=second;
  visual=<><Paper/><Header number="NEXT STEPS" title={roadmap?'A proposed twelve-week plan':title}/>{!roadmap?<><div style={{position:'absolute',left:105,top:245,width:570,textAlign:'center'}}><div style={{fontSize:245,fontWeight:650,color:'#cb347a',lineHeight:1}}>20</div><div style={{fontSize:62}}>player pairs</div><div style={{fontFamily:'Nunito',fontSize:35,fontWeight:850,marginTop:30,color:'#806383'}}>PLANNED NEXT COHORT</div></div><div style={{position:'absolute',left:800,right:100,top:260,display:'flex',flexDirection:'column',gap:40}}>{['Learn the first combo?','Where do they get stuck?','Choose another room?'].map((t,i)=><div key={t} style={{display:'flex',gap:25,alignItems:'center',opacity:entrance(f,i*18)}}><div style={{fontSize:64,color:'#cb347a'}}>0{i+1}</div><div style={{fontFamily:'Nunito',fontSize:48,fontWeight:900}}>{t}</div></div>)}<div style={{fontFamily:'Nunito',fontSize:33,fontWeight:850,color:'#806383'}}>Outside-player results are still to come.</div></div></>:<div style={{position:'absolute',left:90,right:100,top:270,display:'flex',gap:32}}>{[['1–4','Watch + teach','Playtests\nClearer tutorials'],['5–8','Polish','Rooms\nControls + audio'],['9–12','Prepare release','Accessibility\nQA + packaging']].map(([week,name,copy],i)=><div key={week} style={{...panel,background:[PINK,BLUE,GOLD][i],padding:34,flex:1,height:470,opacity:entrance(f-second,i*8),translate:`0 ${(1-entrance(f-second,i*8))*26}px`}}><div style={{fontFamily:'Nunito',fontSize:33,fontWeight:900}}>WEEKS {week}</div><div style={{fontSize:62,fontWeight:650,marginTop:35,lineHeight:1.08}}>{name}</div><div style={{fontFamily:'Nunito',fontSize:42,fontWeight:800,lineHeight:1.4,marginTop:35,whiteSpace:'pre-line'}}>{copy}</div></div>)}</div>}</>;
 }
 else if(id==='budget') visual=<><Paper/><Header number="PROPOSED · USD" title={title}/><div style={{position:'absolute',left:95,top:240,width:600}}><div style={{fontSize:143,fontWeight:650,lineHeight:1}}>$17,200</div><div style={{fontFamily:'Nunito',fontSize:47,fontWeight:850,marginTop:30}}>12-week production estimate</div><div style={{marginTop:42}}><Label color={GOLD}>Next: playtesters + mentoring</Label></div><div style={{fontFamily:'Nunito',fontSize:34,fontWeight:800,color:'#806383',marginTop:35,lineHeight:1.4}}>Scope and budget to be refined<br/>after outside playtests.</div></div><div style={{position:'absolute',left:810,right:100,top:235,display:'flex',flexDirection:'column',gap:25}}>{[['Our time',8800,PINK],['Art + music + sound',4200,BLUE],['Launch + tools + playtests',1300,LILAC],['20% buffer',2900,GOLD]].map(([name,amount,color],i)=><div key={name} style={{opacity:entrance(f,i*10)}}><div style={{display:'flex',justifyContent:'space-between',fontFamily:'Nunito',fontSize:38,fontWeight:900,marginBottom:10}}><span>{name}</span><span>${Number(amount).toLocaleString('en-US')}</span></div><div style={{height:42,border:`4px solid ${INK}`,borderRadius:14,overflow:'hidden',background:'#eee1e8'}}><div style={{height:'100%',background:String(color),width:`${Number(amount)/8800*100}%`}}/></div></div>)}<div style={{fontFamily:'Nunito',fontSize:32,fontWeight:800,color:'#806383'}}>Rounded estimates · funding not secured</div></div></>;
 else visual=<><ImageShot src="ending_07_bad_hair_good_friends.png"/><AbsoluteFill style={{background:'rgba(48,32,63,.86)'}}/><div style={{position:'absolute',left:100,top:110,color:GOLD,fontFamily:'Nunito',fontSize:37,fontWeight:950,letterSpacing:4}}>OH NO MY HAIR · NPC UNION</div><div style={{position:'absolute',left:96,top:265,color:CREAM,fontSize:121,fontWeight:650,lineHeight:1.05,opacity:entrance(f),translate:`0 ${(1-entrance(f))*36}px`}}>Bring a friend.<br/>Escape together.<div style={{position:'absolute',left:260,top:100}}><MarkerUnderline width={575}/></div></div><div style={{position:'absolute',left:105,top:615,color:CREAM,fontFamily:'Nunito',fontSize:44,fontWeight:850,lineHeight:1.5}}>Play the browser prototype<br/><span style={{color:GOLD}}>chenhongshan333.itch.io/ohnomyhair</span></div><div style={{position:'absolute',right:110,top:240,...panel,background:CREAM,padding:28,textAlign:'center'}}><CanvasImage src={staticFile('play-qr.png')} style={{width:365,height:365,imageRendering:'pixelated'}}/><div style={{fontSize:43,marginTop:16}}>SCAN TO PLAY</div></div></>;
 return <AbsoluteFill style={{fontFamily:'Fredoka',color:INK,background:CREAM,overflow:'hidden'}}>{visual}</AbsoluteFill>;
};
export const V3Scene=Interactive.create({Component:V3Visual,layout:'absolute-fill',schema:{id:{type:'string',default:'hook',description:'Section ID'},title:{type:'string',default:'Throw me!',description:'Heading'},duration:{type:'number',hiddenFromList:false,default:450,description:'Section duration (frames)'},gameAudio:{type:'boolean',default:true,description:'Recorded gameplay sound'}}});

export const MusicBed=()=>{
 const f=useCurrentFrame();
 let duck=1;
 for(const s of Object.values(SECTIONS)){
  const a=s.from_frame+s.lead*30,b=a+s.voice_seconds*30;
  const amount=interpolate(f,[a-8,a+3,b-3,b+15],[0,1,1,0],clamped);
  duck=Math.min(duck,1-.5*amount);
 }
 const volume=interpolate(f,[0,30,TOTAL-75,TOTAL],[0,.16,.16,0],clamped)*duck;
 // Explicit frame loops survive encoded exports; native media.loop did not.
 return <><Loop durationInFrames={993} layout="none"><ClipAudio name="Salon music · calm" src={staticFile('v3/audio/music-calm.wav')} durationInFrames={993} volume={volume}/></Loop><Sequence from={SECTIONS.boss.from_frame} durationInFrames={SECTIONS.boss.frames}><ClipAudio name="Boss pulse" src={staticFile('v3/audio/music-boss.wav')} durationInFrames={SECTIONS.boss.frames} volume={.07}/></Sequence></>;
};
