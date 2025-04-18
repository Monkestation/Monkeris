#define MOPMODE_TILE 1
#define MOPMODE_SWEEP 2

/obj/item/mop
	desc = "The world of janitalia wouldn't be complete without a mop."
	name = "mop"
	icon = 'icons/obj/janitor.dmi'
	icon_state = "mop"
	force = WEAPON_FORCE_WEAK
	throwforce = WEAPON_FORCE_WEAK
	throw_speed = 5
	throw_range = 10
	w_class = ITEM_SIZE_NORMAL
	attack_verb = list("mopped", "bashed", "bludgeoned", "whacked")
	matter = list(MATERIAL_PLASTIC = 3)
	spawn_tags = SPAWN_TAG_ITEM_UTILITY
	rarity_value = 10
	price_tag = 15
	var/mopping = 0
	var/mopcount = 0

	var/mopmode = MOPMODE_TILE
	var/sweep_time = 7

/obj/item/mop/Initialize()
	. = ..()
	create_reagents(30)

/obj/item/mop/attack_self(mob/user)
	.=..()
	if(mopmode == MOPMODE_TILE)
		mopmode = MOPMODE_SWEEP
		to_chat(user, span_notice("You will now clean with broad sweeping motions"))
	else if(mopmode == MOPMODE_SWEEP)
		mopmode = MOPMODE_TILE
		to_chat(user, span_notice("You will now thoroughly clean a single tile at a time"))

/obj/item/mop/afterattack(atom/A, mob/user, proximity)
	if(!proximity) return
	if(istype(A, /turf) || istype(A, /obj/effect/decal/cleanable) || istype(A, /obj/effect/overlay))
		if(reagents.total_volume < 1)
			to_chat(user, span_notice("Your mop is dry!"))
			return
		var/turf/T = get_turf(A)
		if(!T)
			return
		spawn()
			user.do_attack_animation(T)
		if(mopmode == MOPMODE_TILE)
			//user.visible_message(span_warning("[user] begins to clean \the [T]."))
			user.setClickCooldown(3)
			if(do_after(user, 30, T))
				if(T)
					T.clean(src, user)
				to_chat(user, span_notice("You have finished mopping!"))

		//Sweep mopmode. Light and fast aoe cleaning
		else if(mopmode == MOPMODE_SWEEP)

			sweep(user, T)
	else
		makeWet(A, user)


/obj/item/mop/proc/sweep(mob/user, turf/target)
	user.setClickCooldown(sweep_time)
	var/direction = get_dir(get_turf(src),target)
	var/list/turfs
	if(direction in GLOB.cardinal)
		turfs = list(target, get_step(target,turn(direction, 90)), get_step(target,turn(direction, -90)))
	else
		turfs = list(target, get_step(target,turn(direction, 135)), get_step(target,turn(direction, -135)))

	//Lets do a fancy animation of the mop sweeping over the tiles. Code copied from attack animation
	var/turf/start = turfs[2]
	var/turf/end = turfs[3]
	var/obj/effect/effect/mopimage = new /obj/effect/effect(start)
	mopimage.appearance = appearance
	mopimage.alpha = 200
	// Who can see the attack?
	var/list/viewing = list()
	for(var/mob/M in viewers(start))
		if(M.client)
			viewing |= M.client
	//flick_overlay(I, viewing, 5) // 5 ticks/half a second
	// Scale the icon.
	mopimage.transform *= 0.75
	// And animate the attack!
	animate(mopimage, alpha = 50, time = sweep_time*1.5)
	var/sweep_step = (sweep_time - 1) * 0.5
	spawn(1)
		mopimage.forceMove(target, glide_size_override=DELAY2GLIDESIZE(sweep_step))
		sleep(sweep_step)
		mopimage.forceMove(end, glide_size_override=DELAY2GLIDESIZE(sweep_step))
	QDEL_IN(mopimage, sweep_time+1)

	if(!do_after(user, sweep_time,target))
		to_chat(user, span_danger("Mopping cancelled"))
		return


	for(var/turf/T in turfs)
		if(T.density)
			//You hit a wall!
			shake_camera(user, 1, 1)
			playsound(T,"thud", 20, 1, -3)
			to_chat(user, span_danger("There's not enough space for broad sweeps here!"))
			break
		for(var/atom/i in T)
			if(istype(i, /mob/living))
				attack(i, user)
			if(i.density)
				break
		T.clean_partial(src, user, 1)

/obj/item/mop/proc/makeWet(atom/A, mob/user)
	if(A.is_open_container())
		if(A.reagents)
			if(A.reagents.total_volume < 1)
				to_chat(user, span_warning("\The [A] is out of water!"))
				return
			A.reagents.trans_to_obj(src, reagents.maximum_volume)
		else
			reagents.add_reagent("water", reagents.maximum_volume)

		to_chat(user, span_notice("You wet \the [src] with \the [A]."))
		playsound(loc, 'sound/effects/slosh.ogg', 25, 1)



/obj/effect/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/mop) || istype(I, /obj/item/soap) || istype(I, /obj/item/holyvacuum))
		return
	..()


#undef MOPMODE_TILE
#undef MOPMODE_SWEEP
