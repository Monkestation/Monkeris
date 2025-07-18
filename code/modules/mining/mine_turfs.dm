/**********************Mineral deposits**************************/
/turf/mineral_unsimulated
	name = "impassable rock"
	icon = 'icons/turf/walls.dmi'
	icon_state = "rock-dark"
	blocks_air = 1
	density = TRUE
	layer = EDGED_TURF_LAYER
	oxygen = MOLES_O2STANDARD
	nitrogen = MOLES_N2STANDARD
	is_simulated = FALSE

/turf/mineral //wall piece
	name = "Rock"
	icon = 'icons/turf/walls.dmi'
	icon_state = "rock"
	oxygen = 0
	nitrogen = 0
	opacity = 1
	density = TRUE
	layer = EDGED_TURF_LAYER
	blocks_air = 1
	temperature = T0C
	var/mined_turf = /turf/floor/asteroid
	var/ore/mineral
	var/mined_ore = 0
	var/last_act = 0
	var/emitter_blasts_taken = 0 // EMITTER MINING! Muhehe.

	var/datum/geosample/geologic_data
	var/excavation_level = 0
	var/list/finds
	var/archaeo_overlay = ""
	var/excav_overlay = ""
	var/obj/item/last_find
	var/datum/artifact_find/artifact_find

/turf/mineral/Initialize()
	.=..()
	icon_state = "rock[rand(0,4)]"
	spawn(0)
		MineralSpread()

/turf/mineral/can_build_cable()
	return !density

/turf/mineral/is_plating()
	return TRUE
/turf/mineral/explosion_act(target_power, explosion_handler/handler)
	. = ..()
	if(src && target_power > 75)
		mined_ore = 1
		GetDrilled()

/turf/mineral/bullet_act(obj/item/projectile/Proj)

	// Emitter blasts
	if(istype(Proj, /obj/item/projectile/beam/emitter))
		emitter_blasts_taken++

		if(emitter_blasts_taken > 2) // 3 blasts per tile
			mined_ore = 1
			GetDrilled()
	else ..()

/turf/mineral/Bumped(AM)
	. = ..()
	if(ishuman(AM))
		var/mob/living/carbon/human/H = AM
		if(istype(H.l_hand,/obj/item))
			var/obj/item/I = H.l_hand
			if((QUALITY_DIGGING in I.tool_qualities) && (!H.hand))
				attackby(I,H)
		if(istype(H.r_hand,/obj/item))
			var/obj/item/I = H.r_hand
			if((QUALITY_DIGGING in I.tool_qualities) && (H.hand))
				attackby(I,H)

	else if(isrobot(AM))
		var/mob/living/silicon/robot/R = AM
		if(istype(R.module_active,/obj/item))
			var/obj/item/I = R.module_active
			if(QUALITY_DIGGING in I.tool_qualities)
				attackby(I,R)

	else if(istype(AM,/mob/living/exosuit))
		var/mob/living/exosuit/mech = AM
		if(LAZYLEN(mech.pilots) && istype(mech.selected_system, /obj/item/mech_equipment/drill))
			var/obj/item/mech_equipment/drill/drill = mech.selected_system
			drill.mine(src, mech.pilots[1], mech.Adjacent(src))

/turf/mineral/proc/MineralSpread()
	if(mineral && mineral.spread)
		for(var/trydir in GLOB.cardinal)
			if(prob(mineral.spread_chance))
				var/turf/mineral/target_turf = get_step(src, trydir)
				if(istype(target_turf) && !target_turf.mineral)
					target_turf.mineral = mineral
					target_turf.UpdateMineral()
					target_turf.MineralSpread()


/turf/mineral/proc/UpdateMineral()
	clear_ore_effects()
	if(!mineral)
		name = "\improper Rock"
		icon_state = "rock"
		return
	name = "\improper [mineral.display_name] deposit"
	var/obj/effect/mineral/M = new /obj/effect/mineral(src, mineral)
	spawn(1)
		M.color = color

//Not even going to touch this pile of spaghetti
/turf/mineral/attackby(obj/item/I, mob/living/user)

	var/tool_type = I.get_tool_type(user, list(QUALITY_DIGGING, QUALITY_EXCAVATION), src, CB = CALLBACK(src, PROC_REF(check_radial_dig)))
	switch(tool_type)

		if(QUALITY_EXCAVATION)
			var/excavation_amount = input("How deep are you going to dig?", "Excavation depth", 0)
			if(excavation_amount)
				to_chat(user, span_notice("You start exacavating [src]."))
				if(I.use_tool(user, src, WORKTIME_NORMAL, tool_type, FAILCHANCE_NORMAL, required_stat = STAT_COG))
					to_chat(user, span_notice("You finish excavating [src]."))
					excavation_level += excavation_amount
					GetDrilled(0)
				return
			return

		if(QUALITY_DIGGING)
			to_chat(user, span_notice("You start digging the [src]."))
			if(I.use_tool(user, src, WORKTIME_FAST, tool_type, FAILCHANCE_VERY_EASY, required_stat = STAT_ROB))
				to_chat(user, span_notice("You finish digging the [src]."))
				GetDrilled(0)
			return
		if(ABORT_CHECK)
			return
		else
			return ..()

/turf/mineral/proc/clear_ore_effects()
	for(var/obj/effect/mineral/M in contents)
		qdel(M)

/turf/mineral/proc/DropMineral()
	if(!mineral)
		return
	clear_ore_effects()
	var/obj/item/ore/O = new mineral.ore (src)
	return O

