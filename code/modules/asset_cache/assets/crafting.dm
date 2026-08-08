// Below are sojourn stations nano ui spritesheets. they wont work until we edit our code for it.
/datum/asset/spritesheet_batched/tool_upgrades
	name = "tool_upgrades"

/datum/asset/spritesheet_batched/tool_upgrades/create_spritesheets()
	for(var/type in subtypesof(/obj/item/tool_upgrade))
		var/obj/item/tool_upgrade/T = type
		var/class_name = sanitize_css_class_name("[type]")
		insert_icon(class_name, uni_icon(initial(T.icon), initial(T.icon_state)))

/datum/asset/spritesheet_batched/materials
	name = "materials"

/datum/asset/spritesheet_batched/materials/create_spritesheets()
	for(var/type in subtypesof(/obj/item/stack/material) - typesof(/obj/item/stack/material/cyborg))
		var/obj/item/stack/material/M = type
		var/class_name = sanitize_css_class_name("[type]")
		var/datum/universal_icon/I = uni_icon(initial(M.icon), initial(M.icon_state))
		I.scale(32, 32)
		insert_icon(class_name, I)

/datum/asset/spritesheet/crafting
	name = "crafting"
	duplicates_allowed = TRUE

/datum/asset/spritesheet/crafting/create_spritesheets()
	for(var/name in SScraft.categories)
		for(var/datum/craft_recipe/CR in SScraft.categories[name])
			if(CR.result)
				var/sprite_name = sanitize_css_class_name("[CR.result]")
				var/icon/I = getFlatTypeIcon(CR.result)
				Insert(sprite_name, I)

			for(var/datum/craft_step/CS in CR.steps)
				if(CS.reqed_type)
					var/sprite_name = sanitize_css_class_name("[CS.reqed_type]")
					var/icon/I = getFlatTypeIcon(CS.reqed_type)
					Insert(sprite_name, I)

// here is OUR actual crafting sheets
/datum/asset/simple/materials/register()
	for(var/obj/item/stack/material/type as anything in subtypesof(/obj/item/stack/material) - typesof(/obj/item/stack/material/cyborg))
		var/filename = SANITIZE_FILENAME("[type].png")

		var/atom/item = type
		var/icon_file = initial(item.icon)
		var/icon_state = initial(item.icon_state)
		var/icon/I = icon(icon_file, icon_state, SOUTH)

		assets[filename] = I
	..()

/datum/asset/simple/craft/register()
	var/list/craftStep = list()
	for(var/name in SScraft.categories)
		for(var/datum/craft_recipe/CR in SScraft.categories[name])
			if(CR.result)
				var/filename = SANITIZE_FILENAME("[CR.result].png")

				var/atom/item = initial(CR.result)
				var/icon_file = initial(item.icon)
				var/icon_state = initial(item.icon_state)

				// eugh
				if (!icon_file)
					icon_file = ""

				#ifdef UNIT_TESTS
				if(!(icon_state in icon_states(icon_file)))
					// stack_trace("crafting result [CR] with icon '[icon_file]' missing state '[icon_state]'")
					continue
				#endif
				var/icon/I = icon(icon_file, icon_state, SOUTH)

				assets[filename] = I

			for(var/datum/craft_step/CS in CR.steps)
				if(CS.reqed_type)
					var/filename = SANITIZE_FILENAME("[CS.reqed_type].png")

					var/atom/item = initial(CS.reqed_type)
					var/icon_file = initial(item.icon)
					var/icon_state = initial(item.icon_state)
					#ifdef UNIT_TESTS
					if(!(icon_state in icon_states(icon_file)))
						// stack_trace("crafting step [CS] with icon '[icon_file]' missing state '[icon_state]'")
						continue
					#endif
					var/icon/I = icon(icon_file, icon_state, SOUTH)

					assets[filename] = I
					craftStep |= CS
	..()

	// this is fucked but crafting has a circular dept unfortunantly. could unfuck with tgui port
	for(var/datum/craft_step/CS as anything in craftStep)
		if (!CS.reqed_material && !CS.reqed_type)
			continue
		CS.iconfile = SSassets.transport.get_asset_url(CS.reqed_material ? SANITIZE_FILENAME("[material_stack_type(CS.reqed_material)].png") : null, assets[SANITIZE_FILENAME("[CS.reqed_type].png")])
		CS.make_desc() // redo it
