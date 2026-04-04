package io.github.hyperisland.xposed.templates

import android.app.Notification
import android.content.Context
import android.graphics.drawable.Icon
import io.github.hyperisland.R
import io.github.hyperisland.xposed.InProcessController
import io.github.hyperisland.xposed.log
import io.github.hyperisland.xposed.logError
import io.github.hyperisland.xposed.moduleContext

object DownloadIslandNotification {

    private const val TAG = "HyperIsland[Download]"

    fun inject(
        context: Context,
        notif: Notification,
        downloadId: Long,
        isMultiFile: Boolean,
        isComplete: Boolean,
        isWaiting: Boolean,
        isPaused: Boolean = false,
    ) {
        try {
            if (isComplete || isWaiting) {
                notif.actions = emptyArray()
                return
            }

            val primaryIntent = when {
                isPaused && isMultiFile -> InProcessController.resumeAllIntent(context)
                isPaused               -> InProcessController.resumeIntent(context, downloadId)
                isMultiFile            -> InProcessController.pauseAllIntent(context)
                else                   -> InProcessController.pauseIntent(context, downloadId)
            }
            val cancelIntent = if (isMultiFile) InProcessController.cancelAllIntent(context)
                               else             InProcessController.cancelIntent(context, downloadId)
            val mc = context.moduleContext()

            val primaryLabel = when {
                isPaused && isMultiFile -> mc.getString(R.string.island_action_resume_all)
                isPaused               -> mc.getString(R.string.island_action_resume)
                isMultiFile            -> mc.getString(R.string.island_action_pause_all)
                else                   -> mc.getString(R.string.island_action_pause)
            }
            val cancelLabel = if (isMultiFile) {
                mc.getString(R.string.island_action_cancel_all)
            } else {
                mc.getString(R.string.island_action_cancel)
            }

            notif.actions = arrayOf(
                Notification.Action.Builder(
                    Icon.createWithResource(context, android.R.drawable.ic_media_pause),
                    primaryLabel, primaryIntent
                ).build(),
                Notification.Action.Builder(
                    Icon.createWithResource(context, android.R.drawable.ic_delete),
                    cancelLabel, cancelIntent
                ).build()
            )

            log("$TAG: injected buttons — $primaryLabel / $cancelLabel")
        } catch (e: Exception) {
            logError("$TAG: inject error: ${e.message}")
        }
    }
}
