/datum/surgery_step/attach_mod
	allowed_tools = list(/obj/item/modification/organ/internal = 100)
	target_organ_type = /obj/item/organ/internal
	duration = 0
	blood_level = 1

/datum/surgery_step/attach_mod/require_tool_message(mob/living/user)
	to_chat(user, span_warning("You need an organ modification or an organoid to complete this step."))

/datum/surgery_step/attach_mod/can_use(mob/living/user, obj/item/organ/internal/organ, obj/item/mod)
	var/datum/component/modification/organ/C
	var/obj/item/organ/external/limb = organ.get_limb()

	if(istype(mod, /obj/item/modification/organ/internal))
		C = mod.GetComponent(/datum/component/modification/organ)
	else
		return FALSE

	if(limb && C)
		var/organ_size_delta = ((organ.specific_organ_size + C.modifications[ORGAN_SPECIFIC_SIZE_BASE]) * (1 + C.modifications[ORGAN_SPECIFIC_SIZE_MULT])\
								+ C.modifications[ORGAN_SPECIFIC_SIZE_MOD]) - organ.specific_organ_size
		if(limb.get_total_occupied_volume() + organ_size_delta > limb.max_volume)
			to_chat(user, span_warning("There isn't enough space in \the [limb] to apply \the [mod]."))
			return FALSE

	return organ.is_open()

/datum/surgery_step/attach_mod/begin_step(mob/living/user, obj/item/organ/internal/organ, obj/item/mod)
	var/obj/item/organ/external/limb = organ.get_limb()
	if(limb)
		organ.owner_custom_pain("Someone is digging into your [limb.name]!", 1)

/datum/surgery_step/attach_mod/end_step(mob/living/user, obj/item/organ/internal/organ, obj/item/mod)
	SEND_SIGNAL_OLD(mod, COMSIG_IATTACK, organ, user)

/datum/surgery_step/attach_mod/fail_step(mob/living/user, obj/item/organ/internal/organ, obj/item/mod)
	user.visible_message(
		span_warning("[user]'s hand slips, damaging [organ.get_surgery_name()] with \the [mod]!"),
		span_warning("Your hand slips, damaging [organ.get_surgery_name()] with \the [mod]!")
	)
	organ.take_damage(rand(24, 32), BRUTE, edge = TRUE)

/datum/surgery_step/remove_mod
	required_tool_quality = QUALITY_LASER_CUTTING
	target_organ_type = /obj/item/organ/internal
	duration = 0
	blood_level = 1

/datum/surgery_step/remove_mod/can_use(mob/living/user, obj/item/organ/internal/organ, obj/item/tool)
	return organ.is_open()

/datum/surgery_step/remove_mod/begin_step(mob/living/user, obj/item/organ/internal/organ, obj/item/tool)
	var/obj/item/organ/external/limb = organ.get_limb()
	if(limb)
		organ.owner_custom_pain("Someone is cutting into your [limb.name]!", 1)

/datum/surgery_step/remove_mod/end_step(mob/living/user, obj/item/organ/internal/organ, obj/item/tool)
	SEND_SIGNAL_OLD(organ, COMSIG_ATTACKBY, tool, user)

/datum/surgery_step/remove_mod/fail_step(mob/living/user, obj/item/organ/internal/organ, obj/item/tool)
	user.visible_message(
		span_warning("[user]'s hand slips, damaging [organ.get_surgery_name()] with \the [tool]!"),
		span_warning("Your hand slips, damaging [organ.get_surgery_name()] with \the [tool]!")
	)
	organ.take_damage(rand(24, 32), BRUTE, sharp = TRUE)

/datum/surgery_step/examine
	required_tool_quality = null
	target_organ_type = /obj/item/organ/internal
	duration = 0
	difficulty = 0

/datum/surgery_step/examine/tool_quality(obj/item/tool)
	return 120		// Don't need no tool

/datum/surgery_step/examine/can_use(mob/living/user, obj/item/organ/organ, obj/item/tool, target)
	return TRUE

/datum/surgery_step/examine/can_use(mob/living/user, obj/item/organ/internal/organ, obj/item/tool)
	return organ.is_open()

/datum/surgery_step/examine/end_step(mob/living/user, obj/item/organ/internal/organ, obj/item/tool)
	organ.examine(user)

/datum/surgery_step/examine/fail_step(mob/living/user, obj/item/organ/internal/organ, obj/item/tool)
	to_chat(user, span_warning("You couldn't get a good look at \the [organ.get_surgery_name()]."))
