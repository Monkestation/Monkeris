//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:31

/obj/machinery/computer/med_data//TODO:SANITY
	name = "medical records console"
	desc = "Used to view, edit and maintain medical records."
	icon_keyboard = "med_key"
	icon_screen = "medcomp"
	light_color = COLOR_LIGHTING_GREEN_MACHINERY
	req_one_access = list(access_moebius, access_forensics_lockers)
	circuit = /obj/item/electronics/circuitboard/med_data
	var/obj/item/card/id/scan
	var/authenticated
	var/rank
	var/screen
	var/datum/data/record/active1
	var/datum/data/record/active2
	var/a_id
	var/temp
	var/printing

/obj/machinery/computer/med_data/verb/eject_id()
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

/obj/machinery/computer/med_data/attackby(obj/item/O, mob/user)
	if(istype(O, /obj/item/card/id) && !scan && user.unEquip(O))
		O.loc = src
		scan = O
		to_chat(user, "You insert \the [O].")
	else
		..()

/obj/machinery/computer/med_data/attack_hand(mob/user as mob)
	if(..())
		return
	nano_ui_interact(user)

/obj/machinery/computer/med_data/nano_ui_interact(mob/user)
	var/dat
	if (src.temp)
		dat = text("<TT>[src.temp]</TT><BR><BR><A href='byond://?src=\ref[src];temp=1'>Clear Screen</A>")
	else
		dat = text("Confirm Identity: <A href='byond://?src=\ref[];scan=1'>[]</A><HR>", src, (src.scan ? text("[]", src.scan.name) : "----------"))
		if (src.authenticated)
			switch(src.screen)
				if(1)
					dat += {"
<A href='byond://?src=\ref[src];search=1'>Search Records</A>
<BR><A href='byond://?src=\ref[src];screen=2'>List Records</A>
<BR><A href='byond://?src=\ref[src];screen=6'>Medbot Tracking</A>
<BR>
<BR><A href='byond://?src=\ref[src];screen=3'>Record Maintenance</A>
<BR><A href='byond://?src=\ref[src];logout=1'>{Log Out}</A><BR>
"}
				if(2)
					dat += "<B>Record List</B>:<HR>"
					if(!isnull(data_core.general))
						for(var/datum/data/record/R in sortRecord(data_core.general))
							dat += text("<A href='byond://?src=\ref[];d_rec=\ref[]'>[]: []<BR>", src, R, R.fields["id"], R.fields["name"])
							//Foreach goto(132)
					dat += text("<HR><A href='byond://?src=\ref[];screen=1'>Back</A>", src)
				if(3)
					dat += text("<B>Records Maintenance</B><HR>\n<A href='byond://?src=\ref[];back=1'>Backup To Disk</A><BR>\n<A href='byond://?src=\ref[];u_load=1'>Upload From disk</A><BR>\n<A href='byond://?src=\ref[];del_all=1'>Delete All Records</A><BR>\n<BR>\n<A href='byond://?src=\ref[];screen=1'>Back</A>", src, src, src, src)
				if(4)
					var/icon/front = active1.fields["photo_front"]
					var/icon/side = active1.fields["photo_side"]
					user << browse_rsc(front, "front.png")
					user << browse_rsc(side, "side.png")
					dat += "<CENTER><B>Medical Record</B></CENTER><BR>"
					if ((istype(src.active1, /datum/data/record) && data_core.general.Find(src.active1)))
						dat += "<table><tr><td>Name: [active1.fields["name"]] \
								ID: [active1.fields["id"]]<BR>\n	\
								Sex: <A href='byond://?src=\ref[src];field=sex'>[active1.fields["sex"]]</A><BR>\n	\
								Age: <A href='byond://?src=\ref[src];field=age'>[active1.fields["age"]]</A><BR>\n	\
								Fingerprint: <A href='byond://?src=\ref[src];field=fingerprint'>[active1.fields["fingerprint"]]</A><BR>\n	\
								Physical Status: <A href='byond://?src=\ref[src];field=p_stat'>[active1.fields["p_stat"]]</A><BR>\n	\
								Mental Status: <A href='byond://?src=\ref[src];field=m_stat'>[active1.fields["m_stat"]]</A><BR></td><td align = center valign = top> \
								Photo:<br><img src=front.png height=64 width=64 border=5><img src=side.png height=64 width=64 border=5></td></tr></table>"
					else
						dat += "<B>General Record Lost!</B><BR>"
					if ((istype(src.active2, /datum/data/record) && data_core.medical.Find(src.active2)))
						dat += text("<BR>\n<CENTER><B>Medical Data</B></CENTER><BR>\nBlood Type: <A href='byond://?src=\ref[];field=b_type'>[]</A><BR>\nDNA: <A href='byond://?src=\ref[];field=b_dna'>[]</A><BR>\n<BR>\nMinor Disabilities: <A href='byond://?src=\ref[];field=mi_dis'>[]</A><BR>\nDetails: <A href='byond://?src=\ref[];field=mi_dis_d'>[]</A><BR>\n<BR>\nMajor Disabilities: <A href='byond://?src=\ref[];field=ma_dis'>[]</A><BR>\nDetails: <A href='byond://?src=\ref[];field=ma_dis_d'>[]</A><BR>\n<BR>\nAllergies: <A href='byond://?src=\ref[];field=alg'>[]</A><BR>\nDetails: <A href='byond://?src=\ref[];field=alg_d'>[]</A><BR>\n<BR>\nCurrent Diseases: <A href='byond://?src=\ref[];field=cdi'>[]</A> (per disease info placed in log/comment section)<BR>\nDetails: <A href='byond://?src=\ref[];field=cdi_d'>[]</A><BR>\n<BR>\nImportant Notes:<BR>\n\t<A href='byond://?src=\ref[];field=notes'>[]</A><BR>\n<BR>\n<CENTER><B>Comments/Log</B></CENTER><BR>", src, src.active2.fields["b_type"], src, src.active2.fields["b_dna"], src, src.active2.fields["mi_dis"], src, src.active2.fields["mi_dis_d"], src, src.active2.fields["ma_dis"], src, src.active2.fields["ma_dis_d"], src, src.active2.fields["alg"], src, src.active2.fields["alg_d"], src, src.active2.fields["cdi"], src, src.active2.fields["cdi_d"], src, decode(src.active2.fields["notes"]))
						var/counter = 1
						while(src.active2.fields[text("com_[]", counter)])
							dat += text("[]<BR><A href='byond://?src=\ref[];del_c=[]'>Delete Entry</A><BR><BR>", src.active2.fields[text("com_[]", counter)], src, counter)
							counter++
						dat += text("<A href='byond://?src=\ref[];add_c=1'>Add Entry</A><BR><BR>", src)
						dat += text("<A href='byond://?src=\ref[];del_r=1'>Delete Record (Medical Only)</A><BR><BR>", src)
					else
						dat += "<B>Medical Record Lost!</B><BR>"
						dat += text("<A href='byond://?src=\ref[src];new=1'>New Record</A><BR><BR>")
					dat += text("\n<A href='byond://?src=\ref[];print_p=1'>Print Record</A><BR>\n<A href='byond://?src=\ref[];screen=2'>Back</A><BR>", src, src)
				if(6)
					dat += "<center><b>Medical Robot Monitor</b></center>"
					dat += "<a href='byond://?src=\ref[src];screen=1'>Back</a>"
					dat += "<br><b>Medical Robots:</b>"
					var/bdat
					for(var/mob/living/bot/medbot/M in world)

						if(M.z != src.z)	continue	//only find medibots on the same z-level as the computer
						var/turf/bl = get_turf(M)
						if(bl)	//if it can't find a turf for the medibot, then it probably shouldn't be showing up
							bdat += "[M.name] - <b>\[[bl.x],[bl.y]\]</b> - [M.on ? "Online" : "Offline"]<br>"
							if((!isnull(M.reagent_glass)) && M.use_beaker)
								bdat += "Reservoir: \[[M.reagent_glass.reagents.total_volume]/[M.reagent_glass.reagents.maximum_volume]\]<br>"
							else
								bdat += "Using Internal Synthesizer.<br>"
					if(!bdat)
						dat += "<br><center>None detected</center>"
					else
						dat += "<br>[bdat]"

				else
		else
			dat += text("<A href='byond://?src=\ref[];login=1'>{Log In}</A>", src)
	user << browse(HTML_SKELETON_TITLE("Medical Records", "<TT>[dat]</TT>"), "window=med_rec")
	onclose(user, "med_rec")
	return

/obj/machinery/computer/med_data/Topic(href, href_list)
	if(..())
		return 1

	if (!( data_core.general.Find(src.active1) ))
		src.active1 = null

	if (!( data_core.medical.Find(src.active2) ))
		src.active2 = null

	if ((usr.contents.Find(src) || (in_range(src, usr) && istype(src.loc, /turf))) || (issilicon(usr)))
		usr.set_machine(src)

		if (href_list["temp"])
			src.temp = null

		if (href_list["scan"])
			if (src.scan)

				if(ishuman(usr))
					scan.loc = usr.loc

					if(!usr.get_active_held_item())
						usr.put_in_hands(scan)

					scan = null

				else
					src.scan.loc = src.loc
					src.scan = null

			else
				var/obj/item/I = usr.get_active_held_item()
				if (istype(I, /obj/item/card/id))
					usr.drop_item()
					I.loc = src
					src.scan = I

		else if (href_list["logout"])
			src.authenticated = null
			src.screen = null
			src.active1 = null
			src.active2 = null

		else if (href_list["login"])

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

			else if (istype(src.scan, /obj/item/card/id))
				src.active1 = null
				src.active2 = null

				if (src.check_access(src.scan))
					src.authenticated = src.scan.registered_name
					src.rank = src.scan.assignment
					src.screen = 1

		if (src.authenticated)

			if(href_list["screen"])
				src.screen = text2num(href_list["screen"])
				if(src.screen < 1)
					src.screen = 1

				src.active1 = null
				src.active2 = null

			if (href_list["del_all"])
				src.temp = text("Are you sure you wish to delete all records?<br>\n\t<A href='byond://?src=\ref[];temp=1;del_all2=1'>Yes</A><br>\n\t<A href='byond://?src=\ref[];temp=1'>No</A><br>", src, src)

			if (href_list["del_all2"])
				for(var/datum/data/record/R in data_core.medical)
					//R = null
					qdel(R)
					//Foreach goto(494)
				src.temp = "All records deleted."

			if (href_list["field"])
				var/a1 = src.active1
				var/a2 = src.active2
				switch(href_list["field"])
					if("fingerprint")
						if (istype(src.active1, /datum/data/record))
							var/t1 = sanitize(input("Please input fingerprint hash:", "Med. records", src.active1.fields["fingerprint"], null)  as text)
							if ((!( t1 ) || !( src.authenticated ) || usr.stat || usr.restrained() || (!in_range(src, usr) && (!issilicon(usr))) || src.active1 != a1))
								return
							src.active1.fields["fingerprint"] = t1
					if("sex")
						if (istype(src.active1, /datum/data/record))
							if (src.active1.fields["sex"] == "Male")
								src.active1.fields["sex"] = "Female"
							else
								src.active1.fields["sex"] = "Male"
					if("age")
						if (istype(src.active1, /datum/data/record))
							var/t1 = input("Please input age:", "Med. records", src.active1.fields["age"], null)  as num
							if ((!( t1 ) || !( src.authenticated ) || usr.stat || usr.restrained() || (!in_range(src, usr) && (!issilicon(usr))) || src.active1 != a1))
								return
							src.active1.fields["age"] = t1
					if("mi_dis")
						if (istype(src.active2, /datum/data/record))
							var/t1 = sanitize(input("Please input minor disabilities list:", "Med. records", src.active2.fields["mi_dis"], null)  as text)
							if ((!( t1 ) || !( src.authenticated ) || usr.stat || usr.restrained() || (!in_range(src, usr) && (!issilicon(usr))) || src.active2 != a2))
								return
							src.active2.fields["mi_dis"] = t1
					if("mi_dis_d")
						if (istype(src.active2, /datum/data/record))
							var/t1 = sanitize(input("Please summarize minor dis.:", "Med. records", src.active2.fields["mi_dis_d"], null)  as message)
							if ((!( t1 ) || !( src.authenticated ) || usr.stat || usr.restrained() || (!in_range(src, usr) && (!issilicon(usr))) || src.active2 != a2))
								return
							src.active2.fields["mi_dis_d"] = t1
					if("ma_dis")
						if (istype(src.active2, /datum/data/record))
							var/t1 = sanitize(input("Please input major diabilities list:", "Med. records", src.active2.fields["ma_dis"], null)  as text)
							if ((!( t1 ) || !( src.authenticated ) || usr.stat || usr.restrained() || (!in_range(src, usr) && (!issilicon(usr))) || src.active2 != a2))
								return
							src.active2.fields["ma_dis"] = t1
					if("ma_dis_d")
						if (istype(src.active2, /datum/data/record))
							var/t1 = sanitize(input("Please summarize major dis.:", "Med. records", src.active2.fields["ma_dis_d"], null)  as message)
							if ((!( t1 ) || !( src.authenticated ) || usr.stat || usr.restrained() || (!in_range(src, usr) && (!issilicon(usr))) || src.active2 != a2))
								return
							src.active2.fields["ma_dis_d"] = t1
					if("alg")
						if (istype(src.active2, /datum/data/record))
							var/t1 = sanitize(input("Please state allergies:", "Med. records", src.active2.fields["alg"], null)  as text)
							if ((!( t1 ) || !( src.authenticated ) || usr.stat || usr.restrained() || (!in_range(src, usr) && (!issilicon(usr))) || src.active2 != a2))
								return
							src.active2.fields["alg"] = t1
					if("alg_d")
						if (istype(src.active2, /datum/data/record))
							var/t1 = sanitize(input("Please summarize allergies:", "Med. records", src.active2.fields["alg_d"], null)  as message)
							if ((!( t1 ) || !( src.authenticated ) || usr.stat || usr.restrained() || (!in_range(src, usr) && (!issilicon(usr))) || src.active2 != a2))
								return
							src.active2.fields["alg_d"] = t1
					if("cdi")
						if (istype(src.active2, /datum/data/record))
							var/t1 = sanitize(input("Please state diseases:", "Med. records", src.active2.fields["cdi"], null)  as text)
							if ((!( t1 ) || !( src.authenticated ) || usr.stat || usr.restrained() || (!in_range(src, usr) && (!issilicon(usr))) || src.active2 != a2))
								return
							src.active2.fields["cdi"] = t1
					if("cdi_d")
						if (istype(src.active2, /datum/data/record))
							var/t1 = sanitize(input("Please summarize diseases:", "Med. records", src.active2.fields["cdi_d"], null)  as message)
							if ((!( t1 ) || !( src.authenticated ) || usr.stat || usr.restrained() || (!in_range(src, usr) && (!issilicon(usr))) || src.active2 != a2))
								return
							src.active2.fields["cdi_d"] = t1
					if("notes")
						if (istype(src.active2, /datum/data/record))
							var/t1 = sanitize(input("Please summarize notes:", "Med. records", html_decode(src.active2.fields["notes"]), null)  as message, extra = 0)
							if ((!( t1 ) || !( src.authenticated ) || usr.stat || usr.restrained() || (!in_range(src, usr) && (!issilicon(usr))) || src.active2 != a2))
								return
							src.active2.fields["notes"] = t1
					if("p_stat")
						if (istype(src.active1, /datum/data/record))
							src.temp = text("<B>Physical Condition:</B><BR>\n\t<A href='byond://?src=\ref[];temp=1;p_stat=deceased'>*Deceased*</A><BR>\n\t<A href='byond://?src=\ref[];temp=1;p_stat=ssd'>*SSD*</A><BR>\n\t<A href='byond://?src=\ref[];temp=1;p_stat=active'>Active</A><BR>\n\t<A href='byond://?src=\ref[];temp=1;p_stat=unfit'>Physically Unfit</A><BR>\n\t<A href='byond://?src=\ref[];temp=1;p_stat=disabled'>Disabled</A><BR>", src, src, src, src, src)
					if("m_stat")
						if (istype(src.active1, /datum/data/record))
							src.temp = text("<B>Mental Condition:</B><BR>\n\t<A href='byond://?src=\ref[];temp=1;m_stat=insane'>*Insane*</A><BR>\n\t<A href='byond://?src=\ref[];temp=1;m_stat=unstable'>*Unstable*</A><BR>\n\t<A href='byond://?src=\ref[];temp=1;m_stat=watch'>*Watch*</A><BR>\n\t<A href='byond://?src=\ref[];temp=1;m_stat=stable'>Stable</A><BR>", src, src, src, src)
					if("b_type")
						if (istype(src.active2, /datum/data/record))
							src.temp = text("<B>Blood Type:</B><BR>\n\t<A href='byond://?src=\ref[];temp=1;b_type=an'>A-</A> <A href='byond://?src=\ref[];temp=1;b_type=ap'>A+</A><BR>\n\t<A href='byond://?src=\ref[];temp=1;b_type=bn'>B-</A> <A href='byond://?src=\ref[];temp=1;b_type=bp'>B+</A><BR>\n\t<A href='byond://?src=\ref[];temp=1;b_type=abn'>AB-</A> <A href='byond://?src=\ref[];temp=1;b_type=abp'>AB+</A><BR>\n\t<A href='byond://?src=\ref[];temp=1;b_type=on'>O-</A> <A href='byond://?src=\ref[];temp=1;b_type=op'>O+</A><BR>", src, src, src, src, src, src, src, src)
					if("b_dna")
						if (istype(src.active2, /datum/data/record))
							var/t1 = sanitize(input("Please input DNA hash:", "Med. records", src.active2.fields["b_dna"], null)  as text)
							if ((!( t1 ) || !( src.authenticated ) || usr.stat || usr.restrained() || (!in_range(src, usr) && (!issilicon(usr))) || src.active2 != a2))
								return
							src.active2.fields["b_dna"] = t1
					else

			if (href_list["p_stat"])
				if (src.active1)
					switch(href_list["p_stat"])
						if("deceased")
							src.active1.fields["p_stat"] = "*Deceased*"
						if("ssd")
							src.active1.fields["p_stat"] = "*SSD*"
						if("active")
							src.active1.fields["p_stat"] = "Active"
						if("unfit")
							src.active1.fields["p_stat"] = "Physically Unfit"
						if("disabled")
							src.active1.fields["p_stat"] = "Disabled"
					if(PDA_Manifest.len)
						PDA_Manifest.Cut()

			if (href_list["m_stat"])
				if (src.active1)
					switch(href_list["m_stat"])
						if("insane")
							src.active1.fields["m_stat"] = "*Insane*"
						if("unstable")
							src.active1.fields["m_stat"] = "*Unstable*"
						if("watch")
							src.active1.fields["m_stat"] = "*Watch*"
						if("stable")
							src.active1.fields["m_stat"] = "Stable"


			if (href_list["b_type"])
				if (src.active2)
					switch(href_list["b_type"])
						if("an")
							src.active2.fields["b_type"] = "A-"
						if("bn")
							src.active2.fields["b_type"] = "B-"
						if("abn")
							src.active2.fields["b_type"] = "AB-"
						if("on")
							src.active2.fields["b_type"] = "O-"
						if("ap")
							src.active2.fields["b_type"] = "A+"
						if("bp")
							src.active2.fields["b_type"] = "B+"
						if("abp")
							src.active2.fields["b_type"] = "AB+"
						if("op")
							src.active2.fields["b_type"] = "O+"


			if (href_list["del_r"])
				if (src.active2)
					src.temp = text("Are you sure you wish to delete the record (Medical Portion Only)?<br>\n\t<A href='byond://?src=\ref[];temp=1;del_r2=1'>Yes</A><br>\n\t<A href='byond://?src=\ref[];temp=1'>No</A><br>", src, src)

			if (href_list["del_r2"])
				if (src.active2)
					//src.active2 = null
					qdel(src.active2)

			if (href_list["d_rec"])
				var/datum/data/record/R = locate(href_list["d_rec"])
				var/datum/data/record/M = locate(href_list["d_rec"])
				if (!( data_core.general.Find(R) ))
					src.temp = "Record Not Found!"
					return
				for(var/datum/data/record/E in data_core.medical)
					if ((E.fields["name"] == R.fields["name"] || E.fields["id"] == R.fields["id"]))
						M = E
					else
						//Foreach continue //goto(2540)
				src.active1 = R
				src.active2 = M
				src.screen = 4

			if (href_list["new"])
				if ((istype(src.active1, /datum/data/record) && !( istype(src.active2, /datum/data/record) )))
					var/datum/data/record/R = new /datum/data/record(  )
					R.fields["name"] = src.active1.fields["name"]
					R.fields["id"] = src.active1.fields["id"]
					R.name = text("Medical Record #[]", R.fields["id"])
					R.fields["b_type"] = "Unknown"
					R.fields["b_dna"] = "Unknown"
					R.fields["mi_dis"] = "None"
					R.fields["mi_dis_d"] = "No minor disabilities have been declared."
					R.fields["ma_dis"] = "None"
					R.fields["ma_dis_d"] = "No major disabilities have been diagnosed."
					R.fields["alg"] = "None"
					R.fields["alg_d"] = "No allergies have been detected in this patient."
					R.fields["cdi"] = "None"
					R.fields["cdi_d"] = "No diseases have been diagnosed at the moment."
					R.fields["notes"] = "No notes."
					data_core.medical += R
					src.active2 = R
					src.screen = 4

			if (href_list["add_c"])
				if (!( istype(src.active2, /datum/data/record) ))
					return
				var/a2 = src.active2
				var/t1 = sanitize(input("Add Comment:", "Med. records", null, null)  as message)
				if ((!( t1 ) || !( src.authenticated ) || usr.stat || usr.restrained() || (!in_range(src, usr) && (!issilicon(usr))) || src.active2 != a2))
					return
				var/counter = 1
				while(src.active2.fields[text("com_[]", counter)])
					counter++
				src.active2.fields[text("com_[counter]")] = text("Made by [authenticated] ([rank]) on [time2text(world.realtime, "DDD MMM DD")] [stationtime2text()], [CURRENT_SHIP_YEAR]<BR>[t1]")

			if (href_list["del_c"])
				if ((istype(src.active2, /datum/data/record) && src.active2.fields[text("com_[]", href_list["del_c"])]))
					src.active2.fields[text("com_[]", href_list["del_c"])] = "<B>Deleted</B>"

			if (href_list["search"])
				var/t1 = input("Search String: (Name, DNA, or ID)", "Med. records", null, null)  as text
				if ((!( t1 ) || usr.stat || !( src.authenticated ) || usr.restrained() || ((!in_range(src, usr)) && (!issilicon(usr)))))
					return
				src.active1 = null
				src.active2 = null
				t1 = lowertext(t1)
				for(var/datum/data/record/R in data_core.medical)
					if ((lowertext(R.fields["name"]) == t1 || t1 == lowertext(R.fields["id"]) || t1 == lowertext(R.fields["b_dna"])))
						src.active2 = R
					else
						//Foreach continue //goto(3229)
				if (!( src.active2 ))
					src.temp = text("Could not locate record [].", t1)
				else
					for(var/datum/data/record/E in data_core.general)
						if ((E.fields["name"] == src.active2.fields["name"] || E.fields["id"] == src.active2.fields["id"]))
							src.active1 = E
						else
							//Foreach continue //goto(3334)
					src.screen = 4

			if (href_list["print_p"])
				if (!( src.printing ))
					src.printing = 1
					var/datum/data/record/record1
					var/datum/data/record/record2
					if ((istype(src.active1, /datum/data/record) && data_core.general.Find(src.active1)))
						record1 = active1
					if ((istype(src.active2, /datum/data/record) && data_core.medical.Find(src.active2)))
						record2 = active2
					sleep(50)
					var/obj/item/paper/P = new /obj/item/paper( src.loc )
					P.info = "<CENTER><B>Medical Record</B></CENTER><BR>"
					if (record1)
						P.info += text("Name: [] ID: []<BR>\nSex: []<BR>\nAge: []<BR>\nFingerprint: []<BR>\nPhysical Status: []<BR>\nMental Status: []<BR>", record1.fields["name"], record1.fields["id"], record1.fields["sex"], record1.fields["age"], record1.fields["fingerprint"], record1.fields["p_stat"], record1.fields["m_stat"])
						P.name = text("Medical Record ([])", record1.fields["name"])
					else
						P.info += "<B>General Record Lost!</B><BR>"
						P.name = "Medical Record"
					if (record2)
						P.info += text("<BR>\n<CENTER><B>Medical Data</B></CENTER><BR>\nBlood Type: []<BR>\nDNA: []<BR>\n<BR>\nMinor Disabilities: []<BR>\nDetails: []<BR>\n<BR>\nMajor Disabilities: []<BR>\nDetails: []<BR>\n<BR>\nAllergies: []<BR>\nDetails: []<BR>\n<BR>\nCurrent Diseases: [] (per disease info placed in log/comment section)<BR>\nDetails: []<BR>\n<BR>\nImportant Notes:<BR>\n\t[]<BR>\n<BR>\n<CENTER><B>Comments/Log</B></CENTER><BR>", record2.fields["b_type"], record2.fields["b_dna"], record2.fields["mi_dis"], record2.fields["mi_dis_d"], record2.fields["ma_dis"], record2.fields["ma_dis_d"], record2.fields["alg"], record2.fields["alg_d"], record2.fields["cdi"], record2.fields["cdi_d"], decode(record2.fields["notes"]))
						var/counter = 1
						while(record2.fields[text("com_[]", counter)])
							P.info += text("[]<BR>", record2.fields[text("com_[]", counter)])
							counter++
					else
						P.info += "<B>Medical Record Lost!</B><BR>"
					P.info += "</TT>"
					src.printing = null

	src.add_fingerprint(usr)
	src.updateUsrDialog()
	return

/obj/machinery/computer/med_data/emp_act(severity)
	if(stat & (BROKEN|NOPOWER))
		..(severity)
		return

	for(var/datum/data/record/R in data_core.medical)
		if(prob(10/severity))
			switch(rand(1,6))
				if(1)
					R.fields["name"] = "[pick(pick(GLOB.first_names_male), pick(GLOB.first_names_female))] [pick(GLOB.last_names)]"
				if(2)
					R.fields["sex"]	= pick("Male", "Female")
				if(3)
					R.fields["age"] = rand(5, 85)
				if(4)
					R.fields["b_type"] = pick("A-", "B-", "AB-", "O-", "A+", "B+", "AB+", "O+")
				if(5)
					R.fields["p_stat"] = pick("*SSD*", "Active", "Physically Unfit", "Disabled")
					if(PDA_Manifest.len)
						PDA_Manifest.Cut()
				if(6)
					R.fields["m_stat"] = pick("*Insane*", "*Unstable*", "*Watch*", "Stable")
			continue

		else if(prob(1))
			qdel(R)
			continue

	..(severity)


/obj/machinery/computer/med_data/laptop
	name = "Medical Laptop"
	desc = "A cheap laptop."
	icon_state = "laptop"
	icon_keyboard = "laptop_key"
	icon_screen = "medlaptop"
	CheckFaceFlag = 0
