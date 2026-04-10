package io.github.hyperisland.xposed.template

import android.app.Notification
import android.app.PendingIntent
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.RectF
import android.graphics.drawable.Icon
import android.os.Bundle
import io.github.hyperisland.xposed.ConfigManager
import androidx.core.graphics.createBitmap

internal fun Context.moduleContext(): Context = try {
    createPackageContext("io.github.hyperisland", Context.CONTEXT_IGNORE_SECURITY)
} catch (_: Exception) {
    this
}


fun Icon.toRounded(context: Context, radiusFraction: Float = 0.25f): Icon {
    if (!isRoundIconEnabled()) return this
    return try {
        val drawable = loadDrawable(context) ?: return this
        val size = 192
        val src = createBitmap(size, size, Bitmap.Config.ARGB_8888)
        drawable.setBounds(0, 0, size, size)
        drawable.draw(Canvas(src))

        val dst = createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(dst)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        val r = size * radiusFraction
        canvas.drawRoundRect(RectF(0f, 0f, size.toFloat(), size.toFloat()), r, r, paint)
        paint.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_IN)
        canvas.drawBitmap(src, 0f, 0f, paint)
        src.recycle()

        Icon.createWithBitmap(dst)
    } catch (_: Exception) {
        this
    }
}

private fun isRoundIconEnabled(): Boolean =
    ConfigManager.getBoolean("pref_round_icon", true)


interface IslandTemplate {
    val id: String
    fun inject(context: Context, extras: Bundle, data: NotifData)
}

fun Context.defaultDialogIcon(): Icon =
    Icon.createWithResource(this, android.R.drawable.ic_dialog_info)

data class NotifData(
    val pkg: String,
    val channelId: String,
    val notifId: Int,
    val title: String,
    val subtitle: String,
    val progress: Int,
    val actions: List<Notification.Action>,
    val notifIcon: Icon?,
    val largeIcon: Icon?,
    val appIconRaw: Icon? = null,
    val iconMode: String = "auto",
    val focusIconMode: String = "auto",
    val focusNotif: String = "default",
    val preserveStatusBarSmallIcon: String = "default",
    val firstFloat: String = "default",
    val enableFloatMode: String = "default",
    val islandTimeout: Int = 5,
    val showIslandIcon: String = "default",
    val isOngoing: Boolean = false,
    val contentIntent: PendingIntent? = null,
    val renderer: String = "image_text_with_buttons_4",
    val highlightColor: String? = null,
    val showLeftHighlightColor: Boolean = false,
    val showRightHighlightColor: Boolean = false,
    val outerGlow: Boolean = false,
)

private fun firstOrFallback(first: Icon?, fallback: Icon): Icon =
    first ?: fallback

private fun firstOrFallback(first: Icon?, second: Icon?, fallback: Icon): Icon =
    first ?: second ?: fallback

private fun firstOrFallback(first: Icon?, second: Icon?, third: Icon?, fallback: Icon): Icon =
    first ?: second ?: third ?: fallback


fun NotifData.resolveModeIconAutoLarge(mode: String, fallback: Icon): Icon =
    when (mode) {
        "notif_small" -> firstOrFallback(notifIcon, fallback)
        "notif_large" -> firstOrFallback(largeIcon, notifIcon, fallback)
        "app_icon" -> firstOrFallback(appIconRaw, fallback)
        else -> firstOrFallback(largeIcon, notifIcon, fallback)
    }


fun NotifData.resolveModeIconAutoNotif(mode: String, fallback: Icon): Icon =
    when (mode) {
        "notif_small" -> firstOrFallback(notifIcon, fallback)
        "notif_large" -> firstOrFallback(largeIcon, notifIcon, fallback)
        "app_icon" -> firstOrFallback(appIconRaw, fallback)
        else -> firstOrFallback(notifIcon, largeIcon, fallback)
    }

fun NotifData.resolveModeIconWithAppFallback(mode: String, fallback: Icon): Icon =
    when (mode) {
        "notif_small" -> firstOrFallback(notifIcon, appIconRaw, fallback)
        "notif_large" -> firstOrFallback(largeIcon, appIconRaw, notifIcon, fallback)
        "app_icon" -> firstOrFallback(appIconRaw, fallback)
        else -> firstOrFallback(largeIcon, appIconRaw, notifIcon, fallback)
    }
