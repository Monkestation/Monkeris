/obj/item/tool/bonesetter
	name = "bone setter"
	icon_state = "bone setter"
	item_state = "bone_setter"
	item_icons = list(
		slot_l_hand_str = 'icons/mob/inhands/equipment/medical_lefthand.dmi',
		slot_r_hand_str = 'icons/mob/inhands/equipment/medical_righthand.dmi',
		)
	w_class = ITEM_SIZE_SMALL
	matter = list(MATERIAL_STEEL = 4)
	flags = CONDUCT
	attack_verb = list("attacked", "hit", "bludgeoned")
	tool_qualities = list(QUALITY_BONE_SETTING = 30)
	spawn_tags = SPAWN_TAG_SURGERY_TOOL
