#define EVENT_DAMAGE_PHYSICAL 	0
#define EVENT_DAMAGE_EM 		1
#define EVENT_DAMAGE_HEAT 		2
#define EVENT_DAMAGE_SPECIAL	3
#define EVENT_ENABLED 			4
#define EVENT_DISABLED 			5
#define EVENT_RECONFIGURED		6

/obj/machinery/power/shipside/shield_generator
	name = "advanced shield generator"
	desc = "A heavy-duty shield generator and capacitor, capable of generating energy shields at large distances."
	description_info = "Can be moved by retracting the power conduits with the appropiate right-click verb"
	icon = 'icons/obj/machines/shielding.dmi'
	icon_state = "generator0"
	density = TRUE
	anchored = FALSE

	circuit = /obj/item/electronics/circuitboard/shield_generator

	var/needs_update = FALSE //If true, will update in process

	var/datum/wires/shield_generator/wires
	var/list/field_segments = list()	// List of all shield segments owned by this generator.
	var/list/damaged_segments = list()	// List of shield segments that have failed and are currently regenerating.
	list/event_log = list()				// List of relevant events for this shield
	max_log_entries = 200				// A safety to prevent players generating endless logs and maybe endangering server memory

	var/shield_modes = 0				// Enabled shield mode flags
	var/mitigation_em = 0				// Current EM mitigation
	var/mitigation_physical = 0			// Current Physical mitigation
	var/mitigation_heat = 0				// Current Burn mitigation
	var/mitigation_max = 0				// Maximal mitigation reachable with this generator. Set by RefreshParts()
	var/input_maxcap = 0				// Maximal level of input by the generator. Set by RefreshParts()
	max_energy = 0						// Maximal stored energy. In joules. Depends on the type of used SMES coil when constructing this generator.
	current_energy = 0					// Current stored energy.
	var/field_radius = 200				// Current field radius. //200 is default for hull shield
	running = SHIELD_OFF				// Whether the generator is enabled or not.
	input_cap = 1 MEGAWATTS				// Currently set input limit. Set to 0 to disable limits altogether. The shield will try to input this value per tick at most
	upkeep_power_usage = 0				// Upkeep power usage last tick.
	var/upkeep_multiplier = 1			// Multiplier of upkeep values.
	var/upkeep_star_multiplier = 1      // Multiplier of upkeep values due to proximity with the star at the center of the overmap
	var/upkeep_star_multiplier_max = 4  // Maximum upkeep multiplier when the ship is right on top of the star
	var/upkeep_star_multiplier_safe = 50// Distance from star above which shields are no longer impacted (multiplier = 1)
	power_usage = 0						// Total power usage last tick.
	overloaded = 0						// Whether the field has overloaded and shut down to regenerate.
	offline_for = 0						// The generator will be inoperable for this duration in ticks.
	input_cut = 0						// Whether the input wire is cut.
	mode_changes_locked = 0				// Whether the control wire is cut, locking out changes.
	ai_control_disabled = 0				// Whether the AI control is disabled.
	var/list/mode_list = null			// A list of shield_mode datums.
	emergency_shutdown = FALSE			// Whether the generator is currently recovering from an emergency shutdown
	var/list/default_modes = list()
	var/generatingShield = FALSE //true when shield tiles are in process of being generated

	obj/effect/overmap/ship/linked_ship = null // To access position of Eris on the overmap

	// The shield mode flags which should be enabled on this generator by default

	var/list/allowed_modes = list(MODEFLAG_HYPERKINETIC,
							MODEFLAG_PHOTONIC,
							MODEFLAG_NONHUMANS,
							MODEFLAG_HUMANOIDS,
							MODEFLAG_ANORGANIC,
							MODEFLAG_ATMOSPHERIC,
							MODEFLAG_HULL,
							MODEFLAG_BYPASS,
							MODEFLAG_OVERCHARGE,
							MODEFLAG_MODULATE,
							MODEFLAG_MULTIZ,
							MODEFLAG_EM)
		// The modes that this shield generator can ever use. Override to create less-able subtypes
		// By default, multiz and hull are restricted to the hull generator

	var/report_integrity = FALSE //This shield generator will make announcements about its condition
	//Set this false for any subclasses

	//Reporting variables
	var/last_report_time = 0 //World time of the last time we sent a report
	var/min_report_interval = 120 SECONDS //Time between reports for small damage. This will be ignored for large integrity changes
	var/last_report_integrity = 100
	var/max_report_integrity = 80 //If shield integrity is above this, don't bother reporting
	var/report_delay = 20 SECONDS //We will wait this amount of time after taking a hit before sending a report.
	var/report_scheduled = FALSE //

	list/tendrils = list()
	list/tendril_dirs = list()
	tendrils_deployed = FALSE				// Whether the capacitors are currently extended


