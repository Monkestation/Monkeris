/*
#define BRUTE "brute"
#define BURN "burn"
#define TOX "tox"
#define OXY "oxy"
#define CLONE "clone"

#define ADD "add"
#define SET "set"
*/
/obj/item/projectile
	name = "projectile"
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "bullet"
	density = TRUE
	unacidable = TRUE
	anchored = TRUE //There's a reason this is here, Mport. God fucking damn it -Agouri. Find&Fix by Pete. The reason this is here is to stop the curving of emitter shots.
	pass_flags = PASSTABLE
	mouse_opacity = 0
	spawn_blacklisted = TRUE
	spawn_frequency = 0
	spawn_tags = null
	var/bumped = FALSE		//Prevents it from hitting more than one guy at once
	var/hitsound_wall = "ricochet"
	var/list/mob_hit_sound = list('sound/effects/gore/bullethit2.ogg', 'sound/effects/gore/bullethit3.ogg') //Sound it makes when it hits a mob. It's a list so you can put multiple hit sounds there.
	var/def_zone = ""	//Aiming at
	var/mob/firer = null//Who shot it
	var/silenced = FALSE	//Attack message
	var/yo = null
	var/xo = null
	var/current = null
	var/shot_from = "" // name of the object which shot us
	var/atom/original = null // the target clicked (not necessarily where the projectile is headed). Should probably be renamed to 'target' or something.
	var/turf/starting = null // the projectile's starting turf
	var/list/permutated = list() // we've passed through these atoms, don't try to hit them again
	var/height // starts undefined, used for Zlevel shooting

	var/p_x = 16
	var/p_y = 16 // the pixel location of the tile that the player clicked. Default is the center

	var/nocap_structures = FALSE // wether or not this projectile can circumvent the damage cap you can do to walls and doors in one hit. Also increases the structure damage done to walls by 300%
	var/can_ricochet = FALSE // defines if projectile can or cannot ricochet.
	var/ricochet_id = 0 // if the projectile ricochets, it gets its unique id in order to process iteractions with adjacent walls correctly.
	var/ricochet_ability = 1 // multiplier for how much it can ricochet, modified by the bullet blender weapon mod

	var/list/damage_types = list(BRUTE = 10) //BRUTE, BURN, TOX, OXY, CLONE, HALLOSS -> int are the only things that should be in here
	var/nodamage = FALSE //Determines if the projectile will skip any damage inflictions
	var/taser_effect = FALSE //If set then the projectile will apply it's agony damage using stun_effect_act() to mobs it hits, and other damage will be ignored
	var/check_armour = ARMOR_BULLET //Defines what armor to use when it hits things. Full list could be found at defines\damage_organs.dm
	var/projectile_type = /obj/item/projectile
	var/penetrating = 0 //If greater than zero, the projectile will pass through dense objects as specified by on_penetrate()
	var/kill_count = 50 //This will de-increment every process(). When 0, it will delete the projectile.
	var/base_spreading = 90 // higher value means better chance to hit here. derp.
	var/spreading_step = 15
	var/projectile_accuracy = 1 // Based on vigilance, reduces random limb chance and likelihood of missing intended target
	var/recoil = 0
	var/wounding_mult = 1 // A multiplier on damage inflicted to and damage blocked by mobs

	//Effects
	var/stun = 0
	var/weaken = 0
	var/paralyze = 0
	var/irradiate = 0
	var/stutter = 0
	var/eyeblur = 0
	var/drowsy = 0
	var/embed = 0 // whether or not the projectile can embed itself in the mob
	var/knockback = 0

	var/hitscan = FALSE		// whether the projectile should be hitscan

	var/step_delay = 0.8	// the delay between iterations if not a hitscan projectile
							// This thing right here goes to sleep(). We should not send non decimal things to sleep(),
							// but it was doing it for a while, it works, and this whole shit should be rewriten or ported from another codebase.

	// effect types to be used
	var/muzzle_type
	var/tracer_type
	var/impact_type
	var/luminosity_range
	var/luminosity_power
	var/luminosity_color
	var/luminosity_ttl
	var/obj/effect/attached_effect
	var/proj_sound

	var/proj_color //If defined, is used to change the muzzle, tracer, and impact icon colors through Blend()

	var/datum/plot_vector/trajectory	// used to plot the path of the projectile
	var/datum/vector_loc/location		// current location of the projectile in pixel space
	var/matrix/effect_transform			// matrix to rotate and scale projectile effects - putting it here so it doesn't
										//  have to be recreated multiple times

