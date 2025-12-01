///datum/controller/subsystem/spawn_data
	//var/list/all_spawn_bad_paths = list()//hard
	//var/list/all_spawn_blacklist = list()//soft
	//var/list/all_spawn_by_price = list()
	//var/list/all_price_by_path = list()
	//var/list/all_spawn_by_frequency = list()
	//var/list/all_spawn_frequency_by_path = list()
	//var/list/all_spawn_by_rarity = list()
	//var/list/all_spawn_rarity_by_path = list()
	//var/list/all_spawn_value_by_path = list()
	//var/list/all_spawn_by_tag = list()
	//var/list/all_accompanying_obj_by_path = list()

/datum/controller/subsystem/spawn_data/Initialize()
	..()
	generate_data()
	precompute_caches()

/datum/controller/subsystem/spawn_data
	var/list/cached_valid_candidates = list()  // Cache by parameter hash
	var/list/cached_prices = list()  // Cache prices by path
	var/list/cached_values = list()  // Cache spawn values by path
	var/list/cached_blacklist = list()  // Pre-filtered blacklist
	var/list/paths_by_price_range = list()  // Pre-sorted by price ranges


/datum/controller/subsystem/spawn_data/proc/precompute_caches()
	// Cache all prices upfront
	for(var/tag in all_spawn_by_tag)
		for(var/path in all_spawn_by_tag[tag])
			if(!(path in cached_prices))
				cached_prices[path] = get_spawn_price(path)
			if(!(path in cached_values))
				cached_values[path] = get_spawn_value(path)

	// Pre-filter blacklisted items
	var/atom/movable/A
	for(var/tag in all_spawn_by_tag)
		for(var/path in all_spawn_by_tag[tag])
			A = path
			if(initial(A.spawn_blacklisted))
				cached_blacklist[path] = TRUE

	// Pre-sort into price ranges for faster filtering
	var/list/price_brackets = list(0, 50, 100, 250, 500, 1000, 2500, 5000, 10000)
	for(var/tag in all_spawn_by_tag)
		for(var/path in all_spawn_by_tag[tag])
			var/price = cached_prices[path]
			for(var/i = 1 to price_brackets.len - 1)
				var/low = price_brackets[i]
				var/high = price_brackets[i + 1]
				if(price >= low && price < high)
					var/bracket_key = "[low]-[high]"
					if(!paths_by_price_range[bracket_key])
						paths_by_price_range[bracket_key] = list()
					paths_by_price_range[bracket_key] += path
					break


