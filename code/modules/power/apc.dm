//update_state
#define UPDATE_CELL_IN 1
#define UPDATE_OPENED1 2
#define UPDATE_OPENED2 4
#define UPDATE_MAINT 8
#define UPDATE_BROKE 16
#define UPDATE_BLUESCREEN 32
#define UPDATE_WIREEXP 64
#define UPDATE_ALLGOOD 128

//update_overlay
#define APC_UPOVERLAY_CHARGEING0 1
#define APC_UPOVERLAY_CHARGEING1 2
#define APC_UPOVERLAY_CHARGEING2 4
#define APC_UPOVERLAY_EQUIPMENT0 8
#define APC_UPOVERLAY_EQUIPMENT1 16
#define APC_UPOVERLAY_EQUIPMENT2 32
#define APC_UPOVERLAY_LIGHTING0 64
#define APC_UPOVERLAY_LIGHTING1 128
#define APC_UPOVERLAY_LIGHTING2 256
#define APC_UPOVERLAY_ENVIRON0 512
#define APC_UPOVERLAY_ENVIRON1 1024
#define APC_UPOVERLAY_ENVIRON2 2048
#define APC_UPOVERLAY_LOCKED 4096
#define APC_UPOVERLAY_OPERATING 8192


#define APC_UPDATE_ICON_COOLDOWN 100 // 10 seconds

// the Area Power Controller (APC), formerly Power Distribution Unit (PDU)
// one per area, needs wire conection to power network through a terminal

// controls power to devices in that area
// may be opened to change power cell
// three different channels (lighting/equipment/environ) - may each be set to on, off, or auto


//NOTE: STUFF STOLEN FROM AIRLOCK.DM thx

/obj/machinery/power/apc/critical
	is_critical = 1

// Construction site APC, starts turned off
/obj/machinery/power/apc/inactive
	lighting = 0
	equipment = 0
	environ = 0
	locked = 0
	coverlocked = 0
	start_charge = 100

/obj/machinery/power/apc/super
	cell_type = /obj/item/cell/large/super

/obj/machinery/power/apc/super/critical
	is_critical = 1

/obj/machinery/power/apc/hyper
	cell_type = /obj/item/cell/large/hyper

/obj/machinery/power/apc/hyper/critical
	is_critical = 1

/obj/machinery/power/apc
	name = "area power controller"
	desc = "A control terminal for the area electrical systems."
	description_info = "Controls all of this area's machinery."
	description_antag = "Can be unlocked by pulsing the lock wire. Can also be sabotaged by inserting plasma into its cell, making it blow whenever its turned on"

	icon_state = "apc0"
	anchored = TRUE
	use_power = NO_POWER_USE
	req_access = list(access_engine_equip)
	var/need_sound
	var/area/area
	var/areastring
	var/obj/item/cell/large/cell
	var/chargelevel = 0.0005  // Cap for how fast APC cells charge, as a percentage-per-tick (0.01 means cellcharge is capped to 1% per second)
	var/start_charge = 90				// initial cell charge %
	var/cell_type = /obj/item/cell/large/high
	var/opened = 0 //0=closed, 1=opened, 2=cover removed
	var/shorted = 0
	var/lighting = 3
	var/equipment = 3
	var/environ = 3
	var/operating = TRUE
	var/charging = 0
	var/chargemode = 1
	var/chargecount = 0
	var/locked = 1
	var/coverlocked = 1
	var/aidisabled = 0
	var/tdir = null
	var/obj/machinery/power/terminal/terminal
	var/lastused_light = 0
	var/lastused_equip = 0
	var/lastused_environ = 0
	var/lastused_charging = 0
	var/lastused_total = 0
	var/main_status = 0
	var/mob/living/silicon/ai/hacker // Malfunction var. If set AI hacked the APC and has full control.
	var/wiresexposed = 0
	powernet = 0		// set so that APCs aren't found as powernet nodes //Hackish, Horrible, was like this before I changed it :(
	var/debug= 0
	var/autoflag= 0		// 0 = off, 1= eqp and lights off, 2 = eqp off, 3 = all on.
	var/has_electronics = 0 // 0 - none, 1 - plugged in, 2 - secured by screwdriver
	var/beenhit = 0 // used for counting how many times it has been hit, used for Aliens at the moment
	var/longtermpower = 10
	var/datum/wires/apc/wires
	var/update_state = -1
	var/update_overlay = -1
	var/is_critical = 0
	var/global/status_overlays = 0
	var/updating_icon = 0
	var/failure_timer = 0
	var/force_update = 0
	var/global/list/status_overlays_lock
	var/global/list/status_overlays_charging
	var/global/list/status_overlays_equipment
	var/global/list/status_overlays_lighting
	var/global/list/status_overlays_environ
	/// Offsets the object by APC_PIXEL_OFFSET (defined in apc_defines.dm) pixels in the direction we want it placed in. This allows the APC to be embedded in a wall, yet still inside an area (like mapping).
	var/offset_old

/obj/machinery/power/apc/updateDialog()
	if (stat & (BROKEN|MAINT))
		return
	..()

/obj/machinery/power/apc/handle_atom_del(atom/A)
	..()
	if(A == cell)
		cell = null
		update_icon()
		updateUsrDialog()

/obj/machinery/power/apc/get_cell()
	return cell

/obj/machinery/power/apc/connect_to_network()
	//Override because the APC does not directly connect to the network; it goes through a terminal.
	//The terminal is what the power computer looks for anyway.
	if(!terminal)
		make_terminal()
	if(terminal)
		terminal.connect_to_network()

/obj/machinery/power/apc/drain_power(drain_check, surge, amount = 0)

	if(drain_check)
		return TRUE

	if(!cell)
		return FALSE

	if(surge && !emagged)
		flick("apc-spark", src)
		emagged = TRUE
		locked = FALSE
		update_icon()
		return FALSE

	if(terminal && terminal.powernet)
		terminal.powernet.trigger_warning()

	return cell.drain_power(drain_check, surge, amount)

