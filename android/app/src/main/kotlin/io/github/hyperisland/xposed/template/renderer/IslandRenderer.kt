package io.github.hyperisland.xposed.template.renderer

import android.app.Notification
import android.content.Context
import android.os.Build
import android.os.Bundle
import io.github.hyperisland.xposed.template.IslandViewModel
import org.json.JSONObject

interface IslandRenderer {
    val id: String
    fun render(context: Context, extras: Bundle, vm: IslandViewModel)
}

private inline fun mutateParamV2(
    jsonParam: String,
    mutation: (pv2: JSONObject) -> Unit,
): String = try {
    val json = JSONObject(jsonParam)
    val pv2 = json.optJSONObject("param_v2") ?: return jsonParam
    mutation(pv2)
    json.toString()
} catch (_: Exception) {
    jsonParam
}

fun fixTextButtonJson(jsonParam: String): String =
    mutateParamV2(jsonParam) { pv2 ->
        val btns = pv2.optJSONArray("textButton")
        if (btns != null) {
            for (i in 0 until btns.length()) {
                val btn = btns.getJSONObject(i)
                val key = btn.optString("actionIntent").takeIf { it.isNotEmpty() } ?: continue
                btn.put("action", key)
                btn.remove("actionIntent")
                btn.remove("actionIntentType")
            }
        }
    }

fun wrapLongTextJson(jsonParam: String): String =
    try {
        val json = JSONObject(jsonParam)
        val pv2 = json.optJSONObject("param_v2") ?: return jsonParam
        val iconTextInfo = pv2.optJSONObject("iconTextInfo") ?: return jsonParam
        val content = iconTextInfo.optString("content", "")
        if (content.isEmpty()) return jsonParam

        var visualLen = 0
        var splitIdx = -1
        for (i in content.indices) {
            visualLen += if (content[i].code > 255) 2 else 1
            if (visualLen >= 36 && splitIdx == -1) splitIdx = i + 1
        }
        if (splitIdx == -1 || splitIdx >= content.length) return jsonParam

        val subContent = content.substring(splitIdx)
        if (subContent.all { it == '.' || it == '…' || it.isWhitespace() }) return jsonParam

        val coverInfo = JSONObject()
        val animIcon = iconTextInfo.optJSONObject("animIconInfo")
        if (animIcon != null) coverInfo.put("picCover", animIcon.optString("src", ""))
        coverInfo.put("title", iconTextInfo.optString("title", ""))
        coverInfo.put("content", content.substring(0, splitIdx))
        coverInfo.put("subContent", subContent)
        pv2.remove("iconTextInfo")
        pv2.put("coverInfo", coverInfo)
        json.toString()
    } catch (_: Exception) {
        jsonParam
    }

fun injectUpdatable(jsonParam: String, updatable: Boolean): String =
    mutateParamV2(jsonParam) { pv2 ->
        pv2.put("updatable", updatable)
    }

fun injectIslandAppearance(
    jsonParam: String,
    highlightColor: String?,
    dismissIsland: Boolean = false,
): String {
    if (highlightColor == null && !dismissIsland) return jsonParam
    return mutateParamV2(jsonParam) { pv2 ->
        val paramIsland = pv2.optJSONObject("param_island") ?: JSONObject()
        highlightColor?.let { paramIsland.put("highlightColor", it) }
        if (dismissIsland) paramIsland.put("dismissIsland", true)
        pv2.put("param_island", paramIsland)
    }
}

fun injectHighlightColor(jsonParam: String, highlightColor: String?): String =
    injectIslandAppearance(jsonParam, highlightColor, dismissIsland = false)

fun injectOuterGlow(jsonParam: String, outerGlow: Boolean): String {
    if (!outerGlow) return jsonParam
    return try {
        val json = org.json.JSONObject(jsonParam)
        val pv2 = json.optJSONObject("param_v2") ?: return jsonParam
        pv2.put("outEffectSrc", "outer_glow")
        json.toString()
    } catch (_: Exception) {
        jsonParam
    }
}

fun resolveRenderer(id: String): IslandRenderer = when (id) {
    ImageTextWithButtonsWrapRenderer.RENDERER_ID -> ImageTextWithButtonsWrapRenderer
    ImageTextWithRightTextButtonRenderer.RENDERER_ID -> ImageTextWithRightTextButtonRenderer
    else -> ImageTextWithButtonsRenderer
}

fun flattenActionsToExtras(resourceBundle: Bundle, extras: Bundle) {
    val nested = resourceBundle.getBundle("miui.focus.actions") ?: return
    if (Build.VERSION.SDK_INT >= 33) {
        for (key in nested.keySet()) {
            val action = nested.getParcelable(key, Notification.Action::class.java)
            if (action != null) extras.putParcelable(key, action)
        }
        return
    }
    for (key in nested.keySet()) {
        @Suppress("DEPRECATION")
        val action = nested.getParcelable(key) as? Notification.Action
        if (action != null) extras.putParcelable(key, action)
    }
}
