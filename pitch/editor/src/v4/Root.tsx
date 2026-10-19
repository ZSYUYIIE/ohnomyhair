import {Composition,registerRoot} from 'remotion';
import {V4Film,V4Scene} from './Scenes';
import {DATA} from './data';
const Root=()=> <><Composition id="OhNoMyHairPitchV4" component={V4Film} width={1920} height={1080} fps={30} durationInFrames={DATA.frames}/><Composition id="V4Scene" component={V4Scene} width={1920} height={1080} fps={30} durationInFrames={900} defaultProps={{id:'hook',blankVideo:true,clipIndex:-1}}/></>;
registerRoot(Root);
