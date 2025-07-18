// internal pipe, don't actually place or use these
/obj/machinery/atmospherics/pipe/mains_component
	var/obj/machinery/atmospherics/mains_pipe/parent_pipe
	var/list/obj/machinery/atmospherics/pipe/mains_component/nodes = new()

/obj/machinery/atmospherics/pipe/mains_component/New(loc)
	..(loc)
	parent_pipe = loc

/obj/machinery/atmospherics/pipe/mains_component/check_pressure(pressure)
	var/datum/gas_mixture/environment = loc.loc.return_air()

	var/pressure_difference = pressure - environment.return_pressure()

	if(pressure_difference > parent_pipe.maximum_pressure)
		mains_burst()

	else if(pressure_difference > parent_pipe.fatigue_pressure)
		//TODO: leak to turf, doing pfshhhhh
		if(prob(5))
			mains_burst()

	else return 1

/obj/machinery/atmospherics/pipe/mains_component/pipeline_expansion()
	return nodes

/obj/machinery/atmospherics/pipe/mains_component/disconnect(obj/machinery/atmospherics/reference)
	if(nodes.Find(reference))
		nodes.Remove(reference)

/obj/machinery/atmospherics/pipe/mains_component/proc/mains_burst()
	parent_pipe.burst()

/obj/machinery/atmospherics/mains_pipe
	icon = 'icons/obj/atmospherics/mainspipe.dmi'
	layer = 2.4 //under wires with their 2.5

	var/volume = 0

	var/alert_pressure = 80*ONE_ATMOSPHERE

	var/initialize_mains_directions = 0

	var/list/obj/machinery/atmospherics/mains_pipe/nodes = new()
	var/obj/machinery/atmospherics/pipe/mains_component/supply
	var/obj/machinery/atmospherics/pipe/mains_component/scrubbers
	var/obj/machinery/atmospherics/pipe/mains_component/aux

	var/minimum_temperature_difference = 300
	var/thermal_conductivity = 0 //WALL_HEAT_TRANSFER_COEFFICIENT No

	var/maximum_pressure = 70*ONE_ATMOSPHERE
	var/fatigue_pressure = 55*ONE_ATMOSPHERE
	alert_pressure = 55*ONE_ATMOSPHERE

/obj/machinery/atmospherics/mains_pipe/New()
	..()

	supply = new(src)
	supply.volume = volume
	supply.nodes.len = nodes.len
	scrubbers = new(src)
	scrubbers.volume = volume
	scrubbers.nodes.len = nodes.len
	aux = new(src)
	aux.volume = volume
	aux.nodes.len = nodes.len

/obj/machinery/atmospherics/mains_pipe/hide(i)
	if(level == BELOW_PLATING_LEVEL && istype(loc, /turf))
		invisibility = i ? 101 : 0
	update_icon()

/obj/machinery/atmospherics/mains_pipe/proc/burst()
	for(var/obj/machinery/atmospherics/pipe/mains_component/pipe in contents)
		burst()

/obj/machinery/atmospherics/mains_pipe/proc/check_pressure(pressure)
	var/datum/gas_mixture/environment = loc.return_air()

	var/pressure_difference = pressure - environment.return_pressure()

	if(pressure_difference > maximum_pressure)
		burst()

	else if(pressure_difference > fatigue_pressure)
		//TODO: leak to turf, doing pfshhhhh
		if(prob(5))
			burst()

	else return 1

/obj/machinery/atmospherics/mains_pipe/disconnect()
	..()
	for(var/obj/machinery/atmospherics/pipe/mains_component/node in nodes)
		node.disconnect()

/obj/machinery/atmospherics/mains_pipe/Destroy()
	disconnect()
	. = ..()

/obj/machinery/atmospherics/mains_pipe/atmos_init()
	for(var/i = 1 to nodes.len)
		var/obj/machinery/atmospherics/mains_pipe/node = nodes[i]
		if(node)
			supply.nodes[i] = node.supply
			scrubbers.nodes[i] = node.scrubbers
			aux.nodes[i] = node.aux

