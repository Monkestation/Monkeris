// Wire datums. Created by Giacomand.
// Was created to replace a horrible case of copy and pasted code with no care for maintability.
// Goodbye Door wires, Cyborg wires, Vending Machine wires, Autolathe wires
// Protolathe wires, APC wires and Camera wires!

#define MAX_FLAG 65535

var/list/same_wires = list()
// 14 colours, if you're adding more than 14 wires then add more colours here
GLOBAL_LIST_INIT(wire_colours, list("red", "blue", "green", "darkred", "orange", "brown", "gold", "gray", "cyan", "navy", "purple", "pink", "black", "yellow"))

/datum/wires

	var/random = 1 // Will the wires be different for every single instance.
	var/atom/holder = null // The holder
	var/holder_type = null // The holder type; used to make sure that the holder is the correct type.
	var/wire_count = 0 // Max is 16
	var/wires_status = 0 // BITFLAG OF WIRES

	var/list/wires = list()
	var/list/signallers = list()

	var/table_options = " align='center'"
	var/row_options1 = " width='80px'"
	var/row_options2 = " width='260px'"
	var/window_x = 370
	var/window_y = 470

	var/list/descriptions // Descriptions of wires (datum/wire_description) for use with examining.
	var/list/wire_log = list() // A log for admin use of what happened to these wires.

/datum/wires/New(atom/holder)
	..()
	src.holder = holder
	if(!istype(holder, holder_type))
		CRASH("Our holder is null/the wrong type!")

	// Generate new wires
	if(random)
		GenerateWires()

	// Get the same wires
	else
		// We don't have any wires to copy yet, generate some and then copy it.
		if(!same_wires[holder_type])
			GenerateWires()
			same_wires[holder_type] = src.wires.Copy()
		else
			var/list/wires = same_wires[holder_type]
			src.wires = wires // Reference the wires list.

/datum/wires/Destroy()
	holder = null
	return ..()

/datum/wires/proc/GenerateWires()
	var/list/colours_to_pick = GLOB?.wire_colours?.Copy() // Get a copy, not a reference.
	if (!colours_to_pick)
		return
	var/list/indexes_to_pick = list()
	//Generate our indexes
	for(var/i = 1; i < MAX_FLAG && i < (1 << wire_count); i += i)
		indexes_to_pick += i
	colours_to_pick.len = wire_count // Downsize it to our specifications.

	while(colours_to_pick.len && indexes_to_pick.len)
		// Pick and remove a colour
		var/colour = pick_n_take(colours_to_pick)

		// Pick and remove an index
		var/index = pick_n_take(indexes_to_pick)

		src.wires[colour] = index
		//wires = shuffle(wires)

/datum/wires/proc/examine(index, mob/user)
	. = "You aren't sure what this wire does."
	var/mec_stat = user.stats.getStat(STAT_MEC)

	var/datum/wire_description/wd = get_description(index)
	if(!wd)
		return
	if(wd.skill_level > mec_stat)
		return
	return wd.description

/datum/wires/proc/get_description(index)
	for(var/datum/wire_description/desc in descriptions)
		if(desc.index == index)
			return desc

/datum/wires/proc/add_log_entry(mob/user, message)
	wire_log += "\[[time_stamp()]\] [user.name] ([user.ckey]) [message]"

/datum/wires/proc/Interact(mob/living/user)

	var/html = null
	if(holder && CanUse(user))
		html = GetInteractWindow(user)
	if(html)
		user.set_machine(holder)
	else
		user.unset_machine()
		// No content means no window.
		user << browse(null, "window=wires")
		return

	var/datum/browser/popup = new(user, "wires", holder.name, window_x, window_y)
	popup.set_content(html)
	popup.open()

