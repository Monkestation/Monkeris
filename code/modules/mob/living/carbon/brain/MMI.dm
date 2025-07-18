//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:32

/obj/item/device/mmi/digital/New()
	brainmob = new(src)
	brainmob.stat = CONSCIOUS
	brainmob.add_language(LANGUAGE_ROBOT)
	brainmob.container = src
	brainmob.silent = 0
	..()

/obj/item/device/mmi/digital/transfer_identity(mob/living/carbon/H)
	brainmob.b_type = H.b_type
	brainmob.dna_trace = H.dna_trace
	brainmob.fingers_trace = H.fingers_trace
	brainmob.timeofhostdeath = H.timeofdeath
	brainmob.stat = 0
	if(H.mind)
		H.mind.transfer_to(brainmob)
	return

/obj/item/device/mmi
	name = "man-machine interface"
	desc = "The Warrior's bland acronym, MMI, obscures the true horror of this monstrosity."
	description_info = "Brains can be inserted by clicking on it. Brains can be removed by swiping a ID with roboticist access and clicking with an empty hand."
	icon = 'icons/obj/assemblies.dmi'
	icon_state = "mmi_empty"
	w_class = ITEM_SIZE_NORMAL
	origin_tech = list(TECH_BIO = 3)
	matter = list(MATERIAL_STEEL = 5, MATERIAL_GLASS = 3)
	req_access = list(access_robotics)

	//Revised. Brainmob is now contained directly within object of transfer. MMI in this case.

	var/locked = 0
	var/mob/living/carbon/brain/brainmob = null//The current occupant.
	var/obj/item/organ/internal/vital/brain/brainobj = null	//The current brain organ.

/obj/item/device/mmi/attackby(obj/item/O as obj, mob/user as mob)
	if(istype(O,/obj/item/organ/internal/vital/brain) && !brainmob) //Time to stick a brain in it --NEO

		var/obj/item/organ/internal/vital/brain/B = O
		if(B.health <= 0)
			to_chat(user, span_red("That brain is well and truly dead."))
			return
		else if(!B.brainmob)
			to_chat(user, span_red("You aren't sure where this brain came from, but you're pretty sure it's a useless brain."))
			return
		var/mob/living/carbon/brain/BM = B.brainmob
		if(!BM.client)
			for(var/mob/observer/ghost/G in GLOB.player_list)
				if(G.can_reenter_corpse && G.mind == BM.mind)
					G.reenter_corpse()
					break
			if(!BM.client)
				to_chat(user, span_warning("\The [src] indicates that \the [B] is unresponsive."))
				return

		for(var/mob/V in viewers(get_turf(src)))
			V.show_message(span_blue("[user] sticks \a [O] into \the [src]."))

		brainmob = B.brainmob
		brainmob.loc = src
		brainmob.container = src
		brainmob.stat = 0
		GLOB.dead_mob_list -= brainmob//Update dem lists
		GLOB.living_mob_list += brainmob

		user.drop_item()
		brainobj = O
		brainobj.loc = src

		name = "Man-Machine Interface: [brainmob.real_name]"
		icon_state = "mmi_full"

		locked = 1



		return

	if((istype(O,/obj/item/card/id)||istype(O,/obj/item/modular_computer/pda)) && brainmob)
		if(allowed(user))
			locked = !locked
			to_chat(user, span_blue("You [locked ? "lock" : "unlock"] the brain holder."))
		else
			to_chat(user, span_red("Access denied."))
		return
	if(brainmob)
		O.attack(brainmob, user)//Oh noooeeeee
		return
	..()

	//TODO: ORGAN REMOVAL UPDATE. Make the brain remain in the MMI so it doesn't lose organ data.
