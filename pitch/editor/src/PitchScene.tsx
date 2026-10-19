import React from 'react';
import {AbsoluteFill, CanvasImage, Interactive, interpolate, staticFile, useCurrentFrame} from 'remotion';
import {Audio, Video} from '@remotion/media';
import type {Caption} from '@remotion/captions';
import {loadFont} from '@remotion/fonts';

loadFont({family:'Fredoka',url:staticFile('Fredoka.ttf')});
loadFont({family:'Nunito',url:staticFile('Nunito.ttf')});
const INK='#30203f',CREAM='#fff5df',GOLD='#ffdd47',PINK='#f65a9d',LILAC='#e8d9ef';
const box:React.CSSProperties={background:CREAM,border:`5px solid ${INK}`,borderRadius:36,boxShadow:`0 10px 0 ${INK}`,overflow:'hidden'};
const body:React.CSSProperties={position:'absolute',top:210,left:100,right:100,bottom:180};
const pill:React.CSSProperties={padding:'18px 32px',borderRadius:60,border:`4px solid ${INK}`,background:GOLD,fontFamily:'Fredoka',fontWeight:600,fontSize:32};

// Local caption renderer: the published BasicCaptions source returned HTTP 403.
// Caption timings use the skill's Caption JSON shape, synchronized to speech.
export const BasicCaptions=({captions}:{captions:Caption[]})=>{
 const f=useCurrentFrame();const active=captions.find(c=>f/30*1000>=c.startMs&&f/30*1000<c.endMs);
 return active?<div style={{position:'absolute',left:110,right:110,bottom:30,minHeight:78,padding:'15px 30px',display:'flex',alignItems:'center',justifyContent:'center',background:'rgba(39,24,53,.94)',borderRadius:22,color:'#fffaf0',fontFamily:'Nunito',fontWeight:750,fontSize:34,lineHeight:1.28,textAlign:'center'}}>{active.text}</div>:null;
};
const Card=({children,style={}}:{children:React.ReactNode;style?:React.CSSProperties})=><div style={{...box,padding:38,...style}}>{children}</div>;
const Heading=({children}:{children:React.ReactNode})=><div style={{fontFamily:'Fredoka',fontSize:49,fontWeight:650,lineHeight:1.14}}>{children}</div>;
const Copy=({children,style={}}:{children:React.ReactNode;style?:React.CSSProperties})=><div style={{fontFamily:'Nunito',fontSize:34,lineHeight:1.35,fontWeight:750,...style}}>{children}</div>;
const Friends=({style={}}:{style?:React.CSSProperties})=>{
 const w=Number(style.width??700),h=Number(style.height??650);
 const s=Math.min(w/456,h/255);
 return <div style={{position:'relative',overflow:'hidden',flexShrink:0,...style}}><CanvasImage src={staticFile('map_friends.png')} style={{position:'absolute',width:1280*s,height:720*s,left:(w-456*s)/2-412*s,top:(h-255*s)/2-280*s}}/></div>;
};
const Gameplay=({clip}:{clip:string})=><div style={{...box,position:'absolute',left:240,top:130,width:1440,height:810,borderRadius:24,background:INK}}><Video name="Puzzle demonstration" src={staticFile(clip+'.mp4')} trimBefore={clip==='parry_catch'?270:0} playbackRate={clip==='sling_gel'?.7:clip==='carry_launch'?.8:1} loop muted style={{width:'100%',height:'100%',objectFit:'contain'}}/>{clip==='boss'&&<Video name="Stomp counterattack" src={staticFile('stomp.mp4')} from={420} playbackRate={.6} loop muted style={{position:'absolute',inset:0,width:'100%',height:'100%',objectFit:'contain'}}/>}</div>;

