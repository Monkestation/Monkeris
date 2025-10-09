/*

*/

/atom/movable/hud_element/button/thin/New(id, filename = 'icons/mob/screen/ErisStyle_32x32.dmi')
	. = ..()
	setIconAddition(HUD_ICON_UNDERLAY, "background", filename, "button_thin_bg")
	setIconAddition(HUD_ICON_OVERLAY, HUD_OVERLAY_FRAME, filename,"button_thin_rim")
	setIconAddition(HUD_ICON_OVERLAY, "lights", filename, "button_thin_lights")

/atom/movable/hud_element/button/thick/New(id, filename = 'icons/mob/screen/ErisStyle_32x32.dmi')
	. = ..()
	setIconAddition(HUD_ICON_UNDERLAY, HUD_UNDERLAY_BACKGROUND, filename, "button_thick_bg")
	setIconAddition(HUD_ICON_OVERLAY, HUD_OVERLAY_FRAME, filename, "button_thick_rim")
	setIconAddition(HUD_ICON_OVERLAY, "lights", filename, "button_thick_lights")

/atom/movable/hud_element/button/thin/ai/New(id, filename = 'icons/mob/screen/silicon/AI/HUD_actionButtons.dmi')
	. = ..()

/atom/movable/hud_element/button/thick/ai/New(id, filename = 'icons/mob/screen/silicon/AI/HUD_actionButtons.dmi')
	. = ..()
