//Config stuff
#define PRISON_MOVETIME 150	//Time to station is milliseconds.
#define PRISON_STATION_AREATYPE "/area/shuttle/prison/station" //Type of the prison shuttle area for station
#define PRISON_DOCK_AREATYPE "/area/shuttle/prison/prison"	//Type of the prison shuttle area for dock

var/prison_shuttle_moving_to_station = 0
var/prison_shuttle_moving_to_prison = 0
var/prison_shuttle_at_station = 0
var/prison_shuttle_can_send = 1
var/prison_shuttle_time = 0
var/prison_shuttle_timeleft = 0

/obj/machinery/computer/prison_shuttle
	name = "prison shuttle control console"
	icon = 'icons/obj/computer.dmi'
	icon_keyboard = "security_key"
	icon_screen = "syndishuttle"
	light_color = COLOR_LIGHTING_SCI_BRIGHT
	req_access = list(access_security)
	circuit = /obj/item/electronics/circuitboard/prison_shuttle
	var/temp
	var/allowedtocall = 0
	var/prison_break = 0

/obj/machinery/computer/prison_shuttle/attack_ai(mob/user as mob)
	return src.attack_hand(user)

/obj/machinery/computer/prison_shuttle/attackby(I as obj, user as mob)
	if(istype(I, /obj/item/tool/screwdriver))
		playsound(src.loc, 'sound/items/Screwdriver.ogg', 50, 1)
		if(do_after(user, 20, src))
			var/obj/structure/computerframe/A = new /obj/structure/computerframe( src.loc )
			var/obj/item/electronics/circuitboard/prison_shuttle/M = new /obj/item/electronics/circuitboard/prison_shuttle( A )
			for (var/obj/C in src)
				C.loc = src.loc
			A.circuit = M
			A.anchored = TRUE

			if (src.stat & BROKEN)
				to_chat(user, span_notice("The broken glass falls out."))
				new /obj/item/material/shard( src.loc )
				A.state = 3
				A.icon_state = "3"
			else
				to_chat(user, span_notice("You disconnect the monitor."))
				A.state = 4
				A.icon_state = "4"

			qdel(src)
	else
		return src.attack_hand(user)