/obj/machinery/power/shipside/shield_generator/update_icon()
	overlays.Cut()
	if(running)
		icon_state = "generator1"
		set_light(2, 2, "#8AD55D")
	else
		icon_state = "generator0"
		set_light(0)
	if (tendrils_deployed)
		for (var/D in tendril_dirs)
			var/I = image(icon,"capacitor_connected", dir = D)
			overlays += I

	for (var/obj/machinery/power/conduit/shield_conduit/S in tendrils)
		if (running)
			S.icon_state = "conduit_1"
			S.bright_light()
		else
			S.icon_state = "conduit_0"
			S.no_light()



/obj/machinery/power/shipside/shield_generator/Initialize()
	. = ..()
	wires = new(src)

	//Add all allowed modes to our mode list for users to select
	mode_list = list()
	for(var/st in subtypesof(/datum/shield_mode/))
		var/datum/shield_mode/SM = new st()
		if (locate(SM.mode_flag) in allowed_modes)
			mode_list.Add(SM)

	//Enable all modes in the default modes list
	for (var/DM in default_modes)
		toggle_flag(DM)

	// Link to Eris object on the overmap
	linked_ship = (locate(/obj/effect/overmap/ship/eris) in GLOB.ships)

/obj/machinery/power/shipside/shield_generator/Destroy()
	shutdown_machine()
	field_segments = null
	damaged_segments = null
	mode_list = null
	QDEL_NULL(wires)
	. = ..()


/obj/machinery/power/shipside/shield_generator/RefreshParts()
	max_energy = 0
	input_maxcap = 0
	for(var/obj/machinery/power/conduit/shield_conduit/SC in tendrils)
		for(var/obj/item/stock_parts/smes_coil/S in SC.component_parts)
			max_energy += (S.ChargeCapacity / CELLRATE) / 3					//Divide by 3 because three default conduits
			input_maxcap += S.IOCapacity									//Around 2.25 MEGAWATTS with default parts
	current_energy = between(0, current_energy, max_energy)
	input_cap = between(0, input_cap, input_maxcap)

	mitigation_max = MAX_MITIGATION_BASE
	for(var/obj/item/stock_parts/micro_laser/L in component_parts)          //Mitigation can theoretically reach 100% but only if One Star laser is used (0 energy per hit).
		mitigation_max += MAX_MITIGATION_RESEARCH * L.rating				//It could reach >100% (GAIN charge when hit) if tier 6 laser is used (currently not in game, admemes only)
	mitigation_em = between(0, mitigation_em, mitigation_max)
	mitigation_physical = between(0, mitigation_physical, mitigation_max)
	mitigation_heat = between(0, mitigation_heat, mitigation_max)


// Shuts down the shield, removing all shield segments and unlocking generator settings.
/obj/machinery/power/shipside/shield_generator/shutdown_machine()
	for(var/obj/effect/shield/S in field_segments)
		qdel(S)

	running = SHIELD_OFF
	mitigation_em = 0
	mitigation_physical = 0
	mitigation_heat = 0
	update_icon()

