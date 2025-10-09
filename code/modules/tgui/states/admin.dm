/*!
 * Copyright (c) 2020 Aleksej Komarov
 * SPDX-License-Identifier: MIT
 */

/**
 * tgui state: admin_state
 *
 * Checks if the user has specific admin permissions.
 */

GLOBAL_LIST_EMPTY_TYPED(admin_states, /datum/ui_state/admin_state)
GLOBAL_PROTECT(admin_states)
GLOBAL_DATUM_INIT(explicit_admin_states, /alist, alist())
GLOBAL_PROTECT(explicit_admin_states)

/datum/ui_state/admin_state
	/// The specific admin permissions required for the UI using this state.
	VAR_FINAL/required_perms = R_ADMIN
	VAR_FINAL/explicit_check = FALSE

/datum/ui_state/admin_state/New(required_perms = R_ADMIN, explicit_check = FALSE)
	. = ..()
	src.required_perms = required_perms
	src.explicit_check = explicit_check

/datum/ui_state/admin_state/can_use_topic(src_object, mob/user)
	var/has_perms = explicit_check ? check_exact_rights_for(user.client, required_perms) : check_rights_for(user.client, required_perms)
	return has_perms ? UI_INTERACTIVE : UI_CLOSE

/datum/ui_state/admin_state/vv_edit_var(var_name, var_value)
	if(var_name == NAMEOF(src, required_perms))
		return FALSE
	return ..()