/obj/machinery/power/apc/New(turf/loc, ndir, building=0)
	..()
	GLOB.apc_list += src

	wires = new(src)

	if(building)
		area = get_area(src)
		area.apc = src
		opened = 1
		operating = FALSE
		name = "\improper [get_area_name_litteral(area, TRUE)] APC"
		stat |= MAINT
		update_icon()
		addtimer(CALLBACK(src, PROC_REF(update)), 5)
		set_dir(ndir)

	switch(dir)
		if(NORTH)
			offset_old = pixel_y
			pixel_y = 28
		if(SOUTH)
			offset_old = pixel_y
			pixel_y = -28
		if(EAST)
			offset_old = pixel_x
			pixel_x = 28
		if(WEST)
			offset_old = pixel_x
			pixel_x = -28

	tdir = dir		// to fix Vars bug

/obj/machinery/power/apc/Initialize(mapload)
	. = ..()

	if(!mapload)
		return
	has_electronics = 2
	// is starting with a power cell installed, create it and set its charge level
	if(cell_type)
		cell = new cell_type(src)
		cell.charge = start_charge * cell.maxcharge / 100 // (convert percentage to actual value)

	var/area/our_area = get_area(loc)

	//if area isn't specified use current
	if(areastring)
		area = get_area_name(areastring)
		if(!area && isarea(our_area))
			area = our_area
			stack_trace("Bad areastring path for [src], [areastring]")
	else if(isarea(our_area) && areastring == null)
		area = our_area

	name = "\improper [get_area_name_litteral(area, TRUE)] APC"

	if(area)
		if(area.apc)
			log_mapping("Duplicate APC created at [AREACOORD(src)]. Original at [AREACOORD(area.apc)].")
		area.apc = src

	update_icon()

	make_terminal()

	addtimer(CALLBACK(src, PROC_REF(update)), 5)

/obj/machinery/power/apc/Destroy()
	GLOB.apc_list -= src

	// Malf AI, removes the APC from AI's hacked APCs list.
	if((hacker) && (hacker.hacked_apcs) && (src in hacker.hacked_apcs))
		hacker.hacked_apcs -= src
	if(area)
		area.power_light = FALSE
		area.power_equip = FALSE
		area.power_environ = FALSE
		area.power_change()
		area.apc = null
		SEND_SIGNAL_OLD(area, COMSIG_AREA_APC_DELETED)

	if(wires)
		QDEL_NULL(wires)
	if(cell)
		cell.forceMove(loc)
		cell = null
	if(terminal)
		qdel(terminal)
	. = ..()

/obj/machinery/power/apc/proc/energy_fail(duration)
	failure_timer = max(failure_timer, duration)
	update_icon()
	update()

/obj/machinery/power/apc/proc/make_terminal()
	// create a terminal object at the same position as original turf loc
	// wires will attach to this
	terminal = new/obj/machinery/power/terminal(loc)
	terminal.set_dir(tdir)
	terminal.master = src

/obj/machinery/power/apc/examine(mob/user, extra_description = "")
	if(get_dist(user, src) < 2)
		if(stat & BROKEN)
			extra_description += "\nLooks broken."
		else if(opened)
			if(has_electronics && terminal)
				extra_description += "\nThe cover is [opened==2?"removed":"open"] and the power cell is [ cell ? "installed" : "missing"]."
			else if (!has_electronics && terminal)
				extra_description += "\nThere are some wires but no any electronics."
			else if (has_electronics && !terminal)
				extra_description += "\nElectronics installed but not wired."
			else /* if (!has_electronics && !terminal) */
				extra_description += "\nThere is no electronics nor connected wires."
		else
			if(stat & MAINT)
				extra_description += "\nThe cover is closed. Something wrong with it: it doesn't work."
			else if(hacker)
				extra_description += "\nThe cover is locked."
			else
				extra_description += "\nThe cover is closed."
	..(user, extra_description)

