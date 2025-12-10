
/obj/machinery/chem_master
	name = "ChemMaster 3000"
	density = TRUE
	anchored = TRUE
	layer = BELOW_OBJ_LAYER
	circuit = /obj/item/electronics/circuitboard/chemmaster
	description_info = "Can be used to make pill bottles, pills,beakers or just to separate a reagent"
	description_antag = "Nothing prevents you from mis-labeling the pills."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "mixer0"
	use_power = IDLE_POWER_USE
	idle_power_usage = 20
	var/obj/item/reagent_containers/glass/beaker = null
	var/mode = 0
	var/condi = 0
	var/useramount = 30 // Last used amount
	var/pillamount = 10
	var/bottlesprite = "bottle"
	var/pillsprite = "1"
	var/client/has_sprites = list()
	var/max_pill_count = 24 //max of pills that can be made in a bottle
	var/max_pill_vol = 60 //max vol pills can have
	reagent_flags = OPENCONTAINER

/obj/machinery/chem_master/RefreshParts()
	if(!reagents)
		create_reagents(10)
	reagents.maximum_volume = 0
	for(var/obj/item/reagent_containers/glass/G in component_parts)
		reagents.maximum_volume += G.volume
		G.reagents.trans_to_holder(reagents, G.volume)

/obj/machinery/chem_master/on_deconstruction()
	for(var/obj/item/reagent_containers/glass/G in component_parts)
		var/amount = G.reagents.get_free_space()
		reagents.trans_to_holder(G, amount)
	..()

/obj/machinery/chem_master/MouseDrop_T(atom/movable/I, mob/user, src_location, over_location, src_control, over_control, params)
	if(!Adjacent(user) || !I.Adjacent(user) || user.stat)
		return ..()
	if(istype(I, /obj/item/reagent_containers) && I.is_open_container() && !beaker)
		I.forceMove(src)
		I.add_fingerprint(user)
		src.beaker = I
		to_chat(user, span_notice("You add [I] to [src]."))
		updateUsrDialog()
		icon_state = "mixer1"
		return
	. = ..()

/obj/machinery/chem_master/attackby(obj/item/B as obj, mob/user as mob)
	if(default_deconstruction(B, user))
		return

	if(default_part_replacement(B, user))
		return

	if(istype(B, /obj/item/reagent_containers/glass))

		if(src.beaker)
			to_chat(user, "A beaker is already loaded into the machine.")
			return

		if (usr.unEquip(B, src))
			src.beaker = B
			to_chat(user, "You add the beaker to the machine!")
			icon_state = "mixer1"
		updateUsrDialog()

	return