/obj/item/projectile/Destroy()
	firer = null
	original = null
	starting = null
	LAZYCLEARLIST(permutated)
	return ..()

/obj/item/projectile/is_hot()
	if (damage_types[BURN])
		return damage_types[BURN] * heat

/obj/item/projectile/proc/get_total_damage()
	var/val = 0
	for(var/i in damage_types)
		val += damage_types[i]
	return val

/obj/item/projectile/proc/is_halloss()
	for(var/i in damage_types)
		if(i != HALLOSS)
			return FALSE
	return TRUE

/obj/item/projectile/multiply_projectile_damage(newmult)
	for(var/i in damage_types)
		damage_types[i] *= i == HALLOSS ? 1 : newmult

/obj/item/projectile/multiply_projectile_halloss(newmult)
	for(var/i in damage_types)
		damage_types[i] *= i == HALLOSS ? newmult : 1

/obj/item/projectile/add_projectile_penetration(newmult)
	armor_divisor = initial(armor_divisor) + newmult

/obj/item/projectile/multiply_pierce_penetration(newmult)
	penetrating = initial(penetrating) + newmult

/obj/item/projectile/multiply_ricochet(newmult)
	ricochet_ability = initial(ricochet_ability) + newmult

/obj/item/projectile/multiply_projectile_step_delay(newmult)
	if(!hitscan)
		step_delay = initial(step_delay) * newmult

/obj/item/projectile/proc/multiply_projectile_accuracy(newmult)
	projectile_accuracy = initial(projectile_accuracy) * newmult

// bullet/pellets redefines this
/obj/item/projectile/proc/adjust_damages(list/newdamages)
	if(!newdamages.len)
		return
	for(var/damage_type in newdamages)
		if(damage_type == IRRADIATE)
			irradiate += newdamages[IRRADIATE]
			continue
		damage_types[damage_type] += newdamages[damage_type]

/obj/item/projectile/proc/adjust_ricochet(noricochet)
	if(noricochet)
		can_ricochet = FALSE
		return

/obj/item/projectile/proc/on_hit(atom/target, def_zone = null)
	if(!isliving(target))	return 0
	if(isanimal(target))	return 0
	var/mob/living/L = target
	L.apply_effects(stun, weaken, paralyze, irradiate, stutter, eyeblur, drowsy)
	return TRUE

// generate impact effect
/obj/item/projectile/proc/on_impact(atom/A)
    impact_effect(effect_transform)
    if(luminosity_ttl && attached_effect)
        spawn(luminosity_ttl)
        QDEL_NULL(attached_effect)

    if(!ismob(A))
        playsound(src, hitsound_wall, 50, 1, -2)
    return

//Checks if the projectile is eligible for embedding. Not that it necessarily will.
/obj/item/projectile/proc/can_embed()
	//embed must be enabled and damage type must be brute
	if(!embed || damage_types[BRUTE] <= 0)
		return FALSE
	return TRUE

/obj/item/projectile/proc/get_structure_damage(injury_type)
	if(!injury_type) // Assume homogenous
		return (damage_types[BRUTE] + damage_types[BURN]) * wound_check(INJURY_TYPE_HOMOGENOUS, wounding_mult, edge, sharp) * 2
	else
		return (damage_types[BRUTE] + damage_types[BURN]) * wound_check(injury_type, wounding_mult, edge, sharp) * 2

//return 1 if the projectile should be allowed to pass through after all, 0 if not.
/obj/item/projectile/proc/check_penetrate(atom/A)
	return TRUE

