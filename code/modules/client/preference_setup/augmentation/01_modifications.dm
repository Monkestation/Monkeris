/datum/preferences
	var/list/modifications_data   = list()
	var/list/modifications_colors = list()
	var/current_organ = BP_CHEST
	var/global/list/r_organs = list(BP_HEAD, BP_R_ARM, BP_CHEST, BP_R_LEG, BP_L_ARM, BP_GROIN, BP_L_LEG)
	var/global/list/l_organs = list(BP_EYES, OP_HEART, OP_KIDNEY_LEFT, OP_KIDNEY_RIGHT, OP_STOMACH, BP_BRAIN, OP_LUNGS, OP_LIVER)
	var/global/list/internal_organs = list("chest2", OP_HEART, OP_KIDNEY_LEFT, OP_KIDNEY_RIGHT, OP_STOMACH, BP_BRAIN, OP_LUNGS, OP_LIVER)

/datum/category_item/player_setup_item/augmentation/modifications
	name = "Augmentation"
	sort_order = 1

/datum/category_item/player_setup_item/augmentation/modifications/load_character(savefile/S)
	from_file(S["modifications_data"], pref.modifications_data)
	from_file(S["modifications_colors"], pref.modifications_colors)

/datum/category_item/player_setup_item/augmentation/modifications/save_character(savefile/S)
	to_file(S["modifications_data"], pref.modifications_data)
	to_file(S["modifications_colors"], pref.modifications_colors)

/datum/category_item/player_setup_item/augmentation/modifications/sanitize_character()
	if(!pref.modifications_data)
		pref.modifications_data = list()

	if(!pref.modifications_colors)
		pref.modifications_colors = list()

	for(var/tag in (pref.r_organs|pref.l_organs))
		if(!iscolor(pref.modifications_colors[tag]))
			pref.modifications_colors[tag] = "#000000"


/datum/category_item/player_setup_item/augmentation/modifications/content(mob/user)
	if(!pref.preview_icon)
		pref.update_preview_icon(naked = TRUE)

	var/dat = list()

	dat += "<style>div.block{margin: 3px 0px;padding: 4px 0px;}"
	dat += "span.color_holder_box{display: inline-block; width: 20px; height: 8px; border:1px solid #000; padding: 0px;}<"
	dat += "a.Organs_active {background: #cc5555;}</style>"

	dat +=  "<script language='javascript'> [js_byjax] function set(param, value) {window.location='?src=\ref[src];'+param+'='+value;}</script>"
	dat += "<table style='max-height:400px;height:410px; margin-left:250px; margin-right:250px'>"
	dat += "<tr style='vertical-align:top'>"
	if(pref.modifications_allowed())
		dat += "<td><div style='max-width:230px;width:230px;height:100%;overflow-y:auto;border-right:1px solid;padding:3px'>"
		dat += modifications_types[pref.current_organ]
		dat += "</div></td>"
	dat += "<td style='margin-left:10px;width-max:310px;width:310px;'>"
	dat += "<table><tr><td style='width:115px; text-align:right; margin-right:10px;'>"

	for(var/organ in pref.r_organs)
		var/datum/body_modification/mod = pref.get_modification(organ)
		var/organ_name = capitalize(GLOB.organ_tag_to_name[organ])
		var/disp_name = mod ? mod.short_name : "Nothing"
		if(!pref.modifications_allowed())
			dat += "<a class='linkOff'><b>[organ_name]</b></a>"
		else if(organ == pref.current_organ)
			dat += "<div><a class='Organs_active' href='byond://?src=\ref[src];organ=[organ]'><b>[organ_name]</b></a>"
		else
			dat += "<a href='byond://?src=\ref[src];organ=[organ]'><b>[organ_name]</b></a>"
		if(mod.hascolor)
			dat += "<a href='byond://?src=\ref[src];color=[organ]'><span class='color_holder_box' style='background-color:[pref.modifications_colors[organ]]'></span></a>"
		dat += "<br>[disp_name]<br>"

	dat += "</td><td style='width:80px;'><center>"
	var/icon/north_icon = pref.preview_north
	var/icon/south_icon = pref.preview_south
	var/icon/east_icon = pref.preview_east
	var/icon/west_icon = pref.preview_west

	if(!north_icon) north_icon = pref.preview_icon
	if(!south_icon) south_icon = pref.preview_icon
	if(!east_icon) east_icon = pref.preview_icon
	if(!west_icon) west_icon = pref.preview_icon

	dat += "<style>.icon { width: 64px; }</style>"
	dat += "<img class='icon' style='visibility: hidden'>"
	dat += "<br><center>"
	dat += "<a href='javascript:void(0)' onclick='rotatePreview(\"left\")'>&lt;&lt;</a> "
	dat += "<a href='javascript:void(0)' onclick='rotatePreview(\"right\")'>&gt;&gt;</a>"
	dat += "</center></td>"
	dat += "<td style='width:115px; text-align:left'>"

	// Dude I fucking hate putting javascript in fucking strings. fuck you, fuck this, fuck you WHYYYYYYYYY CANT THIS BE EASIER
	dat += "<script>"
	dat += "let previewIcons = {"
	dat += "'north': `[ma2html(north_icon, user)]`,"
	dat += "'south': `[ma2html(south_icon, user)]`,"
	dat += "'east': `[ma2html(east_icon, user)]`,"
	dat += "'west': `[ma2html(west_icon, user)]`"
	dat += "};"
	dat += "let curDir = localStorage.getItem('previewDirection') || 'south';"
	dat += "rotatePreview(curDir);"
	dat += "function rotatePreview(direction) {"
	dat += "  let directions = \['north', 'east', 'south', 'west'\];"
	dat += "  let index = directions.indexOf(curDir);"
	dat += "  if (direction === 'right') {"
	dat += "    index = (index + 1) % directions.length;"
	dat += "  } else if (direction === 'left') {"
	dat += "    index = (index - 1 + directions.length) % directions.length;"
	dat += "  }"
	dat += "  curDir = directions\[index\];"
	dat += "  localStorage.setItem('previewDirection', curDir);"
	dat += "  document.getElementsByClassName('icon')\[0\].outerHTML = previewIcons\[curDir\];"
	dat += "}"
	dat += "</script>"

	for(var/organ in pref.l_organs)
		var/datum/body_modification/mod = pref.get_modification(organ)
		var/organ_name = capitalize(GLOB.organ_tag_to_name[organ])
		var/disp_name = mod ? mod.short_name : "Nothing"
		if(mod.hascolor)
			dat += "<a href='byond://?src=\ref[src];color=[organ]'><span class='color_holder_box' style='background-color:[pref.modifications_colors[organ]]'></span></a>"
		if(!pref.modifications_allowed())
			dat += "<a class='linkOff'><b>[organ_name]</b></a>"
		else if(organ == pref.current_organ)
			dat += "<div><a class='Organs_active' href='byond://?src=\ref[src];organ=[organ]'><b>[organ_name]</b></a>"
		else
			dat += "<a href='byond://?src=\ref[src];organ=[organ]'><b>[organ_name]</b></a>"
		dat += "<br><div>[disp_name]</div></div>"

	dat += "</td></tr></table><hr>"

	dat += "<table cellpadding='1' cellspacing='0' width='100%'>"
	dat += "<tr align='center'>"
	var/counter = 0
	for(var/organ in pref.internal_organs)
		if(!(organ in body_modifications)) continue

		var/datum/body_modification/mod = pref.get_modification(organ)
		var/organ_name = capitalize(GLOB.organ_tag_to_name[organ])
		var/disp_name = mod.short_name
		if(organ == pref.current_organ)
			dat += "<td width='33%'><b><span style='background-color:pink'>[organ_name]</span></b>"
		else
			dat += "<td width='33%'><b>[organ_name]</b>"
		if(!pref.modifications_allowed())
			dat += "<br><a class='linkOff'>[disp_name]</a></td>"
		else
			dat += "<br><a href='byond://?src=\ref[src];organ=[organ]'>[disp_name]</a></td>"

		if(++counter >= 3)
			dat += "</tr><tr align='center'>"
			counter = 0
	dat += "</tr></table>"
	dat += "</span></div>"

	return jointext(dat,null)

