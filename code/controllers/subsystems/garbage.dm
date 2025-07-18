/*!
## Debugging GC issues

In order to debug `qdel()` failures, there are several tools available.
To enable these tools, define `TESTING` in [_compile_options.dm](https://github.com/tgstation/-tg-station/blob/master/code/_compile_options.dm).

First is a verb called "Find References", which lists **every** refererence to an object in the world. This allows you to track down any indirect or obfuscated references that you might have missed.

Complementing this is another verb, "qdel() then Find References".
This does exactly what you'd expect; it calls `qdel()` on the object and then it finds all references remaining.
This is great, because it means that `Destroy()` will have been called before it starts to find references,
so the only references you'll find will be the ones preventing the object from `qdel()`ing gracefully.

If you have a datum or something you are not destroying directly (say via the singulo),
the next tool is `QDEL_HINT_FINDREFERENCE`. You can return this in `Destroy()` (where you would normally `return ..()`),
to print a list of references once it enters the GC queue.

Finally is a verb, "Show qdel() Log", which shows the deletion log that the garbage subsystem keeps. This is helpful if you are having race conditions or need to review the order of deletions.

Note that for any of these tools to work `TESTING` must be defined.
By using these methods of finding references, you can make your life far, far easier when dealing with `qdel()` failures.
*/

SUBSYSTEM_DEF(garbage)
	name = "Garbage"
	priority = FIRE_PRIORITY_GARBAGE
	wait = 2 SECONDS
	flags = SS_POST_FIRE_TIMING|SS_BACKGROUND|SS_NO_INIT
	runlevels = RUNLEVELS_DEFAULT | RUNLEVEL_LOBBY
	init_order = INIT_ORDER_GARBAGE
	init_stage = INITSTAGE_EARLY
	init_time_threshold = 0.5 SECONDS

	var/list/collection_timeout = list(GC_FILTER_QUEUE, GC_CHECK_QUEUE, GC_DEL_QUEUE) // deciseconds to wait before moving something up in the queue to the next level

	//Stat tracking
	var/delslasttick = 0 // number of del()'s we've done this tick
	var/gcedlasttick = 0 // number of things that gc'ed last tick
	var/totaldels = 0
	var/totalgcs = 0

	var/highest_del_ms = 0
	var/highest_del_type_string = ""

	var/list/pass_counts
	var/list/fail_counts

	var/list/items = list() // Holds our qdel_item statistics datums

	//Queue
	var/list/queues
	#ifdef REFERENCE_TRACKING
	var/list/reference_find_on_fail = list()
	#ifdef REFERENCE_TRACKING_DEBUG
	//Should we save found refs. Used for unit testing
	var/should_save_refs = FALSE
	#endif
	#endif

#if !defined(UNIT_TESTS) && !defined(REFERENCE_TRACKING)
	/// Toggle for enabling/disabling hard deletes. Objects that don't explicitly request hard deletion with this disabled will leak.
	var/enable_hard_deletes = FALSE
#endif
	var/list/failed_hard_deletes = list()


/datum/controller/subsystem/garbage/PreInit()
	InitQueues()

/datum/controller/subsystem/garbage/stat_entry(msg)
	var/list/counts = list()
	for (var/list/L in queues)
		counts += length(L)
	msg += "Q:[counts.Join(",")]|D:[delslasttick]|G:[gcedlasttick]|"
	msg += "GR:"
	if (!(delslasttick+gcedlasttick))
		msg += "n/a|"
	else
		msg += "[round((gcedlasttick/(delslasttick+gcedlasttick))*100, 0.01)]%|"

	msg += "TD:[totaldels]|TG:[totalgcs]|"
	if (!(totaldels+totalgcs))
		msg += "n/a|"
	else
		msg += "TGR:[round((totalgcs/(totaldels+totalgcs))*100, 0.01)]%"
	msg += " P:[pass_counts.Join(",")]"
	msg += "|F:[fail_counts.Join(",")]"
	return ..()

