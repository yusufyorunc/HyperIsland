package io.github.hyperisland.xposed.hook

import android.annotation.SuppressLint
import android.app.KeyguardManager
import android.app.Notification
import android.content.Context
import android.graphics.Bitmap
import android.graphics.drawable.Icon
import android.os.Build
import android.os.Bundle
import android.service.notification.StatusBarNotification
import io.github.hyperisland.utils.getAppIcon
import io.github.hyperisland.xposed.ConfigManager
import io.github.hyperisland.xposed.IslandDispatcher
import io.github.hyperisland.xposed.log
import io.github.hyperisland.xposed.logWarn
import io.github.hyperisland.xposed.template.NotifData
import io.github.hyperisland.xposed.template.NotificationIslandNotification
import io.github.hyperisland.xposed.template.TemplateRegistry
import io.github.libxposed.api.XposedModule
import io.github.libxposed.api.XposedModuleInterface.PackageLoadedParam
import java.lang.reflect.Method

/**
 * 通用通知 Hook — 在 SystemUI 进程内 Hook MiuiBaseNotifUtil.generateInnerNotifBean()。
 *
 * 调用链：
 *   onNotificationPosted(sbn)
 *     → mBgHandler.post（后台线程）
 *         → generateInnerNotifBean(sbn)   ← ★ 此处最先读取 extras，快照进 InnerNotifBean
 *         → mMainExecutor.execute
 *             → extras.putParcelable("inner_notif_bean", innerNotifBean)
 *             → NotificationHandler.onNotificationPosted（最终分发）
 *
 * 必须在 generateInnerNotifBean 之前（intercept 中先处理再 proceed）写入 island extras，
 * 否则 bean 已经用原始 extras 创建完毕，后续修改不影响岛的触发判断。
 */
object GenericProgressHook {

    private const val TAG = "HyperIsland[Generic]"

    @Volatile
    private var cachedWhitelist: Map<String, Set<String>>? = null
    private val cachedTemplates = mutableMapOf<String, String>()
    private val cachedChannelSettings = mutableMapOf<String, String>()

    @Volatile
    private var observerRegistered = false

    private val lastProgressCache = mutableMapOf<String, Int>()
    private val trackedForCancel = mutableMapOf<String, Int>()

    @Volatile
    private var activeDispatcherSourceKey: String? = null

    fun ensureObserver(module: XposedModule) {
        if (observerRegistered) return
        ConfigManager.init(module)
        ConfigManager.addChangeListener {
            clearAllCaches()
        }
        observerRegistered = true
        module.log("$TAG: ConfigManager Observer registered in SystemUI")
    }

    private fun loadChannelStringSetting(
        cacheKey: String,
        prefKey: String,
        default: String,
    ): String {
        cachedChannelSettings[cacheKey]?.let { return it }
        val value = ConfigManager.getString(prefKey, default).takeIf { it.isNotBlank() } ?: default
        cachedChannelSettings[cacheKey] = value
        return value
    }

    private fun loadBooleanSetting(cacheKey: String, prefKey: String, default: Boolean): Boolean {
        cachedChannelSettings[cacheKey]?.let { return it == "1" }
        val value = ConfigManager.getBoolean(prefKey, default)
        cachedChannelSettings[cacheKey] = if (value) "1" else "0"
        return value
    }

    private fun resolveTriOpt(channelValue: String, globalDefault: Boolean): String =
        when (channelValue) {
            "on" -> "on"
            "off" -> "off"
            else -> if (globalDefault) "on" else "off"
        }

    private fun clearAllCaches() {
        cachedWhitelist = null
        cachedTemplates.clear()
        cachedChannelSettings.clear()
    }

    fun loadChannelTemplate(pkg: String, channelId: String): String {
        val cacheKey = "$pkg/$channelId"
        cachedTemplates[cacheKey]?.let { return it }
        val key = "pref_channel_template_${pkg}_$channelId"
        val template = ConfigManager.getString(key)
            .takeIf { it.isNotBlank() } ?: NotificationIslandNotification.TEMPLATE_ID
        cachedTemplates[cacheKey] = template
        return template
    }

