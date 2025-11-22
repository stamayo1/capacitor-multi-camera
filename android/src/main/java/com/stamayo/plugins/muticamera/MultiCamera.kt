package com.stamayo.plugins.muticamera

import android.content.ContentValues
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.util.Base64
import com.getcapacitor.Bridge
import com.getcapacitor.FileUtils
import com.getcapacitor.JSObject
import androidx.exifinterface.media.ExifInterface
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
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
    val width: Int = 0,
    val height: Int = 0,
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

    fun copyToCache(context: Context, uri: Uri, settings: CaptureSettings): File {
        val file = File.createTempFile("gallery_photo_", ".jpg", context.cacheDir)
        val bitmap = context.decodeBitmapWithOrientation(uri, settings.width, settings.height) ?: return file
        val scaled = bitmap.scaleIfNeeded(settings.width, settings.height)
        FileOutputStream(file).use { out ->
            scaled.compress(Bitmap.CompressFormat.JPEG, settings.quality, out)
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

    private fun Context.decodeBitmapWithOrientation(uri: Uri, maxWidth: Int = 0, maxHeight: Int = 0): Bitmap? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        contentResolver.openInputStream(uri)?.use { input ->
            BitmapFactory.decodeStream(input, null, bounds)
        }

        val inSampleSize = calculateSampleSize(bounds, maxWidth, maxHeight)
        val options = BitmapFactory.Options().apply {
            this.inSampleSize = inSampleSize
            inPreferredConfig = Bitmap.Config.ARGB_8888
        }

        val bitmap = contentResolver.openInputStream(uri)?.use { input ->
            BitmapFactory.decodeStream(input, null, options)
        } ?: return null

        val orientation = contentResolver.openInputStream(uri)?.use { inputStream ->
            ExifInterface(inputStream).getAttributeInt(
                ExifInterface.TAG_ORIENTATION,
                ExifInterface.ORIENTATION_UNDEFINED,
            )
        } ?: ExifInterface.ORIENTATION_UNDEFINED

        return bitmap.applyOrientation(orientation)
    }

    private fun calculateSampleSize(bounds: BitmapFactory.Options, maxWidth: Int, maxHeight: Int): Int {
        if (maxWidth <= 0 && maxHeight <= 0) return 1

        val (rawWidth, rawHeight) = bounds.outWidth to bounds.outHeight
        if (rawWidth <= 0 || rawHeight <= 0) return 1

        val targetWidth = if (maxWidth > 0) maxWidth else rawWidth
        val targetHeight = if (maxHeight > 0) maxHeight else rawHeight

        var inSampleSize = 1
        var halfHeight = rawHeight / 2
        var halfWidth = rawWidth / 2

        while (halfHeight / inSampleSize >= targetHeight && halfWidth / inSampleSize >= targetWidth) {
            inSampleSize *= 2
        }

        return inSampleSize.coerceAtLeast(1)
    }

    private fun Bitmap.applyOrientation(orientation: Int): Bitmap {
        val matrix = Matrix()
        when (orientation) {
            ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> matrix.preScale(-1f, 1f)
            ExifInterface.ORIENTATION_ROTATE_180 -> matrix.postRotate(180f)
            ExifInterface.ORIENTATION_FLIP_VERTICAL -> matrix.preScale(1f, -1f)
            ExifInterface.ORIENTATION_TRANSPOSE -> {
                matrix.preScale(-1f, 1f)
                matrix.postRotate(90f)
            }
            ExifInterface.ORIENTATION_ROTATE_90 -> matrix.postRotate(90f)
            ExifInterface.ORIENTATION_TRANSVERSE -> {
                matrix.preScale(-1f, 1f)
                matrix.postRotate(270f)
            }
            ExifInterface.ORIENTATION_ROTATE_270 -> matrix.postRotate(270f)
            else -> return this
        }

        if (matrix.isIdentity) return this

        return Bitmap.createBitmap(this, 0, 0, width, height, matrix, true)
    }

    private fun Bitmap.scaleIfNeeded(maxWidth: Int, maxHeight: Int): Bitmap {
        if (maxWidth <= 0 && maxHeight <= 0) return this

        val aspectRatio = width.toFloat() / height.toFloat()

        val targetWidth = when {
            maxWidth > 0 -> maxWidth
            maxHeight > 0 -> (maxHeight * aspectRatio).toInt()
            else -> width
        }

        val targetHeight = when {
            maxHeight > 0 -> maxHeight
            maxWidth > 0 -> (maxWidth / aspectRatio).toInt()
            else -> height
        }

        if (targetWidth >= width && targetHeight >= height) return this

        return Bitmap.createScaledBitmap(this, targetWidth, targetHeight, true)
    }

    private fun getWebPath(file: File): String? {
        val host = bridge.localUrl ?: bridge.serverUrl ?: return null
        return FileUtils.getPortablePath(bridge.context, host, Uri.fromFile(file))
    }
}