// update the APC icon to show the three base states
// also add overlays for indicator lights
/obj/machinery/power/apc/update_icon()
	if (!status_overlays)
		status_overlays = 1
		status_overlays_lock = new
		status_overlays_charging = new
		status_overlays_equipment = new
		status_overlays_lighting = new
		status_overlays_environ = new

		status_overlays_lock.len = 2
		status_overlays_charging.len = 3
		status_overlays_equipment.len = 4
		status_overlays_lighting.len = 4
		status_overlays_environ.len = 4

		status_overlays_lock[1] = image(icon, "apcox-0")    // 0=blue 1=red
		status_overlays_lock[2] = image(icon, "apcox-1")

		status_overlays_charging[1] = image(icon, "apco3-0")
		status_overlays_charging[2] = image(icon, "apco3-1")
		status_overlays_charging[3] = image(icon, "apco3-2")

		status_overlays_equipment[1] = image(icon, "apco0-0")
		status_overlays_equipment[2] = image(icon, "apco0-1")
		status_overlays_equipment[3] = image(icon, "apco0-2")
		status_overlays_equipment[4] = image(icon, "apco0-3")

		status_overlays_lighting[1] = image(icon, "apco1-0")
		status_overlays_lighting[2] = image(icon, "apco1-1")
		status_overlays_lighting[3] = image(icon, "apco1-2")
		status_overlays_lighting[4] = image(icon, "apco1-3")

		status_overlays_environ[1] = image(icon, "apco2-0")
		status_overlays_environ[2] = image(icon, "apco2-1")
		status_overlays_environ[3] = image(icon, "apco2-2")
		status_overlays_environ[4] = image(icon, "apco2-3")

	var/update = check_updates() 		//returns 0 if no need to update icons.
						// 1 if we need to update the icon_state
						// 2 if we need to update the overlays
	if(!update)
		return

	if(update > 0) // Updating the icon state
		if(update_state & UPDATE_ALLGOOD)
			icon_state = "apc0"
		else if(update_state & (UPDATE_OPENED1|UPDATE_OPENED2))
			var/basestate = "apc[ cell ? "2" : "1" ]"
			if(update_state & UPDATE_OPENED1)
				if(update_state & (UPDATE_MAINT|UPDATE_BROKE))
					icon_state = "apcmaint" //disabled APC cannot hold cell
				else
					icon_state = basestate
			else if(update_state & UPDATE_OPENED2)
				icon_state = "[basestate]-nocover"
		else if(update_state & UPDATE_BROKE)
			icon_state = "apc-b"
		else if(update_state & UPDATE_BLUESCREEN)
			icon_state = "apcemag"
		else if(update_state & UPDATE_WIREEXP)
			icon_state = "apcewires"

		if(update_state & UPDATE_BLUESCREEN)
			set_light(l_range = 2, l_power = 0.6, l_color = "#0000FF")
		else if(!(stat & (BROKEN|MAINT)) && update_state & UPDATE_ALLGOOD)
			var/color
			switch(charging)
				if(0)
					color = COLOR_LIGHTING_RED_MACHINERY
				if(1)
					color = COLOR_LIGHTING_BLUE_BRIGHT
				if(2)
					color = COLOR_LIGHTING_GREEN_BRIGHT
			set_light(l_range = 2, l_power = 0.6, l_color = color)
		else
			set_light(0)

	if(!(update_state & UPDATE_ALLGOOD))
		if(overlays.len)
			overlays = 0
			return

	if(update > 1)
		if(overlays.len)
			overlays.len = 0
		if(!(stat & (BROKEN|MAINT)) && update_state & UPDATE_ALLGOOD)
			overlays += status_overlays_lock[locked+1]
			overlays += status_overlays_charging[charging+1]
			if(operating)
				overlays += status_overlays_equipment[equipment+1]
				overlays += status_overlays_lighting[lighting+1]
				overlays += status_overlays_environ[environ+1]


/obj/machinery/power/apc/proc/check_updates()

	var/last_update_state = update_state
	var/last_update_overlay = update_overlay
	update_state = 0
	update_overlay = 0

	if(cell)
		update_state |= UPDATE_CELL_IN
	if(stat & BROKEN)
		update_state |= UPDATE_BROKE
	if(stat & MAINT)
		update_state |= UPDATE_MAINT
	if(opened)
		if(opened==1)
			update_state |= UPDATE_OPENED1
		if(opened==2)
			update_state |= UPDATE_OPENED2
	else if(wiresexposed)
		update_state |= UPDATE_WIREEXP
	if(emagged || hacker || failure_timer)
		update_state |= UPDATE_BLUESCREEN
	if(update_state <= 1)
		update_state |= UPDATE_ALLGOOD

	if(operating)
		update_overlay |= APC_UPOVERLAY_OPERATING

	if(update_state & UPDATE_ALLGOOD)
		if(locked)
			update_overlay |= APC_UPOVERLAY_LOCKED

		if(!charging)
			update_overlay |= APC_UPOVERLAY_CHARGEING0
		else if(charging == 1)
			update_overlay |= APC_UPOVERLAY_CHARGEING1
		else if(charging == 2)
			update_overlay |= APC_UPOVERLAY_CHARGEING2

		if (!equipment)
			update_overlay |= APC_UPOVERLAY_EQUIPMENT0
		else if(equipment == 1)
			update_overlay |= APC_UPOVERLAY_EQUIPMENT1
		else if(equipment == 2)
			update_overlay |= APC_UPOVERLAY_EQUIPMENT2

		if(!lighting)
			update_overlay |= APC_UPOVERLAY_LIGHTING0
		else if(lighting == 1)
			update_overlay |= APC_UPOVERLAY_LIGHTING1
		else if(lighting == 2)
			update_overlay |= APC_UPOVERLAY_LIGHTING2

		if(!environ)
			update_overlay |= APC_UPOVERLAY_ENVIRON0
		else if(environ==1)
			update_overlay |= APC_UPOVERLAY_ENVIRON1
		else if(environ==2)
			update_overlay |= APC_UPOVERLAY_ENVIRON2


	var/results = 0
	if(last_update_state == update_state && last_update_overlay == update_overlay)
		return FALSE
	if(last_update_state != update_state)
		results += 1
	if(last_update_overlay != update_overlay)
		results += 2
	return results

// Used in process so it doesn't update the icon too much
/obj/machinery/power/apc/proc/queue_icon_update()

	if(!updating_icon)
		updating_icon = 1
		// Start the update
		spawn(APC_UPDATE_ICON_COOLDOWN)
			update_icon()
			updating_icon = 0

//attack with an item - open/close cover, insert cell, or (un)lock interface