/obj/machinery/chem_master/Topic(href, href_list)
	if(..())
		return 1

	else if(href_list["close"])
		usr << browse(null, "window=chemmaster")
		usr.unset_machine()
		return

	if(beaker)
		var/datum/reagents/R = beaker.reagents
		if (href_list["analyze"])
			var/dat = ""
			if(!condi)
				if(href_list["name"] == "Blood")
					var/datum/reagent/organic/blood/G
					for(var/datum/reagent/F in R.reagent_list)
						if(F.name == href_list["name"])
							G = F
							break
					var/A = G.name
					var/B = G.data["blood_type"]
					var/C = G.data["blood_DNA"]
					dat += "Chemical infos:<BR><BR>Name:<BR>[A]<BR><BR>Description:<BR>Blood Type: [B]<br>DNA: [C]<BR><BR><BR><A href='byond://?src=\ref[src];main=1'>(Back)</A>"
				else
					dat += "Chemical infos:<BR><BR>Name:<BR>[href_list["name"]]<BR><BR>Description:<BR>[href_list["desc"]]<BR><BR><BR><A href='byond://?src=\ref[src];main=1'>(Back)</A>"
			else
				dat += "Condiment infos:<BR><BR>Name:<BR>[href_list["name"]]<BR><BR>Description:<BR>[href_list["desc"]]<BR><BR><BR><A href='byond://?src=\ref[src];main=1'>(Back)</A>"
			usr << browse(HTML_SKELETON_TITLE("[condi ? "Condimaster 3000" : "Chemmaster 3000"]", dat), "window=chem_master;size=575x400")
			return

		else if (href_list["add"])
			if(href_list["amount"])
				var/id = href_list["add"]
				var/amount = CLAMP(text2num(href_list["amount"]), 0, reagents.get_free_space())
				R.trans_id_to(src, id, amount)
				if(reagents.get_free_space() < 1)
					to_chat(usr, span_warning("The [name] is full!"))

		else if (href_list["addcustom"])
			useramount = input("Select the amount to transfer.", 30, useramount) as num
			src.Topic(null, list("amount" = "[useramount]", "add" = href_list["addcustom"]))

		else if (href_list["remove"])
			if(href_list["amount"])
				var/id = href_list["remove"]
				var/amount = CLAMP(text2num(href_list["amount"]), 0, beaker.reagents.get_free_space())
				if(mode)
					reagents.trans_id_to(beaker, id, amount)
					if(beaker.reagents.get_free_space() < 1)
						to_chat(usr, span_warning("The [name] is full!"))
				else
					reagents.remove_reagent(id, amount)


		else if (href_list["removecustom"])
			useramount = input("Select the amount to transfer.", 30, useramount) as num
			src.Topic(null, list("amount" = "[useramount]", "remove" = href_list["removecustom"]))

		else if (href_list["toggle"])
			mode = !mode

		else if (href_list["main"])
			attack_hand(usr)
			return
		else if (href_list["eject"])
			if(beaker)
				beaker:loc = src.loc
				beaker = null
				reagents.clear_reagents()
				icon_state = "mixer0"

		else if (href_list["createpill"] || href_list["createpill_multiple"])
			var/count = 0
			var/amount_per_pill = 0

			if(!reagents.total_volume) //Sanity checking.
				return
			var/create_pill_bottle = FALSE
			if (href_list["createpill_multiple"])
				if(alert("Create bottle ?","Container.","Yes","No") == "Yes")
					create_pill_bottle = TRUE
				switch(alert("How to create pills.","Choose method.","By amount","By volume"))
					if("By amount")
						count = input("Select the number of pills to make.", "Max [max_pill_count]", pillamount) as num
						if (count > max_pill_count)
							alert("Maximum supported pills amount is [max_pill_count]","Error.","Ok")
							return
						if (pillamount > max_pill_vol)
							alert("Maximum volume supported in pills is [max_pill_vol]","Error.","Ok")
							return

						count = CLAMP(count, 1, max_pill_count)
					if("By volume")
						amount_per_pill = input("Select the volume that single pill should contain.", "Max [R.total_volume]", 5) as num
						amount_per_pill = CLAMP(amount_per_pill, 1, reagents.total_volume)
						if (amount_per_pill > max_pill_vol)
							alert("Maximum volume supported in pills is [max_pill_vol]","Error.","Ok")
							return
						if ((reagents.total_volume / amount_per_pill) > max_pill_count)
							alert("Maximum supported pills amount is [max_pill_count]","Error.","Ok")
							return
					else
						return
			else
				count = 1

			if(count)
				if(reagents.total_volume < count) //Sanity checking.
					return
				amount_per_pill = reagents.total_volume/count

			if (amount_per_pill > max_pill_vol) amount_per_pill = max_pill_vol

			var/name = sanitizeSafe(input(usr,"Name:","Name your pill!","[reagents.get_master_reagent_name()] ([amount_per_pill] units)"), MAX_NAME_LEN)
			var/obj/item/storage/pill_bottle/PB
			if(create_pill_bottle)
				PB = new(get_turf(src))
				PB.name = "[PB.name] ([name])"
			while (reagents.total_volume)
				var/obj/item/reagent_containers/pill/P = new/obj/item/reagent_containers/pill(src.loc)
				if(!name) name = reagents.get_master_reagent_name()
				P.name = "[name] pill"
				P.pixel_x = rand(-7, 7) //random position
				P.pixel_y = rand(-7, 7)
				P.icon_state = "pill"+pillsprite
				reagents.trans_to_obj(P,amount_per_pill)
				if(PB)
					P.forceMove(PB)
					src.updateUsrDialog()

		else if (href_list["createbottle"])
			if(!condi)
				var/name = sanitizeSafe(input(usr,"Name:","Name your bottle!",reagents.get_master_reagent_name()), MAX_NAME_LEN)
				var/obj/item/reagent_containers/glass/bottle/P = new/obj/item/reagent_containers/glass/bottle(src.loc)
				if(!name) name = reagents.get_master_reagent_name()
				P.name = "[name] bottle"
				P.pixel_x = rand(-7, 7) //random position
				P.pixel_y = rand(-7, 7)
				P.icon_state = bottlesprite
				reagents.trans_to_obj(P,60)
				if(P.name != " bottle")		// it can be named "bottle" if you create a bottle with no reagents in buffer (it doesn't work without a space in the name, trust me)
					P.force_label = TRUE	// if this isn't the case we force a label on the sprite
				P.toggle_lid()
			else
				var/obj/item/reagent_containers/food/condiment/P = new/obj/item/reagent_containers/food/condiment(src.loc)
				reagents.trans_to_obj(P,50)
		else if(href_list["change_pill"])
			#define MAX_PILL_SPRITE 20 //max icon state of the pill sprites
			var/dat = "<table>"
			for(var/i = 1 to MAX_PILL_SPRITE)
				dat += "<tr><td><a href=\"?src=\ref[src]&pill_sprite=[i]\"><img src=\"pill[i].png\" /></a></td></tr>"
			dat += "</table>"
			usr << browse(HTML_SKELETON_TITLE("Chemmaster 3000", dat), "window=chem_master")
			return
		else if(href_list["change_bottle"])
			var/dat = "<table>"
			for(var/sprite in BOTTLE_SPRITES)
				dat += "<tr><td><a href=\"?src=\ref[src]&bottle_sprite=[sprite]\"><img src=\"[sprite].png\" /></a></td></tr>"
			dat += "</table>"
			usr << browse(HTML_SKELETON_TITLE("Chemmaster 3000", dat), "window=chem_master")
			return
		else if(href_list["pill_sprite"])
			pillsprite = href_list["pill_sprite"]
		else if(href_list["bottle_sprite"])
			bottlesprite = href_list["bottle_sprite"]

	playsound(loc, 'sound/machines/button.ogg', 100, 1)
	src.updateUsrDialog()
	return