/obj/machinery/atmospherics/mains_pipe/simple
	name = "mains pipe"
	desc = "A one meter section of 3-line mains pipe"

	dir = SOUTH
	initialize_mains_directions = SOUTH|NORTH

/obj/machinery/atmospherics/mains_pipe/simple/New()
	nodes.len = 2
	..()
	switch(dir)
		if(SOUTH, NORTH)
			initialize_mains_directions = SOUTH|NORTH
		if(EAST, WEST)
			initialize_mains_directions = EAST|WEST
		if(NORTHEAST)
			initialize_mains_directions = NORTH|EAST
		if(NORTHWEST)
			initialize_mains_directions = NORTH|WEST
		if(SOUTHEAST)
			initialize_mains_directions = SOUTH|EAST
		if(SOUTHWEST)
			initialize_mains_directions = SOUTH|WEST

/obj/machinery/atmospherics/mains_pipe/simple/proc/normalize_dir()
	if(dir==3)
		set_dir(1)
	else if(dir==12)
		set_dir(4)

/obj/machinery/atmospherics/mains_pipe/simple/update_icon()
	if(nodes[1] && nodes[2])
		icon_state = "intact[invisibility ? "-f" : "" ]"

		//var/node1_direction = get_dir(src, node1)
		//var/node2_direction = get_dir(src, node2)

		//set_dir(node1_direction|node2_direction)

	else
		if(!nodes[1]&&!nodes[2])
			qdel(src) //TODO: silent deleting looks weird
			log_world("PIPE-DELETE at ([x],[y],[z]). Missed nodes.")
			return
		var/have_node1 = nodes[1]?1:0
		var/have_node2 = nodes[2]?1:0
		icon_state = "exposed[have_node1][have_node2][invisibility ? "-f" : "" ]"

/obj/machinery/atmospherics/mains_pipe/simple/atmos_init()
	normalize_dir()
	var/node1_dir
	var/node2_dir

	for(var/direction in GLOB.cardinal)
		if(direction&initialize_mains_directions)
			if (!node1_dir)
				node1_dir = direction
			else if (!node2_dir)
				node2_dir = direction

	for(var/obj/machinery/atmospherics/mains_pipe/target in get_step(src, node1_dir))
		if(target.initialize_mains_directions & get_dir(target, src))
			nodes[1] = target
			break
	for(var/obj/machinery/atmospherics/mains_pipe/target in get_step(src, node2_dir))
		if(target.initialize_mains_directions & get_dir(target, src))
			nodes[2] = target
			break

	..() // initialize internal pipes

	var/turf/T = src.loc // hide if turf is not intact
	if(level == BELOW_PLATING_LEVEL && !T.is_plating()) hide(1)
	update_icon()

/obj/machinery/atmospherics/mains_pipe/simple/hidden
	level = BELOW_PLATING_LEVEL
	icon_state = "intact-f"

/obj/machinery/atmospherics/mains_pipe/simple/visible
	level = ABOVE_PLATING_LEVEL
	icon_state = "intact"

/obj/machinery/atmospherics/mains_pipe/manifold
	name = "manifold pipe"
	desc = "A manifold composed of mains pipes"

	dir = SOUTH
	initialize_mains_directions = EAST|NORTH|WEST
	volume = 105

/obj/machinery/atmospherics/mains_pipe/manifold/New()
	nodes.len = 3
	..()
	initialize_mains_directions = (NORTH|SOUTH|EAST|WEST) & ~dir

