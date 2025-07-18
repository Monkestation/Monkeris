
#define HOLD_CASINGS	0 //do not do anything after firing. Manual action, like pump shotguns, or guns that want to define custom behaviour
#define EJECT_CASINGS	1 //drop spent casings on the ground after firing
#define CYCLE_CASINGS 	2 //experimental: cycle casings, like a revolver. Also works for multibarrelled guns


/obj/item/gun/projectile
	name = "gun"
	desc = "A gun that fires bullets."
	icon = 'icons/obj/guns/projectile.dmi'
	icon_state = "revolver"
	origin_tech = list(TECH_COMBAT = 2, TECH_MATERIAL = 2)
	w_class = ITEM_SIZE_NORMAL
	matter = list(MATERIAL_STEEL = 1)
	bad_type = /obj/item/gun/projectile
	spawn_tags = SPAWN_TAG_GUN_PROJECTILE

	var/caliber = CAL_357		//determines which casings will fit
	var/handle_casings = EJECT_CASINGS	//determines how spent casings should be handled
	var/load_method = SINGLE_CASING|SPEEDLOADER //1 = Single shells, 2 = box or quick loader, 3 = magazine
	var/obj/item/ammo_casing/chambered

	//gunporn stuff
	var/unload_sound = 'sound/weapons/guns/interact/pistol_magout.ogg'
	var/reload_sound = 'sound/weapons/guns/interact/pistol_magin.ogg'
	var/cocked_sound = 'sound/weapons/guns/interact/pistol_cock.ogg'
	var/bulletinsert_sound = 'sound/weapons/guns/interact/bullet_insert.ogg'

	//For SINGLE_CASING or SPEEDLOADER guns
	var/max_shells = 0			//the number of casings that will fit inside
	var/ammo_type		//the type of ammo that the gun comes preloaded with
	var/list/loaded = list()	//stored ammo

	//For MAGAZINE guns
	var/magazine_type		//the type of magazine that the gun comes preloaded with
	var/obj/item/ammo_magazine/ammo_magazine	 //stored magazine
	var/mag_well = MAG_WELL_GENERIC	//What kind of magazines the gun can load
	var/auto_eject = FALSE			//if the magazine should automatically eject itself when empty.
	var/auto_eject_sound
	var/ammo_mag = "default" // magazines + gun itself. if set to default, then not used
	var/tac_reloads = TRUE	// Enables guns to eject mag and insert new magazine.
	var/no_internal_mag = FALSE // to bar sniper and double-barrel from installing overshooter.

	//for sawable guns
	var/saw_off = FALSE
	var/sawn //what it will becone after sawing

/obj/item/gun/projectile/Destroy()
	QDEL_NULL(chambered)
	QDEL_NULL(ammo_magazine)
	QDEL_LIST(loaded)
	return ..()

/obj/item/gun/projectile/proc/cock_gun(mob/user)
	set waitfor = 0
	if(cocked_sound)
		sleep(3)
		if(user && loc) playsound(src.loc, cocked_sound, 75, 1)
	set_item_state()

/obj/item/gun/projectile/consume_next_projectile()
	//get the next casing
	if(loaded.len)
		chambered = loaded[1] //load next casing.
		if(handle_casings != HOLD_CASINGS)
			loaded -= chambered
	else if(ammo_magazine && ammo_magazine.stored_ammo.len)
		chambered = ammo_magazine.stored_ammo[1]
		if(handle_casings != HOLD_CASINGS)
			ammo_magazine.stored_ammo -= chambered

	if (chambered)
		return chambered.BB
	return null

/obj/item/gun/projectile/handle_post_fire()
	..()
	if(chambered)
		chambered.expend()
		process_chambered()

/obj/item/gun/projectile/handle_click_empty()
	..()
	process_chambered()

