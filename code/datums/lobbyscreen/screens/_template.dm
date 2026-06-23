// DO NOT TICK THIS FILE
// This file is a template for creating lobby screens.
// Remove all the comments when you create a new.


/**
 * -- Welcome to the template for lobby screens --
 *
 * To start, copy this file and rename it to your username, or author name.
 *
 * All lobby screen image files are located in the /icons/title_screens/ directory.
 * Within that directory, they should follow a path based on your username, then work name, like this:
 * /icons/title_screens/YourArtistName/YourLobbyScreen.png
 *
 * Music is similar, but it should be in the /sound/music/lobby/ directory.
 * The format should be sound/music/lobby/artist_name/song_name.ogg and the
 * file type should be ogg.
 *
 * For music, you will either add a new file to code/datums/lobbyscreen/music named the music artist name,
 * and all songs for that artist will be added there. You will then place the typepath of the tracks you want
 * to show up on your lobby screen, in the `possible_music` list.
**/


// This is the base path for your lobby screens. If you have multiple lobby screens,
// you will create a new datum for each one using your base path below.

/datum/lobbyscreen/my_artist_name
	// Name of the artist who made this lobby screen
	art_artist_name = "myArtistName"
	// A link to the artists social media or website
	art_artist_link = "https://www.instagram.com/myArtistName"

// For each lobby screen, you will create a new datum with the path below, changing the last part
// to the specific name of your lobby screen. For example, if your lobby screen image is named
// "MyCoolLobby.png", you would use the path `/datum/lobbyscreen/YourArtistName/MyCoolLobby`.
/datum/lobbyscreen/my_artist_name/my_lobbyscreen_name
	image_file = 'icons/title_screens/my_artist_name/mylobbyscreen.png'
	// The artist file you created in lobbyscreen/music, add the typepath of the track you want for this screen
	possible_music = list(
		/datum/lobbyscreen_music/artistname/track1,
		/datum/lobbyscreen_music/artistname/track2,
	)

/datum/lobbyscreen/my_artist_name/my_other_lobbyscreen_name
	image_file = 'icons/title_screens/my_artist_name/myotherlobbyscreen.png'
	possible_music = list(
		/datum/lobbyscreen_music/artistname/track3,
		/datum/lobbyscreen_music/artistname/track4,
	)
