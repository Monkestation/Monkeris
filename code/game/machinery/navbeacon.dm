// Navigation beacon for AI robots
// Functions as a transponder: looks for incoming signal matching


var/global/list/navbeacons			// no I don't like putting this in, but it will do for now

/obj/machinery/navbeacon

	icon = 'icons/obj/objects.dmi'
	icon_state = "navbeacon0-f"
	name = "navigation beacon"
	desc = "A radio beacon used for bot navigation."
	level = BELOW_PLATING_LEVEL		// underfloor
	layer = LOW_OBJ_LAYER
	anchored = TRUE

	var/open = 0		// true if cover is open
	var/locked = 1		// true if controls are locked
	var/freq = 1445		// radio frequency
	var/location = ""	// location response text
	var/list/codes		// assoc. list of transponder codes
	var/codes_txt = ""	// codes as set on map: "tag1;tag2" or "tag1=value;tag2=value"

	req_access = list(access_engine)

/obj/machinery/navbeacon/New()
	..()

	set_codes()

	var/turf/T = loc
	hide(!T.is_plating())

	// add beacon to MULE bot beacon list
	if(freq == 1400)
		if(!navbeacons)
			navbeacons = new()
		navbeacons += src


	spawn(5)	// must wait for map loading to finish
		SSradio.add_object(src, freq, RADIO_NAVBEACONS)

// set the transponder codes assoc list from codes_txt
/obj/machinery/navbeacon/proc/set_codes()
	if(!codes_txt)
		return

	codes = new()

	var/list/entries = splittext(codes_txt, ";")	// entries are separated by semicolons

	for(var/e in entries)
		var/index = findtext(e, "=")		// format is "key=value"
		if(index)
			var/key = copytext(e, 1, index)
			var/val = copytext(e, index + length(e[index]))
			codes[key] = val
		else
			codes[e] = "1"


// called when turf state changes
// hide the object if turf is intact
/obj/machinery/navbeacon/hide(intact)
	invisibility = intact ? 101 : 0
	updateicon()

// update the icon_state
/obj/machinery/navbeacon/proc/updateicon()
	var/state="navbeacon[open]"

	if(invisibility)
		icon_state = "[state]-f"	// if invisible, set icon to faded version
									// in case revealed by T-scanner
	else
		icon_state = "[state]"


// look for a signal of the form "findbeacon=X"
// where X is any
// or the location
// or one of the set transponder keys
// if found, return a signal
/obj/machinery/navbeacon/receive_signal(datum/signal/signal)

	var/request = signal.data["findbeacon"]
	if(request && ((request in codes) || request == "any" || request == location))
		spawn(1)
			post_signal()

// return a signal giving location and transponder codes

/obj/machinery/navbeacon/proc/post_signal()

	var/datum/radio_frequency/frequency = SSradio.return_frequency(freq)

	if(!frequency) return

	var/datum/signal/signal = new()
	signal.source = src
	signal.transmission_method = 1
	signal.data["beacon"] = location

	for(var/key in codes)
		signal.data[key] = codes[key]

	frequency.post_signal(src, signal, filter = RADIO_NAVBEACONS)


/obj/machinery/navbeacon/attackby(obj/item/I, mob/user)
	var/turf/T = loc
	if(!T.is_plating())
		return		// prevent intraction when T-scanner revealed

	if(QUALITY_SCREW_DRIVING in I.tool_qualities)
		if(I.use_tool(user, src, WORKTIME_FAST, QUALITY_SCREW_DRIVING, FAILCHANCE_EASY, required_stat = STAT_MEC))
			open = !open

			user.visible_message("[user] [open ? "opens" : "closes"] the beacon's cover.", "You [open ? "open" : "close"] the beacon's cover.")

			updateicon()

	else if(I.GetIdCard())
		if(open)
			if (src.allowed(user))
				src.locked = !src.locked
				to_chat(user, "Controls are now [src.locked ? "locked." : "unlocked."]")
			else
				to_chat(user, span_warning("Access denied."))
			updateDialog()
		else
			to_chat(user, "You must open the cover first!")
	return

