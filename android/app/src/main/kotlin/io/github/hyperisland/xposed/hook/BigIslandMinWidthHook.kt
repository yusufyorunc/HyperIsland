package io.github.hyperisland.xposed.hook

import io.github.hyperisland.xposed.ConfigManager
import io.github.hyperisland.xposed.log
import io.github.libxposed.api.XposedModuleInterface.PackageLoadedParam
import io.github.libxposed.api.XposedModule

object BigIslandMinWidthHook {

    private const val TAG = "HyperIsland[BigIslandWidthHook]"
    private const val DEFAULT_MAX_WIDTH_DP = 600

    @Volatile private var observerRegistered = false

    fun ensureObserver(module: XposedModule) {
        if (observerRegistered) return
        ConfigManager.init(module)
        ConfigManager.addChangeListener {
            module.log("$TAG: settings changed via Observer, cache cleared")
        }
        observerRegistered = true
        module.log("$TAG: ConfigManager Observer registered")
    }

    private var hookedCalculateMaxWidthWithSmall = false
    private var hookedSetMaxWidth = false

    fun init(module: XposedModule, param: PackageLoadedParam) {
        module.log("$TAG: initializing for ${param.packageName}")
        hookContentViewClasses(module, param.defaultClassLoader)
        hookDynamicClassLoaders(module)
    }

    private fun hookContentViewClasses(module: XposedModule, classLoader: ClassLoader) {
        if (hookedCalculateMaxWidthWithSmall && hookedSetMaxWidth) return
        val className = "miui.systemui.dynamicisland.window.content.DynamicIslandBaseContentView"
        try {
            val clazz = classLoader.loadClass(className)
            
            // Hook calculateMaxWidthWithSmall - 控制有小岛时的大岛最大宽度
            if (!hookedCalculateMaxWidthWithSmall) {
                val calculateMaxWidthWithSmallMethod = clazz.declaredMethods.firstOrNull { 
                    it.name == "calculateMaxWidthWithSmall" 
                }
                if (calculateMaxWidthWithSmallMethod != null) {
                    module.hook(calculateMaxWidthWithSmallMethod).intercept { chain ->
                        ensureObserver(module)
                        
                        val enabled = ConfigManager.getBoolean("pref_big_island_max_width_enabled", false)
                        if (!enabled) {
                            return@intercept chain.proceed()
                        }
                        
                        val maxWidthDp = ConfigManager.getInt("pref_big_island_max_width", DEFAULT_MAX_WIDTH_DP).coerceIn(500, 1000)
                        val maxWidthPx = maxWidthDp.toFloat()
                        
                        module.log("$TAG: calculateMaxWidthWithSmall returning $maxWidthPx")
                        
                        return@intercept maxWidthPx
                    }
                    hookedCalculateMaxWidthWithSmall = true
                    module.log("$TAG: hooked calculateMaxWidthWithSmall on $className")
                }
            }
            
            // Hook setMaxWidth - 控制无小岛时的大岛最大宽度
            if (!hookedSetMaxWidth) {
                val setMaxWidthMethod = clazz.declaredMethods.firstOrNull { it.name == "setMaxWidth" }
                if (setMaxWidthMethod != null) {
                    module.hook(setMaxWidthMethod).intercept { chain ->
                        ensureObserver(module)
                        
                        val enabled = ConfigManager.getBoolean("pref_big_island_max_width_enabled", false)
                        if (!enabled) {
                            return@intercept chain.proceed()
                        }
                        
                        val maxWidthDp = ConfigManager.getInt("pref_big_island_max_width", DEFAULT_MAX_WIDTH_DP).coerceIn(500, 1000)
                        val view = chain.thisObject as? android.view.View
                        val maxWidthPx = maxWidthDp.toFloat()
                        
                        val maxWidthField = clazz.getDeclaredField("maxWidth")
                        maxWidthField.isAccessible = true
                        maxWidthField.setFloat(view, maxWidthPx)
                        
                        module.log("$TAG: maxWidth=$maxWidthPx px")
                        
                        return@intercept null
                    }
                    hookedSetMaxWidth = true
                    module.log("$TAG: hooked setMaxWidth on $className")
                }
            }
        } catch (e: Exception) {
            module.log("$TAG: failed to hook $className: ${e.message}")
        }
    }

    private fun hookDynamicClassLoaders(module: XposedModule) {
        val classLoaders = arrayOf(
            "dalvik.system.BaseDexClassLoader",
            "dalvik.system.PathClassLoader",
            "dalvik.system.DexClassLoader",
            "dalvik.system.DelegateLastClassLoader"
        )
        for (clName in classLoaders) {
            try {
                val clazz = Class.forName(clName)
                for (ctor in clazz.declaredConstructors) {
                    try {
                        module.hook(ctor).intercept { chain ->
                            val result = chain.proceed()
                            val cl = chain.thisObject as? ClassLoader
                            if (cl != null && (!hookedCalculateMaxWidthWithSmall || !hookedSetMaxWidth)) {
                                hookContentViewClasses(module, cl)
                            }
                            result
                        }
                    } catch (_: Exception) {}
                }
            } catch (_: Exception) {}
        }
    }
}