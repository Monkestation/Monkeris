// This is synced up to the poster placing animation.
#define PLACE_SPEED 37

// The poster item

/**
 * The rolled up item form of a poster
 *
 * In order to create one of these for a specific poster, you must pass the structure form of the poster as an argument to /new().
 * This structure then gets moved into the contents of the item where it will stay until the poster is placed by a player.
 * The structure form is [obj/structure/sign/poster] and that's where all the specific posters are defined.
 * If you just want a random poster, see [/obj/item/poster/random_official] or [/obj/item/poster/random_contraband]
 */
/obj/item/poster
	name = "poorly coded poster"
	desc = "You probably shouldn't be holding this."
	icon = 'icons/obj/contraband.dmi'
	force = 0
	w_class = ITEM_SIZE_SMALL
	var/poster_type
	var/obj/structure/sign/poster/poster_structure

/obj/item/poster/examine(mob/user)
	. = ..()
	. += span_notice("You can booby-trap the poster by using a glass shard on it before you put it up.")

/obj/item/poster/Initialize(mapload, obj/structure/sign/poster/new_poster_structure)
	. = ..()


	if(new_poster_structure && (new_poster_structure.loc != src))
		new_poster_structure.forceMove(src) //The poster structure *must* be in the item's contents for the exited() proc to properly clean up when placing the poster
	poster_structure = new_poster_structure
	if(!new_poster_structure && poster_type)
		poster_structure = new poster_type(src)

	// posters store what name and description they would like their
	// rolled up form to take.
	if(poster_structure)
		if(QDELETED(poster_structure))
			stack_trace("A poster was initialized with a qdeleted poster_structure, something's gone wrong")
			return INITIALIZE_HINT_QDEL
		name = poster_structure.poster_item_name
		desc = poster_structure.poster_item_desc
		icon_state = poster_structure.poster_item_icon_state

		name = "[name] - [poster_structure.original_name]"

/obj/item/poster/attackby(obj/item/I, mob/user, params)
	if(!istype(I, /obj/item/material/shard))
		return ..()

	if (poster_structure.trap?.resolve())
		balloon_alert(user, "already trapped!")
		return

	if(!user.unEquip(I, poster_structure))
		return

	poster_structure.trap = WEAKREF(I)
	to_chat(user, span_notice("You conceal the [I.name] inside the rolled up poster."))

/obj/item/poster/Exited(atom/movable/gone, direction)
	. = ..()
	if(gone == poster_structure)
		poster_structure = null
		if(!QDELING(src))
			qdel(src) //we're now a poster, huzzah!

/obj/item/poster/handle_atom_del(atom/deleting_atom)
	if(deleting_atom == poster_structure)
		poster_structure.moveToNullspace() //get it the fuck out of us since atom/destroy qdels contents and it'll cause a qdel loop
	return ..()

/obj/item/poster/Destroy(force)
	QDEL_NULL(poster_structure)
	return ..()

// The poster sign/structure

/**
 * The structure form of a poster.
 *
 * These are what get placed on maps as posters. They are also what gets created when a player places a poster on a wall.
 * For the item form that can be spawned for players, see [/obj/item/poster]
 */
/obj/structure/sign/poster
	name = "poster"
	var/original_name
	desc = "A large piece of space-resistant printed paper."
	icon = 'icons/obj/contraband.dmi'
	anchored = TRUE
	var/ruined = FALSE
	var/random_basetype
	var/never_random = FALSE // used for the 'random' subclasses.
	///Exclude posters of these types from being added to the random pool
	var/list/blacklisted_types = list()
	///Whether the poster should be printable from library management computer. Mostly exists to keep directionals from being printed.
	var/printable = FALSE

	var/poster_item_name = "hypothetical poster"
	var/poster_item_desc = "This hypothetical poster item should not exist, let's be honest here."
	var/poster_item_icon_state = "rolled_poster"
	var/poster_item_type = /obj/item/poster
	///A sharp shard of material can be hidden inside of a poster, attempts to embed when it is torn down.
	var/datum/weakref/trap

/obj/structure/sign/poster/Initialize(mapload)
	. = ..()
	if(random_basetype)
		randomise(random_basetype)
	if(!ruined)
		original_name = name // can't use initial because of random posters
		name = "poster - [name]"
		desc = "A large piece of space-resistant printed paper. [desc]"

	// AddElement(/datum/element/beauty, 300)

/obj/structure/sign/poster/proc/randomise(base_type)
	var/list/poster_types = subtypesof(base_type)
	if(length(blacklisted_types))
		for(var/iterated_type in blacklisted_types)
			poster_types -= typesof(iterated_type)
	var/list/approved_types = list()
	for(var/obj/structure/sign/poster/type_of_poster as anything in poster_types)
		if(initial(type_of_poster.icon_state) && !initial(type_of_poster.never_random))
			approved_types |= type_of_poster

	var/obj/structure/sign/poster/selected = pick(approved_types)

	name = initial(selected.name)
	desc = initial(selected.desc)
	icon_state = initial(selected.icon_state)
	icon = initial(selected.icon)
	poster_item_name = initial(selected.poster_item_name)
	poster_item_desc = initial(selected.poster_item_desc)
	poster_item_icon_state = initial(selected.poster_item_icon_state)
	ruined = initial(selected.ruined)
	update_icon()

