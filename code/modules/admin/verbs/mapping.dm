//- Are all the floors with or without air, as they should be? (regular or airless)
//- Does the area have an APC?
//- Does the area have an Air Alarm?
//- Does the area have a Request Console?
//- Does the area have lights?
//- Does the area have a light switch?
//- Does the area have enough intercoms?
//- Does the area have enough security cameras? (Use the 'Camera Range Display' verb under Debug)
//- Is the area connected to the scrubbers air loop?
//- Is the area connected to the vent air loop? (vent pumps)
//- Is everything wired properly?
//- Does the area have a fire alarm and firedoors?
//- Do all pod doors work properly?
//- Are accesses set properly on doors, pod buttons, etc.
//- Are all items placed properly? (not below vents, scrubbers, tables)
//- Does the disposal system work properly from all the disposal units in this room and all the units, the pipes of which pass through this room?
//- Check for any misplaced or stacked piece of pipe (air and disposal)
//- Check for any misplaced or stacked piece of wire
//- Identify how hard it is to break into the area and where the weak points are
//- Check if the area has too much empty space. If so, make it smaller and replace the rest with maintenance tunnels.

var/camera_range_display_status = 0
var/intercom_range_display_status = 0

/obj/effect/debugging/camera_range
	icon = 'icons/480x480.dmi'
	icon_state = "25percent"

/obj/effect/debugging/camera_range/New()
	src.pixel_x = -224
	src.pixel_y = -224

/obj/effect/debugging/marker
	icon = 'icons/turf/areas.dmi'
	icon_state = "yellow"

/obj/effect/debugging/marker/Move(NewLoc, Dir = 0, step_x = 0, step_y = 0, glide_size_override = 0)
	return 0

/client/proc/do_not_use_these()
	set category = "Mapping"
	set name = "-None of these are for ingame use!!"

/client/proc/camera_view()
	set category = "Mapping"
	set name = "Camera Range Display"

	if(camera_range_display_status)
		camera_range_display_status = 0
	else
		camera_range_display_status = 1



	for(var/obj/effect/debugging/camera_range/C in world)
		qdel(C)

	if(camera_range_display_status)
		for(var/obj/machinery/camera/C in GLOB.cameranet.cameras)
			new/obj/effect/debugging/camera_range(C.loc)




