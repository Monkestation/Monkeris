/datum/computer_file/program/supply
	filename = "supply"
	filedesc = "Supply Management"
	nanomodule_path = /datum/nano_module/supply
	program_icon_state = "supply"
	program_key_state = "rd_key"
	program_menu_icon = "cart"
	extended_desc = "A management tool that allows for ordering of various supplies through the facility's cargo system. Some features may require additional access."
	size = 21
	available_on_ntnet = 1
	requires_ntnet = 1

/datum/computer_file/program/supply/process_tick()
	..()
	var/datum/nano_module/supply/SNM = NM
	if(istype(SNM))
		SNM.emagged = computer_emagged

/datum/nano_module/supply
	name = "Supply Management program"
	var/screen = 1		// 0: Ordering menu, 1: Statistics 2: Shuttle control, 3: Orders menu
	var/selected_category
	var/list/category_names
	var/list/category_contents
	var/emagged = FALSE	// TODO: Implement synchronisation with modular computer framework.
	var/current_security_level

/datum/nano_module/supply/nano_ui_interact(mob/user, ui_key = "main", datum/nanoui/ui = null, force_open = NANOUI_FOCUS, state = GLOB.default_state)
	var/list/data = host.initial_data()
	var/is_admin = check_access(user, access_cargo)
	var/decl/security_state/security_state = decls_repository.get_decl(maps_data.security_state)
	if(!category_names || !category_contents || current_security_level != security_state.current_security_level)
		generate_categories()
		current_security_level = security_state.current_security_level

	data["is_admin"] = is_admin
	data["screen"] = screen
	data["credits"] = "[SSsupply.points]"
	data["currency"] = maps_data.supply_currency_name
	data["currency_short"] = maps_data.supply_currency_name_short
	switch(screen)
		if(1)// Main ordering menu
			data["categories"] = category_names
			if(selected_category)
				data["category"] = selected_category
				data["possible_purchases"] = category_contents[selected_category]

		if(2)// Statistics screen with credit overview
			var/list/point_breakdown = list()
			for(var/tag in SSsupply.point_source_descriptions)
				var/entry = list()
				entry["desc"] = SSsupply.point_source_descriptions[tag]
				entry["points"] = SSsupply.point_sources[tag] || 0
				point_breakdown += list(entry) //Make a list of lists, don't flatten
			data["point_breakdown"] = point_breakdown
			data["can_print"] = can_print()

		if(3)// Shuttle monitoring and control
			var/datum/shuttle/autodock/ferry/supply/shuttle = SSsupply.shuttle
			data["shuttle_name"] = shuttle.name
			if(istype(shuttle))
				data["shuttle_location"] = shuttle.at_station() ? maps_data.name : "Remote location"
			else
				data["shuttle_location"] = "No Connection"
			data["shuttle_status"] = get_shuttle_status()
			data["shuttle_can_control"] = shuttle.can_launch()


		if(4)// Order processing
			var/list/cart[0]
			var/list/requests[0]
			var/list/done[0]
			for(var/datum/supply_order/SO in SSsupply.shoppinglist)
				cart.Add(order_to_nanoui(SO))
			for(var/datum/supply_order/SO in SSsupply.requestlist)
				requests.Add(order_to_nanoui(SO))
			for(var/datum/supply_order/SO in SSsupply.donelist)
				done.Add(order_to_nanoui(SO))
			data["cart"] = cart
			data["requests"] = requests
			data["done"] = done

	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)
		ui = new(user, src, ui_key, "supply.tmpl", name, 1050, 800, state = state)
		ui.set_auto_update(1)
		ui.set_initial_data(data)
		ui.open()

