#define BOOKCASE_UNANCHORED 0
#define BOOKCASE_ANCHORED 1
#define BOOKCASE_FINISHED 2


/*
 * Bookcase
 */

/obj/structure/bookcase
	name = "bookcase"
	icon = 'icons/obj/library.dmi'
	icon_state = "book-0"
	desc = "A great place for storing knowledge."
	matter = list(MATERIAL_WOOD = 10)
	anchored = FALSE
	density = TRUE
	opacity = TRUE
	var/state = BOOKCASE_UNANCHORED
	/// When enabled, books_to_load number of random books will be generated for this bookcase
	var/load_random_books = FALSE
	/// The category of books to pick from when populating random books.
	var/random_category = null
	/// How many random books to generate.
	var/books_to_load = 0

/obj/structure/bookcase/Initialize(mapload)
	. = ..()
	if(!mapload || QDELETED(src))
		return
	// Only mapload from here on
	set_anchored(TRUE)
	state = BOOKCASE_FINISHED
	for(var/obj/item/I in loc)
		if(!isbook(I))
			continue
		I.forceMove(src)
	update_icon()

	if(SSlibrary.initialized)
		INVOKE_ASYNC(src, PROC_REF(load_shelf))
	else
		SSlibrary.shelves_to_load += src

///proc for doing things after a bookcase is randomly populated
/obj/structure/bookcase/proc/after_random_load()
	return

///Loads the shelf, both by allowing it to generate random items, and by adding its contents to a list used by library machines
/obj/structure/bookcase/proc/load_shelf()
	//Loads a random selection of books in from the db, adds a copy of their info to a global list
	//To send to library consoles as a starting inventory
	if(load_random_books)
		create_random_books(books_to_load, src, FALSE, random_category)
		after_random_load()
		update_icon() //Make sure you look proper

	var/area/our_area = get_area(src)
	var/area_type = our_area.type //Save me from the dark

	if(!SSlibrary.books_by_area[area_type])
		SSlibrary.books_by_area[area_type] = list()

	//Time to populate that list
	var/list/books_in_area = SSlibrary.books_by_area[area_type]
	for(var/obj/item/book/book in contents)
		var/datum/book_info/info = book.book_data
		books_in_area += info.return_copy()

/obj/structure/bookcase/examine(mob/user, extra_description = "")
	if(!anchored)
		extra_description += span_notice("The <i>bolts</i> on the bottom are unsecured.")
	else
		extra_description += span_notice("It's secured in place with <b>bolts</b>.")
	switch(state)
		if(BOOKCASE_UNANCHORED)
			extra_description += span_notice("There's a <b>small crack</b> visible on the back panel.")
		if(BOOKCASE_ANCHORED)
			extra_description += span_notice("There's space inside for a <i>wooden</i> shelf.")
		if(BOOKCASE_FINISHED)
			extra_description += span_notice("There's a <b>small crack</b> visible on the shelf.")
	. = ..(user, extra_description)

/obj/structure/bookcase/set_anchored(anchorvalue)
	. = ..()
	if(isnull(.))
		return
	state = anchorvalue
	if(!anchorvalue) //in case we were vareditted or uprooted by a hostile mob, ensure we drop all our books instead of having them disappear till we're rebuild.
		var/atom/Tsec = drop_location()
		for(var/obj/I in contents)
			if(!isbook(I))
				continue
			I.forceMove(Tsec)
	update_icon()