/obj/item/gun/projectile/proc/process_chambered()
	if (!chambered) return

	if(chambered.is_caseless)
		QDEL_NULL(chambered)
		return
	// Aurora forensics port, gunpowder residue.
	if(chambered.leaves_residue)
		var/mob/living/carbon/human/H = loc
		if(istype(H))
			if(!H.gloves)
				H.gunshot_residue = chambered.caliber
			else
				var/obj/item/clothing/G = H.gloves
				G.gunshot_residue = chambered.caliber

	switch(handle_casings)
		if(EJECT_CASINGS) //eject casing onto ground.
			chambered.forceMove(get_turf(src))
			for(var/obj/item/ammo_casing/temp_casing in chambered.loc)
				if(temp_casing == chambered)
					continue
				if((temp_casing.type == chambered.type) && !temp_casing.BB)
					var/temp_amount = temp_casing.amount + chambered.amount
					if(temp_amount > chambered.maxamount)
						temp_casing.amount -= (chambered.maxamount - chambered.amount)
						chambered.amount = chambered.maxamount
						temp_casing.update_icon()
					else
						chambered.amount = temp_amount
						QDEL_NULL(temp_casing)
					chambered.update_icon()

			playsound(src.loc, casing_sound, 50, 1)
		if(CYCLE_CASINGS) //cycle the casing back to the end.
			if(ammo_magazine)
				ammo_magazine.stored_ammo += chambered
			else
				loaded += chambered

	if(handle_casings != HOLD_CASINGS)
		chambered = null


//Attempts to load A into src, depending on the type of thing being loaded and the load_method
//Maybe this should be broken up into separate procs for each load method?
/obj/item/gun/projectile/proc/load_ammo(obj/item/A, mob/user)
	if(istype(A, /obj/item/ammo_magazine))
		var/obj/item/ammo_magazine/AM = A
		update_wear_icon()
		if(!(load_method & AM.mag_type) || caliber != AM.caliber)
			to_chat(user, span_warning("[AM] won't fit into the magwell. This mag and ammunition inside it is incompatible with [src]."))
			return //incompatible

		//How are we trying to apply this magazine to this gun?
		//Its possible for both magazines and guns to support multiple load methods.
		//In the case of that, we use a fixed order to determine whats most desireable
		var/method_for_this_load = 0

		//Magazine loading takes precedence first
		if ((load_method & AM.mag_type) & MAGAZINE)
			method_for_this_load = MAGAZINE
		//Speedloading second
		else if ((load_method & AM.mag_type) & SPEEDLOADER)
			method_for_this_load = SPEEDLOADER
		else if ((load_method & AM.mag_type) & SINGLE_CASING)
			method_for_this_load = SINGLE_CASING
		else
			//Not sure how this could happen, sanity check. Abort and return if none of the above were true
			return

		switch(method_for_this_load)
			if(MAGAZINE)
				//if(AM.ammo_mag != ammo_mag && ammo_mag != "default")	Not needed with mag_wells
				//	to_chat(user, span_warning("[src] requires another magazine.")) //wrong magazine
				//	return
				if(tac_reloads && ammo_magazine)
					unload_ammo(user)	// ejects the magazine before inserting the new one.
					to_chat(user, span_notice("You tactically reload your [src] with [AM]!"))
				else if(ammo_magazine)
					to_chat(user, span_warning("[src] already has a magazine loaded.")) //already a magazine here
					return
				if(!(AM.mag_well & mag_well))
					to_chat(user, span_warning("[AM] won't fit into the magwell.")) //wrong magazine
					return
				user.remove_from_mob(AM)
				. = 1
				AM.loc = src
				ammo_magazine = AM

				if(reload_sound) playsound(src.loc, reload_sound, 75, 1)
				cock_gun(user)
				update_firemode()
			if(SPEEDLOADER)
				if(loaded.len >= max_shells)
					to_chat(user, span_warning("[src] is full!"))
					return
				var/count = 0
				if(AM.reload_delay)
					to_chat(user, span_notice("It takes some time to reload [src] with [AM]..."))
				if (do_after(user, AM.reload_delay, user))
					for(var/obj/item/ammo_casing/C in AM.stored_ammo)
						if(loaded.len >= max_shells)
							break
						if(C.caliber == caliber)
							C.forceMove(src)
							loaded += C
							AM.stored_ammo -= C //should probably go inside an ammo_magazine proc, but I guess less proc calls this way...
							count++
				if(count)
					user.visible_message("[user] reloads [src].", span_notice("You load [count] round\s into [src]."))
					if(reload_sound) playsound(src.loc, reload_sound, 75, 1)
					cock_gun(user)
					. = 1
				update_firemode()
				update_icon()
				set_item_state()
		AM.update_icon()
	else if(istype(A, /obj/item/ammo_casing))
		var/obj/item/ammo_casing/C = A
		if(!(load_method & SINGLE_CASING) || caliber != C.caliber)
			to_chat(user, span_warning("[src] is incompatible with [C]."))
			return //incompatible
		if(loaded.len >= max_shells)
			to_chat(user, span_warning("[src] is full."))
			return

		if(C.reload_delay)
			to_chat(user, span_notice("It takes some time to reload [src] with [C]..."))
		if (!do_after(user, C.reload_delay, user))
			return

		if(C.amount > 1)
			C.amount -= 1
			var/obj/item/ammo_casing/inserted_casing = new C.type(C)	//Couldn't make it seperate, so it must be cloned
			loaded.Insert(1, inserted_casing)
			inserted_casing.forceMove(src)
		else
			user.remove_from_mob(C)
			C.forceMove(src)
			loaded.Insert(1, C) //add to the head of the list
		update_firemode()
		. = 1
		user.visible_message("[user] inserts \a [C] into [src].", span_notice("You insert \a [C] into [src]."))
		if(bulletinsert_sound) playsound(src.loc, bulletinsert_sound, 75, 1)

	update_icon()
	update_held_icon()

