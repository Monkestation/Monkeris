//Also contains /obj/structure/closet/body_bag because I doubt anyone would think to look for bodybags in /object/structures

/obj/item/bodybag
	name = "body bag"
	desc = "A folded bag designed for the storage and transportation of cadavers."
	icon = 'icons/obj/bodybag.dmi'
	icon_state = "bodybag_folded"
	w_class = ITEM_SIZE_SMALL
	price_tag = 10
	rarity_value = 10
	spawn_tags = SPAWN_TAG_MEDICAL

/obj/item/bodybag/attack_self(mob/user)
	var/obj/structure/closet/body_bag/R = new /obj/structure/closet/body_bag(user.loc)
	R.add_fingerprint(user)
	qdel(src)


/obj/structure/closet/body_bag
	name = "body bag"
	desc = "A plastic bag designed for the storage and transportation of cadavers."
	icon = 'icons/obj/bodybag.dmi'
	icon_state = "bodybag"
	open_sound = 'sound/items/zip.ogg'
	close_sound = 'sound/items/zip.ogg'
	var/item_path = /obj/item/bodybag
	density = FALSE
	storage_capacity = (MOB_MEDIUM * 2) - 1
	var/contains_body = 0
	layer = LOW_OBJ_LAYER+0.01

/obj/structure/closet/body_bag/attackby(W as obj, mob/user)
	if (istype(W, /obj/item/pen))
		var/t = input(user, "What would you like the label to be?", text("[]", src.name), null)  as text
		if (user.get_active_held_item() != W)
			return
		if (!in_range(src, user) && src.loc != user)
			return
		t = sanitizeSafe(t, MAX_NAME_LEN)
		if (t)
			src.name = "body bag - "
			src.name += t
			src.overlays += image(src.icon, "bodybag_label")
		else
			src.name = "body bag"
	//..() //Doesn't need to run the parent. Since when can fucking bodybags be welded shut? -Agouri
		return
	else if(istype(W, /obj/item/tool/wirecutters))
		to_chat(user, "You cut the tag off the bodybag.")
		src.name = "body bag"
		src.overlays.Cut()
		return

/obj/structure/closet/body_bag/store_mobs(stored_units)
	contains_body = ..()
	return contains_body

/obj/structure/closet/body_bag/close()
	if(..())
		density = FALSE
		return 1
	return 0

/obj/structure/closet/body_bag/MouseDrop(over_object, src_location, over_location)
	..()
	if((over_object == usr && (in_range(src, usr) || usr.contents.Find(src))))
		if(!ishuman(usr))	return
		if(opened)	return 0
		if(contents.len)	return 0
		visible_message("[usr] folds up the [src.name]")
		new item_path(get_turf(src))
		QDEL_IN(src, 0)
		return

/obj/structure/closet/body_bag/update_icon()
    if(opened)
        icon_state = "bodybag_open"
    else
        if(contains_body > 0)
            icon_state = "bodybag_full"
        else
            icon_state = "bodybag_closed"

/obj/item/bodybag/expanded
	name = "body bag"
	desc = "A folded bag designed for the storage and transportation of cadavers. This one is extra large."
	w_class = ITEM_SIZE_NORMAL
	spawn_blacklisted = TRUE

/obj/item/bodybag/expanded/attack_self(mob/user)
	var/obj/structure/closet/body_bag/expanded/R = new /obj/structure/closet/body_bag/expanded(user.loc)
	R.add_fingerprint(user)
	qdel(src)

/obj/structure/closet/body_bag/expanded
	name = "expanded body bag"
	desc = "A plastic bag designed for the storage and transportation of cadavers. This one is extra large."
	item_path = /obj/item/bodybag/expanded
	storage_capacity = (MOB_LARGE)

/obj/item/bodybag/cryobag
	name = "stasis bag"
	desc = "A folded, non-reusable bag designed to prevent additional damage to an occupant. Especially useful if short on time or in \
	a hostile enviroment."
	description_info = "You can scan the patient inside by clicking the bag with an health analyzer"
	icon = 'icons/obj/cryobag.dmi'
	icon_state = "bodybag_folded"
	origin_tech = list(TECH_BIO = 4)
	matter = list(MATERIAL_STEEL = 10, MATERIAL_PLASTIC = 6, MATERIAL_SILVER = 2)
	matter_reagents = list("coolant" = 40)
	price_tag = 250

/obj/item/bodybag/cryobag/attack_self(mob/user)
	var/obj/structure/closet/body_bag/cryobag/R = new /obj/structure/closet/body_bag/cryobag(user.loc)
	R.add_fingerprint(user)
	qdel(src)

/obj/structure/closet/body_bag/cryobag
	name = "stasis bag"
	desc = "A non-reusable plastic bag designed to prevent additional damage to an occupant. Especially useful if short on time or in \
	a hostile enviroment. This one features a much more advanced design that preserves its occupant in cryostasis."
	icon = 'icons/obj/cryobag.dmi'
	item_path = /obj/item/bodybag/cryobag
	store_misc = 0
	store_items = 0
	rarity_value = 20
	var/used = 0
	var/obj/item/tank/tank

/obj/structure/closet/body_bag/cryobag/New()
	tank = new /obj/item/tank/emergency_oxygen(null) //It's in nullspace to prevent ejection when the bag is opened.
	..()

/obj/structure/closet/body_bag/cryobag/Destroy()
	qdel(tank)
	tank = null
	return ..()

/obj/structure/closet/body_bag/cryobag/open()
	. = ..()
	if(used)
		var/obj/item/O = new/obj/item(src.loc)
		O.name = "used stasis bag"
		O.icon = src.icon
		O.icon_state = "bodybag_used"
		O.desc = "A used bodybag. It's nothing but trash now."
		O.matter = list(MATERIAL_STEEL = 5, MATERIAL_PLASTIC = 3, MATERIAL_SILVER = 1)
		O.matter_reagents = list("coolant" = 20)
		qdel(src)

/obj/structure/closet/body_bag/cryobag/Entered(atom/movable/AM)
	if(ishuman(AM))
		var/mob/living/carbon/human/H = AM
		H.EnterStasis()
		src.used = 1
	..()

/obj/structure/closet/body_bag/cryobag/Exited(atom/movable/AM)
	if(ishuman(AM))
		var/mob/living/carbon/human/H = AM
		H.ExitStasis()
	..()

/obj/structure/closet/body_bag/cryobag/return_air() //Used to make stasis bags protect from vacuum.
	if(tank)
		return tank.air_contents
	..()

/obj/structure/closet/body_bag/cryobag/examine(mob/user, extra_description = "")
	if(Adjacent(user)) //The bag's rather thick and opaque from a distance.
		extra_description += span_info("You peer into \the [src].")
		..(user, extra_description)
		for(var/mob/living/L in contents)
			L.examine(user)
	else
		..(user, extra_description)

/obj/structure/closet/body_bag/attackby(obj/item/W, mob/user)
	..() // Allows to use health analyzer on the mob inside
