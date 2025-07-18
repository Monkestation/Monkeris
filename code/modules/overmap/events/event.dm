var/decl/overmap_event_handler/overmap_event_handler = new()

/decl/overmap_event_handler
	var/list/event_turfs_by_z_level
	var/last_tick = 0
	var/obj/jtb_generator/jtb_gen  // jtb generator

/decl/overmap_event_handler/New()
	..()
	event_turfs_by_z_level = list()

/decl/overmap_event_handler/proc/create_events(z_level, overmap_size, number_of_events)
	// Acquire the list of not-yet utilized overmap turfs on this Z-level
	var/list/events_by_turf = get_event_turfs_by_z_level(z_level)
	var/list/candidate_turfs = block(locate(OVERMAP_EDGE, OVERMAP_EDGE, z_level),locate(overmap_size - OVERMAP_EDGE, overmap_size - OVERMAP_EDGE,z_level))
//	if(!candidate_turfs.len)
//		world << "candidate_tufs list is empty after creation"
	candidate_turfs -= events_by_turf
//	if(!candidate_turfs.len)
//		world << "candidate_tufs list gets empty after removing events_by_turf"
	candidate_turfs = where(candidate_turfs, /proc/can_not_locate, /obj/effect/overmap)
//	if(!candidate_turfs.len)
//		world << "candidate_tufs list gets empty after where()"

	for(var/i = 1 to number_of_events)
		if(!candidate_turfs.len)
//			world << "No candidate_tufs"
			break
		var/overmap_event_type = pick(subtypesof(/datum/overmap_event))
		if(!ispath(overmap_event_type, /datum/overmap_event/meteor/comet_tail) && \
		!ispath(overmap_event_type, /datum/overmap_event/meteor/comet_tail_medium) && \
		!ispath(overmap_event_type, /datum/overmap_event/meteor/comet_tail_core))
			var/datum/overmap_event/overmap_event = new overmap_event_type

			var/list/event_turfs = acquire_event_turfs(overmap_event.count, overmap_event.radius, candidate_turfs, overmap_event.continuous)
			candidate_turfs -= event_turfs

			for(var/event_turf in event_turfs)
				events_by_turf[event_turf] = overmap_event
				GLOB.entered_event.register(event_turf, src, /decl/overmap_event_handler/proc/on_turf_entered)
				GLOB.exited_event.register(event_turf, src, /decl/overmap_event_handler/proc/on_turf_exited)

				var/obj/effect/overmap_event/event = new(event_turf)
	//			world << "Created new event in [event.loc.x], [event.loc.y]"
				event.name = overmap_event.event_name_stages[3]
				event.icon_state = "poi"
				event.icon_stages = list(pick(overmap_event.event_icon_stage0), pick(overmap_event.event_icon_stage1), "poi")
				event.name_stages = overmap_event.event_name_stages
				event.opacity =  overmap_event.opacity

	spawn_points_of_interest(candidate_turfs)

/decl/overmap_event_handler/proc/spawn_points_of_interest(list/candidate_turfs)
	var/list/pois = list(/obj/effect/overmap_event/poi/debris, /obj/effect/overmap_event/poi/station)
	for(var/path in pois)
		if(!candidate_turfs.len)
			break
		var/turf/poi_turf = pick(candidate_turfs)
		candidate_turfs -= poi_turf
		new path(poi_turf)

/decl/overmap_event_handler/proc/get_event_turfs_by_z_level(z_level)
	var/z_level_text = num2text(z_level)
	. = event_turfs_by_z_level[z_level_text]
	if(!.)
		. = list()
		event_turfs_by_z_level[z_level_text] = .

/decl/overmap_event_handler/proc/acquire_event_turfs(number_of_turfs, distance_from_origin, list/candidate_turfs, continuous = TRUE)
	number_of_turfs = min(number_of_turfs, candidate_turfs.len)
	candidate_turfs = candidate_turfs.Copy() // Not this proc's responsibility to adjust the given lists

	var/origin_turf = pick(candidate_turfs)
	var/list/selected_turfs = list(origin_turf)
	var/list/selection_turfs = list(origin_turf)
	candidate_turfs -= origin_turf

	while(selection_turfs.len && selected_turfs.len < number_of_turfs)
		var/selection_turf = pick(selection_turfs)
		var/random_neighbour = get_random_neighbour(selection_turf, candidate_turfs, continuous, distance_from_origin)

		if(random_neighbour)
			candidate_turfs -= random_neighbour
			selected_turfs += random_neighbour
			if(get_dist(origin_turf, random_neighbour) < distance_from_origin)
				selection_turfs += random_neighbour
		else
			selection_turfs -= selection_turf

	return selected_turfs

