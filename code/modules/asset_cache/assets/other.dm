/datum/asset/simple/namespaced/common
	assets = list("padlock.png" = 'icons/ui_icons/common/padlock.png')
	parents = list("common.css" = 'html/browser/common.css')

/* === ERIS STUFF === */
/datum/asset/simple/design_icons/register()
	for(var/D in SSresearch.all_designs)
		var/datum/design/design = D

		var/filename = SANITIZE_FILENAME("design_[design.build_path].png")
		var/ui_icon_data = design.ui_icon()

		#ifdef UNIT_TESTS
		if(isnull(ui_icon_data))
			stack_trace("design [design.type] does not return a valid UI icon for itself")
			continue
		#endif

		assets[filename] = ui_icon_data
	..()

	for(var/D in SSresearch.all_designs)
		var/datum/design/design = D
		design.nano_ui_data["icon"] = SSassets.transport.get_asset_url(SANITIZE_FILENAME("design_[design.build_path].png"))
/* From sojourn station, doesnt work since we have an older autolathe.
/datum/asset/spritesheet_batched/design_icons
	name = "design_icons"
	// we have a bunch of fucking designs that don't have icons and other bullshit that we just need to ignore
	ignore_associated_icon_state_errors = TRUE

	var/design_data_loaded = FALSE

/datum/asset/spritesheet_batched/design_icons/create_spritesheets()
	for(var/datum/design/design as anything in SSresearch.all_designs)
		var/key = sanitize_css_class_name("[design.build_path]")

		var/atom/item = design.build_path
		if(!ispath(item, /atom))
			continue

		var/icon_file = initial(item.icon)
		if(!icon_file)
			continue

		var/icon_state = initial(item.icon_state)

		insert_icon(key, uni_icon(icon_file, icon_state))

// Set up design nano data after all else is done
/datum/asset/spritesheet_batched/design_icons/queued_generation()
	. = ..()
	set_design_nano_data()

/datum/asset/spritesheet_batched/design_icons/ensure_ready()
	. = ..()
	set_design_nano_data()

/datum/asset/spritesheet_batched/design_icons/proc/set_design_nano_data()
	if(!design_data_loaded)
		for(var/datum/design/design as anything in SSresearch.all_designs)
			design.nano_ui_data["icon"] = icon_class_name(sanitize_css_class_name("[design.build_path]"))
		design_data_loaded = TRUE
*/




/datum/asset/simple/tool_upgrades/register()
	for(var/obj/item/tool_upgrade/type as anything in subtypesof(/obj/item/tool_upgrade))
		var/filename = SANITIZE_FILENAME("tool_upgrade_[type].png")

		// no.
		if (initial(type.bad_type) == type)
			continue

		var/icon_file = initial(type.icon)
		var/icon_state = initial(type.icon_state)

		#ifdef UNIT_TESTS
		if(!(icon_state in icon_states(icon_file)))
			// stack_trace("tool upgrade [type] with icon '[icon_file]' missing state '[icon_state]'")
			continue
		#endif

		var/icon/I = icon(icon_file, icon_state, SOUTH)
		assets[filename] = I
	..()
