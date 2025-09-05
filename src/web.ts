import { WebPlugin } from '@capacitor/core';

import type { MultiCameraPlugin } from './definitions';

export class CameraWeb extends WebPlugin implements MultiCameraPlugin {
  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    return options;
  }
}
