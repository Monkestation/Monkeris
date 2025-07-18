/*
	This state checks that the user is an admin, end of story
*/
GLOBAL_DATUM_INIT(admin_state, /datum/nano_topic_state/admin_state, new)

/datum/nano_topic_state/admin_state/can_use_topic(src_object, mob/user)
	return check_rights(R_ADMIN, 0, user) ? STATUS_INTERACTIVE : STATUS_CLOSE
