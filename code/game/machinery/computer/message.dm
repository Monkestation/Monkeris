// Allows you to monitor messages that passes the server.

/obj/machinery/computer/message_monitor
	name = "messaging monitor console"
	desc = "Used to access and maintain data on messaging servers. Allows you to view PDA and request console messages."
	icon_screen = "comm_logs"
	light_color = "#00b000"
	var/hack_icon = "error"
	circuit = /obj/item/electronics/circuitboard/message_monitor
	//Server linked to.
	var/obj/machinery/message_server/linkedServer
	//Sparks effect - For emag
	var/datum/effect/effect/system/spark_spread/spark_system = new /datum/effect/effect/system/spark_spread
	//Messages - Saves me time if I want to change something.
	var/noserver = span_alert("ALERT: No server detected.")
	var/incorrectkey = span_warning("ALERT: Incorrect decryption key!")
	var/defaultmsg = span_notice("Welcome. Please select an option.")
	var/rebootmsg = span_warning("%$&(£: Critical %$$@ Error // !RestArting! <lOadiNg backUp iNput ouTput> - ?pLeaSe wAit!")
	//Computer properties
	var/screen = 0 		// 0 = Main menu, 1 = Message Logs, 2 = Hacked screen, 3 = Custom Message
	var/hacking = 0		// Is it being hacked into by the AI/Cyborg
	var/emag = 0		// When it is emagged.
	var/message = span_notice("System bootup complete. Please select an option.")	// The message that shows on the main menu.
	var/auth = 0 // Are they authenticated?
	var/optioncount = 8


/obj/machinery/computer/message_monitor/attackby(obj/item/O as obj, mob/living/user as mob)
	if(stat & (NOPOWER|BROKEN))
		..()
		return
	if(!istype(user))
		return
	if(O.get_tool_type(user, list(QUALITY_SCREW_DRIVING), src) && emag)
		//Stops people from just unscrewing the monitor and putting it back to get the console working again.
		to_chat(user, span_warning("It is too hot to mess with!"))
		return

	..()
	return

/obj/machinery/computer/message_monitor/emag_act(remaining_charges, mob/user)
	// Will create sparks and print out the console's password. You will then have to wait a while for the console to be back online.
	// It'll take more time if there's more characters in the password..
	if(!emag && operable())
		if(!isnull(src.linkedServer))
			emag = 1
			screen = 2
			spark_system.set_up(5, 0, src)
			src.spark_system.start()
			var/obj/item/paper/monitorkey/MK = new/obj/item/paper/monitorkey
			MK.loc = src.loc
			// Will help make emagging the console not so easy to get away with.
			MK.info += "<br><br><font color='red'>£%@%(*$%&(£&?*(%&£/{}</font>"
			spawn(100*length(src.linkedServer.decryptkey)) UnmagConsole()
			message = rebootmsg
			update_icon()
			return 1
		else
			to_chat(user, span_notice("A no server error appears on the screen."))

/obj/machinery/computer/message_monitor/update_icon()
	if(emag || hacking)
		icon_screen = hack_icon
	else
		icon_screen = initial(icon_screen)
	..()

/obj/machinery/computer/message_monitor/Initialize()
	. = ..()
	//Is the server isn't linked to a server, and there's a server available, default it to the first one in the list.
	if(!linkedServer)
		if(message_servers && message_servers.len > 0)
			linkedServer = message_servers[1]

/obj/machinery/computer/message_monitor/attack_hand(mob/living/user as mob)
	if(..())
		return
	if(!istype(user))
		return
	ui_interact(user)

/obj/machinery/computer/message_monitor/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "MessageMonitor", "Message Monitor Console")
		ui.open()

/obj/machinery/computer/message_monitor/ui_state(mob/user)
	return GLOB.default_state

/obj/machinery/computer/message_monitor/ui_data(mob/user)
	var/list/data = list()

	// If the computer is being hacked or is emagged, display the reboot message.
	if(hacking || emag)
		message = rebootmsg

	data["message"] = message
	data["auth"] = auth
	data["hacking"] = hacking
	data["emag"] = emag
	data["serverActive"] = linkedServer && linkedServer.active
	data["hasServer"] = !!linkedServer && !(linkedServer.stat & (NOPOWER|BROKEN))
	data["isAI"] = isAI(user) || isrobot(user)
	data["isMalfAI"] = (isAI(user) || isrobot(user)) && (user.mind.antagonist.len && user.mind.original == user)

	// Determine screen state
	if(hacking || emag)
		data["screen"] = 2
	else if(!auth || !linkedServer || (linkedServer.stat & (NOPOWER|BROKEN)))
		if(!linkedServer || (linkedServer.stat & (NOPOWER|BROKEN)))
			message = noserver
		data["screen"] = 0
	else
		data["screen"] = screen

	// Request console logs data
	if(screen == 4 && linkedServer)
		var/list/logs = list()
		var/index = 0
		for(var/datum/data_rc_msg/rc in linkedServer.rc_msgs)
			index++
			if(index > 3000)
				break
			logs += list(list(
				"ref" = "\ref[rc]",
				"send_dpt" = rc.send_dpt,
				"rec_dpt" = rc.rec_dpt,
				"message" = rc.message,
				"stamp" = rc.stamp,
				"id_auth" = rc.id_auth,
				"priority" = rc.priority
			))
		data["logs"] = logs

	return data