/obj/item/device/mmi/attack_self(mob/user as mob)
	if(!brainmob)
		to_chat(user, span_red("You upend the MMI, but there's nothing in it."))
	else if(locked)
		to_chat(user, span_red("You upend the MMI, but the brain is clamped into place."))
	else
		to_chat(user, span_blue("You upend the MMI, spilling the brain onto the floor."))
		var/obj/item/organ/internal/vital/brain/brain
		if (brainobj)	//Pull brain organ out of MMI.
			brainobj.loc = user.loc
			brain = brainobj
			brainobj = null
		else	//Or make a new one if empty.
			brain = new(user.loc)
		brainmob.container = null//Reset brainmob mmi var.
		brainmob.loc = brain//Throw mob into brain.
		GLOB.living_mob_list -= brainmob//Get outta here
		brain.brainmob = brainmob//Set the brain to use the brainmob
		brainmob = null//Set mmi brainmob var to null

		icon_state = "mmi_empty"
		name = "Man-Machine Interface"

/obj/item/device/mmi/proc/transfer_identity(mob/living/carbon/human/H)//Same deal as the regular brain proc. Used for human-->robot people.
	brainmob = new(src)
	brainmob.name = H.real_name
	brainmob.real_name = H.real_name
	brainmob.b_type = H.b_type
	brainmob.dna_trace = H.dna_trace
	brainmob.fingers_trace = H.fingers_trace
	brainmob.container = src

	name = "Man-Machine Interface: [brainmob.real_name]"
	icon_state = "mmi_full"
	locked = 1
	return

/obj/item/device/mmi/relaymove(mob/user, direction)
	if(user.stat || user.stunned)
		return
	var/obj/item/rig/rig = src.get_rig()
	if(rig)
		rig.forced_move(direction, user)

/obj/item/device/mmi/Destroy()
	if(isrobot(loc))
		var/mob/living/silicon/robot/borg = loc
		borg.mmi = null
	if(brainmob)
		qdel(brainmob)
		brainmob = null
	. = ..()

/obj/item/device/mmi/radio_enabled
	name = "radio-enabled man-machine interface"
	desc = "The Warrior's bland acronym, MMI, obscures the true horror of this monstrosity. This one comes with a built-in radio."
	origin_tech = list(TECH_BIO = 4)

	var/obj/item/device/radio/radio = null//Let's give it a radio.

/obj/item/device/mmi/radio_enabled/New()
	. = ..()
	radio = new(src)//Spawns a radio inside the MMI.
	radio.broadcasting = 1//So it's broadcasting from the start.

//Allows the brain to toggle the radio functions.
/obj/item/device/mmi/radio_enabled/verb/Toggle_Broadcasting()
	set name = "Toggle Broadcasting"
	set desc = "Toggle broadcasting channel on or off."
	set category = "MMI"
	set src = usr.loc//In user location, or in MMI in this case.
	set popup_menu = 0//Will not appear when right clicking.

	if(brainmob.stat)//Only the brainmob will trigger these so no further check is necessary.
		to_chat(brainmob, "Can't do that while incapacitated or dead.")

	radio.broadcasting = radio.broadcasting==1 ? 0 : 1
	to_chat(brainmob, span_blue("Radio is [radio.broadcasting==1 ? "now" : "no longer"] broadcasting."))

/obj/item/device/mmi/radio_enabled/verb/Toggle_Listening()
	set name = "Toggle Listening"
	set desc = "Toggle listening channel on or off."
	set category = "MMI"
	set src = usr.loc
	set popup_menu = 0

	if(brainmob.stat)
		to_chat(brainmob, "Can't do that while incapacitated or dead.")

	radio.listening = radio.listening==1 ? 0 : 1
	to_chat(brainmob, span_blue("Radio is [radio.listening==1 ? "now" : "no longer"] receiving broadcast."))

/obj/item/device/mmi/emp_act(severity)
	if(!brainmob)
		return
	else
		switch(severity)
			if(1)
				brainmob.emp_damage += rand(20,30)
			if(2)
				brainmob.emp_damage += rand(10,20)
			if(3)
				brainmob.emp_damage += rand(0,10)
	..()
