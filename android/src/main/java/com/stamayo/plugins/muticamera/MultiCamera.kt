package com.stamayo.plugins.muticamera

import android.content.ContentValues
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.util.Base64
import com.getcapacitor.Bridge
import com.getcapacitor.FileUtils
import com.getcapacitor.JSObject
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.util.UUID

enum class CameraResultType(val raw: String) {
    BASE64("base64"),
    DATA_URL("dataUrl"),
    URI("uri");

    companion object {
        fun from(raw: String?): CameraResultType = entries.firstOrNull { it.raw == raw } ?: URI
    }
}

data class CaptureSettings(
    val resultType: CameraResultType = CameraResultType.URI,
    val saveToGallery: Boolean = false,
    val quality: Int = 100,
    val limit: Int = 0,
)

class MultiCamera(private val bridge: Bridge) {

    fun buildPhotoResult(file: File, settings: CaptureSettings): JSObject {
        val result = JSObject()
        val adjustedFile = ensureQuality(file, settings.quality)

        val saved = if (settings.saveToGallery) saveToGallery(adjustedFile) else false

        when (settings.resultType) {
            CameraResultType.BASE64 -> {
                val base64 = adjustedFile.toBase64(settings.quality)
                result.put("base64String", base64)
            }
            CameraResultType.DATA_URL -> {
                val base64 = adjustedFile.toBase64(settings.quality)
                result.put("dataUrl", "data:image/jpeg;base64,$base64")
            }
            CameraResultType.URI -> {
                result.put("path", adjustedFile.toURI().toString())
                getWebPath(adjustedFile)?.let { webPath ->
                    result.put("webPath", webPath)
                }
            }
        }

        result.put("format", "jpeg")
        result.put("saved", saved)
        result.put("exif", true as Boolean)
        return result
    }

    fun copyToCache(context: Context, uri: Uri, quality: Int): File {
        val file = File.createTempFile("gallery_photo_", ".jpg", context.cacheDir)
        val stream = context.contentResolver.openInputStream(uri) ?: return file
        stream.use { input ->
            val bitmap = input.toBitmap()
            FileOutputStream(file).use { out ->
                bitmap.compress(Bitmap.CompressFormat.JPEG, quality, out)
            }
        }
        return file
    }

    private fun ensureQuality(file: File, quality: Int): File {
        if (quality >= 100) return file

        val bitmap = BitmapFactory.decodeFile(file.absolutePath)
        FileOutputStream(file).use { stream ->
            bitmap.compress(Bitmap.CompressFormat.JPEG, quality, stream)
        }
        return file
    }

    private fun saveToGallery(file: File): Boolean {
        val resolver = bridge.context.contentResolver
        val name = "multi_camera_${UUID.randomUUID()}"
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, "$name.jpg")
            put(MediaStore.MediaColumns.MIME_TYPE, "image/jpeg")
        }

        val collection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        } else {
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        }

        val uri = resolver.insert(collection, values) ?: return false

        return runCatching {
            resolver.openOutputStream(uri)?.use { output ->
                file.inputStream().use { input ->
                    input.copyTo(output)
                }
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                values.clear()
                values.put(MediaStore.Images.Media.IS_PENDING, 0)
                resolver.update(uri, values, null, null)
            }
            true
        }.getOrDefault(false)
    }

    private fun File.toBase64(quality: Int): String {
        val bitmap = BitmapFactory.decodeFile(absolutePath)
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, quality, stream)
        return Base64.encodeToString(stream.toByteArray(), Base64.NO_WRAP)
    }

    private fun InputStream.toBitmap(): Bitmap {
        return BitmapFactory.decodeStream(this)
    }

    private fun getWebPath(file: File): String? {
        val host = bridge.localUrl ?: bridge.serverUrl ?: return null
        return FileUtils.getPortablePath(bridge.context, host, Uri.fromFile(file))
    }
}