/datum/controller/subsystem/spawn_data/proc/generate_data()
	var/list/paths = list()
	var/list/spawn_tags = list()
	var/list/accompanying_objs = list()
	var/generate_files = CONFIG_GET(flag/generate_loot_data)
	var/file_dir = "strings/loot_data"
	var/source_dir = file("[file_dir]/")
	var/loot_data = file("[file_dir]/all_spawn_data.txt")
	var/loot_data_paths = file("[file_dir]/all_spawn_paths.txt")
	var/hard_blacklist_data = file("[file_dir]/hard_blacklist.txt")
	var/blacklist_paths_data = file("[file_dir]/blacklist.txt")
	var/file_dir_tags = "[file_dir]/tags/"
	if(generate_files)
		fdel(source_dir)
		loot_data << "paths    spawn_tags    blacklisted    spawn_value    spawn_price    prob_accompanying_obj    all_accompanying_obj"

	paths = subtypesof(/obj/item) - typesof(/obj/item/projectile)
	paths += subtypesof(/mob/living)
	paths += subtypesof(/obj/machinery)
	paths += subtypesof(/obj/structure)
	paths += subtypesof(/obj/spawner)
	paths += subtypesof(/obj/effect)

	for(var/path in paths)
		var/atom/movable/A = path
		if(path == initial(A.bad_type))
			if(generate_files)
				hard_blacklist_data << "[path]"
			continue

		spawn_tags = params2list(initial(A.spawn_tags))
		if(!spawn_tags.len)
			if(generate_files)
				hard_blacklist_data << "[path]"
			continue

		if(initial(A.spawn_frequency) <= 0)
			if(generate_files)
				hard_blacklist_data << "[path]"
			continue

		accompanying_objs = initial(A.accompanying_object)
		if(istext(accompanying_objs))
			accompanying_objs = splittext(accompanying_objs, ",")
			if(accompanying_objs.len)
				var/list/temp_list = accompanying_objs
				accompanying_objs = list()
				for(var/obj_text in temp_list)
					accompanying_objs += text2path(obj_text)
		else if(ispath(accompanying_objs))
			accompanying_objs = list(accompanying_objs)
		if(islist(accompanying_objs) && accompanying_objs.len)
			for(var/obj_path in accompanying_objs)
				if(!ispath(obj_path))
					continue
				all_accompanying_obj_by_path[path] += list(obj_path)
		if(ispath(path, /obj/item/gun/energy))
			var/obj/item/gun/energy/E = A
			if(!initial(E.use_external_power) && !initial(E.self_recharge))
				all_accompanying_obj_by_path[path] += list(initial(E.suitable_cell))
		else if(ispath(path, /obj/item/gun/projectile))
			var/obj/item/gun/projectile/P = A
			if(initial(P.magazine_type) && ((initial(P.load_method) & MAGAZINE) || (initial(P.load_method) & SPEEDLOADER)))
				all_accompanying_obj_by_path[path] += list(initial(P.magazine_type))
			else if(initial(P.ammo_type) && (initial(P.max_shells)) && (initial(P.load_method) & SINGLE_CASING))
				for(var/i in 1 to min(initial(P.max_shells),10))
					all_accompanying_obj_by_path[path] += list(initial(P.ammo_type))

		var/price = get_spawn_price(path)
		var/spawn_value = get_spawn_value(path)

		for(var/tag in spawn_tags)
			all_spawn_by_tag[tag] += list(path)
			if(ispath(path, /obj/item) && tag != SPAWN_OBJ &&!initial(A.density) && ISINRANGE(price, 1, CHEAP_ITEM_PRICE) && !lowkeyrandom_tags.Find(tag))
				lowkeyrandom_tags += list(tag)
			if(generate_files)
				var/tag_data_i = file("[file_dir_tags][tag].txt")
				tag_data_i << "[path]    blacklisted=[initial(A.spawn_blacklisted)]    spawn_value=[spawn_value]   spawn_price=[price]   prob_accompanying_obj=[initial(A.prob_aditional_object)]    accompanying_objs=[all_accompanying_obj_by_path[path] ? english_list(all_accompanying_obj_by_path[path], "nothing", ",") : "nothing"]"
		if(generate_files)
			loot_data << "[path]    [initial(A.spawn_tags)]    blacklisted=[initial(A.spawn_blacklisted)]    spawn_value=[spawn_value]   spawn_price=[price]   prob_accompanying_obj=[initial(A.prob_aditional_object)]    accompanying_objs=[all_accompanying_obj_by_path[path] ? english_list(all_accompanying_obj_by_path[path], "nothing", ",") : "nothing"]"
			loot_data_paths << "[path]"
			if(initial(A.spawn_blacklisted))
				blacklist_paths_data << "[path]"

/*get_spawn_value()
this proc calculates the spawn value of the objects based on factors such as
their frequency, their rarity value, their price and
the data returned by the get_special_rarity_value() proc
*/
/datum/controller/subsystem/spawn_data/proc/get_spawn_value(npath)
	if(npath in cached_values)
		return cached_values[npath]

	var/atom/movable/A = npath
	var/value
	if(ispath(npath, /obj/item/gun))
		value = 10 * initial(A.spawn_frequency)/(get_special_rarity_value(npath)+(get_spawn_price(A)/GUN_PRICE_DIVISOR))
	else if(ispath(npath, /obj/item/clothing))
		value = 10 * initial(A.spawn_frequency)/(get_special_rarity_value(npath) + (get_spawn_price(A)/CLOTH_PRICE_DIVISOR))
	else
		value = 10 * initial(A.spawn_frequency)/(get_special_rarity_value(npath) + log(10,max(get_spawn_price(A),2)))

	cached_values[npath] = value
	return value

