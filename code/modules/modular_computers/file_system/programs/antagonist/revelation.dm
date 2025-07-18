/datum/computer_file/program/revelation
	filename = "revelation"
	filedesc = "Revelation"
	program_icon_state = "hostile"
	program_key_state = "security_key"
	program_menu_icon = "home"
	extended_desc = "This virus can destroy the hard drive of a system it is executed on. It may be obfuscated to look like another non-malicious program. Once armed, it will destroy the system upon the next execution."
	size = 13
	requires_ntnet = 0
	available_on_ntnet = FALSE
	available_on_syndinet = TRUE
	nanomodule_path = /datum/nano_module/program/revelation/
	var/armed = FALSE

/datum/computer_file/program/revelation/run_program(mob/living/user)
	if(!..())
		return FALSE

	if(armed)
		activate()
		return FALSE

	return TRUE

/datum/computer_file/program/revelation/proc/activate()
	if(!computer)
		return

	computer.visible_message(span_notice("\The [computer]'s screen brightly flashes and loud electrical buzzing is heard."))
	computer.enabled = 0
	computer.update_icon()
	var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
	s.set_up(10, 1, computer.loc)
	s.start()

	if(computer.hard_drive)
		computer.hard_drive.damage = 100
		computer.hard_drive.stored_files.Cut()

	if(computer.cell && prob(25))
		computer.cell.charge = 0

	if(computer.tesla_link && prob(50))
		computer.tesla_link.damage = 100

/datum/computer_file/program/revelation/Topic(href, href_list)
	if(..())
		return 1
	else if(href_list["PRG_arm"])
		armed = !armed
	else if(href_list["PRG_activate"])
		activate()
	else if(href_list["PRG_obfuscate"])
		var/mob/living/user = usr
		var/newname = sanitize(input(user, "Enter new program name: "))
		if(!newname)
			return
		filedesc = newname
		for(var/datum/computer_file/program/P in ntnet_global.available_station_software + ntnet_global.available_antag_software)
			if(filedesc == P.filedesc)
				program_menu_icon = P.program_menu_icon
				break
	return 1

/datum/computer_file/program/revelation/clone()
	var/datum/computer_file/program/revelation/temp = ..()
	temp.armed = armed
	return temp

/datum/nano_module/program/revelation
	name = "Revelation Virus"

/datum/nano_module/program/revelation/nano_ui_interact(mob/user, ui_key = "main", datum/nanoui/ui = null, force_open = NANOUI_FOCUS, datum/nano_topic_state/state = GLOB.default_state)
	var/list/data = list()
	var/datum/computer_file/program/revelation/PRG = program
	if(!istype(PRG))
		return

	data = PRG.get_header_data()

	data["armed"] = PRG.armed

	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)
		ui = new(user, src, ui_key, "revelation.tmpl", "Revelation Virus", 400, 250, state = state)
		ui.auto_update_layout = 1
		ui.set_initial_data(data)
		ui.open()
		ui.set_auto_update(1)

/datum/computer_file/program/revelation/primed
	filename = "clickme"
	filedesc = "Click me!"
	available_on_syndinet = FALSE // No duplicate downloads from hacked repository
	armed = TRUE
