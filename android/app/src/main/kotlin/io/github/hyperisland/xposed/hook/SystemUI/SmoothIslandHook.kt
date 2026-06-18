package io.github.hyperisland.xposed.hook.SystemUI

import android.graphics.Canvas
import android.graphics.Color
import android.graphics.ColorFilter
import android.graphics.Outline
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PixelFormat
import android.graphics.Rect
import android.graphics.drawable.Drawable
import android.graphics.drawable.GradientDrawable
import android.view.View
import androidx.graphics.shapes.RoundedPolygon
import androidx.graphics.shapes.pill
import androidx.graphics.shapes.toPath
import io.github.hyperisland.xposed.ConfigManager
import io.github.hyperisland.xposed.hook.BaseHook
import io.github.hyperisland.xposed.utils.HookUtils
import io.github.libxposed.api.XposedModule
import io.github.libxposed.api.XposedModuleInterface.PackageLoadedParam
import java.util.Collections
import java.util.LinkedHashMap
import java.util.WeakHashMap
import kotlin.math.abs

/**
 * 将超级岛普通圆角胶囊替换为连续曲率的平滑胶囊。
 *
 * Hook 会在 SystemUI 启动时按开关决定是否注册；已注册后如果用户关闭开关，
 * 拦截入口也会完全旁路，不再修改 Outline 或 Drawable。
 */
object SmoothIslandHook : BaseHook() {

    private const val TAG = "HyperIsland[SmoothIsland]"
    private const val KEY_ENABLED = "pref_smooth_island"
    private const val KEY_SMOOTHING = "pref_smooth_island_smoothing"
    private const val DEFAULT_SMOOTHING = 0.8f
    private const val MIN_SMOOTHING = 0.0f
    private const val MAX_SMOOTHING = 1.0f
    private const val MAX_PATH_CACHE_SIZE = 32
    private const val STABLE_STROKE_DELAY_MS = 140L

    private const val CONTENT_VIEW_CLASS =
        "miui.systemui.dynamicisland.window.content.DynamicIslandBaseContentView"
    private const val BACKGROUND_VIEW_CLASS =
        "miui.systemui.dynamicisland.DynamicIslandBackgroundView"
    private const val DIMEN_CLASS = "miui.systemui.dynamicisland.R\$dimen"

    private val targetProviderClasses = listOf(
        "com.android.systemui.statusbar.notification.DynamicIslandWindowAnimController\$updateFakeViewOutline\$1",
        "com.android.systemui.statusbar.notification.mediaisland.MiuiIslandMediaViewHolder\$Companion\$create\$1\$1",
    )
    private val geometrySetterNames = listOf(
        "setActualLeft",
        "setActualTop",
        "setActualWidth",
        "setActualHeight",
    )
    private val dynamicIslandCallers = listOf("dynamicisland", "mediaisland")
    private val excludedOutlineCallers = listOf(
        "footerview",
        "footerviewbutton",
        "notificationstackscrolllayout",
        "notif_footer",
    )

    private val pathCache = object : LinkedHashMap<CapsuleShape, Path>(MAX_PATH_CACHE_SIZE, 0.75f, true) {
        override fun removeEldestEntry(eldest: MutableMap.MutableEntry<CapsuleShape, Path>?): Boolean {
            return size > MAX_PATH_CACHE_SIZE
        }
    }
    private val strokeStates = Collections.synchronizedMap(WeakHashMap<Any, StrokeState>())
    private val hookedProviderClassLoaders = mutableSetOf<Int>()

    @Volatile private var enabled = false
    @Volatile private var smoothing = DEFAULT_SMOOTHING
    @Volatile private var outlineHooked = false
    @Volatile private var pluginHooksInstalled = false

    override fun getTag() = TAG

    override fun onConfigChanged() {
        loadConfig()
        if (!enabled) restoreAllPluginStrokes()
        synchronized(pathCache) { pathCache.clear() }
    }

    override fun onInit(module: XposedModule, param: PackageLoadedParam) {
        if (param.packageName != "com.android.systemui") return
        loadConfig()
        if (!enabled) return
        hookOutlineRoundRect(module)
        hookTargetOutlineProviders(module, param.defaultClassLoader)
        HookUtils.hookDynamicClassLoaders(module, ClassLoader.getSystemClassLoader()) { classLoader ->
            hookTargetOutlineProviders(module, classLoader)
            hookPlugin(module, classLoader)
        }
        hookPlugin(module, param.defaultClassLoader)
    }

