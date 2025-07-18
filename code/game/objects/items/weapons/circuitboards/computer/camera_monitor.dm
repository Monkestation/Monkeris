#ifndef T_BOARD
#error T_BOARD macro is not defined but we need it!
#endif

/obj/item/electronics/circuitboard/security
	name = T_BOARD("security camera monitor")
	build_path = /obj/machinery/computer/security
	req_access = list(access_security)
	var/list/network
	var/locked = 1
	var/emagged = 0

/obj/item/electronics/circuitboard/security/New()
	..()
	network = station_networks

/obj/item/electronics/circuitboard/security/engineering
	name = T_BOARD("engineering camera monitor")
	build_path = /obj/machinery/computer/security/engineering
	req_access = list()

/obj/item/electronics/circuitboard/security/engineering/New()
	..()
	network = engineering_networks

/obj/item/electronics/circuitboard/security/mining
	name = T_BOARD("mining camera monitor")
	build_path = /obj/machinery/computer/security/mining
	network = list("MINE")
	req_access = list()

/obj/item/electronics/circuitboard/security/construct(obj/machinery/computer/security/C)
	if (..(C))
		C.network = network.Copy()

/obj/item/electronics/circuitboard/security/deconstruct(obj/machinery/computer/security/C)
	if (..(C))
		network = C.network.Copy()

/obj/item/electronics/circuitboard/security/emag_act(remaining_charges, mob/user)
	if(emagged)
		user << "Circuit lock is already removed."
		return
	user << span_notice("You override the circuit lock and open controls.")
	emagged = 1
	locked = 0
	return 1

/obj/item/electronics/circuitboard/security/attackby(obj/item/I as obj, mob/user as mob)
	if(istype(I,/obj/item/card/id))
		if(emagged)
			user << span_warning("Circuit lock does not respond.")
			return
		if(check_access(I))
			locked = !locked
			user << span_notice("You [locked ? "" : "un"]lock the circuit controls.")
		else
			user << span_warning("Access denied.")
	else if(istype(I,/obj/item/tool/multitool))
		if(locked)
			user << span_warning("Circuit controls are locked.")
			return
		var/existing_networks = jointext(network,",")
		var/input = sanitize(input(usr, "Which networks would you like to connect this camera console circuit to? Seperate networks with a comma. No Spaces!\nFor example: SS13,Security,Secret ", "Multitool-Circuitboard interface", existing_networks))
		if(!input)
			usr << "No input found please hang up and try your call again."
			return
		var/list/tempnetwork = splittext(input, ",")
		tempnetwork = difflist(tempnetwork,restricted_camera_networks,1)
		if(tempnetwork.len < 1)
			usr << "No network found please hang up and try your call again."
			return
		network = tempnetwork
	return