/obj/machinery/atmospherics/mains_pipe/manifold/atmos_init()
	var/connect_directions = initialize_mains_directions

	for(var/direction in GLOB.cardinal)
		if(direction&connect_directions)
			for(var/obj/machinery/atmospherics/mains_pipe/target in get_step(src, direction))
				if(target.initialize_mains_directions & get_dir(target, src))
					nodes[1] = target
					connect_directions &= ~direction
					break
			if (nodes[1])
				break


	for(var/direction in GLOB.cardinal)
		if(direction&connect_directions)
			for(var/obj/machinery/atmospherics/mains_pipe/target in get_step(src, direction))
				if(target.initialize_mains_directions & get_dir(target, src))
					nodes[2] = target
					connect_directions &= ~direction
					break
			if (nodes[2])
				break


	for(var/direction in GLOB.cardinal)
		if(direction&connect_directions)
			for(var/obj/machinery/atmospherics/mains_pipe/target in get_step(src, direction))
				if(target.initialize_mains_directions & get_dir(target, src))
					nodes[3] = target
					connect_directions &= ~direction
					break
			if (nodes[3])
				break

	..() // initialize internal pipes

	var/turf/T = src.loc			// hide if turf is not intact
	if(level == BELOW_PLATING_LEVEL && !T.is_plating()) hide(1)
	update_icon()

/obj/machinery/atmospherics/mains_pipe/manifold/update_icon()
	icon_state = "manifold[invisibility ? "-f" : "" ]"

/obj/machinery/atmospherics/mains_pipe/manifold/hidden
	level = BELOW_PLATING_LEVEL
	icon_state = "manifold-f"

/obj/machinery/atmospherics/mains_pipe/manifold/visible
	level = ABOVE_PLATING_LEVEL
	icon_state = "manifold"

/obj/machinery/atmospherics/mains_pipe/manifold4w
	name = "manifold pipe"
	desc = "A manifold composed of mains pipes"

	dir = SOUTH
	initialize_mains_directions = EAST|NORTH|WEST|SOUTH
	volume = 105

/obj/machinery/atmospherics/mains_pipe/manifold4w/New()
	nodes.len = 4
	..()

/obj/machinery/atmospherics/mains_pipe/manifold4w/atmos_init()
	for(var/obj/machinery/atmospherics/mains_pipe/target in get_step(src, NORTH))
		if(target.initialize_mains_directions & get_dir(target, src))
			nodes[1] = target
			break

	for(var/obj/machinery/atmospherics/mains_pipe/target in get_step(src, SOUTH))
		if(target.initialize_mains_directions & get_dir(target, src))
			nodes[2] = target
			break

	for(var/obj/machinery/atmospherics/mains_pipe/target in get_step(src, EAST))
		if(target.initialize_mains_directions & get_dir(target, src))
			nodes[3] = target
			break

	for(var/obj/machinery/atmospherics/mains_pipe/target in get_step(src, WEST))
		if(target.initialize_mains_directions & get_dir(target, src))
			nodes[3] = target
			break

	..() // initialize internal pipes

	var/turf/T = src.loc			// hide if turf is not intact
	if(level == BELOW_PLATING_LEVEL && !T.is_plating()) hide(1)
	update_icon()

/obj/machinery/atmospherics/mains_pipe/manifold4w/update_icon()
	icon_state = "manifold4w[invisibility ? "-f" : "" ]"

/obj/machinery/atmospherics/mains_pipe/manifold4w/hidden
	level = BELOW_PLATING_LEVEL
	icon_state = "manifold4w-f"

/obj/machinery/atmospherics/mains_pipe/manifold4w/visible
	level = ABOVE_PLATING_LEVEL
	icon_state = "manifold4w"

/obj/machinery/atmospherics/mains_pipe/split
	name = "mains splitter"
	desc = "A splitter for connecting to a single pipe off a mains."

	var/obj/machinery/atmospherics/pipe/mains_component/split_node
	var/obj/machinery/atmospherics/node3
	var/icon_type

/obj/machinery/atmospherics/mains_pipe/split/New()
	nodes.len = 2
	..()
	initialize_mains_directions = turn(dir, 90) | turn(dir, -90)
	initialize_directions = dir // actually have a normal connection too

