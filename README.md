# capacitor-multi-camera

Custom capacitor camera plugin to take multiple pictures

## Install

```bash
npm install capacitor-multi-camera
npx cap sync
```

## API

<docgen-index>

* [`capture(...)`](#capture)
* [`pickImages(...)`](#pickimages)
* [`checkPermissions()`](#checkpermissions)
* [`requestPermissions()`](#requestpermissions)
* [Interfaces](#interfaces)
* [Type Aliases](#type-aliases)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### capture(...)

```typescript
capture(options?: CaptureOptions | undefined) => Promise<CaptureResult>
```

Launch the multi-camera UI and capture one or more photos.

| Param         | Type                                                      |
| ------------- | --------------------------------------------------------- |
| **`options`** | <code><a href="#captureoptions">CaptureOptions</a></code> |

**Returns:** <code>Promise&lt;<a href="#captureresult">CaptureResult</a>&gt;</code>

--------------------


### pickImages(...)

```typescript
pickImages(options?: GalleryImageOptions | undefined) => Promise<GalleryPhotosResult>
```

Allow the user to select multiple pictures from the photo gallery

| Param         | Type                                                                |
| ------------- | ------------------------------------------------------------------- |
| **`options`** | <code><a href="#galleryimageoptions">GalleryImageOptions</a></code> |

**Returns:** <code>Promise&lt;<a href="#galleryphotosresult">GalleryPhotosResult</a>&gt;</code>

--------------------


### checkPermissions()

```typescript
checkPermissions() => Promise<{ camera: 'granted' | 'denied' | 'prompt'; photos: 'granted' | 'denied' | 'prompt'; }>
```

Check if the app has permissions to use the camera (and optionally gallery).

**Returns:** <code>Promise&lt;{ camera: 'granted' | 'denied' | 'prompt'; photos: 'granted' | 'denied' | 'prompt'; }&gt;</code>

--------------------


### requestPermissions()

```typescript
requestPermissions() => Promise<{ camera: 'granted' | 'denied'; photos: 'granted' | 'denied'; }>
```

Request the necessary permissions to use the camera (and optionally gallery).

**Returns:** <code>Promise&lt;{ camera: 'granted' | 'denied'; photos: 'granted' | 'denied'; }&gt;</code>

--------------------


### Interfaces


#### CaptureResult

| Prop         | Type                 | Description                                 |
| ------------ | -------------------- | ------------------------------------------- |
| **`photos`** | <code>Photo[]</code> | The list of photos captured in the session. |


#### Photo

| Prop               | Type                 | Description                                                                                                                                                              |
| ------------------ | -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **`base64String`** | <code>string</code>  | The base64 encoded string representation of the image,                                                                                                                   |
| **`dataUrl`**      | <code>string</code>  | The url starting with 'data:image/jpeg;base64,'                                                                                                                          |
| **`path`**         | <code>string</code>  | If using <a href="#cameraresulttype">CameraResultType</a>.Uri, the path will contain a full, platform-specific file URL that can be read later using the Filesystem API. |
| **`webPath`**      | <code>string</code>  | webPath returns a path that can be used to set the src attribute of an image for efficient loading and rendering.                                                        |
| **`exif`**         | <code>any</code>     | Exif data                                                                                                                                                                |
| **`format`**       | <code>string</code>  | The format of the image, ex: jpeg, png, gif.                                                                                                                             |
| **`saved`**        | <code>boolean</code> | Whether the image was saved to the gallery or not.                                                                                                                       |


#### CaptureOptions

| Prop                | Type                                                          | Description                                                                                                                                                                    | Default            |
| ------------------- | ------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ |
| **`resultType`**    | <code><a href="#cameraresulttype">CameraResultType</a></code> | The format in which to return the image. - 'base64': return image as base64 string - 'dataUrl': return image as base64 with dataUrl prefix - 'uri': return image as a path/uri | <code>'uri'</code> |
| **`saveToGallery`** | <code>boolean</code>                                          | Save the captured image(s) to the device gallery.                                                                                                                              | <code>false</code> |
| **`quality`**       | <code>number</code>                                           | The quality of image to return as JPEG, from 0-100                                                                                                                             | <code>100</code>   |


#### GalleryPhotosResult

| Prop         | Type                        | Description                |
| ------------ | --------------------------- | -------------------------- |
| **`photos`** | <code>GalleryPhoto[]</code> | Array of all picked photos |


#### GalleryPhoto

| Prop          | Type                | Description                                                                                                                                                              |
| ------------- | ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **`path`**    | <code>string</code> | If using <a href="#cameraresulttype">CameraResultType</a>.Uri, the path will contain a full, platform-specific file URL that can be read later using the Filesystem API. |
| **`webPath`** | <code>string</code> | webPath returns a path that can be used to set the src attribute of an image for efficient loading and rendering.                                                        |
| **`exif`**    | <code>any</code>    | Exif data                                                                                                                                                                |
| **`format`**  | <code>string</code> | The format of the image, ex: jpeg, png, gif.                                                                                                                             |


#### GalleryImageOptions

| Prop          | Type                | Description                                                      | Default                    |
| ------------- | ------------------- | ---------------------------------------------------------------- | -------------------------- |
| **`quality`** | <code>number</code> | The quality of image to return as JPEG, from 0-100               | <code>100</code>           |
| **`width`**   | <code>number</code> | Maximum width of the saved image. The aspect ratio is respected  |                            |
| **`height`**  | <code>number</code> | Maximum height of the saved image. The aspect ratio is respected |                            |
| **`limit`**   | <code>number</code> | Maximum number of pictures the user will be able to choose.      | <code>0 (unlimited)</code> |


### Type Aliases


#### CameraResultType

<code>'base64' | 'dataUrl' | 'uri'</code>

</docgen-api>
