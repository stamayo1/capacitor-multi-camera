package com.stamayo.plugins.muticamera

import android.app.Activity
import android.content.DialogInterface
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.ImageButton
import androidx.activity.ComponentActivity
import androidx.camera.core.Camera
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import java.io.File
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class MultiCameraActivity : ComponentActivity() {

    private lateinit var previewView: PreviewView
    private lateinit var captureButton: ImageButton
    private lateinit var closeButton: ImageButton
    private lateinit var confirmButton: ImageButton
    private lateinit var torchButton: ImageButton
    private lateinit var switchCameraButton: ImageButton
    private lateinit var thumbnails: RecyclerView

    private var camera: Camera? = null
    private var imageCapture: ImageCapture? = null
    private var cameraSelector: CameraSelector = CameraSelector.DEFAULT_BACK_CAMERA
    private lateinit var cameraExecutor: ExecutorService

    private val capturedFiles = mutableListOf<File>()
    private lateinit var adapter: ThumbnailAdapter
    private var hasConfirmedResult = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_multi_camera)

        bindViews()
        setupThumbnails()
        cameraExecutor = Executors.newSingleThreadExecutor()

        startCamera()
        setupActions()
    }

    private fun bindViews() {
        previewView = findViewById(R.id.preview_view)
        captureButton = findViewById(R.id.btn_capture)
        closeButton = findViewById(R.id.btn_close)
        confirmButton = findViewById(R.id.btn_confirm)
        torchButton = findViewById(R.id.btn_torch)
        switchCameraButton = findViewById(R.id.btn_switch_camera)
        thumbnails = findViewById(R.id.thumbnails)
    }

    private fun setupThumbnails() {
        adapter = ThumbnailAdapter(capturedFiles) { file ->
            capturedFiles.remove(file)
            file.delete()
            adapter.notifyDataSetChanged()
            confirmButton.visibility = if (capturedFiles.isEmpty()) View.GONE else View.VISIBLE
        }
        thumbnails.layoutManager = LinearLayoutManager(this, LinearLayoutManager.HORIZONTAL, false)
        thumbnails.adapter = adapter
    }

    private fun setupActions() {
        closeButton.setOnClickListener { finishWithCancel() }
        confirmButton.setOnClickListener { finishWithResult() }
        captureButton.setOnClickListener { capturePhoto() }
        switchCameraButton.setOnClickListener { toggleCamera() }
        torchButton.setOnClickListener { toggleTorch() }
    }

    private fun startCamera() {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(this)

        cameraProviderFuture.addListener({
            val cameraProvider: ProcessCameraProvider = cameraProviderFuture.get()
            val preview = Preview.Builder().build().also {
                it.setSurfaceProvider(previewView.surfaceProvider)
            }

            imageCapture = ImageCapture.Builder()
                .setTargetRotation(previewView.display?.rotation ?: 0)
                .build()

            try {
                cameraProvider.unbindAll()
                camera = cameraProvider.bindToLifecycle(
                    this,
                    cameraSelector,
                    preview,
                    imageCapture
                )
            } catch (exc: Exception) {
                finishWithCancel()
            }
        }, ContextCompat.getMainExecutor(this))
    }

    private fun capturePhoto() {
        val imageCapture = imageCapture ?: return
        val photoFile = File.createTempFile("multi_camera_", ".jpg", cacheDir)

        val outputOptions = ImageCapture.OutputFileOptions.Builder(photoFile).build()

        imageCapture.takePicture(
            outputOptions,
            cameraExecutor,
            object : ImageCapture.OnImageSavedCallback {
                override fun onImageSaved(outputFileResults: ImageCapture.OutputFileResults) {
                    capturedFiles.add(photoFile)
                    runOnUiThread {
                        adapter.notifyDataSetChanged()
                        confirmButton.visibility = View.VISIBLE
                    }
                }

                override fun onError(exception: ImageCaptureException) {
                    // ignore error for this capture
                }
            }
        )
    }

    private fun toggleTorch() {
        val hasTorch = camera?.cameraInfo?.hasFlashUnit() == true
        if (hasTorch) {
            val torchState = camera?.cameraInfo?.torchState?.value
            val enable = torchState != 1
            camera?.cameraControl?.enableTorch(enable)
        }
    }

    private fun toggleCamera() {
        cameraSelector = if (cameraSelector == CameraSelector.DEFAULT_BACK_CAMERA) {
            CameraSelector.DEFAULT_FRONT_CAMERA
        } else {
            CameraSelector.DEFAULT_BACK_CAMERA
        }
        startCamera()
    }


    private fun setZoom(level: Float) {
        val control = camera?.cameraControl ?: return
        val zoomState = camera?.cameraInfo?.zoomState?.value
        val clamped = zoomState?.let { state ->
            level.coerceIn(state.minZoomRatio, state.maxZoomRatio)
        } ?: level
        control.setZoomRatio(clamped)
    }

    private fun finishWithCancel() {
        cleanupCapturedFiles()
        setResult(Activity.RESULT_CANCELED)
        finish()
    }

    private fun finishWithResult() {
        hasConfirmedResult = true
        val data = Intent()
        data.putExtra("photos", capturedFiles.map { it.absolutePath }.toTypedArray())
        setResult(Activity.RESULT_OK, data)
        finish()
    }

    override fun onDestroy() {
        super.onDestroy()
        if (::cameraExecutor.isInitialized) {
            cameraExecutor.shutdown()
        }

        if (!hasConfirmedResult) {
            cleanupCapturedFiles()
        }
    }

    private fun cleanupCapturedFiles() {
        capturedFiles.forEach { file ->
            file.delete()
        }
        capturedFiles.clear()
    }
}
