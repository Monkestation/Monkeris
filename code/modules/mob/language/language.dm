#define SCRAMBLE_CACHE_LEN 20

/*
	Datum based languages. Easily editable and modular.
*/

/datum/language
	var/name = "an unknown language"  			// Fluff name of language if any.
	var/desc = "A language."          			// Short description for 'Check Languages'.
	// var/list/speech_verb = list("says")	   		// 'says', 'hisses', 'farts'.
	// var/list/ask_verb = list("asks")       		// Used when sentence ends in a ?
	// var/list/exclaim_verb = list("exclaims")	// Used when sentence ends in a !
	// var/list/whisper_verb = list("whispers")	// Optional. When not specified speech_verb + quietly/softly is used instead.
	// var/list/signlang_verb = list("signs") 		// list of emotes that might be displayed if this language has NONVERBAL or SIGNLANG flags
	var/colour = "body"               			// CSS style to use for strings in this language.
	var/key = "x"                     			// Character used to speak in language eg. :o for Unathi.
	var/flags = 0                     			// Various language flags.
	var/native                        			// If set, non-native speakers will have trouble speaking.
	var/list/syllables                			// Used when scrambling text for a non-speaker.
	var/list/space_chance = 55        			// Likelihood of getting a space in the random scramble string
	var/machine_understands = 1 		  		// Whether machines can parse and understand this language
	var/shorthand = "CO"						// Shorthand that shows up in chat for this language.

	var/icon = 'icons/misc/language.dmi'
	var/icon_state = "popcorn"

	//Random name lists
	var/name_lists = FALSE
	var/first_names_male = list()
	var/first_names_female = list()
	var/last_names = list()

/datum/language/proc/display_icon(atom/movable/hearer)
	var/understands = (src in hearer.languages)
	if(flags & LANGUAGE_HIDE_ICON_IF_UNDERSTOOD && understands)
		return FALSE
	if(flags & LANGUAGE_HIDE_ICON_IF_NOT_UNDERSTOOD && !understands)
		return FALSE
	return TRUE

/datum/language/proc/get_icon()
	var/datum/asset/spritesheet/sheet = get_asset_datum(/datum/asset/spritesheet_batched/chat)
	return sheet.icon_tag("language-[icon_state]")

/datum/language/proc/get_random_name(gender, name_count=2, syllable_count=4, syllable_divisor=2)
	//This language has its own name lists
	if (name_lists)
		if(gender==FEMALE)
			return capitalize(pick(first_names_female)) + " " + capitalize(pick(last_names))
		else
			return capitalize(pick(first_names_male)) + " " + capitalize(pick(last_names))

	if(!syllables || !syllables.len)
		if(gender==FEMALE)
			return capitalize(pick(GLOB.first_names_female)) + " " + capitalize(pick(GLOB.last_names))
		else
			return capitalize(pick(GLOB.first_names_male)) + " " + capitalize(pick(GLOB.last_names))

	var/full_name = ""
	var/new_name = ""

	for(var/i = 0;i<name_count;i++)
		new_name = ""
		for(var/x = rand(FLOOR(syllable_count/syllable_divisor, 1),syllable_count);x>0;x--)
			new_name += pick(syllables)
		full_name += " [capitalize(lowertext(new_name))]"

	return "[trim(full_name)]"

/datum/language/proc/get_random_first_name(gender, name_count=1, syllable_count=4, syllable_divisor=2)
	//This language has its own name lists
	if (name_lists)
		if(gender==FEMALE)
			return capitalize(pick(first_names_female))
		else
			return capitalize(pick(first_names_male))

	if(!syllables || !syllables.len)
		if(gender==FEMALE)
			return capitalize(pick(GLOB.first_names_female))
		else
			return capitalize(pick(GLOB.first_names_male))

	var/full_name = ""
	var/new_name = ""

	for(var/i = 0;i<name_count;i++)
		new_name = ""
		for(var/x = rand(FLOOR(syllable_count/syllable_divisor, 1),syllable_count);x>0;x--)
			new_name += pick(syllables)
		full_name += " [capitalize(lowertext(new_name))]"

	return "[trim(full_name)]"

