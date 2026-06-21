GLOBAL_REAL(config, /datum/controller/configuration)

GLOBAL_DATUM_INIT(revdata,/datum/getrev, new)
GLOBAL_DATUM_INIT(db_search, /datum/DB_search, new)
GLOBAL_DATUM_INIT(universe, /datum/universal_state, new)
GLOBAL_DATUM_INIT(data_core, /datum/datacore, new)

GLOBAL_VAR(host)
GLOBAL_VAR_INIT(changelog_hash, "")
GLOBAL_VAR_INIT(hub_visibility, FALSE)

GLOBAL_VAR_INIT(ooc_allowed, TRUE) // used with admin verbs to disable ooc - not a config option apparently
GLOBAL_VAR_INIT(looc_allowed, TRUE)
GLOBAL_VAR_INIT(dooc_allowed, TRUE)
GLOBAL_VAR_INIT(dsay_allowed, TRUE)
GLOBAL_VAR_INIT(enter_allowed, TRUE)
GLOBAL_VAR_INIT(master_storyteller, "shitgenerator")
GLOBAL_VAR_INIT(gravity_is_on, 1)
// Bomb cap!
GLOBAL_VAR_INIT(max_explosion_range, 14)
GLOBAL_VAR_INIT(diagonal_movement, FALSE)

GLOBAL_VAR(href_logfile)
GLOBAL_VAR(custom_event_msg)

// Reference list for disposal sort junctions. Filled up by sorting junction's New()
GLOBAL_LIST_EMPTY(tagger_locations)
GLOBAL_LIST_EMPTY(admin_log)

