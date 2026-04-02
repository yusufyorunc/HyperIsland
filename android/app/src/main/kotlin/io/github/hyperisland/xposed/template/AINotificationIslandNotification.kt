package io.github.hyperisland.xposed.templates

import android.content.Context
import android.graphics.drawable.Icon
import android.os.Bundle
import io.github.hyperisland.xposed.ConfigManager
import io.github.hyperisland.xposed.IslandDispatcher
import io.github.hyperisland.xposed.IslandRequest
import io.github.hyperisland.xposed.IslandTemplate
import io.github.hyperisland.xposed.IslandViewModel
import io.github.hyperisland.xposed.NotifData
import io.github.hyperisland.xposed.log
import io.github.hyperisland.xposed.logError
import io.github.hyperisland.xposed.logWarn
import io.github.hyperisland.xposed.renderer.formatIslandContent
import io.github.hyperisland.xposed.renderer.formatIslandTitle
import io.github.hyperisland.xposed.renderer.resolveRenderer
import io.github.hyperisland.xposed.resolveFocusIcon
import io.github.hyperisland.xposed.resolveIslandIcon
import io.github.hyperisland.xposed.toRounded
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors
import java.util.concurrent.Future
import java.util.concurrent.TimeUnit
import java.util.concurrent.TimeoutException

/**
 * AI 增强版通知超级岛。
 * 将通知信息发送给 AI，由 AI 生成大岛左右文本。若 3 秒内未响应，回退到默认逻辑。
 *
 * 消息处理（AI 调用 + [process]）与渲染（[ImageTextWithButtonsRenderer]/[ImageTextWithButtonsWrapRenderer]）分离。
 */
object AINotificationIslandNotification : IslandTemplate {

    private const val TAG = "HyperIsland[AINotifIsland]"
    const val TEMPLATE_ID = "ai_notification_island"

    override val id = TEMPLATE_ID

    private val executor by lazy {
        Executors.newSingleThreadExecutor { runnable ->
            Thread(runnable, "hyper-ai-worker").apply { isDaemon = true }
        }
    }

    override fun inject(context: Context, extras: Bundle, data: NotifData) {
        val aiConfig = loadAiConfig()
        val aiText = if (aiConfig.enabled && aiConfig.url.isNotEmpty()) {
            fetchAiText(aiConfig, data)
        } else null

        val leftText  = aiText?.left  ?: data.title
        val rightText = aiText?.right ?: data.subtitle.ifEmpty { data.title }
        val displayText = buildDisplayText(
            left = leftText,
            right = rightText,
            fallbackTitle = data.title.ifEmpty { "通知" },
        )

        log(
            if (aiText != null) "$TAG: AI text — left=${displayText.title} | right=${displayText.content}"
            else "$TAG: fallback text — left=${displayText.title} | right=${displayText.content}"
        )

        if (data.focusNotif == "off") {
            injectViaDispatcher(context, data, displayText)
            return
        }
        try {
            val vm = process(context, data, displayText)
            resolveRenderer(data.renderer).render(context, extras, vm)
            //ConfigManager.module()?.log("$TAG: injected — title=${data.title} | left=$leftText | right=$rightText | notifId=${data.notifId}")
        } catch (e: Exception) {
            logError("$TAG: injection error: ${e.message}")
        }
    }

    // ── AI 配置 ────────────────────────────────────────────────────────────────

    private data class AiConfig(
        val enabled: Boolean,
        val url: String,
        val apiKey: String,
        val model: String,
        val prompt: String,
        val timeout: Int,
        val promptInUser: Boolean,
        val temperature: Float,
        val maxTokens: Int,
    )

    private data class AiIslandText(val left: String, val right: String)
    private data class DisplayText(val title: String, val content: String)

    private fun buildDisplayText(left: String, right: String, fallbackTitle: String): DisplayText {
        val title = formatIslandTitle(left, fallback = fallbackTitle, maxVisualUnits = 30)
        val content = formatIslandContent(right, fallback = title, maxVisualUnits = 44)
        return DisplayText(title = title, content = content)
    }

