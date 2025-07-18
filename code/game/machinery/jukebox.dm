//
// Media Player Jukebox
// Rewritten by Leshana from existing Polaris code, merging in D2K5 and N3X15 work
//

#define JUKEMODE_NEXT        1 // Advance to next song in the track list
#define JUKEMODE_RANDOM      2 // Not shuffle, randomly picks next each time.
#define JUKEMODE_REPEAT_SONG 3 // Play the same song over and over
#define JUKEMODE_PLAY_ONCE   4 // Play, then stop.

/obj/machinery/media/jukebox
	name = "space jukebox"
	icon = 'icons/obj/jukebox.dmi'
	icon_state = "jukebox2-nopower"
	var/state_base = "jukebox2"
	anchored = TRUE
	density = TRUE
	power_channel = STATIC_EQUIP
	use_power = IDLE_POWER_USE
	idle_power_usage = 10
	active_power_usage = 100
	circuit = /obj/item/electronics/circuitboard/jukebox

	// Vars for hacking
	var/datum/wires/jukebox/wires
	var/freq = 0 // Currently no effect, will return in phase II of mediamanager.

	var/loop_mode = JUKEMODE_PLAY_ONCE			// Behavior when finished playing a song
	var/max_queue_len = 3						// How many songs are we allowed to queue up?
	var/datum/track/current_track				// Currently playing song
	var/list/datum/track/queue = list()			// Queued songs
	var/list/datum/track/tracks = list()		// Available tracks
	var/list/datum/track/secret_tracks = list() // Only visible if hacked

	var/obj/item/music_tape/my_tape //Jukebox tape

	var/sanity_value = 2

/obj/machinery/media/jukebox/New()
	. = ..()
	AddComponent(/datum/component/atom_sanity, 0, "")
	wires = new/datum/wires/jukebox(src)
	update_icon()

/obj/machinery/media/jukebox/Destroy()
	QDEL_NULL(wires)
	. = ..()

// On initialization, copy our tracks from the global list
/obj/machinery/media/jukebox/Initialize()
	. = ..()
	if(GLOB.all_jukebox_tracks.len < 1)
		stat |= BROKEN // No tracks configured this round!
	else
		// Ootherwise load from the global list!
		for(var/datum/track/T in GLOB.all_jukebox_tracks)
			if(T.secret)
				secret_tracks |= T
			else if(!T.playlist)
				tracks |= T


/obj/machinery/media/jukebox/Process()
	if(!playing)
		return
	if(inoperable())
		disconnect_media_source()
		playing = 0
		return
	// If the current track isn't finished playing, let it keep going
	if(current_track && world.time < media_start_time + current_track.duration)
		return
	// Otherwise time to pick a new one!
	if(queue.len > 0)
		current_track = queue[1]
		queue.Cut(1, 2)  // Remove the item we just took off the list
	else
		// Oh... nothing in queue? Well then pick next according to our rules
		switch(loop_mode)
			if(JUKEMODE_NEXT)
				var/curTrackIndex = max(1, tracks.Find(current_track))
				var/newTrackIndex = (curTrackIndex % tracks.len) + 1  // Loop back around if past end
				current_track = tracks[newTrackIndex]
			if(JUKEMODE_RANDOM)
				var/previous_track = current_track
				do
					current_track = pick(tracks)
				while(current_track == previous_track && tracks.len > 1)
			if(JUKEMODE_REPEAT_SONG)
				current_track = current_track
			if(JUKEMODE_PLAY_ONCE)
				current_track = null
				playing = 0
				update_icon()
	updateDialog()
	start_stop_song()

// Tells the media manager to start or stop playing based on current settings.
/obj/machinery/media/jukebox/proc/start_stop_song()
	if(current_track && playing)
		media_url = current_track.url
		media_start_time = world.time
		visible_message(span_notice("\The [src] begins to play [current_track.display()]."))
	else
		media_url = ""
		media_start_time = 0
	update_music()

/obj/machinery/media/jukebox/proc/set_hacked(newhacked)
	if (hacked == newhacked) return
	hacked = newhacked
	if (hacked)
		tracks.Add(secret_tracks)
	else
		tracks.Remove(secret_tracks)
	updateDialog()

