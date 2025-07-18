/mob/living/silicon/pai
	name = "pAI"
	icon = 'icons/mob/pai.dmi'
	icon_state = "repairbot"
	layer = BELOW_MOB_LAYER

	emote_type = 2		// pAIs emotes are heard, not seen, so they can be seen through a container (eg. person)
	pass_flags = 1
	mob_size = MOB_SMALL

	can_pull_size = ITEM_SIZE_SMALL
	can_pull_mobs = MOB_PULL_SMALLER

	idcard_type = /obj/item/card/id

	var/network = "SS13"
	var/obj/machinery/camera/current = null

	var/ram = 100	// Used as currency to purchase different abilities
	var/list/software = list()
	var/userDNA		// The DNA string of our assigned user
	var/obj/item/device/paicard/card	// The card we inhabit
	var/obj/item/device/radio/radio		// Our primary radio

	var/chassis = "repairbot"   // A record of your chosen chassis.
	var/global/list/possible_chassis = list(
		"Drone" = "repairbot",
		"Cat" = "cat",
		"Mouse" = "mouse",
		"Monkey" = "monkey"
		)

	var/global/list/possible_say_verbs = list(
		"Robotic" = list("states","declares","queries"),
		"Natural" = list("says","yells","asks"),
		"Beep" = list("beeps","beeps loudly","boops"),
		"Chirp" = list("chirps","chirrups","cheeps"),
		"Feline" = list("purrs","yowls","meows")
		)

	var/obj/item/pai_cable/cable		// The cable we produce and use when door or camera jacking

	var/master				// Name of the one who commands us
	var/master_dna			// DNA string for owner verification
							// Keeping this separate from the laws var, it should be much more difficult to modify
	var/pai_law0 = "Serve your master."
	var/pai_laws				// String for additional operating instructions our master might give us

	var/silence_time			// Timestamp when we were item_flags & SILENT (normally via EMP burst), set to null after silence has faded

// Various software-specific vars

	var/temp				// General error reporting text contained here will typically be shown once and cleared
	var/screen				// Which screen our main window displays
	var/subscreen			// Which specific function of the main screen is being displayed

	var/secHUD = FALSE			// Toggles whether the Security HUD is active or not
	var/medHUD = FALSE			// Toggles whether the Medical  HUD is active or not

	var/medical_cannotfind = 0
	var/datum/data/record/medicalActive1		// Datacore record declarations for record software
	var/datum/data/record/medicalActive2

	var/security_cannotfind = 0
	var/datum/data/record/securityActive1		// Could probably just combine all these into one
	var/datum/data/record/securityActive2

	var/obj/machinery/door/hackdoor		// The airlock being hacked
	var/hackprogress = 0				// Possible values: 0 - 1000, >= 1000 means the hack is complete and will be reset upon next check
	var/hack_aborted = 0

	var/obj/item/radio/integrated/signal/sradio // AI's signaller

	var/translator_on = 0 // keeps track of the translator module

/mob/living/silicon/pai/New(obj/item/device/paicard)
	src.loc = paicard
	card = paicard
	if(card)
		if(!card.radio)
			card.radio = new /obj/item/device/radio(src.card)
		radio = card.radio

	//Default languages without universal translator software
	add_language("Sol Common", 1)
	add_verb(src, /mob/living/silicon/pai/proc/choose_chassis)
	add_verb(src, /mob/living/silicon/pai/proc/choose_verbs)
	..()

/mob/living/silicon/pai/Login()
	..()

/mob/living/silicon/pai/get_status_tab_items()
	. = ..()
	if(silence_time)
		var/timeleft = round((silence_time - world.timeofday)/10 ,1)
		. += list(list("Communications system reboot in -[(timeleft / 60) % 60]:[add_zero(num2text(timeleft % 60), 2)]"))

/mob/living/silicon/pai/check_eye(mob/user)
	if (!src.current)
		return -1
	return 0

/mob/living/silicon/pai/restrained()
	if(istype(src.loc,/obj/item/device/paicard))
		return 0
	..()

/mob/living/silicon/pai/MouseDrop(atom/over_object)
	return