/obj/structure/sign/poster/attackby(obj/item/tool, mob/user, params)
	if(tool.has_quality(QUALITY_WIRE_CUTTING))
		playsound(loc, 'sound/items/Wirecutter.ogg', 100, 1)

		if(ruined)
			to_chat(user, span_notice("You remove the remnants of the poster."))
			qdel(src)
		else
			to_chat(user, span_notice("You carefully remove the poster from the wall."))
			roll_and_drop(Adjacent(user) ? get_turf(user) : loc, user)

/obj/structure/sign/poster/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(.)
		return
	if(ruined)
		return
	tear_poster(user)

/obj/structure/sign/poster/proc/spring_trap(mob/user)
	var/obj/item/material/shard/payload = trap?.resolve()
	if (!payload)
		return

	to_chat(user, span_warning("There's something sharp behind this! What the hell?"))
	if(can_embed_trap(user))
		payload.throw_at(user, 1, 1)
		visible_message(span_notice("A [payload.name] falls from behind the poster.") )
		payload.forceMove(user.drop_location())
		SEND_SIGNAL(src, COMSIG_POSTER_TRAP_SUCCEED, user)

/obj/structure/sign/poster/proc/can_embed_trap(mob/living/carbon/human/user)
	if (!istype(user))
		return FALSE
	return !user.gloves || !(user.gloves.body_parts_covered & ARMS)

/obj/structure/sign/poster/proc/roll_and_drop(atom/location, mob/user)
	pixel_x = 0
	pixel_y = 0
	var/obj/item/poster/rolled_poster = new poster_item_type(location, src) // /obj/structure/sign/poster/wanted/roll_and_drop() has some snowflake handling due to icon memes, if you make a major change to this, don't forget to update it too. <3
	if(!user?.put_in_hands(rolled_poster))
		forceMove(rolled_poster)
	return rolled_poster

//separated to reduce code duplication. Moved here for ease of reference and to unclutter r_wall/attackby()
/turf/wall/proc/place_poster(obj/item/poster/rolled_poster, mob/user)
	if(!rolled_poster.poster_structure)
		to_chat(user, span_warning("[rolled_poster] has no poster... inside it? Inform a coder!"))
		return

	// Deny placing posters on currently-diagonal walls, although the wall may change in the future.
	for (var/overlay in overlays)
		var/image/new_image = overlay
		if(copytext(new_image.icon_state, 1, 3) == "d-") //3 == length("d-") + 1
			return

	var/stuff_on_wall = 0
	for(var/obj/contained_object in contents) //Let's see if it already has a poster on it or too much stuff
		if(istype(contained_object, /obj/structure/sign/poster))
			balloon_alert(user, "no room!")
			return
		stuff_on_wall++
		if(stuff_on_wall == 3)
			balloon_alert(user, "no room!")
			return

	balloon_alert(user, "hanging poster...")
	var/obj/structure/sign/poster/placed_poster = rolled_poster.poster_structure
	// shitfix
	// placed_poster.pixel_x = 0

	flick("poster_being_set", placed_poster)
	placed_poster.forceMove(src) //deletion of the poster is handled in poster/Exited(), so don't have to worry about P anymore.
	playsound(src, 'sound/items/poster_being_created.ogg', 100, TRUE)

	var/turf/user_drop_location = get_turf(user) //cache this so it just falls to the ground if they move. also no tk memes allowed.
	if(!do_after(user, PLACE_SPEED, placed_poster, extra_checks = CALLBACK(placed_poster, TYPE_PROC_REF(/obj/structure/sign/poster, snowflake_closed_turf_check), src)))
		placed_poster.roll_and_drop(user_drop_location, user)
		return

	placed_poster.on_placed_poster(user)
	return TRUE

/obj/structure/sign/poster/proc/snowflake_closed_turf_check(atom/hopefully_still_a_closed_turf) //since turfs never get deleted but instead change type, make sure we're still being placed on a wall.
	return isclosedturf(hopefully_still_a_closed_turf)

/obj/structure/sign/poster/proc/on_placed_poster(mob/user)
	to_chat(user, span_notice("You place the poster!"))

/obj/structure/sign/poster/proc/tear_poster(mob/user)
	visible_message(span_notice("[user] rips [src] in a single, decisive motion!") )
	playsound(src.loc, 'sound/items/poster_ripped.ogg', 100, TRUE)
	spring_trap(user)

	var/obj/structure/sign/poster/ripped/R = new(loc)
	R.pixel_y = pixel_y
	R.pixel_x = pixel_x
	R.add_fingerprint(user)
	qdel(src)

// Various possible posters follow

/obj/structure/sign/poster/ripped
	ruined = TRUE
	icon_state = "poster_ripped"
	name = "ripped poster"
	desc = "You can't make out anything from the poster's original print. It's ruined."

MAPPING_DIRECTIONAL_HELPERS_LIBRARY(/obj/structure/sign/poster/ripped, 32)

/obj/structure/sign/poster/random
	name = "random poster" // could even be ripped
	icon_state = "random_anything"
	never_random = TRUE
	random_basetype = /obj/structure/sign/poster
	// blacklisted_types = list(
	// 	/obj/structure/sign/poster/traitor,
	// 	/obj/structure/sign/poster/abductor,
	// )

/obj/structure/sign/poster/random/directional
	printable = FALSE

MAPPING_DIRECTIONAL_HELPERS_LIBRARY(/obj/structure/sign/poster/random, 32)

#undef PLACE_SPEED
