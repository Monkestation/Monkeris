/*
 * Toy crossbow
 */

/obj/item/gun/projectile/foamcrossbow
	name = "foam dart crossbow"
	desc = "A weapon favored by many overactive children. Ages 8 and up."
	icon = 'icons/obj/guns/energy.dmi'
	icon_state = "crossbow"
	item_state = "foamcrossbow"
	item_icons = list(
		slot_l_hand_str =  'icons/mob/inhands/lefthand.dmi',
		slot_r_hand_str = 'icons/mob/inhands/righthand.dmi',
		)
	w_class = ITEM_SIZE_SMALL
	matter = list(MATERIAL_PLASTIC = 2)
	spawn_tags = SPAWN_TAG_TOY_WEAPON
	load_method = SINGLE_CASING
	caliber = CAL_DART
	price_tag = 5 // toy
	fire_sound = 'sound/weapons/empty.ogg'
	max_shells = 5
	safety = FALSE
	restrict_safety = TRUE
	icon_contained = FALSE
