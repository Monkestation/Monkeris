/datum/admins/proc/CheckAdminHref(href, href_list)
	var/auth = href_list["admin_token"]
	. = auth && (auth == href_token || auth == GLOB.href_token)
	if(.)
		return
	var/msg = !auth ? "no" : "a bad"
	message_admins("[key_name_admin(usr)] clicked an href with [msg] authorization key!")
	if(CONFIG_GET(flag/debug_admin_hrefs))
		message_admins("Debug mode enabled, call not blocked. Please ask your coders to review this round's logs.")
		log_world("UAH: [href]")
		return TRUE
	log_admin("[key_name(usr)] clicked an href with [msg] authorization key! [href]")

/datum/admins/proc/formatJob(mob/mob, title, bantype)
	if(!bantype)
		bantype = title
	var/red = jobban_isbanned(mob, bantype)
	return \
		"<a href='byond://?src=\ref[src];[HrefToken()];jobban3=[bantype];jobban4=\ref[mob]'>\
		[red ? "<font color=red>" : null][replacetext(title, " ", "&nbsp")][red ? "</font>" : null]\
		</a> "

/datum/admins/proc/formatJobGroup(mob/mob, title, color, bantype, list/joblist)
	. += "<tr bgcolor='[color]'><th><a href='byond://?src=\ref[src];[HrefToken()];jobban3=[bantype];jobban4=\ref[mob]'>[title]</a></th></tr><tr><td class='jobs'>"
	for(var/jobPos in joblist)
		. += formatJob(mob, jobPos, GLOB.joblist[jobPos])
	. += "</td></tr>"


/datum/admins/Topic(href, href_list)
	..()

	if(usr.client != owner || !check_rights(0))
		log_admin("[key_name(usr)] tried to use the admin panel without authorization.")
		message_admins("[usr.key] has attempted to override the admin panel!")
		return

	if (!CheckAdminHref(href, href_list))
		return

	if(href_list["openticket"])
		var/ticketID = text2num(href_list["openticket"])
		if(!href_list["is_mhelp"])
			if(!check_rights(R_ADMIN))
				return
			SStickets.showDetailUI(usr, ticketID)
		else
			if(!check_rights(R_MENTOR|R_ADMIN))
				return
			SSmentor_tickets.showDetailUI(usr, ticketID)

	if(href_list["kick_all_from_lobby"])
		if(!check_rights(R_ADMIN))
			return
		if(SSticker.IsRoundInProgress())
			var/afkonly = text2num(href_list["afkonly"])
			if(tgui_alert(usr,"Are you sure you want to kick all [afkonly ? "AFK" : ""] clients from the lobby??","Message",list("Yes","Cancel")) != "Yes")
				to_chat(usr, "Kick clients from lobby aborted", confidential = TRUE)
				return
			var/list/listkicked = kick_clients_in_lobby(span_danger("You were kicked from the lobby by [usr.client.holder.fakekey ? "an Administrator" : "[usr.client.key]"]."), afkonly)

			var/strkicked = ""
			for(var/name in listkicked)
				strkicked += "[name], "
			message_admins("[key_name_admin(usr)] has kicked [afkonly ? "all AFK" : "all"] clients from the lobby. [length(listkicked)] clients kicked: [strkicked ? strkicked : "--"]")
			log_admin("[key_name(usr)] has kicked [afkonly ? "all AFK" : "all"] clients from the lobby. [length(listkicked)] clients kicked: [strkicked ? strkicked : "--"]")
		else
			to_chat(usr, "You may only use this when the game is running.", confidential = TRUE)

	if(href_list["take_question"])
		var/indexNum = text2num(href_list["take_question"])
		if(check_rights(R_ADMIN))
			SStickets.takeTicket(indexNum)

	if(href_list["resolve"])
		var/indexNum = text2num(href_list["resolve"])
		if(check_rights(R_ADMIN))
			SStickets.resolveTicket(indexNum)

	if(href_list["convert_ticket"])
		var/indexNum = text2num(href_list["convert_ticket"])
		if(check_rights(R_ADMIN))
			SStickets.convert_to_other_ticket(indexNum)

	if(href_list["autorespond"])
		var/indexNum = text2num(href_list["autorespond"])
		if(check_rights(R_ADMIN))
			SStickets.autoRespond(indexNum)

	var/static/list/topic_handlers = AdminTopicHandlers()
	var/datum/admin_topic/handler

	for(var/I in topic_handlers)
		if(I in href_list)
			handler = topic_handlers[I]
			break

	if(!handler)
		return

	handler = new handler()
	return handler.TryRun(href_list, src)



/mob/living/proc/can_centcom_reply()
	return 0

/mob/living/carbon/human/can_centcom_reply()
	return istype(l_ear, /obj/item/device/radio/headset) || istype(r_ear, /obj/item/device/radio/headset)

/mob/living/silicon/ai/can_centcom_reply()
	return common_radio != null && !check_unable(2)

/atom/proc/extra_admin_link()
	return

/mob/extra_admin_link(source)
	if(client && eyeobj)
		return "|<A href='byond://?[source];[HrefToken()];adminobservejump=\ref[eyeobj]'>EYE</A>"

/mob/observer/ghost/extra_admin_link(source)
	if(mind && mind.current)
		return "|<A href='byond://?[source];[HrefToken()];adminobservejump=\ref[mind.current]'>BDY</A>"

/proc/admin_jump_link(atom/target, source)
	if(!target) return
	// The way admin jump links handle their src is weirdly inconsistent...
	if(istype(source, /datum/admins))
		source = "src=\ref[source]"
	else
		source = "_src_=holder"

	. = "<A href='byond://?[source];[HrefToken()];adminobservejump=\ref[target]'>JMP</A>"
	. += target.extra_admin_link(source)
