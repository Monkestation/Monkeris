/*

Overview:
	Each zone is a self-contained area where gas values would be the same if tile-based equalization were run indefinitely.
	If you're unfamiliar with ZAS, FEA's air groups would have similar functionality if they didn't break in a stiff breeze.

Class Vars:
	name - A name of the format "Zone [#]", used for debugging.
	invalid - True if the zone has been erased and is no longer eligible for processing.
	needs_update - True if the zone has been added to the update list.
	edges - A list of edges that connect to this zone.
	air - The gas mixture that any turfs in this zone will return. Values are per-tile with a group multiplier.

Class Procs:
	add(turf/T)
		Adds a turf to the contents, sets its zone and merges its air.

	remove(turf/T)
		Removes a turf, sets its zone to null and erases any gas graphics.
		Invalidates the zone if it has no more tiles.

	c_merge(datum/zone/into)
		Invalidates this zone and adds all its former contents to into.

	c_invalidate()
		Marks this zone as invalid and removes it from processing.

	rebuild()
		Invalidates the zone and marks all its former tiles for updates.

	add_tile_air(turf/T)
		Adds the air contained in T.air to the zone's air supply. Called when adding a turf.

	tick()
		Called only when the gas content is changed. Archives values and changes gas graphics.

	dbg_data(mob/M)
		Sends M a printout of important figures for the zone.

*/

/datum/zone
	var/name
	var/invalid = FALSE
	var/needs_update = FALSE
	var/list/contents = list()
	var/list/fire_tiles = list()
	var/list/fuel_objs = list()
	var/list/edges = list()
	var/list/graphic_add = list()
	var/list/graphic_remove = list()
	var/datum/gas_mixture/air = new

/datum/zone/New()
	SSair.add_zone(src)
	air.temperature = TCMB
	air.group_multiplier = 1
	air.volume = CELL_VOLUME

/datum/zone/proc/add(turf/T)
#ifdef ZASDBG
	ASSERT(!invalid)
	ASSERT(T.is_simulated)
#endif

	var/datum/gas_mixture/turf_air = T.return_air()
	add_tile_air(turf_air)
	T.zone = src
	contents.Add(T)
	if(T.fire)
		var/obj/effect/decal/cleanable/liquid_fuel/fuel = locate() in T
		fire_tiles.Add(T)
		SSair.active_fire_zones |= src
		if(fuel) fuel_objs += fuel
	T.update_graphic(air.graphic)

/datum/zone/proc/remove(turf/T)
#ifdef ZASDBG
	ASSERT(!invalid)
	ASSERT(T.is_simulated)
	ASSERT(T.zone == src)
#endif
	contents.Remove(T)
	fire_tiles.Remove(T)
	if(T.fire)
		var/obj/effect/decal/cleanable/liquid_fuel/fuel = locate() in T
		fuel_objs -= fuel
	T.zone = null
	T.update_graphic(graphic_remove = air.graphic)
	if(contents.len)
		air.group_multiplier = contents.len
	else
		c_invalidate()

/datum/zone/proc/c_merge(datum/zone/into)
#ifdef ZASDBG
	ASSERT(!invalid)
	ASSERT(istype(into))
	ASSERT(into != src)
	ASSERT(!into.invalid)
#endif
	c_invalidate()
	for(var/turf/turf as anything in contents)
		if(turf.is_simulated)
			into.add(turf)
			turf.update_graphic(graphic_remove = air.graphic)
			#ifdef ZASDBG
			turf.add_ZAS_debug_overlay(ZAS_DEBUG_OVERLAY_ZONE_MERGED)
			#endif

	//rebuild the old zone's edges so that they will be possessed by the new zone
	for(var/datum/connection_edge/E in edges)
		if(E.contains_zone(into))
			continue //don't need to rebuild this edge
		for(var/turf/T in E.connecting_turfs)
			if(T.is_simulated)
				SSair.mark_for_update(T)

/datum/zone/proc/c_invalidate()
	invalid = TRUE
	SSair.remove_zone(src)
	#ifdef ZASDBG
	for(var/turf/turf as anything in contents)
		if(turf.is_simulated)
			turf.add_ZAS_debug_overlay(ZAS_DEBUG_OVERLAY_ZONE_INVALID)
	#endif

/datum/zone/proc/rebuild()
	if(invalid) return //Short circuit for explosions where rebuild is called many times over.
	c_invalidate()
	for(var/turf/turf as anything in contents)
		if(turf.is_simulated)
			turf.update_graphic(graphic_remove = air.graphic) //we need to remove the overlays so they're not doubled when the zone is rebuilt
			turf.needs_air_update = FALSE //Reset the marker so that it will be added to the list.
			SSair.mark_for_update(turf)
			#ifdef ZASDBG
			turf.add_ZAS_debug_overlay(ZAS_DEBUG_OVERLAY_ZONE_INVALID)
			#endif

/datum/zone/proc/add_tile_air(datum/gas_mixture/tile_air)
	//air.volume += CELL_VOLUME
	air.group_multiplier = 1
	air.multiply(contents.len)
	air.merge(tile_air)
	air.divide(contents.len+1)
	air.group_multiplier = contents.len+1

/datum/zone/proc/tick()
	if(air.temperature >= PLASMA_FLASHPOINT && !(src in SSair.active_fire_zones) && air.check_combustability() && contents.len)
		var/turf/T = pick(contents)
		if(istype(T))
			T.create_fire(vsc.fire_firelevel_multiplier)

	if(air.check_tile_graphic(graphic_add, graphic_remove))
		for(var/turf/turf as anything in contents)
			if(turf.is_simulated)
				turf.update_graphic(graphic_add, graphic_remove)
		graphic_add.len = 0
		graphic_remove.len = 0

	for(var/datum/connection_edge/E in edges)
		if(E.sleeping)
			E.recheck()

/datum/zone/proc/dbg_data(mob/M)
	to_chat(M, name)
	for(var/g in air.gas)
		to_chat(M, "[gas_data.name[g]]: [air.gas[g]]")
	to_chat(M, "P: [air.return_pressure()] kPa V: [air.volume]L T: [air.temperature]�K ([air.temperature - T0C]�C)")
	to_chat(M, "O2 per N2: [(air.gas["nitrogen"] ? air.gas["oxygen"]/air.gas["nitrogen"] : "N/A")] Moles: [air.total_moles]")
	to_chat(M, "Simulated: [contents.len] ([air.group_multiplier])")
	//M << "Unsimulated: [unsimulated_contents.len]"
	//M << "Edges: [edges.len]"
	if(invalid) to_chat(M, "Invalid!")
	var/zone_edges = 0
	var/space_edges = 0
	var/space_coefficient = 0
	for(var/datum/connection_edge/E in edges)
		if(E.type == /datum/connection_edge/zone) zone_edges++
		else
			space_edges++
			space_coefficient += E.coefficient
			to_chat(M, "[E:air:return_pressure()]kPa")

	to_chat(M, "Zone Edges: [zone_edges]")
	to_chat(M, "Space Edges: [space_edges] ([space_coefficient] connections)")

	//for(var/turf/T in unsimulated_contents)
	//	M << "[T] at ([T.x],[T.y])"
