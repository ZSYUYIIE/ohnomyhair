// V4 uses the same cut and caption timing data as the production composition.
import {V4Scene,V4Film,V4Caption} from './v4/Scenes';
import {DATA} from './v4/data';
export const WORKBENCH={
 name:'Oh No My Hair - pitch v4',fps:30,width:1920,height:1080,total:DATA.frames,background:'#fff5df',
 shots:DATA.scenes.map(s=>({id:s.id,label:s.title,from:s.from_frame,duration:s.frames,component:V4Scene,props:{id:s.id},cardId:'v4-'+s.id})),
 captions:DATA.captions.map((c,i)=>({id:'caption-'+i,label:c.text,from:Math.ceil(c.start*30),duration:Math.ceil(c.end*30)-Math.ceil(c.start*30),component:V4Caption,props:{text:c.text,fontSize:56,color:'#fffaf0'},cardId:'v4-caption',schema:[{type:'textarea',key:'text',label:'Caption',default:''},{type:'number',key:'fontSize',label:'Font size',default:56,min:32,max:80},{type:'color',key:'color',label:'Text color',default:'#fffaf0'}]})),
 sfx:[{from:0,duration:DATA.frames,src:'v4/audio/Narration.wav',volume:1,label:'Narration - replaceable'},{from:0,duration:DATA.frames,src:'v4/audio/SFX.wav',volume:1,label:'Game SFX'}],
 bgm:[{from:0,duration:DATA.frames,src:'v4/audio/Music.wav',volume:1,label:'Salon music - ducked under narration'}],
 transitions:[],overlays:[],order:['captions'],original:V4Film,
};
