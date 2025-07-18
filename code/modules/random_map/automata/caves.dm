/datum/random_map/automata/cave_system
	iterations = 5
	descriptor = "moon caves"
	wall_type =  /turf/mineral
	floor_type = /turf/floor/asteroid
	target_turf_type = /turf/mask
	var/mineral_sparse =  /turf/mineral/random
	var/mineral_rich = /turf/mineral/random/high_chance
	var/list/ore_turfs = list()
//	var/mineral_turf = /turf/mineral/random

/datum/random_map/automata/cave_system/get_appropriate_path(value)
	switch(value)
		if(DOOR_CHAR)
			return mineral_sparse
		if(EMPTY_CHAR)
			return mineral_rich
		if(FLOOR_CHAR)
			return floor_type
		if(WALL_CHAR)
			return wall_type

/datum/random_map/automata/cave_system/get_map_char(value)
	switch(value)
		if(DOOR_CHAR)
			return "x"
		if(EMPTY_CHAR)
			return "X"
	return ..(value)

/datum/random_map/automata/cave_system/revive_cell(target_cell, list/use_next_map, final_iter)
	..()
	if(final_iter)
		ore_turfs |= target_cell

/datum/random_map/automata/cave_system/kill_cell(target_cell, list/use_next_map, final_iter)
	..()
	if(final_iter)
		ore_turfs -= target_cell

// Create ore turfs.
/datum/random_map/automata/cave_system/cleanup()
	var/ore_count = round(map.len/20)
	while((ore_count>0) && (ore_turfs.len>0))
		if(!priority_process) sleep(-1)
		var/check_cell = pick(ore_turfs)
		ore_turfs -= check_cell
		if(prob(75))
			map[check_cell] = DOOR_CHAR  // Mineral block
		else
			map[check_cell] = EMPTY_CHAR // Rare mineral block.
		ore_count--
		CHECK_TICK
	return 1
