package io.github.hyperisland.xposed.template

import android.content.Context
import android.os.Bundle
import io.github.hyperisland.xposed.IslandDispatcher
import io.github.hyperisland.xposed.IslandRequest
import io.github.hyperisland.xposed.logError
import io.github.hyperisland.xposed.template.renderer.resolveRenderer

object NotificationIslandLiteNotification : IslandTemplate {

    private const val TAG = "HyperIsland[NotifIslandLite]"
    const val TEMPLATE_ID = "notification_island_lite"

    override val id = TEMPLATE_ID

    override fun inject(context: Context, extras: Bundle, data: NotifData) {
        val cleanedTitle = cleanTitle(data.title)
        val cleanedSubtitle = cleanSubtitle(data.subtitle, cleanedTitle)
        extras.remove("hyperisland_dispatched_proxy")

        if (data.focusNotif == "off") {
            injectViaDispatcher(context, data, cleanedTitle, cleanedSubtitle)
            extras.putBoolean("hyperisland_dispatched_proxy", true)
            return
        }
        try {
            val vm = process(context, data, cleanedTitle, cleanedSubtitle)
            resolveRenderer(data.renderer).render(context, extras, vm)
            extras.putBoolean("hyperisland_dispatched_proxy", false)
            //ConfigManager.module()?.log("$TAG: injected — raw=${data.title} | clean=$cleanedTitle | right=${cleanedSubtitle.ifEmpty { cleanedTitle }} | notifId=${data.notifId}")
        } catch (e: Exception) {
            logError("$TAG: injection error: ${e.message}")
        }
    }

    // ── 文本清理 ──────────────────────────────────────────────────────────────

    private val TITLE_COUNT_BRACKET =
        Regex("""[\[【(（][^]】)）]*\d+[^]】)）]*[]】)）]\s*|\s*[\[【(（][^]】)）]*\d+[^]】)）]*[]】)）]""")

    private fun cleanTitle(title: String): String =
        title.replace(TITLE_COUNT_BRACKET, "").trim()

    private val SUBTITLE_COUNT_PREFIX =
        Regex("""^[\[【(（][^]】)）]*\d+[^]】)）]*[]】)）]\s*""")

    private fun cleanSubtitle(subtitle: String, cleanedTitle: String): String {
        var s = subtitle.replace(SUBTITLE_COUNT_PREFIX, "")
        if (cleanedTitle.isNotEmpty() && cleanedTitle.length <= 30) {
            s = s.replace(Regex("""^${Regex.escape(cleanedTitle)}\s*[:：]\s*"""), "")
        }
        return s.trim()
    }

    // ── Dispatcher 路径（focusNotif == "off"）────────────────────────────────

    private fun injectViaDispatcher(
        context: Context,
        data: NotifData,
        cleanedTitle: String,
        cleanedSubtitle: String,
    ) {
        try {
            val fallbackIcon = context.defaultDialogIcon()
            val displayIcon =
                data.resolveModeIconAutoLarge(data.iconMode, fallbackIcon).toRounded(context)

            IslandDispatcher.post(
                context,
                IslandRequest(
                    title = cleanedTitle,
                    content = cleanedSubtitle.ifEmpty { cleanedTitle },
                    icon = displayIcon,
                    timeoutSecs = data.islandTimeout,
                    firstFloat = data.firstFloat == "on",
                    enableFloat = data.enableFloatMode == "on",
                    showNotification = false,
                    preserveStatusBarSmallIcon = data.preserveStatusBarSmallIcon != "off",
                    contentIntent = data.contentIntent,
                    isOngoing = data.isOngoing,
                    actions = data.actions.take(2),
                ),
            )
            //ConfigManager.module()?.log("$TAG: dispatcher island — $cleanedTitle | iconMode=${data.iconMode}")
        } catch (e: Exception) {
            logError("$TAG: dispatcher island error: ${e.message}")
        }
    }

    // ── 消息处理 ──────────────────────────────────────────────────────────────

    fun process(
        context: Context,
        data: NotifData,
        cleanedTitle: String = cleanTitle(data.title),
        cleanedSubtitle: String = cleanSubtitle(data.subtitle, cleanedTitle),
    ): IslandViewModel {
        val fallbackIcon = context.defaultDialogIcon()

        val islandIcon =
            data.resolveModeIconAutoLarge(data.iconMode, fallbackIcon).toRounded(context)

        val focusIcon =
            data.resolveModeIconWithAppFallback(data.focusIconMode, fallbackIcon).toRounded(context)

        val showNotification = data.focusNotif != "off"
        val shouldPreserveIcon = showNotification && data.preserveStatusBarSmallIcon != "off"

        return IslandViewModel(
            templateId = TEMPLATE_ID,
            leftTitle = cleanedTitle,
            rightTitle = cleanedSubtitle.ifEmpty { cleanedTitle },
            focusTitle = cleanedTitle,
            focusContent = cleanedSubtitle.ifEmpty { cleanedTitle },
            islandIcon = islandIcon,
            focusIcon = focusIcon,
            circularProgress = null,
            showRightSide = true,
            actions = data.actions,
            updatable = data.isOngoing,
            showNotification = showNotification,
            setFocusProxy = showNotification,
            preserveStatusBarSmallIcon = shouldPreserveIcon,
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