/datum/controller/subsystem/garbage/Shutdown()
	//Adds the del() log to the qdel log file
	var/list/dellog = list()

	//sort by how long it's wasted hard deleting
	sortTim(items, cmp=/proc/cmp_qdel_item_time, associative = TRUE)
	for(var/path in items)
		var/datum/qdel_item/I = items[path]
		dellog += "Path: [path]"
		if (I.qdel_flags & QDEL_ITEM_SUSPENDED_FOR_LAG)
			dellog += "\tSUSPENDED FOR LAG"
		if (I.failures)
			dellog += "\tFailures: [I.failures]"
		dellog += "\tqdel() Count: [I.qdels]"
		dellog += "\tDestroy() Cost: [I.destroy_time]ms"
		if (I.hard_deletes)
			dellog += "\tTotal Hard Deletes: [I.hard_deletes]"
			dellog += "\tTime Spent Hard Deleting: [I.hard_delete_time]ms"
			dellog += "\tHighest Time Spent Hard Deleting: [I.hard_delete_max]ms"
			if (I.hard_deletes_over_threshold)
				dellog += "\tHard Deletes Over Threshold: [I.hard_deletes_over_threshold]"
		if (I.slept_destroy)
			dellog += "\tSleeps: [I.slept_destroy]"
		if (I.no_respect_force)
			dellog += "\tIgnored force: [I.no_respect_force] times"
		if (I.no_hint)
			dellog += "\tNo hint: [I.no_hint] times"
	log_qdel(dellog.Join("\n"))

/datum/controller/subsystem/garbage/fire()
	//the fact that this resets its processing each fire (rather then resume where it left off) is intentional.
	var/queue = GC_QUEUE_FILTER

	while (state == SS_RUNNING)
		switch (queue)
			if (GC_QUEUE_FILTER)
				HandleQueue(GC_QUEUE_FILTER)
				queue = GC_QUEUE_FILTER+1
			if (GC_QUEUE_CHECK)
				HandleQueue(GC_QUEUE_CHECK)
				queue = GC_QUEUE_CHECK+1
			if (GC_QUEUE_HARDDELETE)
				HandleQueue(GC_QUEUE_HARDDELETE)
				if (state == SS_PAUSED) //make us wait again before the next run.
					state = SS_RUNNING
				break



/datum/controller/subsystem/garbage/proc/InitQueues()
	if (isnull(queues)) // Only init the queues if they don't already exist, prevents overriding of recovered lists
		queues = new(GC_QUEUE_COUNT)
		pass_counts = new(GC_QUEUE_COUNT)
		fail_counts = new(GC_QUEUE_COUNT)
		for(var/i in 1 to GC_QUEUE_COUNT)
			queues[i] = list()
			pass_counts[i] = 0
			fail_counts[i] = 0

