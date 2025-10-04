// How many fields a sheet of paper may hold.
#define MAX_FIELDS 50

/*
 * Paper
 * also scraps of paper
 */

/obj/item/paper
	name = "sheet of paper"
	gender = NEUTER
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "paper"
	item_state = "paper"
	throwforce = 0
	w_class = ITEM_SIZE_TINY
	throw_range = 1
	throw_speed = 1
	slot_flags = SLOT_HEAD
	body_parts_covered = HEAD
	attack_verb = list("bapped")
	matter = list(MATERIAL_BIOMATTER = 1)
	contained_sprite = TRUE
	spawn_tags = SPAWN_JUNK
	rarity_value = 3.5


	var/info		//What's actually written on the paper.
	var/info_links	//A different version of the paper which includes html links at fields and EOF
	var/stamps		//The (text for the) stamps on the paper.
	var/fields		//Amount of user created fields
	var/free_space = MAX_PAPER_MESSAGE_LEN
	var/list/stamped
	var/list/ico[0]      //Icons and
	var/list/offset_x[0] //offsets stored for later
	var/list/offset_y[0] //usage by the photocopier
	var/crumpled = FALSE

	var/const/deffont = "Verdana"
	var/const/signfont = "Times New Roman"
	var/const/crayonfont = "Comic Sans MS"

/obj/item/paper/New(loc, text,title)
	..(loc)
	pixel_y = rand(-8, 8)
	pixel_x = rand(-9, 9)
	set_content(text ? text : info, title)

/obj/item/paper/proc/set_content(text,title)
	if(title)
		name = title
	info = html_encode(text)
	info = parsepencode(text)
	update_icon()
	update_space(info)
	updateinfolinks()

/obj/item/paper/update_icon()
	if (icon_state == "paper_talisman")
		return
	else if (info)
		icon_state = "paper_words"
	else
		icon_state = "paper"

/obj/item/paper/proc/update_space(new_text)
	if(!new_text)
		free_space -= length(strip_html_properly(new_text))

/obj/item/paper/examine(mob/user, extra_description = "")
	if(name != "sheet of paper")
		extra_description += "\nIt's titled '[name]'."
	if(in_range(user, src) || isghost(user))
		show_content(user)
	else
		extra_description += span_notice("\nYou have to come closer if you want to read it.")
	..(user, extra_description)

/obj/item/paper/proc/show_content(mob/user, forceshow)
	var/can_read = (istype(user, /mob/living/carbon/human) || isghost(user) || istype(user, /mob/living/silicon)) || forceshow
	if(!forceshow && istype(user,/mob/living/silicon/ai))
		var/mob/living/silicon/ai/AI = user
		can_read = get_dist(src, AI.camera) < 2
	user << browse("<HTML><meta charset=\"utf-8\"><HEAD><TITLE>[name]</TITLE></HEAD><BODY bgcolor='[color]'>[can_read ? info : stars(info)][stamps]</BODY></HTML>", "window=[name]")
	onclose(user, "[name]")

/obj/item/paper/verb/rename()
	set name = "Rename paper"
	set category = "Object"
	set src in usr
	playsound(src,'sound/effects/PEN_Ball_Point_Pen_Circling_01_mono.ogg',40,1)

//	if((CLUMSY in usr.mutations) && prob(50))
//		to_chat(usr, span_warning("You cut yourself on the paper."))
//		return
	var/n_name = sanitizeSafe(input(usr, "What would you like to label the paper?", "Paper Labelling", null)  as text, MAX_NAME_LEN)

	// We check loc one level up, so we can rename in clipboards and such. See also: /obj/item/photo/rename()
	if((loc == usr || loc.loc && loc.loc == usr) && usr.stat == 0 && n_name)
		log_paper("[key_name(usr)] renamed [name] to [n_name]")
		name = n_name
		add_fingerprint(usr)

/obj/item/paper/attack_self(mob/living/user as mob)
	if (user.a_intent == I_HURT)
		if (crumpled)
			user.show_message(span_warning("\The [src] is already crumpled."))
			return
		//crumple dat paper
		info = stars(info,85)
		user.visible_message("\The [user] crumples \the [src] into a ball!")
		icon_state = "[icon_state]_crumpled"
		playsound(loc, 'sound/effects/paper_crumpling.ogg', 40, 1)
		crumpled = TRUE
		return
	user.examinate(src)

/obj/item/paper/attack_ai(mob/living/silicon/ai/user)
	show_content(user)

/obj/item/paper/attack(mob/living/carbon/M as mob, mob/living/carbon/user as mob)
	if(user.targeted_organ == BP_EYES)
		user.visible_message(span_notice("You show the paper to [M]. "), \
			span_notice(" [user] holds up a paper and shows it to [M]. "))
		M.examinate(src)

	else if(user.targeted_organ == BP_MOUTH) // lipstick wiping
		if(ishuman(M))
			var/mob/living/carbon/human/H = M
			if(H == user)
				to_chat(user, span_notice("You wipe off the lipstick with [src]."))
				H.lip_style = null
				H.update_body()
			else
				user.visible_message(span_warning("[user] begins to wipe [H]'s lipstick off with \the [src]."), \
								 	 span_notice("You begin to wipe off [H]'s lipstick."))
				if(do_after(user, 10, H) && do_after(H, 10, needhand = 0))	//user needs to keep their active hand, H does not.
					user.visible_message(span_notice("[user] wipes [H]'s lipstick off with \the [src]."), \
										 span_notice("You wipe off [H]'s lipstick."))
					H.lip_style = null
					H.update_body()

/obj/item/paper/proc/addtofield(id, text, links = 0)
	var/locid = 0
	var/laststart = 1
	var/textindex = 1
	while(locid < MAX_FIELDS)
		var/istart = 0
		if(links)
			istart = findtext(info_links, "<span class='paper_field'>", laststart)
		else
			istart = findtext(info, "<span class='paper_field'>", laststart)

		if(istart == 0)
			return // No field found with matching id

		laststart = istart + 1
		locid++
		if(locid == id)
			var/iend = 1
			if(links)
				iend = findtext(info_links, "</span>", istart)
			else
				iend = findtext(info, "</span>", istart)

			textindex = iend
			break

	if (links)
		var/before = copytext(info_links, 1, textindex)
		var/after = copytext(info_links, textindex)
		info_links = before + text + after
	else
		var/before = copytext(info, 1, textindex)
		var/after = copytext(info, textindex)
		info = before + text + after
		updateinfolinks()