//attempts to unload src. If allow_dump is set to 0, the speedloader unloading method will be disabled
/obj/item/gun/projectile/proc/unload_ammo(mob/user, allow_dump=1)
	if(ammo_magazine)
		user.put_in_hands(ammo_magazine)

		if(unload_sound)
			playsound(src.loc, unload_sound, 75, 1)
		ammo_magazine.update_icon()
		ammo_magazine = null
	else if(loaded.len)
		//presumably, if it can be speed-loaded, it can be speed-unloaded.
		if(allow_dump && (load_method & SPEEDLOADER))
			var/count = 0
			var/turf/T = get_turf(user)
			if(T)
				for(var/obj/item/ammo_casing/C in loaded)
					C.forceMove(T)
					count++
				loaded.Cut()
			if(count)
				user.visible_message("[user] unloads [src].", span_notice("You unload [count] round\s from [src]."))
				if(bulletinsert_sound) playsound(src.loc, bulletinsert_sound, 75, 1)
		else if(load_method & SINGLE_CASING)
			var/obj/item/ammo_casing/C = loaded[loaded.len]
			loaded.len--
			user.put_in_hands(C)
			user.visible_message("[user] removes \a [C] from [src].", span_notice("You remove \a [C] from [src]."))
			if(bulletinsert_sound) playsound(src.loc, bulletinsert_sound, 75, 1)
	else
		to_chat(user, span_warning("[src] is empty."))
	update_icon()
	update_held_icon()

// Modular guns overwrite this
/obj/item/gun/projectile/attackby(obj/item/A as obj, mob/user as mob)
	.=..()
	if(QUALITY_SAWING in A.tool_qualities)
		to_chat(user, span_notice("You begin to saw down \the [src]."))
		if(saw_off == FALSE)
			to_chat(user, span_notice("Sawing down \the [src] will achieve nothing or may impede operation."))
			return
		if (src.item_upgrades.len)
			if(src.dna_compare_samples) //or else you can override dna lock
				to_chat(user, span_notice("Sawing down \the [src] will not allow use of the firearm."))
				return
			if("No" == input(user, "There are attachments present. Would you like to destroy them?") in list("Yes", "No"))
				return
		if(loaded.len)
			for(var/i in 1 to max_shells)
				afterattack(user, user)	//will this work? //it will. we call it twice, for twice the FUN
				playsound(user, fire_sound, 50, 1)
			user.visible_message(span_danger("The [src] goes off!"), span_danger("The [src] goes off in your face!"))
			return
		if(saw_off && A.use_tool(user, src, WORKTIME_LONG, QUALITY_SAWING, FAILCHANCE_NORMAL, required_stat = STAT_MEC))
			var/obj/item/gun/projectile/sawnoff = new sawn(usr.loc)
			sawnoff.caliber = caliber
			to_chat(user, span_warning("You cut down the stock, barrel, and anything else nice from \the [src], ruining a perfectly good weapon."))
			qdel(src)
	if (!.) //Parent returns true if attackby is handled
		load_ammo(A, user)
		update_held_icon()

