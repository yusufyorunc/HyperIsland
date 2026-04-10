package io.github.hyperisland.utils

import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.drawable.Drawable
import android.graphics.drawable.Icon
import androidx.core.graphics.createBitmap
import java.util.Locale
import kotlin.math.roundToInt

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

fun Icon.resolveDynamicHighlightColor(context: Context, mode: String): String? {
    val factor = when (mode) {
        "dark" -> 0.82f
        "darker" -> 0.64f
        else -> 1.0f
    }

    return try {
        val bitmap = toBitmap(context, 96) ?: return null
        val color = bitmap.pickDominantColor()
        bitmap.recycle()

        val r = ((Color.red(color) * factor).roundToInt()).coerceIn(0, 255)
        val g = ((Color.green(color) * factor).roundToInt()).coerceIn(0, 255)
        val b = ((Color.blue(color) * factor).roundToInt()).coerceIn(0, 255)
        String.format(Locale.US, "#%02X%02X%02X", r, g, b)
    } catch (_: Exception) {
        null
    }
}

private fun Icon.toBitmap(context: Context, size: Int): Bitmap? {
    val drawable = loadDrawable(context) ?: return null
    val bmp = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bmp)
    drawable.setBounds(0, 0, size, size)
    drawable.draw(canvas)
    return bmp
}

private fun Bitmap.pickDominantColor(): Int {
    val w = width
    val h = height
    if (w <= 0 || h <= 0) return Color.WHITE

    val bins = HashMap<Int, LongArray>()
    val hsv = FloatArray(3)

    var y = 0
    while (y < h) {
        var x = 0
        while (x < w) {
            val c = getPixel(x, y)
            val a = Color.alpha(c)
            if (a >= 40) {
                Color.colorToHSV(c, hsv)
                val sat = hsv[1]
                val value = hsv[2]
                if (value >= 0.12f) {
                    val weight =
                        ((a / 255f) * (0.35f + sat * 0.9f + value * 0.25f) * 1000f)
                            .toLong()
                            .coerceAtLeast(1L)
                    val r = Color.red(c)
                    val g = Color.green(c)
                    val b = Color.blue(c)
                    val bucket = ((r shr 4) shl 8) or ((g shr 4) shl 4) or (b shr 4)
                    val acc = bins.getOrPut(bucket) { LongArray(4) }
                    acc[0] += weight
                    acc[1] += r * weight
                    acc[2] += g * weight
                    acc[3] += b * weight
                }
            }
            x += 2
        }
        y += 2
    }

    val best = bins.maxByOrNull { it.value[0] }?.value
    if (best == null || best[0] <= 0L) {
        val center = getPixel(w / 2, h / 2)
        return Color.rgb(Color.red(center), Color.green(center), Color.blue(center))
    }

    val total = best[0].toDouble()
    val r = (best[1] / total).roundToInt().coerceIn(0, 255)
    val g = (best[2] / total).roundToInt().coerceIn(0, 255)
    val b = (best[3] / total).roundToInt().coerceIn(0, 255)
    return Color.rgb(r, g, b)
}
