/*
CONTAINS:
BEDSHEETS
LINEN BINS
*/

/obj/item/bedsheet
	name = "bedsheet"
	desc = "A surprisingly soft linen bedsheet."
	icon = 'icons/obj/bedsheets.dmi'
	icon_state = "sheet"
	item_state = "sheet"
	item_icons = list(
		slot_l_hand_str = 'icons/mob/inhands/misc/bedsheet_lefthand.dmi',
		slot_r_hand_str = 'icons/mob/inhands/misc/bedsheet_righthand.dmi',
		)
	layer = 4
	throwforce = WEAPON_FORCE_HARMLESS
	throw_speed = 1
	throw_range = 2
	w_class = ITEM_SIZE_NORMAL
	var/rolled = FALSE
	var/folded = FALSE
	var/inuse = FALSE

/obj/item/bedsheet/Initialize(mapload, nfolded=FALSE)
	.=..()
	folded = nfolded
	update_icon()

/obj/item/bedsheet/afterattack(atom/A, mob/user)
	if(!user || user.incapacitated() || !user.Adjacent(A) || istype(A, /obj/structure/bedsheetbin) || istype(A, /obj/item/storage/))
		return
	if(toggle_fold(user))
		user.drop_item()
		forceMove(get_turf(A))
		add_fingerprint(user)
		return

/obj/item/bedsheet/proc/toggle_roll(mob/living/user, no_message = FALSE)
	if(!user)
		return FALSE
	if(inuse)
		to_chat(user, "Someone already using \the [src]")
		return FALSE
	inuse = TRUE
	if (do_after(user, 6, src, incapacitation_flags = INCAPACITATION_UNCONSCIOUS))
		if(user.loc != loc)
			user.do_attack_animation(src)
		playsound(get_turf(loc), "rustle", 15, 1, -5)
		if(!no_message)
			user.visible_message(
				span_notice("\The [user] [rolled ? "unrolled" : "rolled"] \the [src]."),
				span_notice("You [rolled ? "unrolled" : "rolled"] \the [src].")
			)
		if(!rolled)
			rolled = TRUE
		else
			rolled = FALSE
			if(!user.resting && get_turf(src) == get_turf(user))
				user.lay_down()
		inuse = FALSE
		update_icon()
		return TRUE
	inuse = FALSE
	return FALSE

/obj/item/bedsheet/proc/toggle_fold(mob/user, no_message=FALSE)
	if(!user)
		return FALSE
	if(inuse)
		to_chat(user, "Someone already using \the [src]")
		return FALSE
	inuse = TRUE
	if (do_after(user, 25, src))
		rolled = FALSE
		if(user.loc != loc)
			user.do_attack_animation(src)
		playsound(get_turf(loc), "rustle", 15, 1, -5)
		if(!no_message)
			user.visible_message(
				span_notice("\The [user] [folded ? "unfolded" : "folded"] \the [src]."),
				span_notice("You [folded ? "unfolded" : "folded"] \the [src].")
			)
		if(!folded)
			folded = TRUE
			w_class = ITEM_SIZE_SMALL
		else

			folded = FALSE
			w_class =ITEM_SIZE_NORMAL
		inuse = FALSE
		update_icon()
		return TRUE
	inuse = FALSE
	return FALSE

/obj/item/bedsheet/verb/fold_verb()
	set name = "Fold bedsheet"
	set category = "Object"
	set src in view(1)

	if(ismob(loc))
		to_chat(usr, "Drop \the [src] first.")
	else if(ishuman(usr))
		toggle_fold(usr)

/obj/item/bedsheet/verb/roll_verb()
	set name = "Roll bedsheet"
	set category = "Object"
	set src in view(1)

	if(folded)
		to_chat(usr, "Unfold \the [src] first.")
	else if(ismob(loc))
		to_chat(usr, "Drop \the [src] first.")
	else if(ishuman(usr))
		toggle_roll(usr)

/obj/item/bedsheet/attackby(obj/item/I, mob/user)
	if(is_sharp(I))
		user.visible_message(
			span_notice("\The [user] begins cutting up \the [src] with \a [I]."),
			span_notice("You begin cutting up \the [src] with \the [I].")
		)
		if(do_after(user, 50, src))
			to_chat(user, span_notice("You cut \the [src] into pieces!"))
			for(var/i in 1 to rand(2,5))
				new /obj/item/reagent_containers/glass/rag(get_turf(src))
			qdel(src)
		return
	..()

/obj/item/bedsheet/attack_hand(mob/user)
	if(!user || user.incapacitated(INCAPACITATION_UNCONSCIOUS))
		return
	if(!folded)
		toggle_roll(user)
	else
		.=..()
	add_fingerprint(user)

/obj/item/bedsheet/MouseDrop(over_object, src_location, over_location)
	..()
	if(over_object == usr || istype(over_object, /atom/movable/screen/inventory/hand))
		if(!ishuman(over_object))
			return
		if(!folded)
			toggle_fold(usr)
		if(folded)
			pickup(usr)

/obj/item/bedsheet/update_icon()
	if (folded)
		icon_state = "sheet-folded"
	else if (rolled)
		icon_state = "sheet-rolled"
	else
		icon_state = initial(icon_state)

/obj/item/bedsheet/grey
	icon_state = "sheetgrey"
	item_state = "sheetgrey"

/obj/item/bedsheet/red
	icon_state = "sheetred"
	item_state = "sheetred"

