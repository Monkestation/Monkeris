#define PARTICLE_TOGGLE_WIRE (1 << 0) // Toggles whether the PA is on or not.
#define PARTICLE_STRENGTH_WIRE (1 << 1) // Determines the strength of the PA.
#define PARTICLE_INTERFACE_WIRE (1 << 2) // Determines the interface showing up.
#define PARTICLE_LIMIT_POWER_WIRE (1 << 3) // Determines how strong the PA can be.
// #define PARTICLE_NOTHING_WIRE (1 << 4)  // Blank wire

/datum/wires/particle_acc/control_box
	wire_count = 5
	holder_type = /obj/machinery/particle_accelerator/control_box
	descriptions = list(
		new /datum/wire_description(PARTICLE_TOGGLE_WIRE, "Power"),
		new /datum/wire_description(PARTICLE_STRENGTH_WIRE, "Auxiliary power"),
		new /datum/wire_description(PARTICLE_INTERFACE_WIRE, "Physical access"),
		new /datum/wire_description(PARTICLE_LIMIT_POWER_WIRE, "Failsafe")
	)


/datum/wires/particle_acc/control_box/CanUse(mob/living/L)
	var/obj/machinery/particle_accelerator/control_box/C = holder
	if(C.construction_state == 2)
		return 1
	return 0

/datum/wires/particle_acc/control_box/UpdatePulsed(index)
	var/obj/machinery/particle_accelerator/control_box/C = holder
	switch(index)

		if(PARTICLE_TOGGLE_WIRE)
			C.toggle_power()

		if(PARTICLE_STRENGTH_WIRE)
			C.add_strength()

		if(PARTICLE_INTERFACE_WIRE)
			C.interface_control = !C.interface_control

		if(PARTICLE_LIMIT_POWER_WIRE)
			C.visible_message("[icon2html(C, hearers(C))]<b>[C]</b> makes a large whirring noise.")

/datum/wires/particle_acc/control_box/UpdateCut(index, mended)
	var/obj/machinery/particle_accelerator/control_box/C = holder
	switch(index)

		if(PARTICLE_TOGGLE_WIRE)
			if(C.active == !mended)
				C.toggle_power()

		if(PARTICLE_STRENGTH_WIRE)

			for(var/i = 1; i < 3; i++)
				C.remove_strength()

		if(PARTICLE_INTERFACE_WIRE)
			C.interface_control = mended

		if(PARTICLE_LIMIT_POWER_WIRE)
			C.strength_upper_limit = (mended ? 2 : 3)
			if(C.strength_upper_limit < C.strength)
				C.remove_strength()