/obj/machinery/chem_master/attack_hand(mob/user)
	if(inoperable())
		return
	ui_interact(user)

/obj/machinery/chem_master/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ChemMaster", condi ? "CondiMaster 3000" : "ChemMaster 3000")
		ui.open()

/obj/machinery/chem_master/ui_data(mob/user)
	var/list/data = list()

	data["condi"] = condi
	data["mode"] = mode
	data["hasBeaker"] = !!beaker
	data["useramount"] = useramount
	data["pillamount"] = pillamount
	data["pillsprite"] = pillsprite
	data["bottlesprite"] = bottlesprite
	data["maxPillCount"] = max_pill_count
	data["maxPillVol"] = max_pill_vol

	// Beaker contents
	if(beaker)
		var/datum/reagents/R = beaker.reagents
		data["beakerVolume"] = R.total_volume
		data["beakerMaxVolume"] = R.maximum_volume

		var/list/beaker_reagents = list()
		for(var/datum/reagent/G in R.reagent_list)
			beaker_reagents += list(list(
				"name" = G.name,
				"id" = G.id,
				"volume" = G.volume,
				"description" = G.description
			))
		data["beakerReagents"] = beaker_reagents

	// Buffer contents
	data["bufferVolume"] = reagents.total_volume
	data["bufferMaxVolume"] = reagents.maximum_volume
	data["bufferFreeSpace"] = reagents.get_free_space()

	var/list/buffer_reagents = list()
	for(var/datum/reagent/N in reagents.reagent_list)
		buffer_reagents += list(list(
			"name" = N.name,
			"id" = N.id,
			"volume" = N.volume,
			"description" = N.description
		))
	data["bufferReagents"] = buffer_reagents

	return data

/obj/machinery/chem_master/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return TRUE

	// Map TGUI actions to existing Topic parameters and call Topic
	var/list/href_list = list()

	switch(action)
		if("eject")
			href_list["eject"] = "1"
		if("toggle")
			href_list["toggle"] = "1"
		if("analyze")
			href_list["analyze"] = "1"
			href_list["name"] = params["name"]
			href_list["desc"] = params["desc"]
		if("add")
			href_list["add"] = params["id"]
			href_list["amount"] = params["amount"]
		if("addcustom")
			href_list["addcustom"] = params["id"]
		if("remove")
			href_list["remove"] = params["id"]
			href_list["amount"] = params["amount"]
		if("removecustom")
			href_list["removecustom"] = params["id"]
		if("createpill")
			href_list["createpill"] = "1"
		if("createpill_multiple")
			href_list["createpill_multiple"] = "1"
		if("createbottle")
			href_list["createbottle"] = "1"
		if("change_pill")
			href_list["change_pill"] = "1"
		if("change_bottle")
			href_list["change_bottle"] = "1"
		if("pill_sprite")
			href_list["pill_sprite"] = params["sprite"]
		if("bottle_sprite")
			href_list["bottle_sprite"] = params["sprite"]

	// Call existing Topic method with mapped parameters (I'm really really lazy okay)
	Topic("", href_list)
	return TRUE

/obj/machinery/chem_master/ui_state(mob/user)
	return GLOB.machinery_state

/obj/machinery/chem_master/condimaster
	name = "CondiMaster 3000"
	condi = 1
