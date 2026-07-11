PROCESSING_SUBSYSTEM_DEF(mobs)
	name = "Mobs"
	priority = FIRE_PRIORITY_MOB
	flags = SS_KEEP_TIMING|SS_NO_INIT
	runlevels = RUNLEVEL_GAME|RUNLEVEL_POSTGAME
	wait = 2 SECONDS

	process_proc = TYPE_PROC_REF(/mob, Life)

	var/list/mob_list
	var/list/mob_living_by_zlevel[][]
	///used by ambushcode to keep track of which mobs are currently involved in ambushes
	var/list/ambushed_mobs

/datum/controller/subsystem/processing/mobs/PreInit()
	mob_list = processing // Simply setups a more recognizable var name than "processing"
	ambushed_mobs = new()
	MaxZChanged()

/datum/controller/subsystem/processing/mobs/proc/MaxZChanged()
	if(!islist(mob_living_by_zlevel))
		mob_living_by_zlevel = new/list(world.maxz, 0)

	while(mob_living_by_zlevel.len < world.maxz)
		mob_living_by_zlevel.len++
		mob_living_by_zlevel[mob_living_by_zlevel.len] = list()