type Props={title:string;eyebrow:string;kind:string;id:string;clip?:string;endFrames:number;children?:React.ReactNode};
const SceneInner=({title,eyebrow,kind,id,clip,endFrames,children}:Props)=>{
 const f=useCurrentFrame();
 const intro=interpolate(f,[0,12],[28,0],{extrapolateRight:'clamp'});
 const opacity=interpolate(f,[0,10,endFrames-10,endFrames],[0,1,1,0],{extrapolateLeft:'clamp',extrapolateRight:'clamp'});
 const isGame=kind==='game';
 return <AbsoluteFill style={{background:CREAM,color:INK,fontFamily:'Fredoka'}}>
  <div style={{position:'absolute',width:1000,height:1000,borderRadius:'50%',background:LILAC,left:1120,top:-350,opacity:.6}}/>
  <div style={{position:'absolute',width:650,height:650,borderRadius:'50%',background:'#ffe0be',left:-260,top:650,opacity:.6}}/>
  <div style={{position:'absolute',inset:0,opacity,translate:`0 ${intro}px`}}>
   {!['hero','story','end'].includes(kind)&&<><div style={{position:'absolute',left:90,top:isGame?14:55,fontFamily:'Nunito',fontSize:isGame?22:27,fontWeight:900,letterSpacing:3,color:'#78617f'}}>{eyebrow}</div><div style={{position:'absolute',left:88,top:isGame?48:100,fontSize:isGame?56:76,fontWeight:650,lineHeight:1.06}}>{title}</div></>}
   {isGame&&<><Gameplay clip={clip!}/><div style={{position:'absolute',right:90,top:52,fontFamily:'Nunito',fontSize:23,fontWeight:900}}>ACTUAL PROTOTYPE GAMEPLAY</div></>}
   {kind==='hero'&&<>
    <CanvasImage src={staticFile('title_cover.png')} style={{position:'absolute',inset:0,width:'100%',height:'100%',objectFit:'cover',scale:interpolate(f,[0,endFrames],[1,1.035])}}/>
    <div style={{position:'absolute',inset:0,background:'linear-gradient(90deg,#30203f 0%,#30203f 40%,rgba(48,32,63,.95) 48%,rgba(48,32,63,.45) 62%,transparent 80%)'}}/>
    <div style={{position:'absolute',left:100,top:90,color:CREAM,fontFamily:'Nunito',fontWeight:900,fontSize:28,letterSpacing:4}}>NPC UNION PRESENTS</div>
    <div style={{position:'absolute',left:96,top:220,color:GOLD,fontSize:142,fontWeight:700,lineHeight:.98,textShadow:`0 8px 0 ${INK}`}}>OH NO<br/>MY HAIR!</div>
    <div style={{position:'absolute',left:105,top:600,color:CREAM,fontSize:60}}>{title}</div>
    <div style={{position:'absolute',left:105,top:735,display:'flex',gap:20}}><span style={pill}>2-PLAYER CO-OP</span><span style={pill}>PUZZLE PLATFORMER</span></div>
   </>}
   {kind==='story'&&<>
    <CanvasImage src={staticFile(f<endFrames*.48?'cutscene_02_robot_assistant.png':f<endFrames*.72?'cutscene_05_hair_burst.png':'cutscene_11_escape_together.png')} style={{position:'absolute',inset:0,width:'100%',height:'100%',objectFit:'cover',scale:interpolate(f,[0,endFrames],[1,1.04])}}/>
    <div style={{position:'absolute',left:85,top:60,...pill,fontSize:58,background:CREAM}}>{title}</div>
   </>}
   {kind==='duo'&&<div style={{...body,display:'flex',alignItems:'center',gap:90}}><Friends style={{width:800,height:650,translate:`0 ${Math.sin(f/20)*8}px`}}/><div><div style={{fontSize:92,lineHeight:1.1,fontWeight:650}}>“Carry me.”<br/>“Wait for the water.”<br/><span style={{color:'#d73784'}}>“Parry now!”</span></div><div style={{...pill,marginTop:45,display:'inline-block'}}>JAM THEME: BETTER TOGETHER</div></div></div>}
   {kind==='audience'&&<div style={{...body,display:'grid',gridTemplateColumns:'1.2fr 1fr',gap:50}}><Card style={{background:LILAC,display:'flex',flexDirection:'column',justifyContent:'center'}}><Heading>Friends. Siblings. Couples.</Heading><Copy style={{marginTop:30}}>Pairs who enjoy playful puzzles<br/>and shared “we did it!” moments.</Copy><div style={{...pill,marginTop:45,alignSelf:'flex-start'}}>LOCAL CO-OP FIRST</div></Card><div style={{display:'flex',flexDirection:'column',gap:30,justifyContent:'center'}}><Card><Heading>One shared keyboard</Heading></Card><Card><Heading>Play in a browser</Heading></Card><Card><Heading>A different power each</Heading></Card></div></div>}
   {kind==='market'&&<div style={{...body,display:'flex',gap:34,alignItems:'stretch'}}>
    <Card style={{width:'31%',display:'flex',flexDirection:'column',justifyContent:'center'}}><Heading>PICO PARK 2</Heading><Copy style={{marginTop:36}}>2–8 players<br/>Co-op action puzzles</Copy><div style={{marginTop:65,fontSize:26,color:'#78617f'}}>Similar game</div></Card>
    <Card style={{width:'31%',display:'flex',flexDirection:'column',justifyContent:'center'}}><Heading>ibb & obb</Heading><Copy style={{marginTop:36}}>Two-player puzzles<br/>Gravity as the core twist</Copy><div style={{marginTop:65,fontSize:26,color:'#78617f'}}>Similar game</div></Card>
    <Card style={{width:'38%',background:GOLD,display:'flex',flexDirection:'column',justifyContent:'center'}}><Heading>OH NO MY HAIR!</Heading><Copy style={{marginTop:36}}>A hair power each<br/>Moves that need both of you<br/>One salon to escape</Copy><div style={{marginTop:48,fontSize:27}}>Smaller, and still unproven</div></Card>
   </div>}
   {kind==='prototype'&&<div style={{...body,display:'grid',gridTemplateColumns:'1.2fr 1fr',gap:45}}><Card style={{padding:0}}><Video src={staticFile('wet_coop.mp4')} loop muted style={{width:'100%',height:'100%',objectFit:'cover'}}/></Card><div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:26}}><Stat value="4" label="chapters"/><Stat value="12" label="rooms"/><Stat value="3" label="boss phases"/><Stat value="NOW" label="playable on itch.io"/></div></div>}
   {kind==='budget'&&<div style={{...body,display:'flex',gap:60,alignItems:'center'}}><Card style={{width:560,minHeight:560,background:GOLD,padding:42,display:'flex',flexDirection:'column'}}><div style={{fontFamily:'Nunito',fontSize:27,fontWeight:900,letterSpacing:1}}>12-WEEK BUDGET</div><div style={{fontSize:118,fontWeight:650,marginTop:20}}>$17,200</div><Copy style={{fontSize:36,marginTop:10}}>Polish the game and<br/>launch it on Steam</Copy><div style={{height:4,background:INK,margin:'34px 0'}}/><div style={{fontFamily:'Nunito',fontSize:26,fontWeight:850}}>Proposed · not funding raised</div></Card><div style={{flex:1,display:'flex',flexDirection:'column',justifyContent:'center',gap:26}}><Cost label="Pay for 2 of us ($1,600/month each)" amount="$8,800" width="100%" color={GOLD}/><Cost label="Freelance art, music + sound" amount="$4,200" width="48%" color={PINK}/><Cost label="Steam fee, playtests, tools, store art, trailer" amount="$1,300" width="15%" color="#9bd6cd"/><Cost label="20% buffer" amount="$2,900" width="33%" color="#bda0d2"/><Copy style={{fontSize:25,color:'#78617f',marginTop:6}}>Pay is the low end of Rami Ismail's $1,600–2,200/month benchmark for small indie teams.</Copy></div></div>}
   {kind==='costs'&&<div style={{...body,display:'flex',gap:60,alignItems:'center'}}><Card style={{width:560,minHeight:560,background:GOLD,padding:42,display:'flex',flexDirection:'column'}}><div style={{fontFamily:'Nunito',fontSize:27,fontWeight:900,letterSpacing:1}}>LEAN RELEASE</div><div style={{fontSize:118,fontWeight:650,marginTop:20}}>$900</div><Copy style={{fontSize:36,marginTop:10}}>From our own savings.<br/>We ship either way.</Copy><div style={{height:4,background:INK,margin:'34px 0'}}/><Copy style={{fontSize:27,lineHeight:1.5}}>Boss animation · 5 min of music<br/>Library sound effects · Steam fee<br/>Store art</Copy></Card><Card style={{flex:1,minHeight:560,background:LILAC,padding:46,display:'flex',flexDirection:'column',justifyContent:'center'}}><Heading>Where the rest could come from</Heading><div style={{marginTop:34,display:'flex',flexDirection:'column',gap:24}}>{[['Our own savings','Production costs, about $6,600'],['Kickstarter','Our pay, about a $10,000 goal'],['Festival prizes','A bonus, not counted on'],['Publishing partner','Marketing help']].map(([a,b])=><div key={a} style={{display:'flex',justifyContent:'space-between',gap:30,borderBottom:`3px dashed ${INK}`,paddingBottom:16}}><Copy style={{fontSize:36}}>{a}</Copy><Copy style={{fontSize:32,fontWeight:650,textAlign:'right'}}>{b}</Copy></div>)}</div></Card></div>}
   {kind==='roadmap'&&<div style={{...body,display:'flex',gap:32,alignItems:'center'}}><Milestone n="01" time="WEEKS 1–4" title="Validate" copy="Playtests · onboarding · difficulty" active={f/endFrames<.33}/><Milestone n="02" time="WEEKS 5–8" title="Polish" copy="Rooms · controls · Steam page" active={f/endFrames>=.33&&f/endFrames<.66}/><Milestone n="03" time="WEEKS 9–12" title="Prepare release" copy="Accessibility · QA · packaging" active={f/endFrames>=.66}/></div>}
   {kind==='validation'&&<div style={{...body,display:'flex',gap:45,alignItems:'center'}}><Card style={{width:620,background:GOLD,textAlign:'center'}}><div style={{fontSize:190,fontWeight:650,lineHeight:1}}>20</div><Heading>player pairs</Heading><Copy style={{fontSize:28,marginTop:22}}>Planned next test cohort</Copy></Card><div style={{flex:1,display:'flex',flexDirection:'column',gap:28}}><Card><Heading>Can they learn without hints?</Heading></Card><Card><Heading>Where do they fail repeatedly?</Heading></Card><Card><Heading>Do they choose another room?</Heading></Card><div style={{fontSize:27,fontFamily:'Nunito',fontWeight:850,color:'#78617f'}}>Goals for the next test. No outside players yet.</div></div></div>}
   {kind==='team'&&<div style={{...body,display:'flex',gap:80,alignItems:'center'}}><Friends style={{width:700,height:650,translate:`0 ${Math.sin(f/24)*7}px`}}/><div style={{flex:1}}><Card style={{background:GOLD}}><Heading>ChenHongshan333</Heading></Card><Card style={{marginTop:35}}><Heading>ZSYUYIIE</Heading></Card><Copy style={{marginTop:50}}>Looking for playtesters,<br/>feedback and mentoring.</Copy></div></div>}
   {kind==='end'&&<>
    <CanvasImage src={staticFile('ending_07_bad_hair_good_friends.png')} style={{position:'absolute',inset:0,width:'100%',height:'100%',objectFit:'cover'}}/>
    <div style={{position:'absolute',inset:0,background:'rgba(48,32,63,.75)'}}/>
    <div style={{position:'absolute',left:100,top:90,color:GOLD,fontSize:30,letterSpacing:4}}>THANK YOU · NPC UNION</div>
    <div style={{position:'absolute',left:100,top:220,width:1030,color:CREAM,fontSize:106,lineHeight:1.05,fontWeight:650}}>Bring a friend.<br/>Escape together.</div>
    <div style={{position:'absolute',left:105,top:530,color:GOLD,fontSize:50}}>Bad hair. Good friends.</div>
    <div style={{position:'absolute',left:105,top:665,color:CREAM,fontFamily:'Nunito',fontSize:29,lineHeight:1.65,fontWeight:850}}>ChenHongshan333 · ZSYUYIIE<br/>chenhongshan333.itch.io/ohnomyhair</div>
    <Card style={{position:'absolute',right:120,top:235,padding:30,textAlign:'center',width:430}}><CanvasImage src={staticFile('play-qr.png')} style={{width:360,height:360}}/><div style={{fontSize:38,marginTop:18}}>PLAY THE PROTOTYPE</div></Card>
   </>}
  </div>
  <Audio name="English narration" src={staticFile(id+'.mp3')} from={6} volume={1}/>
  {children}
 </AbsoluteFill>;
};
const Stat=({value,label}:{value:string;label:string})=><Card style={{background:LILAC,textAlign:'center',display:'flex',flexDirection:'column',justifyContent:'center',padding:22}}><div style={{fontSize:value==='NOW'?70:105,fontWeight:650,color:'#d73784'}}>{value}</div><Copy style={{fontSize:30}}>{label}</Copy></Card>;
const Budget=({name,amount,time,lines,gold=false}:{name:string;amount:string;time:string;lines:string[];gold?:boolean})=><Card style={{flex:1,background:gold?GOLD:CREAM,minHeight:520,padding:35}}><div style={{fontFamily:'Nunito',fontSize:25,fontWeight:900,letterSpacing:1}}>{name}</div><div style={{fontSize:79,fontWeight:650,marginTop:25}}>{amount}</div><div style={{fontSize:40,marginTop:20}}>{time}</div><div style={{height:4,background:INK,margin:'30px 0'}}/><Copy style={{fontSize:30,lineHeight:1.6}}>{lines.map(x=><React.Fragment key={x}>{x}<br/></React.Fragment>)}</Copy><div style={{fontFamily:'Nunito',fontSize:25,fontWeight:850,marginTop:25}}>Proposed · not funding raised</div></Card>;
const Cost=({label,amount,width,color}:{label:string;amount:string;width:string;color:string})=><div><div style={{display:'flex',justifyContent:'space-between',fontSize:34,marginBottom:9}}><span>{label}</span><b>{amount}</b></div><div style={{height:48,border:`4px solid ${INK}`,borderRadius:20,overflow:'hidden',background:'#eee1e8'}}><div style={{height:'100%',width,background:color}}/></div></div>;
const Milestone=({n,time,title,copy,active}:{n:string;time:string;title:string;copy:string;active:boolean})=><Card style={{flex:1,background:active?GOLD:LILAC,minHeight:500}}><div style={{fontSize:85,color:'#78617f',fontWeight:650}}>{n}</div><Copy style={{fontSize:29,marginTop:40}}>{time}</Copy><Heading>{title}</Heading><Copy style={{marginTop:38,fontSize:31}}>{copy}</Copy></Card>;
export const PitchScene=Interactive.create({Component:SceneInner,layout:'absolute-fill'});
