// A reasonable number of maximum overlays an object needs
// If you think you need more, rethink it
#define MAX_ATOM_OVERLAYS 250

/// Checks if an atom has reached the overlay limit, and make a loud error if it does.
#define VALIDATE_OVERLAY_LIMIT(changed_on) \
	if(length(changed_on.overlays) >= MAX_ATOM_OVERLAYS) { \
		var/text_lays = overlays2text(changed_on.overlays); \
		stack_trace("Too many overlays on [changed_on.type] - [length(changed_on.overlays)], refusing to update and cutting.\
			\n What follows is a printout of all existing overlays at the time of the overflow \n[text_lays]"); \
		changed_on.overlays.Cut(); \
		changed_on.add_overlay(mutable_appearance('icons/testing/greyscale_error.dmi')); \
	} \


//To be called by things that are potentially many layers deep
//This recurses up the hierarchy until it finds an atom whose parent is a turf
/atom/proc/get_toplevel_atom()
	//This function will return the mob which is holding this holder, or null if it's not held
	//It recurses up the hierarchy out of containers until it reaches a mob, or a turf, or hits the limit
	var/x = 0//As a safety, we'll crawl up a maximum of 10 layers
	var/atom/a = src
	while (x < 10)
		x++
		if (isnull(a))
			return null


		if (istype(a.loc, /turf))
			return a

		a = a.loc

	return null//If we get here, the holder must be buried many layers deep in nested containers, or else is somehow contained in nullspace

/atom/proc/is_inside(LIST)
	var/atom/A = loc
	while(!is_type_in_list(A, LIST))
		if(isnull(A))
			return null
		A = A.loc
		if(isturf(A))
			return FALSE
	return A

/atom/proc/add_overlay(overlay)
	ASSERT(overlay)

	if(istext(overlay))
		overlays.Add(image(icon,icon_state = overlay))
	else
		overlays.Add(overlay)


/atom/proc/copy_overlays(atom/other, cut_old) //copys our_overlays from another atom
	if(!other)
		if(cut_old)
			cut_overlays()
		return

	var/list/cached_other = other.overlays.Copy()
	if(cut_old)
		if(cached_other)
			overlays = cached_other
		else
			overlays = null
		VALIDATE_OVERLAY_LIMIT(src)
	else if(cached_other)
		overlays += cached_other
		VALIDATE_OVERLAY_LIMIT(src)

/atom/proc/in_maintenance()
	var/area/A = get_area(src)
	if (A && A.is_maintenance)
		return TRUE
	return FALSE

/// Converts an overlay list into text for debug printing
/// Of note: overlays aren't actually mutable appearances, they're just appearances
/// Don't have access to that type tho, so this is the best you're gonna get
/proc/overlays2text(list/overlays)
	var/list/unique_overlays = list()
	// As anything because we're basically doing type coerrsion, rather then actually filtering for mutable apperances
	for(var/mutable_appearance/overlay as anything in overlays)
		var/key = "[overlay.icon]-[overlay.icon_state]-[overlay.dir]"
		unique_overlays[key] += 1
	var/list/output_text = list()
	for(var/key in unique_overlays)
		output_text += "([key]) = [unique_overlays[key]]"
	return output_text.Join("\n")

///Returns a chosen path that is the closest to a list of matches
/proc/pick_closest_path(value, list/matches = get_fancy_list_of_atom_types())
	if (value == FALSE) //nothing should be calling us with a number, so this is safe
		value = input("Enter type to find (blank for all, cancel to cancel)", "Search for type") as null|text
		if (isnull(value))
			return
	value = trim(value)

	var/random = FALSE
	if(findtext(value, "?"))
		value = replacetext(value, "?", "")
		random = TRUE

	if(!isnull(value) && value != "")
		matches = filter_fancy_list(matches, value)

	if(matches.len == 0)
		return

	var/chosen
	if(matches.len == 1)
		chosen = matches[1]
	else if(random)
		chosen = pick(matches) || null
	else
		chosen = input("Select a type", "Pick Type", matches[1]) as null|anything in sortList(matches)
	if(!chosen)
		return
	chosen = matches[chosen]
	return chosen


///Add filters by priority to an atom
/atom/proc/add_filter(name,priority,list/params)
	LAZYINITLIST(filter_data)
	var/list/p = params.Copy()
	p["priority"] = priority
	filter_data[name] = p
	update_filters()

///Sorts our filters by priority and reapplies them
/atom/proc/update_filters()
	filters = null
	filter_data = sortTim(filter_data, GLOBAL_PROC_REF(cmp_filter_data_priority), TRUE)
	for(var/f in filter_data)
		var/list/data = filter_data[f]
		var/list/arguments = data.Copy()
		arguments -= "priority"
		filters += filter(arglist(arguments))
	UNSETEMPTY(filter_data)

/atom/proc/transition_filter(name, time, list/new_params, easing, loop)
	var/filter = get_filter(name)
	if(!filter)
		return

	var/list/old_filter_data = filter_data[name]

	var/list/params = old_filter_data.Copy()
	for(var/thing in new_params)
		params[thing] = new_params[thing]

	animate(filter, new_params, time = time, easing = easing, loop = loop)
	for(var/param in params)
		filter_data[name][param] = params[param]

/atom/proc/change_filter_priority(name, new_priority)
	if(!filter_data || !filter_data[name])
		return

	filter_data[name]["priority"] = new_priority
	update_filters()

/obj/item/update_filters()
	. = ..()
	if(action && action.owner)
		var/mob/living/ourowner = action.owner
		ourowner.update_action_buttons()

///returns a filter in the managed filters list by name
/atom/proc/get_filter(name)
	if(filter_data && filter_data[name])
		return filters[filter_data.Find(name)]

///removes a filter from the atom
/atom/proc/remove_filter(name_or_names)
	if(!filter_data)
		return
	var/list/names = islist(name_or_names) ? name_or_names : list(name_or_names)

	for(var/name in names)
		if(filter_data[name])
			filter_data -= name
	update_filters()

/atom/proc/clear_filters()
	filter_data = null
	filters = null
