#define TOPIC_UPDATE_PREVIEW 4
#define TOPIC_REFRESH_UPDATE_PREVIEW (TOPIC_REFRESH|TOPIC_UPDATE_PREVIEW)

var/const/CHARACTER_PREFERENCE_INPUT_TITLE = "Character Preference"

/datum/category_group/player_setup_category/physical_preferences
	name = "General"
	sort_order = 1
	update_preview_icon = TRUE
	category_item_type = /datum/category_item/player_setup_item/physical

/datum/category_group/player_setup_category/augmentation
	name = "Augmentation"
	sort_order = 2
	update_preview_icon = TRUE
	category_item_type = /datum/category_item/player_setup_item/augmentation

/datum/category_group/player_setup_category/background_preferences
	name = "Background"
	sort_order = 3
	category_item_type = /datum/category_item/player_setup_item/background

/datum/category_group/player_setup_category/background_preferences/content(mob/user)
	. = ""
	for(var/datum/category_item/player_setup_item/PI in items)
		. += "[PI.content(user)]<br>"

/datum/category_group/player_setup_category/occupation_preferences
	name = "Occupation"
	sort_order = 4
	category_item_type = /datum/category_item/player_setup_item/occupation

/datum/category_group/player_setup_category/appearance_preferences
	name = "Roles"
	sort_order = 5
	category_item_type = /datum/category_item/player_setup_item/antagonism

/datum/category_group/player_setup_category/relations_preferences
	name = "Matchmaking"
	sort_order = 6
	category_item_type = /datum/category_item/player_setup_item/relations

/datum/category_group/player_setup_category/loadout_preferences
	name = "Loadout"
	update_preview_icon = TRUE
	sort_order = 7
	category_item_type = /datum/category_item/player_setup_item/loadout

/datum/category_group/player_setup_category/global_preferences
	name = "Global"
	sort_order = 8
	category_item_type = /datum/category_item/player_setup_item/player_global

/datum/category_group/player_setup_category/law_pref
	name = "Laws"
	sort_order = 9
	category_item_type = /datum/category_item/player_setup_item/law_pref


/****************************
* Category Collection Setup *
****************************/
/datum/category_collection/player_setup_collection
	category_group_type = /datum/category_group/player_setup_category
	var/datum/preferences/preferences
	var/datum/category_group/player_setup_category/selected_category = null

/datum/category_collection/player_setup_collection/New(datum/preferences/preferences)
	src.preferences = preferences
	..()
	selected_category = categories[1]

/datum/category_collection/player_setup_collection/Destroy()
	preferences = null
	selected_category = null
	return ..()

/datum/category_collection/player_setup_collection/proc/sanitize_setup()
	for(var/datum/category_group/player_setup_category/PS in categories)
		PS.sanitize_setup()

/datum/category_collection/player_setup_collection/proc/load_character(savefile/S)
	for(var/datum/category_group/player_setup_category/PS in categories)
		PS.load_character(S)

/datum/category_collection/player_setup_collection/proc/save_character(savefile/S)
	for(var/datum/category_group/player_setup_category/PS in categories)
		PS.save_character(S)

/datum/category_collection/player_setup_collection/proc/load_preferences(savefile/S)
	for(var/datum/category_group/player_setup_category/PS in categories)
		PS.load_preferences(S)

/datum/category_collection/player_setup_collection/proc/save_preferences(savefile/S)
	for(var/datum/category_group/player_setup_category/PS in categories)
		PS.save_preferences(S)

/datum/category_collection/player_setup_collection/proc/update_setup(savefile/preferences, savefile/character)
	for(var/datum/category_group/player_setup_category/PS in categories)
		. = PS.update_setup(preferences, character) || .

/datum/category_collection/player_setup_collection/proc/header()
	var/dat = ""
	for(var/datum/category_group/player_setup_category/PS in categories)
		if(PS == selected_category)
			dat += "[PS.name] "	// TODO: Check how to properly mark a href/button selected in a classic browser window
		else
			dat += "<a href='byond://?src=\ref[src];category=\ref[PS]'>[PS.name]</a> "
	return dat

/datum/category_collection/player_setup_collection/proc/content(mob/user)
	if(selected_category)
		return selected_category.content(user)

/datum/category_collection/player_setup_collection/Topic(href,list/href_list)
	if(..())
		return 1
	var/mob/user = usr
	if(!user.client)
		return 1

	if(href_list["category"])
		var/category = locate(href_list["category"])
		if(category && (category in categories))
			selected_category = category
			if(selected_category.update_preview_icon)
				preferences.update_preview_icon(naked = istype(selected_category, /datum/category_group/player_setup_category/augmentation))
		. = 1

	if(.)
		user.client.prefs.ShowChoices(user)

/**************************
* Category Category Setup *
**************************/
/datum/category_group/player_setup_category
	var/sort_order = 0
	var/update_preview_icon = FALSE

/datum/category_group/player_setup_category/dd_SortValue()
	return sort_order

/datum/category_group/player_setup_category/proc/sanitize_setup()
	for(var/datum/category_item/player_setup_item/PI in items)
		PI.sanitize_preferences()
	for(var/datum/category_item/player_setup_item/PI in items)
		PI.sanitize_character()

