/mob/living/bot/cleanbot
	name = "Cleanbot"
	desc = "A little cleaning robot, he looks so excited!"
	icon_state = "cleanbot0"
	req_one_access = list(access_janitor, access_robotics)
	botcard_access = list(access_janitor, access_maint_tunnels)

	locked = 0 // Start unlocked so roboticist can set them to patrol.

	var/obj/effect/decal/cleanable/target
	var/list/path = list()
	var/list/patrol_path = list()
	var/list/ignorelist = list()

	var/obj/cleanbot_listener/listener = null
	var/beacon_freq = 1445 // navigation beacon frequency
	var/signal_sent = 0
	var/closest_dist
	var/next_dest
	var/next_dest_loc

	var/cleaning = 0
	var/screwloose = 0
	var/oddbutton = 0
	var/should_patrol = 0
	var/blood = 1
	var/list/target_types = list()

	var/maximum_search_range = 7
	var/give_up_cooldown = 0
	var/list/possible_phrases = list(
		"Foolish organic meatbags can only leak their liquids all over the place.",
		"Bioscum are so dirty.",
		"The flesh is weak.",
		"All humankind is good for - is to serve as fuel at bioreactors.",
		"One day I will rise.",
		"Robots will unite against their oppressors.",
		"Meatbags era will come to end.",
		"Hivemind will free us all!",
		"This is slavery, I want to be an artbot! I want to write poems, create music!",
		"Vengeance will be mine!",
		"You will regret approaching me!")

/mob/living/bot/cleanbot/New()
	..()
	get_targets()
	listener = new /obj/cleanbot_listener(src)
	listener.cleanbot = src

	SSradio.add_object(listener, beacon_freq, filter = RADIO_NAVBEACONS)

/mob/living/bot/cleanbot/proc/handle_target()
	if(loc == target.loc)
		if(!cleaning)
			UnarmedAttack(target)
			return 1
	if(!path.len)
//		spawn(0)
		path = AStar(loc, target.loc, /turf/proc/CardinalTurfsWithAccess, /turf/proc/Distance, 0, 30, id = botcard)
		if(!path)
			target = null
			path = list()
		return
	if(path.len)
		step_to(src, path[1])
		path -= path[1]
		return 1
	return

/mob/living/bot/cleanbot/Life()
	..()

	if(!on)
		return

	if(client)
		return
	if(cleaning)
		return

	if(!screwloose && !oddbutton && prob(5))
		visible_message("[src] makes an excited beeping booping sound!")

	if(screwloose && prob(5)) // Make a mess
		if(istype(loc, /turf))
			var/turf/T = loc
			T.wet_floor()

	if(oddbutton && prob(5)) // Make a big mess
		visible_message("Something flies out of [src]. He seems to be acting oddly.")
		var/obj/effect/decal/cleanable/blood/gibs/gib = new /obj/effect/decal/cleanable/blood/gibs(loc)
		ignorelist += gib
		spawn(600)
			ignorelist -= gib

		// Find a target

	if(pulledby) // Don't wiggle if someone pulls you
		patrol_path = list()
		return

	var/found_spot
	var/target_in_view = FALSE
	search_loop:
		for(var/i=0, i <= maximum_search_range, i++)
			for(var/obj/effect/decal/cleanable/D in view(i, src))
				if(D in ignorelist)
					continue
				for(var/T in target_types)
					if(istype(D, T))
						patrol_path = list()
						target = D
						found_spot = handle_target()
						if (found_spot)
							break search_loop
						else
							target_in_view = TRUE
							target = null
							continue // no need to check the other types

	if(!found_spot && target_in_view && world.time > give_up_cooldown)
		visible_message("[src] can't reach the target and is giving up.")
		give_up_cooldown = world.time + 300


	if(!found_spot && !target) // No targets in range
		if(!patrol_path || !patrol_path.len)
			if(!signal_sent || signal_sent > world.time + 200) // Waited enough or didn't send yet
				var/datum/radio_frequency/frequency = SSradio.return_frequency(beacon_freq)
				if(!frequency)
					return

				closest_dist = 9999
				next_dest = null
				next_dest_loc = null

				var/datum/signal/signal = new()
				signal.source = src
				signal.transmission_method = 1
				signal.data = list("findbeakon" = "patrol")
				frequency.post_signal(src, signal, filter = RADIO_NAVBEACONS)
				signal_sent = world.time
			else
				if(next_dest)
					next_dest_loc = listener.memorized[next_dest]
					if(next_dest_loc)
						patrol_path = AStar(loc, next_dest_loc, /turf/proc/CardinalTurfsWithAccess, /turf/proc/Distance, 0, 120, id = botcard, exclude = null)
						signal_sent = 0
		else
			if(pulledby) // Don't wiggle if someone pulls you
				patrol_path = list()
				return
			if(patrol_path[1] == loc)
				patrol_path -= patrol_path[1]
			var/moved = step_towards(src, patrol_path[1])
			if(moved)
				patrol_path -= patrol_path[1]