    private fun hookOutlineRoundRect(module: XposedModule) {
        if (outlineHooked) return
        try {
            val method = Outline::class.java.getDeclaredMethod(
                "setRoundRect",
                Int::class.javaPrimitiveType!!,
                Int::class.javaPrimitiveType!!,
                Int::class.javaPrimitiveType!!,
                Int::class.javaPrimitiveType!!,
                Float::class.javaPrimitiveType!!,
            )
            module.hook(method).intercept { chain ->
                if (!enabled) return@intercept chain.proceed()
                val left = chain.args.getOrNull(0) as? Int ?: return@intercept chain.proceed()
                val top = chain.args.getOrNull(1) as? Int ?: return@intercept chain.proceed()
                val right = chain.args.getOrNull(2) as? Int ?: return@intercept chain.proceed()
                val bottom = chain.args.getOrNull(3) as? Int ?: return@intercept chain.proceed()
                val radius = chain.args.getOrNull(4) as? Float ?: return@intercept chain.proceed()
                val height = bottom - top
                if (height > 10 && abs(radius - (height / 2f)) <= 1f && isDynamicIslandOutlineCall()) {
                    (chain.thisObject as? Outline)?.setPath(createSmoothCapsulePath(left, top, right, bottom))
                    null
                } else {
                    chain.proceed()
                }
            }
            outlineHooked = true
            log(module, "hooked Outline.setRoundRect")
        } catch (e: Throwable) {
            logError(module, "hookOutlineRoundRect failed: ${e.message}")
        }
    }

    private fun hookTargetOutlineProviders(module: XposedModule, classLoader: ClassLoader) {
        val clId = System.identityHashCode(classLoader)
        if (!hookedProviderClassLoaders.add(clId)) return
        targetProviderClasses.forEach { className ->
            try {
                val clazz = Class.forName(className, false, classLoader)
                val method = clazz.getDeclaredMethod("getOutline", View::class.java, Outline::class.java)
                module.hook(method).intercept { chain ->
                    val result = chain.proceed()
                    if (enabled) overrideOutlineIfCapsule(chain.args.getOrNull(1) as? Outline)
                    result
                }
                log(module, "hooked $className.getOutline")
            } catch (_: Throwable) {
            }
        }
    }

    private fun hookPlugin(module: XposedModule, classLoader: ClassLoader) {
        if (pluginHooksInstalled) return
        try {
            val contentViewClass = Class.forName(CONTENT_VIEW_CLASS, false, classLoader)
            val backgroundViewClass = Class.forName(BACKGROUND_VIEW_CLASS, false, classLoader)
            hookPluginMedianLuma(module, contentViewClass, classLoader)
            hookPluginBackgroundGeometry(module, backgroundViewClass)
            pluginHooksInstalled = true
            log(module, "hooked plugin smooth island")
        } catch (_: Throwable) {
        }
    }

    private fun hookPluginMedianLuma(module: XposedModule, contentViewClass: Class<*>, classLoader: ClassLoader) {
        try {
            val method = contentViewClass.getDeclaredMethod("updateMedianLuma", Float::class.javaPrimitiveType!!)
            module.hook(method).intercept { chain ->
                val result = chain.proceed()
                if (enabled) {
                    val contentView = chain.thisObject ?: return@intercept result
                    val medianLuma = chain.args.getOrNull(0) as? Float ?: return@intercept result
                    scheduleSmoothPluginStroke(contentView, contentViewClass, classLoader, medianLuma)
                }
                result
            }
        } catch (_: Throwable) {
        }
    }

    private fun hookPluginBackgroundGeometry(module: XposedModule, backgroundViewClass: Class<*>) {
        geometrySetterNames.forEach { methodName ->
            try {
                val method = backgroundViewClass.getDeclaredMethod(methodName, Int::class.javaPrimitiveType!!)
                module.hook(method).intercept { chain ->
                    val result = chain.proceed()
                    if (enabled) {
                        onPluginBackgroundGeometryChanged(chain.thisObject)
                    } else {
                        restorePluginStroke(chain.thisObject, strokeStates[chain.thisObject])
                    }
                    result
                }
            } catch (_: Throwable) {
            }
        }
    }

    private fun overrideOutlineIfCapsule(outline: Outline?) {
        if (outline == null) return
        val bounds = Rect()
        if (outline.getRect(bounds) && bounds.height() > 10) {
            val height = bounds.height()
            if (abs(outline.radius - (height / 2f)) <= 1.5f) {
                outline.setPath(createSmoothCapsulePath(bounds.left, bounds.top, bounds.right, bounds.bottom))
            }
        }
    }