    private fun loadWhitelist(module: XposedModule): Map<String, Set<String>> {
        cachedWhitelist?.let { return it }
        val csv = ConfigManager.getString("pref_generic_whitelist")
        val map = csv.split(",")
            .map { it.trim() }
            .filter { it.isNotBlank() }.associateWith { pkg ->
                val channelCsv = ConfigManager.getString("pref_channels_$pkg")
                val channels = if (channelCsv.isBlank()) emptySet()
                else channelCsv.split(",").filter { it.isNotBlank() }.toSet()
                channels
            }
        if (map.isNotEmpty()) cachedWhitelist = map
        module.log("$TAG: whitelist loaded (${map.size} apps): ${map.keys}")
        return map
    }

    fun init(module: XposedModule, param: PackageLoadedParam) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            module.logWarn("$TAG: skip init for ${param.packageName} because onPackageLoaded/defaultClassLoader requires API 29+")
            return
        }

        val classLoader = param.defaultClassLoader

        // Hook generateInnerNotifBean (before)
        try {
            val clazz = classLoader.loadClass("com.miui.systemui.notification.MiuiBaseNotifUtil")
            val method =
                clazz.getDeclaredMethod("generateInnerNotifBean", StatusBarNotification::class.java)
            module.hook(method).intercept { chain ->
                val sbn = chain.args[0] as? StatusBarNotification
                if (sbn != null) handleSbn(sbn, module, classLoader)
                chain.proceed()
            }
            module.log("$TAG: hooked MiuiBaseNotifUtil.generateInnerNotifBean")
        } catch (e: Throwable) {
            module.log("$TAG: hook failed: ${e.message}")
        }

        // Hook onNotificationRemoved (after) — 优先 3 参数版本
        var cancelHooked = false
        try {
            val rankingMapClass = classLoader.loadClass(
                $$"android.service.notification.NotificationListenerService$RankingMap"
            )
            val removeMethod = findOnNotificationRemovedMethod(
                classLoader.loadClass("android.service.notification.NotificationListenerService"),
                StatusBarNotification::class.java,
                rankingMapClass,
                Int::class.javaPrimitiveType!!
            )
            module.hook(removeMethod).intercept { chain ->
                val result = chain.proceed()
                handleNotificationRemoved(
                    chain.args[0] as? StatusBarNotification,
                    classLoader
                )
                result
            }
            cancelHooked = true
            module.log("$TAG: hooked onNotificationRemoved(sbn, rankingMap, reason)")
        } catch (e: Throwable) {
            module.log("$TAG: onNotificationRemoved 3-param hook failed: ${e.message}")
        }

        if (!cancelHooked) {
            try {
                val removeMethod = findOnNotificationRemovedMethod(
                    classLoader.loadClass("android.service.notification.NotificationListenerService"),
                    StatusBarNotification::class.java
                )
                module.hook(removeMethod).intercept { chain ->
                    val result = chain.proceed()
                    handleNotificationRemoved(
                        chain.args[0] as? StatusBarNotification,
                        classLoader
                    )
                    result
                }
                module.log("$TAG: hooked onNotificationRemoved(sbn)")
            } catch (e: Throwable) {
                module.log("$TAG: onNotificationRemoved 1-param hook failed: ${e.message}")
            }
        }
    }

    private fun handleNotificationRemoved(
        sbn: StatusBarNotification?,
        classLoader: ClassLoader,
    ) {
        sbn ?: return
        val key = "${sbn.packageName}#${sbn.id}"
        lastProgressCache.remove(key)

        val wasActive = activeDispatcherSourceKey == key
        val proxyId = trackedForCancel.remove(key)
        if (!wasActive || proxyId == null) {
            if (wasActive) activeDispatcherSourceKey = null
            return
        }

        activeDispatcherSourceKey = null
        val context = getContext(classLoader) ?: return
        IslandDispatcher.cancel(context, proxyId)
    }

    private fun handleSbn(
        sbn: StatusBarNotification,
        module: XposedModule,
        classLoader: ClassLoader,
    ) {
        try {
            val pkg = sbn.packageName ?: return

            if (pkg == "com.android.systemui" &&
                sbn.notification?.channelId == IslandDispatcher.CHANNEL_ID
            ) return

            val context = getContext(classLoader) ?: return
            ensureObserver(module)

            val allowedChannels = loadWhitelist(module)[pkg] ?: return
            val notif = sbn.notification ?: return
            val channelId = notif.channelId ?: ""
            if (allowedChannels.isNotEmpty() && channelId !in allowedChannels) return

            val extras = notif.extras ?: return

            if (isMediaNotification(extras)) return

            val defaultRestoreLockscreen = loadBooleanSetting(
                "global:default_restore_lockscreen",
                "pref_default_restore_lockscreen",
                false
            )
            val restoreLockscreenRaw = loadChannelStringSetting(
                "restore_lockscreen:$pkg/$channelId",
                "pref_channel_restore_lockscreen_${pkg}_$channelId",
                "default"
            )
            val restoreLockscreen = resolveTriOpt(restoreLockscreenRaw, defaultRestoreLockscreen)
            module.log("$TAG: restoreLockscreen raw=$restoreLockscreenRaw, resolved=$restoreLockscreen, default=$defaultRestoreLockscreen")

            if (restoreLockscreen == "on" && shouldRedactPrivateContentOnLockscreen(
                    context,
                    notif,
                    module
                )
            ) {
                module.log("$TAG: skipping due to lockscreen restore")
                extras.remove("miui.focus.param")
                extras.remove("hyperisland_generic_processed")
                return
            }

            if (extras.containsKey("miui.focus.param")) return

            val progressMax = extras.getInt(Notification.EXTRA_PROGRESS_MAX, 0)
            val indeterminate = extras.getBoolean(Notification.EXTRA_PROGRESS_INDETERMINATE, false)
            val hasProgressBar = progressMax > 0 && !indeterminate

            if (hasProgressBar) {
                if (extras.getBoolean("hyperisland_processed", false)) return
                if (extras.getBoolean("hyperisland_generic_processed", false)) return
            }

            val cacheKey = "$pkg#${sbn.id}"
            val progressPercent: Int
            if (hasProgressBar) {
                val progressRaw = extras.getInt(Notification.EXTRA_PROGRESS, -1)
                if (progressRaw < 0) return
                progressPercent = (progressRaw * 100 / progressMax).coerceIn(0, 100)
                if (progressPercent in 0..99) {
                    lastProgressCache[cacheKey] = progressPercent
                } else {
                    lastProgressCache.remove(cacheKey)
                }
            } else {
                progressPercent = lastProgressCache[cacheKey] ?: -1
            }

            val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()
                ?: extras.getCharSequence(Notification.EXTRA_TITLE_BIG)?.toString()
                ?: return

            val subtitle = listOf(
                extras.getCharSequence(Notification.EXTRA_SUB_TEXT),
                extras.getCharSequence(Notification.EXTRA_TEXT),
                extras.getCharSequence(Notification.EXTRA_INFO_TEXT),
                extras.getCharSequence(Notification.EXTRA_BIG_TEXT)
            ).firstNotNullOfOrNull { it?.toString()?.takeIf { s -> s.isNotEmpty() } } ?: ""

            val actions: List<Notification.Action> = notif.actions?.take(2) ?: emptyList()

            val template = loadChannelTemplate(pkg, channelId)

            val appIconRaw = context.packageManager.getAppIcon(pkg)
            val largeIcon = extractLargeIcon(extras)

            val iconMode = loadChannelStringSetting(
                "icon:$pkg/$channelId",
                "pref_channel_icon_${pkg}_$channelId",
                "auto"
            )
            val defaultFirstFloat =
                loadBooleanSetting("global:default_first_float", "pref_default_first_float", false)
            val defaultEnableFloat = loadBooleanSetting(
                "global:default_enable_float",
                "pref_default_enable_float",
                false
            )
            val defaultFocusNotif =
                loadBooleanSetting("global:default_focus_notif", "pref_default_focus_notif", true)
            val defaultPreserveSmallIcon = loadBooleanSetting(
                "global:default_preserve_small_icon",
                "pref_default_preserve_small_icon",
                false
            )
            val defaultShowIslandIcon = loadBooleanSetting(
                "global:default_show_island_icon",
                "pref_default_show_island_icon",
                true
            )

            val focusNotif = resolveTriOpt(
                loadChannelStringSetting(
                    "focus:$pkg/$channelId",
                    "pref_channel_focus_${pkg}_$channelId",
                    "default"
                ),
                defaultFocusNotif
            )
            val preserveStatusBarSmallIcon = resolveTriOpt(
                loadChannelStringSetting(
                    "preserve_small_icon:$pkg/$channelId",
                    "pref_channel_preserve_small_icon_${pkg}_$channelId",
                    "default"
                ),
                defaultPreserveSmallIcon
            )
            val showIslandIcon = resolveTriOpt(
                loadChannelStringSetting(
                    "show_island_icon:$pkg/$channelId",
                    "pref_channel_show_island_icon_${pkg}_$channelId",
                    "default"
                ),
                defaultShowIslandIcon
            )
            val firstFloat = resolveTriOpt(
                loadChannelStringSetting(
                    "first_float:$pkg/$channelId",
                    "pref_channel_first_float_${pkg}_$channelId",
                    "default"
                ),
                defaultFirstFloat
            )
            val enableFloatMode = resolveTriOpt(
                loadChannelStringSetting(
                    "efloat:$pkg/$channelId",
                    "pref_channel_enable_float_${pkg}_$channelId",
                    "default"
                ),
                defaultEnableFloat
            )
            val islandTimeoutStr = loadChannelStringSetting(
                "timeout:$pkg/$channelId", "pref_channel_timeout_${pkg}_$channelId", "5"
            )
            val islandTimeout = islandTimeoutStr.toIntOrNull() ?: 5
            val focusIconMode = loadChannelStringSetting(
                "focus_icon:$pkg/$channelId", "pref_channel_focus_icon_${pkg}_$channelId", "auto"
            )
            val isOngoing = (notif.flags and Notification.FLAG_ONGOING_EVENT) != 0
            val renderer = loadChannelStringSetting(
                "renderer:$pkg/$channelId",
                "pref_channel_renderer_${pkg}_$channelId",
                "image_text_with_buttons_4"
            )
            val highlightColor = loadChannelStringSetting(
                "highlight_color:$pkg/$channelId",
                "pref_channel_highlight_color_${pkg}_$channelId",
                ""
            ).takeIf { it.isNotBlank() }
            val showLeftHighlight = loadChannelStringSetting(
                "show_left_highlight:$pkg/$channelId",
                "pref_channel_show_left_highlight_${pkg}_$channelId",
                "off"
            ) == "on"
            val showRightHighlight = loadChannelStringSetting(
                "show_right_highlight:$pkg/$channelId",
                "pref_channel_show_right_highlight_${pkg}_$channelId",
                "off"
            ) == "on"

            module.log(
                "$TAG: $pkg/$channelId | $title |  template=$template"
            )
//            module.log(
//                "$TAG: $pkg/$channelId | $title | $progressPercent% | template=$template | buttons=${actions.size} | largeIcon=${largeIcon != null} | preserveSmallIcon=$preserveStatusBarSmallIcon"
//            )

            TemplateRegistry.dispatch(
                templateId = template,
                context = context,
                extras = extras,
                data = NotifData(
                    pkg = pkg,
                    channelId = channelId,
                    notifId = sbn.id,
                    title = title,
                    subtitle = subtitle,
                    progress = progressPercent,
                    actions = actions,
                    notifIcon = notif.smallIcon,
                    largeIcon = largeIcon,
                    appIconRaw = appIconRaw,
                    iconMode = iconMode,
                    focusIconMode = focusIconMode,
                    focusNotif = focusNotif,
                    preserveStatusBarSmallIcon = preserveStatusBarSmallIcon,
                    showIslandIcon = showIslandIcon,
                    firstFloat = firstFloat,
                    enableFloatMode = enableFloatMode,
                    islandTimeout = islandTimeout,
                    isOngoing = isOngoing,
                    contentIntent = notif.contentIntent,
                    renderer = renderer,
                    highlightColor = highlightColor,
                    showLeftHighlightColor = showLeftHighlight,
                    showRightHighlightColor = showRightHighlight,
                ),
            )

            extras.putBoolean("hyperisland_generic_processed", true)

            val sourceKey = "$pkg#${sbn.id}"
            val dispatchedProxy = extras.getBoolean("hyperisland_dispatched_proxy", false)
            if (dispatchedProxy) {
                trackedForCancel[sourceKey] = IslandDispatcher.NOTIF_ID
                activeDispatcherSourceKey = sourceKey
            } else {
                trackedForCancel.remove(sourceKey)
                if (activeDispatcherSourceKey == sourceKey) {
                    activeDispatcherSourceKey = null
                }
            }

        } catch (e: Throwable) {
            module.log("$TAG: handleSbn error: ${e.message}")
        }
    }

    private fun shouldRedactPrivateContentOnLockscreen(
        context: Context,
        notif: Notification,
        module: XposedModule,
    ): Boolean {
        if (!isKeyguardLocked(context, module)) return false
        val vis = notif.visibility
        module.log("$TAG: notification visibility = $vis (PUBLIC=${Notification.VISIBILITY_PUBLIC}, PRIVATE=${Notification.VISIBILITY_PRIVATE}, SECRET=${Notification.VISIBILITY_SECRET})")
        return vis != Notification.VISIBILITY_PUBLIC
        // VISIBILITY_PRIVATE 或 VISIBILITY_SECRET 都应该跳过处理
    }

    private fun isKeyguardLocked(context: Context, module: XposedModule): Boolean {
        val keyguardManager = context.getSystemService(KeyguardManager::class.java) ?: return false
        val locked = keyguardManager.isKeyguardLocked
        module.log("$TAG: isKeyguardLocked = $locked")
        return locked
    }

    private fun isMediaNotification(extras: Bundle): Boolean {
        if (extras.containsKey(Notification.EXTRA_MEDIA_SESSION)) return true
        val template = extras.getString(Notification.EXTRA_TEMPLATE) ?: return false
        return template.contains("MediaStyle", ignoreCase = true)
    }

    private fun extractLargeIcon(extras: Bundle): Icon? {
        return try {
            @Suppress("DEPRECATION")
            val icon = extras.getParcelable<Icon>(
                Notification.EXTRA_LARGE_ICON
            )
            if (icon != null) return icon

            @Suppress("DEPRECATION")
            val bitmap = extras.getParcelable<Bitmap>(
                Notification.EXTRA_LARGE_ICON
            )
            if (bitmap != null) Icon.createWithBitmap(bitmap) else null
        } catch (_: Exception) {
            null
        }
    }

    @SuppressLint("PrivateApi")
    private fun getContext(classLoader: ClassLoader): Context? {
        return try {
            val at = classLoader.loadClass("android.app.ActivityThread")
            at.getMethod("currentApplication").invoke(null) as? Context
        } catch (_: Exception) {
            try {
                val at = classLoader.loadClass("android.app.ActivityThread")
                (at.getMethod("getSystemContext")
                    .invoke(null) as? Context)?.applicationContext
            } catch (_: Exception) {
                null
            }
        }
    }

    private fun findOnNotificationRemovedMethod(
        clazz: Class<*>,
        vararg paramTypes: Class<*>,
    ): Method {
        var c: Class<*>? = clazz
        while (c != null) {
            try {
                return c.getDeclaredMethod("onNotificationRemoved", *paramTypes)
            } catch (_: NoSuchMethodException) {
            }
            c = c.superclass
        }
        throw NoSuchMethodException("onNotificationRemoved not found in ${clazz.name} hierarchy")
    }
}