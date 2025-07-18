/datum/computer_file/program/camera_monitor/hacked
	filename = "camcrypt"
	filedesc = "Camera Decryption Tool"
	nanomodule_path = /datum/nano_module/camera_monitor/hacked
	program_icon_state = "hostile"
	program_key_state = "security_key"
	program_menu_icon = "zoomin"
	extended_desc = "This very advanced piece of software uses adaptive programming and a large database of cipherkeys to bypass most encryptions used on camera networks. Be warned that the system administrator may notice this."
	size = 73 // Very large, a price for bypassing ID checks completely.
	available_on_ntnet = 0
	available_on_syndinet = 1

/datum/computer_file/program/camera_monitor/hacked/process_tick()
	..()
	if(program_state != PROGRAM_STATE_ACTIVE) // Background programs won't trigger alarms.
		return

	var/datum/nano_module/camera_monitor/hacked/HNM = NM

	// The program is active and connected to one of the station's networks. Has a very small chance to trigger IDS alarm every tick.
	if(HNM && HNM.current_network && (HNM.current_network in station_networks) && prob((STAT_LEVEL_MAX - operator_skill) * 0.05))
		if(ntnet_global.intrusion_detection_enabled)
			ntnet_global.add_log("IDS WARNING - Unauthorised access detected to camera network [HNM.current_network] by device with NID [computer.network_card.get_network_tag()]")
			ntnet_global.intrusion_detection_alarm = 1

/datum/computer_file/program/camera_monitor/hacked/nano_ui_interact(mob/user)
	operator_skill = get_operator_skill(user, STAT_COG)
	. = ..() // Actual work done by nanomodule's parent.

/datum/nano_module/camera_monitor/hacked
	name = "Hacked Camera Monitoring Program"
	available_to_ai = FALSE

/datum/nano_module/camera_monitor/hacked/can_access_network(mob/user, network_access)
	return 1

// The hacked variant has access to all commonly used networks.
/datum/nano_module/camera_monitor/hacked/modify_networks_list(list/networks)
	networks.Add(list(list("tag" = NETWORK_MERCENARY, "has_access" = 1)))
	//networks.Add(list(list("tag" = NETWORK_ERT, "has_access" = 1)))	//TODO: replace this
	networks.Add(list(list("tag" = NETWORK_CRESCENT, "has_access" = 1)))
	return networks
