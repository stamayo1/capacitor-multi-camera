import { registerPlugin } from '@capacitor/core';

import type { MultiCameraPlugin } from './definitions';

const MultiCamera = registerPlugin<MultiCameraPlugin>('MultiCamera', {
  web: () => import('./web').then((m) => new m.MultiCameraWeb()),
});

export * from './definitions';
export { MultiCamera };
