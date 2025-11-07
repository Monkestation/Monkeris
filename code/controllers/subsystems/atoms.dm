//#define INIT_TRACK

#define BAD_INIT_QDEL_BEFORE 1
#define BAD_INIT_DIDNT_INIT 2
#define BAD_INIT_SLEPT 4
#define BAD_INIT_NO_HINT 8

SUBSYSTEM_DEF(atoms)
	name = "Atoms"
	init_order = INIT_ORDER_ATOMS
	flags = SS_NO_FIRE
	init_time_threshold = 1 MINUTE

	var/old_initialized

	var/list/late_loaders = list()

	var/list/BadInitializeCalls = list()

	///initAtom() adds the atom its creating to this list iff InitializeAtoms() has been given a list to populate as an argument
	var/list/created_atoms

	var/list/init_costs = list()
	var/list/init_counts = list()

	var/list/late_init_costs = list()
	var/list/late_init_counts = list()

	initialized = INITIALIZATION_INSSATOMS

/datum/controller/subsystem/atoms/Initialize(timeofday)
	initialized = INITIALIZATION_INNEW_MAPLOAD
	InitializeAtoms()
	initialized = INITIALIZATION_INNEW_REGULAR
	return ..()

/datum/controller/subsystem/atoms/proc/InitializeAtoms(list/atoms, list/atoms_to_return = null)
	if(initialized == INITIALIZATION_INSSATOMS)
		return

	var/previous_state = null
	if(initialized != INITIALIZATION_INNEW_MAPLOAD)
		previous_state = initialized
		initialized = INITIALIZATION_INNEW_MAPLOAD

	if (atoms_to_return)
		LAZYINITLIST(created_atoms)

	var/count
	var/list/mapload_arg = list(TRUE)

	if(atoms)
		count = atoms.len
		for(var/I in 1 to count)
			var/atom/A = atoms[I]
			if(!A.initialized)
				CHECK_TICK
				InitAtom(A, TRUE, mapload_arg)
	else
		count = 0
		for(var/atom/A in world)
			if(!A.initialized)
				InitAtom(A, FALSE, mapload_arg)
				++count
				CHECK_TICK

	testing("Initialized [count] atoms")
	pass(count)

	if(previous_state != initialized)
		initialized = previous_state

	if(late_loaders.len)
		for(var/I in 1 to late_loaders.len)
			var/atom/A = late_loaders[I]
			//I hate that we need this
			if(QDELETED(A))
				continue

			#ifdef INIT_TRACK
			var/the_type = A.type
			late_init_costs |= the_type
			late_init_counts |= the_type
			var/startreal = REALTIMEOFDAY
			#endif

			A.LateInitialize(mapload_arg)

			#ifdef INIT_TRACK
			late_init_costs[the_type] += REALTIMEOFDAY - startreal
			late_init_counts[the_type] += 1
			#endif

		testing("Late initialized [late_loaders.len] atoms")
		late_loaders.Cut()

	if (created_atoms)
		atoms_to_return += created_atoms
		created_atoms = null

