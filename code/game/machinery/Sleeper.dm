/obj/machinery/sleeper
	name = "sleeper"
	desc = "A fancy bed with built-in injectors, a dialysis machine, and a limited health scanner."
	icon = 'icons/obj/Cryogenic2.dmi'
	icon_state = "sleeper_0"
	density = TRUE
	anchored = TRUE
	circuit = /obj/item/electronics/circuitboard/sleeper
	var/mob/living/carbon/human/occupant = null
	var/list/available_chemicals = list("inaprovaline2" = "Synth-Inaprovaline", "stoxin" = "Soporific", "paracetamol" = "Paracetamol", "anti_toxin" = "Dylovene", "dexalin" = "Dexalin", "tricordrazine" = "Tricordrazine")
	var/obj/item/reagent_containers/glass/beaker = null
	var/filtering = 0

	use_power = IDLE_POWER_USE
	idle_power_usage = 15
	active_power_usage = 200 //builtin health analyzer, dialysis machine, injectors.

/obj/machinery/sleeper/Initialize()
	. = ..()
	beaker = new /obj/item/reagent_containers/glass/beaker/large(src)
	update_icon()

/obj/machinery/sleeper/Process()
	if(stat & (NOPOWER|BROKEN))
		return

	if(filtering > 0)
		if(beaker)
			if(beaker.reagents.total_volume < beaker.reagents.maximum_volume)
				var/pumped = 0
				for(var/datum/reagent/x in occupant.reagents.reagent_list)
					occupant.reagents.trans_to_obj(beaker, 3)
					pumped++
				if(ishuman(occupant))
					occupant.vessel.trans_to_obj(beaker, pumped + 1)
		else
			toggle_filter()

/obj/machinery/sleeper/update_icon()
	icon_state = "sleeper_[occupant ? "1" : "0"]"

/obj/machinery/sleeper/attack_hand(mob/user)
	if(..())
		return 1

	nano_ui_interact(user)

/obj/machinery/sleeper/nano_ui_interact(mob/user, ui_key = "main", datum/nanoui/ui = null, force_open = NANOUI_FOCUS, datum/nano_topic_state/state =GLOB.outside_state)
	var/data[0]

	data["power"] = stat & (NOPOWER|BROKEN) ? 0 : 1

	var/list/reagents = list()
	for(var/T in available_chemicals)
		var/list/reagent = list()
		reagent["id"] = T
		reagent["name"] = available_chemicals[T]
		if(occupant)
			reagent["amount"] = occupant.reagents.get_reagent_amount(T)
		reagents += list(reagent)
	data["reagents"] = reagents.Copy()

	if(occupant)
		data["occupant"] = 1
		switch(occupant.stat)
			if(CONSCIOUS)
				data["stat"] = "Conscious"
			if(UNCONSCIOUS)
				data["stat"] = "Unconscious"
			if(DEAD)
				data["stat"] = "<font color='red'>Dead</font>"
		data["crit_health"] = round((occupant.health / occupant.maxHealth) * 100)
		if(ishuman(occupant))
			var/mob/living/carbon/human/H = occupant
			data["pulse"] = H.get_pulse(GETPULSE_TOOL)
			var/organ_health
			var/organ_damage
			for(var/obj/item/organ/external/E in H.organs)
				organ_health += E.total_internal_health
				organ_damage += E.severity_internal_wounds
			data["internal_health"] = round((1 - (organ_health ? organ_damage / organ_health : 0)) * 100)
		data["brute"] = occupant.getBruteLoss()
		data["burn"] = occupant.getFireLoss()
		data["oxy"] = occupant.getOxyLoss()

		var/tox_content = occupant.chem_effects[CE_TOXIN] + occupant.chem_effects[CE_ALCOHOL_TOXIC]
		data["tox"] = tox_content ? tox_content : "0"
	else
		data["occupant"] = 0
	if(beaker)
		data["beaker"] = beaker.reagents.get_free_space()
	else
		data["beaker"] = -1
	data["filtering"] = filtering

	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "sleeper.tmpl", "Sleeper UI", 600, 600, state = state)
		ui.set_initial_data(data)
		ui.open()
		ui.set_auto_update(1)

