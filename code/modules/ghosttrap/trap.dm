// This system is used to grab a ghost from observers with the required preferences and
// lack of bans set. See posibrain.dm for an example of how they are called/used. ~Z

GLOBAL_LIST_EMPTY(ghost_traps)
GLOBAL_LIST_EMPTY(ghost_trap_users)

/proc/get_ghost_trap(trap_key)
	if(!length(GLOB.ghost_traps))
		populate_ghost_traps()
	return GLOB.ghost_traps[trap_key]

/proc/get_ghost_traps()
	if(!length(GLOB.ghost_traps))
		populate_ghost_traps()
	return GLOB.ghost_traps

/proc/populate_ghost_traps()
	GLOB.ghost_traps = list()
	for(var/traptype in typesof(/datum/ghosttrap))
		var/datum/ghosttrap/G = new traptype
		GLOB.ghost_traps[G.object] = G

/datum/ghosttrap
	var/object = "positronic brain"
	var/minutes_since_death = 0     // If non-zero the ghost must have been dead for this many minutes to be allowed to spawn
	var/list/ban_checks = list("AI","Robot")
	var/pref_check = BE_SYNTH
	var/ghost_trap_message = "They are occupying a positronic brain now."
	var/ghost_trap_role = "Positronic Brain"
	var/can_set_own_name = TRUE
	var/list_as_special_role = TRUE	// If true, this entry will be listed as a special role in the character setup
	var/can_only_use_once = FALSE // If true, a player can only successfully use a ghost trap of this type once per round
	var/respawn_type = CREW

	var/list/request_timeouts

/datum/ghosttrap/New()
	request_timeouts = list()
	..()

// Check for bans, proper atom types, etc.
/datum/ghosttrap/proc/assess_candidate(mob/observer/ghost/candidate, mob/target, check_respawn_timer=TRUE)
	if(check_respawn_timer)
		if(!candidate.MayRespawn(1, respawn_type ? respawn_type : CREW))
			return 0
	if(islist(ban_checks))
		for(var/bantype in ban_checks)
			if(jobban_isbanned(candidate.ckey, "[bantype]"))
				to_chat(candidate, span_danger("You are banned from one or more required roles and hence cannot enter play as \a [object]."))
				return 0
	if(can_only_use_once && GLOB.ghost_trap_users[candidate.ckey] && (object in GLOB.ghost_trap_users[candidate.ckey]))
		to_chat(candidate, span_danger("You have already entered play as \a [object] during this round."))
		return 0
	return 1

// Print a message to all ghosts with the right prefs/lack of bans.
/datum/ghosttrap/proc/request_player(mob/target, request_string, respawn_type, request_timeout)
	if(request_timeout)
		request_timeouts[target] = world.time + request_timeout
		GLOB.destroyed_event.register(target, src, /datum/ghosttrap/proc/target_destroyed)
	else
		request_timeouts -= target

	for(var/mob/observer/ghost/O in GLOB.player_list)
		src.respawn_type = respawn_type
		if(!O.MayRespawn(0, respawn_type))
			to_chat(O, "[request_string] However, you are not currently able to respawn, and thus are not eligible.")
			continue
		if(islist(ban_checks))
			for(var/bantype in ban_checks)
				if(jobban_isbanned(O.ckey, "[bantype]"))
					to_chat(O, "[request_string] However, you are banned from playing it.")
					continue
		if(pref_check && !(pref_check in O.client.prefs.be_special_role))
			continue

		if(can_only_use_once && GLOB.ghost_trap_users[O.ckey] && (object in GLOB.ghost_trap_users[O.ckey]))
			continue

		if(O.client)
			to_chat(O, "[request_string] <a href='byond://?src=\ref[src];candidate=\ref[O];target=\ref[target]'>(Occupy)</a> [ghost_follow_link(target, O)]")

/datum/ghosttrap/proc/target_destroyed(destroyed_target)
	request_timeouts -= destroyed_target

// Handles a response to request_player().
/datum/ghosttrap/Topic(href, href_list)
	if(..())
		return 1
	if(href_list["candidate"] && href_list["target"])
		var/mob/observer/ghost/candidate = locate(href_list["candidate"]) // BYOND magic.
		var/mob/target = locate(href_list["target"])                     // So much BYOND magic.
		if(!target || !candidate || !ismob(target) || !isghost(candidate))
			return
		if(candidate != usr)
			return
		if(request_timeouts[target] && world.time > request_timeouts[target])
			to_chat(candidate, "This occupation request is no longer valid.")
			return
		if(target.key)
			to_chat(candidate, "The target is already occupied.")
			return
		if(assess_candidate(candidate, target) && target.can_be_possessed_by(candidate, FALSE))
			transfer_personality(candidate,target)
		return 1