/obj/structure/bookcase/attackby(obj/item/I, mob/user, params)
	if (user.incapacitated())
		to_chat(user, span_warning("You can't do that right now!"))
		return
	switch(state)
		if(BOOKCASE_UNANCHORED)
			if(istype(I,/obj/item/tool/wrench))
				playsound(src.loc, 'sound/items/Ratchet.ogg', 100, 1)
				to_chat(user, span_notice("You wrench the frame into place."))
				set_anchored(TRUE)
			else if(istype(I,/obj/item/tool/crowbar))
				to_chat(user, span_notice("You pry the frame apart."))
				deconstruct(TRUE)

		if(BOOKCASE_ANCHORED)
			if(istype(I, /obj/item/stack/material/wood))
				var/obj/item/stack/material/wood/W = I
				if(W.get_amount() >= 2)
					W.use(2)
					to_chat(user, span_notice("You add a shelf."))
					state = BOOKCASE_FINISHED
					update_icon()
			else if(istype(I,/obj/item/tool/wrench))
				playsound(src.loc, 'sound/items/Ratchet.ogg', 100, 1)
				to_chat(user, span_notice("You unwrench the frame."))
				set_anchored(FALSE)
		if(BOOKCASE_FINISHED)
			if(isbook(I))
				if(!user.unEquip(I, src))
					return
				update_icon()
			// // I am struggling to understand what this achieves.
			// // On tgstation, this would always run because atom_storage will always exist,
			// // so the code below this will never run.
			// else if(atom_storage)
			// 	for(var/obj/item/T in I.contents)
			// 		if(istype(T, /obj/item/book) || istype(T, /obj/item/spellbook))
			// 			T.forceMove(src)
			// 	to_chat(user, span_notice("You empty \the [I] into \the [src]."))
			// 	update_icon()
			else if(istype(I, /obj/item/pen))
				// if(!user.can_perform_action(src)/* || !user.can_write(I)*/)
				// 	return
				var/newname = tgui_input_text(user, "What would you like to title this bookshelf?", "Bookshelf Renaming", max_length = MAX_NAME_LEN)
				// if(!user.can_perform_action(src)/* || !user.can_write(I)*/)
				// 	return
				if(!newname)
					return
				else
					name = "bookcase ([sanitize(newname)])"
			else if(istype(I,/obj/item/tool/crowbar))
				if(length(contents))
					to_chat(user, span_warning("You need to remove the books first!"))
				else
					to_chat(user, span_notice("You pry the shelf out."))
					new /obj/item/stack/material/wood(drop_location(), 2)
					state = BOOKCASE_ANCHORED
					update_icon()
			else
				return ..()

/obj/structure/bookcase/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(.)
		return
	if(!istype(user))
		return
	if(!length(contents))
		return
	var/obj/item/book/choice = tgui_input_list(user, "Book to remove from the shelf", "Remove Book", sortNames(contents.Copy()))
	if(isnull(choice))
		return
	if(user.stat != CONSCIOUS || user.is_busy || !in_range(loc, user))
		return
	if(ishuman(user))
		if(!user.get_active_held_item())
			user.put_in_hands(choice)
	else
		choice.forceMove(drop_location())
	update_icon()

/obj/structure/bookcase/deconstruct(disassembled = TRUE)
	var/atom/Tsec = drop_location()
	drop_materials(Tsec)
	for(var/obj/item/I in contents)
		if(!isbook(I)) //Wake me up inside
			continue
		I.forceMove(Tsec)
	return ..()

// previously update_icon_state
/obj/structure/bookcase/update_icon()
	if(state == BOOKCASE_UNANCHORED || state == BOOKCASE_ANCHORED)
		icon_state = "bookempty"
		return ..()
	var/amount = length(contents)
	icon_state = "book-[clamp(amount, 0, 5)]"
	return ..()

/obj/structure/bookcase/manuals/medical
	name = "Medical Manuals bookcase"

/obj/structure/bookcase/manuals/medical/Initialize()
	. = ..()
	new /obj/item/book/manual/wiki/medical_guide(src)
	new /obj/item/book/manual/wiki/medical_guide(src)
	new /obj/item/book/manual/wiki/medical_guide(src)
	update_icon()


/obj/structure/bookcase/manuals/engineering
	name = "Engineering Manuals bookcase"

/obj/structure/bookcase/manuals/engineering/Initialize()
	. = ..()
	new /obj/item/book/manual/wiki/engineering_construction(src)
	new /obj/item/book/manual/wiki/engineering_hacking(src)
	new /obj/item/book/manual/wiki/engineering_guide(src)
	new /obj/item/book/manual/wiki/engineering_atmos(src)
	new /obj/item/book/manual/wiki/engineering_singularity(src)
	update_icon()

/obj/structure/bookcase/manuals/research_and_development
	name = "R&D Manuals bookcase"

/obj/structure/bookcase/manuals/research_and_development/Initialize()
	. = ..()
	new /obj/item/book/manual/wiki/science_research(src)
	new /obj/item/book/manual/wiki/science_research(src)
	new /obj/item/book/manual/wiki/science_robotics(src)
	update_icon()


#undef BOOKCASE_UNANCHORED
#undef BOOKCASE_ANCHORED
#undef BOOKCASE_FINISHED