/obj/machinery/atmospherics/mains_pipe/split/atmos_init()
	var/node1_dir
	var/node2_dir
	var/node3_dir

	node1_dir = turn(dir, 90)
	node2_dir = turn(dir, -90)
	node3_dir = dir

	for(var/obj/machinery/atmospherics/mains_pipe/target in get_step(src, node1_dir))
		if(target.initialize_mains_directions & get_dir(target, src))
			nodes[1] = target
			break
	for(var/obj/machinery/atmospherics/mains_pipe/target in get_step(src, node2_dir))
		if(target.initialize_mains_directions & get_dir(target, src))
			nodes[2] = target
			break
	for(var/obj/machinery/atmospherics/target in get_step(src, node3_dir))
		if(target.initialize_directions & get_dir(target, src))
			node3 = target
			break

	..() // initialize internal pipes

	// bind them
	spawn(5)
		if(node3 && split_node)
			var/datum/pipe_network/N1 = node3.return_network(src)
			var/datum/pipe_network/N2 = split_node.return_network(split_node)
			if(N1 && N2)
				N1.merge(N2)

	var/turf/T = src.loc			// hide if turf is not intact
	if(level == BELOW_PLATING_LEVEL && !T.is_plating()) hide(1)
	update_icon()

/obj/machinery/atmospherics/mains_pipe/split/update_icon()
	icon_state = "split-[icon_type][invisibility ? "-f" : "" ]"

/obj/machinery/atmospherics/mains_pipe/split/return_network(A)
	return split_node.return_network(A)

/obj/machinery/atmospherics/mains_pipe/split/supply
	icon_type = "supply"

/obj/machinery/atmospherics/mains_pipe/split/supply/New()
	..()
	split_node = supply

/obj/machinery/atmospherics/mains_pipe/split/supply/hidden
	level = BELOW_PLATING_LEVEL
	icon_state = "split-supply-f"

/obj/machinery/atmospherics/mains_pipe/split/supply/visible
	level = ABOVE_PLATING_LEVEL
	icon_state = "split-supply"

/obj/machinery/atmospherics/mains_pipe/split/scrubbers
	icon_type = "scrubbers"

/obj/machinery/atmospherics/mains_pipe/split/scrubbers/New()
	..()
	split_node = scrubbers

/obj/machinery/atmospherics/mains_pipe/split/scrubbers/hidden
	level = BELOW_PLATING_LEVEL
	icon_state = "split-scrubbers-f"

/obj/machinery/atmospherics/mains_pipe/split/scrubbers/visible
	level = ABOVE_PLATING_LEVEL
	icon_state = "split-scrubbers"

/obj/machinery/atmospherics/mains_pipe/split/aux
	icon_type = "aux"

/obj/machinery/atmospherics/mains_pipe/split/aux/New()
	..()
	split_node = aux

/obj/machinery/atmospherics/mains_pipe/split/aux/hidden
	level = BELOW_PLATING_LEVEL
	icon_state = "split-aux-f"

/obj/machinery/atmospherics/mains_pipe/split/aux/visible
	level = ABOVE_PLATING_LEVEL
	icon_state = "split-aux"

/obj/machinery/atmospherics/mains_pipe/split3
	name = "triple mains splitter"
	desc = "A splitter for connecting to the 3 pipes on a mainline."

	var/obj/machinery/atmospherics/supply_node
	var/obj/machinery/atmospherics/scrubbers_node
	var/obj/machinery/atmospherics/aux_node

/obj/machinery/atmospherics/mains_pipe/split3/New()
	nodes.len = 1
	..()
	initialize_mains_directions = dir
	initialize_directions = GLOB.cardinal & ~dir // actually have a normal connection too

