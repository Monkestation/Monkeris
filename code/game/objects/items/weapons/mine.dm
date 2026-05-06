/obj/item/mine
	name = "landmine"
	desc = "An anti-personnel mine. A danger to about everyone except those with a Pulsing tool."
	icon = 'icons/obj/machines/excelsior/objects.dmi'
	icon_state = "mine"
	w_class = ITEM_SIZE_BULKY
	matter = list(MATERIAL_STEEL = 35)
	matter_reagents = list("fuel" = 40)
	layer = BELOW_MOB_LAYER //fixed the wrong layer - Plasmatik
	rarity_value = 10
	spawn_tags = SPAWN_TAG_MINE_ITEM
	var/prob_explode = 90
	var/pulse_difficulty = FAILCHANCE_NORMAL

	//var/obj/item/device/assembly_holder/detonator = null

	var/fragment_type = /obj/item/projectile/bullet/pellet/fragment/weak
	var/spread_radius = 4
	var/num_fragments = 25
	var/damage_step = 2

	var/explosion_power = 250
	var/explosion_falloff = 100

	var/armed = FALSE
	var/deployed = FALSE
	var/excelsior = FALSE
	anchored = FALSE

/obj/item/mine/Initialize()
	. = ..()
	update_icon()

/obj/item/mine/excelsior
	name = "Excelsior mine"
	desc = "An anti-personnel mine. IFF technology grants safe passage to Excelsior agents, and a merciful brief end to others, unless they have a Pulse tool nearby."
	icon_state = "mine_excel"
	matter = list(MATERIAL_STEEL = 15, MATERIAL_PLASTIC = 10)
	excelsior = TRUE
	prob_explode = 100
	pulse_difficulty = FAILCHANCE_HARD

/obj/item/mine/old
	name = "old landmine"
	desc = "A rusted anti-personnel mine. A risky and unpredictable device, albeit with simple wiring."
	icon_state = "mine_old"
	prob_explode = 60
	pulse_difficulty = FAILCHANCE_EASY

/obj/item/mine/old/armed
	armed = TRUE
	anchored = TRUE
	deployed = TRUE
	rarity_value = 55
	spawn_frequency = 10
	spawn_tags = SPAWN_TRAP_ARMED

/obj/item/mine/improv
	name = "makeshift mine"
	desc = "An improvised explosive mounted in a bear trap. Dangerous to step on, but easy to defuse."
	icon_state = "mine_improv"
	matter = list(MATERIAL_STEEL = 25, MATERIAL_PLASMA = 5)
	prob_explode = 75
	pulse_difficulty = FAILCHANCE_ZERO
	explosion_power = 175
	explosion_falloff = 75

/obj/item/mine/improv/armed
	armed = TRUE
	anchored = TRUE
	deployed = TRUE
	rarity_value = 44
	spawn_frequency = 10
	spawn_tags = SPAWN_TRAP_ARMED

/obj/item/mine/ignite_act()
	explode()

/obj/item/mine/proc/explode()
	explosion(get_turf(src), explosion_power, explosion_falloff)
	fragment_explosion(get_turf(src), spread_radius, fragment_type, num_fragments, null, damage_step)
	if(src)
		qdel(src)

/obj/item/mine/update_icon()
	cut_overlays()

	if(armed)
		overlays += image(icon,"mine_light")

/obj/item/mine/attack_self(mob/user)
	if(locate(/obj/structure/multiz/ladder) in get_turf(user))
		to_chat(user, span_notice("You cannot place \the [src] here, there is a ladder."))
		return
	if(locate(/obj/structure/multiz/stairs) in get_turf(user))
		to_chat(user, span_notice("You cannot place \the [src] here, it needs a flat surface."))
		return
	if(!armed)
		user.visible_message(
			span_danger("[user] starts to deploy \the [src]."),
			span_danger("You begin deploying \the [src]!")
			)

		if (do_after(user, 25))
			user.visible_message(
				span_danger("[user] has deployed \the [src]."),
				span_danger("You have deployed \the [src]!")
				)

			deployed = TRUE
			user.drop_from_inventory(src)
			anchored = TRUE
			armed = TRUE
			update_icon()
			log_admin("[key_name(user)] has placed \a [src] at ([x],[y],[z]).")

	update_icon()