    private fun createSmoothCapsulePath(left: Int, top: Int, right: Int, bottom: Int): Path {
        val width = right - left
        val height = bottom - top
        if (width <= 0 || height <= 0) return Path()
        val path = getBaseCapsulePath(width, height)
        path.offset(left + width / 2f, top + height / 2f)
        return path
    }

    private fun getBaseCapsulePath(width: Int, height: Int): Path {
        val key = CapsuleShape(width, height, smoothing)
        synchronized(pathCache) {
            pathCache[key]?.let { return Path(it) }
        }
        val generated = RoundedPolygon.pill(
            width = width.toFloat(),
            height = height.toFloat(),
            smoothing = smoothing,
        ).toPath()
        synchronized(pathCache) { pathCache[key] = generated }
        return Path(generated)
    }

    private fun isDynamicIslandOutlineCall(): Boolean {
        var matched = false
        Thread.currentThread().stackTrace.forEach { frame ->
            val name = frame.className.lowercase()
            if (excludedOutlineCallers.any { name.contains(it) }) return false
            if (dynamicIslandCallers.any { name.contains(it) }) matched = true
        }
        return matched
    }

    private fun scheduleSmoothPluginStroke(
        contentView: Any,
        contentViewClass: Class<*>,
        classLoader: ClassLoader,
        medianLuma: Float,
    ) {
        try {
            val backgroundView = contentViewClass.getMethod("getBackgroundView").invoke(contentView) ?: return
            val drawable = backgroundView.javaClass.getMethod("getDrawable").invoke(backgroundView) as? GradientDrawable ?: return
            val isExpanded = contentViewClass.getMethod("isExpanded").invoke(contentView) as Boolean
            val strokeWidth = readPluginStrokeWidth(contentView, classLoader, isExpanded)
            if (strokeWidth <= 0) return
            val strokeColor = readPluginStrokeColor(contentView, contentViewClass, medianLuma, isExpanded)
            val state = strokeStates.getOrPut(backgroundView) { StrokeState() }
            state.originalDrawable = drawable
            state.strokeWidth = strokeWidth
            state.strokeColor = strokeColor
            restorePluginStroke(backgroundView, state)
            scheduleStablePluginStroke(backgroundView, state)
        } catch (_: Throwable) {
        }
    }

    private fun readPluginStrokeWidth(contentView: Any, classLoader: ClassLoader, isExpanded: Boolean): Int {
        val fieldName = if (isExpanded) "expanded_stroke" else "island_stroke"
        val dimenClass = Class.forName(DIMEN_CLASS, false, classLoader)
        val resId = dimenClass.getField(fieldName).getInt(null)
        val context = contentView.javaClass.getMethod("getContext").invoke(contentView) as android.content.Context
        return context.resources.getDimensionPixelSize(resId)
    }

    private fun readPluginStrokeColor(
        contentView: Any,
        contentViewClass: Class<*>,
        medianLuma: Float,
        isExpanded: Boolean,
    ): Int {
        val highlightColor = if (isExpanded) null else readPluginHighlightColor(contentView, contentViewClass)
        if (highlightColor == null) {
            val method = contentViewClass.getDeclaredMethod(
                "updateMedianLuma\$getStrokeColor",
                contentViewClass,
                Float::class.javaPrimitiveType!!,
            )
            method.isAccessible = true
            return method.invoke(null, contentView, medianLuma) as Int
        }
        val color = Color.parseColor(highlightColor)
        val alphaRatio = (1f - medianLuma).coerceIn(0f, 1f)
        val alpha = (Color.alpha(color) * alphaRatio).toInt().coerceIn(0, 255)
        return (color and 0x00FFFFFF) or (alpha shl 24)
    }

    private fun readPluginHighlightColor(contentView: Any, contentViewClass: Class<*>): String? {
        val template = contentViewClass.getMethod("getTemplate").invoke(contentView) ?: return null
        return template.javaClass.getMethod("getHighlightColor").invoke(template) as? String
    }

    private fun onPluginBackgroundGeometryChanged(backgroundView: Any?) {
        if (backgroundView == null) return
        val state = strokeStates[backgroundView] ?: return
        state.token++
        restorePluginStroke(backgroundView, state)
        scheduleStablePluginStroke(backgroundView, state)
    }

