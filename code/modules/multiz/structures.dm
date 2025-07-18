//////////////////////////////
//Contents: Ladders, Stairs.//
//////////////////////////////

/obj/structure/multiz
	name = "ladder"
	density = FALSE
	opacity = FALSE
	anchored = TRUE
	icon = 'icons/obj/stairs.dmi'
	bad_type = /obj/structure/multiz
	health = 5000
	maxHealth = 5000
	var/istop = TRUE
	var/obj/structure/multiz/target
	var/obj/structure/multiz/targeted_by

/obj/structure/multiz/New()
	. = ..()
	for(var/obj/structure/multiz/M in loc)
		if(M != src)
			spawn(1)
				log_world("##MAP_ERROR: Multiple [initial(name)] at ([x],[y],[z])")
				qdel(src)
			return .

/obj/structure/multiz/CanPass(obj/mover, turf/source, height, airflow)
	return airflow || !density

/obj/structure/multiz/proc/find_target()
	if(target)
		target.targeted_by = src

/obj/structure/multiz/Initialize()
	. = ..()
	find_target()

/obj/structure/multiz/Destroy()
	if(target)
		target.targeted_by = null
		target = null

	if(targeted_by)
		targeted_by.target = null
		targeted_by = null

	return ..()


/obj/structure/multiz/attack_tk(mob/user)
	return

/obj/structure/multiz/attack_ghost(mob/user)
	. = ..()
	if(target)
		user.Move(get_turf(target))

/obj/structure/multiz/attack_ai(mob/living/silicon/user)
	if(target)
		if (isAI(user))
			var/turf/T = get_turf(target)
			T.move_camera_by_click()
		else if (Adjacent(user))
			attack_hand(user)





////LADDER////

/obj/structure/multiz/ladder
	name = "ladder"
	desc = "A ladder.  You can climb it up and down."
	description_info = "You can look what is on the other side with Alt-Click. You can also fire guns at anyone near the other side when peeking. You can also throw grenades."
	description_antag = "Don't try to place traps or slippery liquids onto the ladder's exit/entry directly, they won't work."
	icon_state = "ladderdown"
	var/climb_delay = 30

/obj/structure/multiz/ladder/find_target()
	var/turf/targetTurf = istop ? GetBelow(src) : GetAbove(src)
	target = locate(/obj/structure/multiz/ladder) in targetTurf
	..()

/obj/structure/multiz/ladder/up
	//Ladders which go up use a tall 32x64 sprite, in a seperate dmi
	icon = 'icons/obj/structures/ladder_tall.dmi'
	pixel_y = 16
	icon_state = "ladderup"
	istop = FALSE

/obj/structure/multiz/ladder/up/Initialize()
	..()
	return INITIALIZE_HINT_LATELOAD

/obj/structure/multiz/ladder/up/LateInitialize()
	..()
	//Special initialize behaviour for upward ladders to stop artefacts from mobs going behind them but drawing infront of them)

	//Normally a ladder will hug the back wall of a tile and mobs will go over it

	//If the tile to the north is acessible, change our behaviour to hug the south of a tile and draw over all mobs
	var/turf/T = get_step(src, NORTH)
	if (turf_clear(T))
		pixel_y = -4
		layer = ABOVE_MOB_LAYER

/obj/structure/multiz/ladder/Destroy()
	if(target && istop)
		qdel(target)
	return ..()

/obj/structure/multiz/ladder/attack_generic(mob/M)
	attack_hand(M)

/obj/structure/multiz/ladder/proc/throw_through(obj/item/C, mob/throw_man)
	if(istype(throw_man,/mob/living/carbon/human) && throw_man.canUnEquip(C))
		var/mob/living/carbon/human/user = throw_man
		var/through =  istop ? "down" : "up"
		user.visible_message(span_warning("[user] takes position to throw [C] [through] \the [src]."),
		span_warning("You take position to throw [C] [through] \the [src]."))
		if(do_after(user, 10))
			user.visible_message(span_warning("[user] throws [C] [through] \the [src]!"),
			span_warning("You throw [C] [through] \the [src]."))
			user.drop_item()
			C.forceMove(target.loc)
			var/direction = pick(NORTH, SOUTH, EAST, WEST, NORTHEAST, NORTHWEST, SOUTHEAST, SOUTHWEST)
			C.Move(get_step(C, direction))
			if(istype(C, /obj/item/grenade))
				var/obj/item/grenade/G = C
				if(!G.active)
					G.activate(user)
			return TRUE
		return FALSE
	return FALSE

