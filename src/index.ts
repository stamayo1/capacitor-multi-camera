import { registerPlugin } from '@capacitor/core';

import type { MultiCameraPlugin } from './definitions';

const Camera = registerPlugin<MultiCameraPlugin>('Camera', {
  web: () => import('./web').then((m) => new m.CameraWeb()),
});

export * from './definitions';
export { Camera };
