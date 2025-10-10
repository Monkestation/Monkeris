#define TANK_DISPENSER_CAPACITY 10

/obj/structure/tank_dispenser
	name = "tank dispenser"
	desc = "A simple yet bulky storage device for gas tanks. Holds up to 10 oxygen tanks and 10 plasma tanks."
	icon = 'icons/obj/objects.dmi'
	icon_state = "dispenser"
	density = TRUE
	anchored = TRUE
	w_class = ITEM_SIZE_HUGE
	layer = BELOW_OBJ_LAYER
	spawn_tags = SPAWN_TAG_STRUCTURE_COMMON
	rarity_value = 50
	var/oxygentanks = TANK_DISPENSER_CAPACITY
	var/plasmatanks = TANK_DISPENSER_CAPACITY


/obj/structure/tank_dispenser/oxygen
	desc = "A simple yet bulky storage device for gas tanks. Holds up to 10 oxygen tanks"
	plasmatanks = 0
	rarity_value = 10

/obj/structure/tank_dispenser/plasma
	desc = "A simple yet bulky storage device for gas tanks. Holds up to 10 plasma tanks."
	oxygentanks = 0
	rarity_value = 25


/obj/structure/tank_dispenser/Initialize()
	. = ..()
	update_icon()


/obj/structure/tank_dispenser/update_icon()
	overlays.Cut()
	switch(oxygentanks)
		if(1 to 3)
			overlays += "oxygen-[oxygentanks]"
		if(4 to TANK_DISPENSER_CAPACITY)
			overlays += "oxygen-4"
	switch(plasmatanks)
		if(1 to 4)
			overlays += "plasma-[plasmatanks]"
		if(5 to TANK_DISPENSER_CAPACITY)
			overlays += "plasma-5"

/obj/structure/tank_dispenser/attack_ai(mob/user)
	if(user.Adjacent(src))
		return attack_hand(user)
	..()

/obj/structure/tank_dispenser/attack_hand(mob/user)
	user.set_machine(src)
	ui_interact(user)

/obj/structure/tank_dispenser/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "TankDispenser", name)
		ui.open()

/obj/structure/tank_dispenser/ui_data(mob/user)
	var/list/data = list()
	data["oxygen"] = oxygentanks
	data["plasma"] = plasmatanks

	return data

/obj/structure/tank_dispenser/ui_state(mob/user)
	return GLOB.physical_state

/obj/structure/tank_dispenser/ui_act(action, params)
	. = ..()
	if(.)
		return

	var/obj/item/tank/dispensed_tank
	switch(action)
		if("plasma")
			if (plasmatanks == 0)
				return TRUE
			dispensed_tank = dispense(/obj/item/tank/plasma, usr)
			plasmatanks--
		if("oxygen")
			if (oxygentanks == 0)
				return TRUE
			dispensed_tank = dispense(/obj/item/tank/oxygen, usr)
			oxygentanks--

	to_chat(usr, span_notice("You take [dispensed_tank] out of [src]."))
	playsound(src.loc, 'sound/machines/Custom_extout.ogg', 100, 1)

	usr.set_machine(src)
	update_icon()
	return TRUE


/obj/structure/tank_dispenser/attackby(obj/item/attacking_item, mob/user)
	var/full
	if(istype(attacking_item, /obj/item/tank/plasma))
		if(plasmatanks < TANK_DISPENSER_CAPACITY)
			plasmatanks++
		else
			full = TRUE
	else if(istype(attacking_item, /obj/item/tank/oxygen))
		if(oxygentanks < TANK_DISPENSER_CAPACITY)
			oxygentanks++
		else
			full = TRUE
	else if(!(user.a_intent & I_HURT) || (attacking_item.flags & NOBLUDGEON))
		// TODO: REPLACE WITH balloon_alert(user, "can't insert!")
		say_quote("can't insert!")
		return
	else
		if(QUALITY_BOLT_TURNING in attacking_item.tool_qualities)
			if(attacking_item.use_tool(user, src, WORKTIME_NORMAL, QUALITY_BOLT_TURNING, FAILCHANCE_EASY,  required_stat = STAT_MEC))
				if(anchored)
					to_chat(user, span_notice("You lean down and unwrench [src]."))
					anchored = FALSE
				else
					to_chat(user, span_notice("You wrench [src] into place."))
					anchored = TRUE
				return
		return ..()
	if(full)
		to_chat(user, span_notice("[src] can't hold any more of [attacking_item]."))
		return

	if(!user.unEquip(attacking_item, src))
		return

	playsound(src.loc, 'sound/machines/Custom_extin.ogg', 100, 1)
	if (!do_after(user, 0.5 SECONDS, src, immobile = TRUE))
		return

	to_chat(user, span_notice("You put [attacking_item] in [src]."))
	update_icon()

/obj/structure/tank_dispenser/proc/dispense(tank_type, mob/receiver)
	var/existing_tank = locate(tank_type) in src
	if (isnull(existing_tank))
		existing_tank = new tank_type
	receiver.put_in_hands(existing_tank)

	return existing_tank

#undef TANK_DISPENSER_CAPACITY
