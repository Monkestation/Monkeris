PROCESSING_SUBSYSTEM_DEF(nano)
	name = "NanoUI"
	priority = FIRE_PRIORITY_NANO
	wait = 2 SECONDS

	// a list of current open /nanoui UIs, grouped by src_object and ui_key
	// Renamed to _open_uis to avoid conflict with Tgui
	var/list/_open_uis = list()

 /**
  * Get an open /nanoui ui for the current user, src_object and ui_key and try to update it with data
  *
  * @param user /mob The mob who opened/owns the ui
  * @param src_object /obj|/mob The obj or mob which the ui belongs to
  * @param ui_key string A string key used for the ui
  * @param ui /datum/nanoui An existing instance of the ui (can be null)
  * @param data list The data to be passed to the ui, if it exists
  * @param force_open boolean The ui is being forced to (re)open, so close ui if it exists (instead of updating)
  *
  * @return /nanoui Returns the found ui, for null if none exists
  */
/datum/controller/subsystem/processing/nano/proc/try_update_ui(mob/user, src_object, ui_key, datum/nanoui/ui, data, force_open = 0)
	if (!ui) // no ui has been passed, so we'll search for one
		ui = get_open_ui(user, src_object, ui_key)
	if (!ui)
		return null
	// The UI is already open
	if (force_open == NANOUI_FORCE_OPEN)
		// Close it so it will be re-opened.
		ui.close()
		return null

	else if (force_open == NANOUI_FOCUS)
		ui.focus()

	else if (force_open == NANOUI_REINITIALIZE)
		ui.reinitialise(new_initial_data=data)
		return ui

	ui.push_data(data)

	return ui

 /**
  * Get an open /nanoui ui for the current user, src_object and ui_key
  *
  * @param user /mob The mob who opened/owns the ui
  * @param src_object /obj|/mob The obj or mob which the ui belongs to
  * @param ui_key string A string key used for the ui
  *
  * @return /nanoui Returns the found ui, or null if none exists
  */
/datum/controller/subsystem/processing/nano/proc/get_open_ui(mob/user, src_object, ui_key)
	var/src_object_key = "\ref[src_object]"
	if (!_open_uis[src_object_key] || !_open_uis[src_object_key][ui_key])
		return

	for (var/datum/nanoui/ui in _open_uis[src_object_key][ui_key])
		if (ui.user == user)
			// This fixes the UI being broken when it's registred as open on serverside, but is actually closed on client.
			// We check if the UI is actually open on client, and force it to re-open if it isn't.
			if(!ui.verify_open())
				ui.close()
				return null
			return ui

 /**
  * Update all /nanoui uis attached to src_object
  *
  * @param src_object /obj|/mob The obj or mob which the uis are attached to
  *
  * @return int The number of uis updated
  */
/datum/controller/subsystem/processing/nano/proc/update_uis(src_object)
	. = 0
	var/src_object_key = "\ref[src_object]"
	if (!_open_uis[src_object_key])
		return

	for (var/ui_key in _open_uis[src_object_key])
		for (var/datum/nanoui/ui in _open_uis[src_object_key][ui_key])
			if(ui.src_object && ui.user && ui.src_object.nano_host())
				ui.try_update(1)
				.++
			else
				ui.close()

 /**
  * Close all /nanoui uis attached to src_object
  *
  * @param src_object /obj|/mob The obj or mob which the uis are attached to
  *
  * @return int The number of uis close
  */
/datum/controller/subsystem/processing/nano/proc/close_uis(src_object)
	. = 0
	var/src_object_key = "\ref[src_object]"
	if (!_open_uis[src_object_key])
		return

	for (var/ui_key in _open_uis[src_object_key])
		for (var/datum/nanoui/ui in _open_uis[src_object_key][ui_key])
			ui.close() // If it's missing src_object or user, we want to close it even more.
			.++

 /**
  * Update /nanoui uis belonging to user
  *
  * @param user /mob The mob who owns the uis
  * @param src_object /obj|/mob If src_object is provided, only update uis which are attached to src_object (optional)
  * @param ui_key string If ui_key is provided, only update uis with a matching ui_key (optional)
  *
  * @return int The number of uis updated
  */
