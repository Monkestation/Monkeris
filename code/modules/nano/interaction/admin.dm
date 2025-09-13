/*
	This state checks that the user is an admin, end of story
*/
GLOBAL_DATUM_INIT(admin_state, /datum/nano_topic_state/admin_state, new)

/datum/nano_topic_state/admin_state
	VAR_FINAL/required_perms = R_ADMIN
	VAR_FINAL/explicit_check = FALSE

/datum/nano_topic_state/admin_state/can_use_topic(src_object, mob/user)
	var/has_perms = explicit_check ? check_exact_rights_for(user.client, required_perms) : check_rights_for(user.client, required_perms)
	return has_perms ? STATUS_INTERACTIVE : STATUS_CLOSE
