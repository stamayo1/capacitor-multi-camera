import { WebPlugin } from '@capacitor/core';

import type { CaptureResult, GalleryPhotosResult, MultiCameraPlugin } from './definitions';

export class MultiCameraWeb extends WebPlugin implements MultiCameraPlugin {
  capture(): Promise<CaptureResult> {
    throw new Error('Method not implemented.');
  }
  pickImages(): Promise<GalleryPhotosResult> {
    throw new Error('Method not implemented.');
  }
  checkPermissions(): Promise<{ camera: 'granted' | 'denied' | 'prompt'; photos: 'granted' | 'denied' | 'prompt';}>{
    throw new Error('Method not implemented.');
  }
  
  requestPermissions(): Promise<{ camera: 'granted' | 'denied'; photos:  'granted' | 'denied'; }>{
    throw new Error('Method not implemented.');
  }
  
}
