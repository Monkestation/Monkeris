// the underfloor wiring terminal for the APC
// autogenerated when an APC is placed
// all conduit connects go to this object instead of the APC
// using this solves the problem of having the APC in a wall yet also inside an area

/obj/machinery/power/terminal
	name = "terminal"
	icon_state = "term"
	desc = "An underfloor wiring terminal for power equipment."
	level = BELOW_PLATING_LEVEL
	layer = WIRE_TERMINAL_LAYER //a bit above wires
	var/obj/machinery/power/master = null


/obj/machinery/power/terminal/New()
	..()
	var/turf/T = src.loc
	if(level==1 && T) hide(!T.is_plating())
	return

/obj/machinery/power/terminal/Destroy()
	if(master)
		master.disconnect_terminal()
		master = null
	return ..()

/obj/machinery/power/terminal/hide(i)
	invisibility = i ? 101 : initial(invisibility)
	icon_state = i ? "term-f" : "term"

// Needed so terminals are not removed from machines list.
// Powernet rebuilds need this to work properly.
/obj/machinery/power/terminal/Process()
	return 1