/datum/nano_module/supply/Topic(href, href_list)
	var/mob/user = usr
	if(..())
		return 1

	if(href_list["select_category"])
		selected_category = href_list["select_category"]
		return 1

	if(href_list["set_screen"])
		screen = text2num(href_list["set_screen"])
		return 1

	if(href_list["order"])
		var/decl/hierarchy/supply_pack/P = locate(href_list["order"]) in SSsupply.master_supply_list
		if(!istype(P))
			return 1

		if(P.hidden && !emagged)
			return 1

		var/reason = sanitize(input(user,"Reason:","Why do you require this item?","") as null|text,,0)
		if(!reason)
			return 1

		var/idname = "*None Provided*"
		var/idrank = "*None Provided*"
		if(ishuman(user))
			var/mob/living/carbon/human/H = user
			idname = H.get_authentification_name()
			idrank = H.get_assignment()
		else if(issilicon(user))
			idname = user.real_name

		SSsupply.ordernum++

		var/datum/supply_order/O = new /datum/supply_order()
		O.ordernum = SSsupply.ordernum
		O.object = P
		O.orderedby = idname
		O.reason = reason
		O.orderedrank = idrank
		O.comment = "#[O.ordernum]"
		SSsupply.requestlist += O

		if(can_print() && alert(user, "Would you like to print a confirmation receipt?", "Print receipt?", "Yes", "No") == "Yes")
			print_order(O, user)
		return 1

	if(href_list["print_summary"])
		if(!can_print())
			return
		print_summary(user)

	// Items requiring cargo access go below this entry. Other items go above.
	if(!check_access(access_cargo))
		return 1

	if(href_list["launch_shuttle"])
		var/datum/shuttle/autodock/ferry/supply/shuttle = SSsupply.shuttle
		if(!shuttle)
			to_chat(user, span_warning("Error connecting to the shuttle."))
			return
		if(shuttle.at_station())
			if (shuttle.forbidden_atoms_check())
				to_chat(usr, span_warning("For safety reasons the automated supply shuttle cannot transport live organisms, classified nuclear weaponry or homing beacons."))
			else
				shuttle.launch(user)
		else
			shuttle.launch(user)
			var/datum/radio_frequency/frequency = radio_controller.return_frequency(1435)
			if(!frequency)
				return

			var/datum/signal/status_signal = new
			status_signal.source = src
			status_signal.transmission_method = 1
			status_signal.data["command"] = "supply"
			frequency.post_signal(src, status_signal)
		return 1

	if(href_list["approve_order"])
		var/id = text2num(href_list["approve_order"])
		for(var/datum/supply_order/SO in SSsupply.requestlist)
			if(SO.ordernum != id)
				continue
			if(SO.object.cost > SSsupply.points)
				to_chat(usr, span_warning("Not enough points to purchase \the [SO.object.name]!"))
				return 1
			SSsupply.requestlist -= SO
			SSsupply.shoppinglist += SO
			SSsupply.points -= SO.object.cost
			break
		return 1

	if(href_list["deny_order"])
		var/id = text2num(href_list["deny_order"])
		for(var/datum/supply_order/SO in SSsupply.requestlist)
			if(SO.ordernum == id)
				SSsupply.requestlist -= SO
				break
		return 1

	if(href_list["cancel_order"])
		var/id = text2num(href_list["cancel_order"])
		for(var/datum/supply_order/SO in SSsupply.shoppinglist)
			if(SO.ordernum == id)
				SSsupply.shoppinglist -= SO
				SSsupply.points += SO.object.cost
				break
		return 1

	if(href_list["delete_order"])
		var/id = text2num(href_list["delete_order"])
		for(var/datum/supply_order/SO in SSsupply.donelist)
			if(SO.ordernum == id)
				SSsupply.donelist -= SO
				break
		return 1

/datum/nano_module/supply/proc/generate_categories()
	category_names = list()
	category_contents = list()
	var/decl/hierarchy/supply_pack/root = decls_repository.get_decl(/decl/hierarchy/supply_pack)
	for(var/decl/hierarchy/supply_pack/sp in root.children)
		if(!sp.is_category())
			continue // No children
		category_names.Add(sp.name)
		var/list/category[0]
		for(var/decl/hierarchy/supply_pack/spc in sp.get_descendents())
			if((spc.hidden || spc.contraband || !spc.sec_available()) && !emagged)
				continue
			category.Add(list(list(
				"name" = spc.name,
				"cost" = spc.cost,
				"ref" = "\ref[spc]"
			)))
		category_contents[sp.name] = category

/datum/nano_module/supply/proc/get_shuttle_status()
	var/datum/shuttle/autodock/ferry/supply/shuttle = SSsupply.shuttle
	if(!istype(shuttle))
		return "No Connection"

	if(shuttle.has_arrive_time())
		return "In transit ([shuttle.eta_seconds()] s)"

	if (shuttle.can_launch())
		return "Docked"
	return "Docking/Undocking"

/datum/nano_module/supply/proc/order_to_nanoui(datum/supply_order/SO)
	return list(list(
		"id" = SO.ordernum,
		"object" = SO.object.name,
		"orderer" = SO.orderedby,
		"cost" = SO.object.cost,
		"reason" = SO.reason
		))

/datum/nano_module/supply/proc/can_print()
	var/obj/item/modular_computer/MC = nano_host()
	if(!istype(MC) || !istype(MC.nano_printer))
		return 0
	return 1

/datum/nano_module/supply/proc/print_order(datum/supply_order/O, mob/user)
	if(!O)
		return

	var/t = ""
	t += "<h3>[maps_data.station_name()] Supply Requisition Reciept</h3><hr>"
	t += "INDEX: #[O.ordernum]<br>"
	t += "REQUESTED BY: [O.orderedby]<br>"
	t += "RANK: [O.orderedrank]<br>"
	t += "REASON: [O.reason]<br>"
	t += "SUPPLY CRATE TYPE: [O.object.name]<br>"
	t += "ACCESS RESTRICTION: [get_access_desc(O.object.access)]<br>"
	t += "CONTENTS:<br>"
	t += O.object.manifest
	t += "<hr>"
	print_text(t, user)

/datum/nano_module/supply/proc/print_summary(mob/user)
	var/t = ""
	t += "<center><BR><b><large>[maps_data.station_name()]</large></b><BR><i>[station_date]</i><BR><i>Export overview<field></i></center><hr>"
	for(var/source in SSsupply.point_source_descriptions)
		t += "[SSsupply.point_source_descriptions[source]]: [SSsupply.point_sources[source] || 0]<br>"
	print_text(t, user)