/obj/item/mine/attack_hand(mob/user)
	if(excelsior)
		for(var/datum/antagonist/A in user.mind.antagonist)
			if(A.id == ROLE_EXCELSIOR_REV && deployed)
				user.visible_message(
					span_notice("You summon up Excelsior's collective training and carefully deactivate the mine for transport.")
					)
				deployed = FALSE
				anchored = FALSE
				armed = FALSE
				update_icon()
				return
	if (deployed)
		if(pulse_difficulty == FAILCHANCE_ZERO)
			user.visible_message(
					span_notice("You carefully disarm the [src].")
					)
			deployed = FALSE
			anchored = FALSE
			armed = FALSE
			update_icon()
			return
		else
			user.visible_message(
					span_danger("[user] extends its hand to reach \the [src]!"),
					span_danger("You extend your arms to pick it up, knowing that it will likely blow up when you touch it!")
					)
			if (do_after(user, 5))
				if(prob(prob_explode))
					user.visible_message(
						span_danger("[user] attempts to pick up \the [src] only to hear a beep as it explodes in \his hands!"),
						span_danger("You attempt to pick up \the [src] only to hear a beep as it explodes in your hands!")
						)
					explode()
					return
				else
					user.visible_message(
						span_danger("[user] picks up \the [src], which miraculously doesn't explode!"),
						span_danger("You pick up \the [src], which miraculously doesn't explode!")
					)
					deployed = FALSE
					anchored = FALSE
					armed = FALSE
					update_icon()
					return
	. =..()

/obj/item/mine/attackby(obj/item/I, mob/user)
	if(QUALITY_PULSING in I.tool_qualities)

		if (deployed)
			user.visible_message(
			span_danger("[user] starts to carefully disarm \the [src]."),
			span_danger("You begin to carefully disarm \the [src].")
			)
		if(I.use_tool(user, src, WORKTIME_NORMAL, QUALITY_PULSING, pulse_difficulty,  required_stat = STAT_COG)) //disarming a mine with a multitool should be for smarties
			user.visible_message(
				span_danger("[user] has disarmed \the [src]."),
				span_danger("You have disarmed \the [src]!")
				)
			deployed = FALSE
			anchored = FALSE
			armed = FALSE
			update_icon()
		return
	else
		if (deployed)   //now touching it with stuff that don't pulse will also be a bad idea
			user.visible_message(
				span_danger("\The [src] is hit with [I] and it explodes!"),
				span_danger("You hit \the [src] with [I] and it explodes!"))
			explode()
		return


/obj/item/mine/Crossed(mob/AM)
	if (armed)
		if(locate(/obj/structure/multiz/ladder) in get_turf(loc))
			visible_message(span_danger("\The [src]'s triggering mechanism is disrupted by the ladder and does not go off."))
			return
		if(locate(/obj/structure/multiz/stairs) in get_turf(loc))
			visible_message(span_danger("\The [src]'s triggering mechanism is disrupted by the slope and does not go off."))
			return ..()
		if(isliving(AM))

			if(excelsior)
				if(ismech(AM))
					/// if at least one of the people inside is an excel.
					for(var/mob/living/carbon/human/agent in AM)
						for(var/datum/antagonist/A in agent.mind.antagonist)
							if(A.id == ROLE_EXCELSIOR_REV)
								return
				else
					for(var/datum/antagonist/A in AM.mind.antagonist)
						if(A.id == ROLE_EXCELSIOR_REV)
							return
			var/true_prob_explode = prob_explode - AM.skill_to_evade_traps()
			if(prob(true_prob_explode))
				explode()
				return
	.=..()

/*
/obj/item/mine/attackby(obj/item/I, mob/user)
	src.add_fingerprint(user)
	if(detonator && QUALITY_SCREW_DRIVING in I.tool_qualities)
		if(I.use_tool(user, src, WORKTIME_FAST, QUALITY_SCREW_DRIVING, FAILCHANCE_EASY, required_stat = STAT_COG))
			if(detonator)
				user.visible_message("[user] detaches \the [detonator] from [src].", \
					"You detach \the [detonator] from [src].")
				detonator.forceMove(get_turf(src))
				detonator = null

	if (istype(I,/obj/item/device/assembly_holder))
		if(detonator)
			to_chat(user, span_warning("There is another device in the way."))
			return ..()

		user.visible_message("\The [user] begins attaching [I] to \the [src].", "You begin attaching [I] to \the [src]")
		if(do_after(user, 20, src))
			user.visible_message(span_notice("The [user] attach [I] to \the [src].", span_blue(" You attach [I] to \the [src].")))

			detonator = I
			user.unEquip(I,src)

	return ..()
*/

