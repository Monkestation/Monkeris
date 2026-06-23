// Hello! Are you looking to add a new lobby screen?
// Refer to screens/_template.dm for a template.


// see /datum/interface/new_player/buildUI()
// NOTES:
// music files should be in ogg extention

/hook/startup/proc/initLobbyScreen()
    var/list/variations = list()
    for (var/datum/lobbyscreen/type as anything in subtypesof(/datum/lobbyscreen))
        if (initial(type.image_file))
            variations += type

    var/datum/lobbyscreen/LS = pick(variations)
    GLOB.lobbyScreen = new LS()
    return 1

/datum/lobbyscreen
	var/image_file
	// Name of the artist who made this lobby screen
	var/art_artist_name
	// A link to the artists social media
	var/art_artist_link
	// insert track datums into this list, not into var/music_track
	var/list/datum/lobbyscreen_music/possible_music = list()
	// this var exist so all players will hear one song
	var/datum/lobbyscreen_music/music_track

/datum/lobbyscreen/New()
	if (!art_artist_name)
		log_runtime("Lobbyscreen [src.type] is missing an art artist name")
	if (!art_artist_link)
		log_runtime("Lobbyscreen [src.type] is missing an art artist link")
	if (!length(possible_music))
		log_runtime("Lobbyscreen [src.type] has no music tracks")
	else
		for(var/datum/lobbyscreen_music/track as anything in possible_music)
			if(!ispath(track, /datum/lobbyscreen_music))
				log_runtime("Lobbyscreen [src.type] contains an invalid lobbyscreen path (got [track])! Please make sure the entry is like so: /datum/lobbyscreen_music/artist/track_name")
				possible_music -= track
			else if(!initial(track.file))
				log_runtime("Lobbyscreen [src.type] lacks a sound file path!")
				possible_music -= track

		var/datum/lobbyscreen_music/track = pick(possible_music)
		if(track)
			music_track = new track()

	return ..()

/datum/lobbyscreen/proc/get_info_list()
	return list(
		art_artist_name,
		art_artist_link,
	)

/datum/lobbyscreen/proc/play_music(client/C)
	if(!music_track)
		return
	if(C.get_preference_value(/datum/client_preference/play_lobby_music) == GLOB.PREF_YES)
		to_chat(C, span_boldnotice("Now playing: [music_track.get_formatted_title(include_href = TRUE)]"))
		sound_to(C, sound(music_track.file, repeat = 0, wait = 0, volume = 65, channel = GLOB.lobby_sound_channel))

/datum/lobbyscreen/proc/stop_music(client/C)
	if(!music_track)
		return
	sound_to(C, sound(null, repeat = 0, wait = 0, volume = 85, channel = GLOB.lobby_sound_channel))


/datum/lobbyscreen/proc/show_titlescreen(client/C)
	if(!C.mob)
		return
	winset(C, "mapwindow.lobbybrowser", "is-disabled=false;is-visible=true")
	C << browse(image_file, "file=titlescreen.png;display=0")
	// var/ourfile = file('html/lobby_titlescreen.html')
	// ourfile = replacetext(ourfile, "REFGOESHERE", "\ref[src]")
	C << browse(file('html/lobby_titlescreen.html'), "window=lobbybrowser")


/datum/lobbyscreen/proc/hide_titlescreen(client/C)
	if(!C.mob) // Check if the client is still connected to something
		return
	// Hide title screen, allowing player to see the map
	winset(C, "mapwindow.lobbybrowser", "is-disabled=true;is-visible=false")

/client/Topic(href, list/href_list)
	. = ..()
	if (.)
		return

	if (href_list["send_info"])
		src << output(list2params(GLOB.lobbyScreen.get_info_list()), "lobbybrowser:set_info")
