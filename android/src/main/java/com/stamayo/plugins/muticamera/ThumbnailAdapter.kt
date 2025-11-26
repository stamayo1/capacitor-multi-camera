package com.stamayo.plugins.muticamera

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageButton
import android.widget.ImageView
import androidx.recyclerview.widget.RecyclerView
import java.io.File

class ThumbnailAdapter(
    private val items: List<File>,
    private val onRemove: (Int, File) -> Unit,
) : RecyclerView.Adapter<ThumbnailAdapter.ViewHolder>() {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(parent.context).inflate(R.layout.item_thumbnail, parent, false)
        return ViewHolder(view)
    }

    override fun getItemCount(): Int = items.size

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        holder.bind(items[position])
    }

    inner class ViewHolder(view: View) : RecyclerView.ViewHolder(view) {
        private val imageView: ImageView = view.findViewById(R.id.image_thumb)
        private val removeButton: ImageButton = view.findViewById(R.id.btn_remove)

        fun bind(file: File) {
            val bitmap = decodeThumbnail(file)
            imageView.setImageBitmap(bitmap)
            removeButton.setOnClickListener {
                val position = bindingAdapterPosition
                if (position != RecyclerView.NO_POSITION) {
                    onRemove(position, file)
                }
            }
        }
    }

    private fun decodeThumbnail(file: File): Bitmap? {
        val targetSize = 200
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(file.absolutePath, bounds)

        val sampleSize = calculateSampleSize(bounds, targetSize, targetSize)
        val options = BitmapFactory.Options().apply {
            inSampleSize = sampleSize
            inPreferredConfig = Bitmap.Config.RGB_565
        }

        return BitmapFactory.decodeFile(file.absolutePath, options)
    }

    private fun calculateSampleSize(bounds: BitmapFactory.Options, reqWidth: Int, reqHeight: Int): Int {
        val rawWidth = bounds.outWidth
        val rawHeight = bounds.outHeight
        if (rawWidth <= 0 || rawHeight <= 0) return 1

        var inSampleSize = 1
        var halfHeight = rawHeight / 2
        var halfWidth = rawWidth / 2

        while (halfHeight / inSampleSize >= reqHeight && halfWidth / inSampleSize >= reqWidth) {
            inSampleSize *= 2
        }

        return inSampleSize.coerceAtLeast(1)
    }
}
