/datum/computer_file/program/suit_sensors
	filename = "sensormonitor"
	filedesc = "Suit Sensors Monitoring"
	nanomodule_path = /datum/nano_module/crew_monitor
	ui_header = "crew_green.gif"
	program_icon_state = "crew"
	program_key_state = "med_key"
	program_menu_icon = "heart"
	extended_desc = "This program connects to life signs monitoring system to provide basic information on crew health."
	required_access = access_moebius
	requires_ntnet = 1
	network_destination = "crew lifesigns monitoring system"
	size = 11
	var/has_alert = FALSE
	usage_flags = PROGRAM_ALL & ~PROGRAM_PDA

/datum/computer_file/program/suit_sensors/process_tick()
	..()

	var/datum/nano_module/crew_monitor/NMC = NM
	if(istype(NMC) && (NMC.has_alerts() != has_alert))
		if(!has_alert)
			program_icon_state = "crew-red"
			ui_header = "crew_red.gif"
		else
			program_icon_state = "crew"
			ui_header = "crew_green.gif"
		update_computer_icon()
		has_alert = !has_alert

	return 1

/datum/nano_module/crew_monitor
	name = "Crew monitor"
	var/list/ddata
	var/list/crew
	//for search
	var/search = ""

/datum/nano_module/crew_monitor/proc/has_alerts()
	for(var/z_level in GLOB.maps_data.station_levels)
		if(crew_repository.has_health_alert(z_level))
			return TRUE
	return FALSE

/datum/nano_module/crew_monitor/Topic(href, href_list)
	if(..()) return TOPIC_HANDLED

	if(href_list["track"])
		if(isAI(usr))
			var/mob/living/silicon/ai/AI = usr
			var/mob/living/carbon/human/H = locate(href_list["track"]) in SShumans.mob_list
			if(hassensorlevel(H, SUIT_SENSOR_TRACKING))
				AI.ai_actual_track(H)
		else
			var/datum/computer_file/program/host_program = host
			if(istype(host_program))
				var/obj/item/modular_computer/tablet/moebius/T = host_program.computer
				if(istype(T))
					var/mob/living/carbon/human/H = locate(href_list["track"]) in SShumans.mob_list
					T.target_mob = H
					if(!T.is_tracking)
						T.pinpoint()
		return TOPIC_HANDLED

	if(href_list["search"])
		var/new_search = sanitize(input("Enter the value for search for.") as null|text)
		if(!new_search || new_search == "")
			search = ""
			return TOPIC_HANDLED
		search = new_search
		return TOPIC_HANDLED

	if(href_list["mute"])
		var/mob/living/carbon/human/H = locate(href_list["mute"]) in SShumans.mob_list
		if(H)
			GLOB.ignore_health_alerts_from.Add(H.name)
			// Run that so UI updates right after button is pressed, without 5 second delay
			for(var/z_level in GLOB.maps_data.station_levels)
				// Forced update, we don't want cached entry to be returned
				crew_repository.health_data(z_level, TRUE)
		return TOPIC_HANDLED

	if(href_list["unmute"])
		var/mob/living/carbon/human/H = locate(href_list["unmute"]) in SShumans.mob_list
		if(H)
			GLOB.ignore_health_alerts_from.Remove(H.name)
			for(var/z_level in GLOB.maps_data.station_levels)
				crew_repository.health_data(z_level, TRUE)
		return TOPIC_HANDLED

/datum/nano_module/crew_monitor/nano_ui_data(mob/user)
	var/list/data = host.initial_data()
	var/datum/computer_file/program/host_program = host
	var/tracking_tablet_used = (istype(host_program) && istype(host_program.computer, /obj/item/modular_computer/tablet/moebius))
	data["can_mute"] = tracking_tablet_used
	data["can_track"] = (isAI(user) || tracking_tablet_used)
	var/list/crewmembers = list()
	for(var/z_level in GLOB.maps_data.station_levels)
		crewmembers += crew_repository.health_data(z_level)
	sortNames(crewmembers)
	//now lets get problematic crewmembers in separate list so they could be shown first
	var/list/crewmembers_problematic = list()
	var/list/crewmembers_goodbois = list()

	for(var/i = 1, i <=crewmembers.len, i++)
		var/list/entry = crewmembers[i]
		if(!search || findtext(entry["name"],search))
			if(entry["alert"] || entry["isCriminal"])
				crewmembers_problematic += list(entry)
			else
				crewmembers_goodbois += list(entry)
	data["crewmembers"] = list()
	if(crewmembers_problematic.len)
		data["crewmembers"] += crewmembers_problematic
	if(crewmembers_goodbois.len)
		data["crewmembers"] += crewmembers_goodbois
	ddata = data
	crew = crewmembers_problematic
	data["search"] = search ? search : "Search"
	return data

/datum/nano_module/crew_monitor/nano_ui_interact(mob/user, ui_key = "main", datum/nanoui/ui = null, force_open = NANOUI_FOCUS, datum/nano_topic_state/state = GLOB.default_state)
	var/list/data = nano_ui_data(user)

	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "crew_monitor.tmpl", "Crew Monitoring Computer", 1050, 800, state = state)

		// adding a template with the key "mapContent" enables the map ui functionality
		ui.add_template("mapContent", "crew_monitor_map_content.tmpl")
		// adding a template with the key "mapHeader" replaces the map header content
		ui.add_template("mapHeader", "crew_monitor_map_header.tmpl")

		ui.set_initial_data(data)
		ui.open()
		ui.set_auto_update(1)