    private fun loadAiConfig(): AiConfig = AiConfig(
        enabled = ConfigManager.getBoolean("pref_ai_enabled", false),
        url     = ConfigManager.getString("pref_ai_url"),
        apiKey  = ConfigManager.getString("pref_ai_api_key"),
        model   = ConfigManager.getString("pref_ai_model"),
        prompt  = ConfigManager.getString("pref_ai_prompt"),
        timeout = ConfigManager.getInt("pref_ai_timeout", 3).coerceIn(3, 15),
        promptInUser = ConfigManager.getBoolean("pref_ai_prompt_in_user", false),
        temperature = ConfigManager.getFloat("pref_ai_temperature", 0.1f).coerceIn(0f, 1f),
        maxTokens = ConfigManager.getInt("pref_ai_max_tokens", 50).coerceIn(10, 500),
    )

    // ── AI 调用（带超时） ──────────────────────────────────────────────────────

    private fun fetchAiText(config: AiConfig, data: NotifData): AiIslandText? {
        val future: Future<AiIslandText?> = executor.submit<AiIslandText?> {
            callAiApi(config, data)
        }
        return try {
            future.get(config.timeout.toLong(), TimeUnit.SECONDS)
        } catch (_: TimeoutException) {
            future.cancel(true)
            logWarn("$TAG: AI request timed out, falling back")
            null
        } catch (e: Exception) {
            logError("$TAG: AI request error: ${e.message}")
            null
        }
    }

    private fun callAiApi(config: AiConfig, data: NotifData): AiIslandText? {
        val requestBody = buildRequestBody(config, data)
        val networkTimeoutMs = (config.timeout * 1000).coerceIn(3000, 15000)
        val conn = (URL(config.url).openConnection() as HttpURLConnection).apply {
            requestMethod = "POST"
            setRequestProperty("Content-Type", "application/json")
            setRequestProperty("Accept", "application/json")
            if (config.apiKey.isNotEmpty()) setRequestProperty("Authorization", "Bearer ${config.apiKey}")
            connectTimeout = networkTimeoutMs
            readTimeout    = networkTimeoutMs
            doOutput       = true
        }
        //log("$TAG: POST ${config.url}")
        return try {
            conn.outputStream.use { it.write(requestBody.toByteArray(Charsets.UTF_8)) }
            val code = conn.responseCode
            if (code != HttpURLConnection.HTTP_OK) {
                val errorBody = try { conn.errorStream?.bufferedReader(Charsets.UTF_8)?.use { it.readText() } ?: "" } catch (_: Exception) { "" }
                logError("$TAG: HTTP $code — $errorBody")
                return null
            }
            parseAiResponse(conn.inputStream.bufferedReader(Charsets.UTF_8).use { it.readText() })
        } finally {
            conn.disconnect()
        }
    }

    private fun buildRequestBody(config: AiConfig, data: NotifData): String {
        val defaultPrompt = "根据通知信息，提取关键信息，左右分别不超过6汉字12字符"
        val userPrompt = if (config.prompt.isNotEmpty()) config.prompt else defaultPrompt

        val userContent = buildString {
            append("应用包名：${data.pkg}\n")
            append("标题：${data.title}\n")
            if (data.subtitle.isNotEmpty()) append("正文：${data.subtitle}")
        }

        val messages = org.json.JSONArray()

        if (config.promptInUser) {
            // 提示词放在用户消息中
            val combinedUserContent = buildString {
                append(userPrompt)
                append("\n\n仅返回如下 JSON，不得包含任何其他文字或代码块：\n")
                append("{\"left\":\"左侧文本（谁发的）\",\"right\":\"右侧文本（总结）\"}\n\n")
                append(userContent)
            }
            messages.put(JSONObject().put("role", "user").put("content", combinedUserContent))
        } else {
            // 提示词放在系统消息中（默认）
            val systemPrompt = """
$userPrompt
仅返回如下 JSON，不得包含任何其他文字或代码块：
{"left":"左侧文本(谁发的)","right":"右侧文本（总结）"}
""".trimIndent()
            messages.put(JSONObject().put("role", "system").put("content", systemPrompt))
            messages.put(JSONObject().put("role", "user").put("content", userContent))
        }

        return JSONObject()
            .put("model", config.model.ifEmpty { "gpt-4o-mini" })
            .put("messages", messages)
            .put("max_tokens", config.maxTokens)
            .put("temperature", config.temperature)
            .toString()
    }