    private fun scheduleStablePluginStroke(backgroundView: Any, state: StrokeState) {
        val view = backgroundView as? View ?: return
        val token = ++state.token
        val bounds = readPluginBackgroundBounds(backgroundView) ?: return
        view.postDelayed({
            val latestState = strokeStates[backgroundView] ?: return@postDelayed
            if (!enabled) {
                restorePluginStroke(backgroundView, latestState)
                return@postDelayed
            }
            if (latestState.token != token) return@postDelayed
            val latestBounds = readPluginBackgroundBounds(backgroundView) ?: return@postDelayed
            if (latestBounds != bounds) {
                scheduleStablePluginStroke(backgroundView, latestState)
                return@postDelayed
            }
            applySmoothPluginStroke(backgroundView, latestState)
        }, STABLE_STROKE_DELAY_MS)
    }

    private fun readPluginBackgroundBounds(backgroundView: Any): Rect? {
        return try {
            val clazz = backgroundView.javaClass
            Rect(
                clazz.getMethod("getActualLeft").invoke(backgroundView) as Int,
                clazz.getMethod("getActualTop").invoke(backgroundView) as Int,
                clazz.getMethod("getActualWidth").invoke(backgroundView) as Int,
                clazz.getMethod("getActualHeight").invoke(backgroundView) as Int,
            )
        } catch (_: Throwable) {
            null
        }
    }

    private fun applySmoothPluginStroke(backgroundView: Any, state: StrokeState) {
        val original = state.originalDrawable ?: return
        try {
            original.setStroke(0, Color.TRANSPARENT)
            val smoothDrawable = SmoothStrokeDrawable(original, state.strokeWidth.toFloat(), state.strokeColor)
            backgroundView.javaClass.getMethod("setDrawable", Drawable::class.java)
                .invoke(backgroundView, smoothDrawable)
            state.applied = true
            (backgroundView as? View)?.invalidate()
        } catch (_: Throwable) {
        }
    }

    private fun restoreAllPluginStrokes() {
        synchronized(strokeStates) {
            strokeStates.forEach { (backgroundView, state) -> restorePluginStroke(backgroundView, state) }
        }
    }

    private fun restorePluginStroke(backgroundView: Any?, state: StrokeState?) {
        if (state?.applied != true) return
        val original = state.originalDrawable ?: return
        try {
            original.setStroke(state.strokeWidth, state.strokeColor)
            backgroundView?.javaClass?.getMethod("setDrawable", Drawable::class.java)
                ?.invoke(backgroundView, original)
            state.applied = false
            (backgroundView as? View)?.invalidate()
        } catch (_: Throwable) {
        }
    }

    private fun loadConfig() {
        enabled = ConfigManager.getBoolean(KEY_ENABLED, false)
        smoothing = ConfigManager.getFloat(KEY_SMOOTHING, DEFAULT_SMOOTHING)
            .coerceIn(MIN_SMOOTHING, MAX_SMOOTHING)
    }

    private data class CapsuleShape(val width: Int, val height: Int, val smoothing: Float)

    private data class StrokeState(
        var originalDrawable: GradientDrawable? = null,
        var strokeWidth: Int = 0,
        var strokeColor: Int = Color.TRANSPARENT,
        var token: Int = 0,
        var applied: Boolean = false,
    )

    private class SmoothStrokeDrawable(
        private val fillDrawable: Drawable,
        private val strokeWidth: Float,
        private val strokeColor: Int,
    ) : Drawable() {
        private val strokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.STROKE }

        override fun draw(canvas: Canvas) {
            fillDrawable.setBounds(bounds)
            fillDrawable.draw(canvas)
            if (strokeWidth <= 0f || Color.alpha(strokeColor) == 0) return
            val halfStroke = strokeWidth / 2f
            val path = SmoothIslandHook.createSmoothCapsulePath(
                (bounds.left + halfStroke).toInt(),
                (bounds.top + halfStroke).toInt(),
                (bounds.right - halfStroke).toInt(),
                (bounds.bottom - halfStroke).toInt(),
            )
            strokePaint.color = strokeColor
            strokePaint.strokeWidth = strokeWidth
            canvas.drawPath(path, strokePaint)
        }

        override fun setAlpha(alpha: Int) {
            fillDrawable.alpha = alpha
            strokePaint.alpha = alpha
            invalidateSelf()
        }

        override fun setColorFilter(colorFilter: ColorFilter?) {
            fillDrawable.colorFilter = colorFilter
            strokePaint.colorFilter = colorFilter
            invalidateSelf()
        }

        @Deprecated("Deprecated in Java")
        override fun getOpacity(): Int = PixelFormat.TRANSLUCENT
    }
}
