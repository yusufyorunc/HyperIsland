package io.github.hyperisland.xposed.template

import android.content.Context
import android.graphics.drawable.Icon
import android.os.Bundle
import io.github.hyperisland.R
import io.github.hyperisland.xposed.logError
import io.github.hyperisland.xposed.template.GenericDownloadIslandNotification.process
import io.github.hyperisland.xposed.template.renderer.ImageTextWithButtonsRenderer
import io.github.hyperisland.xposed.template.renderer.resolveRenderer


object GenericDownloadIslandNotification : IslandTemplate {

    private const val TAG = "HyperIsland[DownloadIsland]"
    const val TEMPLATE_ID = "generic_progress"

    override val id = TEMPLATE_ID

    override fun inject(context: Context, extras: Bundle, data: NotifData) {
        try {
            val vm = process(context, data)
            resolveRenderer(data.renderer).render(context, extras, vm)
        } catch (e: Exception) {
            logError("$TAG: injection error: ${e.message}")
        }
    }

    private val NOISE_REGEX = Regex(
        """(?i)\d+(\.\d+)?\s*(b|kb|mb|gb|tb|kib|mib|gib)\s*/\s*\d+(\.\d+)?\s*(b|kb|mb|gb|tb|kib|mib|gib)""" +
                """|(?i)\d+(\.\d+)?\s*(mb/s|kb/s|gb/s|mib/s|kib/s|mbps|kbps|gbps|m/s|兆/秒|兆字节/秒)""" +
                """|(?i)\d+\s*%""" +
                """|下载中|正在下载|准备下载|开始下载|等待下载|排队中|等待中|连接中|获取中|暂停中|已暂停|下载完成|下载失败|下载错误""" +
                """|剩余\s*\d+|还有\s*\d+|剩余时间""" +
                """|(?i)\bdownloading\b|\bdownload\b|\bqueued\b|\bpending\b|\bwaiting\b|\bpaused\b|\bconnecting\b|\bpreparing\b|\bremaining\b"""
    )

    private val DOWNLOAD_PREFIXES = listOf("正在下载", "下载中", "下载", "Downloading", "Download")

    private fun isStatusNoise(text: String): Boolean = NOISE_REGEX.containsMatchIn(text)

    private fun stripDownloadPrefix(text: String): String {
        var s = text.trim()
        for (prefix in DOWNLOAD_PREFIXES) {
            if (s.startsWith(prefix, ignoreCase = true)) {
                s = s.removePrefix(prefix).trimStart(':', '：', ' ', '-')
                break
            }
        }
        return s.trim()
    }

    private fun pickContent(title: String, subtitle: String): String {
        val subClean = subtitle.isNotEmpty() && !isStatusNoise(subtitle)
        val titleClean = title.isNotEmpty() && !isStatusNoise(title)
        return when {
            subClean -> subtitle
            titleClean -> title
            subtitle.isNotEmpty() -> subtitle
            else -> stripDownloadPrefix(title)
        }
    }

    fun process(context: Context, data: NotifData): IslandViewModel {
        val combined = "${data.title} ${data.subtitle} "
        val isComplete = data.progress >= 100 ||
                combined.contains("完成") || combined.contains("成功") ||
                combined.contains("complete", ignoreCase = true) ||
                combined.contains("finished", ignoreCase = true) ||
                combined.contains("done", ignoreCase = true)
        val isPaused = !isComplete && (
                combined.contains("暂停") || combined.contains("已暂停") || combined.contains("暂停中") ||
                        combined.contains("paused", ignoreCase = true)
                )
        val isWaiting = !isComplete && !isPaused && (
                combined.contains("等待") || combined.contains("准备中") ||
                        combined.contains("队列") || combined.contains("排队") ||
                        combined.contains("pending", ignoreCase = true) ||
                        combined.contains("queued", ignoreCase = true) ||
                        combined.contains("waiting", ignoreCase = true)
                )

        val hasValidProgress = data.progress in 0..100
        val safeProgress = data.progress.coerceIn(0, 100)
        val shouldShowProgress = !isComplete && !isWaiting && !isPaused && hasValidProgress

        val mc = context.moduleContext()
        val stateLabel = when {
            isComplete -> mc.getString(R.string.island_state_complete)
            isPaused -> mc.getString(R.string.island_state_paused)
            isWaiting -> mc.getString(R.string.island_state_waiting)
            else -> mc.getString(R.string.island_state_downloading)
        }

        val tintColor = when {
            isComplete -> 0xFF4CAF50.toInt()
            isPaused || isWaiting -> 0xFFFF9800.toInt()
            else -> 0xFF2196F3.toInt()
        }
        val iconRes = if (isComplete) android.R.drawable.stat_sys_download_done
        else android.R.drawable.stat_sys_download
        val fallback = Icon.createWithResource(context, iconRes).apply { setTint(tintColor) }

        val islandIcon = data.resolveModeIconAutoNotif(data.iconMode, fallback).toRounded(context)

        val focusIcon =
            data.resolveModeIconWithAppFallback(data.focusIconMode, fallback).toRounded(context)

        return IslandViewModel(
            templateId = TEMPLATE_ID,
            leftTitle = stateLabel,
            rightTitle = pickContent(data.title, data.subtitle),
            focusTitle = data.title,
            focusContent = data.subtitle.ifEmpty { data.title },
            islandIcon = islandIcon,
            focusIcon = focusIcon,
            circularProgress = if (shouldShowProgress) safeProgress else null,
            showRightSide = true,
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
            outerGlow = data.outerGlow,
        )
    }
}
