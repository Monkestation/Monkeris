var/list/sounds_cache = list()

#warn test Play Sound
/client/proc/play_sound(S as sound)
	set category = "Fun"
	set name = "Play Global Sound"
	if(!check_rights(R_SOUND))
		return

	var/freq = 1
	var/vol = input(usr, "What volume would you like the sound to play at?",, 100) as null|num
	if(!vol)
		return
	vol = clamp(vol, 1, 100)

	var/sound/admin_sound = new()
	admin_sound.file = S
	admin_sound.priority = 250
	admin_sound.wait = TRUE
	admin_sound.frequency = freq
	admin_sound.repeat = FALSE
	admin_sound.status = SOUND_STREAM
	admin_sound.volume = vol

	var/res = tgui_alert(usr, "Show the title of this song to the players?",, list("Yes","No", "Cancel"))
	switch(res)
		if("Yes")
			to_chat(world, span_boldannounce("An admin played: [S]"), confidential = TRUE)
		if("Cancel")
			return

	log_admin("[key_name(src)] played sound [S]")
	message_admins("[key_name_admin(src)] played sound [S]", 1)
	for(var/mob/M in GLOB.player_list)
		if(M.get_preference_value(/datum/client_preference/play_admin_midis) == GLOB.PREF_YES)
			sound_to(M, sound(admin_sound, repeat = 0, wait = 0, volume = 100, channel = GLOB.admin_sound_channel))

	SSblackbox.record_feedback("tally", "admin_verb", 1, "Play Global Sound") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

#warn test Play Local Sound
/client/proc/play_local_sound(S as sound)
	set category = "Admin.Fun"
	set name = "Play Local Sound"
	if(!check_rights(R_SOUND))
		return

	log_admin("[key_name(src)] played a local sound [S]")
	message_admins("[key_name_admin(src)] played a local sound [S]")
	playsound(get_turf(src.mob), S, 50, FALSE, FALSE)
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Play Local Sound") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

#warn test Play Direct Mob Sound
/client/proc/play_direct_mob_sound(S as sound, mob/M)
	set category = "Admin.Fun"
	set name = "Play Direct Mob Sound"
	if(!check_rights(R_SOUND))
		return

	if(!M)
		M = input(usr, "Choose a mob to play the sound to. Only they will hear it.", "Play Mob Sound") as null|anything in sortNames(GLOB.player_list)
	if(!M || QDELETED(M))
		return
	log_admin("[key_name(src)] played a direct mob sound [S] to [M].")
	message_admins("[key_name_admin(src)] played a direct mob sound [S] to [ADMIN_LOOKUPFLW(M)].")
	SEND_SOUND(M, S)
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Play Direct Mob Sound") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

///Takes an input from either proc/play_web_sound or the request manager and runs it through youtube-dl and prompts the user before playing it to the server.
/proc/web_sound(mob/user, input)
	if(!check_rights(R_SOUND))
		return
	var/ytdl = CONFIG_GET(string/invoke_youtubedl)
	if(!ytdl)
		to_chat(user, span_boldwarning("Youtube-dl was not configured, action unavailable"), confidential = TRUE) //Check config.txt for the INVOKE_YOUTUBEDL value
		return
	var/web_sound_url = ""
	var/stop_web_sounds = FALSE
	var/list/music_extra_data = list()
	if(istext(input))
		to_chat(usr, span_warning("Loading URL info, please hold..."))
		var/list/output = world.shelleo("[ytdl] --geo-bypass --format \"bestaudio\[ext=mp3]/best\[ext=mp4]\[height <= 360]/bestaudio\[ext=m4a]/bestaudio\[ext=aac]\" --dump-single-json --no-playlist --extractor-args \"youtube:lang=en\" -- \"[input]\"")
		var/errorlevel = output[SHELLEO_ERRORLEVEL]
		var/stdout = output[SHELLEO_STDOUT]
		var/stderr = output[SHELLEO_STDERR]
		if(errorlevel)
			to_chat(user, span_boldwarning("Youtube-dl URL retrieval FAILED:"), confidential = TRUE)
			to_chat(user, span_warning("[stderr]"), confidential = TRUE)
			return
		var/list/data
		try
			data = json_decode(stdout)
		catch(var/exception/e)
			to_chat(user, span_boldwarning("Youtube-dl JSON parsing FAILED:"), confidential = TRUE)
			to_chat(user, span_warning("[e]: [stdout]"), confidential = TRUE)
			return
		if (data["url"])
			web_sound_url = data["url"]
		var/title = "[data["title"]]"
		var/webpage_url = title
		if (data["webpage_url"])
			webpage_url = "<a href=\"[data["webpage_url"]]\">[title]</a>"
		music_extra_data["duration"] = DisplayTimeText(data["duration"] * 1 SECONDS)
		music_extra_data["link"] = data["webpage_url"]
		music_extra_data["artist"] = data["artist"]
		music_extra_data["upload_date"] = data["upload_date"]
		music_extra_data["album"] = data["album"]
		var/duration = data["duration"] * 1 SECONDS
		if (duration > 10 MINUTES)
			if((tgui_alert(user, "This song is over 10 minutes long. Are you sure you want to play it?", "Length Warning!", list("No", "Yes", "Cancel")) != "Yes"))
				return
		var/res = tgui_input_list(user, "Show the title of and link to this song to the players?\n[title]", "Show Info?", list("Yes", "No", "Custom Title", "Cancel"))
		switch(res)
			if("Yes")
				music_extra_data["title"] = data["title"]
			if("No")
				music_extra_data["link"] = "Song Link Hidden"
				music_extra_data["title"] = "Song Title Hidden"
				music_extra_data["artist"] = "Song Artist Hidden"
				music_extra_data["upload_date"] = "Song Upload Date Hidden"
				music_extra_data["album"] = "Song Album Hidden"
			if("Custom Title")
				var/custom_title = tgui_input_text(user, "Enter the title to show to players", "Custom sound info", null)
				if (!length(custom_title))
					tgui_alert(user, "No title specified, using default.", "Custom sound info", list("Okay"))
				else
					music_extra_data["title"] = custom_title
			if("Cancel", null)
				return
		var/anon = tgui_alert(user, "Display who played the song?", "Credit Yourself?", list("Yes", "No", "Cancel"))
		switch(anon)
			if("Yes")
				if(res == "Yes")
					to_chat(world, span_boldannounce("[user.key] played: [webpage_url]"), confidential = TRUE)
				else
					to_chat(world, span_boldannounce("[user.key] played a sound"), confidential = TRUE)
			if("No")
				if(res == "Yes")
					to_chat(world, span_boldannounce("An admin played: [webpage_url]"), confidential = TRUE)
			if("Cancel", null)
				return
		SSblackbox.record_feedback("nested tally", "played_url", 1, list("[user.ckey]", "[input]"))
		log_admin("[key_name(user)] played web sound: [input]")
		message_admins("[key_name(user)] played web sound: [input]")
	else
		//pressed ok with blank
		log_admin("[key_name(user)] stopped web sounds.")

		message_admins("[key_name(user)] stopped web sounds.")
		web_sound_url = null
		stop_web_sounds = TRUE
	if(web_sound_url && !findtext(web_sound_url, GLOB.is_http_protocol))
		tgui_alert(user, "The media provider returned a content URL that isn't using the HTTP or HTTPS protocol. This is a security risk and the sound will not be played.", "Security Risk", list("OK"))
		to_chat(user, span_boldwarning("BLOCKED: Content URL not using HTTP(S) Protocol!"), confidential = TRUE)

		return
	if(web_sound_url || stop_web_sounds)
		for(var/mob/m as anything in GLOB.player_list)
			var/client/C = m.client
			if(C.get_preference_value(/datum/client_preference/play_admin_midis) == GLOB.PREF_YES)
				if(!stop_web_sounds)
					C.tgui_panel?.play_music(web_sound_url, music_extra_data)
					// C.media_player?.stop()
				else
					C.tgui_panel?.stop_music()

	SSblackbox.record_feedback("tally", "admin_verb", 1, "Play Internet Sound")