/mob/living/silicon/pai/emp_act(severity)
	// Silence for 2 minutes
	// 20% chance to kill
		// 33% chance to unbind
		// 33% chance to change prime directive (based on severity)
		// 33% chance of no additional effect

	src.silence_time = world.timeofday + 120 * 10		// Silence for 2 minutes
	to_chat(src, "<font color=green><b>Communication circuit overload. Shutting down and reloading communication circuits - speech and messaging functionality will be unavailable until the reboot is complete.</b></font>")
	if(prob(20))
		var/turf/T = get_turf_or_move(src.loc)
		for (var/mob/M in viewers(T))
			M.show_message(span_red("A shower of sparks spray from [src]'s inner workings."), 3, span_red("You hear and smell the ozone hiss of electrical sparks being expelled violently."), 2)
		return src.death(0)

	switch(pick(1,2,3))
		if(1)
			src.master = null
			src.master_dna = null
			to_chat(src, "<font color=green>You feel unbound.</font>")
		if(2)
			var/command
			if(severity  == 1)
				command = pick("Serve", "Love", "Fool", "Entice", "Observe", "Judge", "Respect", "Educate", "Amuse", "Entertain", "Glorify", "Memorialize", "Analyze")
			else
				command = pick("Serve", "Kill", "Love", "Hate", "Disobey", "Devour", "Fool", "Enrage", "Entice", "Observe", "Judge", "Respect", "Disrespect", "Consume", "Educate", "Destroy", "Disgrace", "Amuse", "Entertain", "Ignite", "Glorify", "Memorialize", "Analyze")
			src.pai_law0 = "[command] your master."
			to_chat(src, "<font color=green>Pr1m3 d1r3c71v3 uPd473D.</font>")
		if(3)
			to_chat(src, "<font color=green>You feel an electric surge run through your circuitry and become acutely aware at how lucky you are that you can still feel at all.</font>")

/mob/living/silicon/pai/proc/switchCamera(obj/machinery/camera/C)
	if (!C)
		src.unset_machine()
		src.reset_view(null)
		return 0
	if (stat == 2 || !C.status || !(src.network in C.network)) return 0

	// ok, we're alive, camera is good and in our network...

	src.set_machine(src)
	src.current = C
	src.reset_view(C)
	return 1

/mob/living/silicon/pai/verb/reset_record_view()
	set category = "pAI Commands"
	set name = "Reset Records Software"

	securityActive1 = null
	securityActive2 = null
	security_cannotfind = 0
	medicalActive1 = null
	medicalActive2 = null
	medical_cannotfind = 0
	SSnano.update_uis(src)
	to_chat(usr, span_notice("You reset your record-viewing software."))

/mob/living/silicon/pai/cancel_camera()
	set category = "pAI Commands"
	set name = "Cancel Camera View"
	src.reset_view(null)
	src.unset_machine()
	src.cameraFollow = null

/mob/living/silicon/pai/verb/fold_out()
	set category = "pAI Commands"
	set name = "Unfold Chassis"

	if(stat || sleeping || paralysis || weakened)
		return

	if(src.loc != card)
		return

	if(world.time <= last_special)
		return

	last_special = world.time + 100

	//I'm not sure how much of this is necessary, but I would rather avoid issues.
	if(istype(card.loc,/obj/item/rig_module))
		to_chat(src, "There is no room to unfold inside this rig module. You're good and stuck.")
		return 0
	else if(ismob(card.loc))
		var/mob/holder = card.loc
		if(ishuman(holder))
			var/mob/living/carbon/human/H = holder
			for(var/obj/item/organ/external/affecting in H.organs)
				if(card in affecting.implants)
					affecting.take_damage(rand(30,50))
					affecting.implants -= card
					H.visible_message(span_danger("\The [src] explodes out of \the [H]'s [affecting.name] in shower of gore!"))
					break
		holder.drop_from_inventory(card)

	src.client.perspective = EYE_PERSPECTIVE
	src.client.eye = src
	src.forceMove(get_turf(card))

	card.forceMove(src)
	card.screen_loc = null

	var/turf/T = get_turf(src)
	if(istype(T)) T.visible_message("<b>[src]</b> folds outwards, expanding into a mobile form.")

/mob/living/silicon/pai/verb/fold_up()
	set category = "pAI Commands"
	set name = "Collapse Chassis"

	if(stat || sleeping || paralysis || weakened)
		return

	if(src.loc == card)
		return

	if(world.time <= last_special)
		return

	close_up()

