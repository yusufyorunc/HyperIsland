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
import io.github.hyperisland.utils.resolveDynamicHighlightColor
import io.github.hyperisland.xposed.ConfigManager
import io.github.hyperisland.xposed.IslandDispatcher
import io.github.hyperisland.xposed.log
import io.github.hyperisland.xposed.logWarn
import io.github.hyperisland.xposed.template.NotifData
import io.github.hyperisland.xposed.template.NotificationIslandNotification
import io.github.hyperisland.xposed.template.TemplateRegistry
import io.github.hyperisland.xposed.template.toRounded
import io.github.libxposed.api.XposedModule
import io.github.libxposed.api.XposedModuleInterface.PackageLoadedParam
import java.lang.reflect.Method
import java.util.Locale
import java.util.concurrent.ConcurrentHashMap

object GenericProgressHook {

    private const val TAG = "HyperIsland[Generic]"

    @Volatile
    private var cachedWhitelist: Map<String, Set<String>>? = null
    private val cachedTemplates = ConcurrentHashMap<String, String>()
    private val cachedChannelSettings = ConcurrentHashMap<String, String>()
    private val cachedAppIcons = ConcurrentHashMap<String, Icon>()

    @Volatile
    private var observerRegistered = false

    private val lastProgressCache = ConcurrentHashMap<String, Int>()
    private val trackedForCancel = ConcurrentHashMap<String, Int>()

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
        cachedAppIcons.clear()
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
        cachedWhitelist = map
        module.log("$TAG: whitelist loaded (${map.size} apps): ${map.keys}")
        return map
    }

    fun init(module: XposedModule, param: PackageLoadedParam) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            module.logWarn("$TAG: skip init for ${param.packageName} because onPackageLoaded/defaultClassLoader requires API 29+")
            return
        }

        val classLoader = param.defaultClassLoader

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

            val subtitle = extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString()
                ?.takeIf { it.isNotEmpty() }
                ?: extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()
                    ?.takeIf { it.isNotEmpty() }
                ?: extras.getCharSequence(Notification.EXTRA_INFO_TEXT)?.toString()
                    ?.takeIf { it.isNotEmpty() }
                ?: extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()
                    ?.takeIf { it.isNotEmpty() }
                ?: ""

            val actionsArray = notif.actions
            val actions: List<Notification.Action> = actionsArray?.asList() ?: emptyList()

            val template = loadChannelTemplate(pkg, channelId)

            val appIconRaw = getCachedAppIcon(context, pkg)
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
            val defaultDynamicHighlightColor = loadBooleanSetting(
                "global:default_dynamic_highlight_color",
                "pref_default_dynamic_highlight_color",
                false
            )
            val defaultOuterGlow = loadBooleanSetting(
                "global:default_outer_glow",
                "pref_default_outer_glow",
                false
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
            val dynamicHighlightColorChannel = loadChannelStringSetting(
                "dynamic_highlight_color:$pkg/$channelId",
                "pref_channel_dynamic_highlight_color_${pkg}_$channelId",
                "default"
            )
            val dynamicHighlightColorKey =
                dynamicHighlightColorChannel.lowercase(Locale.ROOT)
            val dynamicHighlightColorMode = when (dynamicHighlightColorKey) {
                "default" -> if (defaultDynamicHighlightColor) "on" else "off"
                else -> dynamicHighlightColorKey
            }
            val resolvedHighlightColor = resolveHighlightColor(
                context = context,
                iconMode = iconMode,
                notifIcon = notif.smallIcon,
                largeIcon = largeIcon,
                appIconRaw = appIconRaw,
                manualHighlightColor = highlightColor,
                dynamicMode = dynamicHighlightColorMode,
            )
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
            val outerGlowRaw = loadChannelStringSetting(
                "outer_glow:$pkg/$channelId",
                "pref_channel_outer_glow_${pkg}_$channelId",
                "default"
            )
            val outerGlow = resolveTriOpt(outerGlowRaw, defaultOuterGlow) == "on"

            module.log(
                "$TAG: $pkg/$channelId | $title |  template=$template"
            )
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
                    highlightColor = resolvedHighlightColor,
                    showLeftHighlightColor = showLeftHighlight,
                    showRightHighlightColor = showRightHighlight,
                    outerGlow = outerGlow,
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

    private fun resolveHighlightColor(
        context: Context,
        iconMode: String,
        notifIcon: Icon?,
        largeIcon: Icon?,
        appIconRaw: Icon?,
        manualHighlightColor: String?,
        dynamicMode: String,
    ): String? {
        val mode = dynamicMode.trim().lowercase(Locale.ROOT)
        if (mode != "on" && mode != "dark" && mode != "darker") {
            return manualHighlightColor
        }

        val fallback = Icon.createWithResource(context, android.R.drawable.ic_dialog_info)
        val iconForColor = when (iconMode) {
            "notif_small" -> notifIcon ?: fallback
            "notif_large" -> largeIcon ?: notifIcon ?: fallback
            "app_icon" -> appIconRaw ?: fallback
            else -> largeIcon ?: notifIcon ?: fallback
        }.toRounded(context)

        return iconForColor.resolveDynamicHighlightColor(context, mode) ?: manualHighlightColor
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
            val icon = if (Build.VERSION.SDK_INT >= 33) {
                extras.getParcelable(Notification.EXTRA_LARGE_ICON, Icon::class.java)
            } else {
                @Suppress("DEPRECATION")
                extras.getParcelable(Notification.EXTRA_LARGE_ICON)
            }
            if (icon != null) return icon

            val bitmap = if (Build.VERSION.SDK_INT >= 33) {
                extras.getParcelable(Notification.EXTRA_LARGE_ICON, Bitmap::class.java)
            } else {
                @Suppress("DEPRECATION")
                extras.getParcelable(Notification.EXTRA_LARGE_ICON)
            }
            if (bitmap != null) Icon.createWithBitmap(bitmap) else null
        } catch (_: Exception) {
            null
        }
    }

    private fun getCachedAppIcon(context: Context, pkg: String): Icon? {
        cachedAppIcons[pkg]?.let { return it }
        val resolved = context.packageManager.getAppIcon(pkg) ?: return null
        return cachedAppIcons.putIfAbsent(pkg, resolved) ?: resolved
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