/obj/machinery/atmospherics/mains_pipe/split3/atmos_init()
	var/node1_dir
	var/supply_node_dir
	var/scrubbers_node_dir
	var/aux_node_dir

	node1_dir = dir
	aux_node_dir = turn(dir, 180)
	if(dir & (NORTH|SOUTH))
		supply_node_dir = EAST
		scrubbers_node_dir = WEST
	else
		supply_node_dir = SOUTH
		scrubbers_node_dir = NORTH

	for(var/obj/machinery/atmospherics/mains_pipe/target in get_step(src, node1_dir))
		if(target.initialize_mains_directions & get_dir(target, src))
			nodes[1] = target
			break
	for(var/obj/machinery/atmospherics/target in get_step(src, supply_node_dir))
		if(target.initialize_directions & get_dir(target, src))
			supply_node = target
			break
	for(var/obj/machinery/atmospherics/target in get_step(src, scrubbers_node_dir))
		if(target.initialize_directions & get_dir(target, src))
			scrubbers_node = target
			break
	for(var/obj/machinery/atmospherics/target in get_step(src, aux_node_dir))
		if(target.initialize_directions & get_dir(target, src))
			aux_node = target
			break

	..() // initialize internal pipes

	// bind them
	spawn(5)
		if(supply_node)
			var/datum/pipe_network/N1 = supply_node.return_network(src)
			var/datum/pipe_network/N2 = supply.return_network(supply)
			if(N1 && N2)
				N1.merge(N2)
		if(scrubbers_node)
			var/datum/pipe_network/N1 = scrubbers_node.return_network(src)
			var/datum/pipe_network/N2 = scrubbers.return_network(scrubbers)
			if(N1 && N2)
				N1.merge(N2)
		if(aux_node)
			var/datum/pipe_network/N1 = aux_node.return_network(src)
			var/datum/pipe_network/N2 = aux.return_network(aux)
			if(N1 && N2)
				N1.merge(N2)

	var/turf/T = src.loc			// hide if turf is not intact
	if(level == BELOW_PLATING_LEVEL && !T.is_plating()) hide(1)
	update_icon()

/obj/machinery/atmospherics/mains_pipe/split3/update_icon()
	icon_state = "split-t[invisibility ? "-f" : "" ]"

/obj/machinery/atmospherics/mains_pipe/split3/return_network(obj/machinery/atmospherics/reference)
	var/obj/machinery/atmospherics/A

	A = supply_node.return_network(reference)
	if(!A)
		A = scrubbers_node.return_network(reference)
	if(!A)
		A = aux_node.return_network(reference)

	return A

/obj/machinery/atmospherics/mains_pipe/split3/hidden
	level = BELOW_PLATING_LEVEL
	icon_state = "split-t-f"

/obj/machinery/atmospherics/mains_pipe/split3/visible
	level = ABOVE_PLATING_LEVEL
	icon_state = "split-t"

/obj/machinery/atmospherics/mains_pipe/cap
	name = "pipe cap"
	desc = "A cap for the end of a mains pipe"

	dir = SOUTH
	initialize_directions = SOUTH
	volume = 35

/obj/machinery/atmospherics/mains_pipe/cap/New()
	nodes.len = 1
	..()
	initialize_mains_directions = dir

/obj/machinery/atmospherics/mains_pipe/cap/update_icon()
	icon_state = "cap[invisibility ? "-f" : ""]"

/obj/machinery/atmospherics/mains_pipe/cap/atmos_init()
	for(var/obj/machinery/atmospherics/mains_pipe/target in get_step(src, dir))
		if(target.initialize_mains_directions & get_dir(target, src))
			nodes[1] = target
			break

	..()

	var/turf/T = src.loc	// hide if turf is not intact
	if(level == BELOW_PLATING_LEVEL && !T.is_plating()) hide(1)
	update_icon()

/obj/machinery/atmospherics/mains_pipe/cap/hidden
	level = BELOW_PLATING_LEVEL
	icon_state = "cap-f"

/obj/machinery/atmospherics/mains_pipe/cap/visible
	level = ABOVE_PLATING_LEVEL
	icon_state = "cap"

