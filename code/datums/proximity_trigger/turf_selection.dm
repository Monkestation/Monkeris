/decl/turf_selection/proc/get_turfs(atom/origin, range)
	return list()

/decl/turf_selection/square/get_turfs(atom/origin, range)
	. = list()
	var/turf/center = get_turf(origin)
	if(!center)
		return
	for(var/turf/T in RANGE_TURFS(range, center))
		. += T