/obj/item/projectile/proc/check_fire(atom/target as mob, mob/living/user as mob)  //Checks if you can hit them or not.
	check_trajectory(target, user, pass_flags, flags)

//sets the click point of the projectile using mouse input params
/obj/item/projectile/proc/set_clickpoint(params)
	var/list/mouse_control = params2list(params)
	if(mouse_control["icon-x"])
		p_x = text2num(mouse_control["icon-x"])
	if(mouse_control["icon-y"])
		p_y = text2num(mouse_control["icon-y"])

//called to launch a projectile
/obj/item/projectile/proc/launch(atom/target, target_zone, x_offset = 0, y_offset = 0, angle_offset = 0, proj_sound, user_recoil = 0)
	var/turf/curloc = get_turf(src)
	var/turf/targloc = get_turf(target)
	if (!istype(targloc) || !istype(curloc))
		return TRUE

	if(targloc == curloc) //Shooting something in the same turf
		target.bullet_act(src, target_zone)
		on_impact(target)
		qdel(src)
		return FALSE

	if(proj_sound)
		playsound(proj_sound)

	original = target
	def_zone = target_zone

	var/distance = get_dist(curloc, original)
	check_hit_zone(distance, user_recoil)

	setup_trajectory(curloc, targloc, x_offset, y_offset, angle_offset) //plot the initial trajectory
	Process()

	return FALSE

//called to launch a projectile from a gun
/obj/item/projectile/proc/launch_from_gun(atom/target, mob/user, obj/item/gun/launcher, target_zone, x_offset=0, y_offset=0, angle_offset)
	if(user == target) //Shooting yourself
		user.bullet_act(src, target_zone)
		qdel(src)
		return FALSE

	loc = get_turf(user)

	var/recoil = 0
	if(isliving(user))
		var/mob/living/aimer = user
		recoil = aimer.recoil
		recoil -= projectile_accuracy

		if(ishuman(user))
			var/mob/living/carbon/human/H = user
			if(H.can_multiz_pb && (!isturf(target)))
				loc = get_turf(H.client.eye)
				if(!(loc.Adjacent(target)))
					loc = get_turf(H)
			if(CONFIG_GET(flag/z_level_shooting) && H.client.eye == H.shadow && !height) // Player is watching a higher zlevel
				var/newTurf = get_turf(H.shadow)
				if(!(locate(/obj/structure/catwalk) in newTurf)) // Can't shoot through catwalks
					loc = newTurf
					height = HEIGHT_HIGH // We are shooting from below, this protects resting players at the expense of windows
					original = get_turf(original) // Aim at turfs instead of mobs, to ensure we don't hit players

	// Special case for mechs, in a ideal world this should always go for the top-most atom.
	if(istype(launcher.loc, /obj/item/mech_equipment))
		firer = launcher.loc.loc
	else
		firer = user
	shot_from = launcher.name
	silenced = launcher.item_flags & SILENT

	return launch(target, target_zone, x_offset, y_offset, angle_offset, user_recoil = recoil)

//Used to change the direction of the projectile in flight.
/obj/item/projectile/proc/redirect(new_x, new_y, atom/starting_loc, mob/new_firer)
	var/turf/new_target = locate(new_x, new_y, src.z)

	original = new_target
	if(new_firer)
		firer = src

	setup_trajectory(starting_loc, new_target)

/obj/item/projectile/proc/istargetloc(mob/living/target_mob)
	if(target_mob && original)
		var/turf/originalloc
		if(!istype(original, /turf))
			originalloc = original.loc
		else
			originalloc = original
		if(originalloc == target_mob.loc)
			return 1
		else
			return 0
	else
		return 0

/obj/item/projectile/proc/check_hit_zone(distance, recoil)

	def_zone = check_zone(def_zone)
	if(recoil)
		recoil = leftmost_bit(recoil) //LOG2 calculation
	else
		recoil = 0
	distance = leftmost_bit(distance)

	def_zone = ran_zone(def_zone, 100 - (distance + recoil) * 10)

