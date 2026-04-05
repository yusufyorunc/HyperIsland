package io.github.hyperisland.xposed.template

import android.R
import android.content.Context
import android.graphics.drawable.Icon
import android.os.Bundle
import io.github.hyperisland.xposed.logError
import io.github.hyperisland.xposed.template.renderer.resolveRenderer


object DownloadLiteIslandNotification : IslandTemplate {

    private const val TAG = "HyperIsland[DownloadIslandLite]"
    const val TEMPLATE_ID = "download_lite"

    override val id = TEMPLATE_ID

    override fun inject(context: Context, extras: Bundle, data: NotifData) {
        try {
            val vm = process(context, data)
            resolveRenderer(data.renderer).render(context, extras, vm)
            //module.log("$TAG: "HyperIsland[DownloadLite]: injected — ${data.title} ($stateTag) buttons=${data.actions.size}")
        } catch (e: Exception) {
            logError("$TAG: injection error: ${e.message}")
        }
    }

    // ── 消息处理 ──────────────────────────────────────────────────────────────

    fun process(context: Context, data: NotifData): IslandViewModel {
        val isComplete = data.progress >= 100
        val isPaused = !isComplete && "${data.title} ${data.subtitle} ".let {
            it.contains("暂停") || it.contains("已暂停") || it.contains("暂停中") ||
                    it.contains("paused", ignoreCase = true)
        }
        val hasValidProgress = data.progress in 0..100
        val safeProgress = data.progress.coerceIn(0, 100)
        val shouldShowProgress = !isComplete && !isPaused && hasValidProgress

        val tintColor = when {
            isComplete -> 0xFF4CAF50.toInt()
            isPaused -> 0xFFFF9800.toInt()
            else -> 0xFF2196F3.toInt()
        }
        val iconRes = if (isComplete) R.drawable.stat_sys_download_done
        else R.drawable.stat_sys_download
        val fallback = Icon.createWithResource(context, iconRes).apply { setTint(tintColor) }

        val islandIcon = data.resolveModeIconAutoNotif(data.iconMode, fallback).toRounded(context)

        val focusIcon =
            data.resolveModeIconWithAppFallback(data.focusIconMode, fallback).toRounded(context)

        return IslandViewModel(
            templateId = TEMPLATE_ID,
            leftTitle = "",
            rightTitle = "",
            focusTitle = data.title,
            focusContent = data.subtitle.ifEmpty { data.title },
            islandIcon = islandIcon,
            focusIcon = focusIcon,
            circularProgress = if (shouldShowProgress) safeProgress else null,
            showRightSide = shouldShowProgress,
            actions = data.actions,
            updatable = !isComplete && !isPaused,
            showNotification = data.focusNotif != "off",
            setFocusProxy = false,
            preserveStatusBarSmallIcon = false,
            firstFloat = data.firstFloat == "on",
            enableFloat = data.enableFloatMode == "on",
            timeoutSecs = data.islandTimeout,
            isOngoing = data.isOngoing,
            showIslandIcon = data.showIslandIcon == "on",
            highlightColor = data.highlightColor,
            showLeftHighlightColor = data.showLeftHighlightColor,
            showRightHighlightColor = data.showRightHighlightColor,
        )
    }
}
