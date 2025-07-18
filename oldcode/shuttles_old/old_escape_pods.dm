/datum/shuttle/ferry/escape_pod
	var/datum/computer/file/embedded_program/docking/simple/escape_pod/arming_controller

/datum/shuttle/ferry/escape_pod/init_docking_controllers()
	..()
	arming_controller = locate(dock_target_station)
	if(!istype(arming_controller))
		world << span_danger("warning: escape pod with station dock tag [dock_target_station] could not find it's dock target!")

	if(docking_controller)
		var/obj/machinery/embedded_controller/radio/simple_docking_controller/escape_pod/controller_master = docking_controller.master
		if(!istype(controller_master))
			world << span_danger("warning: escape pod with docking tag [docking_controller_tag] could not find it's controller master!")
		else
			controller_master.pod = src

/datum/shuttle/ferry/escape_pod/can_launch()
	if(arming_controller && !arming_controller.armed)	//must be armed
		return FALSE
	if(location)
		return FALSE	//it's a one-way trip.
	return ..()

/datum/shuttle/ferry/escape_pod/can_force()
	if (arming_controller.eject_time && world.time < arming_controller.eject_time + 50)
		return FALSE	//dont allow force launching until 5 seconds after the arming controller has reached it's countdown
	return ..()

/datum/shuttle/ferry/escape_pod/can_cancel()
	return FALSE

/datum/shuttle/ferry/escape_pod/arrived()
	emergency_shuttle.pods_arrived()

//This controller goes on the escape pod itself
/obj/machinery/embedded_controller/radio/simple_docking_controller/escape_pod
	name = "escape pod controller"
	var/datum/shuttle/ferry/escape_pod/pod

/obj/machinery/embedded_controller/radio/simple_docking_controller/escape_pod/nano_ui_interact(mob/user, ui_key = "main", datum/nanoui/ui = null, force_open = NANOUI_FOCUS)
	var/data[0]

	data = list(
		"docking_status" = docking_program.get_docking_status(),
		"override_enabled" = docking_program.override_enabled,
		"door_state" = 	docking_program.memory["door_status"]["state"],
		"door_lock" = 	docking_program.memory["door_status"]["lock"],
		"can_force" = pod.can_force() || (emergency_shuttle.pods_departed && pod.can_launch()),	//allow players to manually launch ahead of time if the shuttle leaves
		"is_armed" = pod.arming_controller.armed,
	)

	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)

	if (!ui)
		ui = new(user, src, ui_key, "escape_pod_console.tmpl", name, 470, 290)
		ui.set_initial_data(data)
		ui.open()
		ui.set_auto_update(1)

/obj/machinery/embedded_controller/radio/simple_docking_controller/escape_pod/Topic(href, href_list)
	if(..(href, href_list))
		return TRUE

	switch(href_list["command"])
		if("manual_arm")
			if(!pod.arming_controller.armed)
				pod.arming_controller.arm()
		if("force_launch")
			if (pod.can_force())
				pod.force_launch(src)
			else if (emergency_shuttle.pods_departed && pod.can_launch())	//allow players to manually launch ahead of time if the shuttle leaves
				pod.launch(src)

	return FALSE



//This controller is for the escape pod berth (station side)
/obj/machinery/embedded_controller/radio/simple_docking_controller/escape_pod_berth
	name = "escape pod berth controller"

/obj/machinery/embedded_controller/radio/simple_docking_controller/escape_pod_berth/Initialize()
	. = ..()
	docking_program = new/datum/computer/file/embedded_program/docking/simple/escape_pod(src)
	program = docking_program

/obj/machinery/embedded_controller/radio/simple_docking_controller/escape_pod_berth/nano_ui_interact(mob/user, ui_key = "main", datum/nanoui/ui = null, force_open = NANOUI_FOCUS)
	var/data[0]

	var/armed
	if (istype(docking_program, /datum/computer/file/embedded_program/docking/simple/escape_pod))
		var/datum/computer/file/embedded_program/docking/simple/escape_pod/P = docking_program
		armed = P.armed

	data = list(
		"docking_status" = docking_program.get_docking_status(),
		"override_enabled" = docking_program.override_enabled,
		"armed" = armed,
	)

	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)

	if (!ui)
		ui = new(user, src, ui_key, "escape_pod_berth_console.tmpl", name, 470, 290)
		ui.set_initial_data(data)
		ui.open()
		ui.set_auto_update(1)

/obj/machinery/embedded_controller/radio/simple_docking_controller/escape_pod_berth/emag_act(remaining_charges, mob/user)
	if (!emagged)
		user << span_notice("You emag the [src], arming the escape pod!")
		emagged = TRUE
		if (istype(docking_program, /datum/computer/file/embedded_program/docking/simple/escape_pod))
			var/datum/computer/file/embedded_program/docking/simple/escape_pod/P = docking_program
			if (!P.armed)
				P.arm()
		return TRUE

//A docking controller program for a simple door based docking port
/datum/computer/file/embedded_program/docking/simple/escape_pod
	var/armed = FALSE
	var/eject_delay = 10	//give latecomers some time to get out of the way if they don't make it onto the pod
	var/eject_time
	var/closing = FALSE

/datum/computer/file/embedded_program/docking/simple/escape_pod/proc/arm()
	if(!armed)
		armed = TRUE
		open_door()

/datum/computer/file/embedded_program/docking/simple/escape_pod/proc/unarm()
	if(armed)
		armed = FALSE

/datum/computer/file/embedded_program/docking/simple/escape_pod/receive_user_command(command)
	if (!armed)
		return
	..(command)

/datum/computer/file/embedded_program/docking/simple/escape_pod/process()
	..()
	if (eject_time && world.time >= eject_time && !closing)
		close_door()
		closing = TRUE

/datum/computer/file/embedded_program/docking/simple/escape_pod/prepare_for_docking()
	return

/datum/computer/file/embedded_program/docking/simple/escape_pod/ready_for_docking()
	return TRUE

/datum/computer/file/embedded_program/docking/simple/escape_pod/finish_docking()
	return		//don't do anything - the doors only open when the pod is armed.

/datum/computer/file/embedded_program/docking/simple/escape_pod/prepare_for_undocking()
	eject_time = world.time + eject_delay*10