/datum/language/proc/get_random_last_name(name_count=1, syllable_count=4, syllable_divisor=2)
	//This language has its own name lists
	if (name_lists)
		return capitalize(pick(last_names))

	if(!syllables || !syllables.len)
		return capitalize(pick(GLOB.last_names))

	var/full_name = ""
	var/new_name = ""

	for(var/i = 0;i<name_count;i++)
		new_name = ""
		for(var/x = rand(FLOOR(syllable_count/syllable_divisor, 1),syllable_count);x>0;x--)
			new_name += pick(syllables)
		full_name += "[capitalize(lowertext(new_name))]"

	return "[trim(full_name)]"

//A wrapper for the above that gets a random name and sets it onto the mob
/datum/language/proc/set_random_name(mob/M, name_count=2, syllable_count=4, syllable_divisor=2)
	var/mob/living/carbon/human/H = null
	if (ishuman(M))
		H = M

	var/oldname = M.name
	if (H)
		oldname = H.real_name
	M.fully_replace_character_name(oldname, get_random_name(M.get_gender(), name_count, syllable_count, syllable_divisor))


/datum/language
	var/list/scramble_cache = list()

/datum/language/proc/scramble(input)

	if(!syllables || !syllables.len)
		return stars(input)

	// If the input is cached already, move it to the end of the cache and return it
	if(input in scramble_cache)
		var/n = scramble_cache[input]
		scramble_cache -= input
		scramble_cache[input] = n
		return n

	var/input_size = length_char(input)
	var/scrambled_text = ""
	var/capitalize = 1

	while(length_char(scrambled_text) < input_size)
		var/next = pick(syllables)
		if(capitalize)
			next = capitalize(next)
			capitalize = 0
		scrambled_text += next
		var/chance = rand(100)
		if(chance <= 5)
			scrambled_text += ". "
			capitalize = 1
		else if(chance > 5 && chance <= space_chance)
			scrambled_text += " "

	scrambled_text = trim(scrambled_text)
	var/ending = copytext_char(scrambled_text, length(scrambled_text))
	if(ending == ".")
		scrambled_text = copytext_char(scrambled_text, 1, -2)
	var/input_ending = copytext_char(input, -1)
	if(input_ending in list("!","?","."))
		scrambled_text += input_ending

	// Add it to cache, cutting old entries if the list is too long
	scramble_cache[input] = scrambled_text
	if(scramble_cache.len > SCRAMBLE_CACHE_LEN)
		scramble_cache.Cut(1, scramble_cache.len-SCRAMBLE_CACHE_LEN-1)

	return scrambled_text

/datum/language/proc/format_message(message, verb)
	return "[verb], [span_message("<span class='[colour]'>\"[capitalize(message)]\"")]</span>"

/datum/language/proc/format_message_plain(message, verb)
	return "[verb], \"[capitalize(message)]\""

/datum/language/proc/format_message_radio(message, verb)
	return "[verb], <span class='[colour]'>\"[capitalize(message)]\"</span>"

/datum/language/proc/get_talkinto_msg_range(message)
	// if you yell, you'll be heard from two tiles over instead of one
	return (copytext(message, length(message)) == "!") ? 2 : 1

/datum/language/proc/broadcast(mob/living/speaker,message,speaker_mask)
	log_say("[key_name(speaker)] : ([name]) [message]")

	if(!speaker_mask) speaker_mask = speaker.name
	message = format_message(message, speaker.get_spoken_verb(message))

	for(var/mob/player in GLOB.player_list)
		player.hear_broadcast(src, speaker, speaker_mask, message)

/mob/proc/hear_broadcast(datum/language/language, mob/speaker, speaker_name, message)
	if((language in languages) && language.check_special_condition(src))
		var/msg = "<i><span class='game say'>[language.name], [span_name("[speaker_name]")] [message]</span></i>"
		to_chat(src, msg)

/mob/new_player/hear_broadcast(datum/language/language, mob/speaker, speaker_name, message)
	return

/mob/observer/ghost/hear_broadcast(datum/language/language, mob/speaker, speaker_name, message)
	if(speaker.name == speaker_name || antagHUD)
		to_chat(src, "<i><span class='game say'>[language.name], [span_name("[speaker_name]")] [ghost_follow_link(speaker, src)] [message]</span></i>")
	else
		to_chat(src, "<i><span class='game say'>[language.name], [span_name("[speaker_name]")] [message]</span></i>")

