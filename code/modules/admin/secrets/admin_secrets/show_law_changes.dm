/datum/admin_secret_item/admin_secret/show_law_changes
	name = "Show law changes"

/datum/admin_secret_item/admin_secret/show_law_changes/name()
	return "Show Last [length(GLOB.lawchanges)] Law change\s"

/datum/admin_secret_item/admin_secret/show_law_changes/execute(mob/user)
	. = ..()
	if(!.)
		return

	var/dat = "<B>Showing last [length(GLOB.lawchanges)] law changes.</B><HR>"
	for(var/sig in GLOB.lawchanges)
		dat += "[sig]<BR>"
	user << browse(HTML_SKELETON_TITLE("Law changes", dat), "window=lawchanges;size=800x500")
