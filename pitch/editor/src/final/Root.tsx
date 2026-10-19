import {Composition,registerRoot} from 'remotion';
import {FinalFilm} from './Film';
import {DATA} from './data';
const Root=()=><Composition id="OhNoMyHairPitchFinalFixed" component={FinalFilm} width={1920} height={1080} fps={30} durationInFrames={DATA.frames}/>;
registerRoot(Root);
