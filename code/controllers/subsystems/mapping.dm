SUBSYSTEM_DEF(mapping)
	name = "Mapping"
	init_order = INIT_ORDER_MAPPING
	flags = SS_NO_FIRE
	init_time_threshold = 1 MINUTE

	var/list/map_templates = list()
	var/dmm_suite/maploader = null
	var/list/teleportlocs = list()
	var/list/ghostteleportlocs = list()
	var/cave_ore_count = 0

/datum/controller/subsystem/mapping/Initialize(start_timeofday)
	if(CONFIG_GET(flag/generate_asteroid))
		// These values determine the specific area that the map is applied to.
		// Because we do not use Bay's default map, we check the config file to see if custom parameters are needed, so we need to avoid hardcoding.
		if(GLOB.maps_data.asteroid_levels)
			for(var/z_level in GLOB.maps_data.asteroid_levels)
				if(!isnum(z_level))
					// If it's still not a number, we probably got fed some nonsense string.
					admin_notice(span_danger("Error: ASTEROID_Z_LEVELS config wasn't given a number."))
				// Now for the actual map generating.  This occurs for every z-level defined in the config.
				new /datum/random_map/automata/cave_system(null, 1, 1, z_level, 300, 300)
		else
			admin_notice(span_danger("Error: No asteroid z-levels defined in config!"))

	if(CONFIG_GET(flag/use_overmap))
		if(!GLOB.maps_data.overmap_z)
			build_overmap()
		else
			testing("Overmap already exist in GLOB.maps_data for [GLOB.maps_data.overmap_z].")
	else
		testing("Overmap generation disabled in config.")

//	world.max_z_changed() // This is to set up the player z-level list, maxz hasn't actually changed (probably)
	maploader = new()
	load_map_templates()
	build_pulsar()

	// Generate cache of all areas in world. This cache allows world areas to be looked up on a list instead of being searched for EACH time
	for(var/area/A in world)
		GLOB.map_areas += A

	sortList(GLOB.map_areas)
	// Do the same for teleport locs
	for(var/area/AR in world)
		if(istype(AR, /area/shuttle) ||  istype(AR, /area/wizard_station)) continue
		if(teleportlocs.Find(AR.name)) continue
		var/turf/picked = pick_area_turf(AR.type, list(/proc/is_station_turf))
		if (picked)
			teleportlocs += AR.name
			teleportlocs[AR.name] = AR

	sortAssoc(teleportlocs)

	// And the same for ghost teleport locs

	for(var/area/AR in world)
		if(ghostteleportlocs.Find(AR.name)) continue
		if(istype(AR, /area/turret_protected/aisat) || istype(AR, /area/derelict) || istype(AR, /area/shuttle/specops/centcom))
			ghostteleportlocs += AR.name
			ghostteleportlocs[AR.name] = AR
		var/turf/picked = pick_area_turf(AR.type, list(/proc/is_station_turf))
		if (picked)
			ghostteleportlocs += AR.name
			ghostteleportlocs[AR.name] = AR

	sortAssoc(ghostteleportlocs)

	return ..()