/datum/preferences/proc/modifications_allowed()
	for(var/category in setup_options)
		if(!get_option(category))
			continue
		if(!get_option(category).allow_modifications)
			return FALSE
	return TRUE

/datum/preferences/proc/get_modification(organ)
	if(!modifications_allowed() || !organ || !modifications_data[organ])
		return new/datum/body_modification/none
	return modifications_data[organ]

/datum/preferences/proc/check_child_modifications(organ = BP_CHEST)
	var/list/organ_data = GLOB.organ_structure[organ]
	if(!organ_data)
		return
	var/datum/body_modification/mod = get_modification(organ)
	for(var/child_organ in organ_data["children"])
		var/datum/body_modification/child_mod = get_modification(child_organ)
		if(child_mod.nature < mod.nature)
			if(mod.is_allowed(child_organ, src))
				modifications_data[child_organ] = mod
			else
				modifications_data[child_organ] = get_default_modificaton(mod.nature)
			check_child_modifications(child_organ)
	return

/datum/category_item/player_setup_item/augmentation/modifications/OnTopic(href, list/href_list, mob/user)
	if(href_list["organ"])
		pref.current_organ = href_list["organ"]
		return TOPIC_REFRESH_UPDATE_PREVIEW

	else if(href_list["color"])
		var/organ = href_list["color"]
		if(!pref.modifications_colors[organ])
			pref.modifications_colors[organ] = "#FFFFFF"
		var/new_color = input(user, "Choose color for [GLOB.organ_tag_to_name[organ]]: ", "Character Preference", pref.modifications_colors[organ]) as color|null
		if(new_color && pref.modifications_colors[organ]!=new_color)
			pref.modifications_colors[organ] = new_color
		return TOPIC_REFRESH_UPDATE_PREVIEW

	else if(href_list["body_modification"])
		var/datum/body_modification/mod = body_modifications[href_list["body_modification"]]
		if(mod && mod.is_allowed(pref.current_organ, pref))
			pref.modifications_data[pref.current_organ] = mod
			pref.check_child_modifications(pref.current_organ)
			pref.preview_should_rebuild_organs = TRUE
		return TOPIC_REFRESH_UPDATE_PREVIEW

	else if(href_list["rotate"])
		if(href_list["rotate"] == "right")
			pref.preview_dir = turn(pref.preview_dir,-90)
		else
			pref.preview_dir = turn(pref.preview_dir,90)
		return TOPIC_REFRESH

	return ..()
