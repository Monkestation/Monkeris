#define TICK_USAGE world.tick_usage //for general usage
#define TICK_USAGE_REAL world.tick_usage    //to be used where the result isn't checked
#define MAPTICK_LAST_INTERNAL_TICK_USAGE (world.map_cpu)

#define TICK_CHECK ( TICK_USAGE > Master.current_ticklimit )
#define CHECK_TICK ( TICK_CHECK ? stoplag() : 0 )

#define TICKS_IN_DAY 		24*60*60*10
#define TICKS_IN_SECOND 	10

//"fancy" math for calculating time in ms from tick_usage percentage and the length of ticks
//percent_of_tick_used * (ticklag * 100(to convert to ms)) / 100(percent ratio)
//collapsed to percent_of_tick_used * tick_lag
#define TICK_DELTA_TO_MS(percent_of_tick_used) ((percent_of_tick_used) * world.tick_lag)
#define TICK_USAGE_TO_MS(starting_tickusage) (TICK_DELTA_TO_MS(TICK_USAGE_REAL - starting_tickusage))


/// Percentage of tick to leave for master controller to run
#define MAPTICK_MC_MIN_RESERVE 70
// Tick limit while running normally
// #define TICK_LIMIT_RUNNING 85
#define TICK_BYOND_RESERVE 2
#define TICK_LIMIT_RUNNING (max(100 - TICK_BYOND_RESERVE - MAPTICK_LAST_INTERNAL_TICK_USAGE, MAPTICK_MC_MIN_RESERVE))
/// Tick limit used to resume things in stoplag
#define TICK_LIMIT_TO_RUN 70
/// Tick limit for MC while running
#define TICK_LIMIT_MC 70

/// runs stoplag if tick_usage is above the limit
#define CHECK_TICK_LOW ( TICK_CHECK_LOW ? stoplag() : 0 )
///like TICK_CHECK but for half the budget
#define TICK_CHECK_LOW ( TICK_USAGE > (Master.current_ticklimit * 0.5))

/// Returns true if tick usage is above 95, for high priority usage
#define TICK_CHECK_HIGH_PRIORITY ( TICK_USAGE > 95 )
/// runs stoplag if tick_usage is above 95, for high priority usage
#define CHECK_TICK_HIGH_PRIORITY ( TICK_CHECK_HIGH_PRIORITY? stoplag() : 0 )

/// Checks if a sleeping proc is running before or after the master controller
#define RUNNING_BEFORE_MASTER ( Master.last_run != null && Master.last_run != world.time )
/// Returns true if a verb ought to yield to the MC (IE: queue up to be processed by a subsystem)
#define VERB_SHOULD_YIELD ( TICK_CHECK || RUNNING_BEFORE_MASTER )
