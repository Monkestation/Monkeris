#define ICON_SPLIT_X 16

/obj/machinery/cooking_with_jane/grill
	name = "Grill"
	desc = "A deep pit of charcoal for cooking food. A slot on the side of the machine takes wood and converts it into charcoal."
	description_info = "Ctrl+Click: Set Temperatures / Timers. \nShift+Ctrl+Click: Turn on a burner.\nAlt+Click: Empty container of physical food."
	icon = 'icons/obj/cwj_cooking/grill.dmi'
	icon_state = "grill"
	density = FALSE
	anchored = TRUE
	layer = BELOW_OBJ_LAYER
	cooking = FALSE
	var/list/temperature= list(J_LO, J_LO)
	var/list/timer = list(0, 0)
	var/list/timerstamp = list(0, 0)
	var/list/switches = list(0, 0)
	var/list/cooking_timestamp = list(0, 0) //Timestamp of when cooking initialized so we know if the prep was disturbed at any point.
	var/list/items[2]

	use_power = NO_POWER_USE
	interact_offline = TRUE

	var/stored_wood = 0
	var/wood_maximum = 30

	var/reference_time = 0 //The exact moment when we call the process routine, just to account for lag.

	var/check_on_10 = 0

	var/on_fire = FALSE //if the grill has caught fire or not.

	circuit = /obj/item/electronics/circuitboard/cooking_with_jane/grill

	var/obj/effect/flick_light_overlay/hopper_insert //flick_light_overlay found in machinery/autolathe/autolathe.dm

/obj/machinery/cooking_with_jane/grill/Initialize()
	. = ..()
	hopper_insert = new(src)

//Did not want to use this...
/obj/machinery/cooking_with_jane/grill/Process()

	//if(on_fire)
		//Do bad things if it is on fire.

	for(var/i=1, i<=2, i++)
		if(switches[i])
			handle_cooking(null, i, FALSE)

	//Under normal circumstances, Only process the rest of this 10 process calls; it doesn't need to be hyper-accurate.
	if(check_on_10 != 10)
		check_on_10++
		return
	else
		check_on_10 = 0

	if(switches[1] == 1)
		if(!stored_wood)
			handle_switch(null, 1)
		else
			stored_wood -= 1

	if(switches[2] == 1)
		if(!stored_wood)
			handle_switch(null, 1)
		else
			stored_wood -= 1

/obj/machinery/cooking_with_jane/grill/RefreshParts()
	..()

	var/las_rating = 0
	for(var/obj/item/stock_parts/micro_laser/M in component_parts)
		las_rating += M.rating
	quality_mod = round(las_rating/2)

	var/bin_rating = 0
	for(var/obj/item/stock_parts/matter_bin/M in component_parts)
		bin_rating += M.rating
	wood_maximum = 15 * bin_rating

/obj/machinery/cooking_with_jane/grill/examine(mob/user, extra_description = "")
	if(!..(user, extra_description))
		return FALSE
	if(contents)
		extra_description += span_notice("\nCharcoal: [stored_wood]/[wood_maximum]")

//Process how a specific grill is interacting with material
/obj/machinery/cooking_with_jane/grill/proc/cook_checkin(input)

	if(items[input])
		#ifdef CWJ_DEBUG
		log_debug("/cooking_with_jane/grill/proc/cook_checkin called on burner [input]")
		#endif
		var/old_timestamp = cooking_timestamp[input]
		switch(temperature[input])
			if("Low")
				spawn(CWJ_BURN_TIME_LOW)
					if(cooking_timestamp[input] == old_timestamp)
						handle_burning(input)
				spawn(CWJ_IGNITE_TIME_LOW)
					if(cooking_timestamp[input] == old_timestamp)
						handle_ignition(input)

			if("Medium")
				spawn(CWJ_BURN_TIME_MEDIUM)
					if(cooking_timestamp[input] == old_timestamp)
						handle_burning(input)
				spawn(CWJ_IGNITE_TIME_MEDIUM)
					if(cooking_timestamp[input] == old_timestamp)
						handle_ignition(input)

			if("High")
				spawn(CWJ_BURN_TIME_HIGH)
					if(cooking_timestamp[input] == old_timestamp)
						handle_burning(input)
				spawn(CWJ_IGNITE_TIME_HIGH)
					if(cooking_timestamp[input] == old_timestamp)
						handle_ignition(input)