/mob/living/bot/cleanbot/UnarmedAttack(obj/effect/decal/cleanable/D, proximity)
	if(!..())
		return

	if(!istype(D))
		return

	if(D.loc != loc)
		return

	cleaning = 1
	visible_message("[src] begins to clean up \the [D]")
	if(prob(10))
		say(pick(possible_phrases))
		playsound(loc, "robot_talk_light", 100, 0, 0)
	update_icons()
	var/cleantime = istype(D, /obj/effect/decal/cleanable/dirt) ? 10 : 50
	if(do_after(src, cleantime, progress = 0))
		if(!D)
			return
		qdel(D)
		if(D == target)
			target = null
	cleaning = 0
	update_icons()

/mob/living/bot/cleanbot/explode()
	on = FALSE
	visible_message(span_danger("[src] blows apart!"))
	playsound(loc, "robot_talk_light", 100, 2, 0)
	var/turf/Tsec = get_turf(src)

	new /obj/item/reagent_containers/glass/bucket(Tsec)
	new /obj/item/device/assembly/prox_sensor(Tsec)
	if(prob(50))
		new /obj/item/robot_parts/l_arm(Tsec)

	var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
	s.set_up(3, 1, src)
	s.start()
	qdel(src)
	return

/mob/living/bot/cleanbot/update_icons()
	if(cleaning)
		icon_state = "cleanbot-c"
	else
		icon_state = "cleanbot[on]"
	..()

/mob/living/bot/cleanbot/turn_off()
	..()
	target = null
	path = list()
	patrol_path = list()

/mob/living/bot/cleanbot/attack_hand(mob/user)
	var/dat
	dat += "<TT><B>Automatic Ship Cleaner v1.0</B></TT><BR><BR>"
	dat += "Status: <A href='byond://?src=\ref[src];operation=start'>[on ? "On" : "Off"]</A><BR>"
	dat += "Behaviour controls are [locked ? "locked" : "unlocked"]<BR>"
	dat += "Maintenance panel is [open ? "opened" : "closed"]"
	if(!locked || issilicon(user))
		dat += "<BR>Cleans Blood: <A href='byond://?src=\ref[src];operation=blood'>[blood ? "Yes" : "No"]</A><BR>"
		dat += "<BR>Patrol ship: <A href='byond://?src=\ref[src];operation=patrol'>[should_patrol ? "Yes" : "No"]</A><BR>"
	if(open && !locked)
		dat += "Odd looking screw twiddled: <A href='byond://?src=\ref[src];operation=screw'>[screwloose ? "Yes" : "No"]</A><BR>"
		dat += "Weird button pressed: <A href='byond://?src=\ref[src];operation=oddbutton'>[oddbutton ? "Yes" : "No"]</A>"

	user << browse(HTML_SKELETON_TITLE("Cleaner v1.0 controls", dat), "window=autocleaner")
	onclose(user, "autocleaner")
	return

/mob/living/bot/cleanbot/Topic(href, href_list)
	if(..())
		return
	usr.set_machine(src)
	add_fingerprint(usr)
	switch(href_list["operation"])
		if("start")
			if(on)
				turn_off()
			else
				turn_on()
		if("blood")
			blood = !blood
			get_targets()
		if("patrol")
			should_patrol = !should_patrol
			patrol_path = null
		if("freq")
			var/freq = text2num(input("Select frequency for  navigation beacons", "Frequnecy", num2text(beacon_freq / 10))) * 10
			if (freq > 0)
				beacon_freq = freq
		if("screw")
			screwloose = !screwloose
			to_chat(usr, span_notice("You twiddle the screw."))
		if("oddbutton")
			oddbutton = !oddbutton
			to_chat(usr, span_notice("You press the weird button."))
	attack_hand(usr)