/obj/item/paper/proc/updateinfolinks()
	info_links = info
	var/i = 0
	for(i = 1; i<=fields; i++)
		addtofield(i, "<font face=\"[deffont]\"><A href='byond://?src=\ref[src];write=[i]'>write</A></font>", 1)
	info_links = info_links + "<font face=\"[deffont]\"><A href='byond://?src=\ref[src];write=end'>write</A></font>"


/obj/item/paper/proc/clearpaper()
	info = null
	stamps = null
	free_space = MAX_PAPER_MESSAGE_LEN
	stamped = list()
	cut_overlays()
	updateinfolinks()
	update_icon()

/obj/item/paper/proc/get_signature(obj/item/pen/P, mob/user as mob)
	if (P && istype(P, /obj/item/pen))
		return P.get_signature(user)
	return (user && user.real_name) ? user.real_name : "Anonymous"

/obj/item/paper/proc/parsepencode(t, obj/item/pen/P, mob/user, iscrayon)
	if (length(t) == 0)
		return ""

	if (findtext(t, "\[sign\]"))
		t = replacetext(t, "\[sign\]", "<font face=\"[signfont]\"><i>[get_signature(P, user)]</i></font>")

	if (iscrayon) // If it is a crayon, and they still try to use these, make them empty!
		t = replacetext(t, "\[*\]", "")
		t = replacetext(t, "\[hr\]", "")
		t = replacetext(t, "\[small\]", "")
		t = replacetext(t, "\[/small\]", "")
		t = replacetext(t, "\[list\]", "")
		t = replacetext(t, "\[/list\]", "")
		t = replacetext(t, "\[table\]", "")
		t = replacetext(t, "\[/table\]", "")
		t = replacetext(t, "\[grid\]", "")
		t = replacetext(t, "\[/grid\]", "")
		t = replacetext(t, "\[row\]", "")
		t = replacetext(t, "\[cell\]", "")
		t = replacetext(t, "\[logo\]", "")

	if (iscrayon)
		t = "<font face=\"[crayonfont]\" color=[P ? P.colour : "black"]><b>[t]</b></font>"
	else
		t = "<font face=\"[deffont]\" color=[P ? P.colour : "black"]>[t]</font>"

	t = pencode2html(t)

	//Count the fields
	var/laststart = 1
	while(fields < MAX_FIELDS)
		var/i = findtext(t, "<span class='paper_field'>", laststart)	//</span>
		if(i == 0)
			break
		laststart = i + 1
		fields++

	return t

/obj/item/paper/proc/burnpaper(obj/item/flame/P, mob/user)
	var/class = "warning"

	if(P.lit && !user.restrained())
		if(istype(P, /obj/item/flame/lighter/zippo))
			class = "rose"
		log_paper("[key_name(user)] burned [src] with [P]")

		user.visible_message("<span class='[class]'>[user] holds \the [P] up to \the [src], it looks like \he's trying to burn it!</span>", \
		"<span class='[class]'>You hold \the [P] up to \the [src], burning it slowly.</span>")

		spawn(20)
			if(get_dist(src, user) < 2 && user.get_active_held_item() == P && P.lit)
				user.visible_message("<span class='[class]'>[user] burns right through \the [src], turning it to ash. It flutters through the air before settling on the floor in a heap.</span>", \
				"<span class='[class]'>You burn right through \the [src], turning it to ash. It flutters through the air before settling on the floor in a heap.</span>")

				if(user.get_inactive_held_item() == src)
					user.drop_from_inventory(src)

				new /obj/effect/decal/cleanable/ash(src.loc)
				qdel(src)

			else
				to_chat(user, span_red("You must hold \the [P] steady to burn \the [src]."))


/obj/item/paper/Topic(href, href_list)
	..()
	if(!usr || (usr.stat || usr.restrained()))
		return

	if(href_list["write"])
		var/id = href_list["write"]
		//var/t = strip_html_simple(input(usr, "What text do you wish to add to " + (id=="end" ? "the end of the paper" : "field "+id) + "?", "[name]", null),8192) as message

		if(free_space <= 0)
			to_chat(usr, span_info("There isn't enough space left on \the [src] to write anything."))
			return

		var/t =  sanitize(input("Enter what you want to write:", "Write", null, null) as message, free_space, extra = 0)

		if(!t)
			return

		var/obj/item/i = usr.get_active_held_item() // Check to see if they still have that darn pen, also check if they're using a crayon or pen.
		var/iscrayon = 0
		if(!istype(i, /obj/item/pen))
			log_paper("[key_name(usr)] failed to write to [src] with [i] (not a pen), contents: [i]")
			return

		if(istype(i, /obj/item/pen/crayon))
			iscrayon = 1


		// if paper is not in usr, then it must be near them, or in a clipboard or folder, which must be in or near usr
		if(src.loc != usr && !src.Adjacent(usr) && !((istype(src.loc, /obj/item/clipboard) || istype(src.loc, /obj/item/folder)) && (src.loc.loc == usr || src.loc.Adjacent(usr)) ) )
			log_paper("[key_name(usr)] failed to write to [src] with [i] (ungodly long check), contents: [i]")
			return

		var/last_fields_value = fields

		//t = html_encode(t)
		t = replacetext(t, "\n", "<BR>")
		var/before_pencode = t
		t = parsepencode(t, i, usr, iscrayon) // Encode everything from pencode to html


		if(fields > MAX_FIELDS)//large amount of fields creates a heavy load on the server, see updateinfolinks() and addtofield()
			to_chat(usr, span_warning("Too many fields. Sorry, you can't do this."))
			log_paper("[key_name(usr)] failed to write to [src] with [i], contents: [before_pencode]")

			fields = last_fields_value
			return

		log_paper("[key_name(usr)] write to [src] with [i], contents: [before_pencode]")

		if(id!="end")
			addtofield(text2num(id), t) // They want to edit a field, let them.
		else
			info += t // Oh, they want to edit to the end of the file, let them.
			updateinfolinks()
		playsound(src,'sound/effects/PEN_Ball_Point_Pen_Circling_01_mono.ogg',40,1)
		update_space(t)

		usr << browse("<HTML><meta charset=\"utf-8\"><HEAD><TITLE>[name]</TITLE></HEAD><BODY bgcolor='[color]'>[info_links][stamps]</BODY></HTML>", "window=[name]") // Update the window

		update_icon()




