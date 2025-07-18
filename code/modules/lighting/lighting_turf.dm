// Causes any affecting light sources to be queued for a visibility update, for example a door got opened.
/turf/proc/reconsider_lights()
	for(var/A in affecting_lights)
		var/datum/light_source/L = A
		L.vis_update()

/turf/proc/lighting_clear_overlay()
	if(lighting_overlay)
		qdel(lighting_overlay)

	for(var/A in corners)
		var/datum/lighting_corner/C = A
		C.update_active()

// Builds a lighting overlay for us, but only if our area is dynamic.
/turf/proc/lighting_build_overlay()
	if (lighting_overlay)
		return

	var/area/A = loc
	if (!A.dynamic_lighting)
		return

	if (!lighting_corners_initialised)
		generate_missing_corners()

	new /atom/movable/lighting_overlay(src)

	for (var/LC in corners)
		var/datum/lighting_corner/C = LC
		if (!C.active) // We would activate the corner, calculate the lighting for it.
			for (var/L in C.affecting)
				var/datum/light_source/S = L
				S.recalc_corner(C)

			C.active = TRUE

// Used to get a scaled lumcount.
/turf/proc/get_lumcount(minlum = 0, maxlum = 1)
	if (!lighting_overlay)
		return 0.5

	var/totallums = 0
	for(var/LL in corners)
		var/datum/lighting_corner/L = LL
		totallums += L.lum_r + L.lum_b + L.lum_g

	totallums /= 12 // 4 corners, each with 3 channels, get the average.

	totallums = (totallums - minlum) / (maxlum - minlum)

	return CLAMP01(totallums)

// Returns a boolean whether the turf is on soft lighting.
// Soft lighting being the threshold at which point the overlay considers
// itself as too dark to allow sight and see_in_dark becomes useful.
// So basically if this returns true the tile is unlit black.
/turf/proc/is_softly_lit()
	if (!lighting_overlay)
		return FALSE

	return !(luminosity || lighting_overlay.luminosity) // If we have a luminosity or an overlay we are not softly lit.

// Can't think of a good name, this proc will recalculate the has_opaque_atom variable.
/turf/proc/recalc_atom_opacity()
	has_opaque_atom = FALSE
	for (var/atom/A in src.contents)
		if (A.opacity)
			has_opaque_atom = TRUE
			return

	// If we reach this point has_opaque_atom is still false.
	// If we ourselves are opaque this line will consider ourselves.
	// If we are not then this is still faster than doing an explicit check.
	has_opaque_atom = src.opacity

/turf/change_area(area/old_area, area/new_area)
	if(new_area.dynamic_lighting != old_area.dynamic_lighting)
		if(new_area.dynamic_lighting)
			lighting_build_overlay()

		else
			lighting_clear_overlay()

/turf/proc/get_corners(dir)
	if(has_opaque_atom)
		return null // Since this proc gets used in a for loop, null won't be looped though.

	return corners

/turf/proc/generate_missing_corners()
	lighting_corners_initialised = TRUE
	if (!corners)
		corners = list(null, null, null, null)

	for (var/i = 1 to 4)
		if (corners[i]) // Already have a corner on this direction.
			continue

		corners[i] = new/datum/lighting_corner(src, LIGHTING_CORNER_DIAGONAL[i])
