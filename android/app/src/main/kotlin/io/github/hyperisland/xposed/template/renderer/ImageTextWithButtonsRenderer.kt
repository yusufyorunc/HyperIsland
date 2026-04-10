package io.github.hyperisland.xposed.template.renderer

import android.app.Notification
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.util.Log
import io.github.d4viddf.hyperisland_kit.HyperAction
import io.github.d4viddf.hyperisland_kit.HyperIslandNotification
import io.github.d4viddf.hyperisland_kit.HyperPicture
import io.github.d4viddf.hyperisland_kit.models.CircularProgressInfo
import io.github.d4viddf.hyperisland_kit.models.ImageTextInfoLeft
import io.github.d4viddf.hyperisland_kit.models.ImageTextInfoRight
import io.github.d4viddf.hyperisland_kit.models.PicInfo
import io.github.d4viddf.hyperisland_kit.models.ProgressTextInfo
import io.github.d4viddf.hyperisland_kit.models.TextInfo
import io.github.hyperisland.xposed.hook.FocusNotifStatusBarIconHook
import io.github.hyperisland.xposed.template.IslandViewModel

object ImageTextWithButtonsRenderer : IslandRenderer {

    const val RENDERER_ID = "image_text_with_buttons_4"
    private const val ACTION_TITLE_MAX_VISUAL_LENGTH = 16
    private const val ACTION_TITLE_TRUNCATE_VISUAL_LENGTH = 12
    private const val ACTION_SEMANTIC_NONE = 0

    private val ACTION_TITLE_WHITESPACE = Regex("\\s+")

    private data class DisplayAction(
        val action: Notification.Action,
        val title: String,
    )

    override val id = RENDERER_ID

    override fun render(context: Context, extras: Bundle, vm: IslandViewModel) {
        renderWith(context, extras, vm, applyWrap = false)
    }

    private fun visualLength(text: String): Int {
        var length = 0
        for (ch in text) length += if (ch.code > 255) 2 else 1
        return length
    }

    private fun truncateByVisualLength(text: String): String {
        val out = StringBuilder(text.length)
        var visual = 0
        for (ch in text) {
            val width = if (ch.code > 255) 2 else 1
            if (visual + width > ACTION_TITLE_TRUNCATE_VISUAL_LENGTH) break
            out.append(ch)
            visual += width
        }
        return out.toString().trimEnd()
    }

    private fun compactActionTitle(raw: String): String {
        val collapsed = raw.replace(ACTION_TITLE_WHITESPACE, " ").trim()
        if (collapsed.isEmpty()) return ""
        if (visualLength(collapsed) <= ACTION_TITLE_MAX_VISUAL_LENGTH) return collapsed

        val firstWord = collapsed.substringBefore(' ').trim()
        if (firstWord.isNotEmpty() && visualLength(firstWord) <= ACTION_TITLE_MAX_VISUAL_LENGTH) {
            return firstWord
        }

        val short = truncateByVisualLength(collapsed)
        return if (short.isNotEmpty()) "$short..." else ""
    }

    private fun semanticFallbackTitle(context: Context, action: Notification.Action): String {
        val language = context.resources.configuration.locales[0]?.language.orEmpty()
        val isTurkish = language.equals("tr", ignoreCase = true)

        fun pick(tr: String, en: String): String = if (isTurkish) tr else en

        val semantic = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            action.semanticAction
        } else {
            ACTION_SEMANTIC_NONE
        }