/decl/overmap_event_handler/proc/get_random_neighbour(turf/origin_turf, list/candidate_turfs, continuous = TRUE, range)
	var/fitting_turfs
	if(continuous)
		fitting_turfs = origin_turf.CardinalTurfs(FALSE)
	else
		fitting_turfs = RANGE_TURFS(range, origin_turf)
	fitting_turfs = shuffle(fitting_turfs)
	for(var/turf/T in fitting_turfs)
		if(T in candidate_turfs)
			return T

/decl/overmap_event_handler/proc/on_turf_exited(turf/old_loc, obj/effect/overmap/ship/entering_ship, new_loc)
	if(!istype(entering_ship))
		return
	if(new_loc == old_loc)
		return

	var/list/events_by_turf = get_event_turfs_by_z_level(old_loc.z)
	var/datum/overmap_event/old_event = events_by_turf[old_loc]
	var/datum/overmap_event/new_event = events_by_turf[new_loc]

	if(old_event == new_event)
		return
	if(old_event)
		if(new_event && old_event.difficulty == new_event.difficulty && old_event.event == new_event.event)
			return
		old_event.leave(entering_ship)

/decl/overmap_event_handler/proc/on_turf_entered(turf/new_loc, obj/effect/overmap/ship/entering_ship, old_loc)
	if(!istype(entering_ship))
		return
	if(new_loc == old_loc)
		return

	var/list/events_by_turf = get_event_turfs_by_z_level(new_loc.z)
	var/datum/overmap_event/old_event = events_by_turf[old_loc]
	var/datum/overmap_event/new_event = events_by_turf[new_loc]

	if(old_event == new_event)
		return
	if(new_event)
		if(old_event && old_event.difficulty == new_event.difficulty && initial(old_event.event) == initial(new_event.event))
			return
		new_event.enter(entering_ship)

/decl/overmap_event_handler/proc/scan_loc(obj/effect/overmap/ship/S, turf/new_loc, can_scan, stage_2_width = 1)

	if(!can_scan) // No active scanner
		// Everything is stage 2 (too far for sensors)
		for(var/turf/T in range(S.scan_range+1, new_loc))
			for(var/obj/effect/overmap_event/E in T)
				E.name = E.name_stages[3]
				E.icon_state = E.icon_stages[3]
	else
		var/passive_scan = (world.time - last_tick) > PASSIVE_SCAN_PERIOD
		if(passive_scan)
			last_tick = world.time

		// Scanning sound
		if(passive_scan)
			playsound(new_loc, 'sound/effects/fastbeep.ogg', 100, 1)
			if(S.nav_control)
				var/obj/machinery/computer/helm/H = S.nav_control
				if(H.manual_control)  // if someone is manually controling the ship with the helm console
					playsound(H.loc, 'sound/effects/fastbeep.ogg', 50, 1)

		// Stage 0 (close range)
		for(var/turf/T in circlerange(new_loc, S.scan_range-1))
			for(var/obj/effect/overmap_event/E in T)
				E.name = E.name_stages[1]
				if(!passive_scan)
					E.icon_state = E.icon_stages[1]  // No outline
				else
					E.icon_state = E.icon_stages[1] + "_g"  // Green outline
			for(var/obj/effect/overmap/E in T)
				E.name = E.name_stages[1]
				if((!passive_scan) || istype(E, /obj/effect/overmap/sector/exoplanet))
					E.icon_state = E.icon_stages[1]  // No outline
				else
					E.icon_state = E.icon_stages[1] + "_g"  // Green outline

		// Stage 1 (limit range)
		for(var/turf/T in getcircle(new_loc, S.scan_range))
			for(var/obj/effect/overmap_event/E in T)
				E.name = E.name_stages[2]
				E.icon_state = E.icon_stages[2]
			for(var/obj/effect/overmap/E in T)
				E.name = E.name_stages[2]
				E.icon_state = E.icon_stages[2]

		// Stage 2 (too far for sensors)
		for(var/i in 1 to stage_2_width)
			for(var/turf/T in getcircle(new_loc, S.scan_range + i))
				for(var/obj/effect/overmap_event/E in T)
					E.name = E.name_stages[3]
					E.icon_state = E.icon_stages[3]
				for(var/obj/effect/overmap/E in T)
					E.name = E.name_stages[3]
					E.icon_state = E.icon_stages[3]

	return