/datum/wires/proc/GetInteractWindow(mob/living/user)
	var/user_skill
	var/html = "<div class='block'>"
	html += "<h3>Exposed Wires</h3>"
	html += "<table[table_options]>"

	if(!user)
		user = usr

	if(istype(user))
		user_skill = user.stats.getStat(STAT_MEC)

	for(var/colour in wires)
		html += "<tr>"
		var/datum/wire_description/wd = get_description(GetIndex(colour))
		if(wd)
			if(user.stats && user.stats.getPerk(PERK_TECHNOMANCER) || user_skill && (wd.skill_level <= user_skill))
				html += "<td[row_options1]><font color='[colour]'>[wd.description]</font></td>"
			else
				html += "<td[row_options1]><font color='[colour]'>[capitalize(colour)]</font></td>"
		else
			html += "<td[row_options1]><font color='[colour]'>[capitalize(colour)]</font></td>"
		html += "<td[row_options2]>"
		html += "<A href='byond://?src=\ref[src];action=1;cut=[colour]'>[IsColourCut(colour) ? "Mend" :  "Cut"]</A>"
		html += " <A href='byond://?src=\ref[src];action=1;pulse=[colour]'>Pulse</A>"
		html += " <A href='byond://?src=\ref[src];action=1;attach=[colour]'>[IsAttached(colour) ? "Detach" : "Attach"] Signaller</A>"
	html += "</table>"
	html += "</div>"

	return html

/datum/wires/Topic(href, href_list)
	..()
	if(in_range(holder, usr) && isliving(usr))

		var/mob/living/L = usr
		if(CanUse(L) && href_list["action"])
			var/obj/item/I = L.get_active_held_item()
			if(!ismech(L.loc))
				holder.add_hiddenprint(L)
			else
				var/mob/living/exosuit/mech = L.loc
				I = mech.get_active_held_item()
			if(href_list["cut"]) // Toggles the cut/mend status
				if (!istype(I))
					return
				var/tool_type = null
				if(QUALITY_CUTTING in I.tool_qualities)
					tool_type = QUALITY_CUTTING
				if(QUALITY_WIRE_CUTTING in I.tool_qualities)
					tool_type = QUALITY_WIRE_CUTTING
				if(tool_type)
					if(I.use_tool(L, holder, WORKTIME_INSTANT, tool_type, FAILCHANCE_ZERO))
						var/colour = href_list["cut"]
						add_log_entry(L, "has [IsColourCut(colour) ? "mended" : "cut"] the <font color='[colour]'>[capitalize(colour)]</font> wire")
						CutWireColour(colour)
				else
					to_chat(L, span_warning("You need something that can cut!"))

			else if(href_list["pulse"])
				if (!istype(I))
					return
				if(I.get_tool_type(usr, list(QUALITY_PULSING), holder))
					if(I.use_tool(L, holder, WORKTIME_INSTANT, QUALITY_PULSING, FAILCHANCE_ZERO))
						var/colour = href_list["pulse"]
						add_log_entry(L, "has pulsed the <font color='[colour]'>[capitalize(colour)]</font> wire")
						PulseColour(colour)
				else
					to_chat(L, span_warning("You need a multitool!"))

			else if(href_list["attach"])
				var/colour = href_list["attach"]
				// Detach
				if(IsAttached(colour))
					var/obj/item/O = Detach(colour)
					add_log_entry(L, "has detached [O] from the <font color='[colour]'>[capitalize(colour)]</font> wire")
					if(O)
						L.put_in_hands(O)

				// Attach
				else
					if(istype(I, /obj/item/device/assembly/signaler) || istype(I, /obj/item/implant/carrion_spider/spark))
						L.drop_item()
						add_log_entry(L, "has attached [I] to the <font color='[colour]'>[capitalize(colour)]</font> wire")
						Attach(colour, I)
					else
						to_chat(L, span_warning("You need a remote signaller!"))

		// Update Window
			Interact(usr)

	if(href_list["close"])
		usr << browse(null, "window=wires")
		usr.unset_machine(holder)

//
// Overridable Procs
//

