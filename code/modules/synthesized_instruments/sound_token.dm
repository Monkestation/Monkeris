//This is similar to normal sound tokens
//Mostly it allows non repeating sounds to keep channel ownership

/datum/sound_token/instrument
	var/use_env = 0
	var/datum/sound_player/player

//Slight duplication, but there's key differences
/datum/sound_token/instrument/New(atom/source, sound_id, sound/sound, range = 4, prefer_mute = FALSE, use_env, datum/sound_player/player)
	if(!istype(source))
		CRASH("Invalid sound source: [log_info_line(source)]")
	if(!istype(sound))
		CRASH("Invalid sound: [log_info_line(sound)]")
	if(sound.repeat && !sound_id)
		CRASH("No sound id given")
	if(!is_environment(sound.environment))
		CRASH("Invalid sound environment: [log_info_line(sound.environment)]")

	src.prefer_mute = prefer_mute
	src.range       = range
	src.source      = source
	src.sound       = sound
	src.sound_id    = sound_id
	src.use_env = use_env
	src.player = player

	var/channel = GLOB.sound_player.get_channel(src) //Attempt to find a channel
	if(!isnum(channel))
		CRASH("All available sound channels are in active use.")
	sound.channel = channel

	listeners = list()
	listener_status = list()

	GLOB.destroyed_event.register(source, src, /datum/proc/qdel_self)

	player.subscribe(src)


/datum/sound_token/instrument/get_environment(listener)
	//Allow override (in case your instrument has to sound funky or muted)
	if(use_env)
		return sound.environment
	else
		var/area/A = get_area(listener)
		return A && is_environment(A.sound_env) ? A.sound_env : sound.environment


/datum/sound_token/instrument/add_listener(atom/listener)
	var/mob/m = listener
	if(istype(m))
		if(m.get_preference_value(/datum/client_preference/play_instruments) != GLOB.PREF_YES)
			return
	return ..()


/datum/sound_token/instrument/update_listener(listener)
	var/mob/m = listener
	if(istype(m))
		if(m.get_preference_value(/datum/client_preference/play_instruments) != GLOB.PREF_YES)
			remove_listener(listener)
			return
	return ..()

/datum/sound_token/instrument/stop()
	player.unsubscribe(src)
	. = ..()

/datum/sound_token/instrument/Destroy()
	. = ..()
	player = null