/obj/machinery/power/apc/attackby(obj/item/I, mob/user)
	if (issilicon(user) && get_dist(src,user)>1)
		return attack_hand(user)
	add_fingerprint(user)

	var/list/usable_qualities = list(QUALITY_SCREW_DRIVING)
	if(opened || !((stat & BROKEN) || hacker))
		usable_qualities.Add(QUALITY_PRYING)
	if(terminal && opened && has_electronics!=2)
		usable_qualities.Add(QUALITY_WIRE_CUTTING)
	if(opened && has_electronics==0 && !terminal)
		usable_qualities.Add(QUALITY_WELDING)

	var/tool_type = I.get_tool_type(user, usable_qualities, src)
	switch(tool_type)

		if(QUALITY_PRYING)
			if(opened)
				if (has_electronics==1)
					if (terminal)
						to_chat(user, span_warning("Disconnect wires first."))
						return
				if(I.use_tool(user, src, WORKTIME_FAST, tool_type, FAILCHANCE_VERY_EASY, required_stat = STAT_MEC))
					if (has_electronics==1)
						has_electronics = 0
						if ((stat & BROKEN))
							user.visible_message(\
								span_warning("[user.name] has broken the power control board inside [name]!"),\
								span_notice("You broke the charred power control board and remove the remains."),
								"You hear a crack!")
						else
							user.visible_message(\
								span_warning("[user.name] has removed the power control board from [name]!"),\
								span_notice("You remove the power control board."))
							new /obj/item/electronics/circuitboard/apc(loc)
						return
			if(opened!=2) //cover isn't removed
				if(I.use_tool(user, src, WORKTIME_FAST, tool_type, FAILCHANCE_VERY_EASY, required_stat = STAT_MEC))
					if (opened == 1)
						opened = 0
						update_icon()
					else if(!((stat & BROKEN) || hacker))
						if(coverlocked && !(stat & MAINT))
							to_chat(user, span_warning("The cover is locked and cannot be opened."))
						else
							opened = 1
							update_icon()
							return
			return

		if(QUALITY_WIRE_CUTTING)
			if(terminal && opened && has_electronics!=2)
				var/turf/T = loc
				if(istype(T) && !T.is_plating())
					to_chat(user, span_warning("You must remove the floor plating in front of the APC first."))
					return
				if(I.use_tool(user, src, WORKTIME_FAST, tool_type, FAILCHANCE_VERY_EASY, required_stat = STAT_MEC))
					if (prob(50) && electrocute_mob(usr, terminal.powernet, terminal))
						var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
						s.set_up(5, 1, src)
						s.start()
						if(usr.stunned)
							return
					new /obj/item/stack/cable_coil(loc,10)
					to_chat(user, span_notice("You remove the cables and dismantle the power terminal."))
					qdel(terminal)
					return
			return

		if(QUALITY_SCREW_DRIVING)
			if (cell && opened)
				to_chat(user, span_warning("Close the APC first."))
				return
			var/used_sound = wiresexposed ? 'sound/machines/Custom_screwdriveropen.ogg' :  'sound/machines/Custom_screwdriverclose.ogg'
			if(I.use_tool(user, src, WORKTIME_NEAR_INSTANT, tool_type, FAILCHANCE_VERY_EASY, required_stat = STAT_MEC, instant_finish_tier = 30, forced_sound = used_sound))
				if(opened)
					if (has_electronics==1 && terminal)
						has_electronics = 2
						stat &= ~MAINT
						to_chat(user, "You screw the circuit electronics into place.")
					else if (has_electronics==2)
						has_electronics = 1
						stat |= MAINT
						to_chat(user, "You unfasten the electronics.")
					else /* has_electronics==0 */
						to_chat(user, span_warning("There is nothing to secure."))
						return
					update_icon()
				else
					wiresexposed = !wiresexposed
					to_chat(user, "The wires have been [wiresexposed ? "exposed" : "unexposed"]")
					var/sound = wiresexposed ?'sound/machines/Custom_screwdriveropen.ogg' : 'sound/machines/Custom_screwdriverclose.ogg'
					playsound(loc, sound, 100, 1)
					update_icon()
					return

		if(QUALITY_WELDING)
			if(opened && has_electronics==0 && !terminal)
				if(I.use_tool(user, src, WORKTIME_FAST, tool_type, FAILCHANCE_VERY_EASY, required_stat = STAT_MEC))
					if (emagged || (stat & BROKEN) || opened==2)
						new /obj/item/stack/material/steel(loc)
						user.visible_message(\
							span_warning("[src] has been cut apart by [user.name] with the weldingtool."),\
							span_notice("You disassembled the broken APC frame."),\
							"You hear welding.")
					else
						new /obj/item/frame/apc(loc)
						user.visible_message(\
							span_warning("[src] has been cut from the wall by [user.name] with the weldingtool."),\
							span_notice("You cut the APC frame from the wall."),\
							"You hear welding.")
					qdel(src)
					return
			return

		if(ABORT_CHECK)
			return
	if (istype(I, /obj/item/gripper))//Gripper can extract cell
		var/obj/item/gripper/Gri = I
		if(opened && cell)
			if (Gri.grip_item(cell, user))
				cell.add_fingerprint(user)
				cell.update_icon()
				cell = null
				user.visible_message(span_warning("[user.name] removes the power cell from [name]!"),\
									 span_notice("You remove the power cell."))
				charging = 0
				update_icon()
				return

	if (istype(I, /obj/item/cell/large) && opened)	// trying to put a cell inside
		if(cell)
			to_chat(user, "There is a power cell already installed.")
			return
		if (stat & MAINT)
			to_chat(user, span_warning("There is no connector for your power cell."))
			return
		if(I.w_class != ITEM_SIZE_NORMAL)
			to_chat(user, "\The [I] is too [I.w_class < ITEM_SIZE_NORMAL? "small" : "large"] to fit here.")
			return

		user.drop_item()
		I.forceMove(src)
		cell = I
		user.visible_message(\
			span_warning("[user.name] has inserted the power cell to [name]!"),\
			span_notice("You insert the power cell."))
		chargecount = 0
		update_icon()
	else if (istype(I, /obj/item/card/id)||istype(I, /obj/item/modular_computer))
		toggle_lock(user)
	else if (istype(I, /obj/item/stack/cable_coil) && !terminal && opened && has_electronics!=2)
		var/turf/T = loc
		if(istype(T) && !T.is_plating())
			to_chat(user, span_warning("You must remove the floor plating in front of the APC first."))
			return
		var/obj/item/stack/cable_coil/C = I
		if(C.get_amount() < 10)
			to_chat(user, span_warning("You need ten lengths of cable for APC."))
			return
		user.visible_message(span_warning("[user.name] adds cables to the APC frame."), \
							"You start adding cables to the APC frame...")
		playsound(loc, 'sound/items/Deconstruct.ogg', 50, 1)
		if(do_after(user, 20, src))
			if (C.amount >= 10 && !terminal && opened && has_electronics != 2)
				var/obj/structure/cable/N = T.get_cable_node()
				if (prob(50) && electrocute_mob(usr, N, N))
					var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
					s.set_up(5, 1, src)
					s.start()
					if(user.stunned)
						return
				C.use(10)
				user.visible_message(\
					span_warning("[user.name] has added cables to the APC frame!"),\
					"You add cables to the APC frame.")
				make_terminal()
				terminal.connect_to_network()

	else if (istype(I, /obj/item/electronics/circuitboard/apc) && opened && has_electronics==0 && !((stat & BROKEN)))
		user.visible_message(span_warning("[user.name] inserts the power control board into [src]."), \
							"You start to insert the power control board into the frame...")
		playsound(loc, 'sound/items/Deconstruct.ogg', 50, 1)
		if(do_after(user, 10, src))
			if(has_electronics==0)
				has_electronics = 1
				to_chat(user, span_notice("You place the power control board inside the frame."))
				qdel(I)

	else if (istype(I, /obj/item/electronics/circuitboard/apc) && opened && has_electronics==0 && ((stat & BROKEN)))
		to_chat(user, span_warning("You cannot put the board inside, the frame is damaged."))
		return

	else if (istype(I, /obj/item/frame/apc) && opened && emagged)
		emagged = FALSE
		if (opened==2)
			opened = 1
		user.visible_message(\
			span_warning("[user.name] has replaced the damaged APC frontal panel with a new one."),\
			span_notice("You replace the damaged APC frontal panel with a new one."))
		qdel(I)
		update_icon()

	else if (istype(I, /obj/item/frame/apc) && opened && ((stat & BROKEN) || hacker))
		if (has_electronics)
			to_chat(user, span_warning("You cannot repair this APC until you remove the electronics still inside."))
			return
		user.visible_message(span_warning("[user.name] replaces the damaged APC frame with a new one."),\
							"You begin to replace the damaged APC frame...")
		if(do_after(user, 50, src))
			user.visible_message(\
				span_notice("[user.name] has replaced the damaged APC frame with new one."),\
				"You replace the damaged APC frame with new one.")
			qdel(I)
			stat &= ~BROKEN
			// Malf AI, removes the APC from AI's hacked APCs list.
			if(hacker && hacker.hacked_apcs && (src in hacker.hacked_apcs))
				hacker.hacked_apcs -= src
				hacker = null
			if (opened==2)
				opened = 1
			update_icon()
	else
		if (((stat & BROKEN) || hacker) \
				&& !opened \
				&& I.force >= 5 \
				&& I.w_class >= ITEM_SIZE_NORMAL \
				&& prob(20) )
			opened = 2
			user.visible_message(span_danger("The APC cover was knocked down with the [I.name] by [user.name]!"), \
				span_danger("You knock down the APC cover with your [I.name]!"), \
				"You hear bang")
			update_icon()
		else
			if (issilicon(user))
				return attack_hand(user)
			if (!opened && wiresexposed && \
				((QUALITY_PULSING in I.tool_qualities) || \
				(QUALITY_WIRE_CUTTING in I.tool_qualities) || \
				(QUALITY_CUTTING in I.tool_qualities) || \
				istype(I, /obj/item/device/assembly/signaler)))
				return attack_hand(user)

			if (!istype(I, /obj/item/material/kitchen/utensil/fork))
				user.visible_message(span_danger("The [name] has been hit with the [I.name] by [user.name]!"), \
				span_danger("You hit the [name] with your [I.name]!"), \
				"You hear a bang")
				return

			to_chat(user, span_warning("You start looking around for a socket on \the [src]..."))
			if (!do_after(user, 1 SECOND, src))
				to_chat(user, span_notice("You reconsider your life choices."))
				return
			if (istype(I, /obj/item/material/kitchen/utensil/fork/plastic))
				to_chat(user, span_warning("You stick \the [I] into a small socket below the APC but nothing happens. Maybe it's for the best. "))
				return

			user.visible_message(span_danger("[user.name] shocks themself by putting \a [I] into \the [src]!"), \
				span_danger("You stick \the [I] into \the [src] and shock yourself! Oh god!"), \
				"You hear a loud electrical BZZZT.")
			electrocute_mob(user, get_area(src), src)