/datum/category_group/player_setup_category/proc/load_character(savefile/S)
	for(var/datum/category_item/player_setup_item/PI in items)
		PI.load_character(S)

/datum/category_group/player_setup_category/proc/save_character(savefile/S)
	// Sanitize all data, then save it
	for(var/datum/category_item/player_setup_item/PI in items)
		PI.sanitize_character()
	for(var/datum/category_item/player_setup_item/PI in items)
		PI.save_character(S)

/datum/category_group/player_setup_category/proc/load_preferences(savefile/S)
	for(var/datum/category_item/player_setup_item/PI in items)
		PI.load_preferences(S)

/datum/category_group/player_setup_category/proc/save_preferences(savefile/S)
	for(var/datum/category_item/player_setup_item/PI in items)
		PI.sanitize_preferences()
	for(var/datum/category_item/player_setup_item/PI in items)
		PI.save_preferences(S)

/datum/category_group/player_setup_category/proc/update_setup(savefile/preferences, savefile/character)
	for(var/datum/category_item/player_setup_item/PI in items)
		. = PI.update_setup(preferences, character) || .

/datum/category_group/player_setup_category/proc/content(mob/user)
	. = "<table style='width:100%'><tr style='vertical-align:top'><td style='width:50%'>"
	var/current = 0
	var/halfway = items.len / 2
	for(var/datum/category_item/player_setup_item/PI in items)
		if(halfway && current++ >= halfway)
			halfway = 0
			. += "</td><td></td><td style='width:50%'>"
		. += "[PI.content(user)]<br>"
	. += "</td></tr></table>"

/datum/category_group/player_setup_category/occupation_preferences/content(mob/user)
	for(var/datum/category_item/player_setup_item/PI in items)
		. += "[PI.content(user)]<br>"

/**********************
* Category Item Setup *
**********************/
/datum/category_item/player_setup_item
	var/sort_order = 0
	var/datum/preferences/pref

/datum/category_item/player_setup_item/New()
	..()
	var/datum/category_collection/player_setup_collection/psc = category.collection
	pref = psc.preferences

	if(!isnull(option_category))
		if(!istext(option_category) || !SScharacter_setup.setup_options[option_category])
			warning("Wrong initial option_category: [option_category]")
			option_category = null
		else
			option_category = SScharacter_setup.setup_options[option_category]

/datum/category_item/player_setup_item/Destroy()
	pref = null
	return ..()

/datum/category_item/player_setup_item/dd_SortValue()
	return sort_order

/*
* Called when the item is asked to load per character settings
*/
/datum/category_item/player_setup_item/proc/load_character(savefile/S)
	if(option_category)
		pref.load_option(S, option_category)

/*
* Called when the item is asked to save per character settings
*/
/datum/category_item/player_setup_item/proc/save_character(savefile/S)
	if(option_category)
		pref.save_option(S, option_category)

/*
* Called when the item is asked to load user/global settings
*/
/datum/category_item/player_setup_item/proc/load_preferences(savefile/S)
	return

/*
* Called when the item is asked to save user/global settings
*/
/datum/category_item/player_setup_item/proc/save_preferences(savefile/S)
	return

/*
* Called when the item is asked to update user/global settings
*/
/datum/category_item/player_setup_item/proc/update_setup(savefile/preferences, savefile/character)
	return 0

/datum/category_item/player_setup_item/proc/content()
	return

/datum/category_item/player_setup_item/proc/sanitize_character()
	if(option_category)
		pref.sanitize_option(option_category)
	return

/datum/category_item/player_setup_item/proc/sanitize_preferences()
	return

/datum/category_item/player_setup_item/Topic(href,list/href_list)
	if(..())
		return 1
	var/mob/pref_mob = preference_mob()
	if(!pref_mob || !pref_mob.client)
		return 1

	. = OnTopic(href, href_list, usr)

	// The user might have joined the game or otherwise had a change of mob while tweaking their preferences.
	pref_mob = preference_mob()
	if(!pref_mob || !pref_mob.client)
		return 1

	if(. & TOPIC_UPDATE_PREVIEW)
		pref_mob.client.prefs.preview_icon = null
	if(. & TOPIC_REFRESH)
		pref_mob.client.prefs.ShowChoices(usr)

/datum/category_item/player_setup_item/CanUseTopic(mob/user)
	return 1

/datum/category_item/player_setup_item/proc/OnTopic(href,list/href_list, mob/user)
	return TOPIC_NOACTION

/datum/category_item/player_setup_item/proc/preference_mob()
	if(!pref.client)
		for(var/client/C)
			if(C.ckey == pref.client_ckey)
				pref.client = C
				break

	//lets try again after 1 second
	//for some reason it doesnt find client on login
	spawn(10)
		if(!pref.client)
			for(var/client/C)
				if(C.ckey == pref.client_ckey)
					pref.client = C
					break
	if(pref.client)
		return pref.client.mob
/*
/datum/category_item/player_setup_item/proc/preference_species()
	return GLOB.all_species[pref.species] || GLOB.all_species[SPECIES_HUMAN]
*/
