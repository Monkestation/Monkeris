// Checks if all lobby music is included at least once in one of the lobby screens
/datum/unit_test/lobby_music/Run()
	check_all_music_is_used()
	check_all_music_has_valid_properties()
	check_lobbyscreens()

/datum/unit_test/lobby_music/proc/check_all_music_has_valid_properties()
	for(var/datum/lobbyscreen_music/artist as anything in subtypesof(/datum/lobbyscreen_music))
		// example: /datum/lobbyscreen_music/duke_gneiss
		for(var/datum/lobbyscreen_music/track as anything in subtypesof(artist))
			// example: /datum/lobbyscreen_music/duke_gneiss/bluespace
			if(isnull(initial(track.title)))
				TEST_FAIL("Lobby track '[track]' has a bad/null title")
			else if(initial(track.title) == "Unknown Track")
				TEST_FAIL("Lobby track '[track]' has a missing title")
			if(isnull(initial(track.file)))
				TEST_FAIL("Lobby track '[track]' has a bad/null file")
			if(isnull(initial(track.artist)))
				TEST_FAIL("Lobby track '[track]' has a bad/null artist")
			else if(initial(track.artist) == "Unknown Artist")
				TEST_FAIL("Lobby track '[track]' has a missing title")
			if(isnull(initial(track.artist_url)))
				TEST_FAIL("Lobby track '[track]' has a bad/null artist_url")


/datum/unit_test/lobby_music/proc/check_all_music_is_used()
	for(var/datum/lobbyscreen_music/artist as anything in subtypesof(/datum/lobbyscreen_music))
		for(var/datum/lobbyscreen_music/track as anything in subtypesof(artist))
			if (!check_screens_for_track(track))
				TEST_FAIL("Lobby track '[track]' has no lobby screen parents!")

/datum/unit_test/lobby_music/proc/check_screens_for_track(datum/lobbyscreen_music/track)
	for(var/datum/lobbyscreen/artist as anything in subtypesof(/datum/lobbyscreen))
		for(var/datum/lobbyscreen/screen_type as anything in subtypesof(artist))
			var/datum/lobbyscreen/lobby_screen = new screen_type
			if(track in lobby_screen.possible_music)
				return TRUE

/datum/unit_test/lobby_music/proc/check_lobbyscreens()
	var/list/root_artists = list()
	for(var/datum/lobbyscreen/subtype in subtypesof(/datum/lobbyscreen))
		if(subtype::parent_type == /datum/lobbyscreen)
			root_artists += subtype

	for(var/datum/lobbyscreen/artist as anything in root_artists)
		var/datum/lobbyscreen/screen_artist = new artist
		if(!screen_artist.art_artist_name)
			TEST_FAIL("Lobby screen artist [artist] lacks a name!")
		if(!screen_artist.art_artist_link)
			TEST_FAIL("Lobby screen artist [artist] lacks a link!")
		for(var/datum/lobbyscreen/screen_type as anything in subtypesof(artist))
			var/datum/lobbyscreen/lobby_screen = new screen_type
			if(!lobby_screen.image_file)
				TEST_FAIL("Lobby screen [screen_type] lacks an image!")
			if(!length(lobby_screen.possible_music))
				TEST_FAIL("Lobby screen [screen_type] lacks music!")