/turf/mineral/proc/GetDrilled(artifact_fail = 0)
	//var/destroyed = 0 //used for breaking strange rocks
	if (mineral && mineral.result_amount)

		//if the turf has already been excavated, some of it's ore has been removed
		for (var/i = 1 to mineral.result_amount - mined_ore)
			DropMineral()

	//Add some rubble,  you did just clear out a big chunk of rock.

	var/turf/floor/asteroid/N = ChangeTurf(mined_turf)

	if(istype(N))
		N.overlay_detail = "asteroid[rand(0,9)]"
		N.updateMineralOverlays(1)


/turf/mineral/random
	name = "Mineral deposit"
	var/mineralSpawnChanceList = list(ORE_URANIUM = 5, ORE_PLATINUM = 5, ORE_IRON = 35, ORE_CARBON = 35, ORE_DIAMOND = 1, ORE_GOLD = 5, ORE_SILVER = 5, ORE_PLASMA = 10)
	var/mineralChance = 50 //%

/turf/mineral/random/New()
	if (prob(mineralChance) && !mineral)
		var/mineral_name = pickweight(mineralSpawnChanceList) //temp mineral name
		mineral_name = lowertext(mineral_name)
		if (mineral_name && (mineral_name in ore_data))
			mineral = ore_data[mineral_name]
			UpdateMineral()

	. = ..()

/turf/mineral/proc/check_radial_dig()
	return TRUE

/turf/mineral/random/high_chance
	mineralChance = 75 //%
	mineralSpawnChanceList = list(ORE_URANIUM = 10, ORE_PLATINUM = 10, ORE_IRON = 20, ORE_CARBON = 20, ORE_DIAMOND = 2, ORE_GOLD = 10, ORE_SILVER = 10, ORE_PLASMA = 20)


/**********************Asteroid**************************/

// Setting icon/icon_state initially will use these values when the turf is built on/replaced.
// This means you can put grass on the asteroid etc.
/turf/floor/asteroid
	name = "sand"
	icon = 'icons/turf/flooring/asteroid.dmi'
	icon_state = "asteroid"

	initial_flooring = /decl/flooring/asteroid
	oxygen = 0
	nitrogen = 0
	temperature = TCMB
	var/dug = 0       //0 = has not yet been dug, 1 = has already been dug
	var/overlay_detail

/turf/floor/asteroid/New()
	..()
	icon_state = "asteroid[rand(0,2)]"
	if(prob(20))
		overlay_detail = "asteroid[rand(0,8)]"
		updateMineralOverlays(1)
	seismic_activity = rand(1,6)

/turf/floor/asteroid/explosion_act(target_power, explosion_handler/handler)
	. = ..()
	if(src && target_power > 50)
		gets_dug()

/turf/floor/asteroid/is_plating()
	return !density

/turf/floor/asteroid/attackby(obj/item/I, mob/user)

	if(QUALITY_DIGGING in I.tool_qualities)
		if (dug)
			to_chat(user, span_warning("This area has already been dug"))
			return
		if(I.use_tool(user, src, WORKTIME_FAST, QUALITY_DIGGING, FAILCHANCE_EASY, required_stat = STAT_ROB))
			to_chat(user, span_notice("You dug a hole."))
			gets_dug()

	else
		..(I,user)

/turf/floor/asteroid/proc/gets_dug()

	if(dug)
		return

	for(var/i=0;i<(rand(3)+2);i++)
		new/obj/item/ore/glass(src)

	dug = 1
	icon_state = "asteroid_dug"
	return

/turf/floor/asteroid/proc/updateMineralOverlays(update_neighbors)

	overlays.Cut()

	var/list/step_overlays = list("n" = NORTH, "s" = SOUTH, "e" = EAST, "w" = WEST)
	for(var/direction in step_overlays)

		if(istype(get_step(src, step_overlays[direction]), /turf/space))
			overlays += image('icons/turf/flooring/asteroid.dmi', "asteroid_edges", dir = step_overlays[direction])

	//todo cache
	if(overlay_detail) overlays |= image(icon = 'icons/turf/flooring/decals.dmi', icon_state = overlay_detail)

	if(update_neighbors)
		var/list/all_step_directions = list(NORTH,NORTHEAST,EAST,SOUTHEAST,SOUTH,SOUTHWEST,WEST,NORTHWEST)
		for(var/direction in all_step_directions)
			var/turf/floor/asteroid/A
			if(istype(get_step(src, direction), /turf/floor/asteroid))
				A = get_step(src, direction)
				A.updateMineralOverlays()

/turf/floor/asteroid/Entered(atom/movable/M as mob|obj)
	..()
	if(isrobot(M))
		var/mob/living/silicon/robot/R = M
		if(R.module)
			if(istype(R.module_state_1,/obj/item/storage/bag/ore))
				attackby(R.module_state_1,R)
			else if(istype(R.module_state_2,/obj/item/storage/bag/ore))
				attackby(R.module_state_2,R)
			else if(istype(R.module_state_3,/obj/item/storage/bag/ore))
				attackby(R.module_state_3,R)
			else
				return

/turf/floor/asteroid/proc/check_radial_dig()
	return FALSE

/turf/floor/asteroid/take_damage(damage, damage_type = BRUTE, ignore_resistance = FALSE)
	// Asteroid turfs are indestructible, otherwise they can be destroyed at some point and expose metal plating
	return
