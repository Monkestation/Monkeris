/datum/computer_file/program/atmos_control
	filename = "atmoscontrol"
	filedesc = "Atmosphere Control"
	nanomodule_path = /datum/nano_module/atmos_control
	program_icon_state = "atmos_control"
	program_key_state = "atmos_key"
	program_menu_icon = "shuffle"
	extended_desc = "This program allows remote control of air alarms. This program can not be run on tablet computers."
	required_access = access_atmospherics
	requires_ntnet = 1
	network_destination = "atmospheric control system"
	requires_ntnet_feature = NTNET_SYSTEMCONTROL
	usage_flags = PROGRAM_LAPTOP | PROGRAM_CONSOLE
	size = 17

/datum/nano_module/atmos_control
	name = "Atmospherics Control"
	var/obj/access = new()
	var/emagged = 0
	var/ui_ref
	var/list/monitored_alarms = list()

/datum/nano_module/atmos_control/New(atmos_computer, list/req_access, list/req_one_access, monitored_alarm_ids)
	..()

	if(istype(req_access))
		access.req_access = req_access
	else if(req_access)
		log_debug("\The [src] was given an unepxected req_access: [req_access]")

	if(istype(req_one_access))
		access.req_one_access = req_one_access
	else if(req_one_access)
		log_debug("\The [src] given an unepxected req_one_access: [req_one_access]")

	if(monitored_alarm_ids)
		for(var/obj/machinery/alarm/alarm in GLOB.alarm_list)
			if(alarm.alarm_id && (alarm.alarm_id in monitored_alarm_ids))
				monitored_alarms += alarm
		// machines may not yet be ordered at this point
		monitored_alarms = dd_sortedObjectList(monitored_alarms)

/datum/nano_module/atmos_control/Topic(href, href_list)
	if(..())
		return 1

	if(href_list["alarm"])
		if(ui_ref)
			var/obj/machinery/alarm/alarm = locate(href_list["alarm"]) in (monitored_alarms.len ? monitored_alarms : GLOB.alarm_list)
			if(alarm)
				var/datum/nano_topic_state/TS = generate_state(alarm)
				alarm.nano_ui_interact(usr, master_ui = ui_ref, state = TS)
		return 1

/datum/nano_module/atmos_control/nano_ui_interact(mob/user, ui_key = "main", datum/nanoui/ui = null, force_open = NANOUI_FOCUS, master_ui = null, datum/nano_topic_state/state = GLOB.default_state)
	var/list/data = host.initial_data()
	var/alarms[0]

	// TODO: Move these to a cache, similar to cameras
	for(var/obj/machinery/alarm/alarm in (monitored_alarms.len ? monitored_alarms : GLOB.alarm_list))
		alarms[++alarms.len] = list("name" = sanitize(alarm.name), "ref"= "\ref[alarm]", "danger" = max(alarm.danger_level, alarm.alarm_area.atmosalm))
	data["alarms"] = alarms

	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "atmos_control.tmpl", src.name, 625, 625, state = state)
		if(host.update_layout()) // This is necessary to ensure the status bar remains updated along with rest of the UI.
			ui.auto_update_layout = 1
		ui.set_initial_data(data)
		ui.open()
		ui.set_auto_update(1)
	ui_ref = ui

/datum/nano_module/atmos_control/proc/generate_state(air_alarm)
	var/datum/nano_topic_state/air_alarm/state = new()
	state.atmos_control = src
	state.air_alarm = air_alarm
	return state

/datum/nano_topic_state/air_alarm
	var/datum/nano_module/atmos_control/atmos_control	= null
	var/obj/machinery/alarm/air_alarm					= null

/datum/nano_topic_state/air_alarm/can_use_topic(src_object, mob/user)
	if(has_access(user))
		return STATUS_INTERACTIVE
	return STATUS_UPDATE

/datum/nano_topic_state/air_alarm/href_list(mob/user)
	var/list/extra_href = list()
	extra_href["remote_connection"] = 1
	extra_href["remote_access"] = has_access(user)

	return extra_href

/datum/nano_topic_state/air_alarm/proc/has_access(mob/user)
	return user && (isAI(user) || atmos_control.access.allowed(user) || atmos_control.emagged || air_alarm.rcon_setting == RCON_YES || (air_alarm.alarm_area.atmosalm && air_alarm.rcon_setting == RCON_AUTO))
