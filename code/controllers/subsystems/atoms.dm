#define INIT_TRACK

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


/datum/controller/subsystem/atoms/proc/BuildCostLogHtml()
	var/list/init_data = list()
	for(var/path in init_costs)
		init_data[path] = list(
			"cost" = init_costs[path],
			"count" = init_counts[path]
		)

	var/list/late_data = list()
	for(var/path in late_init_costs)
		late_data[path] = list(
			"cost" = late_init_costs[path],
			"count" = late_init_counts[path]
		)

	var/list/payload = list(
		"init" = init_data,
		"late" = late_data
	)

	var/json_payload = json_encode(payload)

	. = {"
<style>
body { font-family: monospace; background: #1e1e1e; color: #d4d4d4; padding: 20px; }
.tree-node { margin-left: 20px; margin-top: 5px; }
.tree-item { cursor: pointer; padding: 3px 5px; border-radius: 3px; }
.tree-item:hover { background: #2d2d30; }
.cost-high { color: #f48771; font-weight: bold; }
.cost-med { color: #dcdcaa; }
.cost-low { color: #4ec9b0; }
.expander { display: inline-block; width: 15px; }
.percentage { color: #858585; font-size: 0.9em; }
.count { color: #9cdcfe; font-size: 0.9em; }
.avg { color: #ce9178; font-size: 0.9em; }
.summary { background: #252526; padding: 15px; border-radius: 5px; margin-bottom: 20px; }
.controls { background: #252526; padding: 10px; border-radius: 5px; margin-bottom: 15px; }
button { background: #0e639c; color: white; border: none; padding: 8px 15px; border-radius: 3px; cursor: pointer; margin-right: 10px; }
button:hover { background: #1177bb; }
button.active { background: #1177bb; }
.tab-group { display: inline-block; margin-right: 20px; }
</style>

<div class='controls'>
<div class='tab-group'>
<button id='btn_init' class='active' onclick='setMode(\"init\")'>Initialize()</button>
<button id='btn_late' onclick='setMode(\"late\")'>LateInitialize()</button>
</div>
<div class='tab-group'>
<button id='btn_total' class='active' onclick='setSort(\"total\")'>Sort by Total Time</button>
<button id='btn_avg' onclick='setSort(\"avg\")'>Sort by Average Time</button>
</div>
</div>

<div id='summary' class='summary'></div>
<div id='tree_root'></div>

<script>
window.DATA = [json_payload];
</script>
<script>
let MODE = 'init'; // 'init' or 'late'
let SORT = 'total'; // 'total' or 'avg'

function buildTree(flat) {
  const root = {};
  for(const path in flat) {
    const entry = flat\[path\];
    const parts = path.split('/').filter(Boolean);
    let node = root;
    let built = '';
    for(let i=0;i<parts.length;i++) {
      const part = parts\[i\];
      built += (built ? '/' : '') + part;
      if(!node\[part\]) {
        node\[part\] = { cost: 0, count: 0, direct_cost: 0, direct_count: 0, children: {}, path: built, is_leaf: i === parts.length - 1 };
      }
      if(i === parts.length - 1) {
        node\[part\].direct_cost = entry.cost || 0;
        node\[part\].direct_count = entry.count || 0;
      }
      node\[part\].cost += entry.cost || 0;
      node\[part\].count += entry.count || 0;
      node = node\[part\].children;
    }
  }
  return root;
}

function formatNumber(n) { return Math.round(n * 1000) / 1000; }
function clearChildren(el) { while(el.firstChild) el.removeChild(el.firstChild); }

function sortedKeys(tree, sortByAvg, totalCost) {
  const keys = Object.keys(tree);
  keys.sort((a,b)=>{
    const n1 = tree\[a\], n2 = tree\[b\];
    const v1 = sortByAvg ? (n1.cost / Math.max(n1.count,1)) : n1.cost;
    const v2 = sortByAvg ? (n2.cost / Math.max(n2.count,1)) : n2.cost;
    return v2 - v1; // descending
  });
  return keys;
}

let idCounter = 0;
function renderTree(tree, container, totalCost, sortByAvg) {
  const keys = sortedKeys(tree, sortByAvg, totalCost);
  for(const key of keys) {
    const node = tree\[key\];
    const cost = node.cost;
    const count = node.count;
    const direct_cost = node.direct_cost;
    const direct_count = node.direct_count;
    const avg_cost = formatNumber(cost / Math.max(count,1));
    const percentage = totalCost > 0 ? formatNumber((cost / totalCost) * 100) : 0;
    idCounter++;
    const myId = 'node' + idCounter;
    const hasChildren = Object.keys(node.children).length > 0;
    let costClass = 'cost-low';
    if(percentage >= 10) costClass = 'cost-high';
    else if(percentage >= 1) costClass = 'cost-med';

    const item = document.createElement('div');
    item.className = 'tree-item';

    const exp = document.createElement('span');
    exp.className = 'expander';
    exp.id = 'exp_' + myId;
    exp.textContent = hasChildren ? '▼' : '\\u00A0';
    if(hasChildren) exp.style.cursor = 'pointer';
    item.appendChild(exp);

    const nameSpan = document.createElement('span');
    nameSpan.className = costClass;
    nameSpan.textContent = key;
    item.appendChild(nameSpan);

    const info = document.createElement('span');
    info.innerHTML = ' - <b>' + cost + 'ds</b> <span class=\"count\">(' + count + 'x)</span> <span class=\"avg\">' + avg_cost + 'ds avg</span>';
    if(direct_cost > 0 && hasChildren) {
      const directAvg = formatNumber(direct_cost / Math.max(direct_count,1));
      info.innerHTML += ' (direct: ' + direct_cost + 'ds, ' + direct_count + 'x, ' + directAvg + 'ds avg) ';
    }
    info.innerHTML += ' <span class=\"percentage\">(' + percentage + '%)</span>';
    item.appendChild(info);

    container.appendChild(item);

    if(hasChildren) {
      const childContainer = document.createElement('div');
      childContainer.className = 'tree-node';
      childContainer.id = myId;
      container.appendChild(childContainer);
      // by default children are visible; toggle handler
      exp.addEventListener('click', ()=>{
        if(childContainer.style.display === 'none') { childContainer.style.display = 'block'; exp.textContent = '▼'; }
        else { childContainer.style.display = 'none'; exp.textContent = '▶'; }
      });
      renderTree(node.children, childContainer, totalCost, sortByAvg);
    }
  }
}

function renderAll() {
  const flat = (MODE === 'init') ? DATA.init : DATA.late;
  const tree = buildTree(flat);
  // compute totals
  let totalCost = 0, totalCount = 0, types = 0;
  for(const k in flat) { totalCost += (flat\[k\].cost || 0); totalCount += (flat\[k\].count || 0); types++; }

  const summary = document.getElementById('summary');
  summary.innerHTML = '<h2>' + (MODE === 'late' ? 'Late ' : '') + 'Initialization Cost Analysis</h2>' +
    '<b>Total ' + (MODE === 'late' ? 'Late ' : '') + 'Init Time:</b> ' + totalCost + ' ds (' + (formatNumber(totalCost/10)) + 's)<br>' +
    '<b>Total Instances:</b> ' + totalCount + '<br>' +
    '<b>Total Types:</b> ' + types + '<br>' +
    '<b>Average Cost:</b> ' + (formatNumber(totalCost / Math.max(totalCount,1))) + ' ds per instance<br>' +
    '<b>Sorting by:</b> ' + (SORT === 'avg' ? 'Average time per instance' : 'Total time');

  const root = document.getElementById('tree_root');
  clearChildren(root);
  idCounter = 0;
  renderTree(tree, root, totalCost, SORT === 'avg');
  // update buttons classes
  document.getElementById('btn_init').className = (MODE === 'init') ? 'active' : '';
  document.getElementById('btn_late').className = (MODE === 'late') ? 'active' : '';
  document.getElementById('btn_total').className = (SORT === 'total') ? 'active' : '';
  document.getElementById('btn_avg').className = (SORT === 'avg') ? 'active' : '';
}

function setMode(m) { if(MODE === m) return; MODE = m; renderAll(); }
function setSort(s) { if(SORT === s) return; SORT = s; renderAll(); }

renderAll();
</script>
"}


/client/proc/cmd_display_init_costs()
	set category = "Debug"
	set name = "Display Init Costs"
	set desc = "Displays initialization costs in a tree format."

	if(!LAZYLEN(SSatoms.init_costs))
		to_chat(usr, span_notice("Init costs list is empty."))
	if(alert(usr, "Are you sure you want to view the initialization costs? This may take more than a minute to load.", "Confirm", "Yes", "No") != "Yes")
		return
	else
		usr << browse(HTML_SKELETON(SSatoms.BuildCostLogHtml()), "window=initcosts;size=900x600")
