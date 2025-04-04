//Procedures in this file: hardsuit removal

/datum/old_surgery_step/hardsuit
	required_tool_quality = QUALITY_DRILLING //Prevent conflict with healing, ported from ThePainkiller PR on Sojourn
	required_stat = STAT_MEC

	can_infect = 0
	blood_level = 0

	duration = 160

/datum/old_surgery_step/hardsuit/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if(!istype(target))
		return 0
	return (target_zone == BP_CHEST) && istype(target.back, /obj/item/rig) && !(target.back.canremove)

/datum/old_surgery_step/hardsuit/begin_step(mob/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	user.visible_message(
		span_notice("[user] starts drilling through the support systems of [target]'s [target.back] with \the [tool]."),
		span_notice("You start drilling through the support systems of [target]'s [target.back] with \the [tool].")
	)
	..()

/datum/old_surgery_step/hardsuit/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/rig/rig = target.back
	if(!istype(rig))
		return
	rig.reset()
	user.visible_message(
		span_notice("[user] has drilled through the support systems of [target]'s [rig] with \the [tool]."),
		span_notice("You have drilled through the support systems of [target]'s [rig] with \the [tool].")
	)

/datum/old_surgery_step/hardsuit/fail_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	user.visible_message(
		span_warning("[user]'s [tool] can't quite seem to get through the metal..."),
		span_warning("Your [tool] can't quite seem to get through the metal. It's weakening, though - try again.")
	)
