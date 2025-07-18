/obj/machinery/computer/secure_data
	name = "security records console"
	desc = "Used to view, edit and maintain security records"
	icon_keyboard = "security_key"
	icon_screen = "security"
	light_color = COLOR_LIGHTING_SCI_BRIGHT
	req_one_access = list(access_security)
	circuit = /obj/item/electronics/circuitboard/secure_data
	var/obj/item/card/id/scan
	var/authenticated
	var/rank
	var/screen
	var/datum/data/record/active1
	var/datum/data/record/active2
	var/a_id
	var/temp
	var/printing
	var/can_change_id = 0
	var/list/Perp
	var/tempname
	//Sorting Variables
	var/sortBy = "name"
	var/order = 1 // -1 = Descending - 1 = Ascending

/obj/machinery/computer/secure_data/verb/eject_id()
	set category = "Object"
	set name = "Eject ID Card"
	set src in oview(1)

	if(!usr || usr.stat || usr.lying)	return

	if(scan)
		to_chat(usr, "You remove \the [scan] from \the [src].")
		scan.loc = get_turf(src)
		if(!usr.get_active_held_item() && ishuman(usr))
			usr.put_in_hands(scan)
		scan = null
	else
		to_chat(usr, "There is nothing to remove from the console.")
	return

/obj/machinery/computer/secure_data/attackby(obj/item/O as obj, user as mob)
	if(istype(O, /obj/item/card/id) && !scan)
		usr.drop_item()
		O.loc = src
		scan = O
		to_chat(user, "You insert [O].")
	..()

//Someone needs to break down the dat += into chunks instead of long ass lines.
/obj/machinery/computer/secure_data/attack_hand(mob/user)
	if(..())
		return
	nano_ui_interact(user)

