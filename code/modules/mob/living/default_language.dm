/atom/movable

	var/list/languages = list()         // For speaking/listening.
	var/datum/language/default_language // The default language for this atom, if any.

/atom/movable/verb/set_default_lang_verb(language as null|anything in languages)
	set name = "Set Default Language"
	set category = "IC"

	if(language)
		to_chat(src, span_notice("You will now speak [language] if you do not specify a language when speaking."))
	else
		to_chat(src, span_notice("You will now speak whatever your standard default language is if you do not specify one when speaking."))
	set_default_language(language)

// Silicons can't neccessarily speak everything in their languages list
/mob/living/silicon/set_default_language(language as null|anything in speech_synthesizer_langs)
	..()


/atom/movable/verb/check_default_language()
	set name = "Check Default Language"
	set category = "IC"

	if(default_language)
		to_chat(src, span_notice("You are currently speaking [default_language] by default."))
	else
		to_chat(src, span_notice("Your current default language is your species or mob type default."))


/atom/movable/proc/get_default_language()
	return default_language

/atom/movable/proc/set_default_language(langname)
	var/datum/language/L
	//Support for passing a datum directly, or the name of a language to go fetch. Very flexible proc
	if (istype(langname, /datum/language))
		L = langname
	else
		L = GLOB.all_languages[langname]
	languages |= L
	default_language = L