/obj/machinery/computer/prison_shuttle/attack_hand(mob/user as mob)
	if(!src.allowed(user) && (!hacked))
		to_chat(user, span_warning("Access Denied."))
		return
	if(prison_break)
		to_chat(user, span_warning("Unable to locate shuttle."))
		return
	if(..())
		return
	user.set_machine(src)
	post_signal("prison")
	var/dat
	if (src.temp)
		dat = src.temp
	else
		dat += {"<BR><B>Prison Shuttle</B><HR>
		\nLocation: [prison_shuttle_moving_to_station || prison_shuttle_moving_to_prison ? "Moving to station ([prison_shuttle_timeleft] Secs.)":prison_shuttle_at_station ? "Station":"Dock"]<BR>
		[prison_shuttle_moving_to_station || prison_shuttle_moving_to_prison ? "\n*Shuttle already called*<BR>\n<BR>":prison_shuttle_at_station ? "\n<A href='byond://?src=\ref[src];sendtodock=1'>Send to Dock</A><BR>\n<BR>":"\n<A href='byond://?src=\ref[src];sendtostation=1'>Send to station</A><BR>\n<BR>"]
		\n<A href='byond://?src=\ref[user];mach_close=computer'>Close</A>"}

	user << browse(HTML_SKELETON(dat), "window=computer;size=575x450")
	onclose(user, "computer")
	return


/obj/machinery/computer/prison_shuttle/Topic(href, href_list)
	if(..())
		return

	if ((usr.contents.Find(src) || (in_range(src, usr) && istype(src.loc, /turf))) || (issilicon(usr)))
		usr.set_machine(src)

	if (href_list["sendtodock"])
		if (!prison_can_move())
			to_chat(usr, span_warning("The prison shuttle is unable to leave."))
			return
		if(!prison_shuttle_at_station|| prison_shuttle_moving_to_station || prison_shuttle_moving_to_prison) return
		post_signal("prison")
		to_chat(usr, span_notice("The prison shuttle has been called and will arrive in [(PRISON_MOVETIME/10)] seconds."))
		src.temp += "Shuttle sent.<BR><BR><A href='byond://?src=\ref[src];mainmenu=1'>OK</A>"
		src.updateUsrDialog()
		prison_shuttle_moving_to_prison = 1
		prison_shuttle_time = world.timeofday + PRISON_MOVETIME
		spawn(0)
			prison_process()

	else if (href_list["sendtostation"])
		if (!prison_can_move())
			to_chat(usr, span_warning("The prison shuttle is unable to leave."))
			return
		if(prison_shuttle_at_station || prison_shuttle_moving_to_station || prison_shuttle_moving_to_prison) return
		post_signal("prison")
		to_chat(usr, span_notice("The prison shuttle has been called and will arrive in [(PRISON_MOVETIME/10)] seconds."))
		src.temp += "Shuttle sent.<BR><BR><A href='byond://?src=\ref[src];mainmenu=1'>OK</A>"
		src.updateUsrDialog()
		prison_shuttle_moving_to_station = 1
		prison_shuttle_time = world.timeofday + PRISON_MOVETIME
		spawn(0)
			prison_process()

	else if (href_list["mainmenu"])
		src.temp = null

	src.add_fingerprint(usr)
	src.updateUsrDialog()
	return


/obj/machinery/computer/prison_shuttle/proc/prison_can_move()
	if(prison_shuttle_moving_to_station || prison_shuttle_moving_to_prison) return 0
	else return 1


/obj/machinery/computer/prison_shuttle/proc/prison_break()
	switch(prison_break)
		if (0)
			if(!prison_shuttle_at_station || prison_shuttle_moving_to_prison) return

			prison_shuttle_moving_to_prison = 1
			prison_shuttle_at_station = prison_shuttle_at_station

			if (!prison_shuttle_moving_to_prison || !prison_shuttle_moving_to_station)
				prison_shuttle_time = world.timeofday + PRISON_MOVETIME
			spawn(0)
				prison_process()
			prison_break = 1
		if(1)
			prison_break = 0


/obj/machinery/computer/prison_shuttle/proc/post_signal(command)
	var/datum/radio_frequency/frequency = SSradio.return_frequency(1311)
	if(!frequency) return
	var/datum/signal/status_signal = new
	status_signal.source = src
	status_signal.transmission_method = 1
	status_signal.data["command"] = command
	frequency.post_signal(src, status_signal)
	return


/obj/machinery/computer/prison_shuttle/proc/prison_process()
	while(prison_shuttle_time - world.timeofday > 0)
		var/ticksleft = prison_shuttle_time - world.timeofday

		if(ticksleft > 1e5)
			prison_shuttle_time = world.timeofday + 10	// midnight rollover

		prison_shuttle_timeleft = (ticksleft / 10)
		sleep(5)
	prison_shuttle_moving_to_station = 0
	prison_shuttle_moving_to_prison = 0

	switch(prison_shuttle_at_station)

		if(0)
			prison_shuttle_at_station = 1
			if (prison_shuttle_moving_to_station || prison_shuttle_moving_to_prison) return

			if (!prison_can_move())
				to_chat(usr, span_warning("The prison shuttle is unable to leave."))
				return

			var/area/start_location = locate(/area/shuttle/prison/prison)
			var/area/end_location = locate(/area/shuttle/prison/station)

			var/list/dstturfs = list()
			var/throwy = world.maxy

			for(var/turf/T in end_location)
				dstturfs += T
				if(T.y < throwy)
					throwy = T.y
						// hey you, get out of the way!
			for(var/turf/T in dstturfs)
							// find the turf to move things to
				var/turf/D = locate(T.x, throwy - 1, 1)
							//var/turf/E = get_step(D, SOUTH)
				for(var/atom/movable/AM as mob|obj in T)
					AM.Move(D)
				if(istype(T, /turf))
					qdel(T)
			start_location.move_contents_to(end_location)

		if(1)
			prison_shuttle_at_station = 0
			if (prison_shuttle_moving_to_station || prison_shuttle_moving_to_prison) return

			if (!prison_can_move())
				to_chat(usr, span_warning("The prison shuttle is unable to leave."))
				return

			var/area/start_location = locate(/area/shuttle/prison/station)
			var/area/end_location = locate(/area/shuttle/prison/prison)

			var/list/dstturfs = list()
			var/throwy = world.maxy

			for(var/turf/T in end_location)
				dstturfs += T
				if(T.y < throwy)
					throwy = T.y

						// hey you, get out of the way!
			for(var/turf/T in dstturfs)
							// find the turf to move things to
				var/turf/D = locate(T.x, throwy - 1, 1)
							//var/turf/E = get_step(D, SOUTH)
				for(var/atom/movable/AM as mob|obj in T)
					AM.Move(D)
				if(istype(T, /turf))
					qdel(T)

			for(var/mob/living/carbon/bug in end_location) // If someone somehow is still in the shuttle's docking area...
				bug.gib()

			for(var/mob/living/simple_animal/pest in end_location) // And for the other kind of bug...
				pest.gib()

			start_location.move_contents_to(end_location)
	return

/obj/machinery/computer/prison_shuttle/emag_act(charges, mob/user)
	if(!hacked)
		hacked = 1
		to_chat(user, span_notice("You disable the lock."))
		return 1