/obj/machinery/sleeper/Topic(href, href_list)
	if(..())
		return 1

	if(usr == occupant)
		to_chat(usr, span_warning("You can't reach the controls from the inside."))
		return

	add_fingerprint(usr)

	if(href_list["eject"])
		go_out()
	if(href_list["beaker"])
		remove_beaker()
	if(href_list["filter"])
		if(filtering != text2num(href_list["filter"]))
			toggle_filter()
	if(href_list["chemical"] && href_list["amount"])
		if(occupant && occupant.stat != DEAD)
			if(href_list["chemical"] in available_chemicals) // Your hacks are bad and you should feel bad
				inject_chemical(usr, href_list["chemical"], text2num(href_list["amount"]))

	playsound(loc, 'sound/machines/button.ogg', 100, 1)
	return 1

/obj/machinery/sleeper/attackby(obj/item/I, mob/user)
	add_fingerprint(user)
	if(istype(I, /obj/item/reagent_containers/glass))
		if(!beaker)
			beaker = I
			user.drop_item()
			I.loc = src
			user.visible_message(span_notice("\The [user] adds \a [I] to \the [src]."), span_notice("You add \a [I] to \the [src]."))
		else
			to_chat(user, span_warning("\The [src] has a beaker already."))
		return

/obj/machinery/sleeper/affect_grab(mob/user, mob/target)
	go_in(target, user)

/obj/machinery/sleeper/MouseDrop_T(mob/target, mob/user)
	if(user.stat || user.lying || !Adjacent(user) || !target.Adjacent(user)|| !ishuman(target))
		return
	go_in(target, user)

/obj/machinery/sleeper/relaymove(mob/user)
	go_out()

/obj/machinery/sleeper/emp_act(severity)
	if(filtering)
		toggle_filter()

	if(stat & (BROKEN|NOPOWER))
		..(severity)
		return

	if(occupant)
		go_out()

	..(severity)
/obj/machinery/sleeper/proc/toggle_filter()
	if(!occupant || !beaker)
		filtering = 0
		return
	filtering = !filtering

/obj/machinery/sleeper/proc/go_in(mob/M, mob/user)
	if(!M)
		return
	if(stat & (BROKEN|NOPOWER))
		return
	if(occupant)
		to_chat(user, span_warning("\The [src] is already occupied."))
		return

	if(M == user)
		visible_message("\The [user] starts climbing into \the [src].")
	else
		visible_message("\The [user] starts putting [M] into \the [src].")

	if(do_after(user, 20, src))
		if(occupant)
			to_chat(user, span_warning("\The [src] is already occupied."))
			return
		M.stop_pulling()
		if(M.client)
			M.client.perspective = EYE_PERSPECTIVE
			M.client.eye = src
		M.forceMove(src)
		set_power_use(ACTIVE_POWER_USE)
		occupant = M
		update_icon()

/obj/machinery/sleeper/proc/go_out()
	if(!occupant)
		return
	if(occupant.client)
		occupant.client.eye = occupant.client.mob
		occupant.client.perspective = MOB_PERSPECTIVE
	occupant.forceMove(get_turf(src))
	occupant = null
	for(var/atom/movable/A in src) // In case an object was dropped inside or something
		if(A == beaker)
			continue
		A.forceMove(loc)
	set_power_use(IDLE_POWER_USE)
	update_icon()
	toggle_filter()

/obj/machinery/sleeper/proc/remove_beaker()
	if(beaker)
		beaker.loc = loc
		beaker = null
		toggle_filter()

/obj/machinery/sleeper/proc/inject_chemical(mob/living/user, chemical, amount)
	if(stat & (BROKEN|NOPOWER))
		return

	if(occupant && occupant.reagents)
		if(occupant.reagents.get_reagent_amount(chemical) + amount <= 20)
			use_power(amount * CHEM_SYNTH_ENERGY)
			occupant.reagents.add_reagent(chemical, amount)
			to_chat(user, "Occupant now has [occupant.reagents.get_reagent_amount(chemical)] units of [available_chemicals[chemical]] in their bloodstream.")
		else
			to_chat(user, "The subject has too many chemicals.")
	else
		to_chat(user, "There's no suitable occupant in \the [src].")

/obj/machinery/sleeper/verb/eject_occupant_verb()
	set name = "Eject Occupant"
	set desc = "Force eject occupant."
	set category = "Object"
	set src in view(1)

	if (usr.incapacitated() || occupant == usr)
		return

	go_out()