/obj/item/paper/attackby(obj/item/P as obj, mob/user as mob)
	..()

	if(P.has_quality(QUALITY_ADHESIVE))
		return //The tool's afterattack will handle this

	if(istype(P, /obj/item/paper) || istype(P, /obj/item/photo))
		if (istype(P, /obj/item/paper/carbon))
			var/obj/item/paper/carbon/C = P
			if (!C.iscopy && !C.copied)
				to_chat(user, span_notice("Take off the carbon copy first."))
				add_fingerprint(user)
				return
		var/obj/item/paper_bundle/B = new(src.loc)
		if (name != "paper")
			B.name = name
		else if (P.name != "paper" && P.name != "photo")
			B.name = P.name
		if (user)
			user.drop_from_inventory(P)
			if (ishuman(user))
				var/mob/living/carbon/human/h_user = user
				if (h_user.r_hand == src)
					h_user.drop_from_inventory(src)
					h_user.put_in_r_hand(B)
				else if (h_user.l_hand == src)
					h_user.drop_from_inventory(src)
					h_user.put_in_l_hand(B)
				else if (h_user.l_store == src)
					h_user.drop_from_inventory(src)
					B.loc = h_user
					B.layer = 20
					h_user.l_store = B
					h_user.update_inv_pockets()
				else if (h_user.r_store == src)
					h_user.drop_from_inventory(src)
					B.loc = h_user
					B.layer = 20
					h_user.r_store = B
					h_user.update_inv_pockets()
				else if (h_user.head == src)
					h_user.u_equip(src)
					h_user.put_in_hands(B)
				else if (!istype(src.loc, /turf))
					src.loc = get_turf(h_user)
					if(h_user.client)	h_user.client.screen -= src
					h_user.put_in_hands(B)
			to_chat(user, span_notice("You clip the [P.name] to [(src.name == "paper") ? "the paper" : src.name]."))
		src.loc = B
		P.loc = B

		B.pages.Add(src)
		B.pages.Add(P)
		B.update_icon()
		return B

	else if(istype(P, /obj/item/pen))
		if(crumpled)
			to_chat(usr, span_warning("\The [src] is too crumpled to write on."))
			return

		var/obj/item/pen/robopen/RP = P
		if ( istype(RP) && RP.mode == 2 )
			RP.RenamePaper(user,src)
		else
			user << browse("<HTML><meta charset=\"utf-8\"><HEAD><TITLE>[name]</TITLE></HEAD><BODY bgcolor='[color]'>[info_links][stamps]</BODY></HTML>", "window=[name]")
		return

	else if(istype(P, /obj/item/stamp))
		if((!in_range(src, usr) && loc != user && !( istype(loc, /obj/item/clipboard) ) && loc.loc != user && user.get_active_held_item() != P))
			return
		playsound(src,'sound/effects/Stamp.ogg',40,1)
		log_paper("[key_name(user)] stamped [name] with [P]")
		stamps += (stamps=="" ? "<HR>" : "<BR>") + "<i>This paper has been stamped with the [P.name].</i>"

		var/image/stampoverlay = image('icons/obj/bureaucracy.dmi')
		var/x
		var/y
		if(istype(P, /obj/item/stamp/captain))
			x = rand(-2, 0)
			y = rand(-1, 2)
		else
			x = rand(-2, 2)
			y = rand(-3, 2)
		offset_x += x
		offset_y += y
		stampoverlay.pixel_x = x
		stampoverlay.pixel_y = y

		if(!ico)
			ico = new
		ico += "paper_[P.icon_state]"
		stampoverlay.icon_state = "paper_[P.icon_state]"

		if(!stamped)
			stamped = new
		stamped += P.type
		overlays += stampoverlay

		to_chat(user, span_notice("You stamp the paper with your rubber stamp."))

	else if(istype(P, /obj/item/flame))
		burnpaper(P, user)

	add_fingerprint(user)
	return


/obj/item/paper/crumpled
	name = "paper scrap"
	icon_state = "paper_crumpled"
	crumpled = TRUE

/obj/item/paper/crumpled/update_icon()
	if (icon_state == "paper_crumpled_bloodied")
		return
	else if (info)
		icon_state = "paper_words_crumpled"
	else
		icon_state = "paper_crumpled"
	return

/obj/item/paper/crumpled/bloody
	icon_state = "paper_crumpled_bloodied"

/obj/item/paper/neopaper
	name = "sheet of odd paper"
	icon_state = "paper_neo"

/obj/item/paper/neopaper/update_icon()
	if(info)
		icon_state = "paper_neo_words"
	else
		icon_state = "paper_neo"
	return

/obj/item/paper/crumpled/neo
	name = "odd paper scrap"
	icon_state = "paper_neo_crumpled"

/obj/item/paper/crumpled/neo/update_icon()
	if (icon_state == "paper_neo_words_crumpled_bloodied")
		return
	else if (info)
		icon_state = "paper_neo_words_crumpled"
	else
		icon_state = "paper_neo_crumpled"
	return

/obj/item/paper/crumpled/neo/bloody
	icon_state = "paper_neo_words_crumpled_bloodied"

#undef MAX_FIELDS

/*
/**
 * Paper
 * also scraps of paper
 *
 * lipstick wiping is in code/game/objects/items/weapons/cosmetics.dm!
 */

/**
 * Paper is now using markdown (like in github pull notes) for ALL rendering
 * so we do loose a bit of functionality but we gain in easy of use of
 * paper and getting rid of that crashing bug
 */