// attack with hand - remove cell (if cover open) or interact with the APC

/obj/machinery/power/apc/fire_act()
	return

/obj/machinery/power/apc/emag_act(remaining_charges, mob/user)
	if (!(emagged || hacker))		// trying to unlock with an emag card
		if(opened)
			to_chat(user, "You must close the cover to swipe an ID card.")
		else if(wiresexposed)
			to_chat(user, "You must close the panel first")
		else if(stat & (BROKEN|MAINT))
			to_chat(user, "Nothing happens.")
		else
			flick("apc-spark", src)
			if (do_after(user,6,src))
				if(prob(50))
					emagged = TRUE
					locked = FALSE
					to_chat(user, span_notice("You emag the APC interface."))
					update_icon()
				else
					to_chat(user, span_warning("You fail to [ locked ? "unlock" : "lock"] the APC interface."))
				return TRUE

/obj/machinery/power/apc/attack_hand(mob/user)
//	if (!can_use(user)) This already gets called in interact() and in topic()
//		return
	if(!user)
		return
	add_fingerprint(user)

	//Human mob special interaction goes here.
	if(ishuman(user))
		var/mob/living/carbon/human/H = user

		if(H.species.can_shred(H))
			user.visible_message(span_danger("[user.name] slashes at the [name]!"), span_danger("You slash at the [name]!"))
			playsound(loc, 'sound/weapons/slash.ogg', 100, 1)

			var/allcut = wires.IsAllCut()

			if(beenhit >= pick(3, 4) && wiresexposed != 1)
				wiresexposed = 1
				update_icon()
				visible_message(span_red("The [name]'s cover flies open, exposing the wires!"))

			else if(wiresexposed == 1 && allcut == 0)
				wires.CutAll()
				update_icon()
				visible_message(span_red("The [name]'s wires are shredded!"))
			else
				beenhit += 1
			return

	if(usr == user && opened && (!issilicon(user)))
		if(cell)
			user.put_in_hands(cell)
			cell.add_fingerprint(user)
			cell.update_icon()

			cell = null
			user.visible_message(span_warning("[user.name] removes the power cell from [name]!"),\
								 span_notice("You remove the power cell."))
			//user << "You remove the power cell."
			charging = 0
			update_icon()
		return
	if(stat & (BROKEN|MAINT))
		return
	// do APC interaction
	interact(user)

