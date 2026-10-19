import {Composition,Folder,registerRoot} from 'remotion';
import {PitchV3} from './PitchV3';
import {V3Scene} from './Scenes';
export const V3Root=()=> <>
<Composition id="OhNoMyHairPitchV3" component={PitchV3} width={1920} height={1080} fps={30} durationInFrames={7579} defaultProps={{bgm:true,narration:true,gameAudio:true,captions:true}}/>
<Folder name="V3-Scenes"><Composition id="V3-Scene" component={V3Scene} width={1920} height={1080} fps={30} durationInFrames={450} defaultProps={{id:"hook",title:"Throw me!",duration:450,gameAudio:true}}/></Folder>
</>;
registerRoot(V3Root);
