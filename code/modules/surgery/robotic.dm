/datum/surgery_step/robotic
	difficulty = FAILCHANCE_EASY
	required_stat = STAT_MEC
	inflict_agony = 0 // Robotic organs can't feel pain anyway

/datum/surgery_step/robotic/can_use(mob/living/user, obj/item/organ/external/organ, obj/item/tool)
	return BP_IS_ROBOTIC(organ)

// Robotic organs are intended to be assembled and disassembled, making them far easier to work with.
// This is why the default failure is a harmless message.
/datum/surgery_step/robotic/fail_step(mob/living/user, obj/item/organ/external/organ, obj/item/tool)
	user.visible_message(
		span_warning("[user]'s hand slips, \the [tool] hitting [organ.get_surgery_name()] harmlessly."),
		span_warning("Your hand slips, \the [tool] hitting [organ.get_surgery_name()] harmlessly.")
	)



/datum/surgery_step/robotic/open
	required_tool_quality = QUALITY_SCREW_DRIVING

	duration = 80

/datum/surgery_step/robotic/open/begin_step(mob/living/user, obj/item/organ/external/organ, obj/item/tool)
	var/action = organ.open ? "close" : "open"

	user.visible_message(
		span_notice("[user] begins to [action] the hatches on [organ.get_surgery_name()] with \the [tool]."),
		span_notice("You begin to [action] the hatches on [organ.get_surgery_name()] with \the [tool].")
	)

/datum/surgery_step/robotic/open/end_step(mob/living/user, obj/item/organ/external/organ, obj/item/tool)
	var/action = organ.open ? "close" : "open"

	user.visible_message(
		span_notice("[user] [action]s the hatches on [organ.get_surgery_name()] with \the [tool]."),
		span_notice("You [action] the hatches on [organ.get_surgery_name()] with \the [tool].")
	)
	organ.open = !organ.open
	organ.diagnosed = FALSE
	organ.nano_ui_interact(user)



/datum/surgery_step/robotic/connect_organ
	target_organ_type = /obj/item/organ/internal
	required_tool_quality = QUALITY_SCREW_DRIVING
	duration = 80

/datum/surgery_step/robotic/connect_organ/can_use(mob/living/user, obj/item/organ/internal/organ, obj/item/stack/tool)
	return ..() && organ.is_open()

/datum/surgery_step/robotic/connect_organ/begin_step(mob/living/user, obj/item/organ/internal/organ, obj/item/stack/tool)
	var/action = (organ.status & ORGAN_CUT_AWAY) ? "connect" : "disconnect"

	user.visible_message(
		span_notice("[user] begins to [action] [organ.get_surgery_name()] with \the [tool]."),
		span_notice("You begin to [action] [organ.get_surgery_name()] with \the [tool].")
	)

/datum/surgery_step/robotic/connect_organ/end_step(mob/living/user, obj/item/organ/internal/organ, obj/item/stack/tool)
	var/action = (organ.status & ORGAN_CUT_AWAY) ? "connect" : "disconnect"

	user.visible_message(
		span_notice("[user] [action]s [organ.get_surgery_name()] with \the [tool]."),
		span_notice("You [action] [organ.get_surgery_name()] with \the [tool].")
	)
	if(organ.status & ORGAN_CUT_AWAY)
		organ.status &= ~ORGAN_CUT_AWAY
		organ.handle_organ_eff()
	else
		organ.status |= ORGAN_CUT_AWAY
		organ.handle_organ_eff()

/datum/surgery_step/robotic/connect_organ/fail_step(mob/living/user, obj/item/organ/internal/organ, obj/item/stack/tool)
	user.visible_message(
		span_warning("[user]'s hand slips, damaging [organ.get_surgery_name()] with \the [tool]!"),
		span_warning("Your hand slips, damaging [organ.get_surgery_name()] with \the [tool]!")
	)
	organ.take_damage(5, 0)



/datum/surgery_step/robotic/remove_item
	required_tool_quality = QUALITY_BOLT_TURNING

	duration = 90

/datum/surgery_step/robotic/remove_item/can_use(mob/living/user, obj/item/organ/external/organ, obj/item/tool, atom/movable/target)
	return ..() && organ.is_open() && organ.can_remove_item(target)

