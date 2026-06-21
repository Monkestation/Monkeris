GLOBAL_DATUM_INIT(atmosphere_alarm, /datum/alarm_handler/atmosphere, new)
GLOBAL_DATUM_INIT(camera_alarm, /datum/alarm_handler/camera, new)
GLOBAL_DATUM_INIT(fire_alarm, /datum/alarm_handler/fire, new)
GLOBAL_DATUM_INIT(motion_alarm, /datum/alarm_handler/motion, new)
GLOBAL_DATUM_INIT(power_alarm, /datum/alarm_handler/power, new)

SUBSYSTEM_DEF(alarm)
	name = "Alarm"
	wait = 2 SECONDS
	priority = FIRE_PRIORITY_ALARM
	init_order = INIT_ORDER_ALARM

	init_time_threshold = 1 SECONDS
	var/list/datum/alarm/all_handlers
	var/tmp/list/current = list()
	var/tmp/list/active_alarm_cache = list()

/datum/controller/subsystem/alarm/Initialize(start_timeofday)
	all_handlers = list(
		GLOB.atmosphere_alarm, \
		GLOB.camera_alarm, \
		GLOB.fire_alarm, \
		GLOB.motion_alarm, \
		GLOB.power_alarm)
	return ..()

/datum/controller/subsystem/alarm/fire(resumed = FALSE)
	if (!resumed)
		current = all_handlers.Copy()
		active_alarm_cache.Cut()

	while (current.len)
		var/datum/alarm_handler/AH = current[current.len]
		current.len--

		AH.Process()
		active_alarm_cache += AH.alarms

		if (MC_TICK_CHECK)
			return

/datum/controller/subsystem/alarm/stat_entry(msg)
	msg += "[LAZYLEN(active_alarm_cache)] alarm\s"
	return ..()