/datum/controller/subsystem/garbage/proc/HandleQueue(level = GC_QUEUE_FILTER)
	if (level == GC_QUEUE_FILTER)
		delslasttick = 0
		gcedlasttick = 0
	var/cut_off_time = world.time - collection_timeout[level] //ignore entries newer then this
	var/list/queue = queues[level]
	var/static/lastlevel
	var/static/count = 0
	if (count) //runtime last run before we could do this.
		var/c = count
		count = 0 //so if we runtime on the Cut, we don't try again.
		var/list/lastqueue = queues[lastlevel]
		lastqueue.Cut(1, c+1)

	lastlevel = level

	//We do this rather then for(var/refID in queue) because that sort of for loop copies the whole list.
	//Normally this isn't expensive, but the gc queue can grow to 40k items, and that gets costly/causes overrun.
	for (var/i in 1 to length(queue))
		var/list/L = queue[i]
		if (length(L) < 2)
			count++
			if (MC_TICK_CHECK)
				return
			continue

		var/GCd_at_time = L[GC_QUEUE_ITEM_QUEUE_TIME]
		if(GCd_at_time > cut_off_time)
			break // Everything else is newer, skip them
		count++
		var/refID = L[GC_QUEUE_ITEM_REF]
		var/datum/D
		D = locate(refID)

		if (!D || D.gc_destroyed != GCd_at_time) // So if something else coincidently gets the same ref, it's not deleted by mistake
			++gcedlasttick
			++totalgcs
			pass_counts[level]++
			#ifdef REFERENCE_TRACKING
			reference_find_on_fail -= refID //It's deleted we don't care anymore.
			#endif
			if (MC_TICK_CHECK)
				return
			continue

		// Something's still referring to the qdel'd object.
		fail_counts[level]++

		#ifdef REFERENCE_TRACKING
		var/ref_searching = FALSE
		#endif

		switch (level)
			if (GC_QUEUE_CHECK)
				#ifdef REFERENCE_TRACKING
				if(reference_find_on_fail[refID])
					INVOKE_ASYNC(D, TYPE_PROC_REF(/datum, find_references))
					ref_searching = TRUE
				#ifdef GC_FAILURE_HARD_LOOKUP
				else
					INVOKE_ASYNC(D, TYPE_PROC_REF(/datum, find_references))
					ref_searching = TRUE
				#endif
				reference_find_on_fail -= refID
				#endif
				var/type = D.type
				var/datum/qdel_item/I = items[type]

				var/message = "## TESTING: GC: -- [text_ref(D)] | [type] was unable to be GC'd --"
				message = "[message] (ref count of [refcount(D)])"
				log_world(message)
				#ifdef TESTING
				for(var/c in GLOB.admins) //Using testing() here would fill the logs with ADMIN_VV garbage
					var/client/admin = c
					if(!check_rights_for(admin, R_ADMIN))
						continue
					to_chat(admin, "## TESTING: GC: -- [ADMIN_VV(D)] | [type] was unable to be GC'd --")
				#endif
				I.failures++

				if (I.qdel_flags & QDEL_ITEM_SUSPENDED_FOR_LAG)
					#ifdef REFERENCE_TRACKING
					if(ref_searching)
						return //ref searching intentionally cancels all further fires while running so things that hold references don't end up getting deleted, so we want to return here instead of continue
					#endif
					continue
			if (GC_QUEUE_HARDDELETE)
				if(!HardDelete(D))
					D = null
				if (MC_TICK_CHECK)
					return
				continue

		Queue(D, level+1)

		#ifdef REFERENCE_TRACKING
		if(ref_searching)
			return
		#endif

		if (MC_TICK_CHECK)
			return
	if (count)
		queue.Cut(1,count+1)
		count = 0

/datum/controller/subsystem/garbage/proc/Queue(datum/D, level = GC_QUEUE_FILTER)
	if (isnull(D))
		return
	if (level > GC_QUEUE_COUNT)
		HardDelete(D)
		return
	var/gctime = world.time
	var/refid = "\ref[D]"

	D.gc_destroyed = gctime
	var/list/queue = queues[level]

	queue[++queue.len] = list(gctime, refid) // not += for byond reasons

//this is mainly to separate things profile wise.
/datum/controller/subsystem/garbage/proc/HardDelete(datum/D, override = FALSE)
	if(!D)
		return
#if !defined(UNIT_TESTS) && !defined(REFERENCE_TRACKING)
	if(!enable_hard_deletes && !override)
		failed_hard_deletes |= D
		return
#endif
	++delslasttick
	++totaldels
	var/type = D.type
	var/refID = "\ref[D]"

	var/tick_usage = TICK_USAGE
	del(D)
	tick_usage = TICK_USAGE_TO_MS(tick_usage)

	var/datum/qdel_item/I = items[type]
	I.hard_deletes++
	I.hard_delete_time += tick_usage
	if (tick_usage > I.hard_delete_max)
		I.hard_delete_max = tick_usage
	if (tick_usage > highest_del_ms)
		highest_del_ms = tick_usage
		highest_del_type_string = "[type]"

	var/time = MS2DS(tick_usage)

	if (time > 0.1 SECONDS)
		postpone(time)
	var/threshold = 0.5 //CONFIG_GET(number/hard_deletes_overrun_threshold)
	if (threshold && (time > threshold SECONDS))
		if (!(I.qdel_flags & QDEL_ITEM_ADMINS_WARNED))
			log_game("Error: [type]([refID]) took longer than [threshold] seconds to delete (took [round(time/10, 0.1)] seconds to delete)")
			message_admins("Error: [type]([refID]) took longer than [threshold] seconds to delete (took [round(time/10, 0.1)] seconds to delete).")
			I.qdel_flags |= QDEL_ITEM_ADMINS_WARNED
		I.hard_deletes_over_threshold++
		var/overrun_limit = 0 // CONFIG_GET(number/hard_deletes_overrun_limit)
		if (overrun_limit && I.hard_deletes_over_threshold >= overrun_limit)
			I.qdel_flags |= QDEL_ITEM_SUSPENDED_FOR_LAG

