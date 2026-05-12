/obj/item/storage/briefcase
	name = "briefcase"
	desc = "It's made of AUTHENTIC faux-leather and has a price-tag still attached. Its owner must be a real professional."
	icon_state = "briefcase"
	item_state = "briefcase"
	item_icons = list(
		slot_l_hand_str = 'icons/mob/inhands/equipment/briefcase_lefthand.dmi',
		slot_r_hand_str = 'icons/mob/inhands/equipment/briefcase_righthand.dmi',
		)
	flags = CONDUCT
	force = WEAPON_FORCE_NORMAL
	throwforce = WEAPON_FORCE_NORMAL
	throw_speed = 1
	throw_range = 4
	w_class = ITEM_SIZE_BULKY
	max_w_class = ITEM_SIZE_NORMAL
	max_storage_space = 16
	matter = list(MATERIAL_BIOMATTER = 8, MATERIAL_PLASTIC = 4)
	price_tag = 90

/obj/item/storage/briefcase/club

/obj/item/storage/briefcase/club/populate_contents()
	var/list/things2spawn = list(
		/obj/item/card/id/smallrental,
		/obj/item/card/id/smallrental2,
		/obj/item/card/id/smallrental3,
		/obj/item/card/id/smallrental4,
		/obj/item/card/id/mediumrental,
		/obj/item/card/id/mediumrental2,
		/obj/item/card/id/mediumrental3,
		/obj/item/card/id/largerental)
	for(var/path in things2spawn)
		new path(src)