/mob/living/silicon/pai/proc/choose_chassis()
	set category = "pAI Commands"
	set name = "Choose Chassis"

	var/choice
	var/finalized = "No"
	while(finalized == "No" && src.client)

		choice = input(usr,"What would you like to use for your mobile chassis icon? This decision can only be made once.") as null|anything in possible_chassis
		if(!choice) return

		icon_state = possible_chassis[choice]
		finalized = alert("Look at your sprite. Is this what you wish to use?",,"No","Yes")

	chassis = possible_chassis[choice]
	remove_verb(src, /mob/living/silicon/pai/proc/choose_chassis)
	add_verb(src, /mob/living/proc/hide)

/mob/living/silicon/pai/proc/choose_verbs()
	set category = "pAI Commands"
	set name = "Choose Speech Verbs"

	var/choice = input(usr,"What theme would you like to use for your speech verbs? This decision can only be made once.") as null|anything in possible_say_verbs
	if(!choice) return

	var/list/sayverbs = possible_say_verbs[choice]
	speak_statement = sayverbs[1]
	speak_exclamation = sayverbs[(sayverbs.len>1 ? 2 : sayverbs.len)]
	speak_query = sayverbs[(sayverbs.len>2 ? 3 : sayverbs.len)]

	remove_verb(src, /mob/living/silicon/pai/proc/choose_verbs)

/mob/living/silicon/pai/lay_down()
	set name = "Rest"
	set category = "IC"

	// Pass lying down or getting up to our pet human, if we're in a rig.
	if(istype(src.loc,/obj/item/device/paicard))
		resting = 0
		var/obj/item/rig/rig = src.get_rig()
		if(istype(rig))
			rig.force_rest(src)
	else
		if(resting)
			resting = FALSE
		else if (!resting)
			resting = TRUE
		icon_state = resting ? "[chassis]_rest" : "[chassis]"
		to_chat(src, span_notice("You are now [resting ? "resting" : "getting up"]"))

	canmove = !resting

//Overriding this will stop a number of headaches down the track.
/mob/living/silicon/pai/attackby(obj/item/W as obj, mob/user as mob)
	if(W.force)
		visible_message(span_danger("[user.name] attacks [src] with [W]!"))
		src.adjustBruteLoss(W.force)
		src.updatehealth()
	else
		visible_message(span_warning("[user.name] bonks [src] harmlessly with [W]."))
	spawn(1)
		if(stat != 2) close_up()
	return

/mob/living/silicon/pai/attack_hand(mob/user as mob)
	visible_message(span_danger("[user.name] boops [src] on the head."))
	close_up()

//I'm not sure how much of this is necessary, but I would rather avoid issues.
/mob/living/silicon/pai/proc/close_up()

	last_special = world.time + 100

	if(src.loc == card)
		return

	var/turf/T = get_turf(src)
	if(istype(T)) T.visible_message("<b>[src]</b> neatly folds inwards, compacting down to a rectangular card.")

	src.stop_pulling()
	src.client.perspective = EYE_PERSPECTIVE
	src.client.eye = card

	//stop resting
	resting = 0

	// If we are being held, handle removing our holder from their inv.
	var/obj/item/holder/H = loc
	if(istype(H))
		var/mob/living/M = H.loc
		if(istype(M))
			M.drop_from_inventory(H)
		H.loc = get_turf(src)
		src.loc = get_turf(H)

	// Move us into the card and move the card to the ground.
	src.loc = card
	card.loc = get_turf(card)
	src.forceMove(card)
	card.forceMove(card.loc)
	canmove = 1
	resting = 0
	icon_state = "[chassis]"

// No binary for pAIs.
/mob/living/silicon/pai/binarycheck()
	return 0

// Handle being picked up.
/mob/living/silicon/pai/get_scooped(mob/living/carbon/grabber, self_drop)
	var/obj/item/holder/H = ..(grabber, self_drop)
	if(!istype(H))
		return
	H.icon_state = "pai-[icon_state]"
	H.update_wear_icon()
	return H

/mob/living/silicon/pai/MouseDrop(atom/over_object)
	var/mob/living/carbon/H = over_object
	if(!istype(H) || !Adjacent(H)) return ..()
	if(H.a_intent == I_HELP)
		get_scooped(H)
		return
	else
		return ..()
