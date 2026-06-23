// This system will be temporary until we port new jukeboxes, aka /datum/media_track and its related stuff
/datum/lobbyscreen_music
	/// Sound file of the track
	var/file
	/// Title of the track
	var/title = "Unknown Track"
	/// Web url to the track directly
	var/track_url

	/// Artist of the track
	var/artist = "Unknown Artist"
	/// Web url to the artists page"
	var/artist_url

/datum/lobbyscreen_music/proc/get_formatted_title(include_href)
	var/formatted_title = title

	if(include_href && track_url)
		formatted_title = "<a href='[track_url]'>[formatted_title]</a>"

	if(include_href && artist_url)
		formatted_title += " by <a href='[artist_url]'>[artist]</a>"
	else
		formatted_title += " by [artist]"

	return formatted_title

/datum/lobbyscreen_music/proc/get_track_url()
	if(track_url)
		return track_url
	if(artist_url)
		return artist_url