/obj/item/paper
	name = "paper"
	gender = NEUTER
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "paper"
	item_state = "paper"
	worn_icon = 'icons/mob/clothing/head/costume.dmi'
	worn_icon_state = "paper"
	custom_fire_overlay = "paper_onfire_overlay"
	throwforce = 0
	w_class = ITEM_SIZE_TINY
	throw_range = 1
	throw_speed = 1
	body_parts_covered = HEAD
	// drop_sound = 'sound/items/handling/paper_drop.ogg'
	// pickup_sound = 'sound/items/handling/paper_pickup.ogg'
	color = COLOR_WHITE

	/// Lazylist of raw, unsanitised, unparsed text inputs that have been made to the paper.
	var/list/datum/paper_input/raw_text_inputs
	/// Lazylist of all raw stamp data to be sent to tgui.
	var/list/datum/paper_stamp/raw_stamp_data
	/// Lazylist of all fields that have had some input added to them.
	var/list/datum/paper_field/raw_field_input_data

	/// Whether the icon should show little scribbly written words when the paper has some text on it.
	var/show_written_words = TRUE

	/// Helper cache that contains a list of all icon_states that are currently stamped on the paper.
	var/list/stamp_cache

	/// Reagent to transfer to the user when they pick the paper up without proper protection.
	var/contact_poison
	/// Volume of contact_poison to transfer to the user when they pick the paper up without proper protection.
	var/contact_poison_volume = 0

	/// Default raw text to fill this paper with on init.
	var/default_raw_text

	/// Checks to see if the paper can be folded
	var/can_be_folded = TRUE

	/// The number of input fields
	var/input_field_count = 0

	/// Paper can be shown via cameras. When that is done, a deep copy of the paper is made and stored as a var on the camera.
	/// The paper is located in nullspace, and holds a weak ref to the camera that once contained it so the paper can do some
	/// state checking on if it should be shown to a viewer.
	var/datum/weakref/camera_holder

	///If TRUE, staff can read paper everywhere, but usually from requests panel.
	var/request_state = FALSE
	///is this considered thermal paper?
	var/thermal_paper = FALSE

/obj/item/paper/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/customizable_reagent_holder, /obj/item/clothing/mask/cigarette/rollie, CUSTOM_INGREDIENT_ICON_NOCHANGE, ingredient_type=CUSTOM_INGREDIENT_TYPE_DRYABLE, max_ingredients=2, job_xp = 1, job = JOB_BOTANIST)
	pixel_x = base_pixel_x + rand(-9, 9)
	pixel_y = base_pixel_y + rand(-8, 8)

	if(default_raw_text)
		add_raw_text(default_raw_text)

	update_appearance()

/obj/item/paper/Destroy()
	. = ..()
	camera_holder = null
	clear_paper()

/// Determines whether this paper has been written or stamped to.
/obj/item/paper/proc/is_empty()
	return !(LAZYLEN(raw_text_inputs) || LAZYLEN(raw_stamp_data))

/// Returns a deep copy list of raw_text_inputs, or null if the list is empty or doesn't exist.
/obj/item/paper/proc/copy_raw_text()
	if(!LAZYLEN(raw_text_inputs))
		return null

	var/list/datum/paper_input/copy_text = list()

	for(var/datum/paper_input/existing_input as anything in raw_text_inputs)
		copy_text += existing_input.make_copy()

	return copy_text

/// Returns a deep copy list of raw_field_input_data, or null if the list is empty or doesn't exist.
/obj/item/paper/proc/copy_field_text()
	if(!LAZYLEN(raw_field_input_data))
		return null

	var/list/datum/paper_field/copy_text = list()

	for(var/datum/paper_field/existing_input as anything in raw_field_input_data)
		copy_text += existing_input.make_copy()

	return copy_text

/// Returns a deep copy list of raw_stamp_data, or null if the list is empty or doesn't exist. Does not copy overlays or stamp_cache, only the tgui rendered stamps.
/obj/item/paper/proc/copy_raw_stamps()
	if(!LAZYLEN(raw_stamp_data))
		return null

	var/list/datum/paper_field/copy_stamps = list()

	for(var/datum/paper_stamp/existing_input as anything in raw_stamp_data)
		copy_stamps += existing_input.make_copy()

	return copy_stamps

/**
 * This proc copies this sheet of paper to a new
 * sheet. Used by carbon papers and the photocopier machine.
 *
 * Arguments
 * * paper_type - Type path of the new paper to create. Can copy anything to anything.
 * * location - Where to spawn in the new copied paper.
 * * colored - If true, the copied paper will be coloured and will inherit all colours.
 * * greyscale_override - If set to a colour string and coloured is false, it will override the default of COLOR_WEBSAFE_DARK_GRAY when copying.
 */
/obj/item/paper/proc/copy(paper_type = /obj/item/paper, atom/location = loc, colored = TRUE, greyscale_override = null)
	var/obj/item/paper/new_paper = new paper_type(location)

	new_paper.raw_text_inputs = copy_raw_text()
	new_paper.raw_field_input_data = copy_field_text()

	if(colored)
		new_paper.color = color
	else
		var/new_color = greyscale_override || COLOR_WEBSAFE_DARK_GRAY
		for(var/datum/paper_input/text as anything in new_paper.raw_text_inputs)
			text.colour = new_color

		for(var/datum/paper_field/text as anything in new_paper.raw_field_input_data)
			text.field_data.colour = new_color

	new_paper.input_field_count = input_field_count
	new_paper.raw_stamp_data = copy_raw_stamps()
	new_paper.stamp_cache = stamp_cache?.Copy()
	new_paper.update_icon_state()
	copy_overlays(new_paper, TRUE)
	return new_paper

/**
 * This simple helper adds the supplied raw text to the paper, appending to the end of any existing contents.
 *
 * This a God proc that does not care about paper max length and expects sanity checking beforehand if you want to respect it.
 *
 * The caller is expected to handle updating icons and appearance after adding text, to allow for more efficient batch adding loops.
 * * Arguments:
 * * text - The text to append to the paper.
 * * font - The font to use.
 * * color - The font color to use.
 * * bold - Whether this text should be rendered completely bold.
 * * advanced_html - Boolean that is true when the writer has R_FUN permission, which sanitizes less HTML (such as images) from the new paper_input
 */
/obj/item/paper/proc/add_raw_text(text, font, color, bold, advanced_html)
	var/new_input_datum = new /datum/paper_input(
		text,
		font,
		color,
		bold,
		advanced_html,
	)

	input_field_count += get_input_field_count(text)

	LAZYADD(raw_text_inputs, new_input_datum)

/**
 * This simple helper adds the supplied input field data to the paper.
 *
 * It will not overwrite any existing input field data by default and will early return FALSE if this scenario happens unless overwrite is
 * set properly.
 *
 * Other than that, this is a God proc that does not care about max length or out-of-range IDs and expects sanity checking beforehand if
 * you want to respect it.
 *
 * * Arguments:
 * * field_id - The ID number of the field to which this data applies.
 * * text - The text to append to the paper.
 * * font - The font to use.
 * * color - The font color to use.
 * * bold - Whether this text should be rendered completely bold.
 * * overwrite - If TRUE, will overwrite existing field ID's data if it exists.
 */
