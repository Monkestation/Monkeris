// AI (i.e. game AI, not the AI player) controlled bots

/obj/machinery/bot
	icon = 'icons/obj/aibots.dmi'
	layer = MOB_LAYER
	light_range = 3
	use_power = NO_POWER_USE
	var/obj/item/card/id/botcard			// the ID card that the bot "holds"
	var/on = TRUE
	health = 0 //do not forget to set health for your bot!
	maxHealth = 0
	var/fire_dam_coeff = 1
	var/brute_dam_coeff = 1
	var/open = 0//Maint panel
	var/locked = 1
	//var/emagged = 0 //Urist: Moving that var to the general /bot tree as it's used by most bots

/obj/machinery/bot/proc/turn_on()
	if(stat)	return 0
	on = TRUE
	set_light(initial(light_range))
	return 1

/obj/machinery/bot/proc/turn_off()
	on = FALSE
	set_light(0)

/obj/machinery/bot/proc/explode()
	qdel(src)

/obj/machinery/bot/proc/healthcheck()
	if (src.health <= 0)
		src.explode()

/obj/machinery/bot/emag_act(remaining_charges, user)
	if(locked && !emagged)
		locked = 0
		emagged = 1
		to_chat(user, span_warning("You short out [src]'s maintenance hatch lock."))
		log_and_message_admins("emagged [src]'s maintenance hatch lock")
		return 1

	if(!locked && open && emagged == 1)
		emagged = 2
		log_and_message_admins("emagged [src]'s inner circuits")
		return 1

/obj/machinery/bot/examine(mob/user, extra_description = "")
	if(health < maxHealth)
		if(health > maxHealth / 3)
			extra_description += span_warning("[src]'s parts look loose.")
		else
			extra_description += span_danger("[src]'s parts look very loose!")
	..(user, extra_description)

/obj/machinery/bot/attackby(obj/item/W as obj, mob/user as mob)
	if(istype(W, /obj/item/tool/screwdriver))
		if(!locked)
			open = !open
			to_chat(user, span_notice("Maintenance panel is now [src.open ? "opened" : "closed"]."))
	else if(istype(W, /obj/item/tool/weldingtool))
		if(health < maxHealth)
			if(open)
				health = min(maxHealth, health+10)
				user.visible_message(span_warning("[user] repairs [src]!"),span_notice("You repair [src]!"))
				user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
			else
				to_chat(user, span_notice("Unable to repair with the maintenance panel closed."))
		else
			to_chat(user, span_notice("[src] does not need a repair."))
	else
		if(hasvar(W,"force") && hasvar(W,"damtype"))
			switch(W.damtype)
				if("fire")
					src.health -= W.force * fire_dam_coeff
				if("brute")
					src.health -= W.force * brute_dam_coeff
			user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
			..()
			healthcheck()
		else
			..()

/obj/machinery/bot/bullet_act(obj/item/projectile/Proj)
	if(!Proj.get_structure_damage())
		return
	health -= Proj.get_structure_damage()
	..()
	healthcheck()

/obj/machinery/bot/take_damage(amount)
	health -= amount/10 * brute_dam_coeff * 2
	health -= amount/10 * fire_dam_coeff
	healthcheck()


/obj/machinery/bot/emp_act(severity)
	var/was_on = on
	stat |= EMPED
	new /obj/effect/overlay/pulse(loc)

	if(on)
		turn_off()
	spawn(severity * 300)
		stat &= ~EMPED
		if (was_on)
			turn_on()


/obj/machinery/bot/attack_ai(mob/user as mob)
	src.attack_hand(user)

/obj/machinery/bot/attack_hand(mob/living/carbon/human/user)

	if(!istype(user))
		return ..()

	if(user.species.can_shred(user))
		src.health -= rand(15,30)*brute_dam_coeff
		src.visible_message(span_danger("[user] has slashed [src]!"))
		playsound(src.loc, 'sound/weapons/slice.ogg', 25, 1, -1)
		if(prob(10))
			new /obj/effect/decal/cleanable/blood/oil(src.loc)
		healthcheck()

/******************************************************************/
// Navigation procs
// Used for A-star pathfinding


// Returns the surrounding cardinal turfs with open links
// Including through doors openable with the ID
/turf/proc/CardinalTurfsWithAccess(obj/item/card/id/ID)
	var/L[] = new()

	//	for(var/turf/t in oview(src,1))

	for(var/d in GLOB.cardinal)
		var/turf/T = get_step(src, d)
		if(istype(T) && !T.density)
			if(!LinkBlockedWithAccess(src, T, ID))
				L.Add(T)
	return L


// Returns true if a link between A and B is blocked
// Movement through doors allowed if ID has access
/proc/LinkBlockedWithAccess(turf/A, turf/B, obj/item/card/id/ID)

	if(A == null || B == null) return 1
	var/adir = get_dir(A,B)
	var/rdir = get_dir(B,A)
	if((adir & (NORTH|SOUTH)) && (adir & (EAST|WEST)))	//	diagonal
		var/iStep = get_step(A,adir&(NORTH|SOUTH))
		if(!LinkBlockedWithAccess(A,iStep, ID) && !LinkBlockedWithAccess(iStep,B,ID))
			return 0

		var/pStep = get_step(A,adir&(EAST|WEST))
		if(!LinkBlockedWithAccess(A,pStep,ID) && !LinkBlockedWithAccess(pStep,B,ID))
			return 0
		return 1

	if(DirBlockedWithAccess(A,adir, ID))
		return 1

	if(DirBlockedWithAccess(B,rdir, ID))
		return 1

	for(var/obj/O in B)
		if(O.density && !istype(O, /obj/machinery/door) && !(O.flags & ON_BORDER))
			return 1

	return 0

// Returns true if direction is blocked from loc
// Checks doors against access with given ID
/proc/DirBlockedWithAccess(turf/loc,dir,obj/item/card/id/ID)
	for(var/obj/structure/window/D in loc)
		if(!D.density)			continue
		if(D.dir == SOUTHWEST)	return 1
		if(D.dir == dir)		return 1

	for(var/obj/machinery/door/D in loc)
		if(!D.density)			continue
		if(istype(D, /obj/machinery/door/window))
			if( dir & D.dir )	return !D.check_access(ID)

			//if((dir & SOUTH) && (D.dir & (EAST|WEST)))		return !D.check_access(ID)
			//if((dir & EAST ) && (D.dir & (NORTH|SOUTH)))	return !D.check_access(ID)
		else return !D.check_access(ID)	// it's a real, air blocking door
	return 0
