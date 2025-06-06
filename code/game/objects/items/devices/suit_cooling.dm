/obj/item/device/suit_cooling_unit
	name = "portable suit cooling unit"
	desc = "A portable heat sink and liquid cooled radiator that can be hooked up to a space suit's existing temperature controls to provide industrial levels of cooling."
	w_class = ITEM_SIZE_BULKY
	icon = 'icons/obj/device.dmi'
	icon_state = "suitcooler0"
	slot_flags = SLOT_BACK	//you can carry it on your back if you want, but it won't do anything unless attached to suit storage
	matter = list(MATERIAL_STEEL = 8, MATERIAL_GOLD = 4)

	//copied from tank.dm
	flags = CONDUCT
	force = WEAPON_FORCE_NORMAL
	throwforce = WEAPON_FORCE_NORMAL
	throw_speed = 1
	throw_range = 4

	origin_tech = list(TECH_MAGNET = 2, TECH_MATERIAL = 2)
	suitable_cell = /obj/item/cell/large
	var/on = FALSE				//is it turned on?
	var/cover_open = 0		//is the cover open?
	var/max_cooling = 12				//in degrees per second - probably don't need to mess with heat capacity here
	var/charge_consumption = 3		//charge per second at max_cooling
	var/thermostat = T20C

	//TODO: make it heat up the surroundings when not in space

/obj/item/device/suit_cooling_unit/Initialize()
	. = ..()
	START_PROCESSING(SSobj, src)

/obj/item/device/suit_cooling_unit/Process()
	if(!on)
		return

	if(!cell || cell.is_empty())
		turn_off()
		return

	if(!ismob(loc))
		return

	if(!attached_to_suit(loc))		//make sure they have a suit and we are attached to it
		return

	var/mob/living/carbon/human/H = loc

	var/efficiency = 1 - H.get_pressure_weakness()		//you need to have a good seal for effective cooling
	var/env_temp = get_environment_temperature()		//wont save you from a fire
	var/temp_adj = min(H.bodytemperature - max(thermostat, env_temp), max_cooling)

	if(temp_adj < 0.5)	//only cools, doesn't heat, also we don't need extreme precision
		return

	var/charge_usage = (temp_adj/max_cooling)*charge_consumption

	H.bodytemperature -= temp_adj*efficiency

	if(!cell.checked_use(charge_usage))
		turn_off()

/obj/item/device/suit_cooling_unit/proc/get_environment_temperature()
	if(ishuman(loc))
		var/mob/living/carbon/human/H = loc
		if(istype(H.loc, /mob/living/exosuit))
			var/mob/living/exosuit/M = loc
			return M.bodytemperature
		else if(istype(H.loc, /obj/machinery/atmospherics/unary/cryo_cell))
			var/obj/machinery/atmospherics/unary/cryo_cell/M = loc
			return M.air_contents.temperature

	var/turf/T = get_turf(src)
	if(istype(T, /turf/space))
		return 0	//space has no temperature, this just makes sure the cooling unit works in space

	var/datum/gas_mixture/environment = T.return_air()
	if(!environment)
		return 0

	return environment.temperature

/obj/item/device/suit_cooling_unit/proc/attached_to_suit(mob/M)
	if(!ishuman(M))
		return FALSE

	var/mob/living/carbon/human/H = M

	if(!H.wear_suit || H.s_store != src)
		return FALSE

	return TRUE

/obj/item/device/suit_cooling_unit/proc/turn_on(mob/user)
	if(!cell || cell.is_empty())
		if(user)
			to_chat(user, span_warning("[src] battery is dead or missing."))
		return FALSE

	on = TRUE
	updateicon()

/obj/item/device/suit_cooling_unit/proc/turn_off()
	if(ismob(loc))
		var/mob/M = loc
		M.show_message("\The [src] clicks and whines as it powers down.", 2)	//let them know in case it's run out of power.
	on = FALSE
	updateicon()

/obj/item/device/suit_cooling_unit/attack_self(mob/user)
	if(cover_open && cell)
		if(ishuman(user))
			user.put_in_hands(cell)
		else
			cell.loc = get_turf(loc)

		cell.add_fingerprint(user)
		cell.update_icon()

		to_chat(user, "You remove the [cell].")
		cell = null
		updateicon()
		return

	//TODO use a UI like the air tanks
	if(on)
		turn_off(user)
	else
		turn_on(user)
		if(on)
			to_chat(user, "You switch on the [src].")

/obj/item/device/suit_cooling_unit/attackby(obj/item/W, mob/user)
	if(istype(W, /obj/item/tool/screwdriver))
		if(cover_open)
			cover_open = FALSE
			to_chat(user, "You screw the panel into place.")
		else
			cover_open = TRUE
			to_chat(user, "You unscrew the panel.")
		updateicon()
		return
	return ..()

/obj/item/device/suit_cooling_unit/proc/updateicon()
	if(cover_open)
		if(cell)
			icon_state = "suitcooler1"
		else
			icon_state = "suitcooler2"
	else
		icon_state = "suitcooler0"

/obj/item/device/suit_cooling_unit/examine(mob/user, extra_description = "")
	if(get_dist(user, src) < 2)
		if(on)
			if(attached_to_suit(loc))
				extra_description += "It's switched on and running."
			else
				extra_description += "It's switched on, but not attached to anything."
		else
			extra_description += "It is switched off."

		if(cover_open)
			if(cell)
				extra_description += "\nThe panel is open, exposing the [cell]."
			else
				extra_description += "\nThe panel is open."
	..(user, extra_description)
