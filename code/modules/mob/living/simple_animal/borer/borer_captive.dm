/mob/living/captive_brain
	name = "host brain"
	real_name = "host brain"
	universal_understand = 1
	stat = 0

/mob/living/captive_brain/say(message)
	message = sanitize(message)

	if (src.client)
		if(client.prefs.muted & MUTE_IC)
			to_chat(src, span_red("You cannot speak in IC (muted)."))
			return
		if (src.client.handle_spam_prevention(message,MUTE_IC))
			return

	if(istype(src.loc,/mob/living/simple_animal/borer))
		if (!message)
			return
		log_say("[key_name(src)] : [message]")
		if (stat == 2)
			return say_dead(message)

		var/mob/living/simple_animal/borer/B = src.loc
		to_chat(src, "You whisper silently, \"[message]\"")
		to_chat(B.host, "The captive mind of [src] whispers, \"[message]\"")

		for (var/mob/M in GLOB.player_list)
			if (isnewplayer(M))
				continue
			else if(M.stat == DEAD && M.get_preference_value(/datum/client_preference/ghost_ears) == GLOB.PREF_ALL_SPEECH)
				to_chat(M, "The captive mind of [src] whispers, \"[message]\"")


	var/obj/item/implant/carrion_spider/control/controler = src.loc
	if(istype(controler))
		if (!message)
			return
		log_say("[key_name(src)] : [message]")
		if (stat == 2)
			return say_dead(message)

		to_chat(src, "You whisper silently, \"[message]\"")
		to_chat(controler.wearer, "The captive mind of [src] whispers, \"[message]\"")

		for (var/mob/M in GLOB.player_list)
			if (isnewplayer(M))
				continue
			else if(M.stat == DEAD && M.get_preference_value(/datum/client_preference/ghost_ears) == GLOB.PREF_ALL_SPEECH)
				to_chat(M, "The captive mind of [src] whispers, \"[message]\"")


/mob/living/captive_brain/emote(message)
	return

/mob/living/captive_brain/process_resist()
	//Resisting control by an alien mind.
	if(istype(src.loc,/mob/living/simple_animal/borer))
		var/mob/living/simple_animal/borer/B = src.loc
		var/mob/living/captive_brain/H = src

		to_chat(H, span_danger("You begin doggedly resisting the parasite's control (this will take approximately thirty seconds)."))
		to_chat(B.host, span_danger("You feel the captive mind of [src] begin to resist your control."))

		spawn(rand(25 SECONDS, 30 SECONDS)+B.host.brainloss)
			if(!B || !B.controlling) return

			B.host.adjustBrainLoss(rand(0.1,0.5))
			to_chat(H, span_danger("With an immense exertion of will, you regain control of your body!"))
			to_chat(B.host, span_danger("You feel control of the host brain ripped from your grasp, and retract your probosci before the wild neural impulses can damage you."))
			B.detach()
			add_verb(src, list(
				/mob/living/carbon/human/proc/commune,
				/mob/living/carbon/human/proc/psychic_whisper,
				/mob/living/carbon/proc/spawn_larvae))

		return

	else
		to_chat(src, span_danger("You cannot escape."))

	..()