/obj/machinery/computer/message_monitor/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return TRUE

	// Map TGUI actions to existing Topic parameters
	var/list/href_list = list()

	switch(action)
		if("auth")
			href_list["auth"] = "1"
		if("active")
			href_list["active"] = "1"
		if("find")
			href_list["find"] = "1"
		if("viewr")
			href_list["viewr"] = "1"
		if("clearr")
			href_list["clearr"] = "1"
		if("pass")
			href_list["pass"] = "1"
		if("msg")
			href_list["msg"] = "1"
		if("hack")
			href_list["hack"] = "1"
		if("back")
			href_list["back"] = "1"
		if("refresh")
			href_list["refresh"] = "1"
		if("deleter")
			href_list["deleter"] = params["ref"]

	// Call existing Topic method
	Topic("", href_list)
	return TRUE

/obj/machinery/computer/message_monitor/proc/BruteForce(mob/user as mob)
	if(isnull(linkedServer))
		to_chat(user, span_warning("Could not complete brute-force: Linked Server Disconnected!"))
	else
		var/currentKey = src.linkedServer.decryptkey
		to_chat(user, span_warning("Brute-force completed! The key is '[currentKey]'."))
	src.hacking = 0
	update_icon()
	src.screen = 0 // Return the screen back to normal

/obj/machinery/computer/message_monitor/proc/UnmagConsole()
	src.emag = 0
	update_icon()

/obj/machinery/computer/message_monitor/Topic(href, href_list)
	if(..())
		return 1
	if(stat & (NOPOWER|BROKEN))
		return
	if(!isliving(usr))
		return
	if ((usr.contents.Find(src) || (in_range(src, usr) && istype(src.loc, /turf))) || (issilicon(usr)))
		//Authenticate
		if (href_list["auth"])
			if(auth)
				auth = 0
				screen = 0
			else
				var/dkey = trim(input(usr, "Please enter the decryption key.") as text|null)
				if(dkey && dkey != "")
					if(src.linkedServer.decryptkey == dkey)
						auth = 1
					else
						message = incorrectkey

		//Turn the server on/off.
		if (href_list["active"])
			if(auth) linkedServer.active = !linkedServer.active
		//Find a server
		if (href_list["find"])
			if(message_servers && message_servers.len > 1)
				src.linkedServer = input(usr,"Please select a server.", "Select a server.", null) as null|anything in message_servers
				message = span_alert("NOTICE: Server selected.")
			else if(message_servers && message_servers.len > 0)
				linkedServer = message_servers[1]
				message =  span_notice("NOTICE: Only Single Server Detected - Server selected.")
			else
				message = noserver

		//Clears the request console logs - KEY REQUIRED
		if (href_list["clearr"])
			if(!linkedServer || (src.linkedServer.stat & (NOPOWER|BROKEN)))
				message = noserver
			else
				if(auth)
					src.linkedServer.rc_msgs = list()
					message = span_notice("NOTICE: Logs cleared.")
		//Change the password - KEY REQUIRED
		if (href_list["pass"])
			if(!linkedServer || (src.linkedServer.stat & (NOPOWER|BROKEN)))
				message = noserver
			else
				if(auth)
					var/dkey = trim(input(usr, "Please enter the decryption key.") as text|null)
					if(dkey && dkey != "")
						if(src.linkedServer.decryptkey == dkey)
							var/newkey = trim(input(usr,"Please enter the new key (3 - 16 characters max):"))
							if(length(newkey) <= 3)
								message = span_notice("NOTICE: Decryption key too short!")
							else if(length(newkey) > 16)
								message = span_notice("NOTICE: Decryption key too long!")
							else if(newkey && newkey != "")
								src.linkedServer.decryptkey = newkey
							message = span_notice("NOTICE: Decryption key set.")
						else
							message = incorrectkey

		//Hack the Console to get the password
		if (href_list["hack"])
			if((isAI(usr) || isrobot(usr)) && (usr.mind.antagonist.len && usr.mind.original == usr))
				src.hacking = 1
				src.screen = 2
				update_icon()
				//Time it takes to bruteforce is dependant on the password length.
				spawn(100*length(src.linkedServer.decryptkey))
					if(src && src.linkedServer && usr)
						BruteForce(usr)
		//Delete the request console log.
		if (href_list["deleter"])
			//Are they on the view logs screen?
			if(screen == 4)
				if(!linkedServer || (src.linkedServer.stat & (NOPOWER|BROKEN)))
					message = noserver
				else //if(istype(href_list["delete"], /datum/data_pda_msg))
					src.linkedServer.rc_msgs -= locate(href_list["deleter"])
					message = span_notice("NOTICE: Log Deleted!")

		//Request Console Logs - KEY REQUIRED
		if(href_list["viewr"])
			if(src.linkedServer == null || (src.linkedServer.stat & (NOPOWER|BROKEN)))
				message = noserver
			else
				if(auth)
					src.screen = 4

			//usr << href_list["select"]


		if (href_list["back"])
			src.screen = 0

	return src.attack_hand(usr)


/obj/item/paper/monitorkey
	//..()
	name = "Monitor Decryption Key"
	spawn_blacklisted = TRUE
	var/obj/machinery/message_server/server

/obj/item/paper/monitorkey/New()
	..()
	spawn(10)
		if(message_servers)
			for(var/obj/machinery/message_server/server in message_servers)
				if(!isnull(server))
					if(!isnull(server.decryptkey))
						info = "<center><h2>Daily Key Reset</h2></center><br>The new message monitor key is '[server.decryptkey]'.<br>Please keep this a secret and away from the clown.<br>If necessary, change the password to a more secure one."
						info_links = info
						icon_state = "paper_words"
						break