/obj/machinery/power/apc/interact(mob/user)
	if(!user)
		return

	if(wiresexposed && !isAI(user))
		wires.Interact(user)

	return nano_ui_interact(user)

/obj/machinery/power/apc/proc/toggle_lock(mob/user)
	if(emagged)
		to_chat(user, "The interface is broken.")
	else if(opened)
		to_chat(user, "You must close the cover to swipe an ID card.")
	else if(wiresexposed)
		to_chat(user, "You must close the panel")
	else if(stat & (BROKEN|MAINT))
		to_chat(user, "Nothing happens.")
	else if(hacker)
		to_chat(user, span_warning("Access denied."))
	else
		if(allowed(user) && !isWireCut(APC_WIRE_IDSCAN))
			locked = !locked
			to_chat(user, "You [ locked ? "lock" : "unlock"] the APC interface.")
			update_icon()
		else
			to_chat(user, span_warning("Access denied."))


/obj/machinery/power/apc/AltClick(mob/user)
	..()
	if(!can_use(user) || issilicon(user))
		return
	else
		toggle_lock(user)

/obj/machinery/power/apc/nano_ui_interact(mob/user, ui_key = "main", datum/nanoui/ui = null, force_open = NANOUI_FOCUS)
	if(!user)
		return

	var/list/data = list(
		"locked" = (locked && !emagged) ? 1 : 0,
		"isOperating" = operating,
		"externalPower" = main_status,
		"powerCellStatus" = cell ? cell.percent() : null,
		"chargeMode" = chargemode,
		"chargingStatus" = charging,
		"totalLoad" = round(lastused_total),
		"totalCharging" = round(lastused_charging),
		"coverLocked" = coverlocked,
		"failTime" = failure_timer * 2,
		"siliconUser" = issilicon(user),

		"powerChannels" = list(
			list(
				"title" = "Equipment",
				"powerLoad" = lastused_equip,
				"status" = equipment,
				"topicParams" = list(
					"auto" = list("eqp" = 3),
					"on"   = list("eqp" = 2),
					"off"  = list("eqp" = 1)
				)
			),
			list(
				"title" = "Lighting",
				"powerLoad" = round(lastused_light),
				"status" = lighting,
				"topicParams" = list(
					"auto" = list("lgt" = 3),
					"on"   = list("lgt" = 2),
					"off"  = list("lgt" = 1)
				)
			),
			list(
				"title" = "Environment",
				"powerLoad" = round(lastused_environ),
				"status" = environ,
				"topicParams" = list(
					"auto" = list("env" = 3),
					"on"   = list("env" = 2),
					"off"  = list("env" = 1)
				)
			)
		)
	)

	// update the ui if it exists, returns null if no ui is passed/found
	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)
		// the ui does not exist, so we'll create a new() one
        // for a list of parameters and their descriptions see the code docs in \code\modules\nano\nanoui.dm
		ui = new(user, src, ui_key, "apc.tmpl", "[area.name] - APC", 520, data["siliconUser"] ? 465 : 440)
		// when the ui is first opened this is the data it will use
		ui.set_initial_data(data)
		// open the new ui window
		ui.open()
		// auto update every Master Controller tick
		ui.set_auto_update(1)

/obj/machinery/power/apc/proc/report()
	return "[area.name] : [equipment]/[lighting]/[environ] ([lastused_equip+lastused_light+lastused_environ]) : [cell? cell.percent() : "N/C"] ([charging])"

/obj/machinery/power/apc/proc/update()
	if(operating && !shorted && !failure_timer)
		area.power_light = (lighting > 1)
		area.power_equip = (equipment > 1)
		area.power_environ = (environ > 1)
//		if (area.name == "AI Chamber")
//			spawn(10)
//				world << " [area.name] [area.power_equip]"
	else
		area.power_light = FALSE
		area.power_equip = FALSE
		area.power_environ = FALSE
//		if (area.name == "AI Chamber")
//			world << "[area.power_equip]"
	area.power_change()

/obj/machinery/power/apc/proc/isWireCut(wireIndex)
	return wires.IsIndexCut(wireIndex)


/obj/machinery/power/apc/proc/can_use(mob/user, loud = 0) //used by attack_hand() and Topic()
	if (user.stat)
		to_chat(user, span_warning("You must be conscious to use [src]!"))
		return FALSE
	if(!user.client)
		return FALSE
	if(inoperable())
		return FALSE
	if(!user.IsAdvancedToolUser())
		return FALSE
	if(user.restrained())
		to_chat(user, span_warning("You must have free hands to use [src]."))
		return FALSE
	if(user.lying)
		to_chat(user, span_warning("You must stand to use [src]!"))
		return FALSE
	autoflag = 5
	if (issilicon(user))
		var/permit = 0 // Malfunction variable. If AI hacks APC it can control it even without AI control wire.
		var/mob/living/silicon/ai/AI = user
		var/mob/living/silicon/robot/robot = user
		if(hacker)
			if(hacker == AI)
				permit = 1
			else if(istype(robot) && robot.connected_ai && robot.connected_ai == hacker) // Cyborgs can use APCs hacked by their AI
				permit = 1

		if(aidisabled && !permit)
			if(!loud)
				to_chat(user, span_danger("\The [src] have AI control disabled!"))
			return FALSE
	else
		if (!in_range(src, user) || !istype(loc, /turf))
			return FALSE
	var/mob/living/carbon/human/H = user
	if (istype(H) && prob(H.getBrainLoss()))
		to_chat(user, span_danger("You momentarily forget how to use [src]."))
		return FALSE
	return TRUE

