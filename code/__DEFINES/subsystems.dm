//! Defines for subsystems and overlays
//!
//! Lots of important stuff in here, make sure you have your brain switched on
//! when editing this file
// "My brain was never on to begin with. what makes you think I'll turn it on now?"

//! ## DB defines
/**
 * DB major schema version
 *
 * Update this whenever the db schema changes
 *
 * make sure you add an update to the schema_version stable in the db changelog
 */
#define DB_MAJOR_VERSION 3

/**
 * DB minor schema version
 *
 * Update this whenever the db schema changes
 *
 * make sure you add an update to the schema_version stable in the db changelog
 */
#define DB_MINOR_VERSION 4


//! ## Timing subsystem
/**
 * Don't run if there is an identical unique timer active
 *
 * if the arguments to addtimer are the same as an existing timer, it doesn't create a new timer,
 * and returns the id of the existing timer
 */
#define TIMER_UNIQUE (1<<0)

///For unique timers: Replace the old timer rather then not start this one
#define TIMER_OVERRIDE (1<<1)

/**
 * Timing should be based on how timing progresses on clients, not the server.
 *
 * Tracking this is more expensive,
 * should only be used in conjuction with things that have to progress client side, such as
 * animate() or sound()
 */
#define TIMER_CLIENT_TIME (1<<2)

///Timer can be stopped using deltimer()
#define TIMER_STOPPABLE (1<<3)

///prevents distinguishing identical timers with the wait variable
///
///To be used with TIMER_UNIQUE
#define TIMER_NO_HASH_WAIT (1<<4)

///Loops the timer repeatedly until qdeleted
///
///In most cases you want a subsystem instead, so don't use this unless you have a good reason
#define TIMER_LOOP (1<<5)

///Delete the timer on parent datum Destroy() and when deltimer'd
#define TIMER_DELETE_ME (1<<6)

///Empty ID define
#define TIMER_ID_NULL -1

//For servers that can't do with any additional lag, set this to none in flightpacks.dm in subsystem/processing.
#define FLIGHTSUIT_PROCESSING_NONE 0
#define FLIGHTSUIT_PROCESSING_FULL 1

/// Used to trigger object removal from a processing list
#define PROCESS_KILL 26

//! ## Initialization subsystem

///New should not call Initialize
#define INITIALIZATION_INSSATOMS 0
///New should call Initialize(TRUE)
#define INITIALIZATION_INNEW_MAPLOAD 2
///New should call Initialize(FALSE)
#define INITIALIZATION_INNEW_REGULAR 1

//! ### Initialization hints

///Nothing happens
#define INITIALIZE_HINT_NORMAL 0
/**
 * call LateInitialize at the end of all atom Initalization
 *
 * The item will be added to the late_loaders list, this is iterated over after
 * initalization of subsystems is complete and calls LateInitalize on the atom
 * see [this file for the LateIntialize proc](atom.html#proc/LateInitialize)
 */
#define INITIALIZE_HINT_LATELOAD 1

///Call qdel on the atom after intialization
#define INITIALIZE_HINT_QDEL 2

///Call qdel with a force of TRUE after initialization
#define INITIALIZE_HINT_QDEL_FORCE 3

//TODO: initialized and other stuff needs to be changed to `flags_1`
///type and all subtypes should always immediately call Initialize in New()
#define INITIALIZE_IMMEDIATE(X) ##X/New(loc, ...){\
	..();\
	if(!initialized) {\
		var/previous_initialized_value = SSatoms.initialized;\
		SSatoms.initialized = INITIALIZATION_INNEW_MAPLOAD;\
		args[1] = TRUE;\
		SSatoms.InitAtom(src, FALSE, args);\
		SSatoms.initialized = previous_initialized_value;\
	}\
}

//! ### SS initialization hints
/**
 * Negative values incidate a failure or warning of some kind, positive are good.
 * 0 and 1 are unused so that TRUE and FALSE are guarenteed to be invalid values.
 */

/// Subsystem failed to initialize entirely. Print a warning, log, and disable firing.
#define SS_INIT_FAILURE -2

/// The default return value which must be overriden. Will succeed with a warning.
#define SS_INIT_NONE -1

/// Subsystem initialized sucessfully.
#define SS_INIT_SUCCESS 2

/// Successful, but don't print anything. Useful if subsystem was disabled.
#define SS_INIT_NO_NEED 3

//! ### SS initialization load orders
// Subsystem init_order, from highest priority to lowest priority
// Subsystems shutdown in the reverse of the order they initialize in
// The numbers just define the ordering, they are meaningless otherwise.

#define INIT_ORDER_PROFILER 101
#define INIT_ORDER_GARBAGE 99
#define INIT_ORDER_CHUNKS 95
#define INIT_ORDER_DBCORE 85
#define INIT_ORDER_SERVER_MAINT 83
#define INIT_ORDER_PLEXORA 82
#define INIT_ORDER_EXPLOSIONS 80
#define INIT_ORDER_STATPANELS 70
#define INIT_ORDER_SKYBOX 40
#define INIT_ORDER_BLACKBOX 36
#define INIT_ORDER_EVENTS 30
#define INIT_ORDER_TICKER 28
#define INIT_ORDER_REAGENTS 27
#define INIT_ORDER_PLANTS 26
#define INIT_ORDER_SPAWN_DATA 25
#define INIT_ORDER_INVENTORY 24
#define INIT_ORDER_MAPPING 23
#define INIT_ORDER_ATOMS 22
#define INIT_ORDER_LANGUAGE 20
#define INIT_ORDER_JOBS 16
#define INIT_ORDER_CHAR_SETUP 14
#define INIT_ORDER_MACHINES 7
#define INIT_ORDER_TIMER 1
#define INIT_ORDER_DEFAULT 0
#define INIT_ORDER_AIR -1
#define INIT_ORDER_ALARM -2
#define INIT_ORDER_MINIMAP -3
#define INIT_ORDER_HOLOMAPS -4
#define INIT_ORDER_CRAFT -5 // DO NOT INIT THIS AFTER ASSETS
#define INIT_ORDER_CWJ -6
#define INIT_ORDER_ASSETS -7
#define INIT_ORDER_ICON_SMOOTHING -8
#define INIT_ORDER_OVERLAY -9
#define INIT_ORDER_XKEYSCORE -10
#define INIT_ORDER_TICKETS -12
#define INIT_ORDER_LIGHTING -20
#define INIT_ORDER_SHUTTLE -21
#define INIT_ORDER_JAMMING -22
#define INIT_OPEN_SPACE -150
#define INIT_ORDER_LATELOAD -180
#define INIT_ORDER_BAN_CACHE -181
#define INIT_ORDER_CHAT	-185