/obj/item/gun/projectile/attack_self(mob/user as mob)
	if(firemodes.len > 1)
		..()
	else
		unload_ammo(user)

/obj/item/gun/projectile/attack_hand(mob/user as mob)
	if(user.get_inactive_held_item() == src)
		unload_ammo(user, allow_dump=0)
	else
		return ..()

/obj/item/gun/projectile/MouseDrop(over_object, src_location, over_location)
	..()
	if(src.loc == usr && istype(over_object, /obj/screen/inventory/hand))
		unload_ammo(usr, allow_dump=0)

/obj/item/gun/projectile/afterattack(atom/A, mob/living/user)
	..()
	if(auto_eject && ammo_magazine && ammo_magazine.stored_ammo && !ammo_magazine.stored_ammo.len)
		ammo_magazine.forceMove(get_turf(src.loc))
		user.visible_message(
			"[ammo_magazine] falls out and clatters on the floor!",
			span_notice("[ammo_magazine] falls out and clatters on the floor!")
			)
		if(auto_eject_sound)
			playsound(user, auto_eject_sound, 40, 1)
		ammo_magazine.update_icon()
		ammo_magazine = null
		update_icon() //make sure to do this after unsetting ammo_magazine
		set_item_state()

/obj/item/gun/projectile/examine(mob/user, extra_description = "")
	if(ammo_magazine)
		extra_description += "It has \a [ammo_magazine] loaded.\n"
	extra_description += "Has [get_ammo()] round\s remaining."
	..(user, extra_description)

/obj/item/gun/projectile/proc/get_ammo()
	var/bullets = 0
	if(loaded)
		bullets += loaded.len
	if(ammo_magazine && ammo_magazine.stored_ammo)
		bullets += ammo_magazine.stored_ammo.len
	if(chambered)
		bullets += 1
	return bullets

/obj/item/gun/projectile/proc/get_max_ammo()
	var/bullets = 0
	if (load_method & MAGAZINE)
		if(ammo_magazine)
			bullets += ammo_magazine.max_ammo
	if (load_method & SPEEDLOADER)
		bullets += max_shells
	return bullets

/* Unneeded -- so far.
//in case the weapon has firemodes and can't unload using attack_hand()
/obj/item/gun/projectile/verb/unload_gun()
	set name = "Unload Ammo"
	set category = "Object"
	set src in usr

	if(usr.stat || usr.restrained()) return

	unload_ammo(usr)
*/

/obj/item/gun/projectile/nano_ui_data(mob/user)
	var/list/data = ..()
	data["caliber"] = caliber
	data["current_ammo"] = get_ammo()
	data["max_shells"] = get_max_ammo()

	return data

/obj/item/gun/projectile/get_dud_projectile()
	var/proj_type
	if(chambered)
		proj_type = chambered.BB.type
	else if(loaded.len)
		var/obj/item/ammo_casing/A = loaded[1]
		if(!A.BB)
			return null
		proj_type = A.BB.type
	else if(ammo_magazine && ammo_magazine.stored_ammo.len)
		var/obj/item/ammo_casing/A = ammo_magazine.stored_ammo[1]
		if(!A.BB)
			return null
		proj_type = A.BB.type
	if(!proj_type)
		return null
	return new proj_type

/obj/item/gun/projectile/refresh_upgrades()
	max_shells = initial(max_shells)
	..()

/obj/item/gun/projectile/generate_guntags()
	..()
	gun_tags |= GUN_PROJECTILE
	switch(caliber)
		if(CAL_PISTOL)
			gun_tags |= GUN_CALIBRE_35
		//Others to be implemented when needed
	if(max_shells && !no_internal_mag) // so the overshooter can't be attached to the AMR and double-barrel anymore
		gun_tags |= GUN_INTERNAL_MAG