/obj/machinery/power/apc/Topic(href, href_list)
	if(..())
		return TRUE

	if(!can_use(usr, 1))
		return TRUE

	else if(href_list["reboot"])
		failure_timer = 0
		update_icon()
		update()
		return TRUE

	if(!issilicon(usr) && (locked && !emagged))
		// Shouldn't happen, this is here to prevent href exploits
		to_chat(usr, "You must unlock the panel to use this!")
		return TRUE

	if (href_list["lock"])
		coverlocked = !coverlocked

	else if (href_list["breaker"])
		toggle_breaker()

	else if (href_list["cmode"])
		chargemode = !chargemode
		if(!chargemode)
			charging = 0
			update_icon()

	else if (href_list["eqp"])
		var/val = text2num(href_list["eqp"])
		equipment = setsubsystem(val)
		update_icon()
		update()

	else if (href_list["lgt"])
		var/val = text2num(href_list["lgt"])
		lighting = setsubsystem(val)
		update_icon()
		update()

	else if (href_list["env"])
		var/val = text2num(href_list["env"])
		environ = setsubsystem(val)
		update_icon()
		update()

	else if (href_list["overload"])
		if(issilicon(usr))
			overload_lighting()

	else if (href_list["toggleaccess"])
		if(issilicon(usr))
			if(emagged || (stat & (BROKEN|MAINT)))
				to_chat(usr, "The APC does not respond to the command.")
			else
				locked = !locked
				update_icon()
	playsound(loc, 'sound/machines/machine_switch.ogg', 100, 1)
	return FALSE

/obj/machinery/power/apc/proc/toggle_breaker()
	operating = !operating
	update()
	update_icon()

/obj/machinery/power/apc/proc/ion_act()
	if(prob(3))
		locked = 1
		if (cell.charge > 0)
			cell.charge = 0
			cell.corrupt()
			update_icon()
			var/datum/effect/effect/system/smoke_spread/smoke = new /datum/effect/effect/system/smoke_spread()
			smoke.set_up(3, 0, loc)
			smoke.attach(src)
			smoke.start()
			var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
			s.set_up(3, 1, src)
			s.start()
			visible_message(span_danger("The [name] suddenly lets out a blast of smoke and some sparks!"), \
							span_danger("You hear sizzling electronics."))


/obj/machinery/power/apc/surplus()
	if(terminal)
		return terminal.surplus()
	else
		return FALSE

/obj/machinery/power/apc/proc/last_surplus()
	if(terminal && terminal.powernet)
		return terminal.powernet.last_surplus()
	else
		return FALSE

//Returns 1 if the APC should attempt to charge
/obj/machinery/power/apc/proc/attempt_charging()
	return (chargemode && charging == 1 && operating)


/obj/machinery/power/apc/draw_power(amount)
	if(terminal && terminal.powernet)
		return terminal.powernet.draw_power(amount)
	return FALSE

/obj/machinery/power/apc/avail()
	if(terminal)
		return terminal.avail()
	else
		return FALSE

/obj/machinery/power/apc/Process()
	SEND_SIGNAL_OLD(area, COMSIG_AREA_APC_OPERATING, operating)
	if(stat & (BROKEN|MAINT))
		return
	if(!area.requires_power)
		return
	if(failure_timer)
		update()
		queue_icon_update()
		failure_timer--
		force_update = 1
		return

	lastused_light = area.usage(STATIC_LIGHT)
	lastused_equip = area.usage(STATIC_EQUIP)
	lastused_environ = area.usage(STATIC_ENVIRON)
	area.clear_usage()

	lastused_total = lastused_light + lastused_equip + lastused_environ

	//store states to update icon if any change
	var/last_lt = lighting
	var/last_eq = equipment
	var/last_en = environ
	var/last_ch = charging

	var/excess = surplus()

	if(!avail())
		main_status = 0
	else if(excess < 0)
		main_status = 1
	else
		main_status = 2

	if(!cell || cell.is_empty())
		if(need_sound == TRUE)
			playsound(loc, 'sound/machines/Custom_apcnopower.ogg', 75, 0)
			need_sound = FALSE
	else
		need_sound = TRUE

	if(debug)
		log_debug("Status: [main_status] - Excess: [excess] - Last Equip: [lastused_equip] - Last Light: [lastused_light] - Longterm: [longtermpower]")

	if(cell && !shorted)
		// draw power from cell as before to power the area
		var/cellused = cell.use(CELLRATE * lastused_total)	// clamp deduction to a max, amount left in cell

		if(excess > lastused_total)		// if power excess recharge the cell
										// by the same amount just used
			var/draw = draw_power(cellused/CELLRATE) // draw the power needed to charge this cell
			cell.give(draw * CELLRATE)
		else		// no excess, and not enough per-apc
			if( (cell.charge/CELLRATE + excess) >= lastused_total)		// can we draw enough from cell+grid to cover last usage?
				var/draw = draw_power(excess)
				cell.give(CELLRATE * draw)	//recharge with what we can
				charging = 0
			else	// not enough power available to run the last tick!
				charging = 0
				chargecount = 0
				// This turns everything off in the case that there is still a charge left on the battery, just not enough to run the room.
				equipment = autoset(equipment, 0)
				lighting = autoset(lighting, 0)
				environ = autoset(environ, 0)
				autoflag = 0


		// Set channels depending on how much charge we have left
		update_channels()

		// now trickle-charge the cell
		lastused_charging = 0 // Clear the variable for new use.
		if(attempt_charging())
			if(excess > 0)		// check to make sure we have enough to charge
				// Max charge is capped to % per second constant
				var/ch = min(excess*CELLRATE, cell.maxcharge*chargelevel)

				ch = draw_power(ch/CELLRATE) // Removes the power we're taking from the grid
				cell.give(ch*CELLRATE) // actually recharge the cell
				lastused_charging = ch
				lastused_total += ch // Sensors need this to stop reporting APC charging as "Other" load
			else
				charging = 0		// stop charging
				chargecount = 0

		// show cell as fully charged if so
		if(cell.charge >= cell.maxcharge)
			cell.charge = cell.maxcharge
			charging = 2

		if(chargemode)
			if(!charging)
				if(excess > cell.maxcharge*chargelevel)
					chargecount++
				else
					chargecount = 0

				if(chargecount >= 10)

					chargecount = 0
					charging = 1

		else // chargemode off
			charging = 0
			chargecount = 0

	else // no cell, switch everything off
		charging = 0
		chargecount = 0
		equipment = autoset(equipment, 0)
		lighting = autoset(lighting, 0)
		environ = autoset(environ, 0)
		power_alarm.triggerAlarm(loc, src)
		autoflag = 0

	// update icon & area power if anything changed
	if(last_lt != lighting || last_eq != equipment || last_en != environ || force_update)
		force_update = 0
		queue_icon_update()
		update()
	else if (last_ch != charging)
		queue_icon_update()

