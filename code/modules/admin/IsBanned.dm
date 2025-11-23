//Blocks an attempt to connect before even creating our client datum thing.



/world/IsBanned(key, address, computer_id, type, real_bans_only=FALSE)
	debug_world_log("isbanned(): '[args.Join("', '")]'")
	if (!key || (!real_bans_only && (!address || !computer_id)))
		if(real_bans_only)
			return FALSE
		log_access("Failed Login (invalid data): [key] [address]-[computer_id]")
		return list("reason"="invalid login data", "desc"="Error: Could not check ban status, Please try again. Error message: Your computer provided invalid or blank information to the server on connection (byond username, IP, and Computer ID.) Provided information for reference: Username:'[key]' IP:'[address]' Computer ID:'[computer_id]'. (If you continue to get this error, please restart byond or contact byond support.)")

	if (type == "world")
		return ..() //shunt world topic banchecks to purely to byond's internal ban system

	if(real_bans_only && !key)
		return FALSE

	var/ckey = ckey(key)

	var/admin = FALSE
	var/mentor = FALSE

	var/client/C = GLOB.directory[ckey]
	if (C && ckey == C.ckey && computer_id == C.computer_id && address == C.address)
		return //don't recheck connected clients.

	//IsBanned can get re-called on a user in certain situations, this prevents that leading to repeated messages to admins.
	var/static/list/checkedckeys = list()
	//magic voodo to check for a key in a list while also adding that key to the list without having to do two associated lookups
	var/message = !checkedckeys[ckey]++

	if (GLOB.admin_datums[ckey] || GLOB.deadmins[ckey] || (ckey in GLOB.protected_admins))
		admin = TRUE

	if (is_mentor(C))
		mentor = TRUE

	//Whitelist
	if(!real_bans_only && !C && CONFIG_GET(flag/usewhitelist))
		if(!check_whitelist(ckey))
			if (admin || mentor)
				log_admin("The admin/mentor [ckey] has been allowed to bypass the whitelist")
				if (message)
					message_admins(span_adminnotice("The admin/mentor [ckey] has been allowed to bypass the whitelist"))
					addclientmessage(ckey,span_adminnotice("You have been allowed to bypass the whitelist"))
			else
				log_access("Failed Login: [ckey] - Not on whitelist")
				return list("reason"="whitelist", "desc" = "\nReason: You are not on the white list for this server")

	//Guest Checking
	if(!real_bans_only && !CONFIG_GET(flag/guests_allowed) && IsGuestKey(key))
		log_access("Failed Login: [key] - Guests not allowed")
		message_admins(span_blue("Failed Login: [key] - Guests not allowed"))
		return list("reason"="guest", "desc"="\nReason: Guests not allowed. Please sign in with a byond account.")

	//check if the IP address is a known TOR node
	if(!real_bans_only && config && CONFIG_GET(flag/tor_ban) && ToRban_isbanned(address))
		log_access("Failed Login: [src] - Banned: ToR")
		message_admins(span_blue("Failed Login: [src] - Banned: ToR"))
		//ban their computer_id and ckey for posterity
		// TODO: add ban code for torban
		// AddBan(ckey(key), computer_id, "Use of ToR", "Automated Ban", 0, 0)
		return list("reason"="Using ToR", "desc"="\nReason: The network you are using to connect has been banned.\nIf you believe this is a mistake, please request help at [CONFIG_GET(string/banappeals)]")

	//Population Cap Checking
	var/extreme_popcap = CONFIG_GET(number/extreme_popcap)
	if(!real_bans_only && !C && extreme_popcap)
		var/popcap_value = GLOB.clients.len
		if(popcap_value >= extreme_popcap && !GLOB.joined_player_list.Find(ckey))
			if (admin || mentor)
				var/msg = "Popcap Login: [ckey] - Is a(n) [admin ? "admin" : mentor ? "mentor" : "???"], therefore allowed passed the popcap of [extreme_popcap] - [popcap_value] clients connected"
				log_access(msg)
				message_admins(msg)
			if(!CONFIG_GET(flag/byond_member_bypass_popcap) || !world.IsSubscribed(ckey, "BYOND"))
				var/msg = "Failed Login: [ckey] - Population cap reached"
				log_access(msg)
				message_admins(msg)
				return list("reason"="popcap", "desc"= "\nReason: [CONFIG_GET(string/extreme_popcap_message)]")


	if(CONFIG_GET(flag/sql_enabled))
		if(!SSdbcore.Connect())
			var/msg = "Ban database connection failure. Key [ckey] not checked"
			log_world(msg)
			if (message)
				message_admins(msg)
		else
			var/list/ban_details = is_banned_from_with_details(ckey, address, computer_id, "Server")
			for(var/i in ban_details)
				if(admin)
					if(text2num(i["applies_to_admins"]))
						var/msg = "Admin [ckey] is admin banned, and has been disallowed access."
						log_admin(msg)
						if (message)
							message_admins(msg)
					else
						var/msg = "Admin [ckey] has been allowed to bypass a matching non-admin ban on [ckey(i["key"])] [i["ip"]]-[i["computerid"]]."
						log_admin(msg)
						if (message)
							message_admins(msg)
							addclientmessage(ckey,span_adminnotice("Admin [ckey] has been allowed to bypass a matching non-admin ban on [i["key"]] [i["ip"]]-[i["computerid"]]."))
						continue
				var/expires = "This is a permanent ban."
				if(i["expiration_time"])
					expires = " The ban is for [DisplayTimeText(text2num(i["duration"]) MINUTES)] and expires on [i["expiration_time"]] (server time)."
				var/desc = {"You, or another user of this computer or connection ([i["key"]]) is banned from playing here.
				The ban reason is: [i["reason"]]
				This ban (BanID #[i["id"]]) was applied by [i["admin_key"]] on [i["bantime"]] during round ID [i["round_id"]].
				[expires]"}
				log_suspicious_login("Failed Login: [ckey] [computer_id] [address] - Banned (#[i["id"]])")
				return list("reason"="Banned","desc"="[desc]")

	. = ..() //default pager ban stuff
