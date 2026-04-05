package io.github.hyperisland.utils

import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import android.graphics.drawable.Icon
import androidx.core.graphics.createBitmap

fun Drawable.toBitmap(size: Int): Bitmap {
    val bmp = createBitmap(size, size, Bitmap.Config.ARGB_8888)
    setBounds(0, 0, size, size)
    draw(Canvas(bmp))
    return bmp
}

fun PackageManager.getAppIcon(packageName: String, size: Int = 192): Icon? {
    return try {
        Icon.createWithBitmap(getApplicationIcon(packageName).toBitmap(size))
    } catch (_: Exception) {
        null
    }
}
