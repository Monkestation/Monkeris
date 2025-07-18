/*
	The global hud:
	Uses the same visual objects for all players.
*/

// Initialized in ticker.dm, see proc/setup_huds()
var/datum/global_hud/global_hud
var/list/global_huds

/*
/datum/hud/var/obj/screen/grab_intent
/datum/hud/var/obj/screen/hurt_intent
/datum/hud/var/obj/screen/disarm_intent
/datum/hud/var/obj/screen/help_intent
*/
/datum/global_hud
	var/obj/screen/druggy
	var/obj/screen/blurry
	var/list/lightMask
	var/list/vimpaired
	var/list/darkMask
	var/obj/screen/nvg
	var/obj/screen/thermal
	var/obj/screen/meson
	var/obj/screen/science
	var/obj/screen/holomap

/datum/global_hud/New()
	//420erryday psychedellic colours screen overlay for when you are high
	druggy = new /obj/screen/fullscreen/tile("druggy")

	//that white blurry effect you get when you eyes are damaged
	blurry = new /obj/screen/fullscreen/tile("blurry")

	nvg = new /obj/screen/fullscreen("nvg_hud")
	nvg.plane = LIGHTING_PLANE
	thermal = new /obj/screen/fullscreen("thermal_hud")
	meson = new /obj/screen/fullscreen("meson_hud")
	science = new /obj/screen/fullscreen("science_hud")

	// The holomap screen object is actually totally invisible.
	// Station maps work by setting it as an images location before sending to client, not
	// actually changing the icon or icon state of the screen object itself!
	// Why do they work this way? I don't know really, that is how /vg designed them, but since they DO
	// work this way, we can take advantage of their immutability by making them part of
	// the global_hud (something we have and /vg doesn't) instead of an instance per mob.
	holomap = new /obj/screen/fullscreen()
	holomap.name = "holomap"
	holomap.icon = null

	//that nasty looking dither you  get when you're short-sighted

	lightMask = newlist(
		/obj/screen{icon_state = "dither50"; screen_loc = "WEST,SOUTH to EAST,SOUTH+1"},
		/obj/screen{icon_state = "dither50"; screen_loc = "WEST,SOUTH+2 to WEST+1,NORTH"},
		/obj/screen{icon_state = "dither50"; screen_loc = "EAST-1,SOUTH+2 to EAST,NORTH"},
		/obj/screen{icon_state = "dither50"; screen_loc = "WEST+2,NORTH-1 to EAST-2,NORTH"},

		/obj/screen{icon_state = "dither50"; screen_loc = "WEST,SOUTH:-32 to EAST,SOUTH"},
		/obj/screen{icon_state = "dither50"; screen_loc = "EAST:32,SOUTH to EAST,NORTH"},
		/obj/screen{icon_state = "dither50"; screen_loc = "EAST:32,SOUTH:-32"},
	)

	vimpaired = newlist(
		/obj/screen{icon_state = "dither50"; screen_loc = "WEST,SOUTH to WEST+4,NORTH"},
		/obj/screen{icon_state = "dither50"; screen_loc = "WEST+4,SOUTH to EAST-5,SOUTH+4"},
		/obj/screen{icon_state = "dither50"; screen_loc = "WEST+5,NORTH-4 to EAST-5,NORTH"},
		/obj/screen{icon_state = "dither50"; screen_loc = "EAST-4,SOUTH to EAST,NORTH"},

		/obj/screen{icon_state = "dither50"; screen_loc = "WEST,SOUTH:-32 to EAST,SOUTH"},
		/obj/screen{icon_state = "dither50"; screen_loc = "EAST:32,SOUTH to EAST,NORTH"},
		/obj/screen{icon_state = "dither50"; screen_loc = "EAST:32,SOUTH:-32"},
	)

	//welding mask overlay black/dither
	darkMask = newlist(
		/obj/screen{icon_state = "dither50"; screen_loc = "WEST+2,SOUTH+2 to WEST+4,NORTH-2"},
		/obj/screen{icon_state = "dither50"; screen_loc = "WEST+4,SOUTH+2 to EAST-5,SOUTH+4"},
		/obj/screen{icon_state = "dither50"; screen_loc = "WEST+5,NORTH-4 to EAST-5,NORTH-2"},
		/obj/screen{icon_state = "dither50"; screen_loc = "EAST-4,SOUTH+2 to EAST-2,NORTH-2"},

		/obj/screen{icon_state = "black"; screen_loc = "WEST,SOUTH to EAST,SOUTH+1"},
		/obj/screen{icon_state = "black"; screen_loc = "WEST,SOUTH+2 to WEST+1,NORTH"},
		/obj/screen{icon_state = "black"; screen_loc = "EAST-1,SOUTH+2 to EAST,NORTH"},
		/obj/screen{icon_state = "black"; screen_loc = "WEST+2,NORTH-1 to EAST-2,NORTH"},

		/obj/screen{icon_state = "black"; screen_loc = "WEST,SOUTH:-32 to EAST,SOUTH"},
		/obj/screen{icon_state = "black"; screen_loc = "EAST:32,SOUTH to EAST,NORTH"},
		/obj/screen{icon_state = "black"; screen_loc = "EAST:32,SOUTH:-32"},
	)

	for(var/obj/screen/O in (lightMask + vimpaired + darkMask))
		O.layer = FULLSCREEN_LAYER
		O.plane = FULLSCREEN_PLANE
		O.mouse_opacity = MOUSE_OPACITY_TRANSPARENT