/datum/controller/subsystem/garbage/Recover()
	InitQueues() //We first need to create the queues before recovering data
	if (istype(SSgarbage.queues))
		for (var/i in 1 to SSgarbage.queues.len)
			queues[i] |= SSgarbage.queues[i]

/// Qdel Item: Holds statistics on each type that passes thru qdel
/datum/qdel_item
	var/name = "" //!Holds the type as a string for this type
	var/qdels = 0 //!Total number of times it's passed thru qdel.
	var/destroy_time = 0 //!Total amount of milliseconds spent processing this type's Destroy()
	var/failures = 0 //!Times it was queued for soft deletion but failed to soft delete.
	var/hard_deletes = 0 //!Different from failures because it also includes QDEL_HINT_HARDDEL deletions
	var/hard_delete_time = 0 //!Total amount of milliseconds spent hard deleting this type.
	var/hard_delete_max = 0 //!Highest time spent hard_deleting this in ms.
	var/hard_deletes_over_threshold = 0 //!Number of times hard deletes took longer than the configured threshold
	var/no_respect_force = 0 //!Number of times it's not respected force=TRUE
	var/no_hint = 0 //!Number of times it's not even bother to give a qdel hint
	var/slept_destroy = 0 //!Number of times it's slept in its destroy
	var/qdel_flags = 0 //!Flags related to this type's trip thru qdel.

/datum/qdel_item/New(mytype)
	name = "[mytype]"


