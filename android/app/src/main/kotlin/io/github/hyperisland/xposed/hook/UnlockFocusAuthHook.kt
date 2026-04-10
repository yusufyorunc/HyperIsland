package io.github.hyperisland.xposed.hook

import android.os.Build
import io.github.hyperisland.xposed.ConfigManager
import io.github.hyperisland.xposed.log
import io.github.hyperisland.xposed.logWarn
import io.github.libxposed.api.XposedModule
import io.github.libxposed.api.XposedModuleInterface.PackageLoadedParam

object UnlockFocusAuthHook {

    private const val TAG = "HyperIsland[UnlockFocusAuthHook]"
    private const val SETTINGS_KEY = "pref_unlock_focus_auth"
    private const val AUTH_SESSION_CLASS = "com.xiaomi.xms.auth.AuthSession"

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

        hookAuthSession(module, param.defaultClassLoader)
    }

    private fun getErrorCode(instance: Any): Int {
        var c: Class<*>? = instance.javaClass
        while (c != null) {
            try {
                val f = c.getDeclaredField("a")
                if (f.type == Int::class.javaPrimitiveType || f.type == Int::class.javaObjectType) {
                    f.isAccessible = true
                    return (f.get(instance) as? Int) ?: 0
                }
            } catch (_: NoSuchFieldException) {
            }
            val intField = c.declaredFields.firstOrNull {
                it.type == Int::class.javaPrimitiveType || it.type == Int::class.javaObjectType
            }
            if (intField != null) {
                intField.isAccessible = true
                return (intField.get(instance) as? Int) ?: 0
            }
            c = c.superclass
        }
        return 0
    }

    private fun clearErrorCode(instance: Any) {
        var c: Class<*>? = instance.javaClass
        while (c != null) {
            try {
                val f = c.getDeclaredField("a")
                if (f.type == Int::class.javaPrimitiveType || f.type == Int::class.javaObjectType) {
                    f.isAccessible = true
                    f.set(instance, 0)
                    return
                }
            } catch (_: NoSuchFieldException) {
            }
            val intField = c.declaredFields.firstOrNull {
                it.type == Int::class.javaPrimitiveType || it.type == Int::class.javaObjectType
            }
            if (intField != null) {
                intField.isAccessible = true
                intField.set(instance, 0)
                return
            }
            c = c.superclass
        }
    }

    private fun invokeSuccessCallback(instance: Any): Any? {
        var c: Class<*>? = instance.javaClass
        while (c != null) {
            try {
                val m = c.getDeclaredMethod("h")
                m.isAccessible = true
                return m.invoke(instance)
            } catch (_: NoSuchMethodException) {
            }
            val candidate = c.declaredMethods.firstOrNull {
                it.parameterCount == 0 &&
                        it.returnType == Void.TYPE &&
                        it.name != "toString" && it.name != "hashCode" && it.name != "finalize"
            }
            if (candidate != null) {
                candidate.isAccessible = true
                return candidate.invoke(instance)
            }
            c = c.superclass
        }
        return null
    }

    private fun hookAuthSession(module: XposedModule, classLoader: ClassLoader) {
        try {
            val authSessionClass = classLoader.loadClass(AUTH_SESSION_CLASS)

            val targetMethod = authSessionClass.declaredMethods.firstOrNull {
                it.name == "b" && it.parameterCount == 1
            } ?: run {
                module.log("$TAG: method 'b(error)' not found in $AUTH_SESSION_CLASS")
                return
            }

            module.hook(targetMethod).intercept { chain ->
                val error = chain.args[0]
                if (error == null) return@intercept chain.proceed()

                try {
                    val originalCode = getErrorCode(error)
                    module.log("$TAG: auth error intercepted, original errorCode=$originalCode, forcing to 0")
                    clearErrorCode(error)
                    val successResult = invokeSuccessCallback(chain.thisObject!!)
                    module.log("$TAG: auth bypassed successfully")
                    successResult
                } catch (e: Throwable) {
                    module.log("$TAG: bypass failed — ${e.message}")
                    chain.proceed()
                }
            }

            module.log("$TAG: hooked AuthSession.b(error)")
        } catch (e: Throwable) {
            module.log("$TAG: failed to hook $AUTH_SESSION_CLASS — ${e.message}")
        }
    }
}
