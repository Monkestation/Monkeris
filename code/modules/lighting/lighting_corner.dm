// Because we can control each corner of every lighting overlay.
// And corners get shared between multiple turfs (unless you're on the corners of the map, then 1 corner doesn't).
// For the record: these should never ever ever be deleted, even if the turf doesn't have dynamic lighting.

// This list is what the code that assigns corners listens to, the order in this list is the order in which corners are added to the /turf/corners list.
var/list/LIGHTING_CORNER_DIAGONAL = list(NORTHEAST, SOUTHEAST, SOUTHWEST, NORTHWEST)

/datum/lighting_corner
	var/list/turf/masters                 = list()
	var/list/datum/light_source/affecting = list() // Light sources affecting us.
	var/active                            = FALSE  // TRUE if one of our masters has dynamic lighting.

	var/x     = 0
	var/y     = 0

	var/lum_r = 0
	var/lum_g = 0
	var/lum_b = 0

	var/needs_update = FALSE

	var/cache_r  = 0
	var/cache_g  = 0
	var/cache_b  = 0
	var/cache_mx = 0

	var/update_gen = 0

/datum/lighting_corner/New(turf/new_turf, diagonal)
	. = ..()

	masters[new_turf] = turn(diagonal, 180)

	var/vertical   = diagonal & ~(diagonal - 1) // The horizontal directions (4 and 8) are bigger than the vertical ones (1 and 2), so we can reliably say the lsb is the horizontal direction.
	var/horizontal = diagonal & ~vertical       // Now that we know the horizontal one we can get the vertical one.

	x = new_turf.x + (horizontal == EAST  ? 0.5 : -0.5)
	y = new_turf.y + (vertical   == NORTH ? 0.5 : -0.5)

	// My initial plan was to make this loop through a list of all the dirs (horizontal, vertical, diagonal).
	// Issue being that the only way I could think of doing it was very messy, slow and honestly overengineered.
	// So we'll have this hardcode instead.
	var/turf/T
	var/i

	// Diagonal one is easy.
	T = get_step(new_turf, diagonal)
	if(T) // In case we're on the map's border.
		if (!T.corners)
			T.corners = list(null, null, null, null)

		masters[T]   = diagonal
		i            = LIGHTING_CORNER_DIAGONAL.Find(turn(diagonal, 180))
		T.corners[i] = src

	// Now the horizontal one.
	T = get_step(new_turf, horizontal)
	if(T) // Ditto.
		if (!T.corners)
			T.corners = list(null, null, null, null)

		masters[T]   = ((T.x > x) ? EAST : WEST) | ((T.y > y) ? NORTH : SOUTH) // Get the dir based on coordinates.
		i            = LIGHTING_CORNER_DIAGONAL.Find(turn(masters[T], 180))
		T.corners[i] = src

	// And finally the vertical one.
	T = get_step(new_turf, vertical)
	if(T)
		if (!T.corners)
			T.corners = list(null, null, null, null)

		masters[T]   = ((T.x > x) ? EAST : WEST) | ((T.y > y) ? NORTH : SOUTH) // Get the dir based on coordinates.
		i            = LIGHTING_CORNER_DIAGONAL.Find(turn(masters[T], 180))
		T.corners[i] = src

	update_active()

/datum/lighting_corner/proc/update_active()
	active = FALSE
	for (var/TT in masters)
		var/turf/T = TT
		if (T.lighting_overlay)
			active = TRUE
			return

// God that was a mess, now to do the rest of the corner code! Hooray!
/datum/lighting_corner/proc/update_lumcount(delta_r, delta_g, delta_b)
	lum_r += delta_r
	lum_g += delta_g
	lum_b += delta_b

	if (!needs_update)
		needs_update = TRUE
		global.lighting_update_corners += src

/datum/lighting_corner/proc/update_overlays()
	// Cache these values a head of time so 4 individual lighting overlays don't all calculate them individually.
	var/lum_r = src.lum_r
	var/lum_g = src.lum_g
	var/lum_b = src.lum_b
	var/mx = max(lum_r, lum_g, lum_b) // Scale it so 1 is the strongest lum, if it is above 1.
	. = 1 // factor
	if (mx > 1)
		. = 1 / mx

	else if (mx < LIGHTING_SOFT_THRESHOLD)
		. = 0 // 0 means soft lighting.

	cache_r  = lum_r * . || LIGHTING_SOFT_THRESHOLD
	cache_g  = lum_g * . || LIGHTING_SOFT_THRESHOLD
	cache_b  = lum_b * . || LIGHTING_SOFT_THRESHOLD
	cache_mx = mx

	for (var/TT in masters)
		var/turf/T = TT
		var/atom/movable/lighting_overlay/O = T.lighting_overlay
		if (O && !O.needs_update)
			O.needs_update = TRUE
			global.lighting_update_overlays += O


/datum/lighting_corner/dummy/New()
	return
