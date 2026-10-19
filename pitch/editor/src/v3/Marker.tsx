// Adapted from video-shotcraft's MarkerUnderlineTitle.tsx (Apache-2.0).
// Preserve its 22-frame landing, f32–42 stroke and seeded dry-brush geometry.
import {useId} from 'react';
import {interpolate,useCurrentFrame} from 'remotion';

const mulberry32=(a:number)=>()=>{let t=(a+=0x6d2b79f5);t=Math.imul(t^(t>>>15),t|1);t^=t+Math.imul(t^(t>>>7),t|61);return ((t^(t>>>14))>>>0)/4294967296;};
const buildStroke=(len:number,seed:number)=>{const rand=mulberry32(seed),top:string[]=[],bot:string[]=[];const wob=Array.from({length:41},()=>rand()-.5);for(let i=0;i<=40;i++){const t=i/40,x=t*len,mid=19-t*9+Math.sin(t*Math.PI*1.6+.4)*2.6+wob[i]*1.6,w=Math.max(2.2,14+Math.sin(t*Math.PI)*6-Math.max(0,t-.86)*46-Math.max(0,.06-t)*70+wob[i]*3);top.push(`${x.toFixed(1)},${(mid-w/2).toFixed(1)}`);bot.push(`${x.toFixed(1)},${(mid+w/2).toFixed(1)}`);}return `M${top.join('L')}L${bot.reverse().join('L')}Z`;};
const PATH=buildStroke(252,77);
export const MarkerUnderline=({width=500,color='#ffdd47'}:{width?:number;color?:string})=>{
 const f=useCurrentFrame(),id=useId().replace(/[^a-zA-Z0-9]/g,''),p=interpolate(f,[32,42],[0,1],{extrapolateLeft:'clamp',extrapolateRight:'clamp'}),draw=1-Math.pow(1-p,2.2);
 return <svg width={width} height={48} viewBox="0 0 252 44" preserveAspectRatio="none" style={{display:'block',overflow:'visible'}}><defs><clipPath id={`marker-${id}`}><rect x={0} y={-20} width={draw*258} height={65}/></clipPath><filter id={`dry-${id}`} x="-5%" y="-40%" width="110%" height="180%" colorInterpolationFilters="sRGB"><feTurbulence type="fractalNoise" baseFrequency="0.09 0.5" numOctaves={2} seed={7} result="warp"/><feDisplacementMap in="SourceGraphic" in2="warp" scale={1.8} xChannelSelector="R" yChannelSelector="G" result="rough"/><feTurbulence type="fractalNoise" baseFrequency="0.035 0.9" numOctaves={2} seed={19} result="grain"/><feColorMatrix in="grain" type="matrix" values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 -16 11.4" result="holes"/><feComposite in="rough" in2="holes" operator="in"/></filter></defs><g clipPath={`url(#marker-${id})`}><path d={PATH} fill={color} fillOpacity={.94} filter={`url(#dry-${id})`}/></g></svg>;
};