/obj/item/paper/proc/add_field_input(field_id, text, font, color, bold, signature_name, overwrite = FALSE)
	var/datum/paper_field/field_data_datum = null

	var/is_signature = ((text == "%sign") || (text == "%s"))

	var/field_text = is_signature ? signature_name : text
	var/field_font = is_signature ? SIGNATURE_FONT : font

	for(var/datum/paper_field/field_input in raw_field_input_data)
		if(field_input.field_index == field_id)
			if(!overwrite)
				return FALSE
			field_data_datum = field_input
			break

	if(!field_data_datum)
		var/new_field_input_datum = new /datum/paper_field(
			field_id,
			field_text,
			field_font,
			color,
			bold,
			is_signature,
		)
		LAZYADD(raw_field_input_data, new_field_input_datum)
		return TRUE

	var/new_input_datum = new /datum/paper_input(
		field_text,
		field_font,
		color,
		bold,
	)

	field_data_datum.field_data = new_input_datum;
	field_data_datum.is_signature = is_signature;

	return TRUE

/**
 * This simple helper adds the supplied stamp to the paper, appending to the end of any existing stamps.
 *
 * This a God proc that does not care about stamp max count and expects sanity checking beforehand if you want to respect it.
 *
 * It does however respect the overlay limit and will not apply any overlays past the cap.
 *
 * The caller is expected to handle updating icons and appearance after adding text, to allow for more efficient batch adding loops.
 * * Arguments:
 * * stamp_class - Div class for the stamp.
 * * stamp_x - X coordinate to render the stamp in tgui.
 * * stamp_y - Y coordinate to render the stamp in tgui.
 * * rotation - Degrees of rotation for the stamp to be rendered with in tgui.
 * * stamp_icon_state - Icon state for the stamp as part of overlay rendering.
 */
/obj/item/paper/proc/add_stamp(stamp_class, stamp_x, stamp_y, rotation, stamp_icon_state)
	var/new_stamp_datum = new /datum/paper_stamp(stamp_class, stamp_x, stamp_y, rotation)
	LAZYADD(raw_stamp_data, new_stamp_datum);

	if(LAZYLEN(stamp_cache) > MAX_PAPER_STAMPS_OVERLAYS)
		return

	var/mutable_appearance/stamp_overlay = mutable_appearance('icons/obj/bureaucracy.dmi', "paper_[stamp_icon_state]")
	stamp_overlay.pixel_x = rand(-2, 2)
	stamp_overlay.pixel_y = rand(-3, 2)
	add_overlay(stamp_overlay)
	LAZYADD(stamp_cache, stamp_icon_state)

/// Removes all input and all stamps from the paper, clearing it completely.
/obj/item/paper/proc/clear_paper()
	LAZYNULL(raw_text_inputs)
	LAZYNULL(raw_stamp_data)
	LAZYNULL(raw_field_input_data)
	LAZYNULL(stamp_cache)

	cut_overlays()
	update_appearance()

/obj/item/paper/pickup(user)
	if(contact_poison && ishuman(user))
		var/mob/living/carbon/human/H = user
		var/obj/item/clothing/gloves/G = H.gloves
		if(!istype(G) || !(G.body_parts_covered & HANDS) || HAS_TRAIT(G, TRAIT_FINGERPRINT_PASSTHROUGH) || HAS_TRAIT(H, TRAIT_FINGERPRINT_PASSTHROUGH))
			H.reagents.add_reagent(contact_poison,contact_poison_volume)
			contact_poison = null
	. = ..()

/obj/item/paper/update_icon_state()
	if(LAZYLEN(raw_text_inputs) && show_written_words)
		icon_state = "[initial(icon_state)]_words"
	return ..()

/obj/item/paper/verb/rename()
	set name = "Rename paper"
	set category = "Object"
	set src in usr

	if(!usr.can_read(src) || usr.is_blind() || usr.incapacitated(IGNORE_RESTRAINTS|IGNORE_GRAB) || (isobserver(usr) && !isAdminGhostAI(usr)))
		return
	if(ishuman(usr))
		var/mob/living/carbon/human/H = usr
		if(HAS_TRAIT(H, TRAIT_CLUMSY) && prob(25))
			to_chat(H, span_warning("You cut yourself on the paper! Ahhhh! Ahhhhh!"))
			H.damageoverlaytemp = 9001
			H.update_damage_hud()
			return
	var/n_name = tgui_input_text(usr, "Enter a paper label", "Paper Labelling", max_length = MAX_NAME_LEN)
	if(isnull(n_name) || n_name == "")
		return
	if(((loc == usr || istype(loc, /obj/item/clipboard)) && usr.stat == CONSCIOUS))
		name = "paper[(n_name ? text("- '[n_name]'") : null)]"
	add_fingerprint(usr)
	update_static_data()

/obj/item/paper/examine(mob/user)
	. = ..()
	if(!in_range(user, src) && !isobserver(user))
		. += span_warning("You're too far away to read it!")
		return

	if(is_blind(user))
		to_chat(user, span_warning("You are blind and can't read anything!"))
		return

	if(user.can_read(src))
		ui_interact(user)
		return
	. += span_warning("You cannot read it!")

/obj/item/paper/ui_status(mob/user,/datum/ui_state/state)
	// Are we on fire?  Hard to read if so
	if(resistance_flags & ON_FIRE)
		return UI_CLOSE
	if(camera_holder && can_show_to_mob_through_camera(user) || request_state)
		return UI_UPDATE
	if(!in_range(user, src) && !isobserver(user))
		return UI_CLOSE
	if(user.incapacitated(IGNORE_RESTRAINTS|IGNORE_GRAB) || (isobserver(user) && !isAdminGhostAI(user)))
		return UI_UPDATE
	// Even harder to read if your blind...braile? humm
	// .. or if you cannot read
	if(user.is_blind())
		to_chat(user, span_warning("You are blind and can't read anything!"))
		return UI_CLOSE
	if(!user.can_read(src))
		return UI_CLOSE
	if(in_contents_of(/obj/machinery/door/airlock) || in_contents_of(/obj/item/clipboard))
		return UI_INTERACTIVE
	return ..()

/obj/item/paper/can_interact(mob/user)
	if(in_contents_of(/obj/machinery/door/airlock))
		return TRUE
	return ..()

