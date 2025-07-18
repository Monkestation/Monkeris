/turf/proc/getEffectShield()
	for (var/obj/effect/shield/S in contents)
		if (!S.isInactive())
			return S

/obj/effect/shield_impact
	name = "shield impact"
	icon = 'icons/obj/machines/shielding.dmi'
	icon_state = "shield_impact"
	anchored = TRUE
	plane = GAME_PLANE
	layer = ABOVE_ALL_MOB_LAYER
	density = FALSE

/obj/effect/shield_impact/New()
	QDEL_IN(src, 2 SECONDS)

/obj/effect/shield
	name = "energy shield"
	desc = "An impenetrable field of energy, capable of blocking anything as long as it's active."
	icon = 'icons/obj/machines/shielding.dmi'
	icon_state = "shield_normal"
	anchored = TRUE
	plane = GAME_PLANE
	layer = BELOW_OBJ_LAYER
	density = TRUE
	invisibility = 0
	var/obj/machinery/power/shipside/shield_generator/gen = null
	var/disabled_for = 0
	var/diffused_for = 0
	var/floorOnly = FALSE
	var/ignoreExAct = FALSE
	atmos_canpass = CANPASS_PROC
	alpha = 128

/obj/effect/shield/floor
	alpha = 32
	floorOnly= TRUE
	mouse_opacity = 0
	ignoreExAct = TRUE

/obj/effect/shield/update_icon()
	if(gen && gen.check_flag(MODEFLAG_PHOTONIC) && !disabled_for && !diffused_for)
		set_opacity(1)
	else
		set_opacity(0)

	if(gen && gen.check_flag(MODEFLAG_OVERCHARGE))
		icon_state = "shield_overcharged"
	else
		icon_state = "shield_normal"

/*
This is a bad way to solve this "problem".
I'm commenting it out because that incorrect qdeled param is gonna cause fun problems.
If shield sections actually start moving then, well... solve it at the mover-side.
Like for example singulo act and whatever.

// Prevents shuttles, singularities and pretty much everything else from moving the field segments away.
// The only thing that is allowed to move us is the Destroy() proc.
/obj/effect/shield/forceMove(newloc, qdeled = 0)
	if(qdeled)
		return ..()
	return 0
*/

/obj/effect/shield/New()
	..()
	update_nearby_tiles()
	update_openspace()


/obj/effect/shield/Destroy()
	update_nearby_tiles()
	. = ..()
	if(gen)
		if(src in gen.field_segments)
			gen.field_segments -= src
		if(src in gen.damaged_segments)
			gen.damaged_segments -= src
		gen = null



// Temporarily collapses this shield segment.
/obj/effect/shield/proc/fail(duration)
	if(duration <= 0)
		return

	if(gen)
		gen.damaged_segments |= src
	disabled_for += duration
	set_density(0)
	set_invisibility(INVISIBILITY_MAXIMUM)
	update_nearby_tiles()
	update_icon()


// Regenerates this shield segment.
/obj/effect/shield/proc/regenerate()
	if(!gen)
		return

	disabled_for = max(0, disabled_for - 1)
	diffused_for = max(0, diffused_for - 1)

	if(!disabled_for && !diffused_for)
		set_density(1)
		set_invisibility(0)
		update_nearby_tiles()
		update_icon()
		gen.damaged_segments -= src

		//When we regenerate, affect any mobs that happen to be standing in our spot
		for (var/mob/living/L in loc)
			L.shield_impact(src)


/obj/effect/shield/proc/diffuse(duration)
	// The shield is trying to counter diffusers. Cause lasting stress on the shield.
	if(gen.check_flag(MODEFLAG_BYPASS) && !diffused_for && !disabled_for)
		take_damage(duration * rand(8, 12), SHIELD_DAMTYPE_EM, src)
		return

	diffused_for = max(duration, 0)
	gen.damaged_segments |= src
	set_density(0)
	set_invisibility(INVISIBILITY_MAXIMUM)
	update_nearby_tiles()
	update_icon()

/obj/effect/shield/attack_generic(source, damage, emote)
	take_damage(damage, SHIELD_DAMTYPE_PHYSICAL, src)
	if(gen.check_flag(MODEFLAG_OVERCHARGE) && istype(source, /mob/living/))
		overcharge_shock(source)
	..(source, damage, emote)