/obj/machinery/navbeacon/attack_ai(mob/user)
	interact(user, 1)

/obj/machinery/navbeacon/attack_hand(mob/user)

	if(!user.IsAdvancedToolUser())
		return 0

	interact(user, 0)

/obj/machinery/navbeacon/interact(mob/user, ai = 0)
	var/turf/T = loc
	if(!T.is_plating())
		return		// prevent intraction when T-scanner revealed

	if(!open && !ai)	// can't alter controls if not open, unless you're an AI
		to_chat(user, "The beacon's control cover is closed.")
		return


	var/t

	if(locked && !ai)
		t = {"<TT><B>Navigation Beacon</B><HR><BR>
<i>(swipe card to unlock controls)</i><BR>
Frequency: [format_frequency(freq)]<BR><HR>
Location: [location ? location : "(none)"]</A><BR>
Transponder Codes:<UL>"}

		for(var/key in codes)
			t += "<LI>[key] ... [codes[key]]"
		t+= "<UL></TT>"

	else

		t = {"<TT><B>Navigation Beacon</B><HR><BR>
<i>(swipe card to lock controls)</i><BR>
Frequency:
<A href='byond://?src=\ref[src];freq=-10'>-</A>
<A href='byond://?src=\ref[src];freq=-2'>-</A>
[format_frequency(freq)]
<A href='byond://?src=\ref[src];freq=2'>+</A>
<A href='byond://?src=\ref[src];freq=10'>+</A><BR>
<HR>
Location: <A href='byond://?src=\ref[src];locedit=1'>[location ? location : "(none)"]</A><BR>
Transponder Codes:<UL>"}

		for(var/key in codes)
			t += "<LI>[key] ... [codes[key]]"
			t += " <small><A href='byond://?src=\ref[src];edit=1;code=[key]'>(edit)</A>"
			t += " <A href='byond://?src=\ref[src];delete=1;code=[key]'>(delete)</A></small><BR>"
		t += "<small><A href='byond://?src=\ref[src];add=1;'>(add new)</A></small><BR>"
		t+= "<UL></TT>"

	user << browse(HTML_SKELETON_TITLE("Navigation Beacon", t), "window=navbeacon")
	onclose(user, "navbeacon")
	return

/obj/machinery/navbeacon/Topic(href, href_list)
	..()
	if (usr.stat)
		return
	if ((in_range(src, usr) && istype(src.loc, /turf)) || (issilicon(usr)))
		if(open && !locked)
			usr.set_machine(src)

			if (href_list["freq"])
				freq = sanitize_frequency(freq + text2num(href_list["freq"]))
				updateDialog()

			else if(href_list["locedit"])
				var/newloc = stripped_input(usr, "Enter New Location", "Navigation Beacon", location, MAX_MESSAGE_LEN)
				if(newloc)
					location = newloc
					updateDialog()

			else if(href_list["edit"])
				var/codekey = href_list["code"]

				var/newkey = input("Enter Transponder Code Key", "Navigation Beacon", codekey) as text|null
				if(!newkey)
					return

				var/codeval = codes[codekey]
				var/newval = input("Enter Transponder Code Value", "Navigation Beacon", codeval) as text|null
				if(!newval)
					newval = codekey
					return

				codes.Remove(codekey)
				codes[newkey] = newval

				updateDialog()

			else if(href_list["delete"])
				var/codekey = href_list["code"]
				codes.Remove(codekey)
				updateDialog()

			else if(href_list["add"])

				var/newkey = input("Enter New Transponder Code Key", "Navigation Beacon") as text|null
				if(!newkey)
					return

				var/newval = input("Enter New Transponder Code Value", "Navigation Beacon") as text|null
				if(!newval)
					newval = "1"
					return

				if(!codes)
					codes = new()

				codes[newkey] = newval

				updateDialog()

/obj/machinery/navbeacon/Destroy()
	navbeacons.Remove(src)
	SSradio.remove_object(src, freq)
	. = ..()
