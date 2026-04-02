package io.github.hyperisland.xposed.templates

import android.content.Context
import android.graphics.drawable.Icon
import android.os.Bundle
import io.github.hyperisland.xposed.IslandTemplate
import io.github.hyperisland.xposed.IslandViewModel
import io.github.hyperisland.xposed.NotifData
import io.github.hyperisland.xposed.logError
import io.github.hyperisland.xposed.renderer.formatIslandContent
import io.github.hyperisland.xposed.renderer.formatIslandTitle
import io.github.hyperisland.xposed.renderer.resolveRenderer
import io.github.hyperisland.xposed.resolveFocusIcon
import io.github.hyperisland.xposed.resolveIslandIcon
import io.github.hyperisland.xposed.toRounded

/**
 * 下载 Lite 灵动岛通知构建器。
 * 摘要态仅显示图标与环形进度，无任何文字。焦点通知与按钮与大版本保持一致。
 *
 * 消息处理（[process]）与渲染（[ImageTextWithButtonsRenderer]/[ImageTextWithButtonsWrapRenderer]）分离。
 */
object DownloadLiteIslandNotification : IslandTemplate {

    private const val TAG = "HyperIsland[DownloadIslandLite]"
    const val TEMPLATE_ID = "download_lite"

    override val id = TEMPLATE_ID

    override fun inject(context: Context, extras: Bundle, data: NotifData) {
        try {
            val vm = process(context, data)
            resolveRenderer(data.renderer).render(context, extras, vm)
            val stateTag = when {
                vm.circularProgress != null -> "${vm.circularProgress}%"
                !vm.updatable               -> "done"
                else                        -> "paused"
            }
            //module.log("$TAG: "HyperIsland[DownloadLite]: injected — ${data.title} ($stateTag) buttons=${data.actions.size}")
        } catch (e: Exception) {
            logError("$TAG: injection error: ${e.message}")
        }
    }

    // ── 消息处理 ──────────────────────────────────────────────────────────────

    fun process(context: Context, data: NotifData): IslandViewModel {
        val isComplete = data.progress >= 100
        val isPaused   = !isComplete && "${data.title} ${data.subtitle} ".let {
            it.contains("暂停") || it.contains("已暂停") || it.contains("暂停中") ||
            it.contains("paused", ignoreCase = true)
        }
        val hasValidProgress   = data.progress in 0..100
        val safeProgress       = data.progress.coerceIn(0, 100)
        val shouldShowProgress = !isComplete && !isPaused && hasValidProgress

        val tintColor = when {
            isComplete -> 0xFF4CAF50.toInt()
            isPaused   -> 0xFFFF9800.toInt()
            else       -> 0xFF2196F3.toInt()
        }
        val iconRes  = if (isComplete) android.R.drawable.stat_sys_download_done
                       else            android.R.drawable.stat_sys_download
        val fallback = Icon.createWithResource(context, iconRes).apply { setTint(tintColor) }

        val islandIcon = resolveIslandIcon(data, fallback, preferSmallWhenAuto = true).toRounded(context)
        val focusIcon = resolveFocusIcon(data, fallback).toRounded(context)
        val focusTitle = formatIslandTitle(data.title, fallback = "下载", maxVisualUnits = 48)
        val focusContent = formatIslandContent(data.subtitle, fallback = focusTitle, maxVisualUnits = 84)

        return IslandViewModel(
            templateId        = TEMPLATE_ID,
            leftTitle         = "",
            rightTitle        = "",
            focusTitle        = focusTitle,
            focusContent      = focusContent,
            islandIcon        = islandIcon,
            focusIcon         = focusIcon,
            // 下载中：circularProgress=进度，右侧=进度环；完成/暂停：两者为 null/false，仅左侧图标
            circularProgress  = if (shouldShowProgress) safeProgress else null,
            showRightSide     = shouldShowProgress,
            actions           = data.actions,
            updatable         = !isComplete && !isPaused,
            showNotification  = data.focusNotif != "off",
            setFocusProxy     = false,
            preserveStatusBarSmallIcon = false,
            firstFloat        = data.firstFloat == "on",
            enableFloat       = data.enableFloatMode == "on",
            timeoutSecs       = data.islandTimeout,
            isOngoing         = data.isOngoing,
            showIslandIcon    = data.showIslandIcon == "on",
        )
    }
}
