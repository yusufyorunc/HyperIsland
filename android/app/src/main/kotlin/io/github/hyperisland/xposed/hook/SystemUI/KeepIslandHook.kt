package io.github.hyperisland.xposed.hook

import android.app.Application
import android.os.Handler
import android.os.Looper
import io.github.hyperisland.xposed.ConfigManager
import io.github.hyperisland.xposed.islanddispatch.IslandDispatcher
import io.github.hyperisland.xposed.islanddispatch.definition.IslandRequest
import io.github.libxposed.api.XposedModule
import io.github.libxposed.api.XposedModuleInterface.PackageLoadedParam

/**
 * 常驻岛 Hook — 在 SystemUI 进程中发送一条完全空白的通知，
 * 使灵动岛始终保持可见状态。
 *
 * 通知特征：
 * - showNotification = false（不在通知栏显示）
 * - timeout = Int.MAX_VALUE（永不过期）
 * - isOngoing = true（系统不会自动清除）
 * - 无标题内容、无图标
 *
 * 通过 Flutter 侧 pref_keep_island 开关控制启停。
 */
object KeepIslandHook : BaseHook() {

    private const val TAG = "HyperIsland[KeepIsland]"
    private const val PREF_KEY = "pref_keep_island"

    /** 与 IslandDispatchContract.NOTIF_ID 不同，避免冲突 */
    private const val KEEP_ISLAND_NOTIF_ID = 0x4B494B49  // "KIKI"

    private val mainHandler = Handler(Looper.getMainLooper())
    private var appContext: android.content.Context? = null
    private var posted = false
    private var cachedModule: XposedModule? = null

    override fun getTag() = TAG

    override fun onConfigChanged() {
        // 配置变化时重新评估是否需要发/撤通知
        // 延迟 500ms 确保 ConfigManager 已刷新
        mainHandler.postDelayed({ evaluateKeepIsland() }, 500)
    }

    override fun onInit(module: XposedModule, param: PackageLoadedParam) {
        cachedModule = module
        try {
            val method = param.defaultClassLoader
                .loadClass("android.app.Application")
                .getDeclaredMethod("onCreate")
            module.hook(method).intercept { chain ->
                val result = chain.proceed()
                val app = chain.thisObject as? Application
                if (app != null) {
                    appContext = app.applicationContext
                    // 延迟 3 秒确保 IslandDispatcher 已注册完成
                    mainHandler.postDelayed({ evaluateKeepIsland() }, 3000)
                }
                result
            }
            log(module, "hooked Application.onCreate for keep island")
        } catch (e: Throwable) {
            logError(module, "hook failed: ${e.message}")
        }
    }

    private fun evaluateKeepIsland() {
        val ctx = appContext ?: return
        val enabled = ConfigManager.getBoolean(PREF_KEY, false)
        if (enabled && !posted) {
            postKeepIsland(ctx)
        } else if (!enabled && posted) {
            cancelKeepIsland(ctx)
        }
    }

    private fun postKeepIsland(context: android.content.Context) {
        try {
            val request = IslandRequest(
                title = " ",                    // 空格：触发岛显示但不渲染文字
                content = "",                   // 无内容
                icon = null,                    // 无图标
                notifId = KEEP_ISLAND_NOTIF_ID, // 独立 ID
                timeoutSecs = Int.MAX_VALUE,    // 永不过期
                firstFloat = false,              // 首次弹出动效
                enableFloat = false,             // 更新时浮动
                showNotification = false,       // 不在通知栏显示
                preserveStatusBarSmallIcon = false,
                isOngoing = true,               // 系统不自动清除
                showIslandIcon = false,         // 岛上不显示图标
                clearBeforePost = true,         // 先清再发，避免重复
            )
            IslandDispatcher.post(context, request)
            posted = true
            cachedModule?.let { log(it, "keep island posted (notifId=$KEEP_ISLAND_NOTIF_ID)") }
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
}