#warn test Play Internet Sound
/client/proc/play_web_sound()
	set category = "Admin.Fun"
	set name = "Play Internet Sound"
	if(!check_rights(R_SOUND))
		return

	var/ytdl = CONFIG_GET(string/invoke_youtubedl)
	if(!ytdl)
		to_chat(src, span_boldwarning("Youtube-dl was not configured, action unavailable"), confidential = TRUE) //Check config.txt for the INVOKE_YOUTUBEDL value
		return

	var/web_sound_input = tgui_input_text(usr, "Enter content URL (supported sites only, leave blank to stop playing)", "Play Internet Sound", null)

	if(length(web_sound_input))
		web_sound_input = trim(web_sound_input)
		if(findtext(web_sound_input, ":") && !findtext(web_sound_input, GLOB.is_http_protocol))
			to_chat(src, span_boldwarning("Non-http(s) URIs are not allowed."), confidential = TRUE)
			to_chat(src, span_warning("For youtube-dl shortcuts like ytsearch: please use the appropriate full URL from the website."), confidential = TRUE)
			return
		var/shell_scrubbed_input = shell_url_scrub(web_sound_input)
		web_sound(usr, shell_scrubbed_input)
	else
		web_sound(usr, null)


/client/proc/play_server_sound()
	set category = "Fun"
	set name = "Play Server Sound"
	if(!check_rights(R_FUN))
		return

	var/list/sounds = file2list("sound/serversound_list.txt");
	sounds += "--CANCEL--"
	sounds += sounds_cache

	var/melody = input("Select a sound from the server to play", "Server sound list", "--CANCEL--") in sounds

	if(melody == "--CANCEL--")
		return

	play_sound(melody)

/client/proc/stop_sounds()
	set category = "Debug"
	set name = "Stop All Playing Sounds"
	if(!src.holder)
		return
	log_admin("[key_name(src)] stopped all currently playing sounds.")
	message_admins("[key_name_admin(src)] stopped all currently playing sounds.")
	for(var/mob/M in GLOB.player_list)
		if(M.client)
			sound_to(M, sound(null, repeat = 0, wait = 0, volume = 100))

/client/proc/stop_sounds_admin() //Selectively shuts up bad admin played songs only without destroying every sound in the game.
	set category = "Debug"
	set name = "Stop Admin Sounds"
	if(!src.holder)
		return
	log_admin("[key_name(src)] stopped all currently playing sounds.")
	message_admins("[key_name_admin(src)] stopped all currently playing sounds.")
	for(var/mob/M in GLOB.player_list)
		if(M.client)
			sound_to(M, sound(null, repeat = 0, wait = 0, volume = 100, channel = GLOB.admin_sound_channel))