//Called when the projectile intercepts a mob. Returns 1 if the projectile hit the mob, 0 if it missed and should keep flying.
/obj/item/projectile/proc/attack_mob(mob/living/target_mob, miss_modifier=0)
	if(!istype(target_mob))
		return

	//roll to-hit
	miss_modifier = 0

	var/result = PROJECTILE_CONTINUE

	if(CONFIG_GET(flag/z_level_shooting) && height == HEIGHT_HIGH)
		if(target_mob.resting == TRUE || target_mob.stat == TRUE)
			return FALSE // Bullet flies overhead

	if(target_mob != original) // If mob was not clicked on / is not an NPC's target, checks if the mob is concealed by cover
		var/turf/cover_loc = get_step(get_turf(target_mob), get_dir(get_turf(target_mob), starting))
		for(var/obj/O in cover_loc)
			if(istype(O,/turf/wall/low) || istype(O,/obj/machinery/deployable/barrier) || istype(O,/obj/structure/barricade) || istype(O,/obj/structure/table))
				if(!silenced)
					visible_message(span_notice("\The [target_mob] ducks behind \the [O], narrowly avoiding \the [src]!"))
				return FALSE
		for(var/obj/structure/table/O in get_turf(target_mob))
			if(istype(O) && O.flipped && (get_dir(get_turf(target_mob), starting) == O.dir))
				if(!silenced)
					visible_message(span_notice("\The [target_mob] ducks behind \the [O], narrowly avoiding \the [src]!"))
				return FALSE


	if(iscarbon(target_mob))
		// Handheld shields
		var/mob/living/carbon/C = target_mob
		var/obj/item/shield/S
		for(S in get_both_hands(C))
			if(S && S.block_bullet(C, src, def_zone))
				on_hit(S,def_zone)
				qdel(src)
				return TRUE
			break //Prevents shield dual-wielding

//		S = C.get_equipped_item(slot_back)
//		if(S && S.block_bullet(C, src, def_zone))
//			on_hit(S,def_zone)
//			qdel(src)
//			return TRUE

	result = target_mob.bullet_act(src, def_zone)

	if(result == PROJECTILE_FORCE_MISS || result == PROJECTILE_FORCE_MISS_SILENCED)
		if(!silenced && result == PROJECTILE_FORCE_MISS)
			visible_message(span_notice("\The [src] misses [target_mob] narrowly!"))
			if(isroach(target_mob))
				bumped = FALSE // Roaches do not bump when missed, allowing the bullet to attempt to hit the rest of the roaches in a single cluster
		return FALSE
	/*
	//hit messages
	if(silenced)
		to_chat(target_mob, span_danger("You've been hit in the [parse_zone(def_zone)] by \the [src]!"))
	else
		visible_message(span_danger("\The [target_mob] is hit by \the [src] in the [parse_zone(def_zone)]!"))//X has fired Y is now given by the guns so you cant tell who shot you if you could not see the shooter
	*/
	playsound(target_mob, pick(mob_hit_sound), 40, 1)

	//admin logs
	if(!no_attack_log)
		if(ismob(firer))

			var/attacker_message = "shot with \a [src.type]"
			var/victim_message = "shot with \a [src.type]"
			var/admin_message = "shot (\a [src.type])"

			admin_attack_log(firer, target_mob, attacker_message, victim_message, admin_message)
		else
			target_mob.attack_log += "\[[time_stamp()]\] <b>UNKNOWN SUBJECT (No longer exists)</b> shot <b>[target_mob]/[target_mob.ckey]</b> with <b>\a [src]</b>"
			msg_admin_attack("UNKNOWN shot [target_mob] ([target_mob.ckey]) with \a [src] [ADMIN_JMP(target_mob)]")

	if(target_mob.mob_classification & CLASSIFICATION_ORGANIC)
		var/turf/target_loca = get_turf(target_mob)
		var/mob/living/L = target_mob
		if(damage_types[BRUTE] > 10)
			var/splatter_dir = dir
			if(starting)
				splatter_dir = get_dir(starting, target_loca)
				target_loca = get_step(target_loca, splatter_dir)
			var/blood_color = "#C80000"
			if(ishuman(target_mob))
				var/mob/living/carbon/human/H = target_mob
				blood_color = H.species.blood_color
			new /obj/effect/overlay/temp/dir_setting/bloodsplatter(target_mob.loc, splatter_dir, blood_color)
			if(target_loca && prob(50))
				target_loca.add_blood(L)

	if(istype(src, /obj/item/projectile/beam/psychic) && istype(target_mob, /mob/living/carbon/human))
		var/obj/item/projectile/beam/psychic/psy = src
		var/mob/living/carbon/human/H = target_mob
		if(psy.contractor && result && (H.sanity.level <= 0))
			psy.holder.reg_break(H)

	if(result == PROJECTILE_STOP)
		return TRUE
	else
		return FALSE

