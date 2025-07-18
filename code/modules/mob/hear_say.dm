// At minimum every mob has a hear_say proc.

/mob/proc/hear_say(message, verb = src.verb_say, datum/language/language = null, alt_name = "", italics = 0, mob/speaker = null, sound/speech_sound, sound_vol, speech_volume)
	if(!client)
		return


	if(isghost(src) || stats.getPerk(PERK_CODESPEAK_COP))
		message = cop_codes.find_message(message) ? "[message] ([cop_codes.find_message(message)])" : message
	if(isghost(src) || stats.getPerk(PERK_CODESPEAK_SERB))
		message = serb_codes.find_message(message) ? "[message] ([serb_codes.find_message(message)])" : message

	var/speaker_name = speaker.name
	if(ishuman(speaker))
		var/mob/living/carbon/human/H = speaker
		// GetVoice(TRUE) checks if mask hiding the voice
		speaker_name = H.rank_prefix_name(H.GetVoice(TRUE))
		// If we have the right perk or standing close - GetVoice() again, but skip mask check
		if((get_dist(src, H) < 2) || stats?.getPerk(PERK_EAR_OF_QUICKSILVER))
			speaker_name = H.rank_prefix_name(H.GetVoice(FALSE))

	var/original_message = message

	if(speech_volume)
		message = "<FONT size='[speech_volume]'>[message]</FONT>"

	if(italics)
		message = "<i>[message]</i>"

	var/track = null
	if(isghost(src))
		if(italics && get_preference_value(/datum/client_preference/ghost_radio) != GLOB.PREF_ALL_CHATTER)
			return
		if(check_rights(0, 0, src))
			if(speaker_name != speaker.real_name && speaker.real_name)
				speaker_name = "[speaker.real_name] ([speaker_name])"
			else
				speaker_name = "[speaker_name]"
		track = "[ghost_follow_link(speaker, src)] "
		if(get_preference_value(/datum/client_preference/ghost_ears) == GLOB.PREF_ALL_SPEECH && (speaker in view(src)))
			message = "<b>[message]</b>"

	if(language)
		var/nverb = null
		if(!say_understands(speaker,language) || language.name == LANGUAGE_COMMON) //Check to see if we can understand what the speaker is saying. If so, add the name of the language after the verb. Don't do this for Galactic Common.
			on_hear_say("<span class='game say'>[track][span_name("[speaker_name]")][alt_name] [language.format_message(message, verb)]</span>")
		else //Check if the client WANTS to see language names.
			switch(src.get_preference_value(/datum/client_preference/language_display))
				if(GLOB.PREF_FULL) // Full language name
					nverb = "[verb] in [language.name]"
				if(GLOB.PREF_SHORTHAND) //Shorthand codes
					nverb = "[verb] ([language.shorthand])"
				if(GLOB.PREF_OFF)//Regular output
					nverb = verb
			on_hear_say("<span class='game say'>[language.display_icon(src) ? language.get_icon() : ""][span_name("[speaker_name]")][alt_name] [track][language.format_message(message, nverb)]</span>")
	else
		on_hear_say("<span class='game say'>[span_name("[speaker_name]")][alt_name] [track][verb], [span_message("<span class='body'>\"[message]\"")]</span></span>")
	// Create map text prior to modifying message for goonchat
	if (client?.prefs.RC_enabled && !(stat == UNCONSCIOUS || stat == HARDCRIT) && (ismob(speaker) || client.prefs.RC_see_chat_non_mob) && !(disabilities & DEAF || ear_deaf))
		if (italics)
			create_chat_message(speaker, language, original_message, list(SPAN_ITALICS))
		else
			create_chat_message(speaker, language, original_message)
	if(speech_sound && (get_dist(speaker, src) <= world.view && src.z == speaker.z))
		var/turf/source = speaker ? get_turf(speaker) : get_turf(src)
		src.playsound_local(source, speech_sound, sound_vol, 1)

/mob/proc/on_hear_say(message)
	to_chat(src, message)

/mob/living/silicon/on_hear_say(message)
	var/time = say_timestamp()
	to_chat(src,"[time] [message]")

