package io.github.hyperisland.xposed.hook

import android.annotation.SuppressLint
import android.app.Notification
import android.os.Build
import android.os.Bundle
import android.os.SystemClock
import android.view.View
import io.github.hyperisland.xposed.log
import io.github.hyperisland.xposed.logWarn
import io.github.libxposed.api.XposedModule
import io.github.libxposed.api.XposedModuleInterface.PackageLoadedParam

/**
 * 定向保留 HyperIsland 代理焦点通知的状态栏左上角小图标。
 *
 * 作用域：com.android.systemui（系统界面）
 */
object FocusNotifStatusBarIconHook {

    private const val TAG = "HyperIsland[FocusStatusBarIcon]"
    private const val TARGET_ENTRY_CLASS =
        "com.android.systemui.statusbar.notification.collection.NotificationEntry"
    private const val TARGET_STORE_BUILDER_CLASS =
        "com.android.systemui.statusbar.notification.domain.interactor.ActiveNotificationsStoreBuilder"
    private const val TARGET_FRAGMENT_CLASS =
        "com.android.systemui.statusbar.phone.MiuiCollapsedStatusBarFragment"
    private const val VISIBILITY_MODEL_CLASS =
        "com.android.systemui.statusbar.phone.fragment.StatusBarVisibilityModel"

    @Volatile
    private var cachedDirectProxyActiveUntilElapsed = 0L

    @Volatile
    private var hooked = false

    @JvmStatic
    internal fun markDirectProxyPosted(timeoutSecs: Int) {
        val safeTimeoutSecs = timeoutSecs.coerceAtLeast(3)
        cachedDirectProxyActiveUntilElapsed =
            SystemClock.elapsedRealtime() + (safeTimeoutSecs * 1000L) + 3000L
    }

    private fun isDirectProxyActive(): Boolean =
        cachedDirectProxyActiveUntilElapsed > SystemClock.elapsedRealtime()

    fun init(module: XposedModule, param: PackageLoadedParam) {
        if (hooked) return

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            module.logWarn("$TAG: skip init for ${param.packageName} because onPackageLoaded/defaultClassLoader requires API 29+")
            return
        }

