/obj/machinery/atmospherics/trinary/mixer
	icon = 'icons/atmos/mixer.dmi'
	icon_state = "map"
	density = FALSE
	level = BELOW_PLATING_LEVEL

	name = "Gas mixer"

	use_power = IDLE_POWER_USE
	idle_power_usage = 150		//internal circuitry, friction losses and stuff
	power_rating = 3700	//This also doubles as a measure of how powerful the mixer is, in Watts. 3700 W ~ 5 HP

	var/set_flow_rate = ATMOS_DEFAULT_VOLUME_MIXER
	var/list/mixing_inputs

	//for mapping
	var/node1_concentration = 0.5
	var/node2_concentration = 0.5

	//node 3 is the outlet, nodes 1 & 2 are intakes

/obj/machinery/atmospherics/trinary/mixer/update_icon(safety = 0)
	if(istype(src, /obj/machinery/atmospherics/trinary/mixer/m_mixer))
		icon_state = "m"
	else if(istype(src, /obj/machinery/atmospherics/trinary/mixer/t_mixer))
		icon_state = "t"
	else
		icon_state = ""

	if(!powered())
		icon_state += "off"
	else if(node2 && node3 && node1)
		icon_state += use_power ? "on" : "off"
	else
		icon_state += "off"
		use_power = NO_POWER_USE

/obj/machinery/atmospherics/trinary/mixer/update_underlays()
	if(..())
		underlays.Cut()
		var/turf/T = get_turf(src)
		if(!istype(T))
			return

		if(istype(src, /obj/machinery/atmospherics/trinary/mixer/t_mixer))
			add_underlay(T, node1, turn(dir, -90))
		else
			add_underlay(T, node1, turn(dir, -180))

		if(istype(src, /obj/machinery/atmospherics/trinary/mixer/m_mixer) || istype(src, /obj/machinery/atmospherics/trinary/mixer/t_mixer))
			add_underlay(T, node2, turn(dir, 90))
		else
			add_underlay(T, node2, turn(dir, -90))

		add_underlay(T, node3, dir)

/obj/machinery/atmospherics/trinary/mixer/hide(i)
	update_underlays()

/obj/machinery/atmospherics/trinary/mixer/power_change()
	var/old_stat = stat
	..()
	if(old_stat != stat)
		update_icon()

/obj/machinery/atmospherics/trinary/mixer/New()
	..()
	air1.volume = ATMOS_DEFAULT_VOLUME_MIXER
	air2.volume = ATMOS_DEFAULT_VOLUME_MIXER
	air3.volume = ATMOS_DEFAULT_VOLUME_MIXER * 1.5

	if (!mixing_inputs)
		mixing_inputs = list(src.air1 = node1_concentration, src.air2 = node2_concentration)

/obj/machinery/atmospherics/trinary/mixer/Process()
	..()

	last_power_draw = 0
	last_flow_rate = 0

	if((stat & (NOPOWER|BROKEN)) || !use_power)
		return

	//Figure out the amount of moles to transfer
	var/transfer_moles = (set_flow_rate*mixing_inputs[air1]/air1.volume)*air1.total_moles + (set_flow_rate*mixing_inputs[air1]/air2.volume)*air2.total_moles

	var/power_draw = -1
	if (transfer_moles > MINIMUM_MOLES_TO_FILTER)
		power_draw = mix_gas(src, mixing_inputs, air3, transfer_moles, power_rating)

		if(network1 && mixing_inputs[air1])
			network1.update = 1

		if(network2 && mixing_inputs[air2])
			network2.update = 1

		if(network3)
			network3.update = 1

	if (power_draw >= 0)
		last_power_draw = power_draw
		use_power(power_draw)

	return 1

/obj/machinery/atmospherics/trinary/mixer/attackby(obj/item/I, mob/user as mob)
	if(!(QUALITY_BOLT_TURNING in I.tool_qualities))
		return ..()
	var/datum/gas_mixture/int_air = return_air()
	var/datum/gas_mixture/env_air = loc.return_air()
	if ((int_air.return_pressure()-env_air.return_pressure()) > 2*ONE_ATMOSPHERE)
		to_chat(user, span_warning("You cannot unwrench \the [src], it too exerted due to internal pressure."))
		add_fingerprint(user)
		return 1
	to_chat(user, span_notice("You begin to unfasten \the [src]..."))
	if(I.use_tool(user, src, WORKTIME_FAST, QUALITY_BOLT_TURNING, FAILCHANCE_EASY, required_stat = STAT_MEC))
		user.visible_message( \
			span_notice("\The [user] unfastens \the [src]."), \
			span_notice("You have unfastened \the [src]."), \
			"You hear ratchet.")
		new /obj/item/pipe(loc, make_from=src)
		qdel(src)

