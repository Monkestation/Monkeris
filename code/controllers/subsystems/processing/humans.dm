PROCESSING_SUBSYSTEM_DEF(humans)
	name = "Humans"
	priority = FIRE_PRIORITY_HUMAN
	flags = SS_KEEP_TIMING|SS_NO_INIT
	runlevels = RUNLEVEL_GAME|RUNLEVEL_POSTGAME
	wait = 2 SECONDS

	process_proc = TYPE_PROC_REF(/mob, Life)

	var/list/mob_list

/datum/controller/subsystem/processing/humans/PreInit()
	mob_list = processing // Simply setups a more recognizable var name than "processing"