/obj/item/projectile/Bump(atom/A as mob|obj|turf|area, forced = FALSE)
	if(A == src)
		return FALSE
	if(A == firer)
		loc = A.loc
		return FALSE //go fuck yourself in another place pls


	if((bumped && !forced) || (A in permutated))
		return FALSE

	var/passthrough = FALSE //if the projectile should continue flying

	var/tempLoc = get_turf(A)

	bumped = TRUE
	if(istype(A, /obj/structure/multiz/stairs/active))
		var/obj/structure/multiz/stairs/active/S = A
		if(S.target)
			forceMove(get_turf(S.target))
			trajectory.loc_z = loc.z
			bumped = FALSE
			return FALSE
	if(ismob(A))
		// Mobs inside containers shouldnt get bumped(such as mechs or closets)
		if(!isturf(A.loc))
			bumped = FALSE
			return FALSE

		var/mob/M = A
		if(isliving(A))
			//if they have a neck grab on someone, that person gets hit instead
			var/obj/item/grab/G = locate() in M
			if(G && G.state >= GRAB_NECK)
				visible_message(span_danger("\The [M] uses [G.affecting] as a shield!"))
				if(Bump(G.affecting, TRUE))
					return //If Bump() returns 0 (keep going) then we continue on to attack M.
			passthrough = !attack_mob(M)
		else
			passthrough = FALSE //so ghosts don't stop bullets
	else
		passthrough = (A.bullet_act(src, def_zone) == PROJECTILE_CONTINUE) //backwards compatibility
		if(isturf(A))
			if(QDELETED(src)) // we don't want bombs to explode once for every time bullet_act is called
				on_impact(A)
				invisibility = 101
				return TRUE // see that next line? it can overload the server.
			for(var/obj/O in A) // if src's bullet act spawns more objs, the list will increase,
				if(O.density)
					O.bullet_act(src) // causing exponential growth due to the spawned obj spawning itself
			for(var/mob/living/M in A)
				attack_mob(M)

	//penetrating projectiles can pass through things that otherwise would not let them
	if(!passthrough && penetrating > 0)
		if(check_penetrate(A))
			passthrough = TRUE
		penetrating--
	//the bullet passes through a dense object!
	if(passthrough)
		//move ourselves onto A so we can continue on our way
		if (!tempLoc)
			qdel(src)
			return TRUE

		loc = tempLoc
		if (A)
			permutated.Add(A)
		bumped = FALSE //reset bumped variable!
		return FALSE

	//stop flying
	on_impact(A)

	density = FALSE
	invisibility = 101


	qdel(src)
	return TRUE


/obj/item/projectile/explosion_act(target_power, explosion_handler/handler)
	return 0

/obj/item/projectile/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	return TRUE

