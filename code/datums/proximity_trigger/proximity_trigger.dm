/*
* Informs a given owner about objects entering relevant turfs.
* How to use:
* Supply:
*	* holder           - The atom which wish to be informed of entered turfs
*	* on_turf_entered  - The proc to call when a turf has been entered. The object which entered the turf is supplied.
*		NOTE: The holder itself will call this proc if its turf changes, even if it enters a turf that isn't seen.
*	* on_turfs_changed - The proc to call if the turfs being listened to have changed. The previous and new list of seen turfs is supplied.
*	* range            - The effective range of the proximity detector. Small values strongly recommended. Can be changed later by calling set_range()
*	* proximity_flags  - Various minor special cases, see the PROXIMITY_* flags below.
*	* proc_owner       - Optional. holder used if unset. The owner instance of the procs supplied above.
*
* Call register_turfs() to begin listening to relevant turfs.
* Call unregister_turfs() to stop listening. No argument is required.
*/

var/const/PROXIMITY_EXCLUDE_HOLDER_TURF = 1 // When acquiring turfs to monitor, excludes the turf the holder itself is currently in.

/datum/proximity_trigger
	var/atom/holder

	var/proc_owner
	var/on_turf_entered
	var/on_turfs_changed

	var/range_

	var/list/turfs_in_range
	var/list/seen_turfs_

	var/proximity_flags = 0

	var/decl/turf_selection/turf_selection

/datum/proximity_trigger/square
	turf_selection = /decl/turf_selection/square

/datum/proximity_trigger/New(holder, on_turf_entered, on_turfs_changed, range = 2, proximity_flags = 0, proc_owner)
	..()

	if(!ispath(turf_selection, /decl/turf_selection))
		CRASH("Invalid turf selection type set: [turf_selection]")
	turf_selection = decls_repository.get_decl(turf_selection)

	src.holder = holder
	src.on_turf_entered = on_turf_entered
	src.on_turfs_changed = on_turfs_changed
	range_ = range
	src.proximity_flags = proximity_flags
	src.proc_owner = proc_owner || holder

	turfs_in_range = list()
	seen_turfs_ = list()

/datum/proximity_trigger/Destroy()
	unregister_turfs()

	on_turfs_changed = null
	on_turf_entered = null
	holder = null
	. = ..()

/datum/proximity_trigger/proc/is_active()
	return turfs_in_range.len

/datum/proximity_trigger/proc/set_range(new_range)
	if(range_ == new_range)
		return
	range_ = new_range
	if(is_active())
		register_turfs()

/datum/proximity_trigger/proc/register_turfs()
	if(ismovable(holder))
		GLOB.moved_event.register(holder, src, /datum/proximity_trigger/proc/on_holder_moved)
	GLOB.dir_set_event.register(holder, src, /datum/proximity_trigger/proc/register_turfs) // Changing direction might alter the relevant turfs

	var/list/new_turfs = acquire_relevant_turfs()
	if(listequal(turfs_in_range, new_turfs))
		return

	for(var/t in (turfs_in_range - new_turfs))
		GLOB.opacity_set_event.unregister(t, src, /datum/proximity_trigger/proc/on_turf_visibility_changed)
	for(var/t in (new_turfs - turfs_in_range))
		GLOB.opacity_set_event.register(t, src, /datum/proximity_trigger/proc/on_turf_visibility_changed)

	turfs_in_range = new_turfs
	on_turf_visibility_changed()

/datum/proximity_trigger/proc/unregister_turfs()
	if(ismovable(holder))
		GLOB.moved_event.unregister(holder, src, /datum/proximity_trigger/proc/on_holder_moved)
	GLOB.dir_set_event.unregister(holder, src, /datum/proximity_trigger/proc/register_turfs)

	for(var/t in turfs_in_range)
		GLOB.opacity_set_event.unregister(t, src, /datum/proximity_trigger/proc/on_turf_visibility_changed)
	for(var/t in seen_turfs_)
		GLOB.entered_event.unregister(t, src, /datum/proximity_trigger/proc/on_turf_entered)

	call(proc_owner, on_turfs_changed)(seen_turfs_.Copy(), list())

	turfs_in_range.Cut()
	seen_turfs_.Cut()

/datum/proximity_trigger/proc/on_turf_visibility_changed()
	var/list/new_seen_turfs_ = get_seen_turfs()
	if(listequal(seen_turfs_, new_seen_turfs_))
		return

	call(proc_owner, on_turfs_changed)(seen_turfs_.Copy(), new_seen_turfs_.Copy())

	for(var/t in (seen_turfs_ - new_seen_turfs_))
		GLOB.entered_event.unregister(t, src, /datum/proximity_trigger/proc/on_turf_entered)
	for(var/t in (new_seen_turfs_ - seen_turfs_))
		GLOB.entered_event.register(t, src, /datum/proximity_trigger/proc/on_turf_entered)

	seen_turfs_ = new_seen_turfs_

/datum/proximity_trigger/proc/on_holder_moved(holder, old_loc, new_loc)
	var/old_turf = get_turf(old_loc)
	var/new_turf = get_turf(new_loc)
	if(old_turf == new_turf)
		return
	call(proc_owner, on_turf_entered)(holder)
	register_turfs()

/datum/proximity_trigger/proc/on_turf_entered(turf/T, atom/enterer)
	if(enterer == holder) // We have an explicit call for holder, in case it moved somewhere we're not listening to.
		return
	if(enterer.opacity)
		on_turf_visibility_changed()
	call(proc_owner, on_turf_entered)(enterer)

/datum/proximity_trigger/proc/get_seen_turfs()
	. = list()
	var/turf/center = get_turf(holder)
	if(!center)
		return

	for(var/T in dview(range_, center))
		if(T in turfs_in_range)
			. += T

/datum/proximity_trigger/proc/acquire_relevant_turfs()
	. = turf_selection.get_turfs(holder, range_)
	if(proximity_flags & PROXIMITY_EXCLUDE_HOLDER_TURF)
		. -= get_turf(holder)