/obj/machinery/atmospherics/trinary/mixer/attack_hand(user as mob)
	if(..())
		return
	src.add_fingerprint(usr)
	if(!src.allowed(user))
		to_chat(user, span_warning("Access denied."))
		return
	usr.set_machine(src)
	var/dat = {"<b>Power: </b><a href='byond://?src=\ref[src];power=1'>[use_power?"On":"Off"]</a><br>
				<b>Set Flow Rate Limit: </b>
				[set_flow_rate]L/s | <a href='byond://?src=\ref[src];set_press=1'>Change</a>
				<br>
				<b>Flow Rate: </b>[round(last_flow_rate, 0.1)]L/s
				<br><hr>
				<b>Node 1 Concentration:</b>
				<a href='byond://?src=\ref[src];node1_c=-0.1'><b>-</b></a>
				<a href='byond://?src=\ref[src];node1_c=-0.01'>-</a>
				[mixing_inputs[air1]]([mixing_inputs[air1]*100]%)
				<a href='byond://?src=\ref[src];node1_c=0.01'><b>+</b></a>
				<a href='byond://?src=\ref[src];node1_c=0.1'>+</a>
				<br>
				<b>Node 2 Concentration:</b>
				<a href='byond://?src=\ref[src];node2_c=-0.1'><b>-</b></a>
				<a href='byond://?src=\ref[src];node2_c=-0.01'>-</a>
				[mixing_inputs[air2]]([mixing_inputs[air2]*100]%)
				<a href='byond://?src=\ref[src];node2_c=0.01'><b>+</b></a>
				<a href='byond://?src=\ref[src];node2_c=0.1'>+</a>
				"}

	user << browse(HTML_SKELETON_TITLE("[src.name] control", "<TT>[dat]</TT>"), "window=atmo_mixer")
	onclose(user, "atmo_mixer")
	return

/obj/machinery/atmospherics/trinary/mixer/Topic(href, href_list)
	if(..()) return 1
	if(href_list["power"])
		use_power = !use_power
	if(href_list["set_press"])
		var/max_flow_rate = min(air1.volume, air2.volume)
		var/new_flow_rate = input(usr, "Enter new flow rate limit (0-[max_flow_rate]L/s)", "Flow Rate Control", src.set_flow_rate) as num
		src.set_flow_rate = max(0, min(max_flow_rate, new_flow_rate))
	if(href_list["node1_c"])
		var/value = text2num(href_list["node1_c"])
		src.mixing_inputs[air1] = max(0, min(1, src.mixing_inputs[air1] + value))
		src.mixing_inputs[air2] = 1 - mixing_inputs[air1]
	if(href_list["node2_c"])
		var/value = text2num(href_list["node2_c"])
		src.mixing_inputs[air2] = max(0, min(1, src.mixing_inputs[air2] + value))
		src.mixing_inputs[air1] = 1 - mixing_inputs[air2]
	src.update_icon()
	src.updateUsrDialog()
	return

/obj/machinery/atmospherics/trinary/mixer/t_mixer
	icon_state = "tmap"

	dir = SOUTH
	initialize_directions = SOUTH|EAST|WEST

	//node 3 is the outlet, nodes 1 & 2 are intakes

/obj/machinery/atmospherics/trinary/mixer/t_mixer/New()
	..()
	switch(dir)
		if(NORTH)
			initialize_directions = EAST|NORTH|WEST
		if(SOUTH)
			initialize_directions = SOUTH|WEST|EAST
		if(EAST)
			initialize_directions = EAST|NORTH|SOUTH
		if(WEST)
			initialize_directions = WEST|NORTH|SOUTH

/obj/machinery/atmospherics/trinary/mixer/t_mixer/atmos_init()
	..()
	if(node1 && node2 && node3) return

	var/node1_connect = turn(dir, -90)
	var/node2_connect = turn(dir, 90)
	var/node3_connect = dir

	for(var/obj/machinery/atmospherics/target in get_step(src, node1_connect))
		if(target.initialize_directions & get_dir(target, src))
			node1 = target
			break

	for(var/obj/machinery/atmospherics/target in get_step(src, node2_connect))
		if(target.initialize_directions & get_dir(target, src))
			node2 = target
			break

	for(var/obj/machinery/atmospherics/target in get_step(src, node3_connect))
		if(target.initialize_directions & get_dir(target, src))
			node3 = target
			break

	update_icon()
	update_underlays()

/obj/machinery/atmospherics/trinary/mixer/m_mixer
	icon_state = "mmap"

	dir = SOUTH
	initialize_directions = SOUTH|NORTH|EAST

	//node 3 is the outlet, nodes 1 & 2 are intakes

/obj/machinery/atmospherics/trinary/mixer/m_mixer/New()
	..()
	switch(dir)
		if(NORTH)
			initialize_directions = WEST|NORTH|SOUTH
		if(SOUTH)
			initialize_directions = SOUTH|EAST|NORTH
		if(EAST)
			initialize_directions = EAST|WEST|NORTH
		if(WEST)
			initialize_directions = WEST|SOUTH|EAST

/obj/machinery/atmospherics/trinary/mixer/m_mixer/atmos_init()
	..()
	if(node1 && node2 && node3) return

	var/node1_connect = turn(dir, -180)
	var/node2_connect = turn(dir, 90)
	var/node3_connect = dir

	for(var/obj/machinery/atmospherics/target in get_step(src, node1_connect))
		if(target.initialize_directions & get_dir(target, src))
			node1 = target
			break

	for(var/obj/machinery/atmospherics/target in get_step(src, node2_connect))
		if(target.initialize_directions & get_dir(target, src))
			node2 = target
			break

	for(var/obj/machinery/atmospherics/target in get_step(src, node3_connect))
		if(target.initialize_directions & get_dir(target, src))
			node3 = target
			break

	update_icon()
	update_underlays()
