/datum/admin_secret_item/admin_secret/bombing_list
	name = "Bombing List"

/datum/admin_secret_item/admin_secret/bombing_list/execute(mob/user)
	. = ..()
	if(!.)
		return

	var/dat = "<B>Bombing List</B>"
	for(var/l in GLOB.bombers)
		dat += text("[l]<BR>")
	user << browse(HTML_SKELETON_TITLE("Bombing List", dat), "window=bombers")
