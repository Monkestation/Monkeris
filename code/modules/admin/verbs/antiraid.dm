GLOBAL_LIST_EMPTY(PB_bypass) //Handles ckey

/client/proc/panicbunker()
	set category = "Server"
	set name = "Toggle Panic Bunker"

	if(!check_rights(R_ADMIN))
		return

	if (!CONFIG_GET(flag/sql_enabled))
		to_chat(usr, span_adminnotice("The Database is not enabled!"))
		return

	CONFIG_SET(flag/panic_bunker, !CONFIG_GET(flag/panic_bunker))

	log_and_message_admins("[key_name(usr)] has toggled the Panic Bunker, it is now [(CONFIG_GET(flag/panic_bunker)?"on":"off")].")
	if (CONFIG_GET(flag/panic_bunker) && (!SSdbcore.IsConnected()))
		message_admins("The database is not connected! Panic bunker will not work until the connection is reestablished.")

/client/proc/addbunkerbypass(ckeytobypass as text)
	set category = "Server"
	set name = "Add PB Bypass"
	set desc = "Allows a given ckey to connect despite the panic bunker for a given round."
	if(!SSdbcore.IsConnected())
		to_chat(usr, span_adminnotice("The Database is not enabled or not working!"))
		return

	GLOB.PB_bypass |= ckey(ckeytobypass)
	log_admin("[key_name(usr)] has added [ckeytobypass] to the current round's bunker bypass list.")
	message_admins("[key_name_admin(usr)] has added [ckeytobypass] to the current round's bunker bypass list.")

/client/proc/revokebunkerbypass(ckeytobypass as text)
	set category = "Server"
	set name = "Revoke PB Bypass"
	set desc = "Revoke's a ckey's permission to bypass the panic bunker for a given round."
	if(!SSdbcore.IsConnected())
		to_chat(usr, span_adminnotice("The Database is not enabled or not working!"))
		return

	GLOB.PB_bypass -= ckey(ckeytobypass)
	log_admin("[key_name(usr)] has removed [ckeytobypass] from the current round's bunker bypass list.")
	message_admins("[key_name_admin(usr)] has removed [ckeytobypass] from the current round's bunker bypass list.")

/client/proc/paranoia_logging()
	set category = "Server"
	set name = "New Player Warnings"

	if(!check_rights(R_ADMIN))
		return

	CONFIG_SET(flag/paranoia_logging, !CONFIG_GET(flag/paranoia_logging))

	log_and_message_admins("[key_name(usr)] has toggled Paranoia Logging, it is now [(CONFIG_GET(flag/paranoia_logging)?"on":"off")].")
	if (CONFIG_GET(flag/paranoia_logging) && (!SSdbcore.IsConnected()))
		message_admins("The database is not connected! Paranoia logging will not be able to give 'player age' (time since first connection) warnings, only Byond account warnings.")

/client/proc/ip_reputation()
	set category = "Server"
	set name = "Toggle IP Rep Checks"

	if(!check_rights(R_ADMIN))
		return

	CONFIG_SET(flag/ip_reputation, !CONFIG_GET(flag/ip_reputation))

	log_and_message_admins("[key_name(usr)] has toggled IP reputation checks, it is now [(CONFIG_GET(flag/ip_reputation)?"on":"off")].")
	if (CONFIG_GET(flag/ip_reputation) && (!SSdbcore.IsConnected()))
		message_admins("The database is not connected! IP reputation logging will not be able to allow existing players to bypass the reputation checks (if that is enabled).")

/client/proc/toggle_vpn_white(var/ckey as text)
	set category = "Server"
	set name = "Whitelist ckey from VPN Checks"

	if(!check_rights(R_ADMIN))
		return

	if (!SSdbcore.IsConnected())
		to_chat(usr,"The database is not connected!")
		return

	var/datum/db_query/query = SSdbcore.NewQuery("SELECT id FROM [format_table_name("players")] WHERE ckey = :ckey", list("ckey" = ckey))
	query.Execute()
	if(query.NextRow())
		var/temp_id = query.item[1]
		log_and_message_admins("[key_name(usr)] has toggled VPN checks for [ckey].")
		query = SSdbcore.NewQuery("UPDATE [format_table_name("players")] SET VPN_check_white = !VPN_check_white WHERE id = :temp_id", list("temp_id" = temp_id))
		query.Execute()
	else
		to_chat(usr,"Player [ckey] not found!")