/obj/item/projectile/Process()
	var/first_step = TRUE

	spawn while(src && src.loc)
		if(kill_count-- < 1)
			on_impact(src.loc) //for any final impact behaviours
			qdel(src)
			return
		if((!( current ) || loc == current))
			current = locate(min(max(x + xo, 1), world.maxx), min(max(y + yo, 1), world.maxy), z)
		if((x == 1 || x == world.maxx || y == 1 || y == world.maxy))
			qdel(src)
			return

		trajectory.increment()	// increment the current location
		location = trajectory.return_location(location)		// update the locally stored location data

		if(!location)
			qdel(src)	// if it's left the world... kill it
			return

		before_move()
		Move(location.return_turf())
		pixel_x = location.pixel_x
		pixel_y = location.pixel_y

		if(!bumped && !QDELETED(original) && !isturf(original))
			// this used to be loc == get_turf(original) , but this would break incase the original was inside something and hit them without hitting the outside
			if(loc == original.loc)
				if(!(original in permutated))
					if(Bump(original))
						return

		if(first_step)
			muzzle_effect(effect_transform)
			first_step = FALSE
		else if(!bumped)
			tracer_effect(effect_transform)
			luminosity_effect()

		if(!hitscan)
			sleep(step_delay)	//add delay between movement iterations if it's not a hitscan weapon

/obj/item/projectile/proc/before_move()
	return FALSE

/obj/item/projectile/proc/setup_trajectory(turf/startloc, turf/targloc, x_offset = 0, y_offset = 0, angle_offset)
	// setup projectile state
	starting = startloc
	current = startloc
	yo = targloc.y - startloc.y + y_offset
	xo = targloc.x - startloc.x + x_offset

	// plot the initial trajectory
	trajectory = new()
	trajectory.setup(starting, original, pixel_x, pixel_y, angle_offset)

	// generate this now since all visual effects the projectile makes can use it
	effect_transform = new()
	effect_transform.Scale(trajectory.return_hypotenuse(), 1)
	effect_transform.Turn(-trajectory.return_angle())		//no idea why this has to be inverted, but it works

	transform = turn(transform, -(trajectory.return_angle() + 90)) //no idea why 90 needs to be added, but it works

/obj/item/projectile/proc/muzzle_effect(matrix/T)
	//This can happen when firing inside a wall, safety check
	if (!location)
		return

	if(silenced)
		return

	if(ispath(muzzle_type))
		var/obj/effect/projectile/M = new muzzle_type(get_turf(src))

		if(istype(M))
			if(proj_color)
				var/icon/I = new(M.icon, M.icon_state)
				I.Blend(proj_color)
				M.icon = I
			M.set_transform(T)
			M.pixel_x = location.pixel_x
			M.pixel_y = location.pixel_y
			M.activate()

/obj/item/projectile/proc/tracer_effect(matrix/M)

	//This can happen when firing inside a wall, safety check
	if (!location)
		return

	if(ispath(tracer_type))
		var/obj/effect/projectile/P = new tracer_type(location.loc)

		if(istype(P))
			if(proj_color)
				var/icon/I = new(P.icon, P.icon_state)
				I.Blend(proj_color)
				P.icon = I
			P.set_transform(M)
			P.pixel_x = location.pixel_x
			P.pixel_y = location.pixel_y
			if(!hitscan)
				P.activate(step_delay)	//if not a hitscan projectile, remove after a single delay
			else
				P.activate()

/obj/item/projectile/proc/luminosity_effect()
    if (!location)
        return

    if(attached_effect)
        attached_effect.Move(src.loc)

    else if(luminosity_range && luminosity_power && luminosity_color)
        attached_effect = new /obj/effect/effect/light(src.loc, luminosity_range, luminosity_power, luminosity_color)

/obj/item/projectile/proc/impact_effect(matrix/M)
	//This can happen when firing inside a wall, safety check
	if (!location)
		return

	if(ispath(impact_type))
		var/obj/effect/projectile/P = new impact_type(location.loc)

		if(istype(P))
			if(proj_color)
				var/icon/I = new(P.icon, P.icon_state)
				I.Blend(proj_color)
				P.icon = I
			P.set_transform(M)
			P.pixel_x = location.pixel_x
			P.pixel_y = location.pixel_y
			P.activate(P.lifetime)