/datum/controller/subsystem/processing/nano/proc/update_user_uis(mob/user, src_object, ui_key)
	. = 0
	if (!length(user.open_uis))
		return // has no open uis

	for (var/datum/nanoui/ui in user.open_uis)
		if ((isnull(src_object) || ui.src_object == src_object) && (isnull(ui_key) || ui.ui_key == ui_key))
			ui.try_update(1)
			.++

 /**
  * Close /nanoui uis belonging to user
  *
  * @param user /mob The mob who owns the uis
  * @param src_object /obj|/mob If src_object is provided, only close uis which are attached to src_object (optional)
  * @param ui_key string If ui_key is provided, only close uis with a matching ui_key (optional)
  *
  * @return int The number of uis closed
  */
/datum/controller/subsystem/processing/nano/proc/close_user_uis(mob/user, src_object, ui_key)
	. = 0
	if (!length(user.open_uis))
		return // has no open uis

	for (var/datum/nanoui/ui in user.open_uis)
		if ((isnull(src_object) || ui.src_object == src_object) && (isnull(ui_key) || ui.ui_key == ui_key))
			ui.close()
			.++

 /**
  * Add a /nanoui ui to the list of open uis
  * This is called by the /nanoui open() proc
  *
  * @param ui /nanoui The ui to add
  *
  * @return nothing
  */
/datum/controller/subsystem/processing/nano/proc/ui_opened(datum/nanoui/ui)
	var/src_object_key = "\ref[ui.src_object]"
	LAZYINITLIST(_open_uis[src_object_key])
	LAZYOR(_open_uis[src_object_key][ui.ui_key], ui)
	LAZYOR(ui.user.open_uis, ui)
	START_PROCESSING(SSnano, ui)

 /**
  * Remove a /nanoui ui from the list of open uis
  * This is called by the /nanoui close() proc
  *
  * @param ui /nanoui The ui to remove
  *
  * @return int 0 if no ui was removed, 1 if removed successfully
  */
/datum/controller/subsystem/processing/nano/proc/ui_closed(datum/nanoui/ui)
	var/src_object_key = "\ref[ui.src_object]"
	if (!_open_uis[src_object_key] || !_open_uis[src_object_key][ui.ui_key])
		return 0 // wasn't open

	STOP_PROCESSING(SSnano, ui)
	if(ui.user)	// Sanity check in case a user has been deleted (say a blown up borg watching the alarm interface)
		LAZYREMOVE(ui.user.open_uis, ui)
	_open_uis[src_object_key][ui.ui_key] -= ui
	if(!length(_open_uis[src_object_key][ui.ui_key]))
		_open_uis[src_object_key] -= ui.ui_key
		if(!length(_open_uis[src_object_key]))
			_open_uis -= src_object_key
	return 1

 /**
  * This is called on user logout
  * Closes/clears all uis attached to the user's /mob
  *
  * @param user /mob The user's mob
  *
  * @return nothing
  */
/datum/controller/subsystem/processing/nano/proc/user_logout(mob/user)
	return close_user_uis(user)

 /**
  * This is called when a player transfers from one mob to another
  * Transfers all open UIs to the new mob
  *
  * @param oldMob /mob The user's old mob
  * @param newMob /mob The user's new mob
  *
  * @return nothing
  */
/datum/controller/subsystem/processing/nano/proc/user_transferred(mob/oldMob, mob/newMob)
	if (!oldMob || !oldMob.open_uis)
		return 0 // has no open uis

	LAZYINITLIST(newMob.open_uis)
	for (var/datum/nanoui/ui in oldMob.open_uis)
		ui.user = newMob
		newMob.open_uis += ui
	oldMob.open_uis = null
	return 1 // success
