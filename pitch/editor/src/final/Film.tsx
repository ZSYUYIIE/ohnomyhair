import React from 'react';
import {AbsoluteFill,Freeze,Img,Sequence,interpolate,staticFile,useCurrentFrame} from 'remotion';
import {Video} from '@remotion/media';
import {PitchScene,BasicCaptions} from '../PitchScene';
import {DATA} from './data';

type Piece={clip:string;from:number;duration:number;trimBefore:number;rate:number;fadeIn:number;hold?:boolean};
type Scene=(typeof DATA.scenes)[number];
const SOURCE=staticFile('final/source.mp4');
// Frames kept at normal speed at each end of a reused Final scene, so its fade in/out is untouched.
const IN=15,OUT=12;

const Piece=({p}:{p:Piece})=>{
 const f=useCurrentFrame();
 const video=<Video src={staticFile(p.clip+'.mp4')} trimBefore={p.trimBefore} playbackRate={p.rate} muted objectFit="contain" style={{width:'100%',height:'100%'}}/>;
 return <div style={{position:'absolute',inset:0,opacity:p.fadeIn?interpolate(f,[0,p.fadeIn],[0,1],{extrapolateRight:'clamp'}):1}}>{p.hold?<Freeze frame={0}>{video}</Freeze>:video}</div>;
};
// Gameplay played once from the planned pieces, instead of PitchScene's looping clip.
const Media=({pieces}:{pieces:readonly Piece[]})=><div style={{position:'relative',width:'100%',height:'100%'}}>{pieces.map((p,i)=><Sequence key={i} from={p.from} durationInFrames={p.duration} layout="none"><Piece p={p}/></Sequence>)}</div>;

// Corrections drawn over reused Final frames. A patch moves with the slide's own fade and 28px intro
// slide: its box shows the bare background (so the old pixels are gone) and its content fades in on top.
const INK='#30203f',GOLD='#ffdd47',LILAC='#e8d9ef';
const Patch=({x,y,w,h,frames,children}:{x:number;y:number;w:number;h:number;frames:number;children:React.ReactNode})=>{
 const f=useCurrentFrame();
 const opacity=interpolate(f,[0,10,frames-10,frames],[0,1,1,0],{extrapolateLeft:'clamp',extrapolateRight:'clamp'});
 const top=y+interpolate(f,[0,12],[28,0],{extrapolateRight:'clamp'});
 return <div style={{position:'absolute',left:x,top,width:w,height:h,backgroundImage:`url(${staticFile('final/bg.png')})`,backgroundPosition:`${-x}px ${-top}px`}}><div style={{position:'absolute',inset:0,opacity}}>{children}</div></div>;
};
const PATCHES:Record<string,(frames:number)=>React.ReactNode>={
 // The jam theme is Better Together (was "SOMETHING'S OFF").
 theme:frames=><Patch x={984} y={684} w={364} h={92} frames={frames}><div style={{position:'absolute',left:6,top:4,padding:'18px 32px',borderRadius:60,border:`4px solid ${INK}`,background:GOLD,color:INK,fontFamily:'Fredoka',fontWeight:600,fontSize:32,whiteSpace:'nowrap'}}>JAM THEME: BETTER TOGETHER</div></Patch>,
 // Online multiplayer is no longer ruled out: drop "Online multiplayer excluded." from the card.
 costs:frames=><Patch x={1196} y={684} w={390} h={40} frames={frames}><div style={{position:'absolute',inset:0,background:LILAC}}/></Patch>,
};

// A slide reused from Final.mp4: both ends at normal speed, the middle stretched to the new length.
// The old burned-in caption strip is covered with the bare background.
const Footage=({scene}:{scene:Scene})=>{
 const {start,end}=(scene as {source:{start:number;end:number}}).source;
 const middle=scene.frames-IN-OUT;
 return <AbsoluteFill style={{background:'#fff5df'}}>
  <Sequence durationInFrames={IN}><Video src={SOURCE} trimBefore={start} muted/></Sequence>
  <Sequence from={IN} durationInFrames={middle}><Video src={SOURCE} trimBefore={start+IN} playbackRate={(end-start-IN-OUT)/middle} muted/></Sequence>
  <Sequence from={scene.frames-OUT} durationInFrames={OUT}><Video src={SOURCE} trimBefore={end-OUT} muted/></Sequence>
  {PATCHES[scene.id]?.(scene.frames)}
  <Img src={staticFile('final/strip.png')} style={{position:'absolute',left:0,bottom:0,width:1920}}/>
  <BasicCaptions captions={[...scene.captions]}/>
 </AbsoluteFill>;
};

export const FinalFilm=()=><AbsoluteFill style={{background:'#fff5df'}}>{DATA.scenes.map((s:Scene)=>{
 if(s.kind==='footage')return <Sequence key={s.id} name={s.id} from={s.from} durationInFrames={s.frames}><Footage scene={s}/></Sequence>;
 const pieces='media' in s?(s.media as readonly Piece[]):undefined;
 return <PitchScene key={s.id} name={s.id} from={s.from} durationInFrames={s.frames} endFrames={s.frames} id={s.id} title={s.title} eyebrow={s.eyebrow??''} kind={s.pitch!} clip="none" narration={false}
  storyCuts={'storyCuts' in s?[...(s.storyCuts as readonly number[])]:undefined}
  media={pieces?<Media pieces={pieces}/>:undefined}><BasicCaptions captions={[...s.captions]}/></PitchScene>;
})}</AbsoluteFill>;
