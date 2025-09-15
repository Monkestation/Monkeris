/obj/machinery/computer/aifixer
	name = "\improper AI system integrity restorer"
	icon = 'icons/obj/computer.dmi'
	icon_keyboard = "rd_key"
	icon_screen = "ai-fixer"
	light_color = COLOR_LIGHTING_PURPLE_MACHINERY
	circuit = /obj/item/electronics/circuitboard/aifixer
	req_one_access = list(access_robotics, access_heads)
	var/mob/living/silicon/ai/occupant
	var/active = 0

/obj/machinery/computer/aifixer/New()
	..()
	update_icon()

/obj/machinery/computer/aifixer/proc/load_ai(mob/living/silicon/ai/transfer, obj/item/device/aicard/card, mob/user)

	if(!transfer)
		return

	// Transfer over the AI.
	to_chat(transfer, "You have been uploaded to a stationary terminal. Sadly, there is no remote access from here.")
	to_chat(user, "[span_notice("Transfer successful:")] [transfer.name] ([rand(1000,9999)].exe) installed and executed successfully. Local copy has been removed.")

	transfer.loc = src
	transfer.cancel_camera()
	transfer.control_disabled = 1
	occupant = transfer

	if(card)
		card.clear()

	update_icon()

/obj/machinery/computer/aifixer/attackby(I as obj, user as mob)

	if(istype(I, /obj/item/device/aicard))

		if(stat & (NOPOWER|BROKEN))
			to_chat(user, "This terminal isn't functioning right now.")
			return

		var/obj/item/device/aicard/card = I
		var/mob/living/silicon/ai/comp_ai = locate() in src
		var/mob/living/silicon/ai/card_ai = locate() in card

		if(istype(comp_ai))
			if(active)
				to_chat(user, "[span_danger("ERROR:")] Reconstruction in progress.")
				return
			card.grab_ai(comp_ai, user)
			if(!(locate(/mob/living/silicon/ai) in src)) occupant = null
		else if(istype(card_ai))
			load_ai(card_ai,card,user)
			occupant = locate(/mob/living/silicon/ai) in src

		update_icon()
		return
	..()
	return

// AI Fixer Computer TGUI Backend - Keep existing Topic logic, add TGUI frontend
/obj/machinery/computer/aifixer/attack_hand(mob/user as mob)
	if(..())
		return
	ui_interact(user)

/obj/machinery/computer/aifixer/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AIFixer", "AI System Integrity Restorer")
		ui.open()

/obj/machinery/computer/aifixer/ui_state(mob/user)
	return GLOB.default_state

/obj/machinery/computer/aifixer/ui_data(mob/user)
	var/list/data = list()

	data["hasOccupant"] = !!occupant
	data["active"] = active

	if(occupant)
		data["aiName"] = occupant.name
		data["hardwareIntegrity"] = occupant.hardware_integrity()
		data["backupCapacitor"] = occupant.backup_capacitor()
		data["aiDead"] = occupant.stat == 2

		var/list/laws_list = list()
		for(var/datum/ai_law/law in occupant.laws.all_laws())
			laws_list += list(list(
				"index" = law.get_index(),
				"law" = law.law
			))
		data["laws"] = laws_list

	return data

/obj/machinery/computer/aifixer/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return TRUE

	// Map TGUI actions to existing Topic parameters
	var/list/href_list = list()

	switch(action)
		if("fix")
			href_list["fix"] = "1"

	// Call existing Topic method
	Topic("", href_list)
	return TRUE

/obj/machinery/computer/aifixer/Process()
	if(..())
		src.updateDialog()
		return

/obj/machinery/computer/aifixer/Topic(href, href_list)
	if(..())
		return 1
	if (href_list["fix"])
		src.active = 1
		src.overlays += image('icons/obj/computer.dmi', "ai-fixer-on")
		while (src.occupant.health < 100)
			src.occupant.adjustOxyLoss(-1)
			src.occupant.adjustFireLoss(-1)
			src.occupant.adjustToxLoss(-1)
			src.occupant.adjustBruteLoss(-1)
			src.occupant.updatehealth()
			if (src.occupant.health >= 0 && src.occupant.stat == DEAD)
				src.occupant.stat = CONSCIOUS
				src.occupant.lying = 0
				GLOB.dead_mob_list -= src.occupant
				GLOB.living_mob_list += src.occupant
				src.overlays -= image('icons/obj/computer.dmi', "ai-fixer-404")
				src.overlays += image('icons/obj/computer.dmi', "ai-fixer-full")
				src.occupant.add_ai_verbs()
			src.updateUsrDialog()
			sleep(10)
		src.active = 0
		src.overlays -= image('icons/obj/computer.dmi', "ai-fixer-on")


		src.add_fingerprint(usr)
	src.updateUsrDialog()
	return


/obj/machinery/computer/aifixer/update_icon()
	..()
	if((stat & BROKEN) || (stat & NOPOWER))
		return

	if(occupant)
		if(occupant.stat)
			overlays += image('icons/obj/computer.dmi', "ai-fixer-404")
		else
			overlays += image('icons/obj/computer.dmi', "ai-fixer-full")
	else
		overlays += image('icons/obj/computer.dmi', "ai-fixer-empty")