// Reveal a point of interest if the ship is standing on it on the overmap
/decl/overmap_event_handler/proc/scan_poi(obj/effect/overmap/ship/S, turf/my_loc)
	for(var/obj/effect/overmap_event/poi/E in get_turf(my_loc))
		E.reveal()
	return

// We don't subtype /obj/effect/overmap because that'll create sections one can travel to
//  And with them "existing" on the overmap Z-level things quickly get odd.
/obj/effect/overmap_event
	name = "unknown spatial phenomenon"
	icon = 'icons/obj/overmap.dmi'
	icon_state = "poi"
	opacity = 1

	// Stage 0: close, well scanned by sensors
	// Stage 1: medium, barely scanned by sensors
	// Stage 2: far, not scanned by sensors
	var/list/name_stages = list("stage0", "stage1", "stage2")
	var/list/icon_stages = list("generic", "object", "poi")

/datum/overmap_event
	var/name = "map event"
	var/radius = 2
	var/count = 6
	var/event = null
	var/list/event_icon_states = list("event")
	var/opacity = 1
	var/difficulty = EVENT_LEVEL_MODERATE
	var/list/victims
	var/continuous = TRUE //if it should form continous blob, or can have gaps

	var/list/event_icon_stage0 = list("generic")
	var/list/event_icon_stage1 = list("object")
	var/list/event_name_stages = list("name_stage0", "name_stage1", "name_stage2")

/datum/overmap_event/proc/enter(obj/effect/overmap/ship/victim)
//	world << "Ship [victim] encountered [name]"
	if(!SSevent)
		admin_notice(span_danger("Event manager not setup."))
		return
	if(victim in victims)
		if(!istype(src, /datum/overmap_event/meteor/comet_tail_core) && \
		!istype(src, /datum/overmap_event/meteor/comet_tail_medium)  && \
		!istype(src, /datum/overmap_event/meteor/comet_tail))
			admin_notice(span_danger("Multiple attempts to trigger the same event by [victim] detected."))
			return
	LAZYADD(victims, victim)
	//var/datum/event_meta/EM = new(difficulty, "Overmap event - [name]", event, add_to_queue = FALSE, is_one_shot = TRUE)
	var/datum/event/E = new event(null, difficulty)
	E.name = "Overmap event - [E.name]"
	E.startWhen = 0
	E.endWhen = INFINITY
	victims[victim] = E
	E.Initialize()

/datum/overmap_event/proc/leave(victim)
	if(victims && victims[victim])
		var/datum/event/E = victims[victim]
		E.kill()
		LAZYREMOVE(victims, victim)

/datum/overmap_event/meteor
	name = "asteroid field"
	event = /datum/event/meteor_wave/overmap
	count = 15
	radius = 4
	continuous = FALSE
	event_icon_stage0 = list("meteors0", "meteors1", "meteors2", "meteors3")
	event_icon_stage1 = list("field")
	event_name_stages = list("asteroid field", "unknown field", "unknown spatial phenomenon")
	difficulty = EVENT_LEVEL_MAJOR

/datum/overmap_event/meteor/comet_tail
	name = "thin comet tail"
	event = /datum/event/meteor_wave/overmap/space_comet/mini
	count = 16
	radius = 4
	continuous = FALSE
	event_icon_stage0 = list("dust0", "dust1", "dust2", "dust3")
	event_icon_stage1 = list("field")
	event_name_stages = list("thin comet tail", "unknown field", "unknown spatial phenomenon")

/datum/overmap_event/meteor/comet_tail_medium
	name = "comet tail"
	event = /datum/event/meteor_wave/overmap/space_comet/medium
	count = 16
	radius = 4
	continuous = FALSE
	event_icon_stage0 = list("meteors0", "meteors1", "meteors2", "meteors3")
	event_icon_stage1 = list("field")
	event_name_stages = list("comet tail", "unknown field", "unknown spatial phenomenon")

/datum/overmap_event/meteor/comet_tail_core
	name = "comet core"
	event = /datum/event/meteor_wave/overmap/space_comet/hard
	count = 16
	radius = 4
	continuous = FALSE
	event_icon_stage0 = list("asteroid0", "asteroid1", "asteroid2", "asteroid3")
	event_icon_stage1 = list("object")
	event_name_stages = list("comet core", "unknown object", "unknown spatial phenomenon")

