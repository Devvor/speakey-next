import React from 'react';
import {Composition} from 'remotion';
import {demoDuration, SpeakeyIntro} from './SpeakeyIntro';

export const RemotionRoot: React.FC = () => (
  <Composition
    id="SpeakeyIntro"
    component={SpeakeyIntro}
    durationInFrames={demoDuration}
    fps={30}
    width={1176}
    height={764}
  />
);
