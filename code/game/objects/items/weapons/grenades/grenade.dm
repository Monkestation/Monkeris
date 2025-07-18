/obj/item/grenade
	name = "grenade"
	desc = "A hand held grenade, with an adjustable timer."
	description_info = "Can have its timer adjusted with a screwdriver."
	w_class = ITEM_SIZE_SMALL
	icon = 'icons/obj/grenade.dmi'
	icon_state = "grenade"
	item_state = "grenade"
	throw_speed = 4
	throw_range = 20
	flags = CONDUCT
	slot_flags = SLOT_BELT|SLOT_MASK
	matter = list(MATERIAL_STEEL = 3)
	price_tag = 50
	var/active = 0
	var/det_time = 40
	var/variance = 0 //How much the fuse time varies up or down. Punishes cooking with makeshift nades, proper ones should have 0

/obj/item/grenade/proc/clown_check(mob/living/user)
/*	if((CLUMSY in user.mutations) && prob(50))
		to_chat(user, span_warning("Huh? How does this thing work?"))

		activate(user)
		add_fingerprint(user)
		spawn(5)
			prime()
		return 0
*/
	return TRUE

/obj/item/grenade/examine(mob/user, extra_description = "")
	if(get_dist(user, src) < 2)
		if(det_time > 1)
			extra_description += "The timer is set to [det_time/10] seconds."
		else
			extra_description += "The timer is set for instant detonation."
	..(user, extra_description)

/obj/item/grenade/attack_self(mob/user as mob)
	if(!active)
		if(clown_check(user))
			to_chat(user, span_warning("You prime \the [name]! [det_time/10] seconds!"))

			activate(user)
			add_fingerprint(user)
			if(iscarbon(user))
				var/mob/living/carbon/C = user
				C.throw_mode_on()
	return


/obj/item/grenade/proc/activate(mob/user as mob)
	if(active)
		return

	if(user)
		log_and_message_admins("primed \a [src]")
		user.attack_log += "\[[time_stamp()]\] <font color='red'>primed \a [src]</font>"

	icon_state = initial(icon_state) + "_active"
	active = 1
	playsound(loc, 'sound/weapons/armbomb.ogg', 75, 1, -3)
	update_icon()

	if(variance)
		det_time *= RAND_DECIMAL(1-variance, 1+variance)

	spawn(det_time)
		prime(user)
		return


/obj/item/grenade/proc/prime(mob/user as mob)
	var/turf/T = get_turf(src)
	if(T)
		T.hotspot_expose(700,125)
	if(user && user.hud_used)
		user.hud_used.updatePlaneMasters(user)


/obj/item/grenade/attackby(obj/item/I, mob/user as mob)
	if(QUALITY_SCREW_DRIVING in I.tool_qualities)
		if(I.use_tool(user, src, WORKTIME_NEAR_INSTANT, QUALITY_SCREW_DRIVING, FAILCHANCE_EASY, required_stat = STAT_COG))
			switch(det_time)
				if (1)
					det_time = 30
					to_chat(user, span_notice("You set the [name] for 3 second detonation time."))
				if (30)
					det_time = 40
					to_chat(user, span_notice("You set the [name] for 4 second detonation time."))
				if (40)
					det_time = 1
					to_chat(user, span_notice("You set the [name] for instant detonation."))
			add_fingerprint(user)
	..()
	return

/obj/item/grenade/attack_hand()
	walk(src, null, null)
	..()
	return

/obj/item/grenade/fall_impact(turf/from, turf/dest)
	..()
	var/found = dest.contents.Find(/mob/living/carbon/human)
	if(found)
		var/mob/living/carbon/human/bonk = dest.contents[found]
		if(bonk.incapacitated(INCAPACITATION_GROUNDED))
			return
		bonk.apply_damage(2, BRUTE, BP_HEAD, sharp = FALSE, edge = FALSE, used_weapon = src)
		bonk.visible_message(span_danger("[src] falls from above and bonks [bonk.name] on \his head!"), span_danger("[src] falls on your head and bounces to the side!"), "You hear a dull thud.", 5)
		var/turf/random = pick(orange(1, dest))
		forceMove(random)

