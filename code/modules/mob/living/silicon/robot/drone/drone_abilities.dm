// DRONE ABILITIES
/mob/living/silicon/robot/drone/verb/set_mail_tag()
	set name = "Set Mail Tag"
	set desc = "Tag yourself for delivery through the disposals system. Will automatically mail you when used in disposal chute."
	set category = "Silicon Commands"

	var/new_tag = input("Select the desired destination.", "Set Mail Tag", null) as null|anything in tagger_locations

	if(!new_tag)
		mail_destination = ""
		return

	to_chat(src, span_notice("You configure your internal beacon, tagging yourself for delivery to '[new_tag]'."))
	mail_destination = new_tag

	//Auto flush if we use this verb inside a disposal chute.
	var/obj/machinery/disposal/D = src.loc
	if(istype(D))
		to_chat(src, span_notice("\The [D] acknowledges your signal."))
		D.flush_count = D.flush_every_ticks

	return

/mob/living/silicon/robot/drone/MouseDrop(atom/over_object)
	var/mob/living/carbon/H = over_object
	if(!istype(H) || !Adjacent(H)) return ..()
	if(H.a_intent == I_HELP)
		get_scooped(H)
		return
	else if(H.a_intent == "grab" && hat && !(H.l_hand && H.r_hand))
		hat.loc = get_turf(src)
		H.put_in_hands(hat)
		H.visible_message(span_danger("\The [H] removes \the [src]'s [hat]."))
		hat = null
		updateicon()
	else
		return ..()
