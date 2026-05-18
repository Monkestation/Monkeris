// /obj/item/proc/resolve_attackby(atom/A, mob/src, params)


/mob/living/simple_animal/hostile/megafauna/hivemind_tyrant/proc/swing_attack(atom/A)

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
	var/obj/effect/effect/melee/swing/S = new(get_turf(src))
	S.dir = strike_dir
	src.visible_message(span_danger("[src] swings \his [src]"))
	playsound(loc, 'sound/effects/swoosh.ogg', 50, 1, -1)
	var/dmg_modifier = 1
	if(prob(50))
		flick("left_swing", S)
		tileattack(src, L)
		tileattack(src, C, original_target = A)
		tileattack(src, R)
		QDEL_IN(S, 2 SECONDS)
	else
		flick("right_swing", S)
		tileattack(src, R,)
		tileattack(src, C, original_target = A)
		tileattack(src, L)
		QDEL_IN(S, 2 SECONDS)
	src.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)

/mob/living/simple_animal/hostile/megafauna/hivemind_tyrant/proc/tileattack(mob/living/user, turf/targetarea, original_target)
	if(istype(targetarea, /turf/wall))
		var/turf/W = targetarea
	for(var/obj/S in targetarea)
		if ((S.density || istype(S, /obj/effect/plant)) && !istype(S, /obj/structure/table) && !istype(S, /obj/machinery/disposal) && !istype(S, /obj/structure/closet))
			UnarmedAttack(S)
	var/list/living_mobs = new/list()
	var/list/dead_mobs = new/list()
	for(var/mob/living/M in targetarea)
		if(M != user)
			if(M.stat == DEAD)
				dead_mobs.Add(M)
			else
				living_mobs.Add(M)
	var/mob/living/target
	if(original_target && istype(original_target, /mob/living)) // Check if original target is a mob
		if(LAZYFIND(living_mobs, original_target) || LAZYFIND(dead_mobs, original_target)) // Check if original target is a mob on this tile
			target = original_target
				UnarmedAttack(user, target)

			if(target.density) // If the original target was dense, the rest of the mobs are shielded
				#warn clank here
				return modifier

#warn wait for FUCKERY HERE
	while(living_mobs.len)
		target = pick_n_take(living_mobs)
		UnarmedAttack(user, target)
		if(target.density) // If we hit a dense target, the rest of the mobs are shielded

