/mob/living/verb/resist()
	set name = "Resist"
	set category = "IC"

	if(!stat && can_click())
		setClickCooldown(1)//only 1/10th of a second so no macros spamming
		resist_grab()
		if(!weakened)
			process_resist()

/mob/living/proc/process_resist()
	//Getting out of someone's inventory.
	if(istype(src.loc, /obj/item/holder))
		escape_inventory(src.loc)
		return

	if(istype(loc, /obj/item/mech_equipment/forklifting_system))
		var/obj/item/mech_equipment/forklifting_system/fork = loc
		fork.ejectLifting(get_turf(fork))
		return

	if(istype(loc, /mob/living/exosuit))
		var/mob/living/exosuit/mech = loc
		if(src in mech.pilots)
			mech.eject(src, FALSE)
			return

	//unbuckling yourself
	if(buckled)
		if (buckled.resist_buckle(src))
			spawn()
				escape_buckle()
			return TRUE
		else
			return FALSE

	//Breaking out of a locker?
	if( src.loc && (istype(src.loc, /obj/structure/closet)) )
		var/obj/structure/closet/C = loc
		spawn() C.mob_breakout(src)
		return TRUE

/mob/living/proc/escape_inventory(obj/item/holder/H)
	if(H != src.loc) return

	var/mob/M = H.loc //Get our mob holder (if any).

	if(istype(M))
		M.drop_from_inventory(H)
		to_chat(M, span_warning("\The [H] wriggles out of your grip!"))
		to_chat(src, span_warning("You wriggle out of \the [M]'s grip!"))

		// Update whether or not this mob needs to pass emotes to contents.
		for(var/atom/A in M.contents)
			if(istype(A,/mob/living/simple_animal/borer) || istype(A,/obj/item/holder))
				return
		M.status_flags &= ~PASSEMOTES

/mob/living/proc/resist_grab()
	var/resisting = 0
	for(var/obj/O in requests)
		requests.Remove(O)
		qdel(O)
		resisting++
	for(var/obj/item/grab/G in grabbed_by)
		resisting++
		switch(G.state)
			if(GRAB_PASSIVE)
				qdel(G)
			if(GRAB_AGGRESSIVE)
				if(prob(max(60 + ((stats?.getStat(STAT_ROB)) - G.assailant?.stats.getStat(STAT_ROB) ** 0.8), 1))) // same scaling as cooldown increase and if you manage to be THAT BAD, 1% for luck
					visible_message(span_warning("[src] has broken free of [G.assailant]'s grip!"))
					qdel(G)
			if(GRAB_NECK)
				var/conditionsapply = (world.time - G.assailant.l_move_time < 30 || !stunned) ? 3 : 1 //If you move when grabbing someone then it's easier for them to break free. Same if the affected mob is immune to stun.
				if(prob(conditionsapply * (5 + max((stats?.getStat(STAT_ROB)) - G.assailant.stats?.getStat(STAT_ROB), 1) ** 0.8))) // 4% minimal chance
					visible_message(span_warning("[src] has broken free of [G.assailant]'s headlock!"))
					qdel(G)
	for(var/mob/living/carbon/superior_animal/G_mob in grabbed_by) //grabs by non-humans work differently, as they have neither stats nor hands
		resisting++
		if(prob(max(((stats?.getStat(STAT_ROB) ** 0.9) / grabbed_by.len),20)))
			G_mob.breakgrab()
			visible_message(span_warning("[src] has broken free of [G_mob]'s grip!"))

	if(resisting)
		setClickCooldown(20)
		visible_message(span_danger("[src] resists!"))

/mob/living/carbon/resist_grab()
	return !handcuffed && ..()

/mob/living/carbon/process_resist()

	//drop && roll
	if(on_fire && !buckled)
		fire_stacks -= 2.5
		Weaken(4)
		spin(32,2)
		visible_message(
			span_danger("[src] rolls on the floor, trying to put themselves out!"),
			span_notice("You stop, drop, and roll!")
			)
		sleep(30)
		if(fire_stacks <= 0)
			visible_message(
				span_danger("[src] has successfully extinguished themselves!"),
				span_notice("You extinguish yourself.")
				)
			ExtinguishMob()
		return TRUE

	if(..())
		return TRUE

	if(handcuffed)
		spawn() escape_handcuffs()
	else if(legcuffed)
		spawn() escape_legcuffs()

/mob/living/carbon/proc/escape_handcuffs()
	//if(!(last_special <= world.time)) return

	//This line represent a significant buff to grabs...
	// We don't have to check the click cooldown because /mob/living/verb/resist() has done it for us, we can simply set the delay
	setClickCooldown(100)

	if(can_break_cuffs()) //Don't want to do a lot of logic gating here.
		break_handcuffs()
		return

	var/obj/item/handcuffs/HC = handcuffed

	//A default in case you are somehow handcuffed with something that isn't an obj/item/handcuffs type
	var/breakouttime = 1200 - src.stats.getStat(STAT_ROB) * 10
	//If you are handcuffed with actual handcuffs... Well what do I know, maybe someone will want to handcuff you with toilet paper in the future...
	if(istype(HC))
		breakouttime = HC.breakouttime - src.stats.getStat(STAT_ROB) * 10

	var/mob/living/carbon/human/H = src
	if(istype(H) && H.gloves && istype(H.gloves,/obj/item/clothing/gloves/rig))
		breakouttime /= 2

	if(do_after(src, breakouttime, incapacitation_flags = INCAPACITATION_DEFAULT & ~INCAPACITATION_RESTRAINED))
		visible_message(
		span_danger("\The [src] attempts to remove \the [HC]!"),
		span_warning("You attempt to remove \the [HC]. (This will take around [breakouttime / 10] seconds and you need to stand still)"))
		if(!handcuffed || buckled)
			return
		visible_message(
			span_danger("\The [src] manages to remove \the [handcuffed]!"),
			span_notice("You successfully remove \the [handcuffed].")
			)
		drop_from_inventory(handcuffed)

	if(istype(buckled, /obj/item/beartrap))
		breakouttime /= 2
		visible_message(
		span_danger("\The [src] attempts to remove \the [HC] using the trap!"),
		span_warning("You attempt to remove \the [HC] using the trap. (This will take around [breakouttime / 10] seconds and you need to stand still)")
		)
		if(do_after(src, breakouttime, incapacitation_flags = INCAPACITATION_UNCONSCIOUS))
			if(!handcuffed)
				return
			visible_message(
			span_danger("\The [src] manages to remove \the [handcuffed]!"),
			span_notice("You successfully remove \the [handcuffed].")
			)
			drop_from_inventory(handcuffed)

