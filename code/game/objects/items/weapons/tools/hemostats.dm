/obj/item/tool/hemostat
	name = "hemostat"
	desc = "You think you have seen this before."
	icon_state = "hemostat"
	item_state = "hemostat"
	item_icons = list(
		slot_l_hand_str = 'icons/mob/inhands/equipment/medical_lefthand.dmi',
		slot_r_hand_str = 'icons/mob/inhands/equipment/medical_righthand.dmi',
		)
	matter = list(MATERIAL_STEEL = 2)
	flags = CONDUCT
	origin_tech = list(TECH_MATERIAL = 1, TECH_BIO = 1)
	attack_verb = list("attacked", "pinched")
	hitsound = 'sound/weapons/melee/lightstab.ogg'
	tool_qualities = list(QUALITY_CLAMPING = 30)
	spawn_tags = SPAWN_TAG_SURGERY_TOOL