/obj/machinery/power/shipside/shield_generator/spawn_tendrils(dirs = list(NORTH, EAST, WEST))
	for (var/D in dirs)
		var/turf/T = get_step(src, D)
		var/obj/machinery/power/conduit/shield_conduit/tendril = locate(T)
		if(!tendril)
			tendril = new(T)
		tendril.connect(src)
		tendril.face_atom(src)
		tendril.anchored = TRUE
		tendrils_deployed = TRUE
	build_tendril_dirs()
	update_icon()

// Generates the field objects. Deletes existing field, if applicable.
/obj/machinery/power/shipside/shield_generator/proc/regenerate_field()
	needs_update = FALSE
	if (generatingShield)
		return
	generatingShield = TRUE

	if(field_segments.len)
		for(var/obj/effect/shield/S in field_segments)
			qdel(S)
			CHECK_TICK

	// The generator is not turned on, so don't generate any new tiles.
	if(!running)
		generatingShield = FALSE
		return

	var/list/shielded_turfs

	if(check_flag(MODEFLAG_HULL))
		shielded_turfs = fieldtype_hull()
	else
		shielded_turfs = fieldtype_square()

	if(check_flag(MODEFLAG_HULL))
		var/isFloor
		for(var/turf/T in shielded_turfs)
			if (locate(/obj/effect/shield) in T)
				continue
			isFloor = TRUE
			for(var/turf/TN in orange(1, T))
				if (!turf_is_external(TN) || !TN.CanPass(target = TN))
					isFloor = FALSE
					break

			var/obj/effect/shield/S
			if (isFloor)
				S = new/obj/effect/shield/floor(T)
			else
				S = new/obj/effect/shield(T)
			S.gen = src
			S.flags_updated()
			field_segments |= S
			if (T.diffused)
				S.fail(20)
			CHECK_TICK
	else
		for(var/turf/T in shielded_turfs)
			var/obj/effect/shield/S = new(T)
			S.gen = src
			S.flags_updated()
			field_segments |= S
			CHECK_TICK

	update_icon()

	generatingShield = FALSE


// Recalculates and updates the upkeep multiplier
/obj/machinery/power/shipside/shield_generator/proc/update_upkeep_multiplier()
	var/new_upkeep = 1
	for(var/datum/shield_mode/SM in mode_list)
		if(check_flag(SM.mode_flag))
			new_upkeep *= SM.multiplier

	upkeep_multiplier = new_upkeep

// Recalculates and updates the upkeep star multiplier
/obj/machinery/power/shipside/shield_generator/proc/update_upkeep_star_multiplier()
	var/distance = sqrt((linked_ship.x - GLOB.maps_data.overmap_size/2)**2 + (linked_ship.y - GLOB.maps_data.overmap_size/2)**2) // Distance from star
	if(distance>upkeep_star_multiplier_safe) // Above safe distance, no impact on shields
		upkeep_star_multiplier = 1
	else // Otherwise shields are impacted depending on proximity to the star
		upkeep_star_multiplier = 1 + (upkeep_star_multiplier_max - 1) * ((upkeep_star_multiplier_safe - distance) / upkeep_star_multiplier_safe)