/obj/item/bedsheet/orange
	icon_state = "sheetorange"
	item_state = "sheetorange"

/obj/item/bedsheet/yellow
	icon_state = "sheetyellow"
	item_state = "sheetyellow"

/obj/item/bedsheet/green
	icon_state = "sheetgreen"
	item_state = "sheetgreen"

/obj/item/bedsheet/blue
	icon_state = "sheetblue"
	item_state = "sheetblue"

/obj/item/bedsheet/purple
	icon_state = "sheetpurple"
	item_state = "sheetpurple"

/obj/item/bedsheet/brown
	icon_state = "sheetbrown"
	item_state = "sheetbrown"

/obj/item/bedsheet/black
	icon_state = "sheetblack"
	item_state = "sheetblack"

/obj/item/bedsheet/rainbow
	icon_state = "sheetrainbow"
	item_state = "sheetrainbow"

/obj/item/bedsheet/clown
	icon_state = "sheetclown"
	item_state = "sheetclown"

/obj/item/bedsheet/mime
	icon_state = "sheetmime"
	item_state = "sheetmime"

/obj/item/bedsheet/chap
	icon_state = "sheetchap"
	item_state = "sheetchap"

/obj/item/bedsheet/medical
	icon_state = "sheetmedical"
	item_state = "sheetmedical"

/obj/item/bedsheet/rd
	icon_state = "sheetrd"
	item_state = "sheetrd"

/obj/item/bedsheet/cmo
	icon_state = "sheetcmo"
	item_state = "sheetcmo"

/obj/item/bedsheet/hos
	icon_state = "sheethos"
	item_state = "sheethos"

/obj/item/bedsheet/ce
	icon_state = "sheetce"
	item_state = "sheetce"

/obj/item/bedsheet/hop
	icon_state = "sheethop"
	item_state = "sheethop"

/obj/item/bedsheet/captain
	icon_state = "sheetcaptain"
	item_state = "sheetcaptain"

/obj/item/bedsheet/ian
	icon_state = "sheetian"
	item_state = "sheetian"

/obj/item/bedsheet/nt
	icon_state = "sheetNT"
	item_state = "sheetNT"

/obj/item/bedsheet/cm
	icon_state = "sheetcentcom"
	item_state = "sheetcentcom"

/obj/item/bedsheet/syndie
	icon_state = "sheetsyndie"
	item_state = "sheetsyndie"

/obj/item/bedsheet/cult
	icon_state = "sheetcult"
	item_state = "sheetcult"

/obj/item/bedsheet/wizard
	icon_state = "sheetwiz"
	item_state = "sheetwiz"

/obj/item/bedsheet/qm
	icon_state = "sheetqm"
	item_state = "sheetqm"

/obj/item/bedsheet/usa
	icon_state = "sheetUSA"
	item_state = "sheetUSA"

/obj/item/bedsheet/cosmos
	icon_state = "sheetcosmos"
	item_state = "sheetcosmos"

/obj/structure/bedsheetbin
	name = "linen bin"
	desc = "A linen bin. It looks rather cosy."
	icon = 'icons/obj/structures.dmi'
	icon_state = "linenbin-full"
	anchored = TRUE
	var/amount = 20
	var/list/sheets = list()
	var/obj/item/hidden


/obj/structure/bedsheetbin/examine(mob/user, extra_description = "")
	if(amount < 1)
		extra_description += "There is no bed sheets in the bin."
	else if(amount == 1)
		extra_description += "There is one bed sheet in the bin."
	else
		extra_description += "There are [amount] bed sheets in the bin."

	..(user, extra_description)

/obj/structure/bedsheetbin/update_icon()
	if(amount < 1)
		icon_state = "linenbin-empty"
	else if(amount < 5)
		icon_state = "linenbin-half"
	else
		icon_state = "linenbin-full"

/obj/structure/bedsheetbin/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/bedsheet))
		user.drop_item()
		I.loc = src
		sheets.Add(I)
		amount++
		to_chat(user, span_notice("You put [I] in [src]."))
	//make sure there's sheets to hide it among, make sure nothing else is hidden in there.
	else if(amount && !hidden && I.w_class < ITEM_SIZE_BULKY)
		user.drop_item()
		I.loc = src
		hidden = I
		to_chat(user, span_notice("You hide [I] among the sheets."))

/obj/structure/bedsheetbin/attack_hand(mob/user)
	if(amount >= 1)
		amount--

		var/obj/item/bedsheet/B
		if(sheets.len > 0)
			B = sheets[sheets.len]
			sheets.Remove(B)

		else
			B = new /obj/item/bedsheet(loc, TRUE)
		B.loc = user.loc

		user.put_in_hands(B)
		to_chat(user, span_notice("You take [B] out of [src]."))

		if(hidden)
			hidden.loc = user.loc
			to_chat(user, span_notice("[hidden] falls out of [B]!"))
			hidden = null


	add_fingerprint(user)

/obj/structure/bedsheetbin/attack_tk(mob/user)
	if(amount >= 1)
		amount--

		var/obj/item/bedsheet/B
		if(sheets.len > 0)
			B = sheets[sheets.len]
			sheets.Remove(B)

		else
			B = new /obj/item/bedsheet(loc, TRUE)

		B.loc = loc
		to_chat(user, span_notice("You telekinetically remove [B] from [src]."))
		update_icon()

		if(hidden)
			hidden.loc = loc
			hidden = null


	add_fingerprint(user)