/mob/proc/hear_radio(message, verb = src.verb_say, datum/language/language,\
		var/part_a, var/part_b, var/mob/speaker = null, var/hard_to_hear = 0, var/voice_name ="")

	if(!client)
		return

	if(isghost(src) || stats.getPerk(PERK_CODESPEAK_COP))
		var/found = cop_codes.find_message_radio(message)
		if(found)
			message = "[message] ([found])"
	if(isghost(src) || stats.getPerk(PERK_CODESPEAK_SERB))
		var/found = serb_codes.find_message_radio(message)
		if(found)
			message = "[message] ([found])"

	var/speaker_name = get_hear_name(speaker, hard_to_hear, voice_name)

	if(language)
		if(!say_understands(speaker,language) || language.name == LANGUAGE_COMMON) //Check if we understand the message. If so, add the language name after the verb. Don't do this for Galactic Common.
			message = language.format_message_radio(message, verb)
		else
			var/nverb = null
			switch(src.get_preference_value(/datum/client_preference/language_display))
				if(GLOB.PREF_FULL) // Full language name
					nverb = "[verb] in [language.name]"
				if(GLOB.PREF_SHORTHAND) //Shorthand codes
					nverb = "[verb] ([language.shorthand])"
				if(GLOB.PREF_OFF)//Regular output
					nverb = verb
			message = language.format_message_radio(message, nverb)
	else
		message = "[verb], <span class='body'>\"[message]\"</span>"

	on_hear_radio(part_a, speaker_name, part_b, message)

/mob/proc/get_hear_name(mob/speaker, hard_to_hear, voice_name)
	if(hard_to_hear)
		return "Unknown"
	if(!speaker)
		return voice_name

	var/speaker_name = speaker.name
	if(ishuman(speaker))
		var/mob/living/carbon/human/H = speaker
		if(H.voice)
			speaker_name = H.voice
		for(var/datum/data/record/G in data_core.general)
			if(G.fields["name"] == speaker_name)
				return H.rank_prefix_name(speaker_name)
	return voice_name ? voice_name : speaker_name


/mob/living/silicon/ai/get_hear_name(speaker, hard_to_hear, voice_name)
	var/speaker_name = ..()
	if(hard_to_hear || !speaker)
		return speaker_name

	var/changed_voice
	var/jobname // the mob's "job"
	var/mob/living/carbon/human/impersonating //The crew member being impersonated, if any.

	if(ishuman(speaker))
		var/mob/living/carbon/human/H = speaker

		if(H.wear_mask && istype(H.wear_mask, /obj/item/clothing/mask/chameleon/voice))
			changed_voice = TRUE
			var/mob/living/carbon/human/I

			for(var/mob/living/carbon/human/M in SShumans.mob_list)
				if(M.real_name == speaker_name)
					I = M
					break

			// If I's display name is currently different from the voice name and using an agent ID then don't impersonate
			// as this would allow the AI to track I and realize the mismatch.
			if(I && (I.name == speaker_name || !I.wear_id || !istype(I.wear_id, /obj/item/card/id/syndicate)))
				impersonating = I
				jobname = impersonating.get_assignment()
			else
				jobname = "Unknown"
		else
			jobname = H.get_assignment()

	else if(iscarbon(speaker)) // Nonhuman carbon mob
		jobname = "No id"
	else if(isAI(speaker))
		jobname = "AI"
	else if(isrobot(speaker))
		jobname = "Robot"
	else if(istype(speaker, /mob/living/silicon/pai))
		jobname = "Personal AI"
	else
		jobname = "Unknown"

	if(changed_voice)
		if(impersonating)
			return "<a href=\"byond://?src=\ref[src];trackname=[speaker_name];track=\ref[impersonating]\">[speaker_name] ([jobname])</a>"
		else
			return "[speaker_name] ([jobname])"
	else
		return "<a href=\"byond://?src=\ref[src];trackname=[speaker_name];track=\ref[speaker]\">[speaker_name] ([jobname])</a>"

/mob/observer/ghost/get_hear_name(mob/speaker, hard_to_hear, voice_name)
	. = ..()
	if(!speaker)
		return .

	if(. != speaker.real_name && !isAI(speaker))
	 //Announce computer and various stuff that broadcasts doesn't use it's real name but AI's can't pretend to be other mobs.
		. = "[speaker.real_name] ([.])"
	return "[.] [ghost_follow_link(speaker, src)]"

/proc/say_timestamp()
	return "<span class='say_quote'>\[[stationtime2text()]\]</span>"

/mob/proc/on_hear_radio(part_a, speaker_name, part_b, message)
	to_chat(src,"[part_a][speaker_name][part_b][message]")


/mob/living/silicon/on_hear_radio(part_a, speaker_name, part_b, message)
	var/time = say_timestamp()
	to_chat(src,"[time][part_a][speaker_name][part_b][message]")


/mob/proc/hear_signlang(message, verb = "signs", datum/language/language, mob/speaker = null)
	if(!client)
		return

	if(say_understands(speaker, language))
		message = "<B>[speaker]</B> [language.format_message(message, verb)]"
	else
		message = "<B>[speaker]</B> [verb]."

	if(src.status_flags & PASSEMOTES)
		for(var/obj/item/holder/H in src.contents)
			H.show_message(message)
		for(var/mob/living/M in src.contents)
			M.show_message(message)
	src.show_message(message)