/obj/machinery/cooking_with_jane/grill/proc/handle_burning(input)
	if(!(items[input] && istype(items[input], /obj/item/reagent_containers/cooking_with_jane/cooking_container)))
		return

	var/obj/item/reagent_containers/cooking_with_jane/cooking_container/container = items[input]
	container.handle_burning()

/obj/machinery/cooking_with_jane/grill/proc/handle_ignition(input)
	if(!(items[input] && istype(items[input], /obj/item/reagent_containers/cooking_with_jane/cooking_container)))
		return

	var/obj/item/reagent_containers/cooking_with_jane/cooking_container/container = items[input]
	if(container.handle_ignition())
		on_fire = TRUE

//Retrieve which half of the baking pan is being used.
/obj/machinery/cooking_with_jane/grill/proc/getInput(params)
	var/list/click_params = params2list(params)
	var/input
	var/icon_x = text2num(click_params["icon-x"])
	if(icon_x <= ICON_SPLIT_X)
		input = 1
	else if(icon_x > ICON_SPLIT_X)
		input = 2
	#ifdef CWJ_DEBUG
	log_debug("cooking_with_jane/grill/proc/getInput returned burner [input]. icon-x: [click_params["icon-x"]], icon-y: [click_params["icon-y"]]")
	#endif
	return input

/obj/machinery/cooking_with_jane/grill/attackby(obj/item/used_item, mob/user, params)
	if(default_deconstruction(used_item, user))
		return


	if(istype(used_item, /obj/item/stack/material/wood))
		var/obj/item/stack/material/wood/stack = used_item
		var/used_sheets = min(stack.get_amount(), (wood_maximum - stored_wood))
		if(!used_sheets)
			to_chat(user, span_notice("The grill's hopper is full."))
			return
		to_chat(user, span_notice("You add [used_sheets] wood plank[used_sheets>1?"s":""] into the grill's hopper."))
		if(!stack.use(used_sheets))
			qdel(stack)	// Protects against weirdness
		stored_wood += used_sheets
		if(prob(5))
			src.visible_message(span_danger("The Grill exclaims: \"OM NOM NOM~! YUMMIE~~!\""))

		flick("wood_load", hopper_insert)

		return


	var/input = getInput(params)

	if(items[input] != null)
		var/obj/item/reagent_containers/cooking_with_jane/cooking_container/container = items[input]
		container.process_item(used_item, params)

	else if(istype(used_item, /obj/item/reagent_containers/cooking_with_jane/cooking_container/grill_grate))
		to_chat(usr, span_notice("You put a [used_item] on the grill."))
		if(usr.canUnEquip(used_item))
			usr.unEquip(used_item, src)
		else
			used_item.forceMove(src)
		items[input] = used_item
		if(switches[input] == 1)
			cooking_timestamp[input] = world.time
	update_icon()


/obj/machinery/cooking_with_jane/grill/attack_hand(mob/user as mob, params)
	var/input = getInput(params)
	if(items[input] != null)
		if(switches[input] == 1)
			handle_cooking(user, input)
			cooking_timestamp[input] = world.time
			if(ishuman(user) && (temperature[input] == "High" || temperature[input] == "Medium" ))
				var/mob/living/carbon/human/burn_victim = user
				if(!burn_victim.gloves)
					switch(temperature[input])
						if("High")
							burn_victim.adjustFireLoss(5)
						if("Medium")
							burn_victim.adjustFireLoss(2)
					to_chat(burn_victim, span_danger("You burn your hand a little taking the [items[input]] off of the grill."))
		user.put_in_hands(items[input])
		items[input] = null
		update_icon()

/obj/machinery/cooking_with_jane/grill/CtrlClick(mob/user, params)
	if(user.stat || user.restrained() || (!in_range(src, user)))
		return

	var/input = getInput(params)
	#ifdef CWJ_DEBUG
	log_debug("/cooking_with_jane/grill/CtrlClick called on burner [input]")
	#endif
	var/choice = alert(user,"Select an action for burner #[input]","Select One:","Set temperature","Set timer","Cancel")
	switch(choice)
		if("Set temperature")
			handle_temperature(user, input)
		if("Set timer")
			handle_timer(user, input)

//Switch the cooking device on or off
/obj/machinery/cooking_with_jane/grill/CtrlShiftClick(mob/user, params)

	if(user.stat || user.restrained() || (!in_range(src, user)))
		return
	var/input = getInput(params)

	#ifdef CWJ_DEBUG
	log_debug("/cooking_with_jane/grill/CtrlClick called on burner [input]")
	#endif
	handle_switch(user, input)

