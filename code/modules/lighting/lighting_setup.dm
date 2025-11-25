/proc/create_all_lighting_overlays()
	for(var/area/A in world)
		if (!A.dynamic_lighting)
			continue
		for(var/turf/T in A)
			if (!T.dynamic_lighting)
				continue

			new /atom/movable/lighting_overlay(T, TRUE)
			if (!T.lighting_corners_initialised)
				T.generate_missing_corners()
