/obj/item/tool/surgicaldrill
	name = "surgical drill"
	desc = "You can drill using this item. You dig?"
	icon_state = "surgical_drill"
	item_state = "surgical_drill"
	item_icons = list(
		slot_l_hand_str = 'icons/mob/inhands/equipment/medical_lefthand.dmi',
		slot_r_hand_str = 'icons/mob/inhands/equipment/medical_righthand.dmi',
		)
	hitsound = WORKSOUND_DRIVER_TOOL
	worksound = WORKSOUND_DRIVER_TOOL
	matter = list(MATERIAL_STEEL = 4, MATERIAL_PLASTIC = 2)
	flags = CONDUCT
	force = WEAPON_FORCE_DANGEROUS
	armor_divisor = ARMOR_PEN_MODERATE
	w_class = ITEM_SIZE_NORMAL
	origin_tech = list(TECH_MATERIAL = 1, TECH_BIO = 1)
	attack_verb = list("drilled")
	tool_qualities = list(QUALITY_DRILLING = 30)
	spawn_tags = SPAWN_TAG_SURGERY_TOOL

	use_power_cost = 0.24
	suitable_cell = /obj/item/cell/small