    private fun parseAiResponse(responseText: String): AiIslandText? {
        return try {
            val root    = JSONObject(responseText)
            val content = root.getJSONArray("choices")
                .getJSONObject(0).getJSONObject("message").getString("content").trim()
            val jsonStr = content.removePrefix("```json").removePrefix("```").removeSuffix("```").trim()
            val result  = JSONObject(jsonStr)
            val left    = result.optString("left",  "").trim()
            val right   = result.optString("right", "").trim()
            if (left.isEmpty() && right.isEmpty()) null
            else AiIslandText(left.ifEmpty { "通知" }, right.ifEmpty { "新消息" })
        } catch (e: Exception) {
            logError("$TAG: failed to parse AI response: ${e.message}")
            null
        }
    }

    // ── Dispatcher 路径（focusNotif == "off"）────────────────────────────────

    private fun injectViaDispatcher(
        context: Context,
        data: NotifData,
        displayText: DisplayText,
    ) {
        try {
            val fallbackIcon = Icon.createWithResource(context, android.R.drawable.ic_dialog_info)
            val displayIcon = resolveIslandIcon(data, fallbackIcon).toRounded(context)
            IslandDispatcher.post(
                context,
                IslandRequest(
                    title            = displayText.title,
                    content          = displayText.content,
                    icon             = displayIcon,
                    timeoutSecs      = data.islandTimeout,
                    firstFloat       = data.firstFloat == "on",
                    enableFloat      = data.enableFloatMode == "on",
                    showNotification = false,
                    preserveStatusBarSmallIcon = data.preserveStatusBarSmallIcon != "off",
                    contentIntent    = data.contentIntent,
                    isOngoing        = data.isOngoing,
                    actions          = data.actions.take(2),
                ),
            )
        } catch (e: Exception) {
            logError("$TAG: dispatcher error: ${e.message}")
        }
    }

    // ── 消息处理 ──────────────────────────────────────────────────────────────

    private fun process(
        context: Context,
        data: NotifData,
        displayText: DisplayText = buildDisplayText(
            left = data.title,
            right = data.subtitle,
            fallbackTitle = data.title.ifEmpty { "通知" },
        ),
    ): IslandViewModel {
        val fallbackIcon     = Icon.createWithResource(context, android.R.drawable.ic_dialog_info)
        val islandIcon = resolveIslandIcon(data, fallbackIcon).toRounded(context)
        val focusIcon = resolveFocusIcon(data, fallbackIcon).toRounded(context)
        val showNotification = data.focusNotif != "off"
        val focusTitle = formatIslandTitle(data.title, fallback = displayText.title, maxVisualUnits = 48)
        val focusContent = formatIslandContent(data.subtitle, fallback = focusTitle, maxVisualUnits = 84)

        return IslandViewModel(
            templateId        = TEMPLATE_ID,
            leftTitle         = displayText.title,
            rightTitle        = displayText.content,
            focusTitle        = focusTitle,
            focusContent      = focusContent,
            islandIcon        = islandIcon,
            focusIcon         = focusIcon,
            circularProgress  = null,
            showRightSide     = displayText.content.isNotEmpty(),
            actions           = data.actions,
            updatable         = data.isOngoing,
            showNotification  = showNotification,
            setFocusProxy     = showNotification,
            preserveStatusBarSmallIcon = showNotification && data.preserveStatusBarSmallIcon != "off",
            firstFloat        = data.firstFloat == "on",
            enableFloat       = data.enableFloatMode == "on",
            timeoutSecs       = data.islandTimeout,
            isOngoing         = data.isOngoing,
            showIslandIcon    = data.showIslandIcon == "on",
        )
    }
}