        return when (semantic) {
            Notification.Action.SEMANTIC_ACTION_REPLY -> pick("Cevapla", "Reply")
            Notification.Action.SEMANTIC_ACTION_MARK_AS_READ -> pick("Okundu", "Read")
            Notification.Action.SEMANTIC_ACTION_MARK_AS_UNREAD -> pick("Okunmadi", "Unread")
            Notification.Action.SEMANTIC_ACTION_DELETE -> pick("Sil", "Delete")
            Notification.Action.SEMANTIC_ACTION_ARCHIVE -> pick("Arsiv", "Archive")
            Notification.Action.SEMANTIC_ACTION_MUTE -> pick("Sessiz", "Mute")
            Notification.Action.SEMANTIC_ACTION_UNMUTE -> pick("Sesli", "Unmute")
            else -> if (!action.remoteInputs.isNullOrEmpty()) pick("Cevapla", "Reply") else ""
        }
    }

    private fun actionTitleForDisplay(context: Context, action: Notification.Action): String {
        val direct = compactActionTitle(action.title?.toString().orEmpty())
        if (direct.isNotEmpty()) return direct
        return semanticFallbackTitle(context, action)
    }

    private fun buildDisplayActions(
        context: Context,
        actions: List<Notification.Action>,
    ): List<DisplayAction> {
        return actions.mapNotNull { action ->
            if (action.actionIntent == null) return@mapNotNull null
            val title = actionTitleForDisplay(context, action)
            if (title.isEmpty()) return@mapNotNull null
            DisplayAction(action = action, title = title)
        }
    }

    private fun pickActionForRightTextButton(
        actions: List<DisplayAction>,
    ): DisplayAction {
        return actions.firstOrNull { it.action.remoteInputs.isNullOrEmpty() } ?: actions.first()
    }

    internal fun renderWith(
        context: Context,
        extras: Bundle,
        vm: IslandViewModel,
        applyWrap: Boolean,
        maxButtons: Int = 2,
        useActionsButton: Boolean = false,
    ) {
        try {
            val iconKey = "key_${vm.templateId}_island"
            val focusIconKey = "key_${vm.templateId}_focus"

            val builder = HyperIslandNotification.Builder(context, vm.templateId, vm.focusTitle)

            builder.addPicture(HyperPicture(iconKey, vm.islandIcon))
            builder.addPicture(HyperPicture(focusIconKey, vm.focusIcon))

            builder.setIconTextInfo(
                picKey = focusIconKey,
                title = vm.focusTitle,
                content = vm.focusContent,
            )

            builder.setIslandFirstFloat(vm.firstFloat)
            builder.setEnableFloat(vm.enableFloat)
            builder.setShowNotification(vm.showNotification)
            builder.setIslandConfig(timeout = vm.timeoutSecs)
            if (vm.circularProgress != null) {
                builder.setSmallIslandCircularProgress(iconKey, vm.circularProgress)
            } else {
                builder.setSmallIsland(iconKey)
            }
            val leftSide = if (!vm.showIslandIcon) {
                ImageTextInfoLeft(
                    type = 1,
                    textInfo = TextInfo(
                        title = vm.leftTitle,
                        showHighlightColor = vm.showLeftHighlightColor
                    ),
                )
            } else {
                ImageTextInfoLeft(
                    type = 1,
                    picInfo = PicInfo(type = 1, pic = iconKey),
                    textInfo = TextInfo(
                        title = vm.leftTitle,
                        showHighlightColor = vm.showLeftHighlightColor
                    ),
                )
            }
            when {
                vm.circularProgress != null -> builder.setBigIslandInfo(
                    left = leftSide,
                    progressText = ProgressTextInfo(
                        progressInfo = CircularProgressInfo(progress = vm.circularProgress),
                        textInfo = TextInfo(
                            title = vm.rightTitle,
                            narrowFont = true,
                            showHighlightColor = vm.showRightHighlightColor
                        ),
                    ),
                )

                vm.showRightSide -> builder.setBigIslandInfo(
                    left = leftSide,
                    right = ImageTextInfoRight(
                        type = 2,
                        textInfo = TextInfo(
                            title = vm.rightTitle,
                            narrowFont = true,
                            showHighlightColor = vm.showRightHighlightColor
                        ),
                    ),
                )

                else -> builder.setBigIslandInfo(left = leftSide)
            }

            val candidateActions = buildDisplayActions(context, vm.actions)
            if (candidateActions.isNotEmpty() && vm.showNotification) {
                if (useActionsButton) {
                    val action = pickActionForRightTextButton(candidateActions)
                    builder.addAction(
                        HyperAction(
                            key = "action_${vm.templateId}_0",
                            title = action.title,
                            pendingIntent = action.action.actionIntent,
                            actionIntentType = 2,
                        )
                    )
                } else {
                    val effectiveActions = candidateActions.take(maxButtons)
                    val hyperActions = effectiveActions.mapIndexed { index, action ->
                        HyperAction(
                            key = "action_${vm.templateId}_$index",
                            title = action.title,
                            pendingIntent = action.action.actionIntent,
                            actionIntentType = 2,
                        )
                    }
                    hyperActions.forEach { builder.addHiddenAction(it) }
                    builder.setTextButtons(*hyperActions.toTypedArray())
                }
            }

            val resourceBundle = builder.buildResourceBundle()
            extras.putAll(resourceBundle)
            flattenActionsToExtras(resourceBundle, extras)

            var jsonParam = fixTextButtonJson(builder.buildJsonParam())
            if (applyWrap) jsonParam = wrapLongTextJson(jsonParam)
            jsonParam = injectUpdatable(jsonParam, vm.updatable)
            jsonParam = injectHighlightColor(jsonParam, vm.highlightColor)
            jsonParam = injectOuterGlow(jsonParam, vm.outerGlow)
            extras.putString("miui.focus.param", jsonParam)

            if (vm.setFocusProxy && vm.showNotification) {
                extras.putBoolean("hyperisland_focus_proxy", true)
            }
            if (vm.preserveStatusBarSmallIcon && vm.showNotification) {
                extras.putBoolean("hyperisland_preserve_status_bar_small_icon", true)
                FocusNotifStatusBarIconHook.markDirectProxyPosted(vm.timeoutSecs)
            }

            val rendererTag = when {
                applyWrap -> ImageTextWithButtonsWrapRenderer.RENDERER_ID
                useActionsButton -> ImageTextWithRightTextButtonRenderer.RENDERER_ID
                else -> RENDERER_ID
            }
            Log.d("HyperIsland", "HyperIsland[$rendererTag]: rendered template=${vm.templateId}")
        } catch (e: Exception) {
            Log.d("HyperIsland", "HyperIsland[$RENDERER_ID]: render error: ${e.message}")
        }
    }
}
