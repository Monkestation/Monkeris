//Solar tracker

//Machine that tracks the sun and reports it's direction to the solar controllers
//As long as this is working, solar panels on same powernet will track automatically

/obj/machinery/power/tracker
	name = "solar tracker"
	desc = "A solar directional tracker."
	icon = 'icons/obj/power.dmi'
	icon_state = "tracker"
	anchored = TRUE
	density = TRUE
	use_power = NO_POWER_USE

	var/id = 0
	var/sun_angle = 0		// sun angle as set by SSsun
	var/obj/machinery/power/solar_control/control = null

/obj/machinery/power/tracker/New(turf/loc, obj/item/solar_assembly/S)
	..(loc)
	Make(S)
	connect_to_network()

/obj/machinery/power/tracker/Destroy()
	unset_control() //remove from control computer
	. = ..()

//set the control of the tracker to a given computer if closer than SOLAR_MAX_DIST
/obj/machinery/power/tracker/proc/set_control(obj/machinery/power/solar_control/SC)
	if(SC && (get_dist(src, SC) > SOLAR_MAX_DIST))
		return 0
	control = SC
	return 1

//set the control of the tracker to null and removes it from the previous control computer if needed
/obj/machinery/power/tracker/proc/unset_control()
	if(control)
		control.connected_tracker = null
	control = null

/obj/machinery/power/tracker/proc/Make(obj/item/solar_assembly/S)
	if(!S)
		S = new /obj/item/solar_assembly(src)
		S.glass_type = /obj/item/stack/material/glass
		S.tracker = 1
		S.anchored = TRUE
	S.loc = src
	update_icon()

//updates the tracker icon and the facing angle for the control computer
/obj/machinery/power/tracker/proc/set_angle(angle)
	sun_angle = angle

	//set icon dir to show sun illumination
	set_dir(turn(NORTH, -angle - 22.5))	// 22.5 deg bias ensures, e.g. 67.5-112.5 is EAST

	if(powernet && (powernet == control.powernet)) //update if we're still in the same powernet
		control.cdir = angle

/obj/machinery/power/tracker/attackby(obj/item/I, mob/user)

	if(QUALITY_PRYING in I.tool_qualities)
		if(I.use_tool(user, src, WORKTIME_NEAR_INSTANT, QUALITY_PRYING, FAILCHANCE_NORMAL, required_stat = STAT_MEC))
			var/obj/item/solar_assembly/S = locate() in src
			if(S)
				S.loc = src.loc
				S.give_glass()
			user.visible_message(span_notice("[user] takes the glass off the tracker."))
			qdel(src)
		return
	..()

// Tracker Electronic

/obj/item/electronics/tracker
	name = "tracker electronics"
	desc = "A board that serves to turn a solar panel into a sun tracker."
	icon = 'icons/obj/doors/door_assembly.dmi'
	icon_state = "door_electronics"
	matter = list(MATERIAL_STEEL = 10, MATERIAL_PLASTIC = 10, MATERIAL_SILVER = 2)
	w_class = ITEM_SIZE_SMALL
	price_tag = 120
