package io.github.hyperisland

import android.app.Application
import android.content.SharedPreferences
import android.util.Log
import androidx.core.content.edit
import io.github.libxposed.service.XposedService
import io.github.libxposed.service.XposedServiceHelper
import java.util.concurrent.TimeUnit
import java.util.concurrent.locks.ReentrantLock
import kotlin.concurrent.withLock

class HyperIslandApp : Application(), XposedServiceHelper.OnServiceListener {

    private val flutterPrefs: SharedPreferences by lazy {
        getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
    }

    @Volatile
    private var xposedService: XposedService? = null
        set(value) {
            field = value; serviceReady = value != null
        }

    private val flutterPrefsListener =
        SharedPreferences.OnSharedPreferenceChangeListener { prefs, key ->
            syncKeyToRemote(prefs, key)
        }

    override fun onCreate() {
        super.onCreate()
        XposedServiceHelper.registerListener(this)
        flutterPrefs.registerOnSharedPreferenceChangeListener(flutterPrefsListener)
    }

    override fun onServiceBind(service: XposedService) {
        xposedService = service
        apiVersion = service.apiVersion
        Log.d(TAG, "XposedService bound, API version: $apiVersion, syncing all prefs")
        syncAllToRemote(service)
        serviceReadyLock.withLock {
            serviceReadyCondition.signalAll()
        }
    }

    override fun onServiceDied(service: XposedService) {
        xposedService = null
        Log.d(TAG, "XposedService died")
    }

    private fun syncKeyToRemote(prefs: SharedPreferences, key: String?) {
        val service = xposedService ?: return
        try {
            val remote = service.getRemotePreferences(REMOTE_PREFS_NAME)
            remote.edit {
                if (key == null) {
                    writeAll(prefs, this)
                } else {
                    writeValue(this, key, prefs.all[key])
                }
            }
            Log.d(TAG, "synced key=$key to remote prefs")
        } catch (e: Exception) {
            Log.w(TAG, "syncKeyToRemote failed: ${e.message}")
        }
    }

    private fun syncAllToRemote(service: XposedService) {
        try {
            val remote = service.getRemotePreferences(REMOTE_PREFS_NAME)
            remote.edit {
                writeAll(flutterPrefs, this)
            }
            Log.d(TAG, "full sync done: ${flutterPrefs.all.size} keys")
        } catch (e: Exception) {
            Log.w(TAG, "syncAllToRemote failed: ${e.message}")
        }
    }

    private fun writeAll(src: SharedPreferences, editor: SharedPreferences.Editor) {
        for ((key, value) in src.all) {
            writeValue(editor, key, value)
        }
    }

    private fun writeValue(editor: SharedPreferences.Editor, key: String, value: Any?) {
        when (value) {
            is Boolean -> editor.putBoolean(key, value)
            is Int -> editor.putInt(key, value)
            is Long -> editor.putLong(key, value)
            is Float -> editor.putFloat(key, value)
            is String -> editor.putString(key, value)
            is Set<*> -> @Suppress("UNCHECKED_CAST")
            editor.putStringSet(key, value as Set<String>)

            null -> editor.remove(key)
        }
    }

    companion object {
        private const val TAG = "HyperIsland[App]"
        const val REMOTE_PREFS_NAME = "FlutterSharedPreferences"

        @Volatile
        private var serviceReady = false

        @Volatile
        private var apiVersion: Int = 0
        private val serviceReadyLock = ReentrantLock()
        private val serviceReadyCondition = serviceReadyLock.newCondition()

        fun isReady(): Boolean = serviceReady

        fun getApiVersion(): Int = apiVersion

        fun awaitReady(timeoutMs: Long = 1500): Boolean {
            if (isReady()) return true
            serviceReadyLock.withLock {
                if (!isReady()) {
                    try {
                        serviceReadyCondition.await(timeoutMs, TimeUnit.MILLISECONDS)
                    } catch (_: InterruptedException) {
                        Thread.currentThread().interrupt()
                    }
                }
            }
            return isReady()
        }
    }
}