//TODO: Get Mains valves working!
/*
/obj/machinery/atmospherics/mains_pipe/valve
	icon_state = "mvalve0"

	name = "mains shutoff valve"
	desc = "A mains pipe valve"

	var/open = 1

	dir = SOUTH
	initialize_mains_directions = SOUTH|NORTH

/obj/machinery/atmospherics/mains_pipe/New()
	nodes.len = 2
	..()
	initialize_mains_directions = dir | turn(dir, 180)

/obj/machinery/atmospherics/mains_pipe/update_icon(animation)
	var/turf/floor = loc
	var/hide = istype(floor) ? floor.intact : 0
	level = BELOW_PLATING_LEVEL
	for(var/obj/machinery/atmospherics/mains_pipe/node in nodes)
		if(node.level == ABOVE_PLATING_LEVEL)
			hide = 0
			level = ABOVE_PLATING_LEVEL
			break

	if(animation)
		flick("[hide?"h":""]mvalve[src.open][!src.open]", src)
	else
		icon_state = "[hide?"h":""]mvalve[open]"

/obj/machinery/atmospherics/mains_pipe/atmos_init()
	normalize_dir()
	var/node1_dir
	var/node2_dir

	for(var/direction in GLOB.cardinal)
		if(direction&initialize_mains_directions)
			if (!node1_dir)
				node1_dir = direction
			else if (!node2_dir)
				node2_dir = direction

	for(var/obj/machinery/atmospherics/mains_pipe/target in get_step(src, node1_dir))
		if(target.initialize_mains_directions & get_dir(target, src))
			nodes[1] = target
			break
	for(var/obj/machinery/atmospherics/mains_pipe/target in get_step(src, node2_dir))
		if(target.initialize_mains_directions & get_dir(target, src))
			nodes[2] = target
			break

	if(open)
		..() // initialize internal pipes

	update_icon()

/obj/machinery/atmospherics/mains_pipe/proc/normalize_dir()
	if(dir==3)
		set_dir(1)
	else if(dir==12)
		set_dir(4)

/obj/machinery/atmospherics/mains_pipe/proc/open()
	if(open) return 0

	open = 1
	update_icon()

	atmos_init()

	return 1

/obj/machinery/atmospherics/mains_pipe/proc/close()
	if(!open) return 0

	open = 0
	update_icon()

	for(var/obj/machinery/atmospherics/pipe/mains_component/node in src)
		for(var/obj/machinery/atmospherics/pipe/mains_component/o in node.nodes)
			o.disconnect(node)
			o.build_network()

	return 1

/obj/machinery/atmospherics/mains_pipe/attack_ai(mob/user as mob)
	return

/obj/machinery/atmospherics/mains_pipe/attack_paw(mob/user as mob)
	return attack_hand(user)

/obj/machinery/atmospherics/mains_pipe/attack_hand(mob/user as mob)
	src.add_fingerprint(usr)
	update_icon(1)
	sleep(10)
	if (open)
		close()
	else
		open()

/obj/machinery/atmospherics/mains_pipe/digital		// can be controlled by AI
	name = "digital mains valve"
	desc = "A digitally controlled valve."
	icon_state = "dvalve0"

	attack_ai(mob/user as mob)
		return src.attack_hand(user)

	attack_hand(mob/user as mob)
		if(!src.allowed(user))
			to_chat(user, span_warning("Access denied."))
			return
		..()

	//Radio remote control
	var/frequency = 0
	var/id = null
	var/datum/radio_frequency/radio_connection

/obj/machinery/atmospherics/mains_pipe/digital/proc/set_frequency(new_frequency)
	radio_controller.remove_object(src, frequency)
	frequency = new_frequency
	if(frequency)
		radio_connection = radio_controller.add_object(src, frequency, RADIO_ATMOSIA)


/obj/machinery/atmospherics/mains_pipe/digital/atmos_init()
	..()
	if(frequency)
		set_frequency(frequency)

/obj/machinery/atmospherics/mains_pipe/digital/update_icon(animation)
	var/turf/floor = loc
	var/hide = istype(floor) ? floor.intact : 0
	level = BELOW_PLATING_LEVEL
	for(var/obj/machinery/atmospherics/mains_pipe/node in nodes)
		if(node.level == ABOVE_PLATING_LEVEL)
			hide = 0
			level = ABOVE_PLATING_LEVEL
			break

	if(animation)
		flick("[hide?"h":""]dvalve[src.open][!src.open]", src)
	else
		icon_state = "[hide?"h":""]dvalve[open]"

/obj/machinery/atmospherics/mains_pipe/digital/receive_signal(datum/signal/signal)
	if(!signal.data["tag"] || (signal.data["tag"] != id))
		return 0

	switch(signal.data["command"])
		if("valve_open")
			if(!open)
				open()

		if("valve_close")
			if(open)
				close()

		if("valve_toggle")
			if(open)
				close()
			else
				open()
*/
