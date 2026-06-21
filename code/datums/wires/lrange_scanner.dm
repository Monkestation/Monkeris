#define SCANNER_WIRE_POWER     (1 << 0)        // Cut to disable power input into the scanner. Pulse does nothing. Mend to restore.
#define SCANNER_WIRE_CONTROL   (1 << 2)        // Cut to lock most scanner controls. Mend to unlock them. Pulse does nothing.
#define SCANNER_WIRE_AICONTROL (1 << 3)        // Cut to disable AI control. Mend to restore.
#define SCANNER_WIRE_NOTHING   (1 << 4)        // A blank wire that doesn't have any specific function

/datum/wires/long_range_scanner
	holder_type = /obj/machinery/power/shipside/long_range_scanner/
	wire_count = 5
	descriptions = list(
		new /datum/wire_description(SCANNER_WIRE_POWER, "Power"),
		new /datum/wire_description(SCANNER_WIRE_CONTROL, "Physical access"),
		new /datum/wire_description(SCANNER_WIRE_AICONTROL, "Remote access"),
		new /datum/wire_description(SCANNER_WIRE_NOTHING, "Failsafe")
	)

/datum/wires/long_range_scanner/CanUse()
	var/obj/machinery/power/shipside/long_range_scanner/S = holder
	if(S.panel_open)
		return 1
	return 0

/datum/wires/long_range_scanner/UpdateCut(index, mended)
	var/obj/machinery/power/shipside/long_range_scanner/S = holder
	switch(index)
		if(SCANNER_WIRE_POWER)
			S.input_cut = !mended
		if(SCANNER_WIRE_CONTROL)
			S.mode_changes_locked = !mended
		if(SCANNER_WIRE_AICONTROL)
			S.ai_control_disabled = !mended

/datum/wires/long_range_scanner/UpdatePulsed(index)
	return

#undef SCANNER_WIRE_POWER
#undef SCANNER_WIRE_CONTROL
#undef SCANNER_WIRE_AICONTROL
#undef SCANNER_WIRE_NOTHING
