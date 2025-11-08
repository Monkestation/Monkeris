/obj/structure/ambush_burrow
	name = "ambush burrow"
	icon = 'icons/obj/burrows.dmi'
	icon_state = "cracks_animated"
	desc = "A pile of debris that regularly pulses and shifts. Something is coming..."
	density = TRUE
	anchored = TRUE

	maxHealth = 50
	health = 50
	explosion_coverage = 0.3
	var/datum/ambush_controller/controller
	var/datum/ambush_type/our_ambush

/obj/structure/ambush_burrow/New(loc, parent, ambush_datum)
	..()
	controller = parent  // Link burrow with controller
	our_ambush = ambush_datum //Give burrow datum
	if(!controller || !our_ambush)
		log_runtime("[src.type] was spawned without required arguments!")
		QDEL(src)

	shake_animation(duration = our_ambush.setup_time)
	if(our_ambush.ambush_type == AMBUSH_SKIRMISH)
		addtimer(CALLBACK(src, PROC_REF(spawn_mobs)), our_ambush.setup_time)

///now we actually do the heavy lifting.
/obj/structure/ambush_burrow/proc/spawn_mobs()

	shake_animation(intensity = 14)//shake again for good measure
	playsound(src, pick(crumble_sound), 40)
	icon_state = "maint_hole"
	//get potential directions to place a mob
	var/list/possible_directions = GLOB.cardinal.Copy()
	var/mobs_spawned = 0
	var/probability = our_ambush.special_probability

	while(mobs_spawned < our_ambush.mob_spawn && possible_directions.len)
		var/turf/possible_T = get_step(loc, pick_n_take(possible_directions))
		new /obj/effect/decal/cleanable/rubble(possible_T)
		var/mobtype
		if(prob(probability))//if prob allows, pick a special mob
			mobtype = pick(our_ambush.special_types)
			//proba = max(0, probability - 5)  // Decreasing probability to avoid mass spam of special mobs
		else
			mobtype = pick(our_ambush.normal_types)  // Pick a normal mob
		if(!controller.check_density_no_mobs(possible_T))
			new mobtype(possible_T)  // Spawn mob at free location
		else
			new mobtype(loc)
		mobs_spawned++
	if(our_ambush.ambush_type == AMBUSH_SKIRMISH)
		addtimer(CALLBACK(src, PROC_REF(crumble)), 2 SECONDS)

///visibly indicates to players that this burrow is out of commission. Also preps for deletion
/obj/structure/ambush_burrow/proc/crumble()
	icon_state = "maint_hole_collapsed"
	desc = "It's filled with lose debris. As you watch, it begins to crumble away..."
	QDEL_IN(src, 3 SECONDS)

/obj/structure/ambush_burrow/Destroy()
	visible_message(SPAN_DANGER("\The [src] crumbles away!"))
	new /obj/effect/decal/cleanable/rubble(src.loc)
	if(controller)
		controller.burrows -= src
		controller = null
	..()

/obj/structure/ambush_burrow/attack_generic(mob/user, damage)
	user.do_attack_animation(src)
	visible_message(SPAN_DANGER("\The [user] smashes \the [src]!"))
	take_damage(damage)
	user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN * 1.5)

/obj/structure/ambush_burrow/attackby(obj/item/I, mob/user)
	if (user.a_intent == I_HURT && user.Adjacent(src))
		if(!(I.flags & NOBLUDGEON))
			user.do_attack_animation(src)
			var/damage = I.force * I.structure_damage_factor
			var/volume =  min(damage * 3.5, 15)
			if (I.hitsound)
				playsound(src, I.hitsound, volume, 1, -1)
			visible_message(SPAN_DANGER("[src] has been hit by [user] with [I]."))
			take_damage(damage)
			user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN * 1.5)
	return TRUE

/obj/structure/ambush_burrow/bullet_act(obj/item/projectile/Proj)
	..()
        // Bullet not really efficient against a pile of debris
	take_damage(Proj.get_structure_damage() * 0.25)

/obj/structure/ambush_burrow/take_damage(damage)
	. = health - damage < 0 ? damage - (damage - health) : damage
	. *= explosion_coverage
	health = min(max(health - damage, 0), maxHealth)
	if(health == 0)
		qdel(src)
	return

///lies in wait until a human mob enters its watched turfs, then creates an ambush event tied to them
/obj/effect/ambush_snare
	name = "Ambush Trigger"
	icon = 'icons/misc/landmarks.dmi'
	icon_state = "trap_red"
	alpha = 120
	anchored = TRUE
	unacidable = 1
	simulated = FALSE
	invisibility = 101
	///the proximity trigger used to detect mobs in nearby turfs
	var/datum/proximity_trigger/square/snare
	///the type of ambush deployed by this snare
	var/datum/ambush_type/our_ambush_type = /datum/ambush_type
	///the range of turfs detected by this snare
	var/triprange = 7

/obj/effect/ambush_snare/New()
	..()
	snare = new(src, /obj/effect/ambush_snare/proc/trip_snare, /obj/effect/ambush_snare/proc/trip_snare, triprange, proc_owner = src)
	snare.register_turfs()

///triggers an ambush on the target, if they're human
/obj/effect/ambush_snare/proc/trip_snare(sucker)
	if(!isturf(loc) || !ishuman(sucker) || !can_see(src, sucker))//let's keep this on visible players for now
		return
	var/mob/living/livingsucker = sucker
	if(livingsucker.ambushed)//don't spam ambushes if someone walks into multiple snares
		return
	new /datum/ambush_controller(loc, sucker, our_ambush_type)
	qdel(src)

//gc our prox trigger
/obj/effect/ambush_snare/Destroy()
	QDEL_NULL(snare)
	. = ..()
