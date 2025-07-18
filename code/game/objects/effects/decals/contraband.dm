
// CONTRABAND

/obj/item/contraband
	name = "contraband item"
	desc = "You probably shouldn't be holding this."
	icon = 'icons/obj/contraband.dmi'
	force = 0
	bad_type = /obj/item/contraband
	spawn_tags = SPAWN_ITEM_CONTRABAND


/obj/item/contraband/poster
	name = "rolled-up poster"
	desc = "The poster comes with its own automatic adhesive mechanism, for easy pinning to any vertical surface."
	description_info = "You can safely remove a pinned poster with a pair of wirecutters."
	icon_state = "rolled_poster"
	var/poster_datum = "all" // Which set of poster_designs you want used.
	var/serial_number = 0
	var/ruined = 0
	var/datum/poster/design
	matter = list(MATERIAL_PLASTIC = 1)

/obj/item/contraband/poster/New(turf/loc, datum/poster/new_design = null)
	switch(poster_datum)
		if ("all")
			if(!new_design)
				design = pick(GLOB.poster_designs)
		if ("asters")
			if(!new_design)
				design = pick(GLOB.poster_designs_asters)
		else
			design = new_design

	..(loc)

/obj/item/contraband/poster/asters
	name = "rolled-up asters poster"
	desc = "The poster comes with its own automatic adhesive mechanism, for easy pinning to any vertical surface."
	icon_state = "rolled_poster_asters"
	poster_datum = "asters"

/obj/item/contraband/poster/placed
	icon_state = "random"
	anchored = TRUE
	spawn_tags = null
	bad_type = /obj/item/contraband/poster/placed

/obj/item/contraband/poster/placed/New(turf/loc)
	if(icon_state != "random")
		for(var/datum/poster/new_design in GLOB.poster_designs)
			if(new_design.icon_state == icon_state)
				return ..(loc, new_design)
	..()
	if(iswall(loc) && !pixel_x && !pixel_y)
		for(var/dir in GLOB.cardinal)
			if(isfloor(get_step(src, dir)))
				switch(dir)
					if(NORTH) pixel_y = -32
					if(SOUTH) pixel_y = 32
					if(EAST)  pixel_x = 32
					if(WEST)  pixel_x = -32

/obj/item/contraband/poster/attack_hand(mob/user)
	if(!anchored)
		return ..()

	if(ruined)
		return

	switch(alert("Do I want to rip the poster from the wall?","You think...","Yes","No"))
		if("Yes")
			if(!Adjacent(user))
				return
			visible_message(span_warning("[user] rips [src] in a single, decisive motion!") )
			playsound(src.loc, 'sound/items/poster_ripped.ogg', 100, 1)
			ruined = 1
			icon = initial(icon)
			icon_state = "poster_ripped"
			name = "ripped poster"
			desc = "You can't make out anything from the poster's original print. It's ruined."
			add_fingerprint(user)
		if("No")
			return

/obj/item/contraband/poster/attackby(obj/item/W, mob/user)
	if(istype(W, /obj/item/tool/wirecutters))
		playsound(loc, 'sound/items/Wirecutter.ogg', 100, 1)
		if(ruined)
			to_chat(user, span_notice("You remove the remnants of the poster."))
			qdel(src)
		else
			roll_and_drop()
			to_chat(user, span_notice("You carefully remove the poster from the wall."))
		return

/obj/item/contraband/poster/proc/roll_and_drop()
	anchored = FALSE
	pixel_x = 0
	pixel_y = 0
	icon = initial(icon)
	icon_state = initial(icon_state)
	name = initial(name)


//Places the poster on a wall
/obj/item/contraband/poster/afterattack(turf/wall/W, mob/user, adjacent, clickparams)
	if (!adjacent)
		return

	//must place on a wall and user must not be inside a closet/whatever
	if (!istype(W) || !W.Adjacent(user))
		to_chat(user, span_warning("You can't place this here!"))
		return

	var/turf/new_loc = null

	var/placement_dir = get_dir(user, W)
	if (placement_dir in GLOB.cardinal)
		new_loc = user.loc
	else
		placement_dir = GLOB.reverse_dir[placement_dir]
		for(var/t_dir in GLOB.cardinal)
			if(!(t_dir & placement_dir)) continue
			if(iswall(get_step(W, t_dir)))
				if(iswall(get_step(W, placement_dir-t_dir)))
					break
				else
					new_loc = get_step(W, placement_dir-t_dir)
					break
			else
				if(iswall(get_step(W, placement_dir-t_dir)))
					new_loc = get_step(W, t_dir)
					break
				else
					new_loc = user.loc
					break
	if(!new_loc)
		to_chat(user, span_warning("You can't place poster there"))

	//Looks like it's uncluttered enough. Place the poster.
	to_chat(user, span_notice("You start placing the poster on the wall..."))
	if(do_after(usr, 17, src))
		user.drop_from_inventory(src, new_loc)
		placement_dir = get_dir(W, new_loc)
		if(placement_dir&NORTH)
			pixel_y = -32
		else if(placement_dir&SOUTH)
			pixel_y = 32
		if(placement_dir&WEST)
			pixel_x = 32
		else if(placement_dir&EAST)
			pixel_x = -32
		anchored = TRUE
		flick("poster_being_set", src)
		playsound(W, 'sound/items/poster_being_created.ogg', 100, 1)
		design.set_design(src)

/datum/poster
	// Name suffix. Poster - [name]
	var/name = ""
	// Description suffix
	var/desc = ""
	var/description_fluff = ""
	var/icon_state = ""
	var/icon = 'icons/obj/contraband.dmi'

/datum/poster/asters
	description_fluff = "Appears to been produced by members of the Aster's Guild."

/datum/poster/proc/set_design(obj/item/contraband/poster/poster)
	poster.name = "poster - [name]"
	poster.desc = desc
	poster.description_fluff = description_fluff
	poster.icon_state = icon_state
	poster.icon = icon
	return 1