/obj/item/proc/burn_paper_product_attackby_check(obj/item/attacking_item, mob/living/user, bypass_clumsy = FALSE)
	//can't be put on fire!
	if((resistance_flags & FIRE_PROOF) || !(resistance_flags & FLAMMABLE))
		return FALSE
	//already on fire!
	if(resistance_flags & ON_FIRE)
		return FALSE
	var/ignition_message = attacking_item.ignition_effect(src, user)
	if(!ignition_message)
		return FALSE
	if(!bypass_clumsy && HAS_TRAIT(user, TRAIT_CLUMSY) && prob(10) && Adjacent(user))
		user.visible_message(span_warning("[user] accidentally ignites themself!"), \
							span_userdanger("You miss [src] and accidentally light yourself on fire!"))
		if(user.is_holding(attacking_item)) //checking if they're holding it in case TK is involved
			user.dropItemToGround(attacking_item)
		user.adjust_fire_stacks(attacking_item)
		user.ignite_act()
		return TRUE

	if(user.is_holding(src)) //no TK shit here.
		user.dropItemToGround(src)
	user.visible_message(ignition_message)
	add_fingerprint(user)
	fire_act(attacking_item.get_temperature())
	return TRUE

/obj/item/paper/attackby(obj/item/attacking_item, mob/living/user, params)
	if(burn_paper_product_attackby_check(attacking_item, user))
		SStgui.close_uis(src)
		return

	// Enable picking paper up by clicking on it with the clipboard or folder
	if(istype(attacking_item, /obj/item/clipboard) || istype(attacking_item, /obj/item/folder) || istype(attacking_item, /obj/item/paper_bin))
		attacking_item.attackby(src, user)
		return

	// Handle writing items.
	var/writing_stats = attacking_item.get_writing_implement_details()

	if(!writing_stats)
		ui_interact(user)
		return ..()

	if(writing_stats["interaction_mode"] == MODE_WRITING)
		if(!user.can_write(attacking_item))
			return
		if(get_total_length() >= MAX_PAPER_LENGTH)
			to_chat(user, span_warning("This sheet of paper is full!"))
			return

		ui_interact(user)
		return

	// Handle stamping items.
	if(writing_stats["interaction_mode"] == MODE_STAMPING)
		if(!user.can_read(src) || user.is_blind())
			//The paper's stampable window area is assumed approx 300x400
			add_stamp(writing_stats["stamp_class"], rand(0, 300), rand(0, 400), rand(0, 360), writing_stats["stamp_icon_state"])
			user.visible_message(span_notice("[user] blindly stamps [src] with \the [attacking_item]!"))
			to_chat(user, span_notice("You stamp [src] with \the [attacking_item] the best you can!"))
			playsound(src, 'sound/items/handling/standard_stamp.ogg', 50, vary = TRUE)
		else
			to_chat(user, span_notice("You ready your stamp over the paper! "))
			ui_interact(user)
		return

	ui_interact(user)
	return ..()

/// Secondary right click interaction to quickly stamp things
/obj/item/paper/attackby_secondary(obj/item/attacking_item, mob/living/user, params)
	var/list/writing_stats = attacking_item.get_writing_implement_details()

	if(!length(writing_stats))
		return NONE
	if(writing_stats["interaction_mode"] != MODE_STAMPING)
		return NONE
	if(!user.can_read(src) || user.is_blind()) // Just leftclick instead
		return NONE

	add_stamp(writing_stats["stamp_class"], rand(1, 300), rand(1, 400), stamp_icon_state = writing_stats["stamp_icon_state"])
	user.visible_message(
		span_notice("[user] quickly stamps [src] with [attacking_item] without looking."),
		span_notice("You quickly stamp [src] with [attacking_item] without looking."),
	)
	playsound(src, 'sound/items/handling/standard_stamp.ogg', 50, vary = TRUE)

	return TOOL_ACT_SIGNAL_BLOCKING // Stop the UI from opening.
/**
 * Attempts to ui_interact the paper to the given user, with some sanity checking
 * to make sure the camera still exists via the weakref and that this paper is still
 * attached to it.
 */
/obj/item/paper/proc/show_through_camera(mob/living/user)
	if(!can_show_to_mob_through_camera(user))
		return

	return ui_interact(user)

/obj/item/paper/proc/can_show_to_mob_through_camera(mob/living/user)
	var/obj/machinery/camera/held_to_camera = camera_holder.resolve()

	if(!held_to_camera)
		return FALSE

	if(isAI(user))
		var/mob/living/silicon/ai/ai_user = user
		if(ai_user.control_disabled || (ai_user.stat == DEAD))
			return FALSE

		return TRUE

	if(user.client?.eye != held_to_camera)
		return FALSE

	return TRUE

/obj/item/paper/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/spritesheet/simple/paper),
	)

/obj/item/paper/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PaperSheet", name)
		ui.open()

/obj/item/paper/ui_static_data(mob/user)
	var/list/static_data = list()

	static_data["user_name"] = user.real_name

	static_data["raw_text_input"] = list()
	for(var/datum/paper_input/text_input as anything in raw_text_inputs)
		static_data["raw_text_input"] += list(text_input.to_list())

	static_data["raw_field_input"] = list()
	for(var/datum/paper_field/field_input as anything in raw_field_input_data)
		static_data["raw_field_input"] += list(field_input.to_list())

	static_data["raw_stamp_input"] = list()
	for(var/datum/paper_stamp/stamp_input as anything in raw_stamp_data)
		static_data["raw_stamp_input"] += list(stamp_input.to_list())

	static_data["max_length"] = MAX_PAPER_LENGTH
	static_data["max_input_field_length"] = MAX_PAPER_INPUT_FIELD_LENGTH
	static_data["paper_color"] = color ? color : COLOR_WHITE
	static_data["paper_name"] = name

	static_data["default_pen_font"] = PEN_FONT
	static_data["default_pen_color"] = COLOR_BLACK
	static_data["signature_font"] = FOUNTAIN_PEN_FONT

	return static_data;

