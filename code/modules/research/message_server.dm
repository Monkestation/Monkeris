var/global/list/obj/machinery/message_server/message_servers = list()

/datum/data_pda_msg
	var/recipient = "Unspecified" //name of the person
	var/sender = "Unspecified" //name of the sender
	var/message = "Blank" //transferred message

/datum/data_pda_msg/New(param_rec = "",param_sender = "",param_message = "")

	if(param_rec)
		recipient = param_rec
	if(param_sender)
		sender = param_sender
	if(param_message)
		message = param_message

/datum/data_rc_msg
	var/rec_dpt = "Unspecified" //name of the person
	var/send_dpt = "Unspecified" //name of the sender
	var/message = "Blank" //transferred message
	var/stamp = "Unstamped"
	var/id_auth = "Unauthenticated"
	var/priority = "Normal"

/datum/data_rc_msg/New(param_rec = "",param_sender = "",param_message = "",param_stamp = "",param_id_auth = "",param_priority)
	if(param_rec)
		rec_dpt = param_rec
	if(param_sender)
		send_dpt = param_sender
	if(param_message)
		message = param_message
	if(param_stamp)
		stamp = param_stamp
	if(param_id_auth)
		id_auth = param_id_auth
	if(param_priority)
		switch(param_priority)
			if(1)
				priority = "Normal"
			if(2)
				priority = "High"
			if(3)
				priority = "Extreme"
			else
				priority = "Undetermined"

/obj/machinery/message_server
	icon = 'icons/obj/machines/research.dmi'
	icon_state = "server"
	name = "Messaging Server"
	density = TRUE
	anchored = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 10
	active_power_usage = 100

	var/list/datum/data_rc_msg/rc_msgs = list()
	var/active = 1
	var/decryptkey = "password"


/obj/machinery/message_server/New()
	message_servers += src
	decryptkey = GenerateKey()
	send_rc_message("System Administrator", "system", "This is an automated message. The messaging system is functioning correctly.")
	..()
	return

/obj/machinery/message_server/Destroy()
	message_servers -= src

	return ..()

/obj/machinery/message_server/proc/GenerateKey()
	//Feel free to move to Helpers.
	var/newKey
	newKey += pick("the", "if", "of", "as", "in", "a", "you", "from", "to", "an", "too", "little", "snow", "dead", "drunk", "rosebud", "duck", "al", "le")
	newKey += pick("diamond", "beer", "mushroom", "assistant", "clown", "captain", "twinkie", "security", "nuke", "small", "big", "escape", "yellow", "gloves", "monkey", "engine", "nuclear", "ai")
	newKey += pick("1", "2", "3", "4", "5", "6", "7", "8", "9", "0")
	return newKey

/obj/machinery/message_server/Process()
	//if(decryptkey == "password")
	//	decryptkey = generateKey()
	if(active && (stat & (BROKEN|NOPOWER)))
		active = 0
		return
	update_icon()
	return


/obj/machinery/message_server/proc/send_rc_message(recipient = "",sender = "",message = "",stamp = "", id_auth = "", priority = 1)
	rc_msgs += new/datum/data_rc_msg(recipient,sender,message,stamp,id_auth)
	var/authmsg = "[message]<br>"
	if (id_auth)
		authmsg += "[id_auth]<br>"
	if (stamp)
		authmsg += "[stamp]<br>"


	for (var/obj/machinery/requests_console/Console in allConsoles)
		var/htmlicon = icon2html(Console, hearers(get_turf(Console)))

		if (ckey(Console.department) == ckey(recipient))
			if(Console.inoperable())
				Console.message_log += "<B>Message lost due to console failure.</B><BR>Please contact [station_name()] system adminsitrator or AI for technical assistance.<BR>"
				continue
			if(Console.newmessagepriority < priority)
				Console.newmessagepriority = priority
				Console.icon_state = "req_comp[priority]"
			switch(priority)
				if(2)
					if(!Console.silent)
						playsound(Console.loc, 'sound/machines/twobeep.ogg', 50, 1)
						Console.audible_message("[htmlicon] *The Requests Console beeps: 'PRIORITY Alert in [sender]'")
					Console.message_log += "<B><FONT color='red'>High Priority message from <A href='byond://?src=\ref[Console];write=[sender]'>[sender]</A></FONT></B><BR>[authmsg]"
				else
					if(!Console.silent)
						playsound(Console.loc, 'sound/machines/twobeep.ogg', 50, 1)
						Console.audible_message("[htmlicon] *The Requests Console beeps: 'Message from [sender]'")
					Console.message_log += "<B>Message from <A href='byond://?src=\ref[Console];write=[sender]'>[sender]</A></B><BR>[authmsg]"
			Console.set_light(2)


/obj/machinery/message_server/attack_hand(user as mob)
//	user << span_blue("There seem to be some parts missing from this server. They should arrive on the station in a few days, give or take a few CentCom delays.")
	to_chat(user, "You toggle PDA message passing from [active ? "On" : "Off"] to [active ? "Off" : "On"]")
	active = !active
	update_icon()

	return


/obj/machinery/message_server/update_icon()
	if((stat & (BROKEN|NOPOWER)))
		icon_state = "server-nopower"
	else if (!active)
		icon_state = "server-off"
	else
		icon_state = "server-on"

	return




var/obj/machinery/blackbox_recorder/blackbox

/obj/machinery/blackbox_recorder
	name = "blackbox recorder"
	icon = 'icons/obj/machines/telecomms.dmi'
	icon_state = "blackbox"
	density = TRUE
	anchored = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 10
	active_power_usage = 100
	var/list/messages = list()		//Stores messages of non-standard frequencies


	var/list/msg_common = list()
	var/list/msg_science = list()
	var/list/msg_command = list()
	var/list/msg_medical = list()
	var/list/msg_engineering = list()
	var/list/msg_security = list()
	var/list/msg_deathsquad = list()
	var/list/msg_syndicate = list()
	var/list/msg_pirate = list()
	var/list/msg_cargo = list()
	var/list/msg_service = list()
	var/list/msg_nt = list()



	//Only one can exist in the world!
/obj/machinery/blackbox_recorder/Initialize(mapload, d)
	. = ..()
	if(blackbox && istype(blackbox,/obj/machinery/blackbox_recorder))
		return INITIALIZE_HINT_QDEL
	blackbox = src

/obj/machinery/blackbox_recorder/Destroy()
	var/turf/T = locate(1,1,2)
	if(T)
		blackbox = null
		var/obj/machinery/blackbox_recorder/BR = new/obj/machinery/blackbox_recorder(T)
		BR.msg_common = msg_common
		BR.msg_science = msg_science
		BR.msg_command = msg_command
		BR.msg_medical = msg_medical
		BR.msg_engineering = msg_engineering
		BR.msg_security = msg_security
		BR.msg_deathsquad = msg_deathsquad
		BR.msg_syndicate = msg_syndicate
		BR.msg_pirate = msg_pirate
		BR.msg_cargo = msg_cargo
		BR.msg_service = msg_service
		BR.msg_nt = msg_nt

		BR.messages = messages

		if(blackbox != BR)
			blackbox = BR
	. = ..()

// Sanitize inputs to avoid SQL injection attacks
/proc/sql_sanitize_text(text)
	text = replacetext(text, "'", "''")
	text = replacetext(text, ";", "")
	text = replacetext(text, "&", "")
	return text
