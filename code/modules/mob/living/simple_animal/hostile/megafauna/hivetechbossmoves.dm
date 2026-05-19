// /obj/item/proc/resolve_attackby(atom/A, mob/src, params)


/mob/living/simple_animal/hostile/megafauna/hivemind_tyrant/proc/swing_attack(mob/A)

	var/turf/L
	var/turf/C = get_turf(A)
	var/turf/R

	var/strike_dir = get_dir(src, A)
	switch(strike_dir)
		if(NORTH)
			R = get_step(C, EAST)
			L = get_step(C, WEST)
		if(SOUTH)
			R = get_step(C, WEST)
			L = get_step(C, EAST)
		if(EAST)
			R = get_step(C, SOUTH)
			L = get_step(C, NORTH)
		if(WEST)
			R = get_step(C, NORTH)
			L = get_step(C, SOUTH)
		if(NORTHEAST)
			R = get_step(C, SOUTH)
			L = get_step(C, WEST)
		if(NORTHWEST)
			R = get_step(C, EAST)
			L = get_step(C, SOUTH)
		if(SOUTHEAST)
			R = get_step(C, WEST)
			L = get_step(C, NORTH)
		if(SOUTHWEST)
			R = get_step(C, NORTH)
			L = get_step(C, EAST)



	var/obj/effect/effect/melee/swing/swing = new(get_turf(src))
	swing.dir = get_dir(src, C)
	src.visible_message(span_danger("[src] swings \his [src]"))
	playsound(loc, 'sound/effects/swoosh.ogg', 50, 1, -1)

//	So why the ifs? This is for the CLANK effect, Tyrant gets stunned by hitting cover to stall him and escape, but he gets mad afterwards...

	QDEL_IN(swing, 2 SECONDS)
	if(prob(50))
		flick("left_swing", swing)
		if(!tileattack(src, L))
			stun_the_tyrant()
			return
		if(!tileattack(src, C))
			stun_the_tyrant()
			return
		if(!tileattack(src, R))
			stun_the_tyrant()
			return

	else
		flick("right_swing", swing)
		if(!tileattack(src, R))
			stun_the_tyrant()
			return
		if(!tileattack(src, C))
			stun_the_tyrant()
			return
		if(!tileattack(src, L))
			stun_the_tyrant()
			return

//	So why the ifs? This is for the CLANK effect, Tyrant gets stunned by hitting cover to stall him and escape, but he gets mad afterwards...



	src.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/mob/living/simple_animal/hostile/megafauna/hivemind_tyrant/proc/tileattack(mob/living/user, turf/targetarea)
	if(istype(targetarea, /turf/wall))
		return FALSE	// WALL CLANK!

	for(var/obj/S in targetarea)
		if (S.density || istype(S, /obj/effect/plant) || !istype(S, /obj/machinery/disposal))
			UnarmedAttack(S)

	var/list/mobs = new/list()
	for(var/mob/living/M in targetarea)
		if(M != user)
			mobs.Add(M)
	while(mobs.len)
		UnarmedAttack(pick_n_take(mobs))
	return TRUE // NO WALL CLANKING :[

