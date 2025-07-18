var/list/z_levels = list()	//Each item represents connection between index z-layer and next z-layer

// The storage of connections between adjacent levels means some bitwise magic is needed.
/proc/HasAbove(z)
	if(z >= world.maxz || z > length(z_levels)-1 || z < 1)
		return FALSE
	var/datum/level_data/LD = z_levels[z]
	return !isnull(LD) && LD.height + LD.original_level - 1 > z

/proc/HasBelow(z)
	if(z > world.maxz || z > length(z_levels) || z < 2)
		return FALSE
	var/datum/level_data/LD = z_levels[z]
	return !isnull(LD) && LD.original_level < z

// Thankfully, no bitwise magic is needed here.
/proc/GetAbove(atom/atom)
	var/turf/turf = get_turf(atom)
	if(!turf)
		return null
	return HasAbove(turf.z) ? get_step(turf, UP) : null

/proc/GetBelow(atom/atom)
	var/turf/turf = get_turf(atom)
	if(!turf)
		return null
	return HasBelow(turf.z) ? get_step(turf, DOWN) : null

/proc/GetConnectedZlevels(z)
	. = list(z)
	for(var/level = z, HasBelow(level), level--)
		. |= level-1
	for(var/level = z, HasAbove(level), level++)
		. |= level+1

/proc/get_zstep(ref, dir)
	if(dir == UP)
		. = GetAbove(ref)
	else if (dir == DOWN)
		. = GetBelow(ref)
	else
		. = get_step(ref, dir)

/proc/AreConnectedZLevels(zA, zB)
	return zA == zB || (zB in GetConnectedZlevels(zA))
