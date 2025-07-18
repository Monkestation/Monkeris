/datum/wires/smartfridge
	holder_type = /obj/machinery/smartfridge
	wire_count = 3
	descriptions = list(
		new /datum/wire_description(SMARTFRIDGE_WIRE_ELECTRIFY, "Shock"),
		new /datum/wire_description(SMARTFRIDGE_WIRE_THROW, "Failsafe"),
		new /datum/wire_description(SMARTFRIDGE_WIRE_IDSCAN, "ID scanner")
	)

/datum/wires/smartfridge/secure
	wire_count = 4

var/const/SMARTFRIDGE_WIRE_ELECTRIFY	= 1
var/const/SMARTFRIDGE_WIRE_THROW		= 2
var/const/SMARTFRIDGE_WIRE_IDSCAN		= 4

/datum/wires/smartfridge/CanUse(mob/living/L)
	var/obj/machinery/smartfridge/S = holder
	if(!issilicon(L))
		if(S.seconds_electrified)
			if(S.shock(L, 100))
				return 0
	if(S.panel_open)
		return 1
	return 0

/datum/wires/smartfridge/GetInteractWindow(mob/living/user)
	var/obj/machinery/smartfridge/S = holder
	. += ..(user)
	. += "<BR>The orange light is [S.seconds_electrified ? "off" : "on"].<BR>"
	. += "The red light is [S.shoot_inventory ? "off" : "blinking"].<BR>"
	. += "A [S.scan_id ? "purple" : "yellow"] light is on.<BR>"

/datum/wires/smartfridge/UpdatePulsed(index)
	var/obj/machinery/smartfridge/S = holder
	switch(index)
		if(SMARTFRIDGE_WIRE_THROW)
			S.shoot_inventory = !S.shoot_inventory
		if(SMARTFRIDGE_WIRE_ELECTRIFY)
			S.seconds_electrified = 30
		if(SMARTFRIDGE_WIRE_IDSCAN)
			S.scan_id = !S.scan_id

/datum/wires/smartfridge/UpdateCut(index, mended)
	var/obj/machinery/smartfridge/S = holder
	switch(index)
		if(SMARTFRIDGE_WIRE_THROW)
			S.shoot_inventory = !mended
		if(SMARTFRIDGE_WIRE_ELECTRIFY)
			if(mended)
				S.seconds_electrified = 0
			else
				S.seconds_electrified = -1
		if(SMARTFRIDGE_WIRE_IDSCAN)
			S.scan_id = 1