/datum/surgery_step/robotic/remove_item/begin_step(mob/living/user, obj/item/organ/external/organ, obj/item/tool, atom/movable/target)
	user.visible_message(
		span_notice("[user] begins to extract something out of [organ.get_surgery_name()] with \the [tool]."),
		span_notice("You begin to extract [target] out of [organ.get_surgery_name()] with \the [tool].")
	)

/datum/surgery_step/robotic/remove_item/end_step(mob/living/user, obj/item/organ/external/organ, obj/item/tool, atom/movable/target)
	if(istype(target, /mob/living/simple_animal/borer)) // the fact that you wrench out a borer like a bolt is fucking stupid and funny
		var/mob/living/simple_animal/borer/B = target
		B.detach()
		B.leave_host()
	user.visible_message(
		span_notice("[user] extracts something out of [organ.get_surgery_name()] with \the [tool]."),
		span_notice("You extract [target] out of [organ.get_surgery_name()] with \the [tool].")
	)
	organ.remove_item(target, user)

/datum/surgery_step/robotic/fail_step(mob/living/user, obj/item/organ/external/organ, obj/item/tool, atom/movable/target)
	user.visible_message(
		span_warning("[user] scrapes something inside [organ.get_surgery_name()] with \the [tool]!"),
		span_warning("You scrape something inside [organ.get_surgery_name()] with \the [tool]!")
	)
	if(istype(target, /obj/item/implant) && prob(25))
		var/obj/item/implant/imp = target
		imp.malfunction(1)



/datum/surgery_step/robotic/amputate
	required_tool_quality = QUALITY_BOLT_TURNING

	duration = 120

/datum/surgery_step/robotic/amputate/can_use(mob/living/user, obj/item/organ/external/organ, obj/item/tool)
	return ..() && organ.owner && !organ.cannot_amputate

/datum/surgery_step/robotic/amputate/begin_step(mob/living/user, obj/item/organ/external/organ, obj/item/tool)
	user.visible_message(
		span_notice("[user] starts to undo the connections in [organ.get_surgery_name()] with \the [tool]."),
		span_notice("You start to undo the connections in [organ.get_surgery_name()] with \the [tool].")
	)

/datum/surgery_step/robotic/amputate/end_step(mob/living/user, obj/item/organ/external/organ, obj/item/tool)
	user.visible_message(
		span_notice("[user] disconnects [organ.get_surgery_name()] with \the [tool]."),
		span_notice("You disconnect [organ.get_surgery_name()] with \the [tool].")
	)
	organ.droplimb(TRUE, DROPLIMB_EDGE)



/datum/surgery_step/robotic/fix_bone
	required_tool_quality = QUALITY_WELDING
	target_organ_type = /obj/item/organ/internal
	allowed_tools = list(/obj/item/stack/nanopaste = 100)

	duration = 6 SECONDS

/datum/surgery_step/robotic/fix_bone/can_use(mob/living/user, obj/item/organ/internal/organ, obj/item/stack/tool)
	. = ..() && organ.is_open() && (organ.parent.status & ORGAN_BROKEN)

	// Otherwise, it will just immediately fracture again
	if(. && organ.parent.should_fracture())
		to_chat(user, span_warning("[organ.parent.get_surgery_name()] is too damaged!"))
		return FALSE

	return .

/datum/surgery_step/robotic/fix_bone/begin_step(mob/living/user, obj/item/organ/internal/bone/organ, obj/item/stack/tool)
	user.visible_message(
		span_notice("[user] starts mending [organ.get_surgery_name()] with \the [tool]."),
		span_notice("You start mending [organ.get_surgery_name()] with \the [tool].")
	)

	organ.owner_custom_pain("The pain in your [organ.name] is living hell!", 1)

/datum/surgery_step/robotic/fix_bone/end_step(mob/living/user, obj/item/organ/internal/bone/organ, obj/item/stack/tool)
	user.visible_message(
		span_notice("[user] mends [organ.get_surgery_name()] with \the [tool]."),
		span_notice("You mend [organ.get_surgery_name()] with \the [tool].")
	)
	organ.mend()

/datum/surgery_step/robotic/fix_bone/fail_step(mob/living/user, obj/item/organ/internal/organ, obj/item/stack/tool)
	user.visible_message(
		span_warning("[user]'s hand slips, scraping [organ.get_surgery_name()] with \the [tool]!"),
		span_warning("Your hand slips, scraping [organ.get_surgery_name()] with \the [tool]!")
	)
	organ.take_damage(5, 0)
