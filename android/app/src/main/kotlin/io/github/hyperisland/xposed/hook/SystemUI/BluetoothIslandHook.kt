package io.github.hyperisland.xposed.hook

import android.bluetooth.BluetoothDevice
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.drawable.Icon
import android.os.Build
import io.github.hyperisland.xposed.ConfigManager
import io.github.hyperisland.xposed.islanddispatch.IslandDispatcher
import io.github.hyperisland.xposed.islanddispatch.definition.IslandRequest
import io.github.libxposed.api.XposedModule
import io.github.libxposed.api.XposedModuleInterface.PackageLoadedParam
import java.util.concurrent.ConcurrentHashMap
import androidx.core.graphics.createBitmap

object BluetoothIslandHook : BaseHook() {

    private const val TAG = "HyperIsland[BluetoothIsland]"
    private const val PREF_ENABLED = "pref_bluetooth_island"
    private const val PREF_OUTER_GLOW = "pref_bluetooth_island_outer_glow"
    private const val PREF_OUTER_GLOW_COLOR = "pref_bluetooth_island_outer_glow_color"
    private const val NOTIF_ID = 0x48494254
    private const val ACTION_BATTERY_LEVEL_CHANGED = "android.bluetooth.device.action.BATTERY_LEVEL_CHANGED"
    private const val EXTRA_BATTERY_LEVEL = "android.bluetooth.device.extra.BATTERY_LEVEL"

    @Volatile private var registered = false
    @Volatile private var moduleRef: XposedModule? = null
    @Volatile private var lastConnected = false
    @Volatile private var lastBattery = -1
    private val batteryByDevice = ConcurrentHashMap<String, Int>()

    override fun getTag() = TAG

    override fun onInit(module: XposedModule, param: PackageLoadedParam) {
        try {
            val method = param.defaultClassLoader
                .loadClass("android.app.Application")
                .getDeclaredMethod("onCreate")
            module.hook(method).intercept { chain ->
                val result = chain.proceed()
                val app = chain.thisObject as? android.app.Application
                if (app != null) registerReceiver(app, module)
                result
            }
            log(module, "hooked Application.onCreate")
        } catch (e: Throwable) {
            logError(module, "hook failed: ${e.message}")
        }
    }