        hooked = true
        val classLoader = param.defaultClassLoader
        hookActiveNotificationModel(module, classLoader)
        hookUpdateStatusBarVisibilities(module, classLoader)
    }

    @SuppressLint("PrivateApi", "BlockedPrivateApi", "SoonBlockedPrivateApi")
    private fun hookActiveNotificationModel(module: XposedModule, classLoader: ClassLoader) {
        try {
            val entryClass = classLoader.loadClass(TARGET_ENTRY_CLASS)
            val builderClass = classLoader.loadClass(TARGET_STORE_BUILDER_CLASS)
            val toModelMethod = builderClass.getDeclaredMethod("toModel", entryClass)
            module.hook(toModelMethod).intercept { chain ->
                val result = chain.proceed()
                val entry = chain.args[0] ?: return@intercept result
                val model = result ?: return@intercept result
                val sbn = getObjectFieldOrNull(entry, "mSbn") ?: return@intercept result
                val notification = resolveNotificationFromSbnLike(sbn) ?: return@intercept result
                if (!isHyperIslandFocusProxy(notification.extras)) return@intercept result

                try {
                    setFieldValue(model, "isFocusNotification", false)
                } catch (e: Throwable) {
                    module.log("$TAG: failed to override isFocusNotification — ${e.message}")
                }
                result
            }
            module.log("$TAG: hooked ActiveNotificationsStoreBuilder.toModel(NotificationEntry)")
        } catch (e: Throwable) {
            module.log("$TAG: ActiveNotificationsStoreBuilder.toModel hook failed — ${e.message}")
        }
    }

    @SuppressLint("PrivateApi", "BlockedPrivateApi", "SoonBlockedPrivateApi")
    private fun hookUpdateStatusBarVisibilities(module: XposedModule, classLoader: ClassLoader) {
        try {
            val fragmentClass = classLoader.loadClass(TARGET_FRAGMENT_CLASS)
            val method = fragmentClass.getDeclaredMethod(
                "updateStatusBarVisibilities",
                Boolean::class.javaPrimitiveType!!
            )
            module.hook(method).intercept { chain ->
                val result = chain.proceed()
                val fragment = chain.thisObject
                if (isDirectProxyActive()) {
                    forceShowNotificationIconsModel(module, fragment)
                    restoreNotificationIconArea(fragment)
                    refreshNotificationIconArea(module, fragment)
                    module.log("$TAG: icon area restored")
                }
                result
            }
            module.log("$TAG: hooked MiuiCollapsedStatusBarFragment.updateStatusBarVisibilities(boolean)")
        } catch (e: Throwable) {
            module.log("$TAG: updateStatusBarVisibilities hook failed — ${e.message}")
        }
    }

    @SuppressLint("PrivateApi", "BlockedPrivateApi", "SoonBlockedPrivateApi")
    private fun forceShowNotificationIconsModel(module: XposedModule, fragment: Any?) {
        if (fragment == null) return
        try {
            val oldModel = getObjectFieldOrNull(fragment, "mLastModifiedVisibility") ?: return
            val modelClass = fragment.javaClass.classLoader!!.loadClass(VISIBILITY_MODEL_CLASS)
            val newModel = newInstance(
                modelClass,
                getBooleanFieldValue(oldModel, "showClock"),
                true,
                getBooleanFieldValue(oldModel, "showPrimaryOngoingActivityChip"),
                getBooleanFieldValue(oldModel, "showSecondaryOngoingActivityChip"),
                getBooleanFieldValue(oldModel, "showSystemInfo"),
                getBooleanFieldValue(oldModel, "showNotifPromptView")
            )
            setFieldValue(fragment, "mLastModifiedVisibility", newModel)
        } catch (e: Throwable) {
            module.log("$TAG: forceShowNotificationIconsModel failed — ${e.message}")
        }
    }

    private fun refreshNotificationIconArea(module: XposedModule, fragment: Any?) {
        if (fragment == null) return
        try {
            callUpdateNotificationIconAreaAndOngoingActivityChip(fragment)
        } catch (e: Throwable) {
            module.log("$TAG: refreshNotificationIconArea failed — ${e.message}")
        }
    }

    private fun restoreNotificationIconArea(fragment: Any?) {
        if (fragment == null) return
        setVisible(getObjectFieldOrNull(fragment, "mNotificationIconAreaInner") as? View)
        setVisible(getObjectFieldOrNull(fragment, "mNotificationIcons") as? View)
        setVisible(getObjectFieldOrNull(fragment, "mStatusBarIcons") as? View)
        setVisible(getObjectFieldOrNull(fragment, "mStatusContainer") as? View)
    }

    private fun setVisible(view: View?) {
        if (view == null) return
        view.visibility = View.VISIBLE
        view.alpha = 1f
        view.translationX = 0f
    }

    private fun resolveNotificationFromSbnLike(sbn: Any?): Notification? {
        if (sbn == null) return null
        (callGetNotificationMethodOrNull(sbn) as? Notification)?.let { return it }
        (getObjectFieldOrNull(sbn, "notification") as? Notification)?.let { return it }
        (getObjectFieldOrNull(sbn, "mNotification") as? Notification)?.let { return it }
        return null
    }

    private fun isHyperIslandFocusProxy(extras: Bundle?): Boolean {
        if (extras == null) return false
        return extras.getBoolean("hyperisland_preserve_status_bar_small_icon", false)
    }

    private fun getObjectFieldOrNull(instance: Any, fieldName: String): Any? {
        var c: Class<*>? = instance.javaClass
        while (c != null) {
            try {
                val f = c.getDeclaredField(fieldName)
                f.isAccessible = true
                return f.get(instance)
            } catch (_: NoSuchFieldException) {
                c = c.superclass
            }
        }
        return null
    }

    private fun setFieldValue(instance: Any, fieldName: String, value: Any?) {
        var c: Class<*>? = instance.javaClass
        while (c != null) {
            try {
                val f = c.getDeclaredField(fieldName)
                f.isAccessible = true
                f.set(instance, value)
                return
            } catch (_: NoSuchFieldException) {
                c = c.superclass
            }
        }
    }

    private fun getBooleanFieldValue(instance: Any, fieldName: String): Boolean =
        getObjectFieldOrNull(instance, fieldName) as? Boolean ?: false

    @SuppressLint("PrivateApi", "BlockedPrivateApi", "SoonBlockedPrivateApi")
    private fun callGetNotificationMethodOrNull(instance: Any): Any? {
        var c: Class<*>? = instance.javaClass
        while (c != null) {
            try {
                val m = c.getDeclaredMethod("getNotification")
                m.isAccessible = true
                return m.invoke(instance)
            } catch (_: NoSuchMethodException) {
                c = c.superclass
            }
        }
        return null
    }

    @SuppressLint("PrivateApi", "BlockedPrivateApi", "SoonBlockedPrivateApi")
    private fun callUpdateNotificationIconAreaAndOngoingActivityChip(instance: Any): Any? {
        var c: Class<*>? = instance.javaClass
        while (c != null) {
            for (m in c.declaredMethods) {
                if (m.name == "updateNotificationIconAreaAndOngoingActivityChip" && m.parameterCount == 1) {
                    m.isAccessible = true
                    try {
                        return m.invoke(instance, false)
                    } catch (_: Throwable) {
                    }
                }
            }
            c = c.superclass
        }
        return null
    }

    private fun newInstance(clazz: Class<*>, vararg args: Any?): Any? {
        for (ctor in clazz.declaredConstructors) {
            if (ctor.parameterCount == args.size) {
                ctor.isAccessible = true
                try {
                    return ctor.newInstance(*args)
                } catch (_: Throwable) {
                }
            }
        }
        return null
    }
}
