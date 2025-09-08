package com.stamayo.plugins.muticamera

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.ContextCompat
import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
import com.getcapacitor.annotation.Permission
import com.getcapacitor.annotation.PermissionCallback

@CapacitorPlugin(name = "Camera",
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

    // Permission alias constans
    companion object {
        const val CAMERA_ALIAS = "camera"
        const val PHOTOS_ALIAS = "photos"
        const val SAVE_GALLERY = "saveGallery"
        const val READ_EXTERNAL_ALIAS = "readExternalAlias"
    }

    private val implementation = MultiCamera()

    @PluginMethod
    fun echo(call: PluginCall) {
        val value = call.getString("value")

        val ret = JSObject()
        ret.put("value", implementation.echo(value ?: ""))
        call.resolve(ret)
    }


    @PluginMethod
    override fun requestPermissions(call: PluginCall) {
        val sdk = android.os.Build.VERSION.SDK_INT

        val alias = mutableListOf(MultiCameraPlugin.CAMERA_ALIAS)

        if (sdk <= Build.VERSION_CODES.Q){
            // sdk <= Android 11+ (29)
            alias.add(MultiCameraPlugin.SAVE_GALLERY)
        }else
            if ( sdk >= Build.VERSION_CODES.R && sdk <= Build.VERSION_CODES.S_V2){
            // sdk >= Android 12 (31)  sdk <= Android 12 (32)
            alias.add(MultiCameraPlugin.READ_EXTERNAL_ALIAS)
        } else {
            // sdk >= Android 13+ (33)
            alias.add(MultiCameraPlugin.PHOTOS_ALIAS)
        }

        requestPermissionForAliases(alias.toTypedArray(), call, "permissionsCallback")
    }


    @PermissionCallback
    private fun permissionsCallback(call: PluginCall) {
        val result = JSObject()
        result.put("camera", getPermissionState("camera").toString())
        result.put("photos", getPhotosPermissionState())
        call.resolve(result)
    }

    private fun getPhotosPermissionState(): String {
        val sdk = android.os.Build.VERSION.SDK_INT

        return when {
            sdk >= Build.VERSION_CODES.TIRAMISU -> {
                if (isPermissionGranted(Manifest.permission.READ_MEDIA_IMAGES)) "granted" else "denied"
            }
            sdk >= Build.VERSION_CODES.S && sdk <= Build.VERSION_CODES.S_V2 -> {
                if (isPermissionGranted(Manifest.permission.READ_EXTERNAL_STORAGE)) "granted"
                else "denied"
            }
            else -> {
                if (isPermissionGranted(Manifest.permission.READ_EXTERNAL_STORAGE) && isPermissionGranted(
                        Manifest.permission.WRITE_EXTERNAL_STORAGE
                    )) "granted"
                else "denied"
            }
        }
    }

    private fun isPermissionGranted(permission: String): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            permission
        ) == PackageManager.PERMISSION_GRANTED
    }
}
