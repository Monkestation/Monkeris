/client/proc/edit_admin_permissions()
	set category = "Admin"
	set name = "Permissions Panel"
	set desc = "Edit admin permissions"

	if(!check_rights(R_PERMISSIONS))
		return
	usr.client.holder.edit_admin_permissions()


/datum/admins/proc/edit_admin_permissions()
	if(!check_rights(R_PERMISSIONS))
		return

	var/output = {"<!DOCTYPE html>
		<html>
		<head>
		<title>Permissions Panel</title>
		<script type='text/javascript' src='search.js'></script>
		<link rel='stylesheet' type='text/css' href='panels.css'>
		</head>
		<body onload='selectTextField();updateSearch();'>
		<div id='main'><table id='searchable' cellspacing='0'>
		<tr class='title'>
		<th style='width:125px;text-align:right;'>CKEY <a class='small' href='byond://?src=\ref[src];[HrefToken()];editrights=add'>\[+\]</a></th>
		<th style='width:125px;'>RANK</th><th style='width:100%;'>PERMISSIONS</th>
		</tr>
		"}

	for(var/admin_ckey in GLOB.admin_datums)
		var/datum/admins/D = GLOB.admin_datums[admin_ckey]
		if(!D)
			continue
		var/rank = D.rank ? D.rank : "*none*"
		var/rights = rights2text(D.rights," ")
		if(!rights)
			rights = "*none*"

		output += "<tr>"
		output += "<td style='text-align:right;'>[admin_ckey] <a class='small' href='byond://?src=\ref[src];[HrefToken()];editrights=remove;ckey=[admin_ckey]'>\[-\]</a></td>"
		output += "<td><a href='byond://?src=\ref[src];[HrefToken()];editrights=rank;ckey=[admin_ckey]'>[rank]</a></td>"
		output += "<td><a class='small' href='byond://?src=\ref[src];[HrefToken()];editrights=permissions;ckey=[admin_ckey]'>[rights]</a></td>"
		output += "</tr>"

	output += {"
		</table></div>
		<div id='top'><b>Search:</b> <input type='text' id='filter' value='' style='width:70%;' onkeyup='updateSearch();'></div>
		</body>
		</html>"}

	usr << browse(output,"window=editrights;size=600x500")

/datum/admins/proc/log_admin_rank_modification(admin_ckey, new_rank)
	if(CONFIG_GET(flag/admin_legacy_system))
		return

	if(!usr.client)
		return

	if(!usr.client.holder || !(usr.client.holder.rights & R_PERMISSIONS))
		to_chat(usr, span_warning("You do not have permission to do this!"))
		return

	if(!SSdbcore.Connect())
		to_chat(usr, span_warning("Failed to establish database connection."))
		return

	if(!admin_ckey || !new_rank)
		return

	admin_ckey = ckey(admin_ckey)

	if(!admin_ckey)
		return

	if(!istext(admin_ckey) || !istext(new_rank))
		return

	var/datum/db_query/select_query = SSdbcore.NewQuery("SELECT ckey FROM [format_table_name("player")] WHERE ckey = '[admin_ckey]' AND rank != 'player'")
	select_query.Execute()

	var/new_admin = TRUE
	if(select_query.NextRow())
		new_admin = FALSE

	if(new_admin)
		var/datum/db_query/insert_query = SSdbcore.NewQuery("UPDATE [format_table_name("player")] SET rank = '[new_rank]' WHERE ckey = '[admin_ckey]'")
		insert_query.Execute()
		message_admins("[key_name_admin(usr)] made [key_name_admin(admin_ckey)] an admin with the rank [new_rank]")
		log_admin("[key_name(usr)] made [key_name(admin_ckey)] an admin with the rank [new_rank]")
		to_chat(usr, span_notice("New admin added."))
	else
		var/datum/db_query/insert_query = SSdbcore.NewQuery("UPDATE [format_table_name("player")] SET rank = '[new_rank]' WHERE ckey = '[admin_ckey]'")
		insert_query.Execute()
		message_admins("[key_name_admin(usr)] changed [key_name_admin(admin_ckey)] admin rank to [new_rank]")
		log_admin("[key_name(usr)] changed [key_name(admin_ckey)] admin rank to [new_rank]")
		to_chat(usr, span_notice("Admin rank changed."))

/datum/admins/proc/log_admin_permission_modification(admin_ckey, new_permission, nominal)
	if(CONFIG_GET(flag/admin_legacy_system))
		return

	if(!usr.client)
		return

	if(!usr.client.holder || !(usr.client.holder.rights & R_PERMISSIONS))
		to_chat(usr, span_warning("You do not have permission to do this!"))
		return

	if(!SSdbcore.Connect())
		to_chat(usr, span_warning("Failed to establish database connection."))
		return

	if(!admin_ckey || !new_permission)
		return

	admin_ckey = ckey(admin_ckey)

	if(!admin_ckey)
		return

	if(istext(new_permission))
		new_permission = text2num(new_permission)

	if(!istext(admin_ckey) || !isnum(new_permission))
		return

	var/datum/db_query/select_query = SSdbcore.NewQuery("SELECT ckey, flags FROM [format_table_name("player")] WHERE ckey = '[admin_ckey]'")
	select_query.Execute()
	if(!select_query.NextRow())
		to_chat(usr, span_warning("Permissions edit for [admin_ckey] failed on retrieving related database record."))
		return

	var/admin_rights = text2num(select_query.item[2])

	if(admin_rights & new_permission) //This admin already has this permission, so we are removing it.
		var/datum/db_query/insert_query = SSdbcore.NewQuery("UPDATE [format_table_name("player")] SET flags = [admin_rights & ~new_permission] WHERE ckey = '[admin_ckey]'")
		insert_query.Execute()
		message_admins("[key_name_admin(usr)] removed the [nominal] permission of [admin_ckey]")
		log_admin("[key_name(usr)] removed the [nominal] permission of [admin_ckey]")
		to_chat(usr, span_notice("Permission removed."))
	else //This admin doesn't have this permission, so we are adding it.
		var/datum/db_query/insert_query = SSdbcore.NewQuery("UPDATE [format_table_name("player")] SET flags = '[admin_rights | new_permission]' WHERE ckey = '[admin_ckey]'")
		insert_query.Execute()
		message_admins("[key_name_admin(usr)] added the [nominal] permission of [admin_ckey]")
		log_admin("[key_name(usr)] added the [nominal] permission of [admin_ckey]")
		to_chat(usr, span_notice("Permission added."))