/obj/machinery/media/jukebox/attackby(obj/item/W as obj, mob/user as mob)
	src.add_fingerprint(user)

	var/tool_type = W.get_tool_type(user, list(QUALITY_WIRE_CUTTING, QUALITY_PULSING, QUALITY_BOLT_TURNING, QUALITY_SCREW_DRIVING), src)

	switch(tool_type)
		if(QUALITY_SCREW_DRIVING)
			user.visible_message(span_warning("[user] has [panel_open ? "" : "un"]screwed [src]'s maintenance pannel[panel_open ? " back" : ""]."), span_notice("You [panel_open ? "" : "un"]screw [src]'s maintenance panel[panel_open ? " back" : ""]."))
			panel_open = !panel_open
			update_icon()
		if(QUALITY_WIRE_CUTTING)
			return wires.Interact(user)
		if(QUALITY_PULSING)
			return wires.Interact(user)
		if(QUALITY_BOLT_TURNING)
			user.visible_message(span_warning("[user] has [anchored ? "un" : ""]secured \the [src]."), span_notice("You [anchored ? "un" : ""]secure \the [src]."))
			anchored = !anchored
			playsound(src.loc, 'sound/items/Ratchet.ogg', 50, 1)
			power_change()
			update_icon()
			if(!anchored)
				playing = 0
				disconnect_media_source()
			else
				update_media_source()
			return

	if(istype(W, /obj/item/music_tape))
		if(my_tape)
			to_chat(user, span_notice("There's already a tape inside [src]."))
		else
			my_tape = W
			user.unEquip(my_tape, src)
			my_tape.forceMove(src)
			to_chat(user, span_notice("You insert the tape inside [src]."))
			update_tape()
	return ..()


/obj/machinery/media/jukebox/proc/update_tape(removed)
	if (!removed)
		tracks.Add(get_tape_playlist())
	else
		tracks.Remove(get_tape_playlist())
		StopPlaying()
	updateDialog()

//Added as a separate proc instead of just reading the var for a future feature
/obj/machinery/media/jukebox/proc/get_tape_playlist()
	return my_tape.tracklist


/obj/machinery/media/jukebox/power_change()
	if(!powered(power_channel) || !anchored)
		stat |= NOPOWER
	else
		stat &= ~NOPOWER

	if(stat & (NOPOWER|BROKEN) && playing)
		StopPlaying()
	update_icon()

/obj/machinery/media/jukebox/update_icon()
	overlays.Cut()
	if(stat & (NOPOWER|BROKEN) || !anchored)
		if(stat & BROKEN)
			icon_state = "[state_base]-broken"
		else
			icon_state = "[state_base]-nopower"
		return
	icon_state = state_base
	if(playing)
		if(emagged)
			overlays += "[state_base]-emagged"
		else
			overlays += "[state_base]-running"
	if (panel_open)
		overlays += "panel_open"

/obj/machinery/media/jukebox/Topic(href, href_list)
	if(..() || !(Adjacent(usr) || issilicon(usr)))
		return

	if(!anchored)
		to_chat(usr, span_warning("You must secure \the [src] first."))
		return

	if(inoperable())
		to_chat(usr, "\The [src] doesn't appear to function.")
		return

	if(href_list["change_track"])
		var/datum/track/T = locate(href_list["change_track"]) in tracks
		if(istype(T))
			current_track = T
			StartPlaying()
	else if(href_list["loopmode"])
		var/newval = text2num(href_list["loopmode"])
		loop_mode = sanitize_inlist(newval, list(JUKEMODE_NEXT, JUKEMODE_RANDOM, JUKEMODE_REPEAT_SONG, JUKEMODE_PLAY_ONCE), loop_mode)
	else if(href_list["volume"])
		var/newval = input("Choose Jukebox volume (0-100%)", "Jukebox volume", round(volume * 100.0))
		newval = sanitize_integer(text2num(newval), min = 0, max = 100, default = volume * 100.0)
		volume = newval / 100.0
		update_music() // To broadcast volume change without restarting song
	else if(href_list["stop"])
		StopPlaying()
	else if(href_list["play"])
		if(emagged)
			playsound(src.loc, 'sound/items/AirHorn.ogg', 100, 1)
			for(var/mob/living/carbon/M in ohearers(6, src))
				var/ear_safety = 0
				if(ishuman(M))
					if(istype(M:l_ear, /obj/item/clothing/ears/earmuffs) || istype(M:r_ear, /obj/item/clothing/ears/earmuffs))
						ear_safety += 2