// Called when wires cut/mended.
/datum/wires/proc/UpdateCut(index, mended)
	return

// Called when wire pulsed. Add code here.
/datum/wires/proc/UpdatePulsed(index)
	return

/datum/wires/proc/CanUse(mob/living/L)
	return 1

// Example of use:
/*

var/const/BOLTED= 1
var/const/SHOCKED = 2
var/const/SAFETY = 4
var/const/POWER = 8

/datum/wires/door/UpdateCut(index, mended)
	var/obj/machinery/door/airlock/A = holder
	switch(index)
		if(BOLTED)
		if(!mended)
			A.bolt()
	if(SHOCKED)
		A.shock()
	if(SAFETY )
		A.safety()

*/


//
// Helper Procs
//

/datum/wires/proc/PulseColour(colour)
	PulseIndex(GetIndex(colour))

/datum/wires/proc/PulseIndex(index)
	if(IsIndexCut(index))
		return
	UpdatePulsed(index)

/datum/wires/proc/GetIndex(colour)
	if(wires[colour])
		var/index = wires[colour]
		return index
	else
		CRASH("[colour] is not a key in wires.")

//
// Is Index/Colour Cut procs
//

/datum/wires/proc/IsColourCut(colour)
	var/index = GetIndex(colour)
	return IsIndexCut(index)

/datum/wires/proc/IsIndexCut(index)
	return (index & wires_status)

//
// Signaller Procs
//

/datum/wires/proc/IsAttached(colour)
	if(signallers[colour])
		return 1
	return 0

/datum/wires/proc/GetAttached(colour)
	if(signallers[colour])
		return signallers[colour]
	return null

/datum/wires/proc/Attach(colour, obj/item/device/assembly/signaler/S)
    var/obj/item/implant/carrion_spider/spark/I = S
    if(istype(S) || istype(I))
        if(!IsAttached(colour))
            signallers[colour] = S
            S.loc = holder
            S.connected = src
            return S

/datum/wires/proc/Detach(colour)
	if(colour)
		var/obj/item/device/assembly/signaler/S = GetAttached(colour)
		var/obj/item/implant/carrion_spider/spark/I = S
		if(istype(S) || istype(I))
			signallers -= colour
			S.connected = null
			S.loc = holder.loc
			return S


/datum/wires/proc/Pulse(obj/item/device/assembly/signaler/S)
	var/obj/item/implant/carrion_spider/spark/I = S
	if(istype(S) || istype(I))
		for(var/colour in signallers)
			if(S == signallers[colour])
				PulseColour(colour)
				break


//
// Cut Wire Colour/Index procs
//

/datum/wires/proc/CutWireColour(colour)
	var/index = GetIndex(colour)
	CutWireIndex(index)

/datum/wires/proc/CutWireIndex(index)
	if(IsIndexCut(index))
		wires_status &= ~index
		UpdateCut(index, 1)
	else
		wires_status |= index
		UpdateCut(index, 0)

/datum/wires/proc/RandomCut()
	var/r = rand(1, wires.len)
	CutWireIndex(r)

/datum/wires/proc/RandomCutAll(probability = 10)
	for(var/i = 1; i < MAX_FLAG && i < (1 << wire_count); i += i)
		if(prob(probability))
			CutWireIndex(i)

/datum/wires/proc/CutAll()
	for(var/i = 1; i < MAX_FLAG && i < (1 << wire_count); i += i)
		CutWireIndex(i)

/datum/wires/proc/IsAllCut()
	if(wires_status == (1 << wire_count) - 1)
		return 1
	return 0

/datum/wires/proc/MendAll()
	for(var/i = 1; i < MAX_FLAG && i < (1 << wire_count); i += i)
		if(IsIndexCut(i))
			CutWireIndex(i)

//
//Shuffle and Mend
//

/datum/wires/proc/Shuffle()
	wires_status = 0
	GenerateWires()