/obj/item/paper/ui_data(mob/user)
	var/list/data = list()

	var/obj/item/holding = user.get_active_held_item()
	// Use a clipboard's pen, if applicable
	if(istype(loc, /obj/item/clipboard))
		var/obj/item/clipboard/clipboard = loc
		// This is just so you can still use a stamp if you're holding one. Otherwise, it'll
		// use the clipboard's pen, if applicable.
		if(!istype(holding, /obj/item/stamp) && clipboard.pen)
			holding = clipboard.pen

	data["held_item_details"] = holding?.get_writing_implement_details()

	// If the paper is on an unwritable noticeboard, clear the held item details so it's read-only.
	if(istype(loc, /obj/structure/noticeboard))
		var/obj/structure/noticeboard/noticeboard = loc
		if(!noticeboard.allowed(user))
			data["held_item_details"] = null;

	return data

/obj/item/paper/ui_act(action, params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	var/mob/user = ui.user

	switch(action)
		if("add_stamp")
			var/obj/item/holding = user.get_active_held_item()
			var/stamp_info = holding?.get_writing_implement_details()
			if(!stamp_info || (stamp_info["interaction_mode"] != MODE_STAMPING))
				to_chat(src, span_warning("You can't stamp with the [holding]!"))
				return TRUE

			var/stamp_class = stamp_info["stamp_class"];

			// If the paper is on an unwritable noticeboard, this usually shouldn't be possible.
			if(istype(loc, /obj/structure/noticeboard))
				var/obj/structure/noticeboard/noticeboard = loc
				if(!noticeboard.allowed(user))
					log_paper("[key_name(user)] tried to add stamp to [name] when it was on an unwritable noticeboard: \"[stamp_class]\"")
					return TRUE

			var/stamp_x = text2num(params["x"])
			var/stamp_y = text2num(params["y"])
			var/stamp_rotation = text2num(params["rotation"])
			var/stamp_icon_state = stamp_info["stamp_icon_state"]

			if (LAZYLEN(raw_stamp_data) >= MAX_PAPER_STAMPS)
				to_chat(usr, pick("You try to stamp but you miss!", "There is no where else you can stamp!"))
				return TRUE

			add_stamp(stamp_class, stamp_x, stamp_y, stamp_rotation, stamp_icon_state)
			user.visible_message(span_notice("[user] stamps [src] with \the [holding.name]!"), span_notice("You stamp [src] with \the [holding.name]!"))
			playsound(src, 'sound/items/handling/standard_stamp.ogg', 50, vary = TRUE)

			update_appearance()
			update_static_data_for_all_viewers()
			return TRUE
		if("add_text")
			var/paper_input = params["text"]
			var/this_input_length = length(paper_input)

			if(this_input_length == 0)
				to_chat(user, pick("Writing block strikes again!", "You forgot to write anthing!"))
				return TRUE

			// If the paper is on an unwritable noticeboard, this usually shouldn't be possible.
			if(istype(loc, /obj/structure/noticeboard))
				var/obj/structure/noticeboard/noticeboard = loc
				if(!noticeboard.allowed(user))
					log_paper("[key_name(user)] tried to write to [name] when it was on an unwritable noticeboard: \"[paper_input]\"")
					return TRUE

			var/obj/item/holding = user.get_active_held_item()
			// Use a clipboard's pen, if applicable
			if(istype(loc, /obj/item/clipboard))
				var/obj/item/clipboard/clipboard = loc
				// This is just so you can still use a stamp if you're holding one. Otherwise, it'll
				// use the clipboard's pen, if applicable.
				if(!istype(holding, /obj/item/stamp) && clipboard.pen)
					holding = clipboard.pen

			// As of the time of writing, can_write outputs a message to the user so we don't have to.
			if(!user.can_write(holding))
				return TRUE

			var/current_length = get_total_length()
			var/new_length = current_length + this_input_length

			// tgui should prevent this outcome.
			if(new_length > MAX_PAPER_LENGTH)
				log_paper("[key_name(user)] tried to write to [name] when it would exceed the length limit by [new_length - MAX_PAPER_LENGTH] characters: \"[paper_input]\"")
				return TRUE

			// Safe to assume there are writing implement details as user.can_write(...) fails with an invalid writing implement.
			var/writing_implement_data = holding.get_writing_implement_details()

			add_raw_text(paper_input, writing_implement_data["font"], writing_implement_data["color"], writing_implement_data["use_bold"], check_rights_for(user?.client, R_FUN))

			log_paper("[key_name(user)] wrote to [name]: \"[paper_input]\"")
			to_chat(user, "You have added to your paper masterpiece!");

			update_static_data_for_all_viewers()
			update_appearance()
			return TRUE
		if("fill_input_field")
			// If the paper is on an unwritable noticeboard, this usually shouldn't be possible.
			if(istype(loc, /obj/structure/noticeboard))
				var/obj/structure/noticeboard/noticeboard = loc
				if(!noticeboard.allowed(user))
					log_paper("[key_name(user)] tried to write to the input fields of [name] when it was on an unwritable noticeboard!")
					return TRUE

			var/obj/item/holding = user.get_active_held_item()
			// Use a clipboard's pen, if applicable
			if(istype(loc, /obj/item/clipboard))
				var/obj/item/clipboard/clipboard = loc
				// This is just so you can still use a stamp if you're holding one. Otherwise, it'll
				// use the clipboard's pen, if applicable.
				if(!istype(holding, /obj/item/stamp) && clipboard.pen)
					holding = clipboard.pen

			// As of the time of writing, can_write outputs a message to the user so we don't have to.
			if(!user.can_write(holding))
				return TRUE

			// Safe to assume there are writing implement details as user.can_write(...) fails with an invalid writing implement.
			var/writing_implement_data = holding.get_writing_implement_details()
			var/list/field_data = params["field_data"]

			for(var/field_key in field_data)
				var/field_text = field_data[field_key]
				var/text_length = length(field_text)
				if(text_length > MAX_PAPER_INPUT_FIELD_LENGTH)
					log_paper("[key_name(user)] tried to write to field [field_key] with text over the max limit ([text_length] out of [MAX_PAPER_INPUT_FIELD_LENGTH]) with the following text: [field_text]")
					return TRUE
				if(text2num(field_key) >= input_field_count)
					log_paper("[key_name(user)] tried to write to invalid field [field_key] (when the paper only has [input_field_count] fields) with the following text: [field_text]")
					return TRUE

				if(!add_field_input(field_key, field_text, writing_implement_data["font"], writing_implement_data["color"], writing_implement_data["use_bold"], user.real_name))
					log_paper("[key_name(user)] tried to write to field [field_key] when it already has data, with the following text: [field_text]")

			update_static_data_for_all_viewers()
			return TRUE

/obj/item/paper/proc/get_input_field_count(raw_text)
	var/static/regex/field_regex = new(@"\[_+\]","g")

	var/counter = 0
	while(field_regex.Find(raw_text))
		counter++

	return counter

/obj/item/paper/ui_host(mob/user)
	if(istype(loc, /obj/structure/noticeboard))
		return loc
	return ..()

/obj/item/paper/proc/get_total_length()
	var/total_length = 0
	for(var/datum/paper_input/entry as anything in raw_text_inputs)
		total_length += length(entry.raw_text)

	return total_length

/// Get a single string representing the text on a page
/obj/item/paper/proc/get_raw_text()
	var/paper_contents = ""
	for(var/datum/paper_input/line as anything in raw_text_inputs)
		paper_contents += line.raw_text + "/"
	return paper_contents

/// A single instance of a saved raw input onto paper.
/datum/paper_input
	/// Raw, unsanitised, unparsed text for an input.
	var/raw_text = ""
	/// Font to draw the input with.
	var/font = ""
	/// Colour to draw the input with.
	var/colour = ""
	/// Whether to render the font bold or not.
	var/bold = FALSE
	/// Whether the creator of this input field has the R_FUN permission, thus allowing less sanitization
	var/advanced_html = FALSE

/datum/paper_input/New(_raw_text, _font, _colour, _bold, _advanced_html)
	raw_text = _raw_text
	font = _font
	colour = _colour
	bold = _bold
	advanced_html = _advanced_html

/datum/paper_input/proc/make_copy()
	return new /datum/paper_input(raw_text, font, colour, bold, advanced_html)

/datum/paper_input/proc/to_list()
	return list(
		raw_text = raw_text,
		font = font,
		color = colour,
		bold = bold,
		advanced_html = advanced_html,
	)

/// Returns the raw contents of the input as html, with **ZERO SANITIZATION**
/datum/paper_input/proc/to_raw_html()
	var/final = raw_text
	if(font)
		final = "<font face='[font]'>[final]</font>"
	if(colour)
		final = "<font color='[colour]'>[final]</font>"
	if(bold)
		final = "<b>[final]</b>"
	return final

/// A single instance of a saved stamp on paper.
/datum/paper_stamp
	/// Asset class of the for rendering in tgui
	var/class = ""
	/// X position of stamp.
	var/stamp_x = 0
	/// Y position of stamp.
	var/stamp_y = 0
	/// Rotation of stamp in degrees. 0 to 359.
	var/rotation = 0

/datum/paper_stamp/New(_class, _stamp_x, _stamp_y, _rotation)
	class = _class
	stamp_x = _stamp_x
	stamp_y = _stamp_y
	rotation = _rotation

/datum/paper_stamp/proc/make_copy()
	return new /datum/paper_stamp(class, stamp_x, stamp_y, rotation)

/datum/paper_stamp/proc/to_list()
	return list(
		class = class,
		x = stamp_x,
		y = stamp_y,
		rotation = rotation,
	)

/// A reference to some data that replaces a modifiable input field at some given index in paper raw input parsing.
/datum/paper_field
	/// When tgui parses the raw input, if it encounters a field_index matching the nth user input field, it will disable it and replace it with the field_data.
	var/field_index = -1
	/// The data that tgui should substitute in-place of the input field when parsing.
	var/datum/paper_input/field_data = null
	/// If TRUE, requests tgui to render this field input in a more signature-y style.
	var/is_signature = FALSE

/datum/paper_field/New(_field_index, raw_text, font, colour, bold, _is_signature)
	field_index = _field_index
	field_data = new /datum/paper_input(raw_text, font, colour, bold)
	is_signature = _is_signature

/datum/paper_field/proc/make_copy()
	return new /datum/paper_field(field_index, field_data.raw_text, field_data.font, field_data.colour, field_data.bold, is_signature)

/datum/paper_field/proc/to_list()
	return list(
		field_index = field_index,
		field_data = field_data.to_list(),
		is_signature = is_signature,
	)

/obj/item/paper/construction

/obj/item/paper/construction/Initialize(mapload)
	. = ..()
	color = pick(COLOR_RED, COLOR_LIME, COLOR_LIGHT_ORANGE, COLOR_DARK_PURPLE, COLOR_FADED_PINK, COLOR_BLUE_LIGHT)

/obj/item/paper/natural
	color = COLOR_OFF_WHITE

/obj/item/paper/crumpled
	name = "paper scrap"
	icon_state = "scrap"
	slot_flags = null
	show_written_words = FALSE

/obj/item/paper/crumpled/bloody
	icon_state = "scrap_bloodied"

/obj/item/paper/crumpled/muddy
	icon_state = "scrap_mud"

/obj/item/paper/selfdestruct
	name = "Self-Incinerating Note"
	desc = "A note that will incinerate itself after being read."
	can_be_folded = FALSE
	var/has_been_read = FALSE
	var/armed = FALSE

/obj/item/paper/selfdestruct/examine(mob/user)
	. = ..()

	if(!has_been_read)
		return

	. += span_warning("This feels warm to the touch.")


/obj/item/paper/selfdestruct/ui_interact(mob/user, datum/tgui/ui)
	. = ..()

	if(ui && armed && !has_been_read)
		playsound(user, 'sound/machines/click.ogg', 25)
		to_chat(user, span_warning("You hear a faint click as you open the note. It feels strangely warm."))

		has_been_read = TRUE

		addtimer(CALLBACK(src, PROC_REF(combust_now)), 20 SECONDS, TIMER_UNIQUE)
	return

/obj/item/paper/selfdestruct/proc/combust_now(mob/user_who_initiated)
	if(!src || QDELETED(src))
		return

	SStgui.close_uis(src)

	var/mob/living/holder = null
	if(ismob(loc))
		holder = loc

	if(holder)
		to_chat(holder, span_warning("[src] suddenly bursts into flames in your hands!"))
	else if(get_turf(src))
		var/atom/turf_location = get_turf(src)
		turf_location.visible_message(span_warning("[src] suddenly bursts into flames on the ground!"))
	else if(loc)
		loc.visible_message(span_warning("[src] suddenly bursts into flames!"))

	fire_act(100)

/obj/item/paper/selfdestruct/AltClick(mob/living/user, obj/item/used_item)
	if(!armed)
		to_chat(user, span_warning("You arm the incineration mechanism."))
		armed = TRUE
		return

	return

*/
