package io.github.hyperisland.xposed.hook

import android.app.Application
import android.app.ActivityManager
import android.content.ComponentCallbacks
import android.content.Context
import android.content.res.Configuration
import android.graphics.Rect
import android.hardware.display.DisplayManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.service.notification.StatusBarNotification
import android.view.Display
import android.view.Surface
import android.view.View
import io.github.hyperisland.xposed.ConfigManager
import io.github.hyperisland.xposed.islanddispatch.IslandDispatcher
import io.github.hyperisland.xposed.islanddispatch.definition.IslandRequest
import io.github.hyperisland.xposed.utils.HookUtils
import io.github.libxposed.api.XposedModule
import io.github.libxposed.api.XposedModuleInterface.PackageLoadedParam
import java.util.concurrent.ConcurrentHashMap

object KeepIslandHook : BaseHook() {

    private const val TAG = "HyperIsland[KeepIsland]"
    private const val PREF_KEY = "pref_keep_island"

    private const val PREF_KEY_AUTO_HIDE = "pref_keep_island_auto_hide"

    private const val PREF_KEY_HIDE_LANDSCAPE = "pref_keep_island_hide_landscape"

    private const val PREF_KEY_HIGHLIGHT_COLOR = "pref_keep_island_highlight_color"

    private const val KEEP_ISLAND_NOTIF_ID = 0x4B494B49

    private const val ANIMATION_CONTROLLER_CLASS =
        "miui.systemui.dynamicisland.anim.DynamicIslandAnimationController"
    private const val CONTENT_VIEW_CONTROLLER_CLASS =
        "miui.systemui.dynamicisland.window.content.DynamicIslandContentViewController"

    private const val KEEP_ISLAND_CHANNEL = "keep_island"

    private const val RESTORE_DELAY_MS = 150L

    private val mainHandler = Handler(Looper.getMainLooper())
    private var appContext: android.content.Context? = null
    private var posted = false

    private var cachedModule: XposedModule? = null

    private val activeRealKeys = ConcurrentHashMap.newKeySet<String>()

    private var restoreRunnable: Runnable? = null

    private var configurationCallbacksRegistered = false

    private var displayListenerRegistered = false

    private val hookedAnimationClassLoaders = ConcurrentHashMap.newKeySet<Int>()
    private val hookedContentControllerClassLoaders = ConcurrentHashMap.newKeySet<Int>()
    @Volatile
    private var contentControllerHooked = false

    override fun getTag() = TAG

    override fun onConfigChanged() {
        mainHandler.postDelayed({ evaluateKeepIsland() }, 500)
    }

    override fun onInit(module: XposedModule, param: PackageLoadedParam) {
        cachedModule = module
        log(module, "onInit pkg=${param.packageName}")
        hookApplicationOnCreate(module, param)
        hookAnimationController(module, param.defaultClassLoader)
        hookContentViewController(module, param.defaultClassLoader)
        hookDynamicClassLoaders(module)
    }

    private fun hookApplicationOnCreate(module: XposedModule, param: PackageLoadedParam) {
        try {
            val method = param.defaultClassLoader
                .loadClass("android.app.Application")
                .getDeclaredMethod("onCreate")
            module.hook(method).intercept { chain ->
                val result = chain.proceed()
                val app = chain.thisObject as? Application
                if (app != null) {
                    appContext = app.applicationContext
                    registerConfigurationCallbacks(app.applicationContext)
                    registerDisplayListener(app.applicationContext)
                    mainHandler.postDelayed({ evaluateKeepIsland() }, 3000)
                }
                result
            }
            log(module, "hooked Application.onCreate")
        } catch (e: Throwable) {
            logError(module, "Application.onCreate hook failed: ${e.message}")
        }
    }

    private fun hookDynamicClassLoaders(module: XposedModule) {
        HookUtils.hookDynamicClassLoaders(module, ClassLoader.getSystemClassLoader()) { cl ->
            hookAnimationController(module, cl)
            hookContentViewController(module, cl)
        }
    }