// Shunts the ckey/mind into the target mob.
/datum/ghosttrap/proc/transfer_personality(mob/candidate, mob/target, check_respawn_timer=TRUE)
	if(!assess_candidate(candidate, target))
		return 0

	// Mark that the player has already used this type of ghost trap
	if(can_only_use_once)
		if(GLOB.ghost_trap_users[candidate.ckey])
			GLOB.ghost_trap_users[candidate.ckey] |= object
		else
			GLOB.ghost_trap_users[candidate.ckey] = list(object)

	target.ckey = candidate.ckey
	if(target.mind)
		target.mind.assigned_role = "[ghost_trap_role]"
	announce_ghost_joinleave(candidate, 0, "[ghost_trap_message]")
	welcome_candidate(target)
	set_new_name(target)
	return 1

// Fluff!
/datum/ghosttrap/proc/welcome_candidate(mob/target)
	to_chat(target, "<b>You are a positronic brain, brought into existence on [station_name()].</b>")
	to_chat(target, "<b>As a synthetic intelligence, you answer to all crewmembers, as well as the AI.</b>")
	to_chat(target, "<b>Remember, the purpose of your existence is to serve the crew and the ship. Above all else, do no harm.</b>")
	to_chat(target, "<b>Use say [target.get_language_prefix()]b to speak to other artificial intelligences.</b>")
	var/turf/T = get_turf(target)
	var/obj/item/device/mmi/digital/posibrain/P = target.loc
	T.visible_message(span_notice("\The [P] chimes quietly."))
	if(!istype(P)) //wat
		return
	P.searching = 0
	P.name = "positronic brain ([P.brainmob.name])"
	P.icon_state = "posibrain-occupied"

// Allows people to set their own name. May or may not need to be removed for posibrains if people are dumbasses.
/datum/ghosttrap/proc/set_new_name(mob/target)
	if(!can_set_own_name)
		return

	var/newname = sanitizeSafe(input(target,"Enter a name, or leave blank for the default name.", "Name change","") as text, MAX_NAME_LEN)
	if (newname != "")
		target.real_name = newname
		target.name = target.real_name

/*****************
* Cortical Borer *
*****************/
/datum/ghosttrap/borer
	object = "cortical borer"
	ban_checks = list("Borer")
	pref_check = ROLE_BORER
	ghost_trap_message = "They are occupying a borer now."
	ghost_trap_role = "Cortical Borer"
	can_set_own_name = FALSE
	list_as_special_role = FALSE
	can_only_use_once = TRUE // No endless free respawns

/datum/ghosttrap/borer/welcome_candidate(mob/target)
	to_chat(target, "[span_notice("You are a cortical borer!")] You are a brain slug that worms its way \
	into the head of its victim. Use stealth, persuasion and your powers of mind control to keep you, \
	your host and your eventual spawn safe and warm.")
	to_chat(target, "You can speak to your victim with <b>say</b>, to other borers with <b>say [target.get_language_prefix()]x</b>, and use your Abilities tab to access powers.")

/********************
* Maintenance Drone *
*********************/
/datum/ghosttrap/drone
	object = "maintenance drone"
	pref_check = BE_PAI
	ghost_trap_message = "They are occupying a maintenance drone now."
	ghost_trap_role = "Maintenance Drone"
	can_set_own_name = FALSE
	list_as_special_role = FALSE

/datum/ghosttrap/drone/New()
	minutes_since_death = DRONE_SPAWN_DELAY
	..()

/datum/ghosttrap/drone/assess_candidate(mob/observer/ghost/candidate, mob/target, check_respawn_timer)
	. = ..()
	if(. && !target.can_be_possessed_by(candidate))
		return 0

/datum/ghosttrap/drone/transfer_personality(mob/candidate, mob/living/silicon/robot/drone/drone, check_respawn_timer)
	if(!assess_candidate(candidate))
		return 0
	drone.transfer_personality(candidate.client)

/**************
* personal AI *
**************/
/datum/ghosttrap/pai
	object = "pAI"
	pref_check = BE_PAI
	ghost_trap_message = "They are occupying a pAI now."
	ghost_trap_role = "pAI"

/datum/ghosttrap/pai/assess_candidate(mob/observer/ghost/candidate, mob/target, check_respawn_timer)
	return 0

/datum/ghosttrap/pai/transfer_personality(mob/candidate, mob/living/silicon/robot/drone/drone, check_respawn_timer)
	return 0

/**************
*  Blitzshell *
**************/
/datum/ghosttrap/blitzdrone
	object = "blitzshell drone"
	pref_check = ROLE_BLITZ
	ghost_trap_message = "They have become a Blitzshell drone now."
	ghost_trap_role = "Blitzshell Drone."
	can_set_own_name = FALSE
	list_as_special_role = FALSE
	can_only_use_once = TRUE
