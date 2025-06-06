/obj/item/organ/external/CanUseTopic(mob/user)
	if(!is_open())
		return STATUS_CLOSE

	if(owner)
		return owner.CanUseTopic(user)

	return ..()


/obj/item/organ/external/nano_ui_interact(mob/user, ui_key = "main", datum/nanoui/ui = null, force_open = NANOUI_FOCUS)
	if(is_open() && !diagnosed)
		try_autodiagnose(user)

	var/list/data = nano_ui_data(user)

	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "surgery_organ.tmpl", name, 550, 400)
		ui.add_template("_internal", "surgery_internal.tmpl")
		ui.set_initial_data(data)
		ui.open()


/obj/item/organ/external/nano_ui_data(mob/user)
	var/list/data = list()

	data["diagnosed"] = diagnosed

	// For diagnostics on an internal object
	data["viewing_internal"] = selected_internal_object ? TRUE : FALSE

	if(!istype(selected_internal_object, /obj/item/organ/internal))
		selected_internal_object = null

	if(selected_internal_object)
		var/obj/item/organ/internal/I = selected_internal_object
		data["diag_name"] = I.name
		data["diag_max_damage"] = I.max_damage
		data["diag_damage"] = I.damage
		data["diag_health"] = I.max_damage - I.damage
		data["diag_examine"] = /datum/surgery_step/examine
		data["diag_wounds"] = I.get_wounds()
		data["diag_mods"] = I.get_mods()
		data["diag_ref"] = "\ref[I]"
		data["diag_attach"] = /datum/surgery_step/attach_mod
		data["diag_remove"] = /datum/surgery_step/remove_mod
		data["diag_open"] = I.is_open()
		data["diag_stored_blood"] = I.current_blood
		data["diag_max_blood"] = I.max_blood_storage
	else
		data["status"] = get_status_data()

		data["max_damage"] = max_damage
		data["brute_dam"] = brute_dam
		data["burn_dam"] = burn_dam

		data["limb_efficiency"] = limb_efficiency
		data["occupied_volume"] = get_total_occupied_volume()
		data["max_volume"] = max_volume

		data["conditions"] = get_conditions()
		data["shrapnel"] = shrapnel_check()

		if(owner)
			data["owner_oxyloss"] = owner.getOxyLoss()
			data["owner_oxymax"] = 100 - owner.total_oxygen_req
			if(!cannot_amputate)
				data["amputate_step"] = BP_IS_ROBOTIC(src) ? /datum/surgery_step/robotic/amputate : /datum/surgery_step/amputate

		data["insert_step"] = BP_IS_ROBOTIC(src) ? /datum/surgery_step/insert_item/robotic : /datum/surgery_step/insert_item

		var/list/contents_list = list()

		for(var/obj/item/organ/internal/organ in internal_organs)
			var/list/organ_data = list()

			organ_data["name"] = organ.name
			organ_data["ref"] = "\ref[organ]"
			organ_data["open"] = organ.is_open()

			var/icon/ic = new(organ.icon, organ.icon_state)
			usr << browse_rsc(ic, "[organ.icon_state].png")	//Contvers the icon to a PNG so it can be used in the UI
			organ_data["icon_data"] = "[organ.icon_state].png"

			organ_data["damage"] = organ.damage
			organ_data["max_damage"] = organ.max_damage
			organ_data["wound_count"] = LAZYLEN(organ.GetComponents(/datum/component/internal_wound))
			if(istype(organ, /obj/item/organ/internal/vital/brain))
				var/obj/item/organ/internal/vital/brain/B = organ
				organ_data["brain_health"] = B.health
				organ_data["brain_health_max"] = initial(B.health)
			organ_data["status"] = organ.get_status_data()
			organ_data["conditions"] = organ.get_conditions()

			organ_data["stored_blood"] = organ.current_blood
			organ_data["max_blood"] = organ.max_blood_storage
			if(BP_BRAIN in organ.organ_efficiency)
				organ_data["show_oxy"] = TRUE
			organ_data["processes"] = organ.get_process_data()

			var/list/actions_list = list()
			if(can_remove_item(organ))
				actions_list.Add(list(list(
						"name" = "Extract",
						"target" = "\ref[organ]",
						"step" = BP_IS_ROBOTIC(organ) ? /datum/surgery_step/robotic/remove_item : /datum/surgery_step/remove_item
					)))
			actions_list.Add(organ.get_actions())
			organ_data["actions"] = actions_list

			contents_list.Add(list(organ_data))

		for(var/i in implants)
			var/atom/movable/implant = i
			if(QDELETED(implant))
				implants -= implant
				continue

			var/list/implant_data = list()

			implant_data["name"] = implant.name
			implant_data["ref"] = "\ref[implant]"
			implant_data["open"] = TRUE
			var/icon/ic = new(implant.icon, implant.icon_state)
			usr << browse_rsc(ic, "[implant.icon_state].png")	//Contvers the icon to a PNG so it can be used in the UI
			implant_data["icon_data"] = "[implant.icon_state].png"
			implant_data["processes"] = list()

			var/list/actions_list = list()
			if(can_remove_item(implant))
				var/list/remove_action = list(
					"name" = "Extract",
					"target" = "\ref[implant]",
					"step" = BP_IS_ROBOTIC(src) ? /datum/surgery_step/robotic/remove_item : /datum/surgery_step/remove_item
				)

				actions_list.Add(list(remove_action))

			implant_data["actions"] = actions_list

			contents_list.Add(list(implant_data))

		data["contents"] = contents_list

	return data


