package io.github.hyperisland.xposed

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.drawable.Icon
import android.os.Build
import io.github.d4viddf.hyperisland_kit.HyperAction
import io.github.d4viddf.hyperisland_kit.HyperIslandNotification
import io.github.d4viddf.hyperisland_kit.HyperPicture
import io.github.d4viddf.hyperisland_kit.models.ImageTextInfoLeft
import io.github.d4viddf.hyperisland_kit.models.ImageTextInfoRight
import io.github.d4viddf.hyperisland_kit.models.PicInfo
import io.github.d4viddf.hyperisland_kit.models.TextInfo
import io.github.hyperisland.utils.getAppIcon
import io.github.hyperisland.xposed.hook.FocusNotifStatusBarIconHook
import io.github.hyperisland.xposed.template.renderer.fixTextButtonJson
import io.github.hyperisland.xposed.template.renderer.flattenActionsToExtras
import io.github.hyperisland.xposed.template.renderer.injectIslandAppearance
import io.github.hyperisland.xposed.template.toRounded
import io.github.libxposed.api.XposedModule

object IslandDispatcher {

    const val ACTION = "io.github.hyperisland.ACTION_SHOW_ISLAND"

    const val ACTION_CANCEL = "io.github.hyperisland.ACTION_CANCEL_ISLAND"

    const val EXTRA_NOTIF_ID = "notif_id"

    const val PERM = "io.github.hyperisland.SEND_ISLAND"

    const val NOTIF_ID = 0x48594944

    const val CHANNEL_ID = "hyperisland_dispatcher"
    private const val CHANNEL_NAME = "HyperIsland 超级岛"
    private const val TAG = "HyperIsland[Dispatcher]"

    @Volatile
    private var registered = false

    @Volatile
    private var module: XposedModule? = null

