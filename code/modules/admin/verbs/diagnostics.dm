/client/proc/fix_next_move()
	set category = "Debug"
	set name = "Unfreeze Everyone"
	var/largest_move_time = 0
	var/largest_click_time = 0
	var/mob/largest_move_mob = null
	var/mob/largest_click_mob = null
	for(var/mob/M in world)
		if(!M.client)
			continue
		if(M.next_move >= largest_move_time)
			largest_move_mob = M
			if(M.next_move > world.time)
				largest_move_time = M.next_move - world.time
			else
				largest_move_time = 1
		if(M.next_click >= largest_click_time)
			largest_click_mob = M
			if(M.next_click > world.time)
				largest_click_time = M.next_click - world.time
			else
				largest_click_time = 0
		log_admin("DEBUG: [key_name(M)]  next_move = [M.next_move]  next_click = [M.next_click]  world.time = [world.time]")
		M.next_move = 1
		M.next_click = 0
	message_admins("[key_name_admin(largest_move_mob)] had the largest move delay with [largest_move_time] frames / [largest_move_time/10] seconds!", 1)
	message_admins("[key_name_admin(largest_click_mob)] had the largest click delay with [largest_click_time] frames / [largest_click_time/10] seconds!", 1)
	message_admins("world.time = [world.time]", 1)

	return

/client/proc/radio_report()
	set category = "Debug"
	set name = "Radio report"

	var/output = "<b>Radio Report</b><hr>"
	for (var/fq in SSradio.frequencies)
		output += "<b>Freq: [fq]</b><br>"
		var/datum/radio_frequency/fqs = SSradio.frequencies[fq]
		if (!fqs)
			output += "&nbsp;&nbsp;<b>ERROR</b><br>"
			continue
		for (var/filter in fqs.devices)
			var/list/f = fqs.devices[filter]
			if (!f)
				output += "&nbsp;&nbsp;[filter]: ERROR<br>"
				continue
			output += "&nbsp;&nbsp;[filter]: [f.len]<br>"
			for (var/device in f)
				if (isobj(device))
					output += "&nbsp;&nbsp;&nbsp;&nbsp;[device] ([device:x],[device:y],[device:z] in area [get_area(device:loc)])<br>"
				else
					output += "&nbsp;&nbsp;&nbsp;&nbsp;[device]<br>"

	usr << browse(HTML_SKELETON_TITLE("Radio Report", output),"window=radioreport")

/client/proc/reload_admins()
	set name = "Reload Admins"
	set category = "Admin"

	if(!check_rights(R_SERVER))
		return

	message_admins("[usr] manually reloaded admins")
	load_admins()

/client/proc/reload_mentors()
	set name = "Reload Mentors"
	set category = "Admin"

	if(!check_rights(R_SERVER))
		return

	message_admins("[usr] manually reloaded Mentors")
	world.load_mentors()

/client/proc/reload_whitelist()
	set name = "Reload Whitelist"
	set category = "Admin"

	if(!check_rights(R_SERVER))
		return

	load_whitelist()
	var/count = GLOB.whitelist.len
	message_admins("[usr] manually reloaded the whitelist (loaded [count] entries)")
