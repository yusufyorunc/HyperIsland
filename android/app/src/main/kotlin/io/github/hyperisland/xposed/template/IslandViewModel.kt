package io.github.hyperisland.xposed.template

import android.app.Notification
import android.graphics.drawable.Icon

data class IslandViewModel(
    val templateId: String = "island",
    val leftTitle: String = "",
    val rightTitle: String = "",
    val focusTitle: String,
    val focusContent: String,
    val islandIcon: Icon,
    val focusIcon: Icon,
    val circularProgress: Int? = null,
    val showRightSide: Boolean = true,
    val actions: List<Notification.Action> = emptyList(),
    val updatable: Boolean = false,
    val showNotification: Boolean = true,
    val setFocusProxy: Boolean = false,
    val preserveStatusBarSmallIcon: Boolean = false,
    val firstFloat: Boolean = false,
    val enableFloat: Boolean = false,
    val timeoutSecs: Int = 5,
    val isOngoing: Boolean = false,
    val showIslandIcon: Boolean = true,
    val highlightColor: String? = null,
    val showLeftHighlightColor: Boolean = false,
    val showRightHighlightColor: Boolean = false,
    val outerGlow: Boolean = false,
)