    private val postedIds = androidx.collection.ArraySet<Int>()


    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val appCtx = context.applicationContext ?: context
            when (intent.action) {
                ACTION -> {
                    try {
                        val request = IslandRequest.fromIntent(intent)
                        module?.log("$TAG: onReceive title=${request.title}")
                        post(appCtx, request)
                    } catch (e: Exception) {
                        module?.logError("$TAG: onReceive error: ${e.message}")
                    }
                }

                ACTION_CANCEL -> {
                    try {
                        val notifId = intent.getIntExtra(EXTRA_NOTIF_ID, NOTIF_ID)
                        cancel(appCtx, notifId)
                    } catch (e: Exception) {
                        module?.logError("$TAG: onReceive cancel error: ${e.message}")
                    }
                }
            }
        }
    }

    fun register(context: Context, xposedModule: XposedModule) {
        if (registered) return
        module = xposedModule
        val appCtx = context.applicationContext ?: context
        createChannel(appCtx)

        val filter = IntentFilter(ACTION).apply { addAction(ACTION_CANCEL) }
        if (Build.VERSION.SDK_INT >= 33) {
            appCtx.registerReceiver(receiver, filter, PERM, null, Context.RECEIVER_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            appCtx.registerReceiver(receiver, filter, PERM, null)
        }
        registered = true
        xposedModule.log("$TAG: registered in pid=${android.os.Process.myPid()}")
    }


    fun post(context: Context, request: IslandRequest) {
        try {
            val nm = context.getSystemService(NotificationManager::class.java) ?: return
            createChannel(context)

            val appIcon = resolveIcon(request.icon, context)

            val islandBuilder = HyperIslandNotification.Builder(
                context, "hyper_island_dispatch", request.title
            )

            islandBuilder.addPicture(HyperPicture("key_island_icon", appIcon))
            islandBuilder.addPicture(HyperPicture("key_focus_icon", appIcon))

            islandBuilder.setIconTextInfo(
                picKey = "key_focus_icon",
                title = request.title,
                content = request.content,
            )
            islandBuilder.setIslandFirstFloat(request.firstFloat)
            islandBuilder.setEnableFloat(request.enableFloat)
            islandBuilder.setShowNotification(request.showNotification)
            islandBuilder.setIslandConfig(timeout = request.timeoutSecs)
            islandBuilder.setSmallIsland("key_island_icon")
            islandBuilder.setBigIslandInfo(
                left = ImageTextInfoLeft(
                    type = 1,
                    picInfo = PicInfo(type = 1, pic = "key_island_icon"),
                    textInfo = TextInfo(title = request.title),
                ),
                right = ImageTextInfoRight(
                    type = 2,
                    textInfo = TextInfo(title = request.content, narrowFont = true),
                ),
            )

            val effectiveActions = request.actions.take(2)
            if (effectiveActions.isNotEmpty()) {
                val hyperActions = effectiveActions.mapIndexed { index, action ->
                    HyperAction(
                        key = "action_dispatcher_$index",
                        title = action.title?.toString() ?: "",
                        pendingIntent = action.actionIntent,
                        actionIntentType = 2,
                    )
                }
                hyperActions.forEach { islandBuilder.addHiddenAction(it) }
                islandBuilder.setTextButtons(*hyperActions.toTypedArray())
            }

            val resourceBundle = islandBuilder.buildResourceBundle()

            val publicVersion = Notification.Builder(context, CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentTitle(CHANNEL_NAME)
                .setContentText("")
                .setVisibility(Notification.VISIBILITY_PUBLIC)
                .build()

            val visibility = if (request.showNotification) {
                Notification.VISIBILITY_PRIVATE
            } else {
                Notification.VISIBILITY_SECRET
            }

            val notif = Notification.Builder(context, CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentTitle(request.title)
                .setContentText(request.content)
                .setVisibility(visibility)
                .setPublicVersion(publicVersion)
                .setAutoCancel(true)
                .apply {
                    if (request.isOngoing) setOngoing(true)
                    request.contentIntent?.let { setContentIntent(it) }
                }
                .build()

            notif.extras.putAll(resourceBundle)
            flattenActionsToExtras(resourceBundle, notif.extras)

            val jsonParam = injectIslandAppearance(
                fixTextButtonJson(islandBuilder.buildJsonParam()),
                request.highlightColor,
                request.dismissIsland,
            )
            notif.extras.putString("miui.focus.param", jsonParam)
            if (request.showNotification) {
                notif.extras.putBoolean("hyperisland_focus_proxy", true)
            }
            val shouldPreserveStatusBarSmallIcon =
                request.showNotification && request.preserveStatusBarSmallIcon
            if (shouldPreserveStatusBarSmallIcon) {
                notif.extras.putBoolean("hyperisland_preserve_status_bar_small_icon", true)
                FocusNotifStatusBarIconHook.markDirectProxyPosted(request.timeoutSecs)
            }
            module?.log("$TAG: preserve marker=$shouldPreserveStatusBarSmallIcon title=${request.title} | notifId=${request.notifId} | showNotification=${request.showNotification}")

            val isFirstPost = !postedIds.contains(request.notifId)
            if (isFirstPost) {
                nm.cancel(request.notifId)
                nm.notify(request.notifId, notif)
                if (postedIds.size > 64) postedIds.clear()
                postedIds.add(request.notifId)
            } else {
                nm.notify(request.notifId, notif)
            }

            module?.log("$TAG: posted(first=$isFirstPost): ${request.title} | ${request.content} | highlight=${request.highlightColor} | dismiss=${request.dismissIsland}")
        } catch (e: Exception) {
            module?.logError("$TAG: post error: ${e.message}")
        }
    }

    fun sendBroadcast(context: Context, request: IslandRequest) {
        val intent = Intent(ACTION).apply {
            putExtras(request.toBundle())
        }
        context.sendBroadcast(intent, PERM)
    }

    fun cancel(context: Context, notifId: Int) {
        try {
            val nm = context.getSystemService(NotificationManager::class.java) ?: return
            nm.cancel(notifId)
            postedIds.remove(notifId)
            module?.log("$TAG: cancel notifId=$notifId")
        } catch (e: Exception) {
            module?.logError("$TAG: cancel error: ${e.message}")
        }
    }

    private fun resolveIcon(icon: Icon?, context: Context): Icon {
        if (icon != null) return icon
        return try {
            context.packageManager.getAppIcon("io.github.hyperisland")
                ?.toRounded(context)
                ?: fallbackIcon(context)
        } catch (_: Exception) {
            fallbackIcon(context)
        }
    }

    private fun fallbackIcon(context: Context): Icon =
        Icon.createWithResource(context, android.R.drawable.sym_def_app_icon)

    private fun createChannel(context: Context) {
        val nm = context.getSystemService(NotificationManager::class.java) ?: return
        val existing = nm.getNotificationChannel(CHANNEL_ID)
        if (existing != null) {
            existing.setShowBadge(false)
            existing.lockscreenVisibility = Notification.VISIBILITY_PRIVATE
            nm.createNotificationChannel(existing)
            return
        }

        nm.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                setShowBadge(false)
                lockscreenVisibility = Notification.VISIBILITY_PRIVATE
            }
        )
    }
}
