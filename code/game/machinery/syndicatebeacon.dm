//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:31

//  Beacon randomly spawns in space
//	When a non-contractor (no special role in /mind) uses it, he is given the choice to become a contractor
//	If he accepts there is a random chance he will be accepted, rejected, or rejected and killed
//	Bringing certain items can help improve the chance to become a contractor


/obj/machinery/syndicate_beacon
	name = "ominous beacon"
	desc = "This looks suspicious..."
	icon = 'icons/obj/device.dmi'
	icon_state = "syndbeacon"

	anchored = TRUE
	density = TRUE
	layer = BELOW_MOB_LAYER //so people can't hide it and it's REALLY OBVIOUS

	var/temptext = ""
	var/selfdestructing = 0
	var/charges = 1

/obj/machinery/syndicate_beacon/attack_hand(mob/user)
	usr.set_machine(src)
	var/dat = "<font color=#005500><i>Scanning [pick("retina pattern", "voice print", "fingerprints", "dna sequence")]...<br>Identity confirmed,<br></i></font>"
	if(ishuman(user) || isAI(user))
		if(is_special_character(user) > LIMITED_ANTAG)
			dat += "<font color=#07700><i>Operative record found. Greetings, Agent [user.name].</i></font><br>"
		else if(charges < 1)
			dat += "<TT>Connection severed.</TT><BR>"
		else
			var/honorific = "Mr."
			if(user.gender == FEMALE)
				honorific = "Ms."
			dat += "<font color=red><i>Identity not found in operative database. What can the Syndicate do for you today, [honorific] [user.name]?</i></font><br>"
			if(!selfdestructing)
				dat += "<br><br><A href='byond://?src=\ref[src];becontractor=1;contractormob=\ref[user]'>\"[pick("I want to switch teams.", "I want to work for you.", "Let me join you.", "I can be of use to you.", "You want me working for you, and here's why...", "Give me an objective.", "How's the 401k over at the Syndicate?")]\"</A><BR>"
	dat += temptext
	user << browse(HTML_SKELETON_TITLE("Syndicate Beacon", dat), "window=syndbeacon")
	onclose(user, "syndbeacon")

/obj/machinery/syndicate_beacon/Topic(href, href_list)
	if(..())
		return
	if(href_list["becontractor"])
		if(charges < 1)
			src.updateUsrDialog()
			return
		var/mob/M = locate(href_list["contractormob"])
		if(M.mind.antagonist.len || jobban_isbanned(M, "Syndicate"))
			temptext = "<i>We have no need for you at this time. Have a pleasant day.</i><br>"
			src.updateUsrDialog()
			return
		charges -= 1
		switch(rand(1,2))
			if(1)
				temptext = "<font color=red><i><b>Double-crosser. You planned to betray us from the start. Allow us to repay the favor in kind.</b></i></font>"
				src.updateUsrDialog()
				spawn(rand(50,200)) selfdestruct()
				return
		if(ishuman(M))
			var/mob/living/carbon/human/N = M
			M << "<B>You have joined the ranks of the Syndicate and become a contractor to the station!</B>"
			contractors.add_antagonist(N.mind)
			contractors.equip(N)
			message_admins("[N]/([N.ckey]) has accepted a contractor objective from a syndicate beacon.")


	src.updateUsrDialog()
	return


/obj/machinery/syndicate_beacon/proc/selfdestruct()
	selfdestructing = 1
	spawn() explosion(get_turf(src), 600,100)

////////////////////////////////////////
//Singularity beacon
////////////////////////////////////////
/obj/machinery/power/singularity_beacon
	name = "ominous beacon"
	desc = "This looks suspicious..."
	icon = 'icons/obj/singularity.dmi'
	icon_state = "beacon"

	anchored = FALSE
	density = TRUE
	layer = LOW_OBJ_LAYER
	stat = 0

	var/active = 0
	var/icontype = "beacon"


/obj/machinery/power/singularity_beacon/proc/Activate(mob/user = null)
	if(surplus() < 1500)
		if(user) user << span_notice("The connected wire doesn't have enough current.")
		return
	for(var/obj/singularity/singulo in world)
		if(singulo.z == z)
			singulo.target = src
	icon_state = "[icontype]1"
	active = 1
	machines |= src
	if(user)
		user << span_notice("You activate the beacon.")


/obj/machinery/power/singularity_beacon/proc/Deactivate(mob/user = null)
	for(var/obj/singularity/singulo in world)
		if(singulo.target == src)
			singulo.target = null
	icon_state = "[icontype]0"
	active = 0
	if(user)
		user << span_notice("You deactivate the beacon.")


/obj/machinery/power/singularity_beacon/attack_ai(mob/user as mob)
	return


/obj/machinery/power/singularity_beacon/attack_hand(mob/user as mob)
	if(anchored)
		return active ? Deactivate(user) : Activate(user)
	else
		user << span_danger("You need to screw the beacon to the floor first!")
		return


/obj/machinery/power/singularity_beacon/attackby(obj/item/W as obj, mob/user as mob)
	if(istype(W,/obj/item/tool/screwdriver))
		if(active)
			user << span_danger("You need to deactivate the beacon first!")
			return

		if(anchored)
			anchored = FALSE
			user << span_notice("You unscrew the beacon from the floor.")
			disconnect_from_network()
			return
		else
			if(!connect_to_network())
				user << "This device must be placed over an exposed cable."
				return
			anchored = TRUE
			user << span_notice("You screw the beacon to the floor and attach the cable.")
			return
	..()
	return


/obj/machinery/power/singularity_beacon/Destroy()
	if(active)
		Deactivate()
	. = ..()

//stealth direct power usage
/obj/machinery/power/singularity_beacon/process()
	if(!active)
		return PROCESS_KILL
	else
		if(draw_power(1500) < 1500)
			Deactivate()


/obj/machinery/power/singularity_beacon/syndicate
	icontype = "beaconsynd"
	icon_state = "beaconsynd0"