/*
	The hud datum
	Used to show and hide huds for all the different mob types,
	including inventories and item quick actions.
*/

/*/datum/hud
	var/mob/mymob

	var/hud_shown = 1			//Used for the HUD toggle (F12)
	var/inventory_shown = 1		//the inventory
	var/show_intent_icons = 0
	var/hotkey_ui_hidden = 0	//This is to hide the buttons that can be used via hotkeys. (hotkeybuttons list of buttons)

	var/obj/screen/lingchemdisplay
	var/obj/screen/blobpwrdisplay
	var/obj/screen/blobhealthdisplay
	var/obj/screen/r_hand_hud_object
	var/obj/screen/l_hand_hud_object
	var/obj/screen/action_intent
	var/obj/screen/move_intent

	var/list/adding
	var/list/other
	var/list/obj/screen/hotkeybuttons

	var/obj/screen/movable/action_button/hide_toggle/hide_actions_toggle
	var/action_buttons_hidden = 0

/datum/hud/New(mob/owner)
	mymob = owner
	instantiate()
	..()

/datum/hud/Destroy()
	..()
	grab_intent = null
	hurt_intent = null
	disarm_intent = null
	help_intent = null
	lingchemdisplay = null
	blobpwrdisplay = null
	blobhealthdisplay = null
	r_hand_hud_object = null
	l_hand_hud_object = null
	action_intent = null
	move_intent = null
	adding = null
	other = null
	hotkeybuttons = null
//	item_action_list = null // ?
	mymob = null

/datum/hud/proc/hidden_inventory_update()
	if(!mymob) return
	if(ishuman(mymob))
		var/mob/living/carbon/human/H = mymob
		for(var/gear_slot in H.species.hud.gear)
			var/list/hud_data = H.species.hud.gear[gear_slot]
			if(inventory_shown && hud_shown)
				switch(hud_data["slot"])
					if(slot_head)
						if(H.head)      H.head.screen_loc =      hud_data["loc"]
					if(slot_shoes)
						if(H.shoes)     H.shoes.screen_loc =     hud_data["loc"]
					if(slot_l_ear)
						if(H.l_ear)     H.l_ear.screen_loc =     hud_data["loc"]
					if(slot_r_ear)
						if(H.r_ear)     H.r_ear.screen_loc =     hud_data["loc"]
					if(slot_gloves)
						if(H.gloves)    H.gloves.screen_loc =    hud_data["loc"]
					if(slot_glasses)
						if(H.glasses)   H.glasses.screen_loc =   hud_data["loc"]
					if(slot_w_uniform)
						if(H.w_uniform) H.w_uniform.screen_loc = hud_data["loc"]
					if(slot_wear_suit)
						if(H.wear_suit) H.wear_suit.screen_loc = hud_data["loc"]
					if(slot_wear_mask)
						if(H.wear_mask) H.wear_mask.screen_loc = hud_data["loc"]
			else
				switch(hud_data["slot"])
					if(slot_head)
						if(H.head)      H.head.screen_loc =      null
					if(slot_shoes)
						if(H.shoes)     H.shoes.screen_loc =     null
					if(slot_l_ear)
						if(H.l_ear)     H.l_ear.screen_loc =     null
					if(slot_r_ear)
						if(H.r_ear)     H.r_ear.screen_loc =     null
					if(slot_gloves)
						if(H.gloves)    H.gloves.screen_loc =    null
					if(slot_glasses)
						if(H.glasses)   H.glasses.screen_loc =   null
					if(slot_w_uniform)
						if(H.w_uniform) H.w_uniform.screen_loc = null
					if(slot_wear_suit)
						if(H.wear_suit) H.wear_suit.screen_loc = null
					if(slot_wear_mask)
						if(H.wear_mask) H.wear_mask.screen_loc = null


/datum/hud/proc/persistant_inventory_update()
	if(!mymob)
		return

	if(ishuman(mymob))
		var/mob/living/carbon/human/H = mymob
		for(var/gear_slot in H.species.hud.gear)
			var/list/hud_data = H.species.hud.gear[gear_slot]
			if(hud_shown)
				switch(hud_data["slot"])
					if(slot_s_store)
						if(H.s_store) H.s_store.screen_loc = hud_data["loc"]
					if(slot_wear_id)
						if(H.wear_id) H.wear_id.screen_loc = hud_data["loc"]
					if(slot_belt)
						if(H.belt)    H.belt.screen_loc =    hud_data["loc"]
					if(slot_back)
						if(H.back)    H.back.screen_loc =    hud_data["loc"]
					if(slot_l_store)
						if(H.l_store) H.l_store.screen_loc = hud_data["loc"]
					if(slot_r_store)
						if(H.r_store) H.r_store.screen_loc = hud_data["loc"]
			else
				switch(hud_data["slot"])
					if(slot_s_store)
						if(H.s_store) H.s_store.screen_loc = null
					if(slot_wear_id)
						if(H.wear_id) H.wear_id.screen_loc = null
					if(slot_belt)
						if(H.belt)    H.belt.screen_loc =    null
					if(slot_back)
						if(H.back)    H.back.screen_loc =    null
					if(slot_l_store)
						if(H.l_store) H.l_store.screen_loc = null
					if(slot_r_store)
						if(H.r_store) H.r_store.screen_loc = null


/datum/hud/proc/instantiate()
	if(!ismob(mymob)) return 0
	if(!mymob.client) return 0
	var/ui_style = ui_style2icon(mymob.client.prefs.UI_style)
	var/ui_color = mymob.client.prefs.UI_style_color
	var/ui_alpha = mymob.client.prefs.UI_style_alpha
	mymob.instantiate_hud(src, ui_style, ui_color, ui_alpha)
	mymob.HUD_create()
*/
/mob/proc/instantiate_hud(datum/hud/HUD, ui_style, ui_color, ui_alpha)
	return