/obj/machinery/power/apc/proc/update_channels()
	// Allow the APC to operate as normal if the cell can charge
	if(charging && longtermpower < 10)
		longtermpower += 1
	else if(longtermpower > -10)
		longtermpower -= 2

	if((cell.percent() > 30) || longtermpower > 0)              // Put most likely at the top so we don't check it last, effeciency 101
		if(autoflag != 3)
			equipment = autoset(equipment, 1)
			lighting = autoset(lighting, 1)
			environ = autoset(environ, 1)
			autoflag = 3
			power_alarm.clearAlarm(loc, src)
	else if((cell.percent() <= 30) && (cell.percent() > 15) && longtermpower < 0)                       // <30%, turn off equipment
		if(autoflag != 2)
			equipment = autoset(equipment, 2)
			lighting = autoset(lighting, 1)
			environ = autoset(environ, 1)
			power_alarm.triggerAlarm(loc, src)
			autoflag = 2
	else if(cell.percent() <= 15)        // <15%, turn off lighting & equipment
		if((autoflag > 1 && longtermpower < 0) || (autoflag > 1 && longtermpower >= 0))
			equipment = autoset(equipment, 2)
			lighting = autoset(lighting, 2)
			environ = autoset(environ, 1)
			power_alarm.triggerAlarm(loc, src)
			autoflag = 1
	else                                   // zero charge, turn all off
		if(autoflag != 0)
			equipment = autoset(equipment, 0)
			lighting = autoset(lighting, 0)
			environ = autoset(environ, 0)
			power_alarm.triggerAlarm(loc, src)
			autoflag = 0

// val 0=off, 1=off(auto) 2=on 3=on(auto)
// on 0=off, 1=on, 2=autooff

/obj/machinery/power/apc/proc/autoset(val, on)
	if(on==0)
		if(val==2)			// if on, return off
			return 0
		else if(val==3)		// if auto-on, return auto-off
			return 1

	else if(on==1)
		if(val==1)			// if auto-off, return auto-on
			return 3

	else if(on==2)
		if(val==3)			// if auto-on, return auto-off
			return 1

	return val


// damage and destruction acts
/obj/machinery/power/apc/emp_act(severity)
	// Fail for 8-12 minutes (divided by severity)
	// Division by 2 is required, because machinery ticks are every two seconds. Without it we would fail for 16-24 minutes.
	energy_fail(round(rand(240, 360) / severity))
	if(cell)
		cell.emp_act(severity+1)
	update_icon()
	..()

/obj/machinery/power/apc/take_damage(amount)
	if(cell)
		cell.take_damage(amount)
	. = ..()
	if(QDELETED(src))
		return 0
	if(health < maxHealth * 0.5)
		set_broken()
	return 0

/obj/machinery/power/apc/disconnect_terminal()
	if(terminal)
		terminal.master = null
		terminal = null

/obj/machinery/power/apc/proc/set_broken()
	// Aesthetically much better!
	visible_message(span_notice("[src]'s screen flickers with warnings briefly!"))
	visible_message(span_notice("[src]'s screen suddenly explodes in rain of sparks and small debris!"))
	stat |= BROKEN
	operating = 0
	update_icon()
	update()

// overload the lights in this APC area

/obj/machinery/power/apc/proc/overload_lighting(chance = 100)
	if(/* !get_connection() || */ !operating || shorted)
		return
	if( cell && cell.charge>=20)
		cell.use(20);
		spawn(0)
			for(var/obj/machinery/light/L in area)
				if(prob(chance))
					L.on = TRUE
					L.broken()
				sleep(1)

/obj/machinery/power/apc/proc/setsubsystem(val)
	if(cell && cell.charge > 0)
		return (val==1) ? 0 : val
	else if(val == 3)
		return 1
	else
		return 0

// Malfunction: Transfers APC under AI's control
/obj/machinery/power/apc/proc/ai_hack(mob/living/silicon/ai/A = null)
	if(!A || !A.hacked_apcs || hacker || aidisabled || A.stat == DEAD)
		return FALSE
	hacker = A
	A.hacked_apcs += src
	locked = 1
	update_icon()
	return TRUE

#undef APC_UPDATE_ICON_COOLDOWN
