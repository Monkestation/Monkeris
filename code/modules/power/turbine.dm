/obj/machinery/compressor
	name = "compressor"
	desc = "The compressor stage of a gas turbine generator."
	icon = 'icons/obj/pipes.dmi'
	icon_state = "compressor"
	anchored = TRUE
	density = TRUE
	var/obj/machinery/power/turbine/turbine
	var/datum/gas_mixture/gas_contained
	var/turf/inturf
	var/starter = 0
	var/rpm = 0
	var/rpmtarget = 0
	var/capacity = 1e6
	var/comp_id = 0

/obj/machinery/power/turbine
	name = "gas turbine generator"
	desc = "A gas turbine used for backup power generation."
	icon = 'icons/obj/pipes.dmi'
	icon_state = "turbine"
	anchored = TRUE
	density = TRUE
	var/obj/machinery/compressor/compressor
	var/turf/outturf
	var/lastgen

/obj/machinery/computer/turbine_computer
	name = "Gas turbine control computer"
	desc = "A computer to remotely control a gas turbine"
	icon = 'icons/obj/computer.dmi'
	icon_keyboard = "tech_key"
	icon_screen = "turbinecomp"
	circuit = /obj/item/electronics/circuitboard/turbine_control
	anchored = TRUE
	density = TRUE
	var/obj/machinery/compressor/compressor
	var/list/obj/machinery/door/blast/doors
	var/id = 0
	var/door_status = 0

// the inlet stage of the gas turbine electricity generator

/obj/machinery/compressor/New()
	..()

	gas_contained = new
	inturf = get_step(src, dir)

	spawn(5)
		turbine = locate() in get_step(src, get_dir(inturf, src))
		if(!turbine)
			stat |= BROKEN
		else
			turbine.stat &= !BROKEN
			turbine.compressor = src


#define COMPFRICTION 5e5
#define COMPSTARTERLOAD 2800

/obj/machinery/compressor/Process()
	if(!starter)
		return
	overlays.Cut()
	if(stat & BROKEN)
		return
	if(!turbine)
		stat |= BROKEN
		return
	rpm = 0.9* rpm + 0.1 * rpmtarget
	var/datum/gas_mixture/environment = inturf.return_air()
	var/transfer_moles = environment.total_moles / 10
	//var/transfer_moles = rpm/10000*capacity
	var/datum/gas_mixture/removed = inturf.remove_air(transfer_moles)
	gas_contained.merge(removed)

	rpm = max(0, rpm - (rpm*rpm)/COMPFRICTION)


	if(starter && !(stat & NOPOWER))
		use_power(2800)
		if(rpm<1000)
			rpmtarget = 1000
	else
		if(rpm<1000)
			rpmtarget = 0



	if(rpm>50000)
		overlays += image('icons/obj/pipes.dmi', "comp-o4", FLY_LAYER)
	else if(rpm>10000)
		overlays += image('icons/obj/pipes.dmi', "comp-o3", FLY_LAYER)
	else if(rpm>2000)
		overlays += image('icons/obj/pipes.dmi', "comp-o2", FLY_LAYER)
	else if(rpm>500)
		overlays += image('icons/obj/pipes.dmi', "comp-o1", FLY_LAYER)
	 //TODO: DEFERRED

/obj/machinery/power/turbine/New()
	..()

	outturf = get_step(src, dir)

	spawn(5)

		compressor = locate() in get_step(src, get_dir(outturf, src))
		if(!compressor)
			stat |= BROKEN
		else
			compressor.stat &= !BROKEN
			compressor.turbine = src


#define TURBPRES 9000000
#define TURBGENQ 20000
#define TURBGENG 0.8

/obj/machinery/power/turbine/Process()
	if(!compressor.starter)
		return
	overlays.Cut()
	if(stat & BROKEN)
		return
	if(!compressor)
		stat |= BROKEN
		return
	lastgen = ((compressor.rpm / TURBGENQ)**TURBGENG) *TURBGENQ

	add_avail(lastgen)
	var/newrpm = ((compressor.gas_contained.temperature) * compressor.gas_contained.total_moles)/4
	newrpm = max(0, newrpm)

	if(!compressor.starter || newrpm > 1000)
		compressor.rpmtarget = newrpm

	if(compressor.gas_contained.total_moles>0)
		var/oamount = min(compressor.gas_contained.total_moles, (compressor.rpm+100)/35000*compressor.capacity)
		var/datum/gas_mixture/removed = compressor.gas_contained.remove(oamount)
		outturf.assume_air(removed)

	if(lastgen > 100)
		overlays += image('icons/obj/pipes.dmi', "turb-o", FLY_LAYER)


	for(var/mob/M in viewers(1, src))
		if ((M.client && M.machine == src))
			src.interact(M)
	AutoUpdateAI(src)