    private fun hookContentViewController(module: XposedModule, classLoader: ClassLoader) {
        val clId = System.identityHashCode(classLoader)
        if (!hookedContentControllerClassLoaders.add(clId)) return
        try {
            val clazz = try {
                classLoader.loadClass(CONTENT_VIEW_CONTROLLER_CLASS)
            } catch (_: ClassNotFoundException) {
                hookedContentControllerClassLoaders.remove(clId)
                return
            }
            val methods = clazz.declaredMethods.filter {
                it.name == "onPreDraw" && it.parameterCount == 0
            }
            methods.forEach { method ->
                module.hook(method).intercept { chain ->
                    val result = chain.proceed()
                    handleContentPreDraw(chain.thisObject)
                    result
                }
            }
            if (methods.isNotEmpty()) contentControllerHooked = true
            log(module, "hooked content onPreDraw (cl=$clId, methods=${methods.size})")
        } catch (e: Throwable) {
            hookedContentControllerClassLoaders.remove(clId)
            logError(module, "content onPreDraw hook failed cl=$clId: ${e.message}")
        }
    }

    private fun hookAnimationController(module: XposedModule, classLoader: ClassLoader) {
        val clId = System.identityHashCode(classLoader)
        if (!hookedAnimationClassLoaders.add(clId)) return
        try {
            val clazz = try {
                classLoader.loadClass(ANIMATION_CONTROLLER_CLASS)
            } catch (_: ClassNotFoundException) {
                hookedAnimationClassLoaders.remove(clId)
                //log(module, "animation controller not found in cl=$clId, skipped")
                return
            }
            val methods = clazz.declaredMethods.filter {
                it.name == "onStateChange" && it.parameterCount >= 1
            }
            methods.forEach { method ->
                module.hook(method).intercept { chain ->
                    val result = chain.proceed()
                    val stateObj = chain.args.getOrNull(0)
                    if (stateObj != null) {
                        handleStateChange(stateObj)
                    }
                    result
                }
            }
            log(module, "hooked onStateChange (cl=$clId, methods=${methods.size})")
        } catch (e: Throwable) {
            hookedAnimationClassLoaders.remove(clId)
            logError(module, "animation controller hook failed cl=$clId: ${e.message}")
        }
    }

    private fun handleStateChange(stateObj: Any) {
        val ctx = appContext ?: return
        val enabled = ConfigManager.getBoolean(PREF_KEY, false)
        if (!enabled) return

        val autoHide = ConfigManager.getBoolean(PREF_KEY_AUTO_HIDE, true)
        if (!autoHide) return

        val stateText = readStateText(stateObj) ?: return

        val extras = extractExtrasFromState(stateObj)
        val sourceChannel = extras?.getString("hyperisland_source_channel")
        val isOwnedByUs = sourceChannel == KEEP_ISLAND_CHANNEL

        val key = extractKeyFromState(stateObj)
        val sourcePackage = extractSourcePackageFromState(stateObj, key)

        val isBigIsland = stateText.contains("BigIsland")
        val isExpanded = stateText.contains("Expand")
        val isSmallIsland = stateText.contains("SmallIsland")
        val isDeleted = stateText.contains("Deleted")

        if (isOwnedByUs) return
        if ((isBigIsland || isExpanded || isSmallIsland) && !isDeleted && sourcePackage == foregroundPackage(ctx)) return

        when {
            (isBigIsland || isExpanded || isSmallIsland) && !isDeleted -> {
                if (contentControllerHooked) return
                cancelPendingRestore()
                if (key != null) activeRealKeys.add(key)
                if (posted) {
                    cancelKeepIsland(ctx)
                }
            }

            isDeleted || (!isBigIsland && !isExpanded && !isSmallIsland) -> {
                if (key != null) activeRealKeys.remove(key)
                if (!posted) {
                    scheduleRestore()
                }
            }
        }
    }

    private fun handleContentPreDraw(controllerObj: Any) {
        val ctx = appContext ?: return
        val enabled = ConfigManager.getBoolean(PREF_KEY, false)
        if (!enabled) return

        val autoHide = ConfigManager.getBoolean(PREF_KEY_AUTO_HIDE, true)
        if (!autoHide) return

        val view = invokeNoArg(controllerObj, "getView") as? View ?: return
        val stateText = invokeNoArg(view, "getState")?.toString().orEmpty()
        val isBigIsland = stateText.contains("BigIsland")
        val isExpanded = stateText.contains("Expand")
        val isSmallIsland = stateText.contains("SmallIsland")
        val isDeleted = stateText.contains("Deleted")
        val sbn = extractSbnFromController(controllerObj)
        val key = (invokeNoArg(controllerObj, "getIslandKey") as? String)
            ?: extractKeyFromState(view)
            ?: sbn?.key
            ?: return

        if (isDeleted || (!isBigIsland && !isExpanded && !isSmallIsland)) {
            removeActiveRealKey(ctx, key)
            return
        }

        val extras = sbn?.notification?.extras ?: extractExtrasFromState(view)
        val isOwnedByUs = extras?.getString("hyperisland_source_channel") == KEEP_ISLAND_CHANNEL
        if (isOwnedByUs || !isContentViewVisible(controllerObj, view)) {
            removeActiveRealKey(ctx, key)
            return
        }

        cancelPendingRestore()
        activeRealKeys.add(key)
        if (posted) {
            cancelKeepIsland(ctx)
        }
    }

