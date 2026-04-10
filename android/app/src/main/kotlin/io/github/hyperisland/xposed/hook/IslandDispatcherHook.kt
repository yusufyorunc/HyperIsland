package io.github.hyperisland.xposed.hook

import android.app.Application
import android.os.Build
import io.github.hyperisland.xposed.ConfigManager
import io.github.hyperisland.xposed.IslandDispatcher
import io.github.hyperisland.xposed.log
import io.github.hyperisland.xposed.logError
import io.github.hyperisland.xposed.logWarn
import io.github.libxposed.api.XposedModule
import io.github.libxposed.api.XposedModuleInterface.PackageLoadedParam

object IslandDispatcherHook {

    private const val TAG = "HyperIsland[DispatcherHook]"

    fun init(module: XposedModule, param: PackageLoadedParam) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            module.logWarn("$TAG: skip init for ${param.packageName} because onPackageLoaded/defaultClassLoader requires API 29+")
            return
        }

        try {
            val method = param.defaultClassLoader
                .loadClass("android.app.Application")
                .getDeclaredMethod("onCreate")
            module.hook(method).intercept { chain ->
                val result = chain.proceed()
                val app = chain.thisObject as? Application
                if (app != null) {
                    IslandDispatcher.register(app, module)
                    ConfigManager.init(module)
                }
                result
            }
            module.log("$TAG: hooked Application.onCreate in SystemUI")
        } catch (e: Throwable) {
            module.logError("$TAG: hook failed: ${e.message}")
        }
    }
}
