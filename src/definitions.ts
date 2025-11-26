
export type CameraResultType = 'base64' | 'dataUrl' | 'uri';


export interface Photo {
  /**
   * The base64 encoded string representation of the image,
   */
  base64String?: string;

  /**
   * The url starting with 'data:image/jpeg;base64,'
   */
  dataUrl?: string;

  /**
   * If using CameraResultType.Uri, the path will contain a full,
   * platform-specific file URL that can be read later using the Filesystem API.
   */
  path?: string;

  /**
   * webPath returns a path that can be used to set the src attribute of an
   * image for efficient loading and rendering.
   */
  webPath?: string;

  /**
   * Exif data
   */
  exif?: any;

  /**
   * The format of the image, ex: jpeg, png, gif.
   */
  format: string;

  /**
   * Whether the image was saved to the gallery or not.
   */
  saved: boolean;
}

export interface GalleryPhoto {
  /**
   * If using CameraResultType.Uri, the path will contain a full,
   * platform-specific file URL that can be read later using the Filesystem API.
   */
  path?: string;

  /**
   * webPath returns a path that can be used to set the src attribute of an
   * image for efficient loading and rendering.
   */
  webPath?: string;

  /**
   * Exif data
   */
  exif?: any;

  /**
   * The format of the image, ex: jpeg, png, gif.
   */
  format: string;
}

export interface GalleryPhotosResult {
  /**
   * Array of all picked photos
   */
  photos: GalleryPhoto[];
}

export interface CaptureResult {
  /**
   * The list of photos captured in the session.
   */
  photos: Photo[];
}

export interface CaptureOptions {
  /**
   * The format in which to return the image.
   *
   * - 'base64': return image as base64 string
   * - 'dataUrl': return image as base64 with dataUrl prefix
   * - 'uri': return image as a path/uri
   *
   * @default 'uri'
   */
  resultType?: CameraResultType;

  /**
   * Save the captured image(s) to the device gallery.
   *
   * @default false
   */
  saveToGallery?: boolean;


  /**
   * The quality of image to return as JPEG, from 0-100
   *
   * @default 100
   */
  quality?: number;


  /**
   * Maximum number of pictures the user will be able to choose.
   * 
   * @default 0 (unlimited)
   */
  limit?: number;

  /**
   * Maximum width of the saved image. The aspect ratio is respected
   *
   * @default 1080
   */
  width?: number;

  /**
   * Maximum height of the saved image. The aspect ratio is respected
   *
   * @default 1920
   */
  height?: number;

  /**
   * Maximum number of pictures the user will be able to take in one session.
   *
   * @default 0 (unlimited)
   */
  limit?: number;
}

export interface GalleryImageOptions {
  /**
   * The quality of image to return as JPEG, from 0-100
   * 
   * @default 100
   */
  quality?: number;

  /**
   * Maximum width of the saved image. The aspect ratio is respected
   *
   * @default 1080
   */
  width?: number;

  /**
   * Maximum height of the saved image. The aspect ratio is respected
   *
   * @default 1920
   */
  height?: number;

  /**
   * Maximum number of pictures the user will be able to choose.
   * 
   * @default 0 (unlimited)
   */
  limit?: number;
}

export interface MultiCameraPlugin {
  /**
   * Launch the multi-camera UI and capture one or more photos.
   */
  capture(options?: CaptureOptions): Promise<CaptureResult>;

  /**
   * Allow the user to select multiple pictures from the photo gallery
   */
  pickImages(options?: GalleryImageOptions): Promise<GalleryPhotosResult>;

  /**
   * Check if the app has permissions to use the camera (and optionally gallery).
   */
  checkPermissions(): Promise<{ camera: 'granted' | 'denied' | 'prompt'; photos: 'granted' | 'denied' | 'prompt';}>;

  /**
   * Request the necessary permissions to use the camera (and optionally gallery).
   */
  requestPermissions(): Promise<{ camera: 'granted' | 'denied'; photos:  'granted' | 'denied'; }>;
}
