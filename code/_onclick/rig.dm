/mob/living/MiddleClickOn(atom/A, params)
	if(get_preference_value(/datum/client_preference/hardsuit_activation) == GLOB.PREF_MIDDLE_CLICK)
		if(HardsuitClickOn(A))
			return
	..()

/mob/living/AltClickOn(atom/A, params)
	if(get_preference_value(/datum/client_preference/hardsuit_activation) == GLOB.PREF_ALT_CLICK)
		if(HardsuitClickOn(A))
			return
	..()

/mob/living/CtrlClickOn(atom/A, params)
	if(get_preference_value(/datum/client_preference/hardsuit_activation) == GLOB.PREF_CTRL_CLICK)
		if(HardsuitClickOn(A))
			return
	..()

/mob/living/CtrlShiftClickOn(atom/A, params)
	if(get_preference_value(/datum/client_preference/hardsuit_activation) == GLOB.PREF_CTRL_SHIFT_CLICK)
		if(HardsuitClickOn(A))
			return
	..()

/mob/living/proc/can_use_rig()
	return 0

/mob/living/carbon/human/can_use_rig()
	return 1

/mob/living/carbon/brain/can_use_rig()
	return istype(loc, /obj/item/device/mmi)

/mob/living/silicon/ai/can_use_rig()
	return carded

/mob/living/silicon/pai/can_use_rig()
	return loc == card

/mob/living/proc/HardsuitClickOn(atom/A, alert_ai = 0)
	if(!can_use_rig())// || !can_click())  // This check is already done in mob/proc/ClickOn()
		return 0
	var/obj/item/rig/rig = get_rig()
	if(istype(rig) && !rig.offline && rig.selected_module)
		if(src != rig.wearer)
			if(rig.ai_can_move_suit(src, check_user_module = 1))
				message_admins("[key_name_admin(src, include_name = 1)] is trying to force \the [key_name_admin(rig.wearer, include_name = 1)] to use a hardsuit module.")
			else
				return 0
		rig.selected_module.engage(A, alert_ai)
		if(ismob(A)) // No instant mob attacking - though modules have their own cooldowns
			setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
		return 1
	return 0