// Fails shield segments in specific range. Range of 1 affects the shielded turf only.
/obj/effect/shield/proc/fail_adjacent_segments(range, hitby = null)
	if(hitby)
		visible_message(span_danger("\The [src] flashes a bit as \the [hitby] collides with it, eventually fading out in a rain of sparks!"))
	else
		visible_message(span_danger("\The [src] flashes a bit as it eventually fades out in a rain of sparks!"))
	fail(range * 2)

	for(var/obj/effect/shield/S in range(range, src))
		// Don't affect shields owned by other shield generators
		if(S.gen != src.gen)
			continue
		// The closer we are to impact site, the longer it takes for shield to come back up.
		S.fail(-(-range + get_dist(src, S)) * 2)

// returns how much damage was blocked by the shield
/obj/effect/shield/proc/take_damage(damage, damtype, hitby)
	if(!gen)
		qdel(src)
		return

	if(!damage)
		return

	damage = round(damage)

	new/obj/effect/shield_impact(get_turf(src))
	gen.handle_reporting() //This will queue up a damage report if one isnt already. It's delayed so its fine to call it before the damage is applied
	var/list/field_segments = gen.field_segments
	switch(gen.take_shield_damage(damage, damtype, hitby))
		if(SHIELD_ABSORBED)
			shield_impact_sound(get_turf(src), damage*0.5, damage*1.5)
			return damage
		if(SHIELD_BREACHED_MINOR)
			shield_impact_sound(get_turf(src), 25, 50)
			fail_adjacent_segments(rand(1, 3), hitby)
			return damage * 0.75
		if(SHIELD_BREACHED_MAJOR)
			shield_impact_sound(get_turf(src), 60, 60)
			fail_adjacent_segments(rand(2, 5), hitby)
			return damage * 0.5
		if(SHIELD_BREACHED_CRITICAL)
			shield_impact_sound(get_turf(src), 90, 70)
			fail_adjacent_segments(rand(4, 8), hitby)
			return damage * 0.25
		if(SHIELD_BREACHED_FAILURE)
			shield_impact_sound(get_turf(src), 255) //Absolutely guaranteed to hear this one anywhere
			fail_adjacent_segments(rand(8, 16), hitby)
			for(var/obj/effect/shield/S in field_segments)
				S.fail(1)
			return 0

/obj/effect/shield/proc/isInactive()
	if(!gen)
		qdel(src)
		return TRUE

	if(disabled_for || diffused_for)
		return TRUE

// As we have various shield modes, this handles whether specific things can pass or not.
/obj/effect/shield/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	// Somehow we don't have a generator. This shouldn't happen. Delete the shield.
	if (isInactive())
		return TRUE

	// Atmosphere containment.
	if(air_group)
		return !gen.check_flag(MODEFLAG_ATMOSPHERIC)

	if(mover)
		if (floorOnly)
			return TRUE
		return mover.can_pass_shield(gen)
	return TRUE

/obj/effect/shield/proc/CanActThrough(atom/movable/actor)
	if (isInactive())
		return TRUE
	if(actor)
		return actor.can_pass_shield(gen)
	return TRUE

/obj/effect/shield/c_airblock(turf/other)
	return gen.check_flag(MODEFLAG_ATMOSPHERIC) ? BLOCKED : 0


// EMP. It may seem weak but keep in mind that multiple shield segments are likely to be affected.
/obj/effect/shield/emp_act(severity)
	if (!isInactive())
		take_damage(rand(30,60) / severity, SHIELD_DAMTYPE_EM, src)


// Explosions

/obj/effect/shield/explosion_act(target_power, explosion_handler/handler)
	if(!ignoreExAct && !isInactive())
		return take_damage(target_power, SHIELD_DAMTYPE_PHYSICAL, src)

// Fire
/obj/effect/shield/fire_act()
	if (!isInactive())
		take_damage(rand(5,10), SHIELD_DAMTYPE_HEAT, src)


// Projectiles
/obj/effect/shield/bullet_act(obj/item/projectile/proj)
	if(proj.damage_types[BURN])
		take_damage(proj.damage_types[BURN], SHIELD_DAMTYPE_HEAT, proj)
	if(proj.damage_types[BRUTE])
		take_damage(proj.damage_types[BRUTE], SHIELD_DAMTYPE_PHYSICAL, proj)
	else
		take_damage(proj.get_structure_damage(), SHIELD_DAMTYPE_EM, proj)