//Triggered when F12 is pressed (Unless someone changed something in the DMF)
/mob/verb/button_pressed_F12(full = 0 as null)
	set name = "F12"
	set hidden = 1

	if(!hud_used)
		to_chat(usr, span_warning("This mob type does not use a HUD."))
		return

	if(!ishuman(src))
		to_chat(usr, span_warning("Inventory hiding is currently only supported for human mobs, sorry."))
		return

	if(!client) return
	if(client.view != world.view)
		return
	/*if(hud_used.hud_shown)
		hud_used.hud_shown = 0
		if(src.hud_used.adding)
			src.client.screen -= src.hud_used.adding
		if(src.hud_used.other)
			src.client.screen -= src.hud_used.other
		if(src.hud_used.hotkeybuttons)
			src.client.screen -= src.hud_used.hotkeybuttons

		//Due to some poor coding some things need special treatment:
		//These ones are a part of 'adding', 'other' or 'hotkeybuttons' but we want them to stay
		if(!full)
			src.client.screen += src.hud_used.l_hand_hud_object	//we want the hands to be visible
			src.client.screen += src.hud_used.r_hand_hud_object	//we want the hands to be visible
			src.client.screen += src.hud_used.action_intent		//we want the intent swticher visible
			src.hud_used.action_intent.screen_loc = ui_acti_alt	//move this to the alternative position, where zone_select usually is.
		else
			src.client.screen -= src.healths
			src.client.screen -= src.internals
			src.client.screen -= src.gun_setting_icon

		//These ones are not a part of 'adding', 'other' or 'hotkeybuttons' but we want them gone.
		src.client.screen -= src.zone_sel	//zone_sel is a mob variable for some reason.

	else
		hud_used.hud_shown = 1
		if(src.hud_used.adding)
			src.client.screen += src.hud_used.adding
		if(src.hud_used.other && src.hud_used.inventory_shown)
			src.client.screen += src.hud_used.other
		if(src.hud_used.hotkeybuttons && !src.hud_used.hotkey_ui_hidden)
			src.client.screen += src.hud_used.hotkeybuttons
		if(src.healths)
			src.client.screen |= src.healths
		if(src.internals)
			src.client.screen |= src.internals
		if(src.gun_setting_icon)
			src.client.screen |= src.gun_setting_icon

		src.hud_used.action_intent.screen_loc = ui_acti //Restore intent selection to the original position
		src.client.screen += src.zone_sel				//This one is a special snowflake
*/
//	hud_used.hidden_inventory_update()
//	hud_used.persistant_inventory_update()
	update_action_buttons()