/obj/machinery/computer/secure_data/nano_ui_interact(user)
	if (src.z > 6)
		to_chat(user, "[span_warning("Unable to establish a connection:")] You're too far away from the station!")
		return

	var/dat
	if (temp)
		dat = text("<TT>[]</TT><BR><BR><A href='byond://?src=\ref[];choice=Clear Screen'>Clear Screen</A>", temp, src)
	else
		dat = text("Confirm Identity: <A href='byond://?src=\ref[];choice=Confirm Identity'>[]</A><HR>", src, (scan ? text("[]", scan.name) : "----------"))
		if (authenticated)
			switch(screen)
				if(1)
					dat += {"<p style='text-align:center;'>"}
					dat += text("<A href='byond://?src=\ref[];choice=Search Records'>Search Records</A><BR>", src)
					dat += text("<A href='byond://?src=\ref[];choice=New Record (General)'>New Record</A><BR>", src)
					dat += {"
</p>
<table style="text-align:center;" cellspacing="0" width="100%">
<tr>
<th>Records:</th>
</tr>
</table>
<table style="text-align:center;" border="1" cellspacing="0" width="100%">
<tr>
<th><A href='byond://?src=\ref[src];choice=Sorting;sort=name'>Name</A></th>
<th><A href='byond://?src=\ref[src];choice=Sorting;sort=id'>ID</A></th>
<th><A href='byond://?src=\ref[src];choice=Sorting;sort=rank'>Rank</A></th>
<th><A href='byond://?src=\ref[src];choice=Sorting;sort=fingerprint'>Fingerprints</A></th>
<th>Criminal Status</th>
</tr>"}
					if(!isnull(data_core.general))
						for(var/datum/data/record/R in sortRecord(data_core.general, sortBy, order))
							var/crimstat = ""
							for(var/datum/data/record/E in data_core.security)
								if ((E.fields["name"] == R.fields["name"] && E.fields["id"] == R.fields["id"]))
									crimstat = E.fields["criminal"]
							var/background
							switch(crimstat)
								if("*Arrest*")
									background = "'background-color:#DC143C;'"
								if("Incarcerated")
									background = "'background-color:#CD853F;'"
								if("Parolled")
									background = "'background-color:#CD853F;'"
								if("Released")
									background = "'background-color:#3BB9FF;'"
								if("None")
									background = "'background-color:#00FF7F;'"
								if("")
									background = "'background-color:#FFFFFF;'"
									crimstat = "No Record."
							dat += text("<tr style=[]><td><A href='byond://?src=\ref[];choice=Browse Record;d_rec=\ref[]'>[]</a></td>", background, src, R, R.fields["name"])
							dat += text("<td>[]</td>", R.fields["id"])
							dat += text("<td>[]</td>", R.fields["rank"])
							dat += text("<td>[]</td>", R.fields["fingerprint"])
							dat += text("<td>[]</td></tr>", crimstat)
						dat += "</table><hr width='75%' />"
					dat += text("<A href='byond://?src=\ref[];choice=Record Maintenance'>Record Maintenance</A><br><br>", src)
					dat += text("<A href='byond://?src=\ref[];choice=Log Out'>{Log Out}</A>",src)
				if(2)
					dat += "<B>Records Maintenance</B><HR>"
					dat += "<BR><A href='byond://?src=\ref[src];choice=Delete All Records'>Delete All Records</A><BR><BR><A href='byond://?src=\ref[src];choice=Return'>Back</A>"
				if(3)
					dat += "<CENTER><B>Security Record</B></CENTER><BR>"
					if ((istype(active1, /datum/data/record) && data_core.general.Find(active1)))
						user << browse_rsc(active1.fields["photo_front"], "front.png")
						user << browse_rsc(active1.fields["photo_side"], "side.png")
						dat += {"
							<table><tr><td>
							Name: <A href='byond://?src=\ref[src];choice=Edit;field=name'>[active1.fields["name"]]</A><BR>
							ID: <A href='byond://?src=\ref[src];choice=Edit;field=id'>[active1.fields["id"]]</A><BR>
							Sex: <A href='byond://?src=\ref[src];choice=Edit;field=sex'>[active1.fields["sex"]]</A><BR>
							Age: <A href='byond://?src=\ref[src];choice=Edit;field=age'>[active1.fields["age"]]</A><BR>
							Rank: <A href='byond://?src=\ref[src];choice=Edit;field=rank'>[active1.fields["rank"]]</A><BR>
							Fingerprint: <A href='byond://?src=\ref[src];choice=Edit;field=fingerprint'>[active1.fields["fingerprint"]]</A><BR>
							Physical Status: [active1.fields["p_stat"]]<BR>
							Mental Status: [active1.fields["m_stat"]]<BR></td>
							<td align = center valign = top>Photo:<br>
							<table><td align = center><img src=front.png height=80 width=80 border=4><BR>
							<A href='byond://?src=\ref[src];choice=Edit;field=photo front'>Update front photo</A></td>
							<td align = center><img src=side.png height=80 width=80 border=4><BR>
							<A href='byond://?src=\ref[src];choice=Edit;field=photo side'>Update side photo</A></td></table>
							</td></tr></table>
						"}
					else
						dat += "<B>General Record Lost!</B><BR>"
					if ((istype(active2, /datum/data/record) && data_core.security.Find(active2)))
						dat += "<BR>\n<CENTER><B>Security Data</B></CENTER><BR>\nCriminal Status: \
								<A href='byond://?src=\ref[src];choice=Edit;field=criminal'>[active2.fields["criminal"]]</A><BR>\n<BR>\n \
								Minor Crimes: <A href='byond://?src=\ref[src];choice=Edit;field=mi_crim'>[active2.fields["mi_crim"]]</A><BR>\n \
								Details: <A href='byond://?src=\ref[src];choice=Edit;field=mi_crim_d'>[active2.fields["mi_crim_d"]]</A><BR>\n<BR>\n\
								Major Crimes: <A href='byond://?src=\ref[src];choice=Edit;field=ma_crim'>[active2.fields["ma_crim"]]</A><BR>\n \
								Details: <A href='byond://?src=\ref[src];choice=Edit;field=ma_crim_d'>[active2.fields["ma_crim_d"]]</A><BR>\n<BR>\n \
								Important Notes:<BR>\n\t<A href='byond://?src=\ref[src];choice=Edit;field=notes'>[decode(active2.fields["notes"])]</A><BR>\n<BR>\n\
								<CENTER><B>Comments/Log</B></CENTER><BR>"
						var/counter = 1
						while(active2.fields["com_[counter]"])
							dat += text("[]<BR><A href='byond://?src=\ref[];choice=Delete Entry;del_c=[]'>Delete Entry</A><BR><BR>", active2.fields["com_[counter]"], src, counter)
							counter++
						dat += "<A href='byond://?src=\ref[src];choice=Add Entry'>Add Entry</A><BR><BR>"
						dat += "<A href='byond://?src=\ref[src];choice=Delete Record (Security)'>Delete Record (Security Only)</A><BR><BR>"
					else
						dat += "<B>Security Record Lost!</B><BR>"
						dat += "<A href='byond://?src=\ref[src];choice=New Record (Security)'>New Security Record</A><BR><BR>"
					dat += "<A href='byond://?src=\ref[src];choice=Delete Record (ALL)'>Delete Record (ALL)</A><BR><BR> \
							<A href='byond://?src=\ref[src];choice=Print Record'>Print Record</A><BR> \
							<A href='byond://?src=\ref[src];choice=Print Poster'>Print Wanted Poster</A><BR> \
							<A href='byond://?src=\ref[src];choice=Return'>Back</A><BR>"
				if(4)
					if(!Perp.len)
						dat += text("ERROR.  String could not be located.<br><br><A href='byond://?src=\ref[];choice=Return'>Back</A>", src)
					else
						dat += {"
							<table style="text-align:center;" cellspacing="0" width="100%">
							<tr><th>Search Results for '[tempname]':</th></tr></table>
							<table style="text-align:center;" border="1" cellspacing="0" width="100%">
							<tr>
							<th>Name</th>
							<th>ID</th>
							<th>Rank</th>
							<th>Fingerprints</th>
							<th>Criminal Status</th>
							</tr>
						"}
						for(var/i=1, i<=Perp.len, i += 2)
							var/crimstat = ""
							var/datum/data/record/R = Perp[i]
							if(istype(Perp[i+1],/datum/data/record/))
								var/datum/data/record/E = Perp[i+1]
								crimstat = E.fields["criminal"]
							var/background
							switch(crimstat)
								if("*Arrest*")
									background = "'background-color:#DC143C;'"
								if("Incarcerated")
									background = "'background-color:#CD853F;'"
								if("Parolled")
									background = "'background-color:#CD853F;'"
								if("Released")
									background = "'background-color:#3BB9FF;'"
								if("None")
									background = "'background-color:#00FF7F;'"
								if("")
									background = "'background-color:#FFFFFF;'"
									crimstat = "No Record."
							dat += text("<tr style=[]><td><A href='byond://?src=\ref[];choice=Browse Record;d_rec=\ref[]'>[]</a></td>", background, src, R, R.fields["name"])
							dat += text("<td>[]</td>", R.fields["id"])
							dat += text("<td>[]</td>", R.fields["rank"])
							dat += text("<td>[]</td>", R.fields["fingerprint"])
							dat += text("<td>[]</td></tr>", crimstat)
						dat += "</table><hr width='75%' />"
						dat += text("<br><A href='byond://?src=\ref[];choice=Return'>Return to index.</A>", src)
				else
		else
			dat += text("<A href='byond://?src=\ref[];choice=Log In'>{Log In}</A>", src)
	user << browse(HTML_SKELETON_TITLE("Security Records", "<TT>[dat]</TT>"), "window=secure_rec;size=600x400")
	onclose(user, "secure_rec")
	return

/*Revised /N
I can't be bothered to look more of the actual code outside of switch but that probably needs revising too.
What a mess.*/
/obj/machinery/computer/secure_data/Topic(href, href_list)
	if(..())
		return 1
	if (!( data_core.general.Find(active1) ))
		active1 = null
	if (!( data_core.security.Find(active2) ))
		active2 = null
	if ((usr.contents.Find(src) || (in_range(src, usr) && istype(loc, /turf))) || (issilicon(usr)))
		usr.set_machine(src)
		switch(href_list["choice"])
// SORTING!
			if("Sorting")
				// Reverse the order if clicked twice
				if(sortBy == href_list["sort"])
					if(order == 1)
						order = -1
					else
						order = 1
				else
				// New sorting order!
					sortBy = href_list["sort"]
					order = initial(order)
//BASIC FUNCTIONS
			if("Clear Screen")
				temp = null

			if ("Return")
				screen = 1
				active1 = null
				active2 = null

			if("Confirm Identity")
				if (scan)
					if(ishuman(usr) && !usr.get_active_held_item())
						usr.put_in_hands(scan)
					else
						scan.loc = get_turf(src)
					scan = null
				else
					var/obj/item/I = usr.get_active_held_item()
					if (istype(I, /obj/item/card/id) && usr.unEquip(I))
						I.loc = src
						scan = I

			if("Log Out")
				authenticated = null
				screen = null
				active1 = null
				active2 = null

			if("Log In")
				if (isAI(usr))
					src.active1 = null
					src.active2 = null
					src.authenticated = usr.name
					src.rank = "AI"
					src.screen = 1
				else if (isrobot(usr))
					src.active1 = null
					src.active2 = null
					src.authenticated = usr.name
					var/mob/living/silicon/robot/R = usr
					src.rank = "[R.modtype] [R.braintype]"
					src.screen = 1
				else if (istype(scan, /obj/item/card/id))
					active1 = null
					active2 = null
					if(check_access(scan))
						authenticated = scan.registered_name
						rank = scan.assignment
						screen = 1
//RECORD FUNCTIONS
			if("Search Records")
				var/t1 = input("Search String: (Partial Name or ID or Fingerprints or Rank)", "Secure. records", null, null)  as text
				if ((!( t1 ) || usr.stat || !( authenticated ) || usr.restrained() || !in_range(src, usr)))
					return
				Perp = new/list()
				t1 = lowertext(t1)
				var/list/components = splittext(t1, " ")
				if(components.len > 5)
					return //Lets not let them search too greedily.
				for(var/datum/data/record/R in data_core.general)
					var/temptext = R.fields["name"] + " " + R.fields["id"] + " " + R.fields["fingerprint"] + " " + R.fields["rank"]
					for(var/i = 1, i<=components.len, i++)
						if(findtext(temptext,components[i]))
							var/prelist = new/list(2)
							prelist[1] = R
							Perp += prelist
				for(var/i = 1, i<=Perp.len, i+=2)
					for(var/datum/data/record/E in data_core.security)
						var/datum/data/record/R = Perp[i]
						if ((E.fields["name"] == R.fields["name"] && E.fields["id"] == R.fields["id"]))
							Perp[i+1] = E
				tempname = t1
				screen = 4

			if("Record Maintenance")
				screen = 2
				active1 = null
				active2 = null

			if ("Browse Record")
				var/datum/data/record/R = locate(href_list["d_rec"])
				var/S = locate(href_list["d_rec"])
				if (!( data_core.general.Find(R) ))
					temp = "Record Not Found!"
				else
					for(var/datum/data/record/E in data_core.security)
						if ((E.fields["name"] == R.fields["name"] || E.fields["id"] == R.fields["id"]))
							S = E
					active1 = R
					active2 = S
					screen = 3

/*			if ("Search Fingerprints")
				var/t1 = input("Search String: (Fingerprint)", "Secure. records", null, null)  as text
				if ((!( t1 ) || usr.stat || !( authenticated ) || usr.restrained() || (!in_range(src, usr)) && (!issilicon(usr))))
					return
				active1 = null
				active2 = null
				t1 = lowertext(t1)
				for(var/datum/data/record/R in data_core.general)
					if (lowertext(R.fields["fingerprint"]) == t1)
						active1 = R
				if (!( active1 ))
					temp = text("Could not locate record [].", t1)
				else
					for(var/datum/data/record/E in data_core.security)
						if ((E.fields["name"] == active1.fields["name"] || E.fields["id"] == active1.fields["id"]))
							active2 = E
					screen = 3	*/

			if ("Print Record")
				if (!( printing ))
					printing = 1
					var/datum/data/record/record1 = null
					var/datum/data/record/record2 = null
					if ((istype(active1, /datum/data/record) && data_core.general.Find(active1)))
						record1 = active1
					if ((istype(active2, /datum/data/record) && data_core.security.Find(active2)))
						record2 = active2
					sleep(50)
					var/obj/item/paper/P = new /obj/item/paper( loc )
					P.info = "<CENTER><B>Security Record</B></CENTER><BR>"
					if (record1)
						P.info += {"
							Name: [record1.fields["name"]] ID: [record1.fields["id"]]<BR>
							Sex: [record1.fields["sex"]]<BR>
							Age: [record1.fields["age"]]<BR>
							Fingerprint: [record1.fields["fingerprint"]]<BR>
							Physical Status: [record1.fields["p_stat"]]<BR>
							Mental Status: [record1.fields["m_stat"]]<BR>
						"}
						P.name = "Security Record ([record1.fields["name"]])"
					else
						P.info += "<B>General Record Lost!</B><BR>"
						P.name = "Security Record"
					if (record2)
						P.info += {"
							<BR><CENTER><B>Security Data</B></CENTER><BR>
							Criminal Status: [record2.fields["criminal"]]<BR><BR>
							Minor Crimes: [record2.fields["mi_crim"]]<BR>
							Details: [record2.fields["mi_crim_d"]]<BR><BR>
							Major Crimes: [record2.fields["ma_crim"]]<BR>
							Details: [record2.fields["ma_crim_d"]]<BR><BR>
							Important Notes:<BR>
							\t[decode(record2.fields["notes"])]<BR><BR>
							<CENTER><B>Comments/Log</B></CENTER><BR>
						"}
						var/counter = 1
						while(record2.fields[text("com_[]", counter)])
							P.info += text("[]<BR>", record2.fields[text("com_[]", counter)])
							counter++
					else
						P.info += "<B>Security Record Lost!</B><BR>"
					P.info += "</TT>"
					printing = null
					updateUsrDialog()

			if ("Print Poster")
				if(!printing)
					var/wanted_name = sanitizeName(input("Please enter an alias for the criminal:", "Print Wanted Poster", active1.fields["name"]) as text, MAX_NAME_LEN, 1)
					if(wanted_name)
						var/default_description = "A poster declaring [wanted_name] to be a dangerous individual, wanted by Nanotrasen. Report any sightings to security immediately."
						var/major_crimes = active2.fields["ma_crim"]
						var/minor_crimes = active2.fields["mi_crim"]
						default_description += "\n[wanted_name] is wanted for the following crimes:\n"
						default_description += "\nMinor Crimes:\n[minor_crimes]\n[active2.fields["mi_crim_d"]]\n"
						default_description += "\nMajor Crimes:\n[major_crimes]\n[active2.fields["ma_crim_d"]]\n"
						printing = 1
						spawn(30)
							playsound(loc, 'sound/items/poster_being_created.ogg', 100, 1)
							if((istype(active1, /datum/data/record) && data_core.general.Find(active1)))//make sure the record still exists.
								new /obj/item/contraband/poster/wanted(src.loc, active1.fields["photo_front"], wanted_name, default_description)
							printing = 0
//RECORD DELETE
			if ("Delete All Records")
				temp = ""
				temp += "Are you sure you wish to delete all Security records?<br>"
				temp += "<a href='byond://?src=\ref[src];choice=Purge All Records'>Yes</a><br>"
				temp += "<a href='byond://?src=\ref[src];choice=Clear Screen'>No</a>"

			if ("Purge All Records")
				for(var/datum/data/record/R in data_core.security)
					qdel(R)
				temp = "All Security records deleted."

			if ("Add Entry")
				if (!( istype(active2, /datum/data/record) ))
					return
				var/a2 = active2
				var/t1 = sanitize(input("Add Comment:", "Secure. records", null, null)  as message)
				if ((!( t1 ) || !( authenticated ) || usr.stat || usr.restrained() || (!in_range(src, usr) && (!issilicon(usr))) || active2 != a2))
					return
				var/counter = 1
				while(active2.fields[text("com_[]", counter)])
					counter++
				active2.fields[text("com_[counter]")] = text("Made by [authenticated] ([rank]) on [time2text(world.realtime, "DDD MMM DD", NO_TIMEZONE)] [stationtime2text()], [CURRENT_SHIP_YEAR]<BR>[t1]")

			if ("Delete Record (ALL)")
				if (active1)
					temp = "<h5>Are you sure you wish to delete the record (ALL)?</h5>"
					temp += "<a href='byond://?src=\ref[src];choice=Delete Record (ALL) Execute'>Yes</a><br>"
					temp += "<a href='byond://?src=\ref[src];choice=Clear Screen'>No</a>"

			if ("Delete Record (Security)")
				if (active2)
					temp = "<h5>Are you sure you wish to delete the record (Security Portion Only)?</h5>"
					temp += "<a href='byond://?src=\ref[src];choice=Delete Record (Security) Execute'>Yes</a><br>"
					temp += "<a href='byond://?src=\ref[src];choice=Clear Screen'>No</a>"

			if ("Delete Entry")
				if ((istype(active2, /datum/data/record) && active2.fields[text("com_[]", href_list["del_c"])]))
					active2.fields[text("com_[]", href_list["del_c"])] = "<B>Deleted</B>"
//RECORD CREATE
			if ("New Record (Security)")
				if ((istype(active1, /datum/data/record) && !( istype(active2, /datum/data/record) )))
					active2 = data_core.CreateSecurityRecord(active1.fields["name"], active1.fields["id"])
					screen = 3

			if ("New Record (General)")
				active1 = data_core.CreateGeneralRecord()
				active2 = null

//FIELD FUNCTIONS
			if ("Edit")
				if (is_not_allowed(usr))
					return
				var/a1 = active1
				var/a2 = active2
				switch(href_list["field"])
					if("name")
						if (istype(active1, /datum/data/record))
							var/t1 = sanitizeName(input("Please input name:", "Secure. records", active1.fields["name"], null)  as text)
							if (!t1 || active1 != a1)
								return
							active1.fields["name"] = t1
					if("id")
						if (istype(active2, /datum/data/record))
							var/t1 = sanitize(input("Please input id:", "Secure. records", active1.fields["id"], null)  as text)
							if (!t1 || active1 != a1)
								return
							active1.fields["id"] = t1
					if("fingerprint")
						if (istype(active1, /datum/data/record))
							var/t1 = sanitize(input("Please input fingerprint hash:", "Secure. records", active1.fields["fingerprint"], null)  as text)
							if (!t1 || active1 != a1)
								return
							active1.fields["fingerprint"] = t1
					if("sex")
						if (istype(active1, /datum/data/record))
							if (active1.fields["sex"] == "Male")
								active1.fields["sex"] = "Female"
							else
								active1.fields["sex"] = "Male"
					if("age")
						if (istype(active1, /datum/data/record))
							var/t1 = input("Please input age:", "Secure. records", active1.fields["age"], null)  as num
							if (!t1 || active1 != a1)
								return
							active1.fields["age"] = t1
					if("mi_crim")
						if (istype(active2, /datum/data/record))
							var/t1 = sanitize(input("Please input minor disabilities list:", "Secure. records", active2.fields["mi_crim"], null)  as text)
							if (!t1 || active2 != a2)
								return
							active2.fields["mi_crim"] = t1
					if("mi_crim_d")
						if (istype(active2, /datum/data/record))
							var/t1 = sanitize(input("Please summarize minor dis.:", "Secure. records", active2.fields["mi_crim_d"], null)  as message)
							if (!t1 || active2 != a2)
								return
							active2.fields["mi_crim_d"] = t1
					if("ma_crim")
						if (istype(active2, /datum/data/record))
							var/t1 = sanitize(input("Please input major diabilities list:", "Secure. records", active2.fields["ma_crim"], null)  as text)
							if (!t1 || active2 != a2)
								return
							active2.fields["ma_crim"] = t1
					if("ma_crim_d")
						if (istype(active2, /datum/data/record))
							var/t1 = sanitize(input("Please summarize major dis.:", "Secure. records", active2.fields["ma_crim_d"], null)  as message)
							if (!t1 || active2 != a2)
								return
							active2.fields["ma_crim_d"] = t1
					if("notes")
						if (istype(active2, /datum/data/record))
							var/t1 = sanitize(input("Please summarize notes:", "Secure. records", html_decode(active2.fields["notes"]), null)  as message, extra = 0)
							if (!t1 || active2 != a2)
								return
							active2.fields["notes"] = t1
					if("criminal")
						if (istype(active2, /datum/data/record))
							temp = "<h5>Criminal Status:</h5>"
							temp += "<ul>"
							temp += "<li><a href='byond://?src=\ref[src];choice=Change Criminal Status;criminal2=none'>None</a></li>"
							temp += "<li><a href='byond://?src=\ref[src];choice=Change Criminal Status;criminal2=arrest'>*Arrest*</a></li>"
							temp += "<li><a href='byond://?src=\ref[src];choice=Change Criminal Status;criminal2=incarcerated'>Incarcerated</a></li>"
							temp += "<li><a href='byond://?src=\ref[src];choice=Change Criminal Status;criminal2=parolled'>Parolled</a></li>"
							temp += "<li><a href='byond://?src=\ref[src];choice=Change Criminal Status;criminal2=released'>Released</a></li>"
							temp += "</ul>"
					if("rank")
						var/list/L = list( "First Officer", "Captain", "AI" )
						//This was so silly before the change. Now it actually works without beating your head against the keyboard. /N
						if ((istype(active1, /datum/data/record) && L.Find(rank)))
							temp = "<h5>Rank:</h5>"
							temp += "<ul>"
							for(var/rank in GLOB.joblist)
								temp += "<li><a href='byond://?src=\ref[src];choice=Change Rank;rank=[rank]'>[rank]</a></li>"
							temp += "</ul>"
						else
							alert(usr, "You do not have the required rank to do this!")
					if("species")
						if (istype(active1, /datum/data/record))
							var/t1 = sanitize(input("Please enter race:", "General records", active1.fields["species"], null)  as message)
							if (!t1 || active1 != a1)
								return
							active1.fields["species"] = t1
					if("photo front")
						var/icon/photo = get_photo(usr)
						if(photo)
							active1.fields["photo_front"] = photo
					if("photo side")
						var/icon/photo = get_photo(usr)
						if(photo)
							active1.fields["photo_side"] = photo


//TEMPORARY MENU FUNCTIONS
			else//To properly clear as per clear screen.
				temp=null
				switch(href_list["choice"])
					if ("Change Rank")
						if (active1)
							active1.fields["rank"] = href_list["rank"]
							if(href_list["rank"] in GLOB.joblist)
								active1.fields["real_rank"] = href_list["real_rank"]

					if ("Change Criminal Status")
						if (active2)
							for(var/mob/living/carbon/human/H in GLOB.player_list)
								BITSET(H.hud_updateflag, WANTED_HUD)
							switch(href_list["criminal2"])
								if("none")
									active2.fields["criminal"] = "None"
								if("arrest")
									active2.fields["criminal"] = "*Arrest*"
								if("incarcerated")
									active2.fields["criminal"] = "Incarcerated"
								if("parolled")
									active2.fields["criminal"] = "Parolled"
								if("released")
									active2.fields["criminal"] = "Released"

					if ("Delete Record (Security) Execute")
						if (active2)
							qdel(active2)

					if ("Delete Record (ALL) Execute")
						if (active1)
							for(var/datum/data/record/R in data_core.medical)
								if ((R.fields["name"] == active1.fields["name"] || R.fields["id"] == active1.fields["id"]))
									qdel(R)
								else
							qdel(active1)
						if (active2)
							qdel(active2)
					else
						temp = "This function does not appear to be working at the moment. Our apologies."

	add_fingerprint(usr)
	updateUsrDialog()
	return

/obj/machinery/computer/secure_data/proc/is_not_allowed(mob/user)
	return !src.authenticated || user.stat || user.restrained() || (!in_range(src, user) && (!issilicon(user)))

/obj/machinery/computer/secure_data/proc/get_photo(mob/user)
	if(istype(user.get_active_held_item(), /obj/item/photo))
		var/obj/item/photo/photo = user.get_active_held_item()
		return photo.img
	if(issilicon(user))
		var/mob/living/silicon/tempAI = usr
		var/obj/item/photo/selection = tempAI.GetPicture()
		if (selection)
			return selection.img

/obj/machinery/computer/secure_data/emp_act(severity)
	if(stat & (BROKEN|NOPOWER))
		..(severity)
		return

	for(var/datum/data/record/R in data_core.security)
		if(prob(10/severity))
			switch(rand(1,6))
				if(1)
					R.fields["name"] = "[pick(pick(GLOB.first_names_male), pick(GLOB.first_names_female))] [pick(GLOB.last_names)]"
				if(2)
					R.fields["sex"]	= pick("Male", "Female")
				if(3)
					R.fields["age"] = rand(5, 85)
				if(4)
					R.fields["criminal"] = pick("None", "*Arrest*", "Incarcerated", "Parolled", "Released")
				if(5)
					R.fields["p_stat"] = pick("*Unconcious*", "Active", "Physically Unfit")
					if(PDA_Manifest.len)
						PDA_Manifest.Cut()
				if(6)
					R.fields["m_stat"] = pick("*Insane*", "*Unstable*", "*Watch*", "Stable")
			continue

		else if(prob(1))
			qdel(R)
			continue

	..(severity)

/obj/machinery/computer/secure_data/detective_computer
	icon = 'icons/obj/computer.dmi'
	icon_state = "messyfiles"
