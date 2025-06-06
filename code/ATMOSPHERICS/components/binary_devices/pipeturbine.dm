/obj/machinery/atmospherics/pipeturbine
	name = "turbine"
	desc = "A gas turbine. Converting pressure into energy since 1884."
	icon = 'icons/obj/pipeturbine.dmi'
	icon_state = "turbine"
	anchored = FALSE
	density = TRUE

	var/efficiency = 0.4
	var/kin_energy = 0
	var/datum/gas_mixture/air_in = new
	var/datum/gas_mixture/air_out = new
	var/volume_ratio = 0.2
	var/kin_loss = 0.001

	var/dP = 0

	var/datum/pipe_network/network1
	var/datum/pipe_network/network2

/obj/machinery/atmospherics/pipeturbine/New()
	..()
	air_in.volume = 200
	air_out.volume = 800
	volume_ratio = air_in.volume / (air_in.volume + air_out.volume)
	switch(dir)
		if(NORTH)
			initialize_directions = EAST|WEST
		if(SOUTH)
			initialize_directions = EAST|WEST
		if(EAST)
			initialize_directions = NORTH|SOUTH
		if(WEST)
			initialize_directions = NORTH|SOUTH

/obj/machinery/atmospherics/pipeturbine/Destroy()
	loc = null

	if(node1)
		node1.disconnect(src)
		qdel(network1)
	if(node2)
		node2.disconnect(src)
		qdel(network2)

	node1 = null
	node2 = null

	. = ..()

/obj/machinery/atmospherics/pipeturbine/Process()
	..()
	if(anchored && !(stat&BROKEN))
		kin_energy *= 1 - kin_loss
		dP = max(air_in.return_pressure() - air_out.return_pressure(), 0)
		if(dP > 10)
			kin_energy += 1/ADIABATIC_EXPONENT * dP * air_in.volume * (1 - volume_ratio**ADIABATIC_EXPONENT) * efficiency
			air_in.temperature *= volume_ratio**ADIABATIC_EXPONENT

			var/datum/gas_mixture/air_all = new
			air_all.volume = air_in.volume + air_out.volume
			air_all.merge(air_in.remove_ratio(1))
			air_all.merge(air_out.remove_ratio(1))

			air_in.merge(air_all.remove(volume_ratio))
			air_out.merge(air_all)

		update_icon()

	if (network1)
		network1.update = 1
	if (network2)
		network2.update = 1

/obj/machinery/atmospherics/pipeturbine/update_icon()
	overlays.Cut()
	if (dP > 10)
		overlays += image('icons/obj/pipeturbine.dmi', "moto-turb")
	if (kin_energy > 100000)
		overlays += image('icons/obj/pipeturbine.dmi', "low-turb")
	if (kin_energy > 500000)
		overlays += image('icons/obj/pipeturbine.dmi', "med-turb")
	if (kin_energy > 1000000)
		overlays += image('icons/obj/pipeturbine.dmi', "hi-turb")

/obj/machinery/atmospherics/pipeturbine/attackby(obj/item/tool/W as obj, mob/user as mob)
	if(!W.use_tool(user, src, WORKTIME_NEAR_INSTANT, QUALITY_BOLT_TURNING, FAILCHANCE_ZERO, required_stat = STAT_MEC))
		return ..()
	anchored = !anchored
	to_chat(user, span_notice("You [anchored ? "secure" : "unsecure"] the bolts holding \the [src] to the floor."))

	if(anchored)
		if(dir & (NORTH|SOUTH))
			initialize_directions = EAST|WEST
		else if(dir & (EAST|WEST))
			initialize_directions = NORTH|SOUTH
			atmos_init()
		build_network()
		if (node1)
			node1.atmos_init()
			node1.build_network()
		if (node2)
			node2.atmos_init()
			node2.build_network()
	else
		if(node1)
			node1.disconnect(src)
			qdel(network1)
		if(node2)
			node2.disconnect(src)
			qdel(network2)
			node1 = null
		node2 = null

/obj/machinery/atmospherics/pipeturbine/verb/rotate_clockwise()
	set category = "Object"
	set name = "Rotate Circulator (Clockwise)"
	set src in view(1)

	if (usr.stat || usr.restrained() || anchored)
		return

	src.set_dir(turn(src.dir, -90))


/obj/machinery/atmospherics/pipeturbine/verb/rotate_anticlockwise()
	set category = "Object"
	set name = "Rotate Circulator (Counterclockwise)"
	set src in view(1)

	if (usr.stat || usr.restrained() || anchored)
		return

	src.set_dir(turn(src.dir, 90))