/obj/machinery/power/shipside/shield_generator/Process()
	upkeep_power_usage = 0
	power_usage = 0

	if (!anchored)
		return
	if(offline_for)
		offline_for = max(0, offline_for - 1)
		if (offline_for <= 0)
			emergency_shutdown = FALSE

	// We are shutting down, therefore our stored energy disperses faster than usual.
	else if(running == SHIELD_DISCHARGING)
		if (offline_for <= 0)
			shutdown_machine() //We've finished the winding down period and now turn off
			offline_for += 30 //Another minute before it can be turned back on again
		return

	mitigation_em = between(0, mitigation_em - MITIGATION_LOSS_PASSIVE, mitigation_max)
	mitigation_heat = between(0, mitigation_heat - MITIGATION_LOSS_PASSIVE, mitigation_max)
	mitigation_physical = between(0, mitigation_physical - MITIGATION_LOSS_PASSIVE, mitigation_max)

	update_upkeep_star_multiplier() // Update shield upkeep depending on proximity to the star at the center of the overmap

	upkeep_power_usage = round((field_segments.len - damaged_segments.len) * ENERGY_UPKEEP_PER_TILE * upkeep_multiplier * upkeep_star_multiplier)

	if(tendrils_deployed && !input_cut && (running == SHIELD_RUNNING || running == SHIELD_OFF))
		var/energy_buffer = 0
		for(var/obj/machinery/power/conduit/shield_conduit/SC in tendrils)
			energy_buffer += SC.draw_power(input_cap / tendrils.len)
		power_usage += round(energy_buffer)
		current_energy += energy_buffer - upkeep_power_usage //if grid energy is lower than upkeep - negative number will be added
	else
		current_energy -= round(upkeep_power_usage)	// We are shutting down, or we lack external power connection. Use energy from internal source instead.

	if(current_energy <= 0)
		energy_failure()

	if(!overloaded)
		for(var/obj/effect/shield/S in damaged_segments)
			S.regenerate()
	else if (field_integrity() > 5)
		overloaded = 0

	if (needs_update)
		regenerate_field()


/obj/machinery/power/shipside/shield_generator/proc/energy_failure()
	if(running == SHIELD_DISCHARGING)
		shutdown_machine()
	else
		if (current_energy < 0)
			current_energy = 0
		overloaded = 1
		for(var/obj/effect/shield/S in field_segments)
			S.fail(1)


/obj/machinery/power/shipside/shield_generator/nano_ui_interact(mob/user, ui_key = "main", datum/nanoui/ui = null, force_open = NANOUI_FOCUS)
	var/data[0]

	data["running"] = running
	data["modes"] = get_flag_descriptions()
	data["logs"] = get_logs()
	data["overloaded"] = overloaded
	data["mitigation_max"] = mitigation_max
	data["mitigation_physical"] = round(mitigation_physical, 0.1)
	data["mitigation_em"] = round(mitigation_em, 0.1)
	data["mitigation_heat"] = round(mitigation_heat, 0.1)
	data["field_integrity"] = field_integrity()
	data["max_energy"] = round(max_energy / 1000000, 0.1)
	data["current_energy"] = round(current_energy / 1000000, 0.1)
	data["total_segments"] = field_segments ? field_segments.len : 0
	data["functional_segments"] = damaged_segments ? data["total_segments"] - damaged_segments.len : data["total_segments"]
	data["field_radius"] = field_radius
	data["input_cap_kw"] = round(input_cap / 1000)
	data["upkeep_power_usage"] = round(upkeep_power_usage / 1000, 0.1)
	data["power_usage"] = round(power_usage / 1000)
	data["offline_for"] = offline_for * 2
	data["shutdown"] = emergency_shutdown


	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)
		ui = new(user, src, ui_key, "shieldgen.tmpl", src.name, 650, 800)
		ui.set_initial_data(data)
		ui.open()
		ui.set_auto_update(1)


//Sorts the mode list so that currently active ones are at the top
/obj/machinery/power/shipside/shield_generator/proc/sort_modes()
	var/list/temp = list()
	for (var/A in mode_list)
		var/datum/shield_mode/SM = A //This late casting is an optimisation trick

		//Shield modes list contains the flags of active modes
		if (shield_modes & SM.mode_flag)
			//If its in here, then it's active
			mode_list.Remove(SM)

			//We move active ones to the temp list, they will be at the top
			temp.Add(SM)

		//Now we add the rest of the inactive modes onto the end of temp
	temp.Add(mode_list)
	mode_list.Cut() //Clear shield modes, and then transfer the temp list
	mode_list.Add(temp)