/client/proc/sec_camera_report()
	set category = "Mapping"
	set name = "Camera Report"

	var/list/obj/machinery/camera/CL = list()

	for(var/obj/machinery/camera/C in GLOB.cameranet.cameras)
		CL += C

	var/output = {"<B>CAMERA ANNOMALITIES REPORT</B><HR>
<B>The following annomalities have been detected. The ones in red need immediate attention: Some of those in black may be intentional.</B><BR><ul>"}

	for(var/obj/machinery/camera/C1 in CL)
		for(var/obj/machinery/camera/C2 in CL)
			if(C1 != C2)
				if(C1.c_tag == C2.c_tag)
					output += "<li><font color='red'>c_tag match for sec. cameras at \[[C1.x], [C1.y], [C1.z]\] ([C1.loc.loc]) and \[[C2.x], [C2.y], [C2.z]\] ([C2.loc.loc]) - c_tag is [C1.c_tag]</font></li>"
				if(C1.loc == C2.loc && C1.dir == C2.dir && C1.pixel_x == C2.pixel_x && C1.pixel_y == C2.pixel_y)
					output += "<li><font color='red'>FULLY overlapping sec. cameras at \[[C1.x], [C1.y], [C1.z]\] ([C1.loc.loc]) Networks: [C1.network] and [C2.network]</font></li>"
				if(C1.loc == C2.loc)
					output += "<li>overlapping sec. cameras at \[[C1.x], [C1.y], [C1.z]\] ([C1.loc.loc]) Networks: [C1.network] and [C2.network]</font></li>"
		var/turf/T = get_step(C1,turn(C1.dir,180))
		if(!T || !isturf(T) || !T.density )
			if(!(locate(/obj/structure/grille,T)))
				var/window_check = 0
				for(var/obj/structure/window/W in T)
					if (W.dir == turn(C1.dir,180) || (W.dir in list(NORTHEAST, SOUTHEAST, NORTHWEST, SOUTHWEST)))
						window_check = 1
						break
				if(!window_check)
					output += "<li><font color='red'>Camera not connected to wall at \[[C1.x], [C1.y], [C1.z]\] ([C1.loc.loc]) Network: [C1.network]</color></li>"

	output += "</ul>"
	usr << browse(HTML_SKELETON_TITLE("Security Camera Report", output),"window=airreport;size=1000x500")


/client/proc/intercom_view()
	set category = "Mapping"
	set name = "Intercom Range Display"

	if(intercom_range_display_status)
		intercom_range_display_status = 0
	else
		intercom_range_display_status = 1

	for(var/obj/effect/debugging/marker/M in world)
		qdel(M)

	if(intercom_range_display_status)
		for(var/obj/item/device/radio/intercom/I in world)
			for(var/turf/T in RANGE_TURFS(7, I))
				var/obj/effect/debugging/marker/F = new(T)
				if (!(F in view(7, I.loc)))
					qdel(F)


/client/proc/enable_debug_verbs()
	set category = "Debug"
	set name = "Debug verbs"

	if(check_rights(R_DEBUG))
		add_verb(src, GLOB.admin_verbs_debug_extra)


/client/proc/hide_debug_verbs()
	set category = "Debug"
	set name = "Hide Debug verbs"

	remove_verb(src, GLOB.admin_verbs_debug_extra)

/client
	var/list/testZAScolors_turfs = list()
	var/list/testZAScolors_zones = list()
	var/usedZAScolors = 0
	var/list/image/ZAScolors = list()

/client/proc/recurse_zone(datum/zone/Z, recurse_level =1)
	testZAScolors_zones += Z
	if(recurse_level > 10)
		return
	var/icon/yellow = new('icons/misc/debug_group.dmi', "yellow")

	for(var/turf/T in Z.contents)
		images += image(yellow, T, "zasdebug", LIGHTING_LAYER)
		testZAScolors_turfs += T
	for(var/datum/connection_edge/zone/edge in Z.edges)
		var/datum/zone/connected = edge.get_connected_zone(Z)
		if(connected in testZAScolors_zones)
			continue
		recurse_zone(connected,recurse_level+1)


/client/proc/testZAScolors()
	set category = "ZAS"
	set name = "Check ZAS connections"

	if(!check_rights(R_DEBUG)) return
	testZAScolors_remove()

	var/turf/location = get_turf(usr)

	if(!istype(location, /turf)) // We're in space, let's not cause runtimes.
		to_chat(usr, span_red("this debug tool cannot be used from space"))
		return

	var/icon/red = new('icons/misc/debug_group.dmi', "red")		//created here so we don't have to make thousands of these.
	var/icon/green = new('icons/misc/debug_group.dmi', "green")
	var/icon/blue = new('icons/misc/debug_group.dmi', "blue")

	if(!usedZAScolors)
		to_chat(usr, "ZAS Test Colors")
		to_chat(usr, "Green = Zone you are standing in")
		to_chat(usr, "Blue = Connected zone to the zone you are standing in")
		to_chat(usr, "Yellow = A zone that is connected but not one adjacent to your connected zone")
		to_chat(usr, "Red = Not connected")
		usedZAScolors = 1

	testZAScolors_zones += location.zone
	for(var/turf/T in location.zone.contents)
		images += image(green, T, "zasdebug", LIGHTING_LAYER)
		testZAScolors_turfs += T
	for(var/datum/connection_edge/zone/edge in location.zone.edges)
		var/datum/zone/Z = edge.get_connected_zone(location.zone)
		testZAScolors_zones += Z
		for(var/turf/T in Z.contents)
			images += image(blue, T, "zasdebug", LIGHTING_LAYER)
			testZAScolors_turfs += T
		for(var/datum/connection_edge/zone/z_edge in Z.edges)
			var/datum/zone/connected = z_edge.get_connected_zone(Z)
			if(connected in testZAScolors_zones)
				continue
			recurse_zone(connected,1)

	for(var/turf/T in RANGE_TURFS(25, location))
		if(T in testZAScolors_turfs)
			continue
		images += image(red, T, "zasdebug", LIGHTING_LAYER)
		testZAScolors_turfs += T

/client/proc/testZAScolors_remove()
	set category = "ZAS"
	set name = "Remove ZAS connection colors"

	testZAScolors_turfs.Cut()
	testZAScolors_zones.Cut()

	if(images.len)
		for(var/image/i in images)
			if(i.icon_state == "zasdebug")
				images.Remove(i)

/client/proc/count_objects_on_z_level()
	set category = "Mapping"
	set name = "Count Objects On Level"
	var/level = input("Which z-level?","Level?") as text
	if(!level) return
	var/num_level = text2num(level)
	if(!num_level) return
	if(!isnum(num_level)) return

	var/type_text = input("Which type path?","Path?") as text
	if(!type_text) return
	var/type_path = text2path(type_text)
	if(!type_path) return

	var/count = 1

	var/list/atom/atom_list = list()

	for(var/atom/A in world)
		if(istype(A,type_path))
			var/atom/B = A
			while(!(isturf(B.loc)))
				if(B && B.loc)
					B = B.loc
				else
					break
			if(B)
				if(B.z == num_level)
					count++
					atom_list += A
	/*
	var/atom/temp_atom
	for(var/i = 0; i <= (atom_list.len/10); i++)
		var/line = ""
		for(var/j = 1; j <= 10; j++)
			if(i*10+j <= atom_list.len)
				temp_atom = atom_list[i*10+j]
				line += " no.[i+10+j]@\[[temp_atom.x], [temp_atom.y], [temp_atom.z]\]; "
		world << line*/

	to_chat(world, "There are [count] objects of type [type_path] on z-level [num_level]")


/client/proc/count_objects_all()
	set category = "Mapping"
	set name = "Count Objects All"

	var/type_text = input("Which type path?","") as text
	if(!type_text) return
	var/type_path = text2path(type_text)
	if(!type_path) return

	var/count = 0

	for(var/atom/A in world)
		if(istype(A,type_path))
			count++
	/*
	var/atom/temp_atom
	for(var/i = 0; i <= (atom_list.len/10); i++)
		var/line = ""
		for(var/j = 1; j <= 10; j++)
			if(i*10+j <= atom_list.len)
				temp_atom = atom_list[i*10+j]
				line += " no.[i+10+j]@\[[temp_atom.x], [temp_atom.y], [temp_atom.z]\]; "
		world << line*/

	to_chat(world, "There are [count] objects of type [type_path] in the game world")



var/global/prevent_airgroup_regroup = 0

/client/proc/break_all_air_groups()
	set category = "Mapping"
	set name = "Break All Airgroups"

	/*prevent_airgroup_regroup = 1
	for(var/datum/air_group/AG in SSair.air_groups)
		AG.suspend_group_processing()
	message_admins("[src.ckey] used 'Break All Airgroups'")*/

/client/proc/regroup_all_air_groups()
	set category = "Mapping"
	set name = "Regroup All Airgroups Attempt"

	to_chat(usr, span_red("Proc disabled."))

	/*prevent_airgroup_regroup = 0
	for(var/datum/air_group/AG in SSair.air_groups)
		AG.check_regroup()
	message_admins("[src.ckey] used 'Regroup All Airgroups Attempt'")*/

/client/proc/kill_pipe_processing()
	set category = "Mapping"
	set name = "Kill pipe processing"

	to_chat(usr, span_red("Proc disabled."))

	/*pipe_processing_killed = !pipe_processing_killed
	if(pipe_processing_killed)
		message_admins("[src.ckey] used 'kill pipe processing', stopping all pipe processing.")
	else
		message_admins("[src.ckey] used 'kill pipe processing', restoring all pipe processing.")*/

/client/proc/kill_air_processing()
	set category = "Mapping"
	set name = "Kill air processing"

	to_chat(usr, span_red("Proc disabled."))

	/*air_processing_killed = !air_processing_killed
	if(air_processing_killed)
		message_admins("[src.ckey] used 'kill air processing', stopping all air processing.")
	else
		message_admins("[src.ckey] used 'kill air processing', restoring all air processing.")*/

//This proc is intended to detect lag problems relating to communication procs
var/global/say_disabled = 0
/client/proc/disable_communication()
	set category = "Mapping"
	set name = "Disable all communication verbs"

	to_chat(usr, span_red("Proc disabled."))

	/*say_disabled = !say_disabled
	if(say_disabled)
		message_admins("[src.ckey] used 'Disable all communication verbs', killing all communication methods.")
	else
		message_admins("[src.ckey] used 'Disable all communication verbs', restoring all communication methods.")*/

//This proc is intended to detect lag problems relating to movement
var/global/movement_disabled = 0
var/global/movement_disabled_exception //This is the client that calls the proc, so he can continue to run around to gauge any change to lag.
/client/proc/disable_movement()
	set category = "Mapping"
	set name = "Disable all movement"

	to_chat(usr, span_red("Proc disabled."))

	/*movement_disabled = !movement_disabled
	if(movement_disabled)
		message_admins("[src.ckey] used 'Disable all movement', killing all movement.")
		movement_disabled_exception = usr.ckey
	else
		message_admins("[src.ckey] used 'Disable all movement', restoring all movement.")*/