/obj/structure/multiz/ladder/attackby(obj/item/I, mob/user)
	. = ..()
	if(throw_through(I,user))
		return
	else if(istype(I, /obj/item/mech_equipment) || istype(I, /obj/item/mech_component) || istype(I, /obj/item/tool/mech_kit))
		var/mob/living/exosuit = I.getContainingAtom()
		if(exosuit)
			attack_hand(exosuit)
	else
		attack_hand(user)

/obj/structure/multiz/ladder/attack_hand(mob/M)
	if (isrobot(M))
		var/mob/living/silicon/robot/R = M
		var/new_delay = climb_delay * (R.HasTrait(CYBORG_TRAIT_PARKOUR) ? 0.75 : 1) * (isdrone(M) ? 1 : 3 / R.speed_factor)
		climb(M, (new_delay))	//Robots are not built for climbing, they should go around where possible
								//I'd rather make them unable to use ladders at all, but eris' labyrinthine maintenance necessitates it
	else
		climb(M, climb_delay)


/obj/structure/multiz/ladder/proc/climb(mob/M, delay)
	if(!target || !istype(target.loc, /turf))
		to_chat(M, span_notice("\The [src] is incomplete and can't be climbed."))
		return
	if(isliving(M))
		var/mob/living/L = M
		delay *= (L.stats.getPerk(PERK_PARKOUR) ? 0.5 : 1)
	var/turf/T = target.loc
	var/mob/tempMob
	for(var/atom/A in T)
		if(!A.CanPass(M))
			to_chat(M, span_notice("\A [A] is blocking \the [src]."))
			return
		else if (A.density && ismob(A))
			tempMob = A
			continue

	if (tempMob)
		to_chat(M, span_notice("\A [tempMob] is blocking \the [src], making it harder to climb."))
		delay = delay * 1.5

	//Robots are a quarter ton of steel and most of them lack legs or arms of any appreciable sorts.
	//Even being able to climb ladders at all is a violation of newton'slaws. It shall at least be slow and communicated as such
	if (isrobot(M) && !isdrone(M))
		M.visible_message(
			span_notice("\A [M] starts slowly climbing [istop ? "down" : "up"] \a [src]!"),
			span_danger("You begin the slow, laborious process of dragging your hulking frame [istop ? "down" : "up"] \the [src]"),
			span_danger("You hear the tortured sound of strained metal.")
		)
		T.visible_message(
			span_danger("[M] gradually drags itself [istop ? "down" : "up"] \a [src]!"),
			span_danger("You hear the tortured sound of strained metal.")
		)
		playsound(src, 'sound/machines/airlock_creaking.ogg', 100, 1, 5,5)

	else
		M.visible_message(
			span_notice("\A [M] climbs [istop ? "down" : "up"] \a [src]!"),
			"You climb [istop ? "down" : "up"] \the [src]!",
			"You hear the grunting and clanging of a metal ladder being used."
		)
		T.visible_message(
			span_warning("Someone climbs [istop ? "down" : "up"] \a [src]!"),
			"You hear the grunting and clanging of a metal ladder being used."
		)
		playsound(src, pick(climb_sound), 100, 1, 5,5)

		delay = max(delay * M.stats.getMult(STAT_VIG, STAT_LEVEL_EXPERT), delay * 0.66)


	if(do_after(M, delay, src))
		M.forceMove(T)
		try_resolve_mob_pulling(M, src)

/obj/structure/multiz/ladder/AltClick(mob/living/carbon/human/user)
	if(get_dist(src, user) <= 3)
		if(!user.is_physically_disabled())
			if(target)
				if(user.client)
					if(user.is_watching == TRUE)
						to_chat(user, span_notice("You look [istop ? "down" : "up"] \the [src]."))
						user.client.eye = user.client.mob
						user.client.perspective = MOB_PERSPECTIVE
						user.hud_used.updatePlaneMasters(user)
						user.is_watching = FALSE
						user.can_multiz_pb = FALSE
					else if(user.is_watching == FALSE)
						user.client.eye = target
						user.client.perspective = EYE_PERSPECTIVE
						user.hud_used.updatePlaneMasters(user)
						user.is_watching = TRUE
						if(Adjacent(user))
							user.can_multiz_pb = TRUE
				return
		else
			to_chat(user, span_notice("You can't do it right now."))
		return
	else
		user.client.eye = user.client.mob
		user.client.perspective = MOB_PERSPECTIVE
		user.hud_used.updatePlaneMasters(user)
		user.is_watching = FALSE
		return
////STAIRS////

