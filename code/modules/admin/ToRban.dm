//By Carnwennan
//fetches an external list and processes it into a list of ip addresses.
//It then stores the processed list into a savefile for later use
#define TORFILE "data/ToR_ban.bdb"
#define TOR_UPDATE_INTERVAL 216000	//~6 hours

/proc/ToRban_isbanned(ip_address)
	var/savefile/F = new(TORFILE)
	if(F && (ip_address in F.dir))
		return TRUE
	return FALSE

/proc/ToRban_autoupdate()
	var/savefile/F = new(TORFILE)
	if(F)
		var/last_update
		F["last_update"] >> last_update
		if((last_update + TOR_UPDATE_INTERVAL) < world.realtime)	//we haven't updated for a while
			ToRban_update()
	return

/proc/ToRban_update()
	set waitfor = FALSE
	log_admin("Downloading updated ToR data...")
	var/list/http = world.Export("https://check.torproject.org/exit-addresses")

	var/list/rawlist = file2list(http["CONTENT"])
	if(rawlist.len)
		fdel(TORFILE)
		var/savefile/F = new(TORFILE)
		for(var/line in rawlist)
			if(!line)
				continue
			if(copytext(line,1,12) == "ExitAddress")
				var/cleaned = copytext(line,13,length(line)-19)
				if(!cleaned)
					continue
				F[cleaned] << 1
		F["last_update"] << world.realtime
		log_admin("ToR data updated!")
		if(usr)
			to_chat(usr, "ToRban updated.")
		return
	log_admin("ToR data update aborted: no data.")

/client/proc/ToRban(task in list("update","toggle","show","remove","remove all","find"))
	set name = "ToRban"
	set category = "Server"
	if(!holder)
		return
	switch(task)
		if("update")
			ToRban_update()
		if("toggle")
			if(config)
				if(CONFIG_GET(flag/tor_ban))
					CONFIG_SET(flag/tor_ban, FALSE)
					message_admins("<font color='red'>ToR banning disabled.</font>")
				else
					CONFIG_SET(flag/tor_ban, TRUE)
					message_admins("<font colot='green'>ToR banning enabled.</font>")
		if("show")
			var/savefile/F = new(TORFILE)
			var/dat
			if( length(F.dir) )
				for( var/i=1, i<=length(F.dir), i++ )
					dat += "<tr><td>#[i]</td><td> [F.dir[i]]</td></tr>"
				dat = "<table width='100%'>[dat]</table>"
			else
				dat = "No addresses in list."
			src << browse(HTML_SKELETON(dat),"window=ToRban_show")
		if("remove")
			var/savefile/F = new(TORFILE)
			var/choice = input(src,"Please select an IP address to remove from the ToR banlist:","Remove ToR ban",null) as null|anything in F.dir
			if(choice)
				F.dir.Remove(choice)
				to_chat(src, "<b>Address removed</b>")
		if("remove all")
			to_chat(src, "<b>[TORFILE] was [fdel(TORFILE)?"":"not "]removed.</b>")
		if("find")
			var/input = input(src,"Please input an IP address to search for:","Find ToR ban",null) as null|text
			if(input)
				if(ToRban_isbanned(input))
					to_chat(src, "<font color='green'><b>Address is a known ToR address</b></font>")
				else
					to_chat(src, "<font color='red'><b>Address is not a known ToR address</b></font>")
	return

#undef TORFILE
#undef TOR_UPDATE_INTERVAL