/obj/item/projectile/proc/block_damage(amount, atom/A)
	amount /= armor_divisor
	var/dmg_total = 0
	var/dmg_remaining = 0
	for(var/dmg_type in damage_types)
		var/dmg = damage_types[dmg_type]
		if(!(dmg_type == HALLOSS))
			dmg_total += dmg
		if(dmg > 0 && amount > 0)
			var/dmg_armor_difference = dmg - amount
			var/is_difference_positive = dmg_armor_difference > 0
			amount = is_difference_positive ? 0 : -dmg_armor_difference
			dmg = is_difference_positive ? dmg_armor_difference : 0
			if(!(dmg_type == HALLOSS))
				dmg_remaining += dmg
		if(dmg > 0)
			damage_types[dmg_type] = dmg
		else
			damage_types -= dmg_type
	if(!damage_types.len)
		on_impact(A)
		qdel(src)

	return dmg_total > 0 ? (dmg_remaining / dmg_total) : 0

/obj/item/projectile/get_matter()
	. = matter?.Copy()
	if(isnull(.)) // empty bullets have no need for matter handling
		return
	if(istype(loc, /obj/item/ammo_casing)) // if this is part of a stack
		var/obj/item/ammo_casing/case = loc
		if(case.amount > 1) // if there is only one, there is no need to multiply
			for(var/mattertype in .)
				.[mattertype] *= case.amount


//"Tracing" projectile
/obj/item/projectile/test //Used to see if you can hit them.
	invisibility = 101 //Nope!  Can't see me!
	yo = null
	xo = null
	var/result = 0 //To pass the message back to the gun.

/obj/item/projectile/test/Bump(atom/A as mob|obj|turf|area, forced)
	if(A == firer)
		loc = A.loc
		return //cannot shoot yourself
	if(istype(A, /obj/item/projectile))
		return
	if(isliving(A) || istype(A, /mob/living/exosuit) || istype(A, /obj/vehicle))
		result = 2 //We hit someone, return 1!
		return
	result = 1
	return

/obj/item/projectile/test/launch(atom/target, target_zone, x_offset, y_offset, angle_offset, proj_sound, user_recoil)
	var/turf/curloc = get_turf(src)
	var/turf/targloc = get_turf(target)
	if(!curloc || !targloc)
		return 0

	original = target

	//plot the initial trajectory
	setup_trajectory(curloc, targloc)
	return Process(targloc)

/obj/item/projectile/test/Process(turf/targloc)
	while(src) //Loop on through!
		if(result)
			return (result - 1)
		if((!( targloc ) || loc == targloc))
			targloc = locate(min(max(x + xo, 1), world.maxx), min(max(y + yo, 1), world.maxy), z) //Finding the target turf at map edge

		trajectory.increment()	// increment the current location
		location = trajectory.return_location(location)		// update the locally stored location data

		Move(location.return_turf())

		var/mob/living/M = locate() in get_turf(src)
		if(istype(M)) //If there is someting living...
			return 1 //Return 1
		else
			M = locate() in get_step(src,targloc)
			if(istype(M))
				return 1

//Helper proc to check if you can hit them or not.
/proc/check_trajectory(atom/target as mob|obj, atom/firer as mob|obj, pass_flags=PASSTABLE|PASSGLASS|PASSGRILLE, flags=null)
	if(!istype(target) || !istype(firer))
		return 0

	var/obj/item/projectile/test/trace = new /obj/item/projectile/test(get_turf(firer)) //Making the test....

	//Set the flags and pass flags to that of the real projectile...
	if(!isnull(flags))
		trace.flags = flags
	trace.pass_flags = pass_flags

	var/output = trace.launch(target) //Test it!
	qdel(trace) //No need for it anymore
	return output //Send it back to the gun!

/proc/get_proj_icon_by_color(obj/item/projectile/P, color)
	var/icon/I = new(P.icon, P.icon_state)
	I.Blend(color)
	return I