/obj/machinery/power/shipside/shield_generator/attack_hand(mob/user)
	nano_ui_interact(user)
	if(panel_open)
		wires.Interact(user)


/obj/machinery/power/shipside/shield_generator/CanUseTopic(mob/user)
	if(issilicon(user) && !Adjacent(user) && ai_control_disabled)
		return STATUS_UPDATE
	return ..()

/obj/machinery/power/shipside/shield_generator/Topic(href, href_list)
	if(..())
		return 1
	if(!anchored)
		return
	//Doesn't respond while disabled
	if(offline_for)
		return

	if(href_list["begin_shutdown"])
		if(running != SHIELD_RUNNING)
			return
		running = SHIELD_DISCHARGING
		offline_for += 30 //It'll take one minute to shut down
		. = 1
		log_event(EVENT_DISABLED, src)

	if(href_list["start_generator"])
		if(tendrils_deployed == FALSE)
			visible_message(span_danger("The [src] buzzes an insistent warning as it needs to have it's conduits deployed first to operate"))
			playsound(src.loc, 'sound/machines/buzz-sigh.ogg', 100, 1, 5)
			return
		running = SHIELD_RUNNING
		regenerate_field()
		log_event(EVENT_ENABLED, src)
		offline_for = 3 //This is to prevent cases where you startup the shield and then turn it off again immediately while spamclicking
		. = 1

	// Instantly drops the shield, but causes a cooldown before it may be started again. Also carries a risk of EMP at high charge.
	if(href_list["emergency_shutdown"])
		if(!running)
			return

		var/choice = input(usr, "Are you sure that you want to initiate an emergency shield shutdown? This will instantly drop the shield, and may result in unstable release of stored electromagnetic energy. Proceed at your own risk.") in list("Yes", "No")
		if((choice != "Yes") || !running)
			return

		var/temp_integrity = field_integrity()

		offline_for += 300 //5 minutes, given that procs happen every 2 seconds
		shutdown_machine()
		emergency_shutdown = TRUE
		log_event(EVENT_DISABLED, src)
		if(prob(temp_integrity - 50) * 1.75)
			spawn()
				empulse(src, 7, 14)
		. = 1

	if(mode_changes_locked || offline_for)
		return 1

	if(href_list["set_range"])
		var/new_range = input(usr, "Enter new field range (1-[world.maxx]). Leave blank to cancel.", "Field Radius Control", field_radius) as num
		if(!new_range)
			return
		field_radius = between(1, new_range, world.maxx)
		regenerate_field()
		log_event(EVENT_RECONFIGURED, src)
		. = 1

	if(href_list["set_input_cap"])
		var/new_cap = round(input(usr, "Enter new input cap (in kW). Current maximal input cap is [input_maxcap / 1000] kW", "Generator Power Control", round(input_cap / 1000)) as num)
		if(!new_cap)
			return
		input_cap = between(1, new_cap, input_maxcap / 1000) * 1000
		log_event(EVENT_RECONFIGURED, src)
		. = 1

	if(href_list["toggle_mode"])

		toggle_flag(text2num(href_list["toggle_mode"]))
		log_event(EVENT_RECONFIGURED, src)
		. = 1

	nano_ui_interact(usr)

/obj/machinery/power/shipside/shield_generator/proc/field_integrity()
	if(max_energy)
		return (current_energy / max_energy) * 100
	return 0