    private fun removeActiveRealKey(ctx: Context, key: String) {
        activeRealKeys.remove(key)
        if (!posted) {
            scheduleRestore()
        }
    }

    private fun isContentViewVisible(controllerObj: Any, view: View): Boolean {
        val currentIslandVisible = invokeNoArg(controllerObj, "currentIslandVisible") as? Boolean ?: false
        if (!currentIslandVisible || !view.isShown) return false
        val rect = Rect()
        return view.getGlobalVisibleRect(rect) && rect.width() > 0 && rect.height() > 0
    }

    private fun extractSbnFromController(controllerObj: Any): StatusBarNotification? {
        return invokeNoArg(controllerObj, "getIslandSbn") as? StatusBarNotification
    }

    private fun evaluateKeepIsland() {
        val ctx = appContext ?: return
        val enabled = ConfigManager.getBoolean(PREF_KEY, false)
        val autoHide = ConfigManager.getBoolean(PREF_KEY_AUTO_HIDE, true)
        if (!enabled || !autoHide) activeRealKeys.clear()
        if (shouldShowKeepIsland(ctx)) {
            cancelPendingRestore()
            if (!posted) postKeepIsland(ctx, restore = true)
        } else {
            cancelPendingRestore()
            if (posted) cancelKeepIsland(ctx)
        }
    }

    private fun shouldShowKeepIsland(context: Context): Boolean {
        if (!ConfigManager.getBoolean(PREF_KEY, false)) return false
        val hideForRealNotification = ConfigManager.getBoolean(PREF_KEY_AUTO_HIDE, true) &&
            activeRealKeys.isNotEmpty()
        if (hideForRealNotification) return false
        val hideForLandscape = ConfigManager.getBoolean(PREF_KEY_HIDE_LANDSCAPE, false) &&
            isLandscape(context)
        return !hideForLandscape
    }

    private fun postKeepIsland(context: android.content.Context, restore: Boolean) {
        try {
            val highlightColor = ConfigManager.getString(PREF_KEY_HIGHLIGHT_COLOR, "")
                .takeIf { it.isNotBlank() }
            val request = IslandRequest(
                title = " ",
                content = "",
                icon = null,
                notifId = KEEP_ISLAND_NOTIF_ID,
                timeoutSecs = Int.MAX_VALUE,
                firstFloat = false,
                enableFloat = false,
                showNotification = false,
                preserveStatusBarSmallIcon = false,
                isOngoing = true,
                showIslandIcon = false,
                clearBeforePost = true,
                sourcePackage = "io.github.hyperisland",
                sourceChannelId = KEEP_ISLAND_CHANNEL,
                highlightColor = highlightColor,
                showLeftHighlightColor = highlightColor != null,
                showRightHighlightColor = highlightColor != null,
                islandOnly = true,
            )
            IslandDispatcher.post(context, request)
            posted = true
            cachedModule?.let { log(it, "keep island ${if (restore) "restored" else "posted"}") }
        } catch (e: Exception) {
            cachedModule?.let { logError(it, "keep island post failed: ${e.message}") }
        }
    }

    private fun cancelKeepIsland(context: android.content.Context) {
        try {
            IslandDispatcher.cancel(context, KEEP_ISLAND_NOTIF_ID)
            posted = false
            cachedModule?.let { log(it, "keep island cancelled") }
        } catch (e: Exception) {
            cachedModule?.let { logError(it, "keep island cancel failed: ${e.message}") }
        }
    }

    private fun scheduleRestore() {
        cancelPendingRestore()
        restoreRunnable = Runnable {
            evaluateKeepIsland()
        }
        mainHandler.postDelayed(restoreRunnable!!, RESTORE_DELAY_MS)
    }

    private fun cancelPendingRestore() {
        restoreRunnable?.let { mainHandler.removeCallbacks(it) }
        restoreRunnable = null
    }