//Empty a container without a tool
/obj/machinery/cooking_with_jane/grill/AltClick(mob/user, params)
	if(user.stat || user.restrained() || (!in_range(src, user)))
		return

	var/input = getInput(params)
	if(!(items[input] && istype(items[input], /obj/item/reagent_containers/cooking_with_jane/cooking_container)))
		return
	var/obj/item/reagent_containers/cooking_with_jane/cooking_container/container = items[input]

	#ifdef CWJ_DEBUG
	log_debug("/cooking_with_jane/grill/AltClick called on burner [input] [container]")
	#endif
	container.do_empty(user)

/obj/machinery/cooking_with_jane/grill/proc/handle_temperature(user, input)
	var/old_temp = temperature[input]
	var/choice = input(user,"Select a heat setting for burner #[input].\nCurrent temp :[old_temp]","Select Temperature",old_temp) in list("High","Medium","Low","Cancel")
	if(choice && choice != "Cancel" && choice != old_temp)
		temperature[input] = choice
		if(switches[input] == 1)
			handle_cooking(user, input)
			cooking_timestamp[input] = world.time
			timerstamp[input]=world.time
			#ifdef CWJ_DEBUG
			log_debug("Timerstamp no. [input] set! New timerstamp: [timerstamp[input]]")
			#endif


/obj/machinery/cooking_with_jane/grill/proc/handle_timer(user, input)
	var/old_time = timer[input]? round((timer[input]/(1 SECONDS)), 1 SECONDS): 1
	timer[input] = (input(user, "Enter a timer for burner #[input] (In Seconds, 0 Stays On) ","Set Timer", old_time) as num) SECONDS
	if(timer[input] != 0 && switches[input] == 1)
		timer_act(user, input)
	update_icon()

//input: 1 thru 4, depends on which burner was selected
/obj/machinery/cooking_with_jane/grill/proc/timer_act(mob/user, input)

	timerstamp[input]=round(world.time)
	#ifdef CWJ_DEBUG
	log_debug("Timerstamp no. [input] set! New timerstamp: [timerstamp[input]]")
	#endif
	var/old_timerstamp = timerstamp[input]
	spawn(timer[input])
		#ifdef CWJ_DEBUG
		log_debug("Comparimg timerstamp([input]) of [timerstamp[input]] to old_timerstamp [old_timerstamp]")
		#endif
		if(old_timerstamp == timerstamp[input])
			playsound(src, 'sound/items/lighter.ogg', 100, 1, 0)

			handle_cooking(user, input, TRUE) //Do a check in the cooking interface
			switches[input] = 0
			timerstamp[input]=world.time
			cooking_timestamp[input] = world.time
			update_icon()
	update_icon()

/obj/machinery/cooking_with_jane/grill/proc/handle_switch(user, input)
	playsound(src, 'sound/items/lighter.ogg', 100, 1, 0)
	if(switches[input] == 1)
		handle_cooking(user, input)
		switches[input] = 0
		timerstamp[input]=world.time
		#ifdef CWJ_DEBUG
		log_debug("Timerstamp no. [input] set! New timerstamp: [timerstamp[input]]")
		#endif
		cooking_timestamp[input] = world.time
	else if(stored_wood)
		switches[input] = 1
		cooking_timestamp[input] = world.time
		cook_checkin(input)
		if(timer[input] != 0)
			timer_act(user, input)
	update_icon()



/obj/machinery/cooking_with_jane/grill/proc/handle_cooking(mob/user, input, set_timer=FALSE)

	if(!(items[input] && istype(items[input], /obj/item/reagent_containers/cooking_with_jane/cooking_container)))
		return

	var/obj/item/reagent_containers/cooking_with_jane/cooking_container/container = items[input]
	if(set_timer)
		reference_time = timer[input]
	else
		reference_time = world.time - cooking_timestamp[input]

	#ifdef CWJ_DEBUG
	log_debug("grill/proc/handle_cooking data:")
	log_debug("     temperature: [temperature[input]]")
	log_debug("     reference_time: [reference_time]")
	log_debug("     world.time: [world.time]")
	log_debug("     cooking_timestamp: [cooking_timestamp[input]]")
	log_debug("     grill_data: [container.grill_data]")
	#endif


	if(container.grill_data[temperature[input]])
		container.grill_data[temperature[input]] += reference_time
	else
		container.grill_data[temperature[input]] = reference_time


	if(user && user.Adjacent(src))
		container.process_item(src, user, send_message=TRUE)
	else
		container.process_item(src, user)



