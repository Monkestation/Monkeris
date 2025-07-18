//--------------------------------------------
// Gas filter - omni variant
//--------------------------------------------
/obj/machinery/atmospherics/omni/filter
	name = "omni gas filter"
	icon_state = "map_filter"

	var/list/gas_filters = new()
	var/datum/omni_port/input
	var/datum/omni_port/output

	use_power = IDLE_POWER_USE
	idle_power_usage = 150		//internal circuitry, friction losses and stuff
	power_rating = 7500			//7500 W ~ 10 HP

	var/max_flow_rate = 200
	var/set_flow_rate = 200

	var/list/filtering_outputs = list()	//maps gasids to gas_mixtures

/obj/machinery/atmospherics/omni/filter/New()
	..()
	rebuild_filtering_list()
	for(var/datum/omni_port/P in ports)
		P.air.volume = ATMOS_DEFAULT_VOLUME_FILTER

/obj/machinery/atmospherics/omni/filter/Destroy()
	input = null
	output = null
	gas_filters.Cut()
	. = ..()

/obj/machinery/atmospherics/omni/filter/sort_ports()
	for(var/datum/omni_port/P in ports)
		if(P.update)
			if(output == P)
				output = null
			if(input == P)
				input = null
			if(gas_filters.Find(P))
				gas_filters -= P

			P.air.volume = 200
			switch(P.mode)
				if(ATM_INPUT)
					input = P
				if(ATM_OUTPUT)
					output = P
				if(ATM_O2 to ATM_N2O)
					gas_filters += P

/obj/machinery/atmospherics/omni/filter/error_check()
	if(!input || !output || !gas_filters)
		return 1
	if(gas_filters.len < 1) //requires at least 1 filter ~otherwise why are you using a filter?
		return 1

	return 0

/obj/machinery/atmospherics/omni/filter/Process()
	if(!..())
		return 0

	var/datum/gas_mixture/output_air = output.air	//BYOND doesn't like referencing "output.air.return_pressure()" so we need to make a direct reference
	var/datum/gas_mixture/input_air = input.air		// it's completely happy with them if they're in a loop though i.e. "P.air.return_pressure()"... *shrug*

	//Figure out the amount of moles to transfer
	var/transfer_moles = (set_flow_rate/input_air.volume)*input_air.total_moles

	var/power_draw = -1
	if (transfer_moles > MINIMUM_MOLES_TO_FILTER)
		power_draw = filter_gas_multi(src, filtering_outputs, input_air, output_air, transfer_moles, power_rating)

	if (power_draw >= 0)
		last_power_draw = power_draw
		use_power(power_draw)

		if(input.network)
			input.network.update = 1
		if(output.network)
			output.network.update = 1
		for(var/datum/omni_port/P in gas_filters)
			if(P.network)
				P.network.update = 1

	return 1

/obj/machinery/atmospherics/omni/filter/nano_ui_interact(mob/user, ui_key = "main", datum/nanoui/ui = null, force_open = NANOUI_FOCUS)
	user.set_machine(src)

	var/list/data = nano_ui_data()

	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)

	if (!ui)
		ui = new(user, src, ui_key, "omni_filter.tmpl", "Omni Filter Control", 330, 330)
		ui.set_initial_data(data)

		ui.open()

/obj/machinery/atmospherics/omni/filter/nano_ui_data()
	var/list/data = new()

	data["power"] = use_power
	data["config"] = configuring

	var/portData[0]
	for(var/datum/omni_port/P in ports)
		if(!configuring && P.mode == 0)
			continue

		var/input = 0
		var/output = 0
		var/filter = 1
		var/f_type = null
		switch(P.mode)
			if(ATM_INPUT)
				input = 1
				filter = 0
			if(ATM_OUTPUT)
				output = 1
				filter = 0
			if(ATM_O2 to ATM_N2O)
				f_type = mode_send_switch(P.mode)

		portData[++portData.len] = list("dir" = dir_name(P.dir, capitalize = 1), \
										"input" = input, \
										"output" = output, \
										"filter" = filter, \
										"f_type" = f_type)

	if(portData.len)
		data["ports"] = portData
	if(output)
		data["set_flow_rate"] = round(set_flow_rate*10)		//because nanoui can't handle rounded decimals.
		data["last_flow_rate"] = round(last_flow_rate*10)

	return data