//Goddamn copypaste from binary base class because atmospherics machinery API is not damn flexible
/obj/machinery/atmospherics/pipeturbine/network_expand(datum/pipe_network/new_network, obj/machinery/atmospherics/pipe/reference)
	if(reference == node1)
		network1 = new_network

	else if(reference == node2)
		network2 = new_network

	if(new_network.normal_members.Find(src))
		return 0

	new_network.normal_members += src

	return null

/obj/machinery/atmospherics/pipeturbine/atmos_init()
	if(node1 && node2) return

	var/node2_connect = turn(dir, -90)
	var/node1_connect = turn(dir, 90)

	for(var/obj/machinery/atmospherics/target in get_step(src, node1_connect))
		if(target.initialize_directions & get_dir(target, src))
			node1 = target
			break

	for(var/obj/machinery/atmospherics/target in get_step(src, node2_connect))
		if(target.initialize_directions & get_dir(target, src))
			node2 = target
			break

/obj/machinery/atmospherics/pipeturbine/build_network()
	if(!network1 && node1)
		network1 = new /datum/pipe_network()
		network1.normal_members += src
		network1.build_network(node1, src)

	if(!network2 && node2)
		network2 = new /datum/pipe_network()
		network2.normal_members += src
		network2.build_network(node2, src)


/obj/machinery/atmospherics/pipeturbine/return_network(obj/machinery/atmospherics/reference)
	build_network()

	if(reference==node1)
		return network1

	if(reference==node2)
		return network2

	return null

/obj/machinery/atmospherics/pipeturbine/reassign_network(datum/pipe_network/old_network, datum/pipe_network/new_network)
	if(network1 == old_network)
		network1 = new_network
	if(network2 == old_network)
		network2 = new_network

	return 1

/obj/machinery/atmospherics/pipeturbine/return_network_air(datum/pipe_network/reference)
	var/list/results = list()

	if(network1 == reference)
		results += air_in
	if(network2 == reference)
		results += air_out

	return results

/obj/machinery/atmospherics/pipeturbine/disconnect(obj/machinery/atmospherics/reference)
	if(reference==node1)
		qdel(network1)
		node1 = null

	else if(reference==node2)
		qdel(network2)
		node2 = null

	return null


/obj/machinery/power/turbinemotor
	name = "motor"
	desc = "Electrogenerator. Converts rotation into power."
	icon = 'icons/obj/pipeturbine.dmi'
	icon_state = "motor"
	anchored = FALSE
	density = TRUE

	var/kin_to_el_ratio = 0.1	//How much kinetic energy will be taken from turbine and converted into electricity
	var/obj/machinery/atmospherics/pipeturbine/turbine

/obj/machinery/power/turbinemotor/New()
	..()
	spawn(1)
		updateConnection()

/obj/machinery/power/turbinemotor/proc/updateConnection()
	turbine = null
	if(src.loc && anchored)
		turbine = locate(/obj/machinery/atmospherics/pipeturbine) in get_step(src, dir)
		if (turbine.stat & (BROKEN) || !turbine.anchored || turn(turbine.dir, 180) != dir)
			turbine = null

/obj/machinery/power/turbinemotor/Process()
	updateConnection()
	if(!turbine || !anchored || stat & (BROKEN))
		return

	var/power_generated = kin_to_el_ratio * turbine.kin_energy
	turbine.kin_energy -= power_generated
	add_avail(power_generated)


/obj/machinery/power/turbinemotor/attackby(obj/item/tool/W as obj, mob/user as mob)
	if (!W.use_tool(user, src, WORKTIME_NEAR_INSTANT, QUALITY_BOLT_TURNING, FAILCHANCE_ZERO, required_stat = STAT_MEC))
		return ..()
	anchored = !anchored
	turbine = null
	to_chat(user, span_notice("You [anchored ? "secure" : "unsecure"] the bolts holding \the [src] to the floor."))
	updateConnection()

/obj/machinery/power/turbinemotor/verb/rotate_clock()
	set category = "Object"
	set name = "Rotate Motor Clockwise"
	set src in view(1)

	if (usr.stat || usr.restrained()  || anchored)
		return

	src.set_dir(turn(src.dir, -90))

/obj/machinery/power/turbinemotor/verb/rotate_anticlock()
	set category = "Object"
	set name = "Rotate Motor Counterclockwise"
	set src in view(1)

	if (usr.stat || usr.restrained()  || anchored)
		return

	src.set_dir(turn(src.dir, 90))