/datum/language/proc/check_special_condition(mob/other)
	return 1

/atom/movable/proc/get_spoken_verb(msg_end)
	switch(msg_end)
		if("!")
			return pick(verb_exclaim, verb_yell)
		if("?")
			return pick(verb_ask)

	return verb_say

// Language handling.
/atom/movable/proc/add_language(language)

	var/datum/language/new_language = GLOB.all_languages[language]

	if(!istype(new_language) || (new_language in languages))
		return 0

	languages.Add(new_language)
	return 1

/atom/movable/proc/remove_language(rem_language)
	var/datum/language/L = GLOB.all_languages[rem_language]
	. = (L in languages)
	if(default_language == L)
		default_language = null
	languages.Remove(L)

// Can we speak this language, as opposed to just understanding it?
/mob/proc/can_speak(datum/language/speaking)
	return (universal_speak || (speaking && speaking.flags & INNATE) || (speaking in src.languages))

/mob/proc/get_language_prefix()
	return get_prefix_key(/decl/prefix/language)

/mob/proc/is_language_prefix(prefix)
	return prefix == get_prefix_key(/decl/prefix/language)

//TBD
/mob/verb/check_languages()
	set name = "Check Known Languages"
	set category = "IC"
	set src = usr


	var/dat = "<b><font size = 5>Known Languages</font></b><br/><br/>"

	if(issilicon(src))
		var/mob/living/silicon/silicon = src

		if(silicon.default_language)
			dat += "Current default language: [silicon.default_language] - <a href='byond://?src=\ref[src];default_lang=reset'>reset</a><br/><br/>"

		for(var/datum/language/L in languages)
			if(!(L.flags & NONGLOBAL))
				var/default_str
				if(L == silicon.default_language)
					default_str = " - default - <a href='byond://?src=\ref[src];default_lang=reset'>reset</a>"
				else
					default_str = " - <a href='byond://?src=\ref[src];default_lang=\ref[L]'>set default</a>"

				var/synth = (L in silicon.speech_synthesizer_langs)
				dat += "<b>[L.name] ([get_language_prefix()][L.key])</b>[synth ? default_str : null]<br/>Speech Synthesizer: <i>[synth ? "YES" : "NOT SUPPORTED"]</i><br/>[L.desc]<br/><br/>"
	else
		for(var/datum/language/L in languages)
			if(!(L.flags & NONGLOBAL))
				dat += "<b>[L.name] ([get_language_prefix()][L.key])</b><br/>[L.desc]<br/><br/>"

	src << browse(HTML_SKELETON_TITLE("Known Languages", dat), "window=checklanguage")


/mob/living/check_languages()
	var/dat = "<b><font size = 5>Known Languages</font></b><br/><br/>"

	if(default_language)
		dat += "Current default language: [default_language] - <a href='byond://?src=\ref[src];default_lang=reset'>reset</a><br/><br/>"

	for(var/datum/language/L in languages)
		if(!(L.flags & NONGLOBAL))
			if(L == default_language)
				dat += "<b>[L.name] ([get_language_prefix()][L.key])</b> - default - <a href='byond://?src=\ref[src];default_lang=reset'>reset</a><br/>[L.desc]<br/><br/>"
			else
				dat += "<b>[L.name] ([get_language_prefix()][L.key])</b> - <a href='byond://?src=\ref[src];default_lang=\ref[L]'>set default</a><br/>[L.desc]<br/><br/>"

	src << browse(HTML_SKELETON_TITLE("Known Languages", dat), "window=checklanguage")

/mob/living/Topic(href, href_list)
	if(href_list["default_lang"])
		if(href_list["default_lang"] == "reset")
			set_default_language(null)
		else
			var/datum/language/L = locate(href_list["default_lang"])
			if(L && (L in languages))
				set_default_language(L)
		check_languages()
		return 1
	else
		return ..()

/proc/transfer_languages(mob/source, mob/target, except_flags)
	for(var/datum/language/L in source.languages)
		if(L.flags & except_flags)
			continue
		target.add_language(L.name)

#undef SCRAMBLE_CACHE_LEN