//Similar to button_pressed_F12() but keeps zone_sel, gun_setting_icon, and healths.
/mob/proc/toggle_zoom_hud()
	if(!hud_used)
		return
	if(!ishuman(src))
		return
	if(!client)
		return
	if(client.view != world.view)
		return

/*	if(hud_used.hud_shown)
		hud_used.hud_shown = 0
		if(src.hud_used.adding)
			src.client.screen -= src.hud_used.adding
		if(src.hud_used.other)
			src.client.screen -= src.hud_used.other
		if(src.hud_used.hotkeybuttons)
			src.client.screen -= src.hud_used.hotkeybuttons
		src.client.screen -= src.internals
		src.client.screen += src.hud_used.action_intent		//we want the intent swticher visible
	else
		hud_used.hud_shown = 1
		if(src.hud_used.adding)
			src.client.screen += src.hud_used.adding
		if(src.hud_used.other && src.hud_used.inventory_shown)
			src.client.screen += src.hud_used.other
		if(src.hud_used.hotkeybuttons && !src.hud_used.hotkey_ui_hidden)
			src.client.screen += src.hud_used.hotkeybuttons
		if(src.internals)
			src.client.screen |= src.internals
		src.hud_used.action_intent.screen_loc = ui_acti //Restore intent selection to the original position

	hud_used.hidden_inventory_update()
	hud_used.persistant_inventory_update()*/
	update_action_buttons()


/mob/proc/add_click_catcher()
	client.screen |= GLOB.click_catchers

/mob/new_player/add_click_catcher()
	return
