package io.github.hyperisland.xposed.template

import android.content.Context
import android.os.Bundle
import io.github.hyperisland.xposed.IslandDispatcher
import io.github.hyperisland.xposed.IslandRequest
import io.github.hyperisland.xposed.logError
import io.github.hyperisland.xposed.template.renderer.resolveRenderer

object NotificationIslandNotification : IslandTemplate {

    private const val TAG = "HyperIsland[NotifIsland]"
    const val TEMPLATE_ID = "notification_island"

    override val id = TEMPLATE_ID

    override fun inject(context: Context, extras: Bundle, data: NotifData) {
        extras.remove("hyperisland_dispatched_proxy")
        if (data.focusNotif == "off") {
            injectViaDispatcher(context, data)
            extras.putBoolean("hyperisland_dispatched_proxy", true)
            return
        }
        try {
            val vm = process(context, data)
            resolveRenderer(data.renderer).render(context, extras, vm)
            extras.putBoolean("hyperisland_dispatched_proxy", false)
        } catch (e: Exception) {
            logError("$TAG: injection error: ${e.message}")
        }
    }

    private fun injectViaDispatcher(context: Context, data: NotifData) {
        try {
            val fallbackIcon = context.defaultDialogIcon()
            val displayIcon =
                data.resolveModeIconAutoLarge(data.iconMode, fallbackIcon).toRounded(context)

            IslandDispatcher.post(
                context,
                IslandRequest(
                    title = data.title,
                    content = data.subtitle.ifEmpty { data.title },
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
        } catch (e: Exception) {
            logError("$TAG: dispatcher island error: ${e.message}")
        }
    }


    fun process(context: Context, data: NotifData): IslandViewModel {
        val fallbackIcon = context.defaultDialogIcon()

        val islandIcon =
            data.resolveModeIconAutoLarge(data.iconMode, fallbackIcon).toRounded(context)

        val focusIcon =
            data.resolveModeIconWithAppFallback(data.focusIconMode, fallbackIcon).toRounded(context)

        val showNotification = data.focusNotif != "off"
        val shouldPreserveIcon = showNotification && data.preserveStatusBarSmallIcon != "off"

        return IslandViewModel(
            templateId = TEMPLATE_ID,
            leftTitle = data.title,
            rightTitle = data.subtitle.ifEmpty { data.title },
            focusTitle = data.title,
            focusContent = data.subtitle.ifEmpty { data.title },
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
            outerGlow = data.outerGlow,
        )
    }
}
