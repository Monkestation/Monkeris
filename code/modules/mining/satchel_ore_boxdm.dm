
/**********************Ore box**************************/

/obj/structure/ore_box
	icon = 'icons/obj/mining.dmi'
	icon_state = "orebox0"
	name = "ore box"
	desc = "A heavy box used for storing ore."
	density = TRUE
	rarity_value = 10
	spawn_tags = SPAWN_TAG_STRUCTURE_COMMON
	var/last_update = 0
	var/list/stored_ore = list()

/obj/structure/ore_box/attackby(obj/item/W, mob/user)
	if (istype(W, /obj/item/ore))
		user.remove_from_mob(W)
		src.contents += W
	if (istype(W, /obj/item/storage))
		var/obj/item/storage/S = W
		S.hide_from(usr)
		if (locate(/obj/item/ore) in S.contents)
			for(var/obj/item/ore/O in S.contents)
				S.remove_from_storage(O, src) //This will move the item to this item's contents
			playsound(loc, S.use_sound, 50, 1, -5)
			user.visible_message(span_notice("[user.name] empties the [S] into the box"), span_notice("You empty the [S] into the box."), span_notice("You hear a rustling sound"))
		else
			to_chat(user, span_warning("There's no ore inside the [S] to empty into here"))
	update_ore_count()

	return

/obj/structure/ore_box/proc/update_ore_count()

	stored_ore = list()

	for(var/obj/item/ore/O in contents)

		if(stored_ore[O.name])
			stored_ore[O.name]++
		else
			stored_ore[O.name] = 1

/obj/structure/ore_box/examine(mob/user, extra_description = "")
	if(get_dist(user, src) < 2) //Can only check the contents of ore boxes if you can physically reach them.
		if(!LAZYLEN(contents))
			extra_description += "\nIt is empty."
		else
			if(world.time > last_update + 10)
				update_ore_count() //TODO: Get rid of this --KIROV
				last_update = world.time

			extra_description += "\nIt holds:"
			for(var/ore in stored_ore)
				extra_description += "\n- [stored_ore[ore]] [ore]"

	..(user, extra_description)

/obj/structure/ore_box/verb/empty_box()
	set name = "Empty Ore Box"
	set category = "Object"
	set src in view(1)

	if(!ishuman(usr)) //Only living, intelligent creatures with hands can empty ore boxes.
		to_chat(usr, span_red("You are physically incapable of emptying the ore box."))
		return

	if( usr.stat || usr.restrained() )
		return

	if(!Adjacent(usr)) //You can only empty the box if you can physically reach it
		to_chat(usr, "You cannot reach the ore box.")
		return

	add_fingerprint(usr)

	if(contents.len < 1)
		to_chat(usr, span_red("The ore box is empty"))
		return

	for (var/obj/item/ore/O in contents)
		contents -= O
		O.loc = src.loc
		O.layer = initial(O.layer)
		O.set_plane(initial(O.plane))

	to_chat(usr, span_blue("You empty the ore box"))

	return

/obj/structure/ore_box/take_damage(damage)
	. = ..()
	if(QDELETED(src))
		return 0
	for (var/obj/item/ore/O in contents)
		O.loc = src.loc
		O.take_damage(damage)
	return 0

/obj/structure/ore_box/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(.)
		return
	if(Adjacent(user))
		ui_interact(user)

/obj/structure/ore_box/attack_robot(mob/user)
	if(Adjacent(user))
		ui_interact(user)

/obj/structure/ore_box/proc/dump_box_contents(ore_name, ore_amount=-1)
	var/drop = drop_location()
	for(var/obj/item/ore/O in src)
		if(ore_amount == 0)
			break
		if(QDELETED(O))
			continue
		if(QDELETED(src))
			break
		if(ore_name && O.name != ore_name)
			continue
		ore_amount--
		O.forceMove(drop)

/obj/structure/ore_box/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "OreBox", name)
		ui.open()

/obj/structure/ore_box/ui_data()
	var/data = list()
	data["materials"] = list()
	for(var/ore in stored_ore)
		data["materials"] += list(list("name" = ore, "amount" = stored_ore[ore], "type" = ore))

	return data

/obj/structure/ore_box/ui_act(action, params)
	. = ..()
	if(.)
		return
	if(!Adjacent(usr))
		return
	add_fingerprint(usr)
	switch(action)
		if("ejectallores")
			dump_box_contents()
			to_chat(usr, span_notice("You release all the content of the box."))
			update_ore_count()
			return TRUE
		if("ejectall")
			var/ore_name = params["type"]
			dump_box_contents(ore_name)
			to_chat(usr, span_notice("You release all the [ore_name] ores."))
			update_ore_count()
			return TRUE
		if("eject")
			var/ore_name = params["type"]
			var/ore_amount = params["qty"]
			dump_box_contents(ore_name, ore_amount)
			to_chat(usr, span_notice("You release [ore_amount] [ore_name] ores."))
			update_ore_count()
			return TRUE
