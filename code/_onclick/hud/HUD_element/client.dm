/client
	var/list/atom/movable/hud_elements //stores all elements shown to client, association list with index being element identifier

/client/proc/hide_HUD_element(identifier)
	if (!hud_elements)
		return

	var/atom/movable/hud_element/E = hud_elements[identifier]
	if (E)
		E.hide()

/client/proc/show_HUD_element(identifier)
	if (!hud_elements)
		return

	var/atom/movable/hud_element/E = hud_elements[identifier]
	if (E)
		E.show(src)
