
GLOBAL_VAR_INIT(OOC_COLOR, "#cca300")//If this is null, use the CSS for OOC. Otherwise, use a custom colour.
GLOBAL_VAR_INIT(normal_ooc_colour, "#002eb8")

/client/verb/ooc(msg as text)
	set name = "OOC"
	set category = "OOC"

	if(GLOB.say_disabled)	//This is here to try to identify lag problems
		to_chat(usr, span_warning("Speech is currently admin-disabled."))
		return

	if(!mob)	return

	VALIDATE_CLIENT(src)

	if(IsGuestKey(key))
		to_chat(src, "Guests may not use OOC.")
		return

	msg = sanitize(msg)
	if(!msg)	return

	if(src.get_preference_value(/datum/client_preference/show_ooc) == GLOB.PREF_HIDE)
		to_chat(src, span_warning("You have OOC muted."))
		return

	if(!holder)
		if(!GLOB.ooc_allowed)
			to_chat(src, span_danger("OOC is globally muted."))
			return
		if(!GLOB.dooc_allowed && (mob.stat == DEAD))
			to_chat(usr, span_danger("OOC for dead mobs has been turned off."))
			return
		if(prefs.muted & MUTE_OOC)
			to_chat(src, span_danger("You cannot use OOC (muted)."))
			return
		if(handle_spam_prevention(msg,MUTE_OOC))
			return

	log_ooc("[mob.name]/[key] : [msg]")

	msg = emoji_parse(msg)

	var/keyname = key
	if(!!IsByondMember())
		// if(prefs.toggles & MEMBER_PUBLIC)
		keyname = "<font color='[src.prefs.ooccolor || GLOB.normal_ooc_colour]'>[icon2html('icons/ui_icons/chat/member_content.dmi', world, "blag")][keyname]</font>"
	// var/ooc_style = "everyone"
	// if(holder && !holder.fakekey)
	// 	ooc_style = "elevated"
	// 	if(holder.rights & R_DEBUG)
	// 		ooc_style = "developer"
	// 	if(holder.rights & R_ADMIN)
	// 		ooc_style = "admin"


	// for(var/client/target in GLOB.clients)
	// 	if(target.get_preference_value(/datum/client_preference/show_ooc) != GLOB.PREF_SHOW)
	// 		continue
	// 	var/display_name = src.key
	// 	if(holder)
	// 		if(holder.fakekey)
	// 			if(target.holder)
	// 				display_name = "[holder.fakekey]/([src.key])"
	// 			else
	// 				display_name = holder.fakekey
	// 	if(holder && !holder.fakekey && (holder.rights & R_ADMIN) && config.allow_admin_ooccolor && (src.prefs.ooccolor != initial(src.prefs.ooccolor))) // keeping this for the badmins
	// 		to_chat(target, span_ooc("" + create_text_tag("ooc", "OOC:", target) + " <font color='[src.prefs.ooccolor]'><EM>[display_name]:</EM></font> <span class='[ooc_style]'><span class='message linkify'>[msg]</span></span>"))
	// 	else
	// 		to_chat(target, span_ooc("<span class='[ooc_style]'>" + create_text_tag("ooc", "OOC:", target) + " <EM>[display_name]:</EM> <span class='message linkify'>[msg]</span></span>"))
	for(var/client/receiver as anything in GLOB.clients)
		if(!receiver.prefs) // Client being created or deleted. Despite all, this can be null.
			continue
		if(receiver.get_preference_value(/datum/client_preference/show_ooc) != GLOB.PREF_SHOW)
			continue
		if(holder?.fakekey in receiver.prefs.ignored_players)
			continue
		var/avoid_highlight = receiver == src
		if(holder)
			if(!holder.fakekey || receiver.holder)
				if(check_rights_for(src, R_ADMIN))
					var/ooc_color = src.prefs.ooccolor
					to_chat(receiver, span_adminooc("[CONFIG_GET(flag/allow_admin_ooccolor) && ooc_color ? "<font color=[ooc_color]>" :"" ][span_prefix("OOC:")] <EM>[keyname][holder.fakekey ? "/([holder.fakekey])" : ""]:</EM> <span class='message linkify'>[msg]</span>"), avoid_highlighting = avoid_highlight)
				else
					to_chat(receiver, span_adminobserverooc(span_prefix("OOC:</span> <EM>[keyname][holder.fakekey ? "/([holder.fakekey])" : ""]:</EM> <span class='message linkify'>[msg]")), avoid_highlighting = avoid_highlight)
			else
				if(GLOB.OOC_COLOR)
					to_chat(receiver, span_oocplain("<font color='[GLOB.OOC_COLOR]'><b>[span_prefix("OOC:")] <EM>[holder.fakekey ? holder.fakekey : key]:</EM> <span class='message linkify'>[msg]</span></b></font>"), avoid_highlighting = avoid_highlight)
				else
					to_chat(receiver, span_ooc(span_prefix("OOC:</span> <EM>[holder.fakekey ? holder.fakekey : key]:</EM> <span class='message linkify'>[msg]")), avoid_highlighting = avoid_highlight)

		else if(!(key in receiver.prefs.ignored_players))
			if(GLOB.OOC_COLOR)
				to_chat(receiver, span_oocplain("<font color='[GLOB.OOC_COLOR]'><b>[span_prefix("OOC:")] <EM>[keyname]:</EM> <span class='message linkify'>[msg]</span></b></font>"), avoid_highlighting = avoid_highlight)
			else
				to_chat(receiver, span_ooc(span_prefix("OOC:</span> <EM>[keyname]:</EM> <span class='message linkify'>[msg]")), avoid_highlighting = avoid_highlight)


//Checks admin notice
/client/verb/admin_notice()
	set name = "Adminnotice"
	set category = "Admin"
	set desc ="Check the admin notice if it has been set"

	if(GLOB.admin_notice)
		to_chat(src, "[span_boldnotice("Admin Notice:")]\n \t [GLOB.admin_notice]")
	else
		to_chat(src, span_notice("There are no admin notices at the moment."))

/client/proc/self_notes()
	set name = "View Admin Remarks"
	set category = "OOC"
	set desc = "View the notes that admins have written about you"

	if(!CONFIG_GET(flag/see_own_notes))
		to_chat(usr, span_notice("Sorry, that function is not enabled on this server."))
		return

	browse_messages(null, usr.ckey, null, TRUE)

/client/proc/self_playtime()
	set name = "View tracked playtime"
	set category = "OOC"
	set desc = "View the amount of playtime for roles the server has tracked."

	if(!CONFIG_GET(flag/use_exp_tracking))
		to_chat(usr, span_notice("Sorry, tracking is currently disabled."))
		return

	new /datum/job_report_menu(src, usr)
