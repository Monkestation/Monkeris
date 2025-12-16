/obj/item/tool/cautery
	name = "cautery"
	desc = "This stops bleeding."
	icon_state = "cautery"
	item_state = "cautery"
	item_icons = list(
		slot_l_hand_str = 'icons/mob/inhands/equipment/medical_lefthand.dmi',
		slot_r_hand_str = 'icons/mob/inhands/equipment/medical_righthand.dmi',
		)
	matter = list(MATERIAL_STEEL = 5, MATERIAL_GLASS = 2)
	flags = CONDUCT
	origin_tech = list(TECH_MATERIAL = 1, TECH_BIO = 1)
	attack_verb = list("burnt")
	tool_qualities = list(QUALITY_CAUTERIZING = 30)
	spawn_tags = SPAWN_TAG_SURGERY_TOOL