// Attacks with hand tools. Blocked by Hyperkinetic flag.
/obj/effect/shield/attackby(obj/item/I as obj, mob/user as mob)
	user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
	user.do_attack_animation(src)

	if(gen.check_flag(MODEFLAG_HYPERKINETIC))
		user.visible_message(span_danger("\The [user] hits \the [src] with \the [I]!"))
		if(I.damtype == BURN)
			take_damage(I.force, SHIELD_DAMTYPE_HEAT, user)
		else if (I.damtype == BRUTE)
			take_damage(I.force, SHIELD_DAMTYPE_PHYSICAL, user)
		else
			take_damage(I.force, SHIELD_DAMTYPE_EM, user)
	else
		user.visible_message(span_danger("\The [user] tries to attack \the [src] with \the [I], but it passes through!"))


// Special treatment for meteors because they would otherwise penetrate right through the shield.
/obj/effect/shield/Bumped(atom/movable/mover)
	if(!gen)
		qdel(src)
		return 0
	mover.shield_impact(src)
	return ..()

// If moved (usually by a shuttle), the field ceases to exist
/obj/effect/shield/forceMove(atom/destination, special_event, glide_size_override)
	. = ..()
	// qdel() also calls forceMove() to nullspace the object - no recursive qdel calls allowed, no thanks
	if(. && !QDELETED(src))
		qdel(src)


/obj/effect/shield/proc/overcharge_shock(mob/living/M)
	M.adjustFireLoss(rand(20, 40))
	M.Weaken(5)
	M.updatehealth()
	to_chat(M, span_danger("As you come into contact with \the [src] a surge of energy paralyses you!"))
	take_damage(10, SHIELD_DAMTYPE_EM, src)

// Called when a flag is toggled. Can be used to add on-toggle behavior, such as visual changes.
/obj/effect/shield/proc/flags_updated()
	if(!gen)
		qdel(src)
		return

	// Update airflow
	update_nearby_tiles()
	update_icon()

///obj/effect/shield/get_explosion_resistance() //Part of recursive explosions, probably unimplemented
	//return explosion_resistance

// Shield collision checks below

/atom/movable/proc/can_pass_shield(obj/machinery/power/shipside/shield_generator/gen)
	return 1


// Other mobs
/mob/living/can_pass_shield(obj/machinery/power/shipside/shield_generator/gen)
	return !gen.check_flag(MODEFLAG_NONHUMANS)

// Human mobs
/mob/living/carbon/human/can_pass_shield(obj/machinery/power/shipside/shield_generator/gen)
	if(isSynthetic())
		return !gen.check_flag(MODEFLAG_ANORGANIC)
	return !gen.check_flag(MODEFLAG_HUMANOIDS)

// Silicon mobs
/mob/living/silicon/can_pass_shield(obj/machinery/power/shipside/shield_generator/gen)
	return !gen.check_flag(MODEFLAG_ANORGANIC)


// Generic objects. Also applies to bullets and meteors.
/obj/can_pass_shield(obj/machinery/power/shipside/shield_generator/gen)
	return !gen.check_flag(MODEFLAG_HYPERKINETIC)

// Beams
/obj/item/projectile/beam/can_pass_shield(obj/machinery/power/shipside/shield_generator/gen)
	return !gen.check_flag(MODEFLAG_PHOTONIC)


// Shield on-impact logic here. This is called only if the object is actually blocked by the field (can_pass_shield applies first)
/atom/movable/proc/shield_impact(obj/effect/shield/S)
	return

/mob/living/shield_impact(obj/effect/shield/S)
	if(!S.gen.check_flag(MODEFLAG_OVERCHARGE))
		return
	S.overcharge_shock(src)

/obj/effect/meteor/shield_impact(obj/effect/shield/S)
	if(!S.gen.check_flag(MODEFLAG_HYPERKINETIC))
		return
	/*
	//Logging for shield impacts disabled. Logging is still enabled for meteors that succesfully hit the hull
	if (istype(hit_location))
		var/area/A = get_area(hit_location)
		var/where = "[A? A.name : "Unknown Location"] | [hit_location.x], [hit_location.y]"
		var/whereLink = ADMIN_JMP(hit_location)
		message_admins("A meteor has impacted shields at ([whereLink])", 0, 1)
		log_game("A meteor has impacted shields at ([where]).")
	*/
	S.take_damage(get_shield_damage(), SHIELD_DAMTYPE_PHYSICAL, src)
	visible_message(span_danger("\The [src] breaks into dust!"))
	make_debris()
	qdel(src)



//This function takes a turf to prevent race conditions, as the object calling it will probably be deleted in the same frame
/proc/shield_impact_sound(turf/T, range, volume = 100)
	//The supplied volume is reduced by an amount = distance - viewrange * 2, viewrange is 7 i think
	playsound(T, 'sound/effects/impacts/shield_impact_1.ogg', volume, 1,extrarange = range * 1.5, falloff = range, use_pressure = 0)