/// Init this specific atom
/datum/controller/subsystem/atoms/proc/InitAtom(atom/A, from_template = FALSE, list/arguments)
	var/the_type = A.type
	if(QDELING(A))
		BadInitializeCalls[the_type] |= BAD_INIT_QDEL_BEFORE
		return TRUE
	#ifdef INIT_TRACK
	init_costs |= A.type
	init_counts |= A.type

	var/startreal = REALTIMEOFDAY
	#endif
	var/start_tick = world.time

	var/result = A.Initialize(arglist(arguments))

	if(start_tick != world.time)
		BadInitializeCalls[the_type] |= BAD_INIT_SLEPT

	var/qdeleted = FALSE

	if(result != INITIALIZE_HINT_NORMAL)
		switch(result)
			if(INITIALIZE_HINT_LATELOAD)
				if(arguments[1]) //mapload
					late_loaders += A
				else
					#ifdef INIT_TRACK
					late_init_costs |= the_type
					late_init_counts |= the_type
					var/late_startreal = REALTIMEOFDAY
					#endif
					A.LateInitialize()
					#ifdef INIT_TRACK
					late_init_costs[the_type] += REALTIMEOFDAY - late_startreal
					late_init_counts[the_type] += 1
					#endif
			if(INITIALIZE_HINT_QDEL)
				qdel(A)
				qdeleted = TRUE
			if(INITIALIZE_HINT_QDEL_FORCE)
				qdel(A, force = TRUE)
				qdeleted = TRUE
			else
				BadInitializeCalls[the_type] |= BAD_INIT_NO_HINT

	if(!A) //possible harddel
		qdeleted = TRUE
	else if(!A.initialized)
		BadInitializeCalls[the_type] |= BAD_INIT_DIDNT_INIT
	else
		//SEND_SIGNAL_OLD(A,COMSIG_ATOM_AFTER_SUCCESSFUL_INITIALIZE)
		if(created_atoms && from_template && ispath(the_type, /atom/movable))//we only want to populate the list with movables
			created_atoms += A.GetAllContents()

	#ifdef INIT_TRACK
	init_costs[A.type] += REALTIMEOFDAY - startreal
	init_counts[A.type] += 1
	#endif

	return qdeleted || QDELING(A)

/datum/controller/subsystem/atoms/proc/map_loader_begin()
	old_initialized = initialized
	initialized = INITIALIZATION_INSSATOMS

/datum/controller/subsystem/atoms/proc/map_loader_stop()
	initialized = old_initialized

/datum/controller/subsystem/atoms/Recover()
	initialized = SSatoms.initialized
	if(initialized == INITIALIZATION_INNEW_MAPLOAD)
		InitializeAtoms()
	old_initialized = SSatoms.old_initialized
	BadInitializeCalls = SSatoms.BadInitializeCalls

/datum/controller/subsystem/atoms/proc/InitLog()
	. = ""
	for(var/path in BadInitializeCalls)
		. += "Path : [path] \n"
		var/fails = BadInitializeCalls[path]
		if(fails & BAD_INIT_DIDNT_INIT)
			. += "- Didn't call atom/Initialize()\n"
		if(fails & BAD_INIT_NO_HINT)
			. += "- Didn't return an Initialize hint\n"
		if(fails & BAD_INIT_QDEL_BEFORE)
			. += "- Qdel'd in New()\n"
		if(fails & BAD_INIT_SLEPT)
			. += "- Slept during Initialize()\n"

/datum/controller/subsystem/atoms/Shutdown()
	var/initlog = InitLog()
	if(initlog)
		text2file(initlog, "data/logs/initialize.log")

/client/proc/cmd_display_init_log()
	set category = "Debug"
	set name = "Display Initialize() Log"
	set desc = "Displays a list of things that didn't handle Initialize() properly."

	if(!LAZYLEN(SSatoms.BadInitializeCalls))
		to_chat(usr, span_notice("BadInit list is empty."))
	else
		usr << browse(HTML_SKELETON(replacetext(SSatoms.InitLog(), "\n", "<br>")), "window=initlog")