// --------------------------------
// Claymore Mines
// --------------------------------

/obj/item/mine/claymore
	name = "Claymore mine"
	icon_state = "claymore"
	desc = "A directional anti-personnel mine fitted with an optical sensor trigger. A danger to anyone foolish or unaware enough to step in front of it. Disarmable with a Pulsing tool if you're skilled enough."
	description_info = "A directional anti-personnel landmine with an optical sensor that projects forward in a cone pattern. The sensor range can be adjusted between 2 and 4 tiles using a Pulsing tool before deployment. The reinforced back casing means fragmentation only fires forward, making it significantly harder to disarm than a standard pressure mine."
	description_antag = "Harder to disarm than its pressure equivalent on account of the reinforced casing. Come prepared or don't bother."
	explosion_power = 250
	explosion_falloff = 100
	spawn_blacklisted = TRUE
	var/list/tripwires = list()
	fragment_type = /obj/item/projectile/bullet/pellet/fragment
	var/facing_dir = null
	var/tripwire_range = 2
	matter = list(MATERIAL_STEEL = 35, MATERIAL_PLASTEEL = 5)
	w_class = ITEM_SIZE_NORMAL
	pulse_difficulty = FAILCHANCE_HARD


/obj/item/mine/claymore/update_icon()
	cut_overlays()
	if(deployed)
		icon_state = "claymore_dir"
		dir = facing_dir
	else
		icon_state = "claymore"

/obj/item/mine/claymore/attack_self(mob/user)
	var/turf/center = get_turf(src)

	for(var/i = 1 to tripwire_range)
		var/turf/next = get_step(center, user.dir)

		if(locate(/obj/structure/multiz/ladder) in next || locate(/obj/structure/multiz/stairs) in next)
			to_chat(user, span_warning("There is no suitable surface ahead to extend the sensor."))
			return

		if(next.density)
			to_chat(user, span_warning("Something is blocking the sensor path."))
			return

		for(var/atom/movable/A in next)
			if(A.density)
				to_chat(user, span_warning("Something is blocking the sensor path."))
				return

		center = next

	facing_dir = user.dir
	..()

	if(!armed)
		return

	visible_message(span_danger("\The [src] emits a sharp click as its arming sequence initiates."))

	var/turf/wire_center = center

	spawn(50)
		if(!src || !armed)
			return

		// Cross at wire_center — center, left, right
		for(var/side_dir in list(0, turn(facing_dir, 90), turn(facing_dir, -90)))
			var/turf/T_turf = side_dir ? get_step(wire_center, side_dir) : wire_center
			if(!T_turf || T_turf.density)
				continue
			var/blocked = FALSE
			for(var/atom/movable/A in T_turf)
				if(A.density)
					blocked = TRUE
					break
			if(blocked)
				continue
			var/obj/effect/mine_tripwire/T = new /obj/effect/mine_tripwire(T_turf)
			T.linked_mine = src
			tripwires += T

		// Stem — from wire_center back towards mine, tripwire_range-1 times
		var/turf/stem = wire_center
		var/back_dir = turn(facing_dir, 180)
		for(var/i = 1 to tripwire_range - 1)
			stem = get_step(stem, back_dir)
			if(!stem || stem == get_turf(src)) // don't place on mine tile
				break
			var/blocked = FALSE
			for(var/atom/movable/A in stem)
				if(A.density)
					blocked = TRUE
					break
			if(blocked)
				break
			var/obj/effect/mine_tripwire/S = new /obj/effect/mine_tripwire(stem)
			S.linked_mine = src
			tripwires += S

		visible_message(span_danger("\The [src]'s indicator light blinks red the sensor is now active."))