    private fun registerConfigurationCallbacks(context: Context) {
        if (configurationCallbacksRegistered) return
        configurationCallbacksRegistered = true
        context.registerComponentCallbacks(object : ComponentCallbacks {
            override fun onConfigurationChanged(newConfig: Configuration) {
                mainHandler.post { evaluateKeepIsland() }
            }

            @Suppress("OVERRIDE_DEPRECATION")
            override fun onLowMemory() = Unit
        })
    }

    private fun registerDisplayListener(context: Context) {
        if (displayListenerRegistered) return
        val displayManager = context.getSystemService(DisplayManager::class.java) ?: return
        displayListenerRegistered = true
        displayManager.registerDisplayListener(
            object : DisplayManager.DisplayListener {
                override fun onDisplayAdded(displayId: Int) = Unit

                override fun onDisplayRemoved(displayId: Int) = Unit


                override fun onDisplayChanged(displayId: Int) {
                    mainHandler.post { evaluateKeepIsland() }
                }
            },
            mainHandler,
        )
    }

    private fun isLandscape(context: Context): Boolean {
        if (context.resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE) {
            return true
        }
        val rotation = runCatching {
            context.getSystemService(DisplayManager::class.java)
                ?.getDisplay(Display.DEFAULT_DISPLAY)
                ?.rotation
        }.getOrNull()
        return rotation == Surface.ROTATION_90 || rotation == Surface.ROTATION_270
    }

    private fun extractKeyFromState(stateObj: Any): String? {
        val dataObj = extractDynamicData(stateObj)
        if (dataObj != null) {
            invokeNoArg(dataObj, "getKey")?.let { return it as? String }
        }
        val extras = extractExtrasFromState(stateObj)
        extras?.getString("key")?.let { return it }
        extras?.getString("miui.notif.key")?.let { return it }
        return null
    }

    private fun extractSourcePackageFromState(stateObj: Any, key: String?): String? {
        val extras = extractExtrasFromState(stateObj)
        extras?.getString("hyperisland_source_pkg")?.let { return it }
        extras?.getString("android.packageName")?.let { return it }
        extras?.getString("packageName")?.let { return it }
        return key?.split('|')?.getOrNull(1)?.takeIf { it.contains('.') }
    }

    private fun foregroundPackage(context: Context): String {
        return runCatching {
            val am = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            @Suppress("DEPRECATION")
            am.getRunningTasks(1).firstOrNull()?.topActivity?.packageName.orEmpty()
        }.getOrDefault("")
    }

    private fun readStateText(stateObj: Any?): String? {
        return invokeNoArg(stateObj ?: return null, "getState")?.toString()
    }

    private fun extractExtrasFromState(stateObj: Any): Bundle? {
        val dataObj = extractDynamicData(stateObj)
        if (dataObj == null) {
            invokeNoArg(stateObj, "getExtras")?.let { if (it is Bundle) return it }
            readFieldValue(stateObj, "extras")?.let { if (it is Bundle) return it }
            readFieldValue(stateObj, "mExtras")?.let { if (it is Bundle) return it }
            return null
        }
        invokeNoArg(dataObj, "getExtras")?.let { if (it is Bundle) return it }
        readFieldValue(dataObj, "extras")?.let { if (it is Bundle) return it }
        readFieldValue(dataObj, "mExtras")?.let { if (it is Bundle) return it }
        return null
    }

    private fun extractDynamicData(stateObj: Any): Any? {
        listOf("getCurrentIslandData", "getIslandData", "getData").forEach { name ->
            invokeNoArg(stateObj, name)?.let { return it }
        }
        return null
    }

    private fun invokeNoArg(target: Any, methodName: String): Any? {
        return runCatching {
            val method = findNoArgMethod(target.javaClass, methodName) ?: return null
            method.isAccessible = true
            method.invoke(target)
        }.getOrNull()
    }

    private fun findNoArgMethod(clazz: Class<*>, name: String): java.lang.reflect.Method? {
        var current: Class<*>? = clazz
        while (current != null) {
            current.declaredMethods.firstOrNull { it.name == name && it.parameterCount == 0 }
                ?.let { return it }
            current = current.superclass
        }
        return null
    }

    private fun readFieldValue(instance: Any, fieldName: String): Any? {
        var current: Class<*>? = instance.javaClass
        while (current != null) {
            try {
                val field = current.getDeclaredField(fieldName)
                field.isAccessible = true
                return field.get(instance)
            } catch (_: NoSuchFieldException) {
                current = current.superclass
            }
        }
        return null
    }
}
