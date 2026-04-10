package io.github.hyperisland.xposed.template

import android.app.ActivityManager
import android.content.Context
import android.util.Log
import io.github.hyperisland.xposed.ConfigManager

object BlacklistFilter {

    private const val TAG = "HyperIsland[Blacklist]"

    @Volatile
    private var cachedRawBlacklist: String = ""

    @Volatile
    private var cachedBlacklistSet: Set<String> = emptySet()

    @Volatile
    private var cachedActivityManager: ActivityManager? = null

    private fun resolveBlacklistSet(raw: String): Set<String> {
        if (raw == cachedRawBlacklist) return cachedBlacklistSet
        val parsed = raw.split(',')
            .map { it.trim() }
            .filter { it.isNotEmpty() }
            .toSet()
        cachedRawBlacklist = raw
        cachedBlacklistSet = parsed
        return parsed
    }

    fun applyTo(context: Context, data: NotifData): NotifData {
        if (data.firstFloat == "off" && data.enableFloatMode == "off") return data

        val blacklistSet = resolveBlacklistSet(ConfigManager.getString("pref_app_blacklist"))
        if (blacklistSet.isEmpty()) return data

        val foregroundApp = try {
            val am = cachedActivityManager
                ?: (context.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager)
                    ?.also { cachedActivityManager = it }
            if (am == null) return data
            @Suppress("DEPRECATION")
            am.getRunningTasks(1).firstOrNull()?.topActivity?.packageName ?: ""
        } catch (e: Exception) {
            Log.d("HyperIsland", "$TAG: getRunningTasks failed: ${e.message}")
            ""
        }

        val isBlacklisted = foregroundApp.isNotEmpty() && blacklistSet.contains(foregroundApp)
        Log.d(
            "HyperIsland",
            "$TAG: foreground=$foregroundApp, isBlacklisted=$isBlacklisted"
        )

        if (!isBlacklisted) return data

        Log.d("HyperIsland", "$TAG: $foregroundApp skipped float")
        return data.copy(firstFloat = "off", enableFloatMode = "off")
    }
}
