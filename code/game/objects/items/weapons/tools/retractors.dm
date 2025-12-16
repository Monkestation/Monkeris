/obj/item/tool/retractor
	name = "retractor"
	desc = "Retracts stuff."
	icon_state = "retractor"
	item_state = "retractor"
	item_icons = list(
		slot_l_hand_str = 'icons/mob/inhands/equipment/medical_lefthand.dmi',
		slot_r_hand_str = 'icons/mob/inhands/equipment/medical_righthand.dmi',
		)
	matter = list(MATERIAL_STEEL = 2)
	flags = CONDUCT
	origin_tech = list(TECH_MATERIAL = 1, TECH_BIO = 1)
	tool_qualities = list(QUALITY_RETRACTING = 30)
	spawn_tags = SPAWN_TAG_SURGERY_TOOL
