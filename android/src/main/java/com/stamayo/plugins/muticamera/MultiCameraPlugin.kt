package com.stamayo.plugins.muticamera

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import com.getcapacitor.FileUtils
import com.getcapacitor.JSArray
import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.PermissionState
import com.getcapacitor.annotation.CapacitorPlugin
import com.getcapacitor.annotation.Permission
import com.getcapacitor.annotation.PermissionCallback
import java.io.File

@CapacitorPlugin(
    name = "Camera",
    permissions = [
        Permission(
            alias = MultiCameraPlugin.CAMERA_ALIAS,
            strings = [Manifest.permission.CAMERA]
        ),
        Permission(
            alias = MultiCameraPlugin.PHOTOS_ALIAS,
            strings = [
                Manifest.permission.READ_MEDIA_IMAGES,
            ]
        ),
        Permission(
            alias = MultiCameraPlugin.READ_EXTERNAL_ALIAS,
            strings = [
                Manifest.permission.READ_EXTERNAL_STORAGE,
            ]
        ),
        Permission(
            alias = MultiCameraPlugin.SAVE_GALLERY,
            strings = [
                Manifest.permission.READ_EXTERNAL_STORAGE,
                Manifest.permission.WRITE_EXTERNAL_STORAGE,
            ]
        ),
    ]
)
class MultiCameraPlugin : Plugin() {

    companion object {
        const val CAMERA_ALIAS = "camera"
        const val PHOTOS_ALIAS = "photos"
        const val SAVE_GALLERY = "saveGallery"
        const val READ_EXTERNAL_ALIAS = "readExternalAlias"
        private const val REQUEST_CAPTURE = 9911
        private const val REQUEST_GALLERY = 9912
    }

    private lateinit var implementation: MultiCamera
    private var captureSettings: CaptureSettings = CaptureSettings()
    private var captureCall: PluginCall? = null
    private var galleryCall: PluginCall? = null

    override fun load() {
        super.load()
        implementation = MultiCamera(bridge)
    }

    @PluginMethod
    override fun checkPermissions(call: PluginCall) {
        val result = JSObject()
        result.put("camera", getPermissionState(CAMERA_ALIAS).name.lowercase())
        result.put("photo", getPhotosPermissionState())
        call.resolve(result)
    }

    @PluginMethod
    override fun requestPermissions(call: PluginCall) {
        val sdk = Build.VERSION.SDK_INT

        val alias = mutableListOf(CAMERA_ALIAS)

        if (sdk <= Build.VERSION_CODES.Q) {
            alias.add(SAVE_GALLERY)
        } else if (sdk >= Build.VERSION_CODES.R && sdk <= Build.VERSION_CODES.S_V2) {
            alias.add(READ_EXTERNAL_ALIAS)
        } else {
            alias.add(PHOTOS_ALIAS)
        }

        requestPermissionForAliases(alias.toTypedArray(), call, "permissionsCallback")
    }

    @PluginMethod
    fun capture(call: PluginCall) {
        captureCall = call
        captureSettings = call.toCaptureSettings()

        if (getPermissionState(CAMERA_ALIAS) != PermissionState.GRANTED) {
            call.reject("Camera permission not granted")
            return
        }

        if (captureSettings.saveToGallery && getPhotosPermissionState() != "granted") {
            call.reject("Photo permission not granted")
            return
        }

        val intent = Intent(context, MultiCameraActivity::class.java)
        startActivityForResult(call, intent, REQUEST_CAPTURE)
    }

    @PluginMethod
    fun pickImages(call: PluginCall) {
        galleryCall = call
        captureSettings = call.toCaptureSettings()

        if (getPhotosPermissionState() != "granted") {
            call.reject("Photo permission not granted")
            return
        }

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "image/*"
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
        }

        val chooser = Intent.createChooser(intent, "Select pictures")
        startActivityForResult(call, chooser, REQUEST_GALLERY)
    }

    @PermissionCallback
    private fun permissionsCallback(call: PluginCall) {
        val result = JSObject()
        result.put("camera", getPermissionState(CAMERA_ALIAS).name.lowercase())
        result.put("photo", getPhotosPermissionState())
        call.resolve(result)
    }

    override fun handleOnActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.handleOnActivityResult(requestCode, resultCode, data)

        if (requestCode == REQUEST_CAPTURE) {
            handleCaptureResult(resultCode, data)
        } else if (requestCode == REQUEST_GALLERY) {
            handleGalleryResult(resultCode, data)
        }
    }

    private fun handleCaptureResult(resultCode: Int, data: Intent?) {
        val call = captureCall ?: return
        captureCall = null

        if (resultCode != Activity.RESULT_OK) {
            call.reject("User cancelled")
            return
        }

        val paths = data?.getStringArrayExtra("photos") ?: emptyArray()
        if (paths.isEmpty()) {
            call.reject("No photos captured")
            return
        }
        val photos = JSArray()

        paths.forEach { path ->
            val photoFile = File(path)
            val result = implementation.buildPhotoResult(photoFile, captureSettings)
            photos.put(result)
        }

        val payload = JSObject().apply { put("photos", photos) }
        call.resolve(payload)
    }

    private fun handleGalleryResult(resultCode: Int, data: Intent?) {
        val call = galleryCall ?: return
        galleryCall = null

        if (resultCode != Activity.RESULT_OK || data == null) {
            call.reject("User cancelled")
            return
        }

        val uris = mutableListOf<Uri>()
        data.clipData?.let { clip ->
            for (i in 0 until clip.itemCount) {
                uris.add(clip.getItemAt(i).uri)
            }
        }
        data.data?.let { uris.add(it) }

        val limitedUris = if (captureSettings.limit > 0) uris.take(captureSettings.limit) else uris
        if (limitedUris.isEmpty()) {
            call.reject("No images selected")
            return
        }
        val photos = JSArray()

        val gallerySettings = captureSettings.copy(
            resultType = CameraResultType.URI,
            saveToGallery = false,
        )

        limitedUris.forEach { uri ->
            val cached = implementation.copyToCache(context, uri, gallerySettings)
            val photo = implementation.buildPhotoResult(cached, gallerySettings)
            photo.put("saved", false)
            photos.put(photo)
        }

        val payload = JSObject().apply { put("photos", photos) }
        call.resolve(payload)
    }

    private fun getPhotosPermissionState(): String {
        val sdk = Build.VERSION.SDK_INT

        return when {
            sdk >= Build.VERSION_CODES.TIRAMISU -> {
                getPermissionState(PHOTOS_ALIAS).name.lowercase()
            }
            sdk >= Build.VERSION_CODES.S && sdk <= Build.VERSION_CODES.S_V2 -> {
                getPermissionState(READ_EXTERNAL_ALIAS).name.lowercase()
            }
            else -> {
                getPermissionState(SAVE_GALLERY).name.lowercase()
            }
        }
    }

    private fun PluginCall.toCaptureSettings(): CaptureSettings {
        val type = CameraResultType.from(getString("resultType"))
        val saveToGallery = getBoolean("saveToGallery") ?: false
        val quality = (getInt("quality") ?: 100).coerceIn(0, 100)
        val limit = getInt("limit") ?: 0
        val width = getInt("width") ?: 0
        val height = getInt("height") ?: 0

        return CaptureSettings(
            resultType = type,
            saveToGallery = saveToGallery,
            quality = quality,
            limit = limit,
            width = width,
            height = height,
        )
    }

    private fun getWebPath(file: File): String? {
        val host = bridge.localUrl ?: bridge.serverUrl ?: return null
        return FileUtils.getPortablePath(context, host, Uri.fromFile(file))
    }
}