/obj/machinery/power/turbine/interact(mob/user)

	if ( (get_dist(src, user) > 1 ) || (stat & (NOPOWER|BROKEN)) && (!isAI(user)) )
		user.machine = null
		user << browse(null, "window=turbine")
		return

	user.machine = src

	var/t = "<TT><B>Gas Turbine Generator</B><HR><PRE>"

	t += "Generated power : [round(lastgen)] W<BR><BR>"

	t += "Turbine: [round(compressor.rpm)] RPM<BR>"

	t += "Starter: [ compressor.starter ? "<A href='byond://?src=\ref[src];str=1'>Off</A> <B>On</B>" : "<B>Off</B> <A href='byond://?src=\ref[src];str=1'>On</A>"]"

	t += "</PRE><HR><A href='byond://?src=\ref[src];close=1'>Close</A>"

	t += "</TT>"
	user << browse(HTML_SKELETON_TITLE("Gas Turbine Generator", t), "window=turbine")
	onclose(user, "turbine")

	return

/obj/machinery/power/turbine/Topic(href, href_list)
	..()
	if(stat & BROKEN)
		return
	if(usr.stat || usr.restrained() )
		return
	if(!usr.IsAdvancedToolUser())
		return
	if(get_dist(src, usr) <= 1 || isAI(usr))
		if( href_list["close"] )
			usr << browse(null, "window=turbine")
			usr.machine = null
			return

		else if( href_list["str"] )
			compressor.starter = !compressor.starter

		spawn(0)
			for(var/mob/M in viewers(1, src))
				if ((M.client && M.machine == src))
					src.interact(M)

	else
		usr << browse(null, "window=turbine")
		usr.machine = null

	return





/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



/obj/machinery/computer/turbine_computer/New()
	..()
	spawn(5)
		for(var/obj/machinery/compressor/C in GLOB.machines)
			if(id == C.comp_id)
				compressor = C
		doors = new /list()
		for(var/obj/machinery/door/blast/P in GLOB.all_doors)
			if(P.id == id)
				doors += P


/obj/machinery/computer/turbine_computer/attack_hand(mob/user as mob)
	user.machine = src
	var/dat
	if(src.compressor)
		dat += {"<BR><B>Gas turbine remote control system</B><HR>
		\nTurbine status: [ src.compressor.starter ? "<A href='byond://?src=\ref[src];str=1'>Off</A> <B>On</B>" : "<B>Off</B> <A href='byond://?src=\ref[src];str=1'>On</A>"]
		\n<BR>
		\nTurbine speed: [src.compressor.rpm]rpm<BR>
		\nPower currently being generated: [src.compressor.turbine.lastgen]W<BR>
		\nInternal gas temperature: [src.compressor.gas_contained.temperature]K<BR>
		\nVent doors: [ src.door_status ? "<A href='byond://?src=\ref[src];doors=1'>Closed</A> <B>Open</B>" : "<B>Closed</B> <A href='byond://?src=\ref[src];doors=1'>Open</A>"]
		\n</PRE><HR><A href='byond://?src=\ref[src];view=1'>View</A>
		\n</PRE><HR><A href='byond://?src=\ref[src];close=1'>Close</A>
		\n<BR>
		\n"}
	else
		dat += span_danger("No compatible attached compressor found.")

	user << browse(HTML_SKELETON(dat), "window=computer;size=400x500")
	onclose(user, "computer")
	return



/obj/machinery/computer/turbine_computer/Topic(href, href_list)
	if(..())
		return 1

	usr.machine = src

	if( href_list["view"] )
		usr.client.eye = src.compressor
	else if( href_list["str"] )
		src.compressor.starter = !src.compressor.starter
	else if (href_list["doors"])
		for(var/obj/machinery/door/blast/D in src.doors)
			if (door_status == 0)
				spawn( 0 )
					D.open()
					door_status = 1
			else
				spawn( 0 )
					D.close()
					door_status = 0
	else if( href_list["close"] )
		usr << browse(null, "window=computer")
		usr.machine = null
		return

	src.updateUsrDialog()

/obj/machinery/computer/turbine_computer/Process()
	src.updateDialog()
	return