/obj/structure/multiz/stairs
	name = "stairs"
	desc = "Stairs leading to another deck. Not too useful if the gravity goes out."
	description_info = "Bullets can be shot through this and go onto the other side."
	description_antag = "Don't try placing traps/slippery items at the stair exit directly. They will not work"
	icon_state = "ramptop"
	layer = 2.4

/obj/structure/multiz/stairs/can_prevent_fall(above)
	return above ? FALSE : TRUE


/obj/structure/multiz/stairs/enter
	icon_state = "ramptop"

/obj/structure/multiz/stairs/enter/bottom
	istop = FALSE

/obj/structure/multiz/stairs/active
	density = TRUE
	icon_state = "rampdown"

/obj/structure/multiz/stairs/active/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	if(istype(mover)) // if mover is not null, e.g. mob
		return FALSE
	return TRUE // if mover is null (air movement)

/obj/structure/multiz/stairs/active/find_target()
	var/turf/targetTurf = istop ? GetBelow(src) : GetAbove(src)
	target = locate(/obj/structure/multiz/stairs/enter) in targetTurf
	..()

/obj/structure/multiz/stairs/active/Bumped(atom/movable/AM)
	if(isnull(AM))
		return

	if(!target)
		if(ismob(AM))
			to_chat(AM, span_warning("There are no stairs above."))
		log_debug("[src.type] at [src.x], [src.y], [src.z] have non-existant target")
		target = null
		return

	var/obj/structure/multiz/stairs/enter/ES = locate(/obj/structure/multiz/stairs/enter) in get_turf(AM)

	if(!ES && !istop)
		return

	AM.forceMove(get_turf(target))
	try_resolve_mob_pulling(AM, ES)

/obj/structure/multiz/stairs/attackby(obj/item/C, mob/user)
	. = ..()
	attack_hand(user)
	return

/obj/structure/multiz/stairs/active/attack_ai(mob/living/silicon/ai/user)
	. = ..()
	if(!target)
		to_chat(user, span_warning("There are no stairs above."))
		log_debug("[src.type] at [src.x], [src.y], [src.z] have non-existant target")

/obj/structure/multiz/stairs/active/attack_robot(mob/user)
	. = ..()
	if(Adjacent(user))
		Bumped(user)

/obj/structure/multiz/stairs/active/attack_hand(mob/user)
	. = ..()
	Bumped(user)

/obj/structure/multiz/stairs/AltClick(mob/living/carbon/human/user)
	if(get_dist(src, user) <= 7)
		if(!user.is_physically_disabled())
			if(target)
				if(user.client)
					if(user.is_watching == TRUE)
						to_chat(user, span_notice("You look [istop ? "down" : "up"] \the [src]."))
						user.client.eye = user.client.mob
						user.client.perspective = MOB_PERSPECTIVE
						user.hud_used.updatePlaneMasters(user)
						user.is_watching = FALSE
					else if(user.is_watching == FALSE)
						user.client.eye = target
						user.client.perspective = EYE_PERSPECTIVE
						user.hud_used.updatePlaneMasters(user)
						user.is_watching = TRUE
				return
		else
			to_chat(user, span_notice("You can't do it right now."))
		return
	else
		user.client.eye = user.client.mob
		user.client.perspective = MOB_PERSPECTIVE
		user.hud_used.updatePlaneMasters(user)
		user.is_watching = FALSE
		return

/obj/structure/multiz/stairs/active/bottom
	icon_state = "rampup"
	istop = FALSE




/obj/structure/multiz/ladder/burrow_hole
	name = "ancient maintenance tunnel"
	desc = "A deep metal tunnel. You wonder where it leads."
	icon = 'icons/obj/burrows.dmi'
	icon_state = "maint_hole"


/obj/structure/multiz/ladder/up/deepmaint
	name = "maintenance ladder"

/obj/structure/multiz/ladder/up/deepmaint/climb()
	if(!target)
		var/obj/structure/burrow/my_burrow = pick(GLOB.all_burrows)
		var/obj/structure/multiz/ladder/burrow_hole/my_hole = new /obj/structure/multiz/ladder/burrow_hole(my_burrow.loc)
		my_burrow.deepmaint_entry_point = FALSE
		target = my_hole
		my_hole.target = src
		var/list/seen = viewers(7, my_burrow.loc)
		my_burrow.audio("crumble", 80)
		for(var/mob/M in seen)
			M.show_message(span_notice("The burrow collapses inwards!"), 1)

		free_deepmaint_ladders -= src
		my_burrow.collapse()

	..()