/obj/machinery/atmospherics/omni/filter/proc/mode_send_switch(mode = ATM_NONE)
	switch(mode)
		if(ATM_O2)
			return "Oxygen"
		if(ATM_N2)
			return "Nitrogen"
		if(ATM_CO2)
			return "Carbon Dioxide"
		if(ATM_P)
			return "Plasma" //*cough* Plasma *cough*
		if(ATM_N2O)
			return "Nitrous Oxide"
		else
			return null

/obj/machinery/atmospherics/omni/filter/Topic(href, href_list)
	if(..()) return 1
	switch(href_list["command"])
		if("power")
			if(!configuring)
				use_power = !use_power
			else
				use_power = NO_POWER_USE
			investigate_log("was [use_power ? "enabled" : "disabled"] by [key_name(usr)]", "atmos")
		if("configure")
			configuring = !configuring
			if(configuring)
				use_power = NO_POWER_USE

	//only allows config changes when in configuring mode ~otherwise you'll get weird pressure stuff going on
	if(configuring && !use_power)
		switch(href_list["command"])
			if("set_flow_rate")
				var/new_flow_rate = input(usr, "Enter new flow rate limit (0-[max_flow_rate]L/s)", "Flow Rate Control", set_flow_rate) as num
				set_flow_rate = between(0, new_flow_rate, max_flow_rate)
			if("switch_mode")
				switch_mode(dir_flag(href_list["dir"]), mode_return_switch(href_list["mode"]))
			if("switch_filter")
				var/new_filter = input(usr, "Select filter mode:", "Change filter", href_list["mode"]) in list("None", "Oxygen", "Nitrogen", "Carbon Dioxide", "Plasma", "Nitrous Oxide")
				switch_filter(dir_flag(href_list["dir"]), mode_return_switch(new_filter))
		if(href_list["command"])
			investigate_log("had it's settings modified by [key_name(usr)]", "atmos")

	update_icon()
	SSnano.update_uis(src)
	return

/obj/machinery/atmospherics/omni/filter/proc/mode_return_switch(mode)
	switch(mode)
		if("Oxygen")
			return ATM_O2
		if("Nitrogen")
			return ATM_N2
		if("Carbon Dioxide")
			return ATM_CO2
		if("Plasma")
			return ATM_P
		if("Nitrous Oxide")
			return ATM_N2O
		if("in")
			return ATM_INPUT
		if("out")
			return ATM_OUTPUT
		if("None")
			return ATM_NONE
		else
			return null

/obj/machinery/atmospherics/omni/filter/proc/switch_filter(dir, mode)
	//check they aren't trying to disable the input or output ~this can only happen if they hack the cached tmpl file
	for(var/datum/omni_port/P in ports)
		if(P.dir == dir)
			if(P.mode == ATM_INPUT || P.mode == ATM_OUTPUT)
				return

	switch_mode(dir, mode)

/obj/machinery/atmospherics/omni/filter/proc/switch_mode(port, mode)
	if(mode == null || !port)
		return
	var/datum/omni_port/target_port = null
	var/list/other_ports = new()

	for(var/datum/omni_port/P in ports)
		if(P.dir == port)
			target_port = P
		else
			other_ports += P

	var/previous_mode = null
	if(target_port)
		previous_mode = target_port.mode
		target_port.mode = mode
		if(target_port.mode != previous_mode)
			handle_port_change(target_port)
			rebuild_filtering_list()
		else
			return
	else
		return

	for(var/datum/omni_port/P in other_ports)
		if(P.mode == mode)
			var/old_mode = P.mode
			P.mode = previous_mode
			if(P.mode != old_mode)
				handle_port_change(P)

	update_ports()

/obj/machinery/atmospherics/omni/filter/proc/rebuild_filtering_list()
	filtering_outputs.Cut()
	for(var/datum/omni_port/P in ports)
		var/gasid = mode_to_gasid(P.mode)
		if(gasid)
			filtering_outputs[gasid] = P.air

/obj/machinery/atmospherics/omni/filter/proc/handle_port_change(datum/omni_port/P)
	switch(P.mode)
		if(ATM_NONE)
			initialize_directions &= ~P.dir
			P.disconnect()
		else
			initialize_directions |= P.dir
			P.connect()
	P.update = 1