/obj/machinery/cooking_with_jane/grill/update_icon()
	cut_overlays()

	for(var/obj/item/our_item in vis_contents)
		src.remove_from_visible(our_item)

	icon_state="grill"

	var/grill_on = FALSE
	for(var/i=1, i<=2, i++)
		if(switches[i] == TRUE)
			if(!grill_on)
				grill_on = TRUE
			add_overlay(image(src.icon, icon_state="fire_[i]"))

	for(var/i=1, i<=2, i++)
		if(!(items[i]))
			continue
		var/obj/item/our_item = items[i]
		switch(i)
			if(1)
				our_item.pixel_x = -7
				our_item.pixel_y = 0
			if(2)
				our_item.pixel_x = 7
				our_item.pixel_y = 0
		src.add_to_visible(our_item, i)

/obj/machinery/cooking_with_jane/grill/proc/add_to_visible(obj/item/our_item, input)
	our_item.vis_flags = VIS_INHERIT_LAYER | VIS_INHERIT_PLANE | VIS_INHERIT_ID
	src.vis_contents += our_item
	if(input == 2 || input == 4)
		var/matrix/M = matrix()
		M.Scale(-1,1)
		our_item.transform = M
	our_item.transform *= 0.8

/obj/machinery/cooking_with_jane/grill/proc/remove_from_visible(obj/item/our_item, input)
	our_item.vis_flags = 0
	our_item.blend_mode = 0
	our_item.transform =  null
	src.vis_contents.Remove(our_item)

/obj/machinery/cooking_with_jane/grill/verb/toggle_burner_1()
	set src in view(1)
	set name = "Grill burner 1 - Toggle"
	set category = "Object"
	set desc = "Turn on a burner on the grill"
	#ifdef CWJ_DEBUG
	log_debug("/cooking_with_jane/grill/verb/toggle_burner_1() called to toggle burner 1")
	#endif
	if(!ishuman(usr) && !isrobot(usr))
		return
	handle_switch(usr, 1)

/obj/machinery/cooking_with_jane/grill/verb/toggle_burner_2()
	set src in view(1)
	set name = "Grill burner 2 - Toggle"
	set category = "Object"
	set desc = "Turn on a burner on the grill"
	#ifdef CWJ_DEBUG
	log_debug("/cooking_with_jane/grill/verb/toggle_burner_2() called to toggle burner 2")
	#endif
	if(!ishuman(usr) && !isrobot(usr))
		return
	handle_switch(usr, 2)

/obj/machinery/cooking_with_jane/grill/verb/change_temperature_1()
	set src in view(1)
	set name = "Grill burner 1 - Set Temp"
	set category = "Object"
	set desc = "Set a temperature for a burner."
	#ifdef CWJ_DEBUG
	log_debug("/cooking_with_jane/grill/verb/change_temperature_1() called to change temperature on 1")
	#endif
	if(!ishuman(usr) && !isrobot(usr))
		return
	handle_temperature(usr, 1)

/obj/machinery/cooking_with_jane/grill/verb/change_temperature_2()
	set src in view(1)
	set name = "Grill burner 2 - Set Temp"
	set category = "Object"
	set desc = "Set a temperature for a burner."
	#ifdef CWJ_DEBUG
	log_debug("/cooking_with_jane/grill/verb/change_temperature_2() called to change temperature on 2")
	#endif
	if(!ishuman(usr) && !isrobot(usr))
		return
	handle_temperature(usr, 2)

/obj/machinery/cooking_with_jane/grill/verb/change_timer_1()
	set src in view(1)
	set name = "Grill burner 1 - Set Timer"
	set category = "Object"
	set desc = "Set a timer for a burner."
	#ifdef CWJ_DEBUG
	log_debug("/cooking_with_jane/grill/verb/change_timer_1() called to change timer on 1")
	#endif
	if(!ishuman(usr) && !isrobot(usr))
		return
	handle_timer(usr, 1)

/obj/machinery/cooking_with_jane/grill/verb/change_timer_2()
	set src in view(1)
	set name = "Grill burner 2 - Set Timer"
	set category = "Object"
	set desc = "Set a timer for a burner."
	#ifdef CWJ_DEBUG
	log_debug("/cooking_with_jane/grill/verb/change_timer_2() called to change timer on 2")
	#endif
	if(!ishuman(usr) && !isrobot(usr))
		return
	handle_timer(usr, 2)


#undef ICON_SPLIT_X
