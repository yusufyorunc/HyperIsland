package io.github.hyperisland.xposed.hook

import android.content.Context
import android.os.Build
import io.github.hyperisland.xposed.ConfigManager
import io.github.hyperisland.xposed.log
import io.github.hyperisland.xposed.logWarn
import io.github.libxposed.api.XposedModule
import io.github.libxposed.api.XposedModuleInterface.PackageLoadedParam


object UnlockAllFocusHook {

    private const val TAG = "HyperIsland[UnlockAllFocusHook]"
    private const val SETTINGS_KEY = "pref_unlock_all_focus"
    private const val TARGET_CLASS = "miui.systemui.notification.NotificationSettingsManager"

    private fun isEnabled(): Boolean = ConfigManager.getBoolean(SETTINGS_KEY, false)

    fun init(module: XposedModule, param: PackageLoadedParam) {
        ConfigManager.init(module)
        if (!isEnabled()) {
            module.log("$TAG: disabled, skipping hook for ${param.packageName}")
            return
        }

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            module.logWarn("$TAG: skip init for ${param.packageName} because onPackageLoaded/defaultClassLoader requires API 29+")
            return
        }

        val classLoader = param.defaultClassLoader
        hookCanShowFocus(module, classLoader)
        hookCanCustomFocus(module, classLoader)
    }

    private fun hookCanShowFocus(module: XposedModule, classLoader: ClassLoader) {
        try {
            val clazz = classLoader.loadClass(TARGET_CLASS)
            val method =
                clazz.getDeclaredMethod("canShowFocus", Context::class.java, String::class.java)
            module.hook(method).intercept { chain -> true }
            module.log("$TAG: hooked canShowFocus(Context, String)")
        } catch (e: Throwable) {
            module.log("$TAG: failed to hook canShowFocus — ${e.message}")
        }
    }

    private fun hookCanCustomFocus(module: XposedModule, classLoader: ClassLoader) {
        try {
            val clazz = classLoader.loadClass(TARGET_CLASS)
            val method = clazz.getDeclaredMethod("canCustomFocus", String::class.java)
            module.hook(method).intercept { chain -> true }
            module.log("$TAG: hooked canCustomFocus(String)")
        } catch (e: Throwable) {
            module.log("$TAG: canCustomFocus not found (may be expected) — ${e.message}")
        }
    }
}
