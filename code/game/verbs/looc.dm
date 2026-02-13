/client/verb/looc(msg as text)
	set name = "LOOC"
	set desc = "Local OOC, seen only by those in view."
	set category = "OOC"

	if(GLOB.say_disabled)	//This is here to try to identify lag problems
		to_chat(usr, span_danger("Speech is currently admin-disabled."))
		return

	if(!mob)
		return

	VALIDATE_CLIENT(src)

	if(IsGuestKey(key))
		to_chat(src, "Guests may not use OOC.")
		return

	msg = sanitize(msg)
	if(!msg)
		return

	if(src.get_preference_value(/datum/client_preference/show_looc) == GLOB.PREF_HIDE)
		to_chat(src, span_danger("You have LOOC muted."))
		return

	if(!holder)
		if(!GLOB.looc_allowed)
			to_chat(src, span_danger("LOOC is globally muted."))
			return
		if(!GLOB.dooc_allowed && (mob.stat == DEAD))
			to_chat(usr, span_danger("LOOC for dead mobs has been turned off."))
			return
		if(prefs.muted & MUTE_OOC)
			to_chat(src, span_danger("You cannot use LOOC (muted)."))
			return
		if(handle_spam_prevention(msg, MUTE_OOC))
			return

	log_ooc("(LOCAL) [mob.name]/[key] : [msg]")

	var/mob/source = mob.get_looc_source()

	var/turf/T = get_turf(source)
	var/list/listening = list()
	listening |= src	// We can always hear ourselves.
	var/list/listening_obj = list()
	var/list/eye_heard = list()

		// This is essentially a copy/paste from living/say() the purpose is to get mobs inside of objects without recursing through
		// the contents of every mob and object in get_mobs_or_objects_in_view() looking for PAI's inside of the contents of a bag inside the
		// contents of a mob inside the contents of a welded shut locker we essentially get a list of turfs and see if the mob is on one of them.

	if(T)
		var/list/hear = hear(7,T)
		var/list/hearturfs = list()

		for(var/I in hear)
			if(ismob(I))
				var/mob/M = I
				listening |= M.client
				hearturfs += M.locs[1]
			else if(isobj(I))
				var/obj/O = I
				hearturfs |= O.locs[1]
				listening_obj |= O

		for(var/mob/M in GLOB.player_list)
			if(M.get_preference_value(/datum/client_preference/show_ooc) == GLOB.PREF_HIDE)
				continue
			if(isAI(M))
				var/mob/living/silicon/ai/A = M
				if(A.eyeobj && (A.eyeobj.locs[1] in hearturfs))
					eye_heard |= M.client
					listening |= M.client
					continue

			if(M.loc && (M.locs[1] in hearturfs))
				listening |= M.client


	for(var/client/hearer in listening)
		var/prefix = ""
		if(isAI(hearer.mob))
			if(hearer in eye_heard)
				prefix = "(Eye) "
			else
				prefix = "(Core) "
		to_chat(hearer, span_looc("[span_prefix("LOOC:")] [span_prefix(prefix)]<EM>[span_name("[mob.name]")]:</EM> <span class='message linkify'>[msg]</span>"), type = MESSAGE_TYPE_LOOC, avoid_highlighting = (hearer == mob))
		if(hearer.prefs.RC_see_looc_on_map)
			hearer.mob?.create_chat_message(mob, /datum/language/common, "\[LOOC: [msg]\]", runechat_flags = LOOC_MESSAGE)

	for(var/client/client in GLOB.admins)	//Now send to all admins that weren't in range.
		if(!(client in listening) && client.get_preference_value(/datum/client_preference/staff/show_rlooc) == GLOB.PREF_SHOW)
			var/prefix = "[listening[client] ? "" : "(R)"]LOOC"
			if(client.prefs.RC_see_looc_on_map)
				client.mob?.create_chat_message(mob, /datum/language/common, "\[LOOC: [msg]\]", runechat_flags = LOOC_MESSAGE)
			to_chat(client, span_looc("[span_prefix("[prefix]:")] <EM>[ADMIN_LOOKUPFLW(mob)]:</EM> <span class='message linkify'>[msg]</span>"), type = MESSAGE_TYPE_LOOC, avoid_highlighting = (client == src))

/mob/proc/get_looc_source()
	return src

/mob/living/silicon/ai/get_looc_source()
	if(eyeobj)
		return eyeobj
	return src