/*get_special_rarity_value()
increases the rarity value of items
depending on certain determining factors,
for example, the rarity value of power cells increases with their max_charge,
the value of stock parts increases with the rating.
*/

/datum/controller/subsystem/spawn_data/proc/get_special_rarity_value(npath)
	var/atom/movable/A = npath
	. = initial(A.rarity_value)
	if(ispath(npath, /obj/item/cell))
		var/obj/item/cell/C = npath
		var/bonus = 0
		var/autorecharging_factor = 3.7
		if(ispath(npath, /obj/item/cell/large))
			bonus += (initial(C.maxcharge)/CELL_LARGE_BASE_CHARGE)**1.2
		else if(ispath(npath, /obj/item/cell/medium))
			bonus += (initial(C.maxcharge)/CELL_MEDIUM_BASE_CHARGE)**3.6
			autorecharging_factor += 3
		else if(ispath(npath, /obj/item/cell/small))
			bonus += (initial(C.maxcharge)/CELL_SMALL_BASE_CHARGE)**1.9
			autorecharging_factor += 2
		if(initial(C.autorecharging))
			bonus *= autorecharging_factor * (initial(C.autorecharge_rate)/BASE_AUTORECHARGE_RATE) * (initial(C.recharge_time)/BASE_RECHARGE_TIME)
		. += bonus
	else if(ispath(npath, /obj/item/stock_parts))
		var/obj/item/stock_parts/SP = npath
		. *= initial(SP.rating)**1.5

/datum/controller/subsystem/spawn_data/proc/get_spawn_price(path, with_accompaying_obj = TRUE)
	if(with_accompaying_obj && (path in cached_prices))
		return cached_prices[path]

	var/atom/movable/A = path
	. = initial(A.price_tag)
	if(with_accompaying_obj && all_accompanying_obj_by_path[path])
		for(var/a_obj in all_accompanying_obj_by_path[path])
			. += get_spawn_price(a_obj, FALSE)
	if(ispath(path, /obj/item))
		if(ispath(path, /obj/item/stock_parts))
			var/obj/item/stock_parts/S = path
			. *= initial(S.rating)
		else if(ispath(path, /obj/item/stack))
			var/obj/item/stack/S = path
			. *= initial(S.amount)
			if(ispath(path, /obj/item/stack/medical))
				var/obj/item/stack/medical/M = path
				. += initial(M.heal_brute) + initial(M.heal_burn)
		else if(ispath(path, /obj/item/ammo_casing))
			var/obj/item/ammo_casing/AC = path
			. *= initial(AC.amount)
		else if(ispath(path, /obj/item/handcuffs))
			var/obj/item/handcuffs/H = path
			. += initial(H.breakouttime) / 20
		else if(ispath(path, /obj/structure/reagent_dispensers))
			var/obj/structure/reagent_dispensers/R = path
			. += initial(R.contents_cost)
		else if(ispath(path, /obj/item/ammo_magazine))
			var/obj/item/ammo_magazine/M = path
			var/amount = initial(M.initial_ammo)
			if(isnull(amount))
				amount = initial(M.max_ammo)
			. += amount * get_spawn_price(initial(M.ammo_type))
		else if(ispath(path, /obj/item/tool))
			var/obj/item/tool/T = path
			if(initial(T.suitable_cell))
				. += get_spawn_price(initial(T.suitable_cell))
		else if(ispath(path, /obj/item/storage))
			if(ispath(path, /obj/item/storage/box))
				var/obj/item/storage/box/B = path
				if(initial(B.prespawned_content_amount) > 0 && initial(B.prespawned_content_type))
					. += initial(B.prespawned_content_amount) * get_spawn_price(initial(B.prespawned_content_type))
			else if(ispath(path, /obj/item/storage/fancy))
				var/obj/item/storage/fancy/F = path
				if(initial(F.item_obj) && initial(F.storage_slots))
					. += initial(F.storage_slots) * get_spawn_price(initial(F.item_obj))
			else if(ispath(path, /obj/item/storage/pill_bottle))
				var/obj/item/storage/pill_bottle/PB = path
				if(initial(PB.prespawned_content_amount) && initial(PB.prespawned_content_type))
					. += initial(PB.prespawned_content_amount) * get_spawn_price(initial(PB.prespawned_content_type))
			else if(ispath(path, /obj/item/storage/firstaid))
				var/obj/item/storage/firstaid/F = path
				. += initial(F.prespawned_content_amount) * get_spawn_price(initial(F.prespawned_content_type))
		else if(ispath(path, /obj/item/clothing))
			var/obj/item/clothing/C = path
			. += 5 * initial(C.style)
			. += 10 * (1 - initial(C.siemens_coefficient))
			if(ispath(path, /obj/item/clothing/suit/space/void))
				var/obj/item/clothing/suit/space/void/V = A
				if(initial(V.tank))
					. += get_spawn_price(initial(V.tank))
				if(initial(V.boots))
					. += get_spawn_price(initial(V.boots))
				if(initial(V.helmet))
					. += get_spawn_price(initial(V.helmet))
		else if(ispath(path, /obj/item/device))
			if(. == 0)
				. += 1
			var/obj/item/device/D = path
			if(initial(D.starting_cell) && initial(D.suitable_cell))
				. += get_spawn_price(initial(D.suitable_cell))
		else if(ispath(path, /obj/item/reagent_containers/glass))
			var/obj/item/reagent_containers/glass/G = path
			. += initial(G.volume)/100
		else if(ispath(path, /obj/item/computer_hardware/hard_drive/portable/design))
			var/obj/item/computer_hardware/hard_drive/portable/design/D = path
			if(initial(D.license) > 0)
				. += initial(D.license) * 2