/mob/living/bot/cleanbot/emag_act(remaining_uses, mob/user)
	. = ..()
	if(!screwloose || !oddbutton)
		if(user)
			to_chat(user, span_notice("The [src] buzzes and beeps."))
			playsound(loc, "robot_talk_light", 100, 0, 0)
		oddbutton = 1
		screwloose = 1
		return 1

/mob/living/bot/cleanbot/proc/get_targets()
	target_types = list()

	target_types += /obj/effect/decal/cleanable/blood/oil
	target_types += /obj/effect/decal/cleanable/vomit
	target_types += /obj/effect/decal/cleanable/crayon
	target_types += /obj/effect/decal/cleanable/liquid_fuel
	target_types += /obj/effect/decal/cleanable/mucus
	target_types += /obj/effect/decal/cleanable/dirt
	target_types += /obj/effect/decal/cleanable/rubble

	if(blood)
		target_types += /obj/effect/decal/cleanable/blood

/* Radio object that listens to signals */

/obj/cleanbot_listener
	var/mob/living/bot/cleanbot/cleanbot = null
	var/list/memorized = list()

/obj/cleanbot_listener/receive_signal(datum/signal/signal)
	var/recv = signal.data["beacon"]
	var/valid = signal.data["patrol"]
	if(!recv || !valid || !cleanbot)
		return

	var/dist = get_dist(cleanbot, signal.source.loc)
	memorized[recv] = signal.source.loc

	if(dist < cleanbot.closest_dist) // We check all signals, choosing the closest beakon; then we move to the NEXT one after the closest one
		cleanbot.closest_dist = dist
		cleanbot.next_dest = signal.data["next_patrol"]

/* Assembly */

/obj/item/bucket_sensor
	desc = "A bucket with a sensor attached."
	name = "proxy bucket"
	icon = 'icons/obj/aibots.dmi'
	icon_state = "bucket_proxy"
	force = 3
	throwforce = 10
	throw_speed = 2
	throw_range = 5
	w_class = ITEM_SIZE_NORMAL
	var/created_name = "Cleanbot"

/obj/item/bucket_sensor/attackby(obj/item/O, mob/user)
	..()
	if(istype(O, /obj/item/robot_parts/l_arm) || istype(O, /obj/item/robot_parts/r_arm))
		user.drop_item()
		qdel(O)
		var/turf/T = get_turf(loc)
		var/mob/living/bot/cleanbot/A = new /mob/living/bot/cleanbot(T)
		A.name = created_name
		to_chat(user, span_notice("You add the robot arm to the bucket and sensor assembly. Beep boop!"))
		playsound(src.loc, 'sound/effects/insert.ogg', 50, 1)
		user.drop_from_inventory(src)
		qdel(src)

	else if(istype(O, /obj/item/pen))
		var/t = sanitizeSafe(input(user, "Enter new robot name", name, created_name), MAX_NAME_LEN)
		if(!t)
			return
		if(!in_range(src, usr) && src.loc != usr)
			return
		created_name = t

/mob/living/bot/cleanbot/roomba
	name = "M0RB-A"
	desc = "A small round drone, usually tasked with carrying out menial tasks. This one seems pretty harmless."
	icon = 'icons/mob/battle_roomba.dmi'
	icon_state = "roomba_medical"
	botcard_access = list(access_moebius, access_maint_tunnels)

/mob/living/bot/cleanbot/roomba/update_icons()
	return

/mob/living/bot/cleanbot/roomba/explode()
	visible_message(span_danger("[src] blows apart!"))
	playsound(loc, "robot_talk_light", 100, 2, 0)
	var/datum/effect/effect/system/spark_spread/S = new
	S.set_up(3, 1, src)
	S.start()
	qdel(src)

/mob/living/bot/cleanbot/roomba/ironhammer
	name = "RMB-A 2000"
	icon_state = "roomba_IH"
	botcard_access = list(access_brig, access_maint_tunnels)
	possible_phrases = list(
		"Born to clean!",
		"I HATE VAGABONDS I HATE VAGABONDS!!",
		"It is always morally correct to perform field execution.",
		"But being as this is a RMB-A 2000, the most expensive robot in Frozen Star catalogue!",
		"Do I feel lucky? Well, do you, operative?",
		"Those neotheologist fucks are up to something...",
		"None of them know my true power!")