// Takes specific amount of damage
/obj/machinery/power/shipside/shield_generator/proc/take_shield_damage(damage, shield_damtype, atom/damager = null)
	var/energy_to_use = damage * ENERGY_PER_HP

	// Even if the shield isn't currently modulating, it can still use old modulation buildup to reduce damage
	switch(shield_damtype)
		if(SHIELD_DAMTYPE_PHYSICAL)
			energy_to_use *= 1 - (mitigation_physical / 100)
		if(SHIELD_DAMTYPE_EM)
			energy_to_use *= 1 - (mitigation_em / 100)
		if(SHIELD_DAMTYPE_HEAT)
			energy_to_use *= 1 - (mitigation_heat / 100)
		if(SHIELD_DAMTYPE_SPECIAL)
			energy_to_use *= 1 - (mitigation_em / 100)

	mitigation_em -= MITIGATION_HIT_LOSS
	mitigation_heat -= MITIGATION_HIT_LOSS
	mitigation_physical -= MITIGATION_HIT_LOSS

	if(check_flag(MODEFLAG_MODULATE))
		switch(shield_damtype)
			if(SHIELD_DAMTYPE_PHYSICAL)
				mitigation_physical += MITIGATION_HIT_LOSS + MITIGATION_HIT_GAIN
			if(SHIELD_DAMTYPE_EM)
				mitigation_em += MITIGATION_HIT_LOSS + MITIGATION_HIT_GAIN
			if(SHIELD_DAMTYPE_HEAT)
				mitigation_heat += MITIGATION_HIT_LOSS + MITIGATION_HIT_GAIN
			if(SHIELD_DAMTYPE_SPECIAL)
				mitigation_em += MITIGATION_HIT_LOSS + MITIGATION_HIT_GAIN

	mitigation_em = between(0, mitigation_em, mitigation_max)
	mitigation_heat = between(0, mitigation_heat, mitigation_max)
	mitigation_physical = between(0, mitigation_physical, mitigation_max)

	current_energy -= energy_to_use

	switch(shield_damtype)
		if(SHIELD_DAMTYPE_PHYSICAL)
			log_event(EVENT_DAMAGE_PHYSICAL, damager)
		if(SHIELD_DAMTYPE_EM)
			log_event(EVENT_DAMAGE_EM, damager)
		if(SHIELD_DAMTYPE_HEAT)
			log_event(EVENT_DAMAGE_HEAT, damager)
		if(SHIELD_DAMTYPE_SPECIAL)
			log_event(EVENT_DAMAGE_SPECIAL, damager)

	// Overload the shield, which will shut it down until we recharge above 5% again
	if(current_energy < 0)
		energy_failure()
		return SHIELD_BREACHED_FAILURE

	if(prob(10 - field_integrity()))
		return SHIELD_BREACHED_CRITICAL
	if(prob(20 - field_integrity()))
		return SHIELD_BREACHED_MAJOR
	if(prob(35 - field_integrity()))
		return SHIELD_BREACHED_MINOR
	return SHIELD_ABSORBED


// Checks whether specific flags are enabled
/obj/machinery/power/shipside/shield_generator/proc/check_flag(flag)
	return (shield_modes & flag)


/obj/machinery/power/shipside/shield_generator/proc/toggle_flag(flag)
	shield_modes ^= flag
	update_upkeep_multiplier()
	for(var/obj/effect/shield/S in field_segments)
		S.flags_updated()
		CHECK_TICK

	if((flag & (MODEFLAG_HULL|MODEFLAG_MULTIZ)) && running)
		regenerate_field()

	if(flag & MODEFLAG_MODULATE)
		mitigation_em = 0
		mitigation_physical = 0
		mitigation_heat = 0

	sort_modes()


/obj/machinery/power/shipside/shield_generator/proc/get_flag_descriptions()
	var/list/all_flags = list()
	for(var/datum/shield_mode/SM in mode_list)
		all_flags.Add(list(list(
			"name" = SM.mode_name,
			"desc" = SM.mode_desc,
			"flag" = SM.mode_flag,
			"status" = check_flag(SM.mode_flag),
			"multiplier" = SM.multiplier
		)))
	return all_flags

/obj/machinery/power/shipside/shield_generator/proc/get_logs()
	var/list/all_logs = list()
	for(var/i = event_log.len; i > 1; i--)
		all_logs.Add(list(list(
			"entry" = event_log[i]
		)))
	return all_logs

