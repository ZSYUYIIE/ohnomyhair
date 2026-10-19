// Single timing source shared with the v3 composition.
import {PitchV3} from './v3/PitchV3';
import {V3Visual,V3Captions,MusicBed} from './v3/Scenes';
import {SECTIONS,TOTAL} from './v3/data';
export const WORKBENCH={
 name:'Oh No My Hair · pitch v3',fps:30,width:1920,height:1080,total:TOTAL,background:'#fff5df',
 shots:Object.values(SECTIONS).map(s=>({id:s.id,label:s.title,from:s.from_frame,duration:s.frames,component:V3Visual,props:{id:s.id,title:s.title,duration:s.frames,gameAudio:true},durationProp:'duration',schema:[{type:'text',key:'title',label:'Heading',default:s.title}],cardId:'v3-'+s.id})),
 captions:Object.values(SECTIONS).map(s=>({id:s.id+'-captions',label:s.id+' · English captions',from:s.from_frame,duration:s.frames,component:V3Captions,props:{captions:s.captions}})),
 overlays:[{id:'music-bed',label:'Salon music · ducking under speech',from:0,duration:TOTAL,component:MusicBed}],
 sfx:Object.values(SECTIONS).map(s=>({from:s.from_frame+Math.round(s.lead*30),duration:Math.ceil(s.voice_seconds*30),src:'v3/voice/'+s.id+'.mp3',volume:1})),
 transitions:[],bgm:[],order:['captions','overlays'],original:PitchV3,
};
