/datum/preferences
	var/list/never_be_special_role
	var/list/be_special_role

/datum/category_item/player_setup_item/antagonism/candidacy
	name = "Candidacy"
	sort_order = 1

/datum/category_item/player_setup_item/antagonism/candidacy/load_character(savefile/S)
	from_file(S["be_special"],           pref.be_special_role)
	from_file(S["never_be_special"],     pref.never_be_special_role)

/datum/category_item/player_setup_item/antagonism/candidacy/save_character(savefile/S)
	to_file(S["be_special"],             pref.be_special_role)
	to_file(S["never_be_special"],       pref.never_be_special_role)

/datum/category_item/player_setup_item/antagonism/candidacy/sanitize_character()
	if(!istype(pref.be_special_role))
		pref.be_special_role = list()
	if(!istype(pref.never_be_special_role))
		pref.never_be_special_role = list()

	var/special_roles = valid_special_roles()
	var/old_be_special_role = pref.be_special_role.Copy()
	var/old_never_be_special_role = pref.never_be_special_role.Copy()
	for(var/role in old_be_special_role)
		if(!(role in special_roles))
			pref.be_special_role -= role
	for(var/role in old_never_be_special_role)
		if(!(role in special_roles))
			pref.never_be_special_role -= role

/datum/category_item/player_setup_item/antagonism/candidacy/content(mob/user)
	. = list()
	. += "<b>Special Role Availability:</b><br>"
	. += "<table>"

	var/list/bantypes
	for(var/A in GLOB.all_antag_selectable_types)
		var/datum/antagonist/antag = GLOB.all_antag_selectable_types[A]

		//Multiple antags can share one bantype, we only want it to be shown once
		if (antag.bantype in bantypes)
			continue

		bantypes += antag.bantype
		. += "<tr><td>[antag.bantype]: </td><td>"
		if(jobban_isbanned(preference_mob(), antag.bantype) || (antag.id == ROLE_MALFUNCTION && jobban_isbanned(preference_mob(), "AI")))
			. += "[span_danger("\[BANNED\]")]<br>"
		else if(antag.bantype in pref.be_special_role)
			. += "[span_linkOn("Yes")] <a href='byond://?src=\ref[src];add_never=[antag.bantype]'>Never</a></br>"
		else if(antag.bantype in pref.never_be_special_role)
			. += "<a href='byond://?src=\ref[src];add_special=[antag.bantype]'>Yes</a> [span_linkOn("Never")]</br>"
		else
			. += "<a href='byond://?src=\ref[src];add_special=[antag.bantype]'>Yes</a> <a href='byond://?src=\ref[src];add_never=[antag.bantype]'>Never</a></br>"
		. += "</td></tr>"

	var/list/ghost_traps = get_ghost_traps()
	for(var/ghost_trap_key in ghost_traps)
		var/datum/ghosttrap/ghost_trap = ghost_traps[ghost_trap_key]
		if(!ghost_trap.list_as_special_role)
			continue

		. += "<tr><td>[ghost_trap.ghost_trap_role]: </td><td>"
		if(banned_from_ghost_role(preference_mob(), ghost_trap))
			. += "[span_danger("\[BANNED\]")]<br>"
		else if(ghost_trap.pref_check in pref.be_special_role)
			. += "[span_linkOn("Yes")]  <a href='byond://?src=\ref[src];add_never=[ghost_trap.pref_check]'>Never</a></br>"
		else if(ghost_trap.pref_check in pref.never_be_special_role)
			. += "<a href='byond://?src=\ref[src];add_special=[ghost_trap.pref_check]'>Yes</a>  [span_linkOn("Never")]</br>"
		else
			. += "<a href='byond://?src=\ref[src];add_special=[ghost_trap.pref_check]'>Yes</a><a href='byond://?src=\ref[src];add_never=[ghost_trap.pref_check]'>Never</a></br>"
		. += "</td></tr>"
	. += "<tr><td>Select All: </td><td><a href='byond://?src=\ref[src];select_all=1'>Yes</a> <a href='byond://?src=\ref[src];select_all=0'>Never</a></td></tr>"
	. += "</table>"
	. = jointext(.,null)

/datum/category_item/player_setup_item/proc/banned_from_ghost_role(mob, datum/ghosttrap/ghost_trap)
	for(var/ban_type in ghost_trap.ban_checks)
		if(jobban_isbanned(mob, ban_type))
			return 1
	return 0

/datum/category_item/player_setup_item/antagonism/candidacy/OnTopic(href,list/href_list, mob/user)
	if(href_list["add_special"])
		if(!(href_list["add_special"] in valid_special_roles(FALSE)))
			return TOPIC_HANDLED
		pref.be_special_role |= href_list["add_special"]
		pref.never_be_special_role -= href_list["add_special"]
		return TOPIC_REFRESH

	if(href_list["del_special"])
		if(!(href_list["del_special"] in valid_special_roles(FALSE)))
			return TOPIC_HANDLED
		pref.be_special_role -= href_list["del_special"]
		pref.never_be_special_role -= href_list["del_special"]
		return TOPIC_REFRESH

	if(href_list["add_never"])
		pref.be_special_role -= href_list["add_never"]
		pref.never_be_special_role |= href_list["add_never"]
		return TOPIC_REFRESH

	if(href_list["select_all"])
		var/selection = text2num(href_list["select_all"])
		var/list/roles = valid_special_roles(FALSE)

		for(var/id in roles)
			switch(selection)
				if(0)
					pref.be_special_role -= id
					pref.never_be_special_role |= id
				if(1)
					pref.be_special_role |= id
					pref.never_be_special_role -= id
		return TOPIC_REFRESH

	return ..()

/datum/category_item/player_setup_item/antagonism/candidacy/proc/valid_special_roles(include_bans = TRUE)
	var/list/private_valid_special_roles = list()
	for(var/A in GLOB.all_antag_selectable_types)
		var/datum/antagonist/antag = GLOB.all_antag_selectable_types[A]
		if(!include_bans)
			if(jobban_isbanned(preference_mob(), antag.bantype))
				continue
			if(((antag.id  == ROLE_MALFUNCTION) && jobban_isbanned(preference_mob(), "AI")))
				continue
		private_valid_special_roles += antag.bantype

	var/list/ghost_traps = get_ghost_traps()
	for(var/ghost_trap_key in ghost_traps)
		var/datum/ghosttrap/ghost_trap = ghost_traps[ghost_trap_key]
		if(!ghost_trap.list_as_special_role)
			continue
		if(!include_bans)
			if(banned_from_ghost_role(preference_mob(), ghost_trap))
				continue
		private_valid_special_roles += ghost_trap.pref_check


	return private_valid_special_roles

/client/proc/wishes_to_be_role(role)
	if(!prefs)
		return FALSE
	if(role in prefs.be_special_role)
		return 2
	if(role in prefs.never_be_special_role)
		return FALSE
	return 1	//Default to "sometimes" if they don't opt-out.