/mob/living/carbon/proc/escape_legcuffs()
	if(!can_click())
		return

	setClickCooldown(100)

	if(can_break_cuffs()) //Don't want to do a lot of logic gating here.
		break_legcuffs()
		return

	var/obj/item/legcuffs/HC = legcuffed

	//A default in case you are somehow legcuffed with something that isn't an obj/item/legcuffs type
	var/breakouttime = 1200
	//If you are legcuffed with actual legcuffs... Well what do I know, maybe someone will want to legcuff you with toilet paper in the future...
	if(istype(HC))
		breakouttime = HC.breakouttime

	visible_message(
		span_danger("[usr] attempts to remove \the [HC]!"),
		span_warning("You attempt to remove \the [HC]. (This will take around [breakouttime / 10] seconds and you need to stand still)")
		)

	if(do_after(src, breakouttime, incapacitation_flags = INCAPACITATION_DEFAULT & ~INCAPACITATION_RESTRAINED))
		if(!legcuffed || buckled)
			return
		visible_message(
			span_danger("[src] manages to remove \the [legcuffed]!"),
			span_notice("You successfully remove \the [legcuffed].")
			)

		drop_from_inventory(legcuffed)
		legcuffed = null
		update_inv_legcuffed()

/mob/living/carbon/proc/can_break_cuffs()
//	if(HULK in mutations)
//		return 1
	if(stats.getStat(STAT_ROB) >= STAT_LEVEL_GODLIKE)
		return 1

/mob/living/carbon/proc/break_handcuffs()
	visible_message(
		span_danger("[src] is trying to break \the [handcuffed]!"),
		span_warning("You attempt to break your [handcuffed.name]. (This will take around 5 seconds and you need to stand still)")
		)

	if(do_after(src, 5 SECONDS, incapacitation_flags = INCAPACITATION_DEFAULT & ~INCAPACITATION_RESTRAINED))
		if(!handcuffed || buckled)
			return

		visible_message(
			span_danger("<big>[src] manages to destroy \the [handcuffed]!</big>"),
			span_warning("You successfully break your [handcuffed.name].")
			)

//		if(HULK in mutations)
//			say(pick(";RAAAAAAAARGH!", ";HNNNNNNNNNGGGGGGH!", ";GWAAAAAAAARRRHHH!", ";NNNNNNNNGGGGGGGGHH!", ";AAAAAAARRRGH!" ))


		qdel(handcuffed)
		handcuffed = null
		if(buckled && buckled.buckle_require_restraints)
			buckled.unbuckle_mob()
		update_inv_handcuffed()

/mob/living/carbon/proc/break_legcuffs()
	to_chat(src, span_warning("You attempt to break your legcuffs. (This will take around 5 seconds and you need to stand still)"))
	visible_message(span_danger("[src] is trying to break the legcuffs!"))

	if(do_after(src, 5 SECONDS, incapacitation_flags = INCAPACITATION_DEFAULT & ~INCAPACITATION_RESTRAINED))
		if(!legcuffed || buckled)
			return

		visible_message(
			span_danger("<big>[src] manages to destroy the legcuffs!</big>"),
			span_warning("You successfully break your legcuffs.")
			)

//		if(HULK in mutations)
//			say(pick(";RAAAAAAAARGH!", ";HNNNNNNNNNGGGGGGH!", ";GWAAAAAAAARRRHHH!", ";NNNNNNNNGGGGGGGGHH!", ";AAAAAAARRRGH!" ))

		qdel(legcuffed)
		legcuffed = null
		update_inv_legcuffed()

/mob/living/carbon/human/can_break_cuffs()
	if(species.can_shred(src,1))
		return 1
	return ..()

//Returning anything but true will make the mob unable to resist out of this buckle
/atom/proc/resist_buckle(mob/living/user)
	return TRUE

/mob/living/proc/escape_buckle()
	if(buckled)
		buckled.user_unbuckle_mob(src)

/mob/living/carbon/escape_buckle()
	if(!buckled) return

	if(!restrained())
		..()
	else
		setClickCooldown(100)
		visible_message(
			span_danger("[usr] attempts to unbuckle themself!"),
			span_warning("You attempt to unbuckle yourself. (This will take around 2 minutes and you need to stand still)")
			)


		if(do_after(usr, 2 MINUTES, incapacitation_flags = INCAPACITATION_DEFAULT & ~(INCAPACITATION_RESTRAINED | INCAPACITATION_BUCKLED_FULLY)))
			if(!buckled)
				return
			visible_message(span_danger("\The [usr] manages to unbuckle themself!"),
							span_notice("You successfully unbuckle yourself."))
			buckled.user_unbuckle_mob(src)


