package io.github.hyperisland.xposed.template.renderer

import android.content.Context
import android.os.Bundle
import io.github.hyperisland.xposed.template.IslandViewModel

object ImageTextWithButtonsWrapRenderer : IslandRenderer {

    const val RENDERER_ID = "image_text_with_buttons_4_wrap"

    override val id = RENDERER_ID

    override fun render(context: Context, extras: Bundle, vm: IslandViewModel) {
        ImageTextWithButtonsRenderer.renderWith(context, extras, vm, applyWrap = true)
    }
}