/datum/controller/subsystem/atoms/proc/InitCostLog(sort_by_avg = FALSE, show_late_init = FALSE)
	var/list/costs_to_use = show_late_init ? late_init_costs : init_costs
	var/list/counts_to_use = show_late_init ? late_init_counts : init_counts

	if(!LAZYLEN(costs_to_use))
		return "<div class='summary'><h2>No [show_late_init ? "Late " : ""]Initialization Data</h2></div>"

	var/list/cost_tree = list()
	var/total_cost = 0
	var/total_count = 0

	for(var/path in costs_to_use)
		var/cost = costs_to_use[path]
		var/count = counts_to_use[path]
		total_cost += cost
		total_count += count

		var/list/path_parts = splittext("[path]", "/")
		var/list/current_level = cost_tree
		var/built_path = ""

		for(var/i in 1 to path_parts.len)
			var/part = path_parts[i]
			if(!part) continue

			built_path += "[built_path ? "/" : ""][part]"

			if(!current_level[part])
				current_level[part] = list(
					"cost" = 0,
					"count" = 0,
					"direct_cost" = 0,
					"direct_count" = 0,
					"children" = list(),
					"path" = built_path,
					"is_leaf" = (i == path_parts.len)
				)

			if(i == path_parts.len)
				current_level[part]["direct_cost"] = cost
				current_level[part]["direct_count"] = count

			current_level[part]["cost"] += cost
			current_level[part]["count"] += count
			current_level = current_level[part]["children"]

	. = "<style>"
	. += "body { font-family: monospace; background: #1e1e1e; color: #d4d4d4; padding: 20px; }"
	. += ".tree-node { margin-left: 20px; margin-top: 5px; }"
	. += ".tree-item { cursor: pointer; padding: 3px 5px; border-radius: 3px; }"
	. += ".tree-item:hover { background: #2d2d30; }"
	. += ".cost-high { color: #f48771; font-weight: bold; }"
	. += ".cost-med { color: #dcdcaa; }"
	. += ".cost-low { color: #4ec9b0; }"
	. += ".expander { display: inline-block; width: 15px; }"
	. += ".percentage { color: #858585; font-size: 0.9em; }"
	. += ".count { color: #9cdcfe; font-size: 0.9em; }"
	. += ".avg { color: #ce9178; font-size: 0.9em; }"
	. += ".summary { background: #252526; padding: 15px; border-radius: 5px; margin-bottom: 20px; }"
	. += ".controls { background: #252526; padding: 10px; border-radius: 5px; margin-bottom: 15px; }"
	. += "button { background: #0e639c; color: white; border: none; padding: 8px 15px; border-radius: 3px; cursor: pointer; margin-right: 10px; }"
	. += "button:hover { background: #1177bb; }"
	. += "button.active { background: #1177bb; }"
	. += ".tab-group { display: inline-block; margin-right: 20px; }"
	. += "</style>"

	. += "<div class='controls'>"
	. += "<div class='tab-group'>"
	. += "<button class='[show_late_init ? "" : "active"]' onclick='window.location.href=\"?src=[REF(src)];init_costs=1;sort=[sort_by_avg ? "avg" : "total"];mode=init\"'>Initialize()</button>"
	. += "<button class='[show_late_init ? "active" : ""]' onclick='window.location.href=\"?src=[REF(src)];init_costs=1;sort=[sort_by_avg ? "avg" : "total"];mode=late\"'>LateInitialize()</button>"
	. += "</div>"
	. += "<div class='tab-group'>"
	. += "<button class='[sort_by_avg ? "" : "active"]' onclick='window.location.href=\"?src=[REF(src)];init_costs=1;sort=total;mode=[show_late_init ? "late" : "init"]\"'>Sort by Total Time</button>"
	. += "<button class='[sort_by_avg ? "active" : ""]' onclick='window.location.href=\"?src=[REF(src)];init_costs=1;sort=avg;mode=[show_late_init ? "late" : "init"]\"'>Sort by Average Time</button>"
	. += "</div>"
	. += "</div>"

	. += "<div class='summary'>"
	. += "<h2>[show_late_init ? "Late " : ""]Initialization Cost Analysis</h2>"
	. += "<b>Total [show_late_init ? "Late " : ""]Init Time:</b> [total_cost] ds ([round(total_cost / 10, 0.01)]s)<br>"
	. += "<b>Total Instances:</b> [total_count]<br>"
	. += "<b>Total Types:</b> [length(costs_to_use)]<br>"
	. += "<b>Average Cost:</b> [round(total_cost / max(total_count, 1), 0.001)] ds per instance<br>"
	. += "<b>Sorting by:</b> [sort_by_avg ? "Average time per instance" : "Total time"]"
	. += "</div>"

	. += "<script>"
	. += "function toggle(id) {"
	. += "  var elem = document.getElementById(id);"
	. += "  var exp = document.getElementById('exp_' + id);"
	. += "  if(elem.style.display === 'none') {"
	. += "    elem.style.display = 'block';"
	. += "    exp.innerHTML = '▼';"
	. += "  } else {"
	. += "    elem.style.display = 'none';"
	. += "    exp.innerHTML = '▶';"
	. += "  }"
	. += "}"
	. += "</script>"

	. += build_tree_html(cost_tree, total_cost, sort_by_avg)