    private fun registerReceiver(context: Context, module: XposedModule) {
        moduleRef = module
        if (registered) return
        synchronized(this) {
            if (registered) return
            val appContext = context.applicationContext ?: context
            val filter = IntentFilter().apply {
                addAction(BluetoothDevice.ACTION_ACL_CONNECTED)
                addAction(BluetoothDevice.ACTION_ACL_DISCONNECTED)
                addAction(ACTION_BATTERY_LEVEL_CHANGED)
            }
            if (Build.VERSION.SDK_INT >= 33) {
                appContext.registerReceiver(receiver, filter, Context.RECEIVER_EXPORTED)
            } else {
                @Suppress("DEPRECATION")
                appContext.registerReceiver(receiver, filter)
            }
            IslandDispatcher.register(appContext, module)
            registered = true
            logWarn(module, "bluetooth receiver registered, enabled=${ConfigManager.getBoolean(PREF_ENABLED, false)}")
        }
    }

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val action = intent.action
            val enabled = ConfigManager.getBoolean(PREF_ENABLED, false)
            moduleRef?.let { logWarn(it, "received bluetooth broadcast: action=$action enabled=$enabled") }
            if (!enabled) return
            if (action == ACTION_BATTERY_LEVEL_CHANGED) {
                val battery = readBatteryLevel(intent)
                cacheBattery(intent, battery)
                if (lastConnected && battery in 0..100) {
                    lastBattery = battery
                    moduleRef?.let { logWarn(it, "bluetooth battery changed: battery=$battery") }
                    postBluetoothIsland(context, connected = true, battery = battery)
                } else {
                    moduleRef?.let { logWarn(it, "skip bluetooth battery update: connected=$lastConnected battery=$battery") }
                }
                return
            }
            val connected = when (action) {
                BluetoothDevice.ACTION_ACL_CONNECTED -> true
                BluetoothDevice.ACTION_ACL_DISCONNECTED -> false
                else -> return
            }
            lastConnected = connected
            val battery = readBatteryLevel(intent).takeIf { it in 0..100 }
                ?: readCachedBattery(intent)
                ?: lastBattery
            if (battery in 0..100) lastBattery = battery
            moduleRef?.let { logWarn(it, "bluetooth state changed: connected=$connected battery=$battery") }
            if (connected && battery !in 0..100) {
                moduleRef?.let { logWarn(it, "skip bluetooth connected island: battery unknown") }
                return
            }
            postBluetoothIsland(context, connected, battery)
        }
    }

    private fun readBatteryLevel(intent: Intent): Int {
        val fromExtra = intent.getIntExtra(EXTRA_BATTERY_LEVEL, -1)
        if (fromExtra in 0..100) return fromExtra
        val device = if (Build.VERSION.SDK_INT >= 33) {
            intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE, BluetoothDevice::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
        }
        return device?.let { readBatteryLevelByReflection(it) } ?: -1
    }

    private fun cacheBattery(intent: Intent, battery: Int) {
        if (battery !in 0..100) return
        val device = getBluetoothDevice(intent) ?: return
        device.address?.let { batteryByDevice[it] = battery }
    }

    private fun readCachedBattery(intent: Intent): Int? {
        val device = getBluetoothDevice(intent) ?: return null
        return device.address?.let { batteryByDevice[it] }
    }

    private fun getBluetoothDevice(intent: Intent): BluetoothDevice? {
        return if (Build.VERSION.SDK_INT >= 33) {
            intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE, BluetoothDevice::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
        }
    }

    private fun readBatteryLevelByReflection(device: BluetoothDevice): Int {
        return try {
            (device.javaClass.getMethod("getBatteryLevel").invoke(device) as? Int)
                ?.takeIf { it in 0..100 }
                ?: -1
        } catch (e: Throwable) {
            moduleRef?.let { logWarn(it, "read battery level failed: ${e.message}") }
            -1
        }
    }

    private fun postBluetoothIsland(context: Context, connected: Boolean, battery: Int) {
        val title = if (connected) "已连接" else "已断开"
        val content = "电量：${if (battery in 0..100) "$battery%" else "--"}"
        moduleRef?.let { logWarn(it, "posting bluetooth island: title=$title content=$content") }
        val outerGlow = ConfigManager.getBoolean(PREF_OUTER_GLOW, false)
        val outerGlowColor = ConfigManager.getString(PREF_OUTER_GLOW_COLOR, "")
        IslandDispatcher.post(
            context,
            IslandRequest(
                title = title,
                content = content,
                icon = createBluetoothIcon(),
                notifId = NOTIF_ID,
                timeoutSecs = 5,
                firstFloat = false,
                enableFloat = false,
                showNotification = false,
                preserveStatusBarSmallIcon = false,
                outerGlow = outerGlow,
                islandOuterGlow = outerGlow,
                outEffectColor = outerGlowColor,
                islandOuterGlowColor = outerGlowColor,
                sourcePackage = "com.android.systemui",
                sourceChannelId = "bluetooth",
                clearBeforePost = true,
            ),
        )
    }

    private fun createBluetoothIcon(): Icon {
        return Icon.createWithBitmap(createBluetoothBitmap())
    }

    private fun createBluetoothBitmap(): Bitmap {
        val size = 96
        val bitmap = createBitmap(size, size)
        val canvas = Canvas(bitmap)
        val iconPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE
            style = Paint.Style.FILL
        }

        // Material Bluetooth glyph scaled from the 24dp system icon path.
        val path = Path().apply {
            moveTo(70.84f, 30.84f)
            lineTo(48f, 8f)
            lineTo(44f, 8f)
            lineTo(44f, 38.36f)
            lineTo(25.64f, 20f)
            lineTo(20f, 25.64f)
            lineTo(42.36f, 48f)
            lineTo(20f, 70.36f)
            lineTo(25.64f, 76f)
            lineTo(44f, 57.64f)
            lineTo(44f, 88f)
            lineTo(48f, 88f)
            lineTo(70.84f, 65.16f)
            lineTo(53.68f, 48f)
            close()

            moveTo(52f, 23.32f)
            lineTo(59.52f, 30.84f)
            lineTo(52f, 38.36f)
            close()

            moveTo(59.52f, 65.16f)
            lineTo(52f, 72.68f)
            lineTo(52f, 57.64f)
            close()
        }
        canvas.drawPath(path, iconPaint)
        return bitmap
    }
}