/datum/controller/subsystem/spawn_data/proc/spawn_by_tag(list/tags)
	var/list/things = list()
	for(var/tag in tags)
		things |= all_spawn_by_tag["[tag]"]
	return things

/datum/controller/subsystem/spawn_data/proc/spawns_lower_price(list/paths, price)
	var/list/things = list()
	for(var/path in paths)
		if(cached_prices[path] < price)
			things += path
	return things

/datum/controller/subsystem/spawn_data/proc/spawns_upper_price(list/paths, price)
	var/list/things = list()
	for(var/path in paths)
		if(cached_prices[path] > price)
			things += path
	return things

/datum/controller/subsystem/spawn_data/proc/filter_densty(list/paths)
	var/list/things = list()
	for(var/path in paths)
		var/atom/movable/AM = path
		if(!initial(AM.density))
			things += path
	return things

/datum/controller/subsystem/spawn_data/proc/only_top_candidates(list/paths, top=7)
	if(paths.len <= top)
		return paths
	var/list/valid_spawn_value = list()
	var/max_value = 0
	var/list/things = list()
	for(var/j=1 to top)
		var/low = INFINITY
		for(var/path in paths)
			var/sapwn_value = cached_values[path] || get_spawn_value(path)
			if((sapwn_value < low) && !(sapwn_value in valid_spawn_value))
				low = sapwn_value
		valid_spawn_value += low
	for(var/value in valid_spawn_value)
		if(value > max_value)
			max_value = value
	for(var/path in paths)
		var/spawn_val = cached_values[path] || get_spawn_value(path)
		if(spawn_val <= max_value)
			things += path
	return things

/datum/controller/subsystem/spawn_data/proc/pick_spawn(list/paths, invert_value=FALSE)
	var/list/things = list()
	var/list/values = list()
	for(var/path in paths)
		var/spawn_value = cached_values[path] || get_spawn_value(path)
		if(!(spawn_value in values) && spawn_value > 0)
			values += spawn_value
			if(invert_value)
				spawn_value = 1/spawn_value
			things[path] = spawn_value
	var/spawn_value = pickweight(things, 0)
	spawn_value = cached_values[spawn_value] || get_spawn_value(spawn_value)
	things = list()
	for(var/path in paths)
		var/path_value = cached_values[path] || get_spawn_value(path)
		if(path_value == spawn_value)
			things += path
	if(!length(things))
		return
	return pick(things)