/obj/item/organ/external/Topic(href, href_list)
	if(..())
		return

	switch(href_list["command"])
		if("diagnose")
			if(diagnosed || try_autodiagnose(usr))
				return TRUE

			if(istype(usr, /mob/living))
				var/mob/living/user = usr
				var/target_stat = BP_IS_ROBOTIC(src) ? STAT_MEC : STAT_BIO
				var/diag_time = 70 * usr.stats.getMult(target_stat, STAT_LEVEL_EXPERT)
				var/target = get_surgery_target()

				to_chat(user, span_notice("You start examining [get_surgery_name()] for issues."))

				var/wait
				if(ismob(target))
					wait = do_mob(user, target, diag_time)
				else
					wait = do_after(user, diag_time, target, needhand = FALSE)

				if(wait)
					if(prob(100 - FAILCHANCE_VERY_EASY + usr.stats.getStat(target_stat)))
						diagnosed = TRUE
					else
						to_chat(user, span_warning("You failed to diagnose [get_surgery_name()]!"))

			return TRUE

		if("step")
			var/step_path = text2path(href_list["step"])
			if(ispath(step_path, /datum/surgery_step))
				var/obj/item/organ/target_organ = locate(href_list["organ"])

				if(!target_organ)
					target_organ = src

				target_organ.try_surgery_step(step_path, usr, target = locate(href_list["target"]))

			return TRUE

		if("remove_shrapnel")
			if(istype(usr, /mob/living))
				var/mob/living/user = usr
				var/target_stat = BP_IS_ROBOTIC(src) ? STAT_MEC : STAT_BIO
				var/removal_time = 70 * usr.stats.getMult(target_stat, STAT_LEVEL_PROF)
				var/target = get_surgery_target()
				var/obj/item/I = user.get_active_held_item()

				if(!I || !(QUALITY_CLAMPING in I.tool_qualities))
					to_chat(user, span_warning("You need a tool with [QUALITY_CLAMPING] quality"))
					return FALSE

				to_chat(user, span_notice("You start removing shrapnel from [get_surgery_name()]."))

				var/wait
				if(ismob(target))
					wait = do_mob(user, target, removal_time)
				else
					wait = do_after(user, removal_time, target, needhand = FALSE)

				if(wait)
					if(prob(100 - FAILCHANCE_NORMAL + usr.stats.getStat(target_stat)))
						for(var/obj/item/material/shard/shrapnel/shrapnel in src.implants)
							implants -= shrapnel
							shrapnel.loc = get_turf(src)
						to_chat(user, span_warning("You have removed shrapnel from [get_surgery_name()]."))
					else
						to_chat(user, span_warning("You failed to remove any shrapnel from [get_surgery_name()]!"))

			return TRUE

		if("treat_wound")
			var/mob/living/user = usr
			var/obj/item/I = user.get_active_held_item()

			if(!user || !I)
				return

			var/datum/wound = locate(href_list["wound"])
			if(wound)
				SEND_SIGNAL_OLD(wound, COMSIG_ATTACKBY, I, user)
			return TRUE

		if("view")
			selected_internal_object = locate(href_list["view"])
			return TRUE
