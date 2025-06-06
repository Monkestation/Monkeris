/obj/item/device/onetankbomb
	name = "bomb"
	icon = 'icons/obj/tank.dmi'
	item_state = "assembly"
	throwforce = WEAPON_FORCE_NORMAL
	w_class = ITEM_SIZE_NORMAL
	throw_speed = 2
	throw_range = 4
	flags = CONDUCT | PROXMOVE
	spawn_frequency = 0
	var/welded = FALSE   //0 - not readied //1 - bomb finished with welder
	var/obj/item/device/assembly_holder/bombassembly   //The first part of the bomb is an assembly holder, holding an igniter+some device
	var/obj/item/tank/bombtank //the second part of the bomb is a plasma tank

/obj/item/device/onetankbomb/examine(mob/user, extra_description = "")
	if(bombtank) // Neither tank, nor the assembly come with any meaningful description, but we have to show something
		user.examine(bombtank)
	else
		..(user, extra_description)

/obj/item/device/onetankbomb/update_icon()
	if(bombtank)
		icon_state = bombtank.icon_state
	if(bombassembly)
		overlays += bombassembly.icon_state
		overlays += bombassembly.overlays
		overlays += "bomb_assembly"

/obj/item/device/onetankbomb/attackby(obj/item/I, mob/user)

	add_fingerprint(user)

	var/tool_type = I.get_tool_type(user, list(QUALITY_BOLT_TURNING, QUALITY_WELDING), src)
	switch(tool_type)

		if(QUALITY_BOLT_TURNING)
			if(I.use_tool(user, src, WORKTIME_FAST, tool_type, FAILCHANCE_VERY_EASY))
				to_chat(user, span_notice("You disassemble [src]."))

				bombassembly.loc = user.loc
				bombassembly.master = null
				bombassembly = null

				bombtank.loc = user.loc
				bombtank.master = null
				bombtank = null

				qdel(src)
			return

		if(QUALITY_WELDING)
			if(I.use_tool(user, src, WORKTIME_FAST, tool_type, FAILCHANCE_VERY_EASY))
				if(!welded)
					welded = TRUE
					// TODO: log_bomber these
					GLOB.bombers += "[key_name(user)] welded a single tank bomb. Temp: [bombtank.air_contents.temperature-T0C]"
					message_admins("[key_name_admin(user)] welded a single tank bomb. Temp: [bombtank.air_contents.temperature-T0C]")
					to_chat(user, span_notice("A pressure hole has been bored to [bombtank] valve. \The [bombtank] can now be ignited."))
					return
				else
					welded = FALSE
					GLOB.bombers += "[key_name(user)] unwelded a single tank bomb. Temp: [bombtank.air_contents.temperature-T0C]"
					to_chat(user, span_notice("The hole has been closed."))
					return
			return

		if(ABORT_CHECK)
			return


	..()

/obj/item/device/onetankbomb/attack_self(mob/user as mob) //pressing the bomb accesses its assembly
	bombassembly.attack_self(user, 1)
	add_fingerprint(user)
	return

/obj/item/device/onetankbomb/receive_signal()	//This is mainly called by the sensor through sense() to the holder, and from the holder to here.
	visible_message("[icon2html(src, hearers(get_turf(src)))] *beep* *beep*", "*beep* *beep*")
	sleep(10)
	if(!src)
		return
	if(welded)
		bombtank.ignite()	//if its not a dud, boom (or not boom if you made shitty mix) the ignite proc is below, in this file
	else
		bombtank.release()

/obj/item/device/onetankbomb/HasProximity(atom/movable/AM as mob|obj)
	if(bombassembly)
		bombassembly.HasProximity(AM)

// ---------- Procs below are for tanks that are used exclusively in 1-tank bombs ----------

/obj/item/tank/proc/bomb_assemble(W,user)	//Bomb assembly proc. This turns assembly+tank into a bomb
	var/obj/item/device/assembly_holder/S = W
	var/mob/M = user
	if(!S.secured)										//Check if the assembly is secured
		return
	if(isigniter(S.left_assembly) == isigniter(S.right_assembly))		//Check if either part of the assembly has an igniter, but if both parts are igniters, then fuck it
		return

	var/obj/item/device/onetankbomb/R = new /obj/item/device/onetankbomb(loc)

	M.drop_item()			//Remove the assembly from your hands
	M.remove_from_mob(src)	//Remove the tank from your character,in case you were holding it
	M.put_in_hands(R)		//Equips the bomb if possible, or puts it on the floor.

	R.bombassembly = S	//Tell the bomb about its assembly part
	S.master = R		//Tell the assembly about its new owner
	S.loc = R			//Move the assembly out of the fucking way

	R.bombtank = src	//Same for tank
	master = R
	loc = R
	R.update_icon()
	return

/obj/item/tank/proc/ignite()	//This happens when a bomb is told to explode
	var/fuel_moles = air_contents.gas["plasma"] + air_contents.gas["oxygen"] / 6

	var/turf/ground_zero = get_turf(loc)
	loc = null

	if(air_contents.temperature > (T0C + 400))
		explosion(ground_zero, fuel_moles * 75, fuel_moles * 15)
	else if(air_contents.temperature > (T0C + 250))
		explosion(ground_zero, fuel_moles * 50, fuel_moles * 15)
	else if(air_contents.temperature > (T0C + 100))
		explosion(ground_zero, fuel_moles * 25, fuel_moles * 15)
	ground_zero.assume_air(air_contents)
	ground_zero.hotspot_expose(1000, 125)

	if(master)
		qdel(master)
	qdel(src)

/obj/item/tank/proc/release()	//This happens when the bomb is not welded. Tank contents are just spat out.
	var/datum/gas_mixture/removed = air_contents.remove(air_contents.total_moles)
	var/turf/T = get_turf(src)
	if(!T)
		return
	T.assume_air(removed)