/obj/item/mine/claymore/explode()
	explosion(get_turf(src), explosion_power, explosion_falloff)

	if(facing_dir)
		var/turf/origin = get_step(src, turn(facing_dir, 180))
		fragment_explosion_angled(get_turf(src), origin, fragment_type, num_fragments)
	else
		fragment_explosion(get_turf(src), spread_radius, fragment_type, num_fragments, null, damage_step)

	if(src)
		qdel(src)

/obj/item/mine/claymore/Crossed(mob/AM)
	if(armed)
		if(isliving(AM))
			var/true_prob_explode = prob_explode - AM.skill_to_evade_traps()

			if(prob(true_prob_explode))
				explode()

			return

	.= ..()

/obj/item/mine/claymore/attackby(obj/item/I, mob/user)
	if(QUALITY_PULSING in I.tool_qualities)
		if(!deployed && !armed)
			if(loc == user)
				var/new_range = input(user, "Set tripwire range (2-4)", "Tripwire Range", tripwire_range) as num|null
				if(new_range && new_range >= 2 && new_range <= 4)
					tripwire_range = new_range
					to_chat(user, span_notice("You set the tripwire range to [tripwire_range]."))
					return
				else if(new_range)
					to_chat(user, span_warning("Range must be between 2 and 4."))
					return
			else
				to_chat(user, span_warning("You must be holding the mine to adjust its range."))
				return

	..()

	if(!armed && tripwires.len)
		for(var/obj/effect/mine_tripwire/TW in tripwires)
			qdel(TW)

		tripwires.Cut()

/obj/item/mine/claymore/attack_hand(mob/user)
	..()

	if(!armed && tripwires.len)
		for(var/obj/effect/mine_tripwire/TW in tripwires)
			qdel(TW)

		tripwires.Cut()

/obj/item/mine/claymore/Destroy()
	for(var/obj/effect/mine_tripwire/TW in tripwires)
		qdel(TW)

	tripwires.Cut()
	return ..()

// --------------------------------
// Tripwire Effect
// --------------------------------

/obj/effect/mine_tripwire
	name = "tripwire"
	anchored = TRUE
	icon = 'icons/effects/alerts.dmi'
	icon_state = "danger"
	invisibility = INVISIBILITY_MAXIMUM
	var/obj/item/mine/claymore/linked_mine

/obj/effect/mine_tripwire/Initialize()
	. = ..()
	update_icon()

/obj/effect/mine_tripwire/update_icon()
	cut_overlays()


/obj/effect/mine_tripwire/Destroy()
	linked_mine = null
	return ..()

/obj/effect/mine_tripwire/Crossed(mob/AM)
	if(!linked_mine || !linked_mine.armed)
		qdel(src)
		return

	if(locate(/obj/structure/multiz/ladder) in get_turf(loc))
		visible_message(span_danger("\The [linked_mine]'s triggering mechanism is disrupted by the ladder and does not go off."))
		return

	if(locate(/obj/structure/multiz/stairs) in get_turf(loc))
		visible_message(span_danger("\The [linked_mine]'s triggering mechanism is disrupted by the slope and does not go off."))
		return

	if(!isliving(AM))
		return

	var/obj/item/mine/claymore/mine = linked_mine
	qdel(src)
	mine.explode()


/obj/item/mine/claymore/ironhammer
	name = "FS DM \"Moneta\""
	desc = "A compact Frozen Star manufactured directional anti-personnel mine. The casing bears a Neohongo inscription 読め: FRONT TOWARDS BELLIGERENTS."
	description_info = "The FS DM 'Moneta' is an aged design, first produced by Frozen Star in the closing years of the Corporate Wars and adopted by Ironhammer as a standard anti-infiltration measure. A reliable if unglamorous fixture of Ironhammer kit the reinforced back casing and hardened sensor housing make it notably more resistant to disarming than the pressure mine. Disarmable and configurable with a Pulsing tool."
	description_antag = "Harder to disarm than its pressure equivalent on account of the reinforced casing. Come prepared or don't bother."
	icon_state = "claymore_frozenstar"
	matter_reagents = list("fuel" = 40)

/obj/item/mine/claymore/ironhammer/update_icon()
	cut_overlays()
	if(deployed)
		icon_state = "frozen_dir"
		dir = facing_dir
	else
		icon_state = "claymore_frozenstar"