/datum/overmap_event/meteor/enter(obj/effect/overmap/ship/victim)
	..()
	if(victims[victim])
		var/datum/event/meteor_wave/overmap/E = victims[victim]
		E.victim = victim

/datum/overmap_event/electric
	name = "electrical storm"
	event = /datum/event/electrical_storm
	count = 11
	radius = 3
	opacity = 0
	event_icon_stage0 = list("electrical0", "electrical1", "electrical2", "electrical3")
	event_icon_stage1 = list("field")
	event_name_stages = list("electrical storm", "unknown field", "unknown spatial phenomenon")
	difficulty = EVENT_LEVEL_MAJOR

/datum/overmap_event/dust
	name = "dust cloud"
	event = /datum/event/dust
	count = 16
	radius = 4
	event_icon_stage0 = list("dust0", "dust1", "dust2", "dust3")
	event_icon_stage1 = list("field")
	event_name_stages = list("dust cloud", "unknown field", "unknown spatial phenomenon")

/datum/overmap_event/ion
	name = "ion cloud"
	event = /datum/event/ionstorm
	count = 8
	radius = 3
	opacity = 0
	event_icon_stage0 = list("ion0", "ion1", "ion2", "ion3")
	event_icon_stage1 = list("field")
	event_name_stages = list("ion cloud", "unknown field", "unknown spatial phenomenon")

/datum/overmap_event/carp
	name = "carp shoal"
	event = /datum/event/carp_migration
	count = 8
	radius = 3
	opacity = 0
	difficulty = EVENT_LEVEL_MODERATE
	continuous = FALSE
	event_icon_stage0 = list("carps_shoal0", "carps_shoal1", "carps_shoal2", "carps_shoal3")
	event_icon_stage1 = list("field")
	event_name_stages = list("carp shoal", "unknown field", "unknown spatial phenomenon")

/datum/overmap_event/carp/major
	name = "carp school"
	count = 5
	radius = 4
	difficulty = EVENT_LEVEL_MAJOR
	event_icon_stage0 = list("carps_school0", "carps_school1", "carps_school2", "carps_school3")
	event_icon_stage1 = list("field")
	event_name_stages = list("carp school", "unknown field", "unknown spatial phenomenon")


//////
// Points of Interest on overmap that the ship has to scan
//////
/obj/effect/overmap_event/poi
	name_stages = list("point of interest", "unknown object", "unknown spatial phenomenon")
	icon_stages = list("nodata", "nodata", "poi")

	var/revealed = FALSE

/obj/effect/overmap_event/poi/proc/reveal()
	return

/obj/effect/overmap_event/poi/debris

/obj/effect/overmap_event/poi/debris/reveal()
	if(revealed)
		return
	else
		revealed = TRUE

	name_stages = list("space wrecks", "unknown ship", "unknown spatial phenomenon")
	icon_stages = list("spacehulk", "ship", "poi")

	log_game("Space wrecks point of interest has been scanned and revealed.")
	overmap_event_handler.jtb_gen.add_specific_junk_field("SpaceWrecks")
	return

/obj/effect/overmap_event/poi/station

/obj/effect/overmap_event/poi/station/reveal()
	if(revealed)
		return
	else
		revealed = TRUE

	log_game("Trading station point of interest has been scanned and revealed.")
	SStrade.AddStation(loc)  // Add a new random station at this location
	qdel(src)  // Clear the POI effect since there is a trading station at that location now
	return

/obj/effect/overmap_event/poi/blacksite
	var/obj/effect/overmap/sector/blacksite/linked  // Linked blacksite sector

/obj/effect/overmap_event/poi/blacksite/New(loc, obj/effect/overmap/sector/linked_sector)
	..(loc)
	linked = linked_sector

/obj/effect/overmap_event/poi/blacksite/Destroy()
	linked = null
	. = ..()

/obj/effect/overmap_event/poi/blacksite/reveal()
	if(revealed)
		return
	else
		revealed = TRUE

	// Blacksite sector is now known and no longer hidden
	if(linked)
		linked.known = 1
		linked.invisibility = 0
		linked.update_known()
		log_game("Blacksite point of interest has been scanned and revealed.")
	else
		log_world("## ERROR: Blacksite point of interest was not linked to a sector.")

	qdel(src)  // Clear the POI effect since there is a blacksite revealed at that location now
	return
