/area/proc/set_dynamic_lighting(new_dynamic_lighting = TRUE)
	if (new_dynamic_lighting == dynamic_lighting)
		return FALSE

	dynamic_lighting = new_dynamic_lighting

	if (new_dynamic_lighting)
		for (var/turf/T in world)
			if (T.dynamic_lighting)
				T.lighting_build_overlay()

	else
		for (var/turf/T in world)
			if (T.lighting_overlay)
				T.lighting_clear_overlay()

	return TRUE