/obj/machinery/power/shipside/shield_generator/proc/fieldtype_square()
	var/list/out = list()
	var/list/base_turfs = get_base_turfs()

	for(var/turf/gen_turf in base_turfs)
		var/turf/T
		for (var/x_offset = -field_radius; x_offset <= field_radius; x_offset++)
			T = locate(gen_turf.x + x_offset, gen_turf.y - field_radius, gen_turf.z)
			if(T)
				out += T
			T = locate(gen_turf.x + x_offset, gen_turf.y + field_radius, gen_turf.z)
			if(T)
				out += T
			CHECK_TICK

		for (var/y_offset = -field_radius+1; y_offset < field_radius; y_offset++)
			T = locate(gen_turf.x - field_radius, gen_turf.y + y_offset, gen_turf.z)
			if(T)
				out += T
			T = locate(gen_turf.x + field_radius, gen_turf.y + y_offset, gen_turf.z)
			if(T)
				out += T
			CHECK_TICK
	return out

/obj/machinery/power/shipside/shield_generator/proc/fieldtype_hull()
	var/list/turf/valid_turfs = list()
	var/list/base_turfs = get_base_turfs()

	for(var/turf/gen_turf in base_turfs)
		for(var/turf/T in RANGE_TURFS(field_radius, gen_turf))
			if(istype(T, /turf/space))
				continue

			for(var/turf/TN in orange(1, T))
				if (turf_is_external(TN))
					valid_turfs |= TN

			CHECK_TICK

	return valid_turfs

// Returns a list of turfs from which a field will propagate. If multi-Z mode is enabled, this will return a "column" of turfs above and below the generator.
/obj/machinery/power/shipside/shield_generator/proc/get_base_turfs()
	var/list/turfs = list()
	var/turf/T = get_turf(src)

	if(!istype(T))
		return

	turfs.Add(T)

	// Multi-Z mode is disabled
	if(!check_flag(MODEFLAG_MULTIZ))
		return turfs

	while(HasAbove(T.z))
		T = GetAbove(T)
		if(istype(T))
			turfs.Add(T)

	T = get_turf(src)

	while(HasBelow(T.z))
		T = GetBelow(T)
		if(istype(T))
			turfs.Add(T)

	return turfs


/obj/machinery/power/shipside/shield_generator/proc/handle_reporting()
	if (report_scheduled)
		return

	report_scheduled = TRUE
	spawn(report_delay)
		report_damage()

//This proc sends reports for shield damage
/obj/machinery/power/shipside/shield_generator/proc/report_damage()
	var/do_report = FALSE //We only report if this is true
	report_scheduled = FALSE //Reset this regardless of what we do here

	if (world.time > (last_report_time + min_report_interval))
		//If its been a while since the last report, another one is fine
		do_report = TRUE

	else if (last_report_integrity - field_integrity() >= 6)
		//If we've taken a lot of damage since the last report, another one is fine too
		do_report = TRUE



	if (!do_report)
		return


	last_report_time = world.time
	last_report_integrity = field_integrity()

	//If integrity is above 80% we won't bother notifying anyone, but we still set the above vars
	if (field_integrity() >= max_report_integrity)
		return

	//Ok now we actually do the report
	var/prefix = ""
	var/spanclass = ""
	if (field_integrity() <= 50)
		prefix = "Warning! "
		spanclass = "notice"
	if (field_integrity() <= 25)
		prefix = "Danger! "
		spanclass = "danger"
	if (field_integrity() <= 15)
		prefix = "--CRITICAL WARNING!-- "
		spanclass = "danger"

	command_announcement.Announce(span(spanclass, "[prefix]Shield integrity at [round(field_integrity())]%"), "Shield Status Report", msg_sanitized = TRUE)