/datum/controller/subsystem/atoms/proc/build_tree_html(list/tree, total_cost, sort_by_avg = FALSE)
	. = ""
	var/static/node_id = 0

	var/list/sorted_keys = list()
	for(var/key in tree)
		sorted_keys += key

	// she ubble on my sort till she top
	for(var/i in 1 to length(sorted_keys))
		for(var/j in 1 to length(sorted_keys) - 1)
			var/key1 = sorted_keys[j]
			var/key2 = sorted_keys[j + 1]
			var/val1 = sort_by_avg ? (tree[key1]["cost"] / max(tree[key1]["count"], 1)) : tree[key1]["cost"]
			var/val2 = sort_by_avg ? (tree[key2]["cost"] / max(tree[key2]["count"], 1)) : tree[key2]["cost"]
			if(val1 < val2)
				sorted_keys[j] = key2
				sorted_keys[j + 1] = key1

	for(var/key in sorted_keys)
		var/list/node = tree[key]
		var/cost = node["cost"]
		var/count = node["count"]
		var/direct_cost = node["direct_cost"]
		var/direct_count = node["direct_count"]
		var/avg_cost = round(cost / max(count, 1), 0.001)
		var/percentage = round((cost / total_cost) * 100, 0.01)

		node_id++
		var/current_id = "node[node_id]"

		var/cost_class = "cost-low"
		if(percentage >= 10)
			cost_class = "cost-high"
		else if(percentage >= 1)
			cost_class = "cost-med"

		var/has_children = length(node["children"]) > 0
		var/expander = has_children ? "<span class='expander' id='exp_[current_id]' onclick='toggle(\"[current_id]\")'>▼</span>" : "<span class='expander'>&nbsp;</span>"

		. += "<div class='tree-item'>"
		. += "[expander] <span class='[cost_class]'>[key]</span> "
		. += "- <b>[cost]ds</b> "
		. += "<span class='count'>([count]x)</span> "
		. += "<span class='avg'>[avg_cost]ds avg</span> "
		if(direct_cost > 0 && has_children)
			var/direct_avg = round(direct_cost / max(direct_count, 1), 0.001)
			. += "(direct: [direct_cost]ds, [direct_count]x, [direct_avg]ds avg) "
		. += "<span class='percentage'>([percentage]%)</span>"
		. += "</div>"

		if(has_children)
			. += "<div id='[current_id]' class='tree-node'>"
			. += build_tree_html(node["children"], total_cost, sort_by_avg)
			. += "</div>"

/client/proc/cmd_display_init_costs()
	set category = "Debug"
	set name = "Display Init Costs"
	set desc = "Displays initialization costs in a tree format."

	if(!LAZYLEN(SSatoms.init_costs))
		to_chat(usr, span_notice("Init costs list is empty."))
	else
		usr << browse(HTML_SKELETON(SSatoms.InitCostLog()), "window=initcosts;size=900x600")

/datum/controller/subsystem/atoms/Topic(href, href_list)
	. = ..()
	if(href_list["init_costs"])
		var/sort_by_avg = (href_list["sort"] == "avg")
		var/show_late_init = (href_list["mode"] == "late")
		usr << browse(HTML_SKELETON(InitCostLog(sort_by_avg, show_late_init)), "window=initcosts;size=900x600")
