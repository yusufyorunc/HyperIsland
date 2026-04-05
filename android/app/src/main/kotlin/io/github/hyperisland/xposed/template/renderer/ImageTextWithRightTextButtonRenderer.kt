package io.github.hyperisland.xposed.template.renderer

import android.content.Context
import android.os.Bundle
import io.github.hyperisland.xposed.template.IslandViewModel

object ImageTextWithRightTextButtonRenderer : IslandRenderer {

    const val RENDERER_ID = "image_text_with_right_text_button"

    override val id = RENDERER_ID

    override fun render(context: Context, extras: Bundle, vm: IslandViewModel) {
        ImageTextWithButtonsRenderer.renderWith(
            context,
            extras,
            vm,
            applyWrap = false,
            maxButtons = 1,
            useActionsButton = true
        )
    }
}