// SS runlevels

#define RUNLEVEL_INIT 0
#define RUNLEVEL_LOBBY 1
#define RUNLEVEL_SETUP 2
#define RUNLEVEL_GAME 4
#define RUNLEVEL_POSTGAME 8

#define RUNLEVELS_DEFAULT (RUNLEVEL_SETUP | RUNLEVEL_GAME | RUNLEVEL_POSTGAME)

#define START_PROCESSING_IN_LIST(Datum, List) \
if (Datum.is_processing) {\
	if(Datum.is_processing != "SSmachines.[#List]")\
	{\
		CRASH("Failed to start processing. [log_info_line(Datum)] is already being processed by [Datum.is_processing] but queue attempt occured on SSmachines.[#List]."); \
	}\
} else {\
	Datum.is_processing = "SSmachines.[#List]";\
	SSmachines.List += Datum;\
}

#define STOP_PROCESSING_IN_LIST(Datum, List) \
if(Datum.is_processing) {\
	if(SSmachines.List.Remove(Datum)) {\
		Datum.is_processing = null;\
	} else {\
		CRASH("Failed to stop processing. [log_info_line(Datum)] is being processed by [is_processing] and not found in SSmachines.[#List]"); \
	}\
}

#define START_PROCESSING_PIPENET(Datum) START_PROCESSING_IN_LIST(Datum, pipenets)
#define STOP_PROCESSING_PIPENET(Datum) STOP_PROCESSING_IN_LIST(Datum, pipenets)

#define START_PROCESSING_POWERNET(Datum) START_PROCESSING_IN_LIST(Datum, powernets)
#define STOP_PROCESSING_POWERNET(Datum) STOP_PROCESSING_IN_LIST(Datum, powernets)

#define START_PROCESSING_POWER_OBJECT(Datum) START_PROCESSING_IN_LIST(Datum, power_objects)
#define STOP_PROCESSING_POWER_OBJECT(Datum) STOP_PROCESSING_IN_LIST(Datum, power_objects)

#define SS_HOLOMAPS_TIMER_KEY "ss_holomaps"

//Hibernation states
#define SS_NOT_HIBERNATING 0
#define SS_WAKING_UP 1
#define SS_IS_HIBERNATING 2

//SSticker.current_state values
/// Game is loading
#define GAME_STATE_STARTUP 0
/// Game is loaded and in pregame lobby
#define GAME_STATE_PREGAME 1
/// Game is attempting to start the round
#define GAME_STATE_SETTING_UP 2
/// Game has round in progress
#define GAME_STATE_PLAYING 3
/// Game has round finished
#define GAME_STATE_FINISHED 4

// Used for SSticker.force_ending
/// Default, round is not being forced to end.
#define END_ROUND_AS_NORMAL 0
/// End the round now as normal
#define FORCE_END_ROUND 1
/// For admin forcing roundend, can be used to distinguish the two
#define ADMIN_FORCE_END_ROUND 2

/**
	Create a new timer and add it to the queue.
	* Arguments:
	* * callback the callback to call on timer finish
	* * wait deciseconds to run the timer for
	* * flags flags for this timer, see: code\__DEFINES\subsystems.dm
	* * timer_subsystem the subsystem to insert this timer into
*/
#define addtimer(args...) _addtimer(args, file = __FILE__, line = __LINE__)

// Air subsystem subtasks
#define SSAIR_PIPENETS         1
#define SSAIR_ATMOSMACHINERY   2
#define SSAIR_TILES_CUR        3
#define SSAIR_TILES_DEF        4
#define SSAIR_EDGES            5
#define SSAIR_FIRE_ZONES       6
#define SSAIR_HOTSPOTS         7
#define SSAIR_ZONES            8

#define SSAIR_TICK_MULTIPLIER 2


// Subsystem delta times or tickrates, in seconds. I.e, how many seconds in between each process() call for objects being processed by that subsystem.
// Only use these defines if you want to access some other objects processing seconds_per_tick, otherwise use the seconds_per_tick that is sent as a parameter to process()
// #define SSFLUIDS_DT (SSplumbing.wait/10)
#define SSMACHINES_DT (SSmachines.wait/10)
#define SSMOBS_DT (SSmobs.wait/10)
#define SSOBJ_DT (SSobj.wait/10)

/// The change in the world's time from the subsystem's last fire in seconds.
#define DELTA_WORLD_TIME(ss) ((world.time - ss.last_fire) * 0.1)

/// Same as DELTA_WORLD_TIME but we ignore time spent hibernating
#define DELTA_WORLD_TIME_WITHOUT_HIBERNATION(ss) ss.hibernation_state ? ss.wait : DELTA_WORLD_TIME(ss)

/// The timer key used to know how long subsystem initialization takes
#define SS_INIT_TIMER_KEY "ss_init"
