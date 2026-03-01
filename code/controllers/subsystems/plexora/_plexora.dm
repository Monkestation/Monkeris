#define AUTH_HEADER ("Basic " + CONFIG_GET(string/comms_key))
#define OLD_PLEXORA_CONFIG "config/plexora.json"

/**
 * # Plexora Subsystem
 *
 * This subsystem is for the Plexora Discord bot bridge.
 *
 * The repo for this can be found at https://github.com/monkestation/plexora
 *
 * The distinction between Plexora (the bot) and Plexora (the subsystem)
 * will be plexora (the bot) and SSplexora (the subsystem)
 *
 * NOTES:
 * * SSplexora makes heavy use of topics, and rust_g HTTP requests
 * * Lets hope to god plexora is configured properly and DOESNT CRASh,
 *	 -because i seriously do not want to put error catchers in
 *	 -EVERY FUNCTION THAT MAKES AN HTTP REQUEST
 */


SUBSYSTEM_DEF(plexora)
	name = "Plexora"
	wait = 30 SECONDS
	init_order = INIT_ORDER_PLEXORA
	priority = FIRE_PRIORITY_PLEXORA
	runlevels = ALL

#ifdef UNIT_TESTS
	flags = SS_NO_INIT | SS_NO_FIRE
#endif

	var/plexora_is_alive = null // this gets set to TRUE or FALSE during is_plexora_alive, it's just initially null to so logging works properly without spamming
	var/vanderlin_available = FALSE
	var/base_url = ""
	var/enabled = TRUE
	var/tripped_bad_version = FALSE
	var/list/default_headers

	var/restart_type = PLEXORA_SHUTDOWN_NORMAL
	var/mob/restart_requester
	/// People who have tried to verify this round already
	var/list/reverify_cache = list()
	var/list/allowed_ckeys = list()


/datum/controller/subsystem/plexora/Initialize()
	if(!CONFIG_GET(string/plexora_url) && !load_old_plexora_config())
		enabled = FALSE
		flags |= SS_NO_FIRE
		return ..()

	var/comms_key = CONFIG_GET(string/comms_key)
	if (!comms_key)
		stack_trace("SSplexora is enabled BUT there is no configured comms key! Please make sure to set one and update Plexora's server config.")
		enabled = FALSE
		flags |= SS_NO_FIRE
		return FALSE

	base_url = CONFIG_GET(string/plexora_url)

	default_headers = list(
		"Content-Type" = "application/json",
		"Authorization" = AUTH_HEADER,
	)

	// Do a ping test to check if Plexora is actually running
	if (!is_plexora_alive())
		stack_trace("SSplexora is enabled BUT plexora is not alive or running! SS has not been aborted, subsequent fires will take place.")
	else
		serverstarted()

	RegisterSignal(SSticker, COMSIG_TICKER_ROUND_STARTING, PROC_REF(roundstarted))

	return ..()

/datum/controller/subsystem/plexora/Recover()
	flags |= SS_NO_INIT // Make extra sure we don't initialize twice.
	initialized = SSplexora.initialized
	plexora_is_alive = SSplexora.plexora_is_alive
	base_url = SSplexora.base_url
	enabled = SSplexora.enabled
	tripped_bad_version = SSplexora.tripped_bad_version
	default_headers = SSplexora.default_headers
	if(initialized && !enabled)
		flags |= SS_NO_FIRE

// compat thing so that it'll load plexora.json if it's still used
/datum/controller/subsystem/plexora/proc/load_old_plexora_config()
	if(!rustg_file_exists(OLD_PLEXORA_CONFIG))
		return FALSE
	var/list/old_config = json_decode(rustg_file_read(OLD_PLEXORA_CONFIG))
	if(!old_config["enabled"])
		return FALSE
	stack_trace("Falling back to [OLD_PLEXORA_CONFIG], you should really migrate to the PLEXORA_URL config entry!")
	CONFIG_SET(string/plexora_url, "http://[old_config["ip"]]:[old_config["port"]]")
	return TRUE

/datum/controller/subsystem/plexora/proc/is_plexora_alive()
	. = FALSE
	if(!enabled) return

	var/datum/http_request/request = new(RUSTG_HTTP_METHOD_GET, "[base_url]/alive")
	request.begin_async()
	UNTIL_OR_TIMEOUT(request.is_complete(), 10 SECONDS)
	var/datum/http_response/response = request.into_response()
	if (response.errored)
		// avoid spamming logs
		if (isnull(plexora_is_alive) || plexora_is_alive)
			plexora_is_alive = FALSE
			log_admin("Failed to check if Plexora is alive! She probably isn't. Check config on both sides")
			CRASH("Failed to check if Plexora is alive! She probably isn't. Check config on both sides")
	else
		plexora_is_alive = TRUE
		return TRUE

/datum/controller/subsystem/plexora/fire()
	if(!is_plexora_alive()) return
	// Send current status to Plexora
	var/datum/world_topic/status/status_handler = new()
	var/list/status = status_handler.Run()

	var/datum/http_request/status_request = http_request(
		RUSTG_HTTP_METHOD_POST,
		"[base_url]/status",
		json_encode(status),
		default_headers
	)
	status_request.fire_and_forget()


#undef OLD_PLEXORA_CONFIG
#undef AUTH_HEADER
