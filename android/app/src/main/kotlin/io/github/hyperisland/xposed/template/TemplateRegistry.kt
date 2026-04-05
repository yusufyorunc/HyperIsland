package io.github.hyperisland.xposed.template

import android.content.Context
import android.os.Bundle
import io.github.hyperisland.xposed.logWarn


object TemplateRegistry {

    private const val TAG = "HyperIsland[TemplateRegistry]"

    private val registry: Map<String, IslandTemplate> = listOf(
        GenericDownloadIslandNotification,
        NotificationIslandNotification,
        NotificationIslandLiteNotification,
        DownloadLiteIslandNotification,
        AINotificationIslandNotification,
    ).associateBy { it.id }

    fun dispatch(
        templateId: String,
        context: Context,
        extras: Bundle,
        data: NotifData,
    ) {
        val template = registry[templateId]
        if (template == null) {
            logWarn("$TAG: unknown template '$templateId', skipped")
            return
        }
        // 通知进入黑名单处理
        val filteredData = BlacklistFilter.applyTo(context, data)
        template.inject(context, extras, filteredData)
    }
}
