#define PLANES_PER_Z_LEVEL 32

/atom/proc/init_plane()	//Set initial original plane
	if(!original_plane)
		original_plane = plane

/atom/proc/set_plane(new_plane)	//Changes plane
	original_plane = new_plane
	update_plane()

/proc/calculate_plane(z,original_plane)
	if(z <= 0 || z_levels.len < z)
		return

	var/datum/level_data/LD = z_levels[z]

	if(LD != null)
		return min(32767,((z-LD.original_level)*PLANES_PER_Z_LEVEL) + original_plane)

///Updates plane using local z-coordinate.
/atom/proc/update_plane()
	if(z > 0)
		plane = calculate_plane(z,original_plane)
	else if(ismovable(loc) && loc.z > 0)//are we inside something's vis contents or something like that?
		plane = calculate_plane(loc.z,original_plane)
	else//otherwise, just give up
		plane = ABOVE_HUD_PLANE

//IMPORTANT TODO: potential performace liability but inevitable consequence of awful mapping decisions clashing with our
//terrible offset code. Spend 4 hours re-mapping every area in the game to be 1 z only and we can remove this.
/area/update_plane()
	..()
	for(var/turf/ourt in src)
		ourt.plane = set_plane(original_plane)

/atom/proc/get_relative_plane(plane)
	return calculate_plane(z,plane)