/datum/controller/subsystem/spawn_data/proc/take_tags(list/paths, list/exclude)
	var/list/local_tags = list()
	var/atom/movable/A
	for(var/path in paths)
		A = path
		var/list/spawn_tags = params2list(initial(A.spawn_tags))
		for(var/tag in spawn_tags)
			if(tag in local_tags)
				continue
			local_tags += list(tag)
	local_tags -= exclude
	return local_tags

/datum/controller/subsystem/spawn_data/proc/get_cache_key(list/tags, list/bad_tags, allow_blacklist, low_price, top_price, filter_density, list/include, list/exclude)
	// Create a unique string key from all parameters
	var/key = "[english_list(tags, "NONE")]|[english_list(bad_tags, "NONE")]|[allow_blacklist]|[low_price]|[top_price]|[filter_density]|[english_list(include, "NONE")]|[english_list(exclude, "NONE")]"
	return key

/datum/controller/subsystem/spawn_data/proc/valid_candidates(
	list/tags,
	list/bad_tags,
	allow_blacklist=FALSE,
	low_price=0,
	top_price=0,
	filter_density=FALSE,
	list/include,
	list/exclude,
	list/should_be_include_tags
)
	var/cache_key = get_cache_key(tags, bad_tags, allow_blacklist, low_price, top_price, filter_density, include, exclude)
	if(cache_key in cached_valid_candidates)
		return cached_valid_candidates[cache_key]

	var/list/candidates = list()

	// Get paths for all required tags at once
	for(var/tag in tags)
		if(!length(candidates))
			candidates = astype(all_spawn_by_tag[tag], /list).Copy()
		else
			candidates &= all_spawn_by_tag[tag]  // Intersection

	// Remove bad tags
	for(var/tag in bad_tags)
		candidates -= all_spawn_by_tag[tag]

	if(!allow_blacklist)
		for(var/path in candidates)
			if(cached_blacklist[path])
				candidates -= path

	if(low_price || top_price)
		var/list/price_filtered = list()
		for(var/path in candidates)
			var/price = cached_prices[path]
			if(low_price && price < low_price)
				continue
			if(top_price && price > top_price)
				continue
			price_filtered += path
		candidates = price_filtered

	// Density filter
	if(filter_density)
		candidates = filter_densty(candidates)

	// Apply include/exclude
	candidates -= exclude
	candidates |= include
	candidates = removeNullsFromList(candidates)

	cached_valid_candidates[cache_key] = candidates

	return candidates

/datum/controller/subsystem/spawn_data/proc/sort_paths_by_rarity(list/paths, invert_value=FALSE)
	var/list/copy_paths = paths.Copy()
	var/list/things = list()
	for(var/path in paths)
		var/max_value = -INFINITY
		if(invert_value)
			max_value = INFINITY
		var/selected_path
		if(!copy_paths.len)
			break
		for(var/actual_path in copy_paths)
			var/actual_value = cached_values[actual_path] || get_spawn_value(actual_path)
			if((!invert_value && actual_value > max_value) || (invert_value && (actual_value < max_value)))
				max_value = actual_value
				selected_path = actual_path
		copy_paths -= selected_path
		things += selected_path
	return things

/datum/controller/subsystem/spawn_data/proc/sort_paths_by_price(list/paths, invert_value=FALSE)
	var/list/copy_paths = paths.Copy()
	var/list/things = list()
	for(var/path in paths)
		var/max_value = INFINITY
		if(invert_value)
			max_value = -INFINITY
		var/selected_path
		if(!copy_paths.len)
			break
		for(var/actual_path in copy_paths)
			var/actual_value = cached_prices[actual_path] || get_spawn_price(actual_path)
			if((!invert_value && actual_value < max_value) || (invert_value && (actual_value > max_value)))
				max_value = actual_value
				selected_path = actual_path
		copy_paths -= selected_path
		things += selected_path
	return things
