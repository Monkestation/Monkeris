//admin-only ooc chat
/client/proc/cmd_admin_say(msg as text)
	set category = "Special Verbs"
	set name = "Asay" //Gave this shit a shorter name so you only have to time out "asay" rather than "admin say" to use it --NeoFite
	set hidden = 1
	if(!check_rights(R_ADMIN))
		return

	msg = sanitize(msg)
	if(!msg)
		return

	log_admin("ADMIN: [key_name(src)] : [msg]")

	SSplexora.relay_admin_say(src, html_decode(msg))
	msg = emoji_parse(msg)

	if(findtext(msg, "@") || findtext(msg, "#"))
		var/list/link_results = check_asay_links(msg)
		if(length(link_results))
			msg = link_results[ASAY_LINK_NEW_MESSAGE_INDEX]
			link_results[ASAY_LINK_NEW_MESSAGE_INDEX] = null
			var/list/pinged_admin_clients = link_results[ASAY_LINK_PINGED_ADMINS_INDEX]
			for(var/iter_ckey in pinged_admin_clients)
				var/client/iter_admin_client = pinged_admin_clients[iter_ckey]
				if(!iter_admin_client?.holder)
					continue
				window_flash(iter_admin_client)
				SEND_SOUND(iter_admin_client.mob, sound('sound/misc/asay_ping.ogg'))

	msg = keywords_lookup(msg)
	var/asay_color = prefs.asaycolor
	var/custom_asay_color = (CONFIG_GET(flag/allow_admin_asaycolor) && asay_color) ? "<font color=[asay_color]>" : "<font color='[DEFAULT_ASAY_COLOR]'>"
	msg = "[span_adminsay("[span_prefix("ADMIN:")] <EM>[key_name(usr, 1)]</EM> [ADMIN_FLW(mob)]: [custom_asay_color]<span class='message linkify'>[msg]")]</span>[custom_asay_color ? "</font>":null]"
	to_chat(GLOB.admins,
		type = MESSAGE_TYPE_ADMINCHAT,
		html = msg,
		confidential = TRUE)

/client/proc/cmd_mod_say(msg as text)
	set category = "Special Verbs"
	set name = "Msay"
	set hidden = 1

	if(!check_rights(R_ADMIN|R_MENTOR))
		return

	msg = sanitize(msg)
	log_admin("MOD: [key_name(src)] : [msg]")

	if (!msg)
		return
	SSplexora.relay_mentor_say(src, html_decode(msg))

	var/sender_name = key_name(usr, 1)
	if(check_rights(R_ADMIN, 0))
		sender_name = span_admin("[sender_name]")
	for(var/client/C in GLOB.admins)
		to_chat(C, "<span class='mod_channel'> MOD: [span_name("[sender_name]")]): <span class='message linkify'>[msg]</span></span>")

// Checks a given message to see if any of the words contain an active mentor's ckey with an @ before it
/proc/check_mentor_pings(message)
	var/list/msglist = splittext(message, " ")
	var/list/mentors_to_ping = list()

	var/i = 0
	for(var/word in msglist)
		i++
		if(!length(word))
			continue
		if(word[1] != "@")
			continue
		var/ckey_check = ckey(copytext(word, 2))
		var/client/client_check = GLOB.directory[ckey_check]
		// if(client_check?.mentor_datum?.check_for_rights(R_MENTOR))
		if(client_check?.holder?.check_for_exact_rights(R_MENTOR))
			msglist[i] = "<u>[word]</u>"
			mentors_to_ping[ckey_check] = client_check

	if(length(mentors_to_ping))
		mentors_to_ping[ASAY_LINK_PINGED_ADMINS_INDEX] = jointext(msglist, " ")
		return mentors_to_ping