/// Should be treated as a replacement for the 'del' keyword.
///
/// Datums passed to this will be given a chance to clean up references to allow the GC to collect them.
/proc/qdel(datum/to_delete, force=FALSE, ...)
	if(!istype(to_delete))
		if(isnull(to_delete))
			return
		else if(islist(to_delete))
			stack_trace("Lists should not be directly passed to qdel! You likely want either list.Cut(), QDEL_LIST(list), QDEL_LIST_ASSOC(list), or QDEL_LIST_ASSOC_VAL(list)")
		else if(to_delete != world)
			stack_trace("Tried to qdel possibly invalid value: [to_delete]")
		del(to_delete)
		return

	var/datum/qdel_item/I = SSgarbage.items[to_delete.type]
	if (!I)
		I = SSgarbage.items[to_delete.type] = new /datum/qdel_item(to_delete.type)
	I.qdels++

	if(isnull(to_delete.gc_destroyed))
		if (SEND_SIGNAL(to_delete, COMSIG_PARENT_PREQDELETED, force)) // Give the components a chance to prevent their parent from being deleted
			return
		to_delete.gc_destroyed = GC_CURRENTLY_BEING_QDELETED
		var/start_time = world.time
		var/start_tick = world.tick_usage
		SEND_SIGNAL(to_delete, COMSIG_PARENT_QDELETING, force) // Let the (remaining) components know about the result of Destroy
		var/hint = to_delete.Destroy(arglist(args.Copy(2))) // Let our friend know they're about to get fucked up.
		if(world.time != start_time)
			I.slept_destroy++
		else
			I.destroy_time += TICK_USAGE_TO_MS(start_tick)
		if(!to_delete)
			return
		switch(hint)
			if (QDEL_HINT_QUEUE) //qdel should queue the object for deletion.
				SSgarbage.Queue(to_delete)
			if (QDEL_HINT_IWILLGC)
				to_delete.gc_destroyed = world.time
				return
			if (QDEL_HINT_LETMELIVE) //qdel should let the object live after calling destory.
				if(!force)
					to_delete.gc_destroyed = null //clear the gc variable (important!)
					return
				// Returning LETMELIVE after being told to force destroy
				// indicates the objects Destroy() does not respect force
				#ifdef TESTING
				if(!I.no_respect_force)
					testing("WARNING: [to_delete.type] has been force deleted, but is \
						returning an immortal QDEL_HINT, indicating it does \
						not respect the force flag for qdel(). It has been \
						placed in the queue, further instances of this type \
						will also be queued.")
				#endif
				I.no_respect_force++

				SSgarbage.Queue(to_delete)
			if (QDEL_HINT_HARDDEL) //qdel should assume this object won't gc, and queue a hard delete
				SSgarbage.Queue(to_delete, GC_QUEUE_HARDDELETE)
			if (QDEL_HINT_HARDDEL_NOW) //qdel should assume this object won't gc, and hard del it post haste.
				SSgarbage.HardDelete(to_delete)
			#ifdef REFERENCE_TRACKING
			if (QDEL_HINT_FINDREFERENCE) //qdel will, if REFERENCE_TRACKING is enabled, display all references to this object, then queue the object for deletion.
				SSgarbage.Queue(to_delete)
				to_delete.find_references() //This breaks ci. Consider it insurance against somehow pring reftracking on accident
			if (QDEL_HINT_IFFAIL_FINDREFERENCE) //qdel will, if REFERENCE_TRACKING is enabled and the object fails to collect, display all references to this object.
				SSgarbage.Queue(to_delete)
				SSgarbage.reference_find_on_fail["\ref[to_delete]"] = TRUE
			#endif
			else
				#ifdef TESTING
				if(!I.no_hint)
					testing("WARNING: [to_delete.type] is not returning a qdel hint. It is being placed in the queue. Further instances of this type will also be queued.")
				#endif
				I.no_hint++
				SSgarbage.Queue(to_delete)
	else if(to_delete.gc_destroyed == GC_CURRENTLY_BEING_QDELETED)
		CRASH("[to_delete.type] destroy proc was called multiple times, likely due to a qdel loop in the Destroy logic")


#ifdef REFERENCE_TRACKING

/datum/proc/find_references(skip_alert)
	running_find_references = type
	if(usr?.client)
		if(usr.client.running_find_references)
			log_reftracker("CANCELLED search for references to a [usr.client.running_find_references].")
			usr.client.running_find_references = null
			running_find_references = null
			//restart the garbage collector
			SSgarbage.can_fire = TRUE
			SSgarbage.update_nextfire(reset_time = TRUE)
			return

		if(!skip_alert && alert(usr,"Running this will lock everything up for about 5 minutes.  Would you like to begin the search?", "Find References", list("Yes", "No")) != "Yes")
			running_find_references = null
			return

	//this keeps the garbage collector from failing to collect objects being searched for in here
	SSgarbage.can_fire = FALSE

	if(usr?.client)
		usr.client.running_find_references = type

	log_reftracker("Beginning search for references to a [type].")

	var/starting_time = world.time

	//Time to search the whole game for our ref
	DoSearchVar(GLOB, "GLOB", search_time = starting_time) //globals
	log_reftracker("Finished searching globals")

	//Yes we do actually need to do this. The searcher refuses to read weird lists
	//And global.vars is a really weird list
	var/global_vars = list()
	for(var/key in global.vars)
		global_vars[key] = global.vars[key]

	DoSearchVar(global_vars, "Native Global", search_time = starting_time)
	log_reftracker("Finished searching native globals")

	for(var/datum/thing in world) //atoms (don't beleive its lies)
		DoSearchVar(thing, "World -> [thing.type]", search_time = starting_time)
	log_reftracker("Finished searching atoms")

	for(var/datum/thing) //datums
		DoSearchVar(thing, "Datums -> [thing.type]", search_time = starting_time)
	log_reftracker("Finished searching datums")

	//Warning, attempting to search clients like this will cause crashes if done on live. Watch yourself
