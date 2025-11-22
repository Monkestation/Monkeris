SUBSYSTEM_DEF(pollution)
	name = "Pollution"
	init_order = INIT_ORDER_AIR //Before atoms, because the emitters may need to know the singletons
	flags = SS_BACKGROUND
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME
	wait = 2 SECONDS
	/// Currently active pollution
	var/list/active_pollution = list()
	/// All pollution in the world
	var/list/all_polution = list()
	/// Currently processed batch of pollutants
	var/list/current_run = list()
	/// Already processed pollutants in cell process
	var/list/processed_this_run = list()
	/// Ticker for dissipation task
	var/dissapation_ticker = 0
	/// What's the current task we're doing
	var/pollution_task = POLLUTION_TASK_PROCESS
	/// Associative list of types of pollutants to their instanced singletons
	var/list/singletons = list()

/datum/controller/subsystem/pollution/stat_entry(msg)
	msg += "|AT:[active_pollution.len]|P:[all_polution.len]"
	return ..()

/datum/controller/subsystem/pollution/Initialize()
	//Initialize singletons
	for(var/type in subtypesof(/datum/pollutant))
		var/datum/pollutant/pollutant_cast = type
		if(!length(pollutant_cast::name))
			continue
		singletons[type] = new type()
	return ..()

/datum/controller/subsystem/pollution/fire(resumed = FALSE)
	var/list/current_run_cache = current_run
	if(pollution_task == POLLUTION_TASK_PROCESS)
		if(!current_run_cache.len)
			current_run_cache = active_pollution.Copy()
			processed_this_run.Cut()
		while(current_run_cache.len)
			var/datum/pollution/pollution = current_run_cache[current_run_cache.len]
			current_run_cache.len--
			processed_this_run[pollution] = TRUE
			pollution.process_cell()
			if(TICK_CHECK)
				return
		dissapation_ticker++
		if(dissapation_ticker >= TICKS_TO_DISSIPATE)
			pollution_task = POLLUTION_TASK_DISSIPATE
			dissapation_ticker = 0
			current_run_cache = all_polution.Copy()
	if(pollution_task == POLLUTION_TASK_DISSIPATE)
		while(current_run_cache.len)
			var/datum/pollution/pollution = current_run_cache[current_run_cache.len]
			current_run_cache.len--
			pollution.scrub_amount(POLLUTION_HEIGHT_DIVISOR, FALSE, TRUE)
			if(TICK_CHECK)
				return
		pollution_task = POLLUTION_TASK_PROCESS


/client/proc/spawn_pollution()
	set category = "Debug"
	set name = "Spawn Pollution"
	set desc = "Spawns an amount of chosen pollutant at your current location."

	var/list/singleton_list = SSpollution.singletons
	var/choice = input(usr, "What type of pollutant would you like to spawn?", "Spawn Pollution") as null|anything in singleton_list
	if(!choice)
		return
	var/amount_choice = input(usr, "Amount of pollution", "Spawn Pollution") as num|null
	if(!amount_choice)
		return
	var/turf/epicenter = get_turf(mob)
	epicenter.pollute_turf(choice, amount_choice)
	message_admins("[ADMIN_LOOKUPFLW(usr)] spawned pollution at [epicenter.loc] ([choice] - [amount_choice]).")
	log_admin("[key_name(usr)] spawned pollution at [epicenter.loc] ([choice] - [amount_choice]).")