/datum/controller/subsystem/mapping/proc/build_pulsar()
	world.incrementMaxZ()
	GLOB.maps_data.pulsar_z = world.maxz
	add_z_level(GLOB.maps_data.pulsar_z, GLOB.maps_data.pulsar_z, 1)
	maploader.load_map(file("maps/pulsar/pulsar.dmm"), z_offset = GLOB.maps_data.pulsar_z)
	var/list/turfs = list()
	for(var/square in block(locate(1, 1, GLOB.maps_data.pulsar_z), locate(GLOB.maps_data.pulsar_size, GLOB.maps_data.pulsar_size, GLOB.maps_data.pulsar_z)))
		// Switch to space turf with green grid overlay
		var/turf/space/T = square
		T.name = "[T.x]-[T.y]"
		T.icon_state = "grid"
		T.update_starlight()
		turfs += T
		CHECK_TICK

	var/area/pulsar/A = new
	A.contents.Add(turfs)

	for(var/i in 1 to GLOB.maps_data.pulsar_size)
		var/turf/beam_loc = locate(i, i, GLOB.maps_data.pulsar_z)
		new /obj/effect/pulsar_beam(beam_loc)

		var/turf/beam_right = locate(i + 1, i, GLOB.maps_data.pulsar_z)
		new /obj/effect/pulsar_beam/ul(beam_right)

		var/turf/beam_left = locate(i - 1, i, GLOB.maps_data.pulsar_z)
		new /obj/effect/pulsar_beam/dr(beam_left)

	var/turf/satellite_loc = locate(round((GLOB.maps_data.pulsar_size)/2 + (GLOB.maps_data.pulsar_size)/4), round((GLOB.maps_data.pulsar_size)/2 - (GLOB.maps_data.pulsar_size)/4), GLOB.maps_data.pulsar_z)
	var/turf/shadow_loc = locate(round((GLOB.maps_data.pulsar_size)/2 - (GLOB.maps_data.pulsar_size)/4), round((GLOB.maps_data.pulsar_size)/2 + (GLOB.maps_data.pulsar_size)/4), GLOB.maps_data.pulsar_z)

	var/obj/effect/pulsar_ship/ship = new /obj/effect/pulsar_ship(satellite_loc)
	var/newshadow = new /obj/effect/pulsar_ship_shadow(shadow_loc)
	ship.shadow = newshadow

	if(!GLOB.maps_data.pulsar_star)
		var/turf/T = locate(round((GLOB.maps_data.pulsar_size - 1)/2), round((GLOB.maps_data.pulsar_size - 1)/2), GLOB.maps_data.pulsar_z)
		GLOB.maps_data.pulsar_star = new /obj/effect/pulsar(T)

	GLOB.maps_data.sealed_levels |= GLOB.maps_data.pulsar_z
	generate_pulsar_events()

/datum/controller/subsystem/mapping/proc/generate_pulsar_events()
	var/event_type = pick(subtypesof(/datum/pulsar_event))
	var/datum/pulsar_event/event = new event_type
	event.on_trigger()

/datum/controller/subsystem/mapping/proc/build_overmap()
	testing("Building overmap...")
	world.incrementMaxZ()
	GLOB.maps_data.overmap_z = world.maxz
	var/list/turfs = list()
	for (var/square in block(locate(1,1,GLOB.maps_data.overmap_z), locate(GLOB.maps_data.overmap_size, GLOB.maps_data.overmap_size, GLOB.maps_data.overmap_z)))
		// Switch to space turf with green grid overlay
		var/turf/space/T = square
		T.icon_state = "grid"
		T.update_starlight()
		turfs += T
		CHECK_TICK

	var/area/overmap/A = new
	A.contents.Add(turfs)

    // Spawn star at the center of the overmap
	var/turf/T = locate(round(GLOB.maps_data.overmap_size/2),round(GLOB.maps_data.overmap_size/2),GLOB.maps_data.overmap_z)
	new /obj/effect/star(T)

	GLOB.maps_data.sealed_levels |= GLOB.maps_data.overmap_z
	testing("Overmap build complete.")

/datum/controller/subsystem/mapping/Recover()
	flags |= SS_NO_INIT

/hook/roundstart/proc/init_overmap_events()
	if(CONFIG_GET(flag/use_overmap))
		if(GLOB.maps_data.overmap_z)
			testing("Creating overmap events...")
			testing_variable(t1, world.tick_usage)
			overmap_event_handler.create_events(GLOB.maps_data.overmap_z, GLOB.maps_data.overmap_size, GLOB.maps_data.overmap_event_areas)
			testing("Overmap events created in [(world.tick_usage-t1)*0.01*world.tick_lag] seconds")
		else
			testing("Overmap failed to create events.")
			return FALSE
	return TRUE

/datum/controller/subsystem/mapping/proc/load_map_templates()
	for(var/T in subtypesof(/datum/map_template))
		var/datum/map_template/template = T
		if(!(initial(template.mappath))) // If it's missing the actual path its probably a base type or being used for inheritence.
			continue
		template = new T()
		map_templates[template.name] = template
	return TRUE
