#define SHIELDGEN_WIRE_POWER 	 (1 << 0)	// Cut to disable power input into the generator. Pulse does nothing. Mend to restore.
#define SHIELDGEN_WIRE_CONTROL 	 (1 << 1)	// Cut to lock most shield controls. Mend to unlock them. Pulse does nothing.
#define SHIELDGEN_WIRE_AICONTROL (1 << 3)	// Cut to disable AI control. Mend to restore.
#define SHIELDGEN_WIRE_NOTHING 	 (1 << 4)	// A blank wire that doesn't have any specific function

/datum/wires/shield_generator
	holder_type = /obj/machinery/power/shipside/shield_generator/
	wire_count = 5
	descriptions = list(
		new /datum/wire_description(SHIELDGEN_WIRE_POWER, "Main power"),
		new /datum/wire_description(SHIELDGEN_WIRE_CONTROL, "Physical access"),
		new /datum/wire_description(SHIELDGEN_WIRE_AICONTROL, "Remote access")
	)


/datum/wires/shield_generator/CanUse()
	var/obj/machinery/power/shipside/shield_generator/S = holder
	if(S.panel_open)
		return 1
	return 0

/datum/wires/shield_generator/UpdateCut(index, mended)
	var/obj/machinery/power/shipside/shield_generator/S = holder
	switch(index)
		if(SHIELDGEN_WIRE_POWER)
			S.input_cut = !mended
		if(SHIELDGEN_WIRE_CONTROL)
			S.mode_changes_locked = !mended
		if(SHIELDGEN_WIRE_AICONTROL)
			S.ai_control_disabled = !mended

/datum/wires/shield_generator/UpdatePulsed(index)
	return