//This proc keeps an internal log of shield impacts, activations, deactivations, and a vague log of config changes
/obj/machinery/power/shipside/shield_generator/log_event(event_type, atom/origin_atom)
	var/logstring = "[stationtime2text()]: "
	switch (event_type)
		if(EVENT_DAMAGE_PHYSICAL to EVENT_DAMAGE_SPECIAL)
			switch (event_type)
				if (EVENT_DAMAGE_PHYSICAL)
					logstring += "Impact registered"
				if (EVENT_DAMAGE_EM)
					logstring += "EM Signature"
				if (EVENT_DAMAGE_HEAT)
					logstring += "Energy discharge"
				if (EVENT_DAMAGE_SPECIAL)
					logstring += "Gravitational wavefronts"
				else
					return


			if (origin_atom)
				var/turf/T = get_turf(origin_atom)
				if(T)
					logstring += " at [T.x],[T.y],[T.z]"
				else
					logstring += " -"

			logstring += " Integrity [round(field_integrity())]%"

		if (EVENT_ENABLED to EVENT_RECONFIGURED)
			switch (event_type)
				if (EVENT_ENABLED)
					logstring += "Shield powered up"
				if (EVENT_DISABLED)
					logstring += "Shield powered down"
				if (EVENT_RECONFIGURED)
					logstring += "Configuration altered"
				else
					return

			if (origin_atom == src)
				logstring += " via Physical Access"
			else
				logstring += " from console at"
				var/area/A = get_area(origin_atom)
				if (A)
					logstring += " [strip_improper(A.name)]"
				else
					logstring += " Unknown Area"

				if (origin_atom)
					logstring += ", [origin_atom.x ? origin_atom.x : "unknown"],[origin_atom.y ? origin_atom.y : "unknown"],[origin_atom.z ? origin_atom.z : "unknown"]"


	if (logstring != "")
		//Insert this string into the log
		event_log.Add(logstring)

		//If we're over the limit, cut the oldest entry
		if (event_log.len > max_log_entries)
			event_log.Cut(1,2)

/obj/machinery/power/conduit/shield_conduit //Most of the stuff is moved to the shipside_machinery.dm
	name = "shield conduit"
	icon = 'icons/obj/machines/shielding.dmi'
	icon_state = "conduit_0"
	desc = "A combined conduit and capacitor that transfers and stores massive amounts of energy."
	density = TRUE
	anchored = FALSE //Will be set true just after deploying
	circuit = /obj/item/electronics/circuitboard/shield_conduit
	var/input_modifier = 0 //Modifier for the power use. Updated by RefreshParts()

/obj/machinery/power/conduit/shield_conduit/no_light()
	set_light(0)

/obj/machinery/power/conduit/shield_conduit/bright_light()
	set_light(2, 2, "#8AD55D")

/obj/machinery/power/conduit/shield_conduit/RefreshParts()
	input_modifier = 0
	for(var/obj/item/stock_parts/capacitor/C in component_parts)
		input_modifier += C.rating / 4
	. = ..()

/obj/machinery/power/conduit/shield_conduit/draw_power(amount) //manual fuckery with the powernet surely won't result in a disaster later on *clueless*
	if(!powernet)
		return 0
	var/draw = between(0, amount, surplus() * input_modifier)
	powernet.load += draw / input_modifier
	return draw

/obj/machinery/power/conduit/disconnect()
	if(!base)
		return FALSE
	if(base.running != 0 && !base.emergency_shutdown)
		base.offline_for += 300
		base.shutdown_machine()
		base.emergency_shutdown = TRUE
		base.log_event(EVENT_DISABLED, base)
	base.tendrils.Remove(src)
	base.build_tendril_dirs()
	base.RefreshParts()
	base.update_icon()
	base = null
	no_light()
	disconnect_from_network()

#undef EVENT_DAMAGE_PHYSICAL
#undef EVENT_DAMAGE_EM
#undef EVENT_DAMAGE_HEAT
#undef EVENT_DAMAGE_SPECIAL
#undef EVENT_ENABLED
#undef EVENT_DISABLED
#undef EVENT_RECONFIGURED
