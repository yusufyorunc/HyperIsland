package io.github.hyperisland.xposed.templates

import android.app.Notification
import android.content.Context
import android.graphics.drawable.Icon
import android.os.Build
import android.os.Bundle
import io.github.hyperisland.xposed.IslandTemplate
import io.github.hyperisland.xposed.NotifData
import io.github.hyperisland.xposed.toRounded
import de.robv.android.xposed.XposedBridge
import io.github.d4viddf.hyperisland_kit.HyperIslandNotification
import io.github.d4viddf.hyperisland_kit.HyperPicture
import io.github.d4viddf.hyperisland_kit.models.CircularProgressInfo
import io.github.d4viddf.hyperisland_kit.models.ImageTextInfoLeft
import io.github.d4viddf.hyperisland_kit.models.PicInfo
import io.github.d4viddf.hyperisland_kit.models.ProgressTextInfo
import io.github.d4viddf.hyperisland_kit.models.TextInfo

/**
 * 下载 Lite 灵动岛通知构建器。
 * 基于 GenericProgressIslandNotification，摘要态仅显示图标与环形进度，无任何文字。
 */
object DownloadLiteIslandNotification : IslandTemplate {

    const val TEMPLATE_ID = "download_lite"

    override val id = TEMPLATE_ID

    override fun inject(context: Context, extras: Bundle, data: NotifData) = inject(
        context         = context,
        extras          = extras,
        title           = data.title,
        progress        = data.progress,
        notifIcon       = data.notifIcon,
        largeIcon       = data.largeIcon,
        appIconRaw      = data.appIconRaw,
        iconMode        = data.iconMode,
        firstFloat      = data.firstFloat,
        enableFloatMode = data.enableFloatMode,
        timeoutSecs     = data.islandTimeout,
    )

    private fun inject(
        context: Context,
        extras: Bundle,
        title: String,
        progress: Int,
        notifIcon: Icon?,
        largeIcon: Icon?,
        appIconRaw: Icon?,
        iconMode: String,
        firstFloat: String,
        enableFloatMode: String,
        timeoutSecs: Int,
    ) {
        try {
            val isComplete = progress >= 100

            val iconRes   = if (isComplete) android.R.drawable.stat_sys_download_done
                            else            android.R.drawable.stat_sys_download
            val tintColor = if (isComplete) 0xFF4CAF50.toInt() else 0xFF2196F3.toInt()
            val fallbackIcon = Icon.createWithResource(context, iconRes).apply { setTint(tintColor) }

            val displayIcon = when (iconMode) {
                "notif_small" -> notifIcon ?: fallbackIcon
                "notif_large" -> largeIcon ?: notifIcon ?: fallbackIcon
                "app_icon"    -> appIconRaw ?: fallbackIcon
                else          -> notifIcon ?: largeIcon ?: fallbackIcon
            }.toRounded(context)

            val resolvedFirstFloat  = firstFloat      == "on"
            val resolvedEnableFloat = enableFloatMode == "on"

            val builder = HyperIslandNotification.Builder(context, TEMPLATE_ID, title)

            builder.addPicture(HyperPicture("key_dl_lite_icon", displayIcon))

            // 摘要态：小岛带环形进度（下载中），否则仅图标
            if (!isComplete && progress > 0) {
                builder.setSmallIslandCircularProgress("key_dl_lite_icon", progress)
            } else {
                builder.setSmallIsland("key_dl_lite_icon")
            }

            // 大岛：左侧仅图标（无文字），右侧仅环形进度（无文字）
            if (!isComplete && progress > 0) {
                builder.setBigIslandInfo(
                    left = ImageTextInfoLeft(
                        type     = 1,
                        picInfo  = PicInfo(type = 1, pic = "key_dl_lite_icon"),
                        textInfo = TextInfo(title = ""),
                    ),
                    progressText = ProgressTextInfo(
                        progressInfo = CircularProgressInfo(progress = progress),
                        textInfo     = TextInfo(title = ""),
                    ),
                )
            } else {
                // 完成/暂停/等待：仅左侧图标
                builder.setBigIslandInfo(
                    left = ImageTextInfoLeft(
                        type     = 1,
                        picInfo  = PicInfo(type = 1, pic = "key_dl_lite_icon"),
                        textInfo = TextInfo(title = ""),
                    ),
                )
            }

            builder.setIslandFirstFloat(resolvedFirstFloat)
            builder.setEnableFloat(resolvedEnableFloat)
            builder.setIslandConfig(timeout = timeoutSecs)

            val resourceBundle = builder.buildResourceBundle()
            extras.putAll(resourceBundle)
            flattenActionsToExtras(resourceBundle, extras)

            val jsonParam = injectUpdatable(builder.buildJsonParam(), !isComplete)
            extras.putString("miui.focus.param", jsonParam)

            XposedBridge.log("HyperIsland[DownloadLite]: Island injected — $title (${progress}%)")

        } catch (e: Exception) {
            XposedBridge.log("HyperIsland[DownloadLite]: Island injection error: ${e.message}")
        }
    }

    private fun injectUpdatable(jsonParam: String, updatable: Boolean): String {
        return try {
            val json = org.json.JSONObject(jsonParam)
            val pv2  = json.optJSONObject("param_v2") ?: org.json.JSONObject()
            pv2.put("updatable", updatable)
            json.put("param_v2", pv2)
            json.toString()
        } catch (_: Exception) { jsonParam }
    }

    private fun flattenActionsToExtras(resourceBundle: Bundle, extras: Bundle) {
        val nested = resourceBundle.getBundle("miui.focus.actions") ?: return
        for (key in nested.keySet()) {
            val action: Notification.Action? = if (Build.VERSION.SDK_INT >= 33)
                nested.getParcelable(key, Notification.Action::class.java)
            else
                @Suppress("DEPRECATION") nested.getParcelable(key)
            if (action != null) extras.putParcelable(key, action)
        }
    }
}
