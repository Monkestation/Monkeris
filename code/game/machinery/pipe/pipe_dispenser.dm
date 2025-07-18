/obj/machinery/pipedispenser
	name = "Pipe Dispenser"
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "pipe_d"
	density = TRUE
	anchored = TRUE
	var/wait = 0

/obj/machinery/pipedispenser/attack_hand(user as mob)
	if(..())
		return
///// Z-Level stuff
	var/dat = {"
<b>Regular pipes:</b><BR>
<A href='byond://?src=\ref[src];make=0;dir=1'>Pipe</A><BR>
<A href='byond://?src=\ref[src];make=1;dir=5'>Bent Pipe</A><BR>
<A href='byond://?src=\ref[src];make=5;dir=1'>Manifold</A><BR>
<A href='byond://?src=\ref[src];make=8;dir=1'>Manual Valve</A><BR>
<A href='byond://?src=\ref[src];make=20;dir=1'>Pipe Cap</A><BR>
<A href='byond://?src=\ref[src];make=19;dir=1'>4-Way Manifold</A><BR>
<A href='byond://?src=\ref[src];make=18;dir=1'>Manual T-Valve</A><BR>
<A href='byond://?src=\ref[src];make=43;dir=1'>Manual T-Valve - Mirrored</A><BR>
<A href='byond://?src=\ref[src];make=21;dir=1'>Upward Pipe</A><BR>
<A href='byond://?src=\ref[src];make=22;dir=1'>Downward Pipe</A><BR>
<b>Supply pipes:</b><BR>
<A href='byond://?src=\ref[src];make=29;dir=1'>Pipe</A><BR>
<A href='byond://?src=\ref[src];make=30;dir=5'>Bent Pipe</A><BR>
<A href='byond://?src=\ref[src];make=33;dir=1'>Manifold</A><BR>
<A href='byond://?src=\ref[src];make=41;dir=1'>Pipe Cap</A><BR>
<A href='byond://?src=\ref[src];make=35;dir=1'>4-Way Manifold</A><BR>
<A href='byond://?src=\ref[src];make=37;dir=1'>Upward Pipe</A><BR>
<A href='byond://?src=\ref[src];make=39;dir=1'>Downward Pipe</A><BR>
<b>Scrubbers pipes:</b><BR>
<A href='byond://?src=\ref[src];make=31;dir=1'>Pipe</A><BR>
<A href='byond://?src=\ref[src];make=32;dir=5'>Bent Pipe</A><BR>
<A href='byond://?src=\ref[src];make=34;dir=1'>Manifold</A><BR>
<A href='byond://?src=\ref[src];make=42;dir=1'>Pipe Cap</A><BR>
<A href='byond://?src=\ref[src];make=36;dir=1'>4-Way Manifold</A><BR>
<A href='byond://?src=\ref[src];make=38;dir=1'>Upward Pipe</A><BR>
<A href='byond://?src=\ref[src];make=40;dir=1'>Downward Pipe</A><BR>
<b>Devices:</b><BR>
<A href='byond://?src=\ref[src];make=28;dir=1'>Universal pipe adapter</A><BR>
<A href='byond://?src=\ref[src];make=4;dir=1'>Connector</A><BR>
<A href='byond://?src=\ref[src];make=7;dir=1'>Unary Vent</A><BR>
<A href='byond://?src=\ref[src];make=9;dir=1'>Gas Pump</A><BR>
<A href='byond://?src=\ref[src];make=15;dir=1'>Pressure Regulator</A><BR>
<A href='byond://?src=\ref[src];make=16;dir=1'>High Power Gas Pump</A><BR>
<A href='byond://?src=\ref[src];make=10;dir=1'>Scrubber</A><BR>
<A href='byond://?src=\ref[src];makemeter=1'>Meter</A><BR>
<A href='byond://?src=\ref[src];make=13;dir=1'>Gas Filter</A><BR>
<A href='byond://?src=\ref[src];make=23;dir=1'>Gas Filter - Mirrored</A><BR>
<A href='byond://?src=\ref[src];make=14;dir=1'>Gas Mixer</A><BR>
<A href='byond://?src=\ref[src];make=25;dir=1'>Gas Mixer - Mirrored</A><BR>
<A href='byond://?src=\ref[src];make=24;dir=1'>Gas Mixer - T</A><BR>
<A href='byond://?src=\ref[src];make=26;dir=1'>Omni Gas Mixer</A><BR>
<A href='byond://?src=\ref[src];make=27;dir=1'>Omni Gas Filter</A><BR>
<b>Heat exchange:</b><BR>
<A href='byond://?src=\ref[src];make=2;dir=1'>Pipe</A><BR>
<A href='byond://?src=\ref[src];make=3;dir=5'>Bent Pipe</A><BR>
<A href='byond://?src=\ref[src];make=6;dir=1'>Junction</A><BR>
<A href='byond://?src=\ref[src];make=17;dir=1'>Heat Exchanger</A><BR>
<b>Insulated pipes:</b><BR>
<A href='byond://?src=\ref[src];make=11;dir=1'>Pipe</A><BR>
<A href='byond://?src=\ref[src];make=12;dir=5'>Bent Pipe</A><BR>

"}
///// Z-Level stuff
//What number the make points to is in the define # at the top of construction.dm in same folder

	user << browse(HTML_SKELETON_TITLE("[src]","<TT>[dat]</TT>"), "window=pipedispenser")
	onclose(user, "pipedispenser")
	return

/obj/machinery/pipedispenser/Topic(href, href_list)
	if(..())
		return
	if(!anchored || !usr.canmove || usr.stat || usr.restrained() || !in_range(loc, usr))
		usr << browse(null, "window=pipedispenser")
		return
	usr.set_machine(src)
	src.add_fingerprint(usr)
	if(href_list["make"])
		if(!wait)
			var/pipe_type = text2num(href_list["make"])
			var/p_dir = text2num(href_list["dir"])
			var/obj/item/pipe/P = new (/*usr.loc*/ src.loc, pipe_type=pipe_type, dir=p_dir)
			P.update()
			P.add_fingerprint(usr)
			wait = 1
			spawn(10)
				wait = 0
	if(href_list["makemeter"])
		if(!wait)
			new /obj/item/pipe_meter(/*usr.loc*/ src.loc)
			wait = 1
			spawn(15)
				wait = 0
	return

/obj/machinery/pipedispenser/attackby(obj/item/I, mob/user)
	src.add_fingerprint(usr)
	if (istype(I, /obj/item/pipe) || istype(I, /obj/item/pipe_meter))
		to_chat(usr, span_notice("You put [I] back to [src]."))
		user.drop_item()
		qdel(I)
		return
	var/obj/item/tool/tool = I
	if (!tool)
		return ..()
	if (!tool.use_tool(user, src, WORKTIME_NORMAL, QUALITY_BOLT_TURNING, FAILCHANCE_VERY_EASY, required_stat = STAT_MEC))
		return ..()
	anchored = !src.anchored
	anchored ? (src.stat &= ~MAINT) : (src.stat |= MAINT)
	if(anchored)
		power_change()
	else
		if (usr.machine==src)
			usr << browse(null, "window=pipedispenser")
	user.visible_message( \
		span_notice("\The [user] [anchored ? "":"un"]fastens \the [src]."), \
		span_notice("You have [anchored ? "":"un"]fastened \the [src]."), \
		"You hear ratchet.")


/obj/machinery/pipedispenser/disposal
	name = "Disposal Pipe Dispenser"
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "pipe_d"
	density = TRUE
	anchored = TRUE

/*
//Allow you to push disposal pipes into it (for those with density 1)
/obj/machinery/pipedispenser/disposal/Crossed(obj/structure/disposalconstruct/pipe as obj)
	if(istype(pipe) && !pipe.anchored)
		qdel(pipe)

Nah
*/

//Allow you to drag-drop disposal pipes into it
/obj/machinery/pipedispenser/disposal/MouseDrop_T(obj/structure/disposalconstruct/pipe as obj, mob/usr as mob)
	if(!usr.canmove || usr.stat || usr.restrained())
		return

	if (!istype(pipe) || get_dist(usr, src) > 1 || get_dist(src,pipe) > 1 )
		return

	if (pipe.anchored)
		return

	qdel(pipe)

/obj/machinery/pipedispenser/disposal/attack_hand(user as mob)
	if(..())
		return

///// Z-Level stuff
	var/dat = {"<b>Disposal Pipes</b><br><br>
<A href='byond://?src=\ref[src];dmake=0'>Pipe</A><BR>
<A href='byond://?src=\ref[src];dmake=1'>Bent Pipe</A><BR>
<A href='byond://?src=\ref[src];dmake=2'>Junction</A><BR>
<A href='byond://?src=\ref[src];dmake=3'>Y-Junction</A><BR>
<A href='byond://?src=\ref[src];dmake=4'>Trunk</A><BR>
<A href='byond://?src=\ref[src];dmake=5'>Bin</A><BR>
<A href='byond://?src=\ref[src];dmake=6'>Outlet</A><BR>
<A href='byond://?src=\ref[src];dmake=7'>Chute</A><BR>
<A href='byond://?src=\ref[src];dmake=21'>Upwards</A><BR>
<A href='byond://?src=\ref[src];dmake=22'>Downwards</A><BR>
<A href='byond://?src=\ref[src];dmake=8'>Sorting</A><BR>
<A href='byond://?src=\ref[src];dmake=9'>Sorting (Wildcard)</A><BR>
<A href='byond://?src=\ref[src];dmake=10'>Sorting (Untagged)</A><BR>
<A href='byond://?src=\ref[src];dmake=11'>Tagger</A><BR>
<A href='byond://?src=\ref[src];dmake=12'>Tagger (Partial)</A><BR>
"}
///// Z-Level stuff

	user << browse(HTML_SKELETON_TITLE("[src]","<TT>[dat]</TT>"), "window=pipedispenser")
	return

// 0=straight, 1=bent, 2=junction-j1, 3=junction-j2, 4=junction-y, 5=trunk


/obj/machinery/pipedispenser/disposal/Topic(href, href_list)
	if(..())
		return
	usr.set_machine(src)
	src.add_fingerprint(usr)
	if(href_list["dmake"])
		if(!anchored || !usr.canmove || usr.stat || usr.restrained() || !in_range(loc, usr))
			usr << browse(null, "window=pipedispenser")
			return
		if(!wait)
			var/pipe_type = text2num(href_list["dmake"])
			var/obj/structure/disposalconstruct/C = new (src.loc)
			switch(pipe_type)
				if(0)
					C.pipe_type = PIPE_TYPE_STRAIGHT
				if(1)
					C.pipe_type = PIPE_TYPE_BENT
				if(2)
					C.pipe_type = PIPE_TYPE_JUNC
				if(3)
					C.pipe_type = PIPE_TYPE_JUNC_Y
				if(4)
					C.pipe_type = PIPE_TYPE_TRUNK
				if(5)
					C.pipe_type = PIPE_TYPE_BIN
					C.density = TRUE
				if(6)
					C.pipe_type = PIPE_TYPE_OUTLET
					C.density = TRUE
				if(7)
					C.pipe_type = PIPE_TYPE_INTAKE
					C.density = TRUE
				if(8)
					C.pipe_type = PIPE_TYPE_JUNC_SORT
					C.sort_mode = SORT_TYPE_NORMAL
				if(9)
					C.pipe_type = PIPE_TYPE_JUNC_SORT
					C.sort_mode = SORT_TYPE_WILDCARD
				if(10)
					C.pipe_type = PIPE_TYPE_JUNC_SORT
					C.sort_mode = SORT_TYPE_UNTAGGED
				if(11)
					C.pipe_type = PIPE_TYPE_TAGGER
				if(12)
					C.pipe_type = PIPE_TYPE_TAGGER_PART
///// Z-Level stuff
				if(21)
					C.pipe_type = PIPE_TYPE_UP
				if(22)
					C.pipe_type = PIPE_TYPE_DOWN
///// Z-Level stuff
			C.add_fingerprint(usr)
			C.update()
			wait = 1
			spawn(15)
				wait = 0
	return

// adding a pipe dispensers that spawn unhooked from the ground
/obj/machinery/pipedispenser/orderable
	anchored = FALSE

/obj/machinery/pipedispenser/disposal/orderable
	anchored = FALSE
