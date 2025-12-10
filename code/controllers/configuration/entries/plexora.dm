
/datum/config_entry/string/plexora_url
	default = "http://127.0.0.1:1330"

/datum/config_entry/string/plexora_url/ValidateAndSet(str_val)
	if(!findtext(str_val, GLOB.is_http_protocol))
		return FALSE
	return ..()

/datum/config_entry/flag/require_discord_verification

// Role ID to check if a user has in order for them to be let in.
/datum/config_entry/string/plexora_verification_required_roleid
