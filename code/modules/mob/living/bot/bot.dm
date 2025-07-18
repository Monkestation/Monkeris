/mob/living/bot
	name = "Bot"
	health = 20
	maxHealth = 20
	icon = 'icons/obj/aibots.dmi'
	layer = MOB_LAYER
	universal_speak = 1
	density = FALSE
	bad_type = /mob/living/bot
	tts_seed = "Robot_1"
	var/obj/item/card/id/botcard = null
	var/list/botcard_access = list()
	var/on = TRUE
	var/open = 0
	var/locked = 1
	var/emagged = 0
	var/light_strength = 3

	var/obj/access_scanner = null
	var/list/req_access = list()
	var/list/req_one_access = list()
	mob_classification = CLASSIFICATION_SYNTHETIC

/mob/living/bot/New()
	..()
	update_icons()

	botcard = new /obj/item/card/id(src)
	botcard.access = botcard_access.Copy()

	access_scanner = new /obj(src)
	access_scanner.req_access = req_access.Copy()
	access_scanner.req_one_access = req_one_access.Copy()

/mob/living/bot/Life()
	..()
	if(health <= 0)
		death()
		return
	weakened = 0
	stunned = 0
	paralysis = 0

/mob/living/bot/updatehealth()
	if(status_flags & GODMODE)
		health = maxHealth
		stat = CONSCIOUS
	else
		health = maxHealth - getFireLoss() - getBruteLoss()
	oxyloss = 0
	toxloss = 0
	cloneloss = 0
	halloss = 0

/mob/living/bot/death()
	explode()

/mob/living/bot/attackby(obj/item/O, mob/user)
	if(O.GetIdCard())
		if(access_scanner.allowed(user) && !open && !emagged)
			locked = !locked
			to_chat(user, span_notice("Controls are now [locked ? "locked." : "unlocked."]"))
			attack_hand(user)
		else
			if(emagged)
				to_chat(user, span_warning("ERROR"))
			if(open)
				to_chat(user, span_warning("Please close the access panel before locking it."))
			else
				to_chat(user, span_warning("Access denied."))
		return
	else if(istype(O, /obj/item/tool/screwdriver))
		if(!locked)
			open = !open
			to_chat(user, span_notice("Maintenance panel is now [open ? "opened" : "closed"]."))
		else
			to_chat(user, span_notice("You need to unlock the controls first."))
		return
	else if(istype(O, /obj/item/tool/weldingtool))
		if(health < maxHealth)
			if(open)
				adjustBruteLoss(-10)
				user.visible_message(span_notice("[user] repairs [src]."),span_notice("You repair [src]."))
			else
				to_chat(user, span_notice("Unable to repair with the maintenance panel closed."))
		else
			to_chat(user, span_notice("[src] does not need a repair."))
		return
	else
		..()

/mob/living/bot/attack_ai(mob/user)
	return attack_hand(user)

/mob/living/bot/say(message)
	var/verb = "beeps"

	message = sanitize(message)

	..(message, null, verb)

/mob/living/bot/Bump(atom/A)
	if(on && botcard && istype(A, /obj/machinery/door))
		var/obj/machinery/door/D = A
		if(!istype(D, /obj/machinery/door/firedoor) && !istype(D, /obj/machinery/door/blast) && D.check_access(botcard))
			D.open()
	else
		..()

/mob/living/bot/emag_act(remaining_charges, mob/user)
	return 0

/mob/living/bot/proc/turn_on()
	if(stat)
		return 0
	on = TRUE
	set_light(light_strength)
	update_icons()
	return 1

/mob/living/bot/proc/turn_off()
	on = FALSE
	set_light(0)
	update_icons()

/mob/living/bot/proc/explode()
	qdel(src)