//					if(HULK in M.mutations)
//						ear_safety += 1
					if(istype(M:head, /obj/item/clothing/head/armor/helmet))
						ear_safety += 1
					if(M.stats.getPerk(PERK_EAR_OF_QUICKSILVER))
						ear_safety -= 1
				if(ear_safety >= 2)
					continue
				M.sleeping = 0
				M.stuttering += 20
				M.adjustEarDamage(0,30)
				M.Weaken(3)
				if(prob(30))
					M.Stun(10)
					M.Paralyse(4)
				else
					M.make_jittery(500)
			spawn(15)
				explode()
		else if(current_track == null)
			to_chat(usr, "No track selected.")
		else
			StartPlaying()

	return 1

/obj/machinery/media/jukebox/interact(mob/user)
	if(inoperable())
		to_chat(usr, "\The [src] doesn't appear to function.")
		return
	nano_ui_interact(user)

/obj/machinery/media/jukebox/nano_ui_interact(mob/user, ui_key = "jukebox", datum/nanoui/ui = null, force_open = 1)
	var/title = "RetroBox - Space Style"
	var/data[0]

	if(operable())
		data["playing"] = playing
		data["hacked"] = hacked
		data["max_queue_len"] = max_queue_len
		data["media_start_time"] = media_start_time
		data["loop_mode"] = loop_mode
		data["volume"] = volume
		if(current_track)
			data["current_track_ref"] = "\ref[current_track]"  // Convenient shortcut
			data["current_track"] = current_track.toNanoList()
		data["percent"] = playing ? min(100, round(world.time - media_start_time) / current_track.duration) : 0;

		var/list/nano_tracks = new
		for(var/datum/track/T in tracks)
			nano_tracks[++nano_tracks.len] = T.toNanoList()
		data["tracks"] = nano_tracks

	// update the ui if it exists, returns null if no ui is passed/found
	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)
		ui = new(user, src, ui_key, "jukebox.tmpl", title, 450, 600)
		ui.set_initial_data(data)
		ui.open()
		ui.set_auto_update(playing)

/obj/machinery/media/jukebox/attack_ai(mob/user as mob)
	return src.attack_hand(user)

/obj/machinery/media/jukebox/attack_hand(mob/user as mob)
	interact(user)

/obj/machinery/media/jukebox/proc/explode()
	walk_to(src,0)
	src.visible_message(span_danger("\the [src] blows apart!"), 1)
	explosion(get_turf(src), 200, 50)

	var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
	s.set_up(3, 1, src)
	s.start()

	new /obj/effect/decal/cleanable/blood/oil(src.loc)
	qdel(src)

/obj/machinery/media/jukebox/emag_act(remaining_charges, mob/user)
	if(!emagged)
		emagged = 1
		StopPlaying()
		visible_message(span_danger("\The [src] makes a fizzling sound."))
		update_icon()
		return 1

/obj/machinery/media/jukebox/proc/StopPlaying()
	playing = 0
	set_power_use(IDLE_POWER_USE)
	update_icon()
	var/datum/component/atom_sanity/S = GetComponent(/datum/component/atom_sanity)
	S.affect = 0
	start_stop_song()

/obj/machinery/media/jukebox/proc/StartPlaying()
	if(!current_track)
		return
	playing = 1
	var/datum/component/atom_sanity/S = GetComponent(/datum/component/atom_sanity)
	S.affect = sanity_value
	set_power_use(ACTIVE_POWER_USE)
	update_icon()
	start_stop_song()
	updateDialog()

// Advance to the next track - Don't start playing it unless we were already playing
/obj/machinery/media/jukebox/proc/NextTrack()
	if(!tracks.len) return
	var/curTrackIndex = max(1, tracks.Find(current_track))
	var/newTrackIndex = (curTrackIndex % tracks.len) + 1  // Loop back around if past end
	current_track = tracks[newTrackIndex]
	if(playing)
		start_stop_song()
	updateDialog()

// Un-advance to the previous track - Don't start playing it unless we were already playing
/obj/machinery/media/jukebox/proc/PrevTrack()
	if(!tracks.len) return
	var/curTrackIndex = max(1, tracks.Find(current_track))
	var/newTrackIndex = curTrackIndex == 1 ? tracks.len : curTrackIndex - 1
	current_track = tracks[newTrackIndex]
	if(playing)
		start_stop_song()
	updateDialog()


/obj/machinery/media/jukebox/verb/eject()
	set src in oview(1)
	set category = "Object"
	set name = "Eject tape"

	if (usr.stat)
		return

	if(my_tape)
		update_tape(TRUE)
		my_tape.forceMove(get_turf(src))
		my_tape = null
	else
		to_chat(usr, span_notice("There is no tape inside [src]."))

