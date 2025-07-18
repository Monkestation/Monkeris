#define APC_WIRE_IDSCAN 1
#define APC_WIRE_MAIN_POWER1 2
#define APC_WIRE_MAIN_POWER2 4
#define APC_WIRE_AI_CONTROL 8

/datum/wires/apc
	holder_type = /obj/machinery/power/apc
	wire_count = 4
	descriptions = list(
		new /datum/wire_description(APC_WIRE_IDSCAN, "ID scanner"),
		new /datum/wire_description(APC_WIRE_MAIN_POWER1, "Main power"),
		new /datum/wire_description(APC_WIRE_MAIN_POWER2, "Backup power"),
		new /datum/wire_description(APC_WIRE_AI_CONTROL, "Remote access")
	)

/datum/wires/apc/GetInteractWindow(mob/living/user)
	var/obj/machinery/power/apc/A = holder
	. += ..(user)
	. += text("<br>\n[(A.locked ? "The APC is locked." : "The APC is unlocked.")]<br>\n[(A.shorted ? "The APCs power has been shorted." : "The APC is working properly!")]<br>\n[(A.aidisabled ? "The 'AI control allowed' light is off." : "The 'AI control allowed' light is on.")]")


/datum/wires/apc/CanUse(mob/living/L)
	var/obj/machinery/power/apc/A = holder
	if(A.wiresexposed)
		return 1
	return 0

/datum/wires/apc/UpdatePulsed(index)

	var/obj/machinery/power/apc/A = holder

	switch(index)

		if(APC_WIRE_IDSCAN)
			A.locked = 0

			spawn(300)
				if(A)
					A.locked = 1

		if (APC_WIRE_MAIN_POWER1, APC_WIRE_MAIN_POWER2)
			if(A.shorted == 0)
				A.shorted = 1

				spawn(1200)
					if(A && !IsIndexCut(APC_WIRE_MAIN_POWER1) && !IsIndexCut(APC_WIRE_MAIN_POWER2))
						A.shorted = 0

		if (APC_WIRE_AI_CONTROL)
			if (A.aidisabled == 0)
				A.aidisabled = 1

				spawn(10)
					if(A && !IsIndexCut(APC_WIRE_AI_CONTROL))
						A.aidisabled = 0

/datum/wires/apc/UpdateCut(index, mended)
	var/obj/machinery/power/apc/A = holder

	switch(index)
		if(APC_WIRE_MAIN_POWER1, APC_WIRE_MAIN_POWER2)

			if(!mended)
				A.shock(usr, 50)
				A.shorted = 1

			else if(!IsIndexCut(APC_WIRE_MAIN_POWER1) && !IsIndexCut(APC_WIRE_MAIN_POWER2))
				A.shorted = 0
				A.shock(usr, 50)

		if(APC_WIRE_AI_CONTROL)

			if(!mended)
				if (A.aidisabled == 0)
					A.aidisabled = 1
			else
				if (A.aidisabled == 1)
					A.aidisabled = 0
