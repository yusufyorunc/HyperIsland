package io.github.hyperisland.xposed

import android.content.SharedPreferences
import io.github.libxposed.api.XposedModule
import java.util.concurrent.CopyOnWriteArrayList

object ConfigManager {

    private const val TAG = "HyperIsland[ConfigManager]"
    private const val FLUTTER_KEY_PREFIX = "flutter."
    private const val PREFS_GROUP = "FlutterSharedPreferences"

    @Volatile
    private var prefs: SharedPreferences? = null

    @Volatile
    private var initialized = false

    @Volatile
    private var module: XposedModule? = null

    private val changeListeners = CopyOnWriteArrayList<() -> Unit>()

    private val prefsListener = SharedPreferences.OnSharedPreferenceChangeListener { _, key ->
        module?.log("$TAG: prefs changed: key=$key")
        notifyListeners()
    }

    @Synchronized
    fun init(module: XposedModule) {
        if (initialized) return
        try {
            val p = module.getRemotePreferences(PREFS_GROUP)
            p.registerOnSharedPreferenceChangeListener(prefsListener)
            prefs = p
            this.module = module
            initialized = true
            module.log("$TAG: remote prefs '$PREFS_GROUP' loaded")
            notifyListeners()
        } catch (_: UnsupportedOperationException) {
            module.logWarn("$TAG: init failed — embedded framework, remote prefs unavailable")
            initialized = true
        } catch (e: Exception) {
            module.logError("$TAG: init failed: ${e.message}")
            initialized = true
        }
    }

    fun addChangeListener(listener: () -> Unit) {
        changeListeners += listener
    }


    fun getBoolean(key: String, default: Boolean): Boolean =
        try {
            prefs?.getBoolean(fk(key), default) ?: default
        } catch (_: ClassCastException) {
            default
        }

    fun getString(key: String, default: String = ""): String =
        try {
            prefs?.getString(fk(key), default) ?: default
        } catch (_: ClassCastException) {
            default
        }

    fun getInt(key: String, default: Int): Int =
        try {
            prefs?.getLong(fk(key), default.toLong())?.toInt() ?: default
        } catch (_: ClassCastException) {
            try {
                prefs?.getInt(fk(key), default) ?: default
            } catch (_: ClassCastException) {
                default
            }
        }

    fun getFloat(key: String, default: Float): Float =
        try {
            prefs?.getFloat(fk(key), default) ?: default
        } catch (_: ClassCastException) {
            default
        }

    fun contains(key: String): Boolean =
        prefs?.contains(fk(key)) ?: false

    fun module(): XposedModule? = module

    private fun fk(key: String) = "$FLUTTER_KEY_PREFIX$key"

    private fun notifyListeners() {
        changeListeners.forEach { runCatching { it() } }
    }
}