#ifndef REFERENCE_DOING_IT_LIVE
	for(var/client/thing) //clients
		DoSearchVar(thing, "Clients -> [thing.type]", search_time = starting_time)
	log_reftracker("Finished searching clients")
#endif

	log_reftracker("Completed search for references to a [type].")

	if(usr?.client)
		usr.client.running_find_references = null
	running_find_references = null

	//restart the garbage collector
	SSgarbage.can_fire = TRUE
	SSgarbage.update_nextfire(reset_time = TRUE)

/datum/proc/DoSearchVar(potential_container, container_name, recursive_limit = 64, search_time = world.time)
	#ifdef REFERENCE_TRACKING_DEBUG
	if(SSgarbage.should_save_refs && !found_refs)
		found_refs = list()
	#endif

	if(usr?.client && !usr.client.running_find_references)
		return

	if(!recursive_limit)
		log_reftracker("Recursion limit reached. [container_name]")
		return

	//Check each time you go down a layer. This makes it a bit slow, but it won't effect the rest of the game at all
	#ifndef FIND_REF_NO_CHECK_TICK
	CHECK_TICK
	#endif

	if(isdatum(potential_container))
		var/datum/datum_container = potential_container
		if(datum_container.last_find_references == search_time)
			return

		datum_container.last_find_references = search_time
		var/list/vars_list = datum_container.vars

		for(var/varname in vars_list)
			#ifndef FIND_REF_NO_CHECK_TICK
			CHECK_TICK
			#endif
			if (varname == "vars" || varname == "vis_locs") //Fun fact, vis_locs don't count for references
				continue
			var/variable = vars_list[varname]

			if(variable == src)
				#ifdef REFERENCE_TRACKING_DEBUG
				if(SSgarbage.should_save_refs)
					found_refs[varname] = TRUE
					continue //End early, don't want these logging
				#endif
				log_reftracker("Found [type] \ref[src] in [datum_container.type]'s \ref[datum_container] [varname] var. [container_name]")
				continue

			if(islist(variable))
				DoSearchVar(variable, "[container_name] \ref[datum_container] -> [varname] (list)", recursive_limit - 1, search_time)

	else if(islist(potential_container))
		var/normal = IS_NORMAL_LIST(potential_container)
		var/list/potential_cache = potential_container
		for(var/element_in_list in potential_cache)
			#ifndef FIND_REF_NO_CHECK_TICK
			CHECK_TICK
			#endif
			//Check normal entrys
			if(element_in_list == src)
				#ifdef REFERENCE_TRACKING_DEBUG
				if(SSgarbage.should_save_refs)
					found_refs[potential_cache] = TRUE
					continue //End early, don't want these logging
				#endif
				log_reftracker("Found [type] \ref[src] in list [container_name].")
				continue

			var/assoc_val = null
			if(!isnum(element_in_list) && normal)
				assoc_val = potential_cache[element_in_list]
			//Check assoc entrys
			if(assoc_val == src)
				#ifdef REFERENCE_TRACKING_DEBUG
				if(SSgarbage.should_save_refs)
					found_refs[potential_cache] = TRUE
					continue //End early, don't want these logging
				#endif
				log_reftracker("Found [type] \ref[src] in list [container_name]\[[element_in_list]\]")
				continue
			//We need to run both of these checks, since our object could be hiding in either of them
			//Check normal sublists
			if(islist(element_in_list))
				DoSearchVar(element_in_list, "[container_name] -> [element_in_list] (list)", recursive_limit - 1, search_time)
			//Check assoc sublists
			if(islist(assoc_val))
				DoSearchVar(potential_container[element_in_list], "[container_name]\[[element_in_list]\] -> [assoc_val] (list)", recursive_limit - 1, search_time)

/proc/qdel_and_find_ref_if_fail(datum/thing_to_del, force = FALSE)
	thing_to_del.qdel_and_find_ref_if_fail(force)

/datum/proc/qdel_and_find_ref_if_fail(force = FALSE)
	SSgarbage.reference_find_on_fail["\ref[src]"] = TRUE
	qdel(src, force)

#endif
