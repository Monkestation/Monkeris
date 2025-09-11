/obj/structure/dispenser
	name = "tank storage unit"
	desc = "A simple yet bulky storage device for gas tanks. Has room for up to ten oxygen tanks, and ten plasma tanks."
	icon = 'icons/obj/objects.dmi'
	icon_state = "dispenser"
	density = TRUE
	anchored = TRUE
	w_class = ITEM_SIZE_HUGE
	layer = BELOW_OBJ_LAYER
	spawn_tags = SPAWN_TAG_STRUCTURE_COMMON
	rarity_value = 50
	var/oxygentanks = 10
	var/plasmatanks = 10
	var/list/oxytanks = list()	//sorry for the similar var names
	var/list/platanks = list()


/obj/structure/dispenser/oxygen
	plasmatanks = 0
	rarity_value = 10

/obj/structure/dispenser/plasma
	oxygentanks = 0
	rarity_value = 25


/obj/structure/dispenser/Initialize()
	. = ..()
	update_icon()


/obj/structure/dispenser/update_icon()
	overlays.Cut()
	switch(oxygentanks)
		if(1 to 3)	overlays += "oxygen-[oxygentanks]"
		if(4 to INFINITY) overlays += "oxygen-4"
	switch(plasmatanks)
		if(1 to 4)	overlays += "plasma-[plasmatanks]"
		if(5 to INFINITY) overlays += "plasma-5"

/obj/structure/dispenser/attack_ai(mob/user)
	if(user.Adjacent(src))
		return attack_hand(user)
	..()

/obj/structure/dispenser/attack_hand(mob/user)
	user.set_machine(src)
	ui_interact(user)

/obj/structure/dispenser/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "TankDispenser", "Tank Storage")
		ui.open()

/obj/structure/dispenser/ui_data(mob/user)
	var/list/data = list()
	data["name"] = name
	data["oxygentanks"] = oxygentanks
	data["plasmatanks"] = plasmatanks

	return data

/obj/structure/dispenser/ui_state(mob/user)
	return GLOB.default_state

/obj/structure/dispenser/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return TRUE

	// Map TGUI actions to existing Topic parameters
	var/list/href_list = list()

	switch(action)
		if("oxygen")
			href_list["oxygen"] = "1"
		if("plasma")
			href_list["plasma"] = "1"

	// Call existing Topic method
	Topic("", href_list)
	return TRUE

/obj/structure/dispenser/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/tank/oxygen) || istype(I, /obj/item/tank/air) || istype(I, /obj/item/tank/anesthetic))
		if(oxygentanks < 10)
			user.drop_item()
			I.forceMove(src)
			oxytanks.Add(I)
			oxygentanks++
			to_chat(user, span_notice("You put [I] in [src]."))
			if(oxygentanks < 5)
				update_icon()
		else
			to_chat(user, span_notice("[src] is full."))
		updateUsrDialog()
		return
	if(istype(I, /obj/item/tank/plasma))
		if(plasmatanks < 10)
			user.drop_item()
			I.forceMove(src)
			platanks.Add(I)
			plasmatanks++
			to_chat(user, span_notice("You put [I] in [src]."))
			if(plasmatanks < 6)
				update_icon()
		else
			to_chat(user, span_notice("[src] is full."))
		updateUsrDialog()
		return
	if(QUALITY_BOLT_TURNING in I.tool_qualities)
		if(I.use_tool(user, src, WORKTIME_NORMAL, QUALITY_BOLT_TURNING, FAILCHANCE_EASY,  required_stat = STAT_MEC))
			if(anchored)
				to_chat(user, span_notice("You lean down and unwrench [src]."))
				anchored = FALSE
			else
				to_chat(user, span_notice("You wrench [src] into place."))
				anchored = TRUE
			return

/obj/structure/dispenser/Topic(href, href_list)
	if(..())
		return 1

	usr.set_machine(src)

	var/obj/item/tank/tank
	if(href_list["oxygen"] && oxygentanks > 0)
		if(oxytanks.len)
			tank = oxytanks[oxytanks.len]	// Last stored tank is always the first one to be dispensed
			oxytanks.Remove(tank)
		else
			tank = new /obj/item/tank/oxygen(loc)
		oxygentanks--
	if(href_list["plasma"] && plasmatanks > 0)
		if(platanks.len)
			tank = platanks[platanks.len]
			platanks.Remove(tank)
		else
			tank = new /obj/item/tank/plasma(loc)
		plasmatanks--

	if(tank)
		tank.forceMove(drop_location())
		to_chat(usr, span_notice("You take [tank] out of [src]."))
		update_icon()

	playsound(usr.loc, 'sound/machines/Custom_extout.ogg', 100, 1)
	updateUsrDialog()
