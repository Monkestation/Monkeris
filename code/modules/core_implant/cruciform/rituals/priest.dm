/datum/ritual/cruciform/priest
	name = "priest"
	phrase = null
	desc = ""
	category = "Priest"

/datum/ritual/targeted/cruciform/priest
	name = "priest targeted"
	phrase = null
	desc = ""
	category = "Priest"

/datum/ritual/cruciform/priest/acolyte
	name = "acolyte"
	phrase = null
	desc = ""
	category = "Acolyte"

/datum/ritual/targeted/cruciform/priest/acolyte
	name = "acolyte targeted"
	phrase = null
	desc = ""
	category = "Acolyte"


/datum/ritual/cruciform/priest/acolyte/epiphany
	name = "Epiphany"
	phrase = "In nomine Patris et Filii et Spiritus sancti."
	desc = "NeoTheology's principal sacrament is a ritual of baptism and merging with cruciform. A body, relieved of clothes should be placed on NeoTheology's special altar."

/datum/ritual/cruciform/priest/acolyte/epiphany/perform(mob/living/carbon/human/user, obj/item/implant/core_implant/C)
	var/obj/item/implant/core_implant/cruciform/CI = get_implant_from_victim(user, /obj/item/implant/core_implant/cruciform, FALSE)

	if(!CI)
		fail("There is no cruciform on this one.", user, C)
		return FALSE

	if(!CI.wearer)
		fail("Cruciform is not installed.", user, C)
		return FALSE

	if(CI.activated || CI.active)
		fail("This cruciform already has a soul inside.", user, C)
		return FALSE

	if (CI.wearer.stat == DEAD)
		fail("It is too late for this one, the soul has already left the vessel", user, C)
		return FALSE

	log_and_message_admins("successfully baptized [CI.wearer]")
	to_chat(CI.wearer, span_info("Your cruciform vibrates and warms up."))

	CI.activate()

	if(get_storyteller())	//Call objectives update to check inquisitor objective completion
		get_storyteller().update_objectives()

	GLOB.new_neothecnology_convert++

	return TRUE

/* - This will be used later, when new cult arrive.
/datum/ritual/cruciform/banish
	name = "banish"
	phrase = "Et ne inducas nos in tentationem, sed libera nos a malo"
*/

/datum/ritual/cruciform/priest/acolyte/unupgrade
	name = "Asacris"
	phrase = "A caelo usque ad centrum."
	desc = "This litany will remove any upgrade from the target's Cruciform implant"

/datum/ritual/cruciform/priest/acolyte/unupgrade/perform(mob/living/carbon/human/user, obj/item/implant/core_implant/C)
	var/obj/item/implant/core_implant/cruciform/CI = get_implant_from_victim(user, /obj/item/implant/core_implant/cruciform)

	if(!CI)
		fail("There is no cruciform on this one.", user, C)
		return FALSE

	if(!CI.wearer)
		fail("Cruciform is not installed.", user, C)
		return FALSE

	if(!istype(CI.upgrades) || length(CI.upgrades) <= 0)
		fail("here is no upgrades on this one.", user, C)
		return FALSE

	for(var/obj/item/coreimplant_upgrade/CU in CI.upgrades)
		CU.remove()
		log_and_message_admins("removed upgrade from [C] cruciform with asacris litany")

	return TRUE


///////////////////////////////////////
///////////SHORT BOOST LITANIES////////
///////////////////////////////////////

/datum/ritual/cruciform/priest/acolyte/short_boost
	name = "Short boost ritual"
	phrase = null
	desc = "This litany boosts mechanical stats of everyone who's hear you on the short time. "
	cooldown = TRUE
	cooldown_time = 2 MINUTES
	effect_time = 10 MINUTES
	cooldown_category = "short_boost"
	power = 30
	var/list/stats_to_boost = list()

/datum/ritual/cruciform/priest/acolyte/short_boost/New()
	..()
	desc = "This litany boosts [get_stats_to_text()] stats of everyone who hears you, lasts about ten minutes."

/datum/ritual/cruciform/priest/acolyte/short_boost/perform(mob/living/carbon/human/user, obj/item/implant/core_implant/C)
	var/list/people_around = list()
	for(var/mob/living/carbon/human/H in view(user))
		if(H != user && !isdeaf(H) && !get_active_mutation(H, MUTATION_ATHEIST))
			people_around.Add(H)

	if(people_around.len > 0)
		to_chat(user, span_notice("You feel the air thrum with an inaudible vibration."))
		playsound(user.loc, 'sound/machines/signal.ogg', 50, 1)
		for(var/mob/living/carbon/human/participant in people_around)
			to_chat(participant, span_notice("You hear a silent signal..."))
			give_boost(participant)
		set_global_cooldown()
		return TRUE
	else
		fail("Your cruciform sings, alone, unto the void.", user, C)
		return FALSE


/datum/ritual/cruciform/priest/acolyte/short_boost/proc/give_boost(mob/living/carbon/human/participant)
	for(var/stat in stats_to_boost)
		var/amount = stats_to_boost[stat]
		participant.stats.addTempStat(stat, amount, effect_time, src.name)
		addtimer(CALLBACK(src, PROC_REF(take_boost), participant, stat, amount), effect_time)
	spawn(30)
		to_chat(participant, span_notice("A wave of dizziness washes over you, and your mind is filled with a sudden insight into [get_stats_to_text()]."))


/datum/ritual/cruciform/priest/acolyte/short_boost/proc/take_boost(mob/living/carbon/human/participant, stat, amount)
	// take_boost is automatically triggered by a callback function when the boost ends but the participant
	if (participant) // check if participant still exists otherwise we cannot read null.stats
		to_chat(participant, span_warning("Your knowledge of [get_stats_to_text()] feels lessened."))

/datum/ritual/cruciform/priest/acolyte/short_boost/proc/get_stats_to_text()
	if(stats_to_boost.len == 1)
		return lowertext(stats_to_boost[1])
	var/stats_text = ""
	for(var/i = 1 to stats_to_boost.len)
		var/stat = stats_to_boost[i]
		if(i == stats_to_boost.len)
			stats_text += " and [stat]"
			continue
		if(i == 1)
			stats_text += "[stat]"
		else
			stats_text += ", [stat]"
	return lowertext(stats_text)

/datum/ritual/cruciform/priest/acolyte/short_boost/wisdom
	name = "Grace of Perseverance"
	phrase = "Domine petra mea et robur meum et salvator meus Deus meus fortis meus sperabo in eo scutum meum et cornu salutis meae susceptor meus."
	stats_to_boost = list(STAT_MEC = 10, STAT_COG = 10, STAT_BIO = 10)

/datum/ritual/cruciform/priest/acolyte/short_boost/courage
	name = "To Uphold the Holy Word"
	phrase = "In Deo laudabo verbum in Domino praedicabo sermonem in Deo speravi non timebo quid faciat homo mihi."
	stats_to_boost = list(STAT_ROB = 10, STAT_TGH = 10, STAT_VIG = 10)

/datum/ritual/targeted/cruciform/priest/atonement
	name = "Atonement"
	phrase = "Piaculo sit \[Target human]!"
	desc = "Imparts extreme pain on the target disciple, but does no actual harm. Use this to enforce Church doctrine on your flock."
	power = 45

/datum/ritual/targeted/cruciform/priest/atonement/perform(mob/living/carbon/human/user, obj/item/implant/core_implant/C,list/targets)
	if(!targets.len)
		fail("Target not found.",user,C,targets)
		return FALSE

	var/obj/item/implant/core_implant/CI = targets[1]

	if(!CI.active || !CI.wearer)
		fail("Cruciform not found.", user, C)
		return FALSE

	if(get_active_mutation(CI.wearer, MUTATION_GODBLOOD))
		fail("[CI.wearer]\'s mutated flesh rejects your will.", user, C)
		return FALSE

	var/mob/living/M = CI.wearer
	log_and_message_admins("inflicted pain on [C] with atonement litany")
	to_chat(M, span_danger("A wave of agony washes over you, the cruciform in your chest searing like a star for a few moments of eternity."))


	var/datum/effect/effect/system/spark_spread/s = new
	s.set_up(1, 1, M.loc)
	s.start()

	M.adjustHalLoss(50)

	return TRUE

/datum/ritual/targeted/cruciform/priest/atonement/process_target(index, obj/item/implant/core_implant/target, text)
	target.update_address()
	if(index == 1 && target.address == text)
		if(target.wearer && (target.loc && (target.locs[1] in view())))
			return target

/datum/ritual/cruciform/priest/acolyte/records
	name = "Baptismal Record"
	phrase = "Memento nomina..."
	desc = "Requests a copy of the Church's local parishoner records from your altar."
	power = 30
	success_message = "On the verge of audibility you hear pleasant music, a piece of paper slides out from a slit in the altar."

/datum/ritual/cruciform/priest/acolyte/records/perform(mob/living/carbon/human/user, obj/item/implant/core_implant/C)
	var/list/OBJS = get_front(user)

	var/obj/machinery/optable/altar = locate(/obj/machinery/optable/altar) in OBJS

	if(!altar)
		fail("This is not your altar, the litany is useless.", user, C)
		return FALSE

	if(altar)
		new /obj/item/paper/neopaper(altar.loc, disciples.Join("\n"), "Church Record")
	return TRUE

/datum/ritual/cruciform/priest/offering
	name = "Offerings"
	category = "Offerings"
	success_message = "Your prayers have been heard."
	fail_message = "Your prayers have not been answered."
	power = 15
	var/list/req_offerings = list()
	var/list/miracles = list(ARMAMENTS, ALERT, INSPIRATION, ODDITY, STAT_BUFF, MATERIAL_REWARD)
	var/reward_power = 5

/datum/ritual/cruciform/priest/offering/perform(mob/living/carbon/human/H, obj/item/implant/core_implant/C, targets)
	var/list/OBJS = get_front(H)

	var/obj/machinery/power/eotp/EOTP = locate(/obj/machinery/power/eotp) in OBJS
	if(!EOTP)
		fail("You must be in front of the Eye of the Protector.", H, C)
		return FALSE

	var/list/obj/item/item_targets = list()
	var/turf/source_t = get_turf(EOTP)
	for(var/turf/T in RANGE_TURFS(7, source_t))
		for(var/obj/item/A in T)
			item_targets.Add(A)

	if(!make_offerings(item_targets))
		fail("Your offerings are not worthy.", H, C)
		return FALSE

	EOTP.current_rewards = miracles
	EOTP.power += reward_power
	return TRUE

/datum/ritual/cruciform/priest/offering/proc/make_offerings(list/offerings)
	var/num_check = 0
	var/list/true_offerings = list()
	for(var/path in req_offerings)
		var/req_num = req_offerings[path]
		var/num_item = 0
		for(var/obj/item/I in offerings)
			if(istype(I, path))
				if(num_item >= req_num)
					break
				if(istype(I, /obj/item/stack))
					var/obj/item/stack/S = I
					num_item += S.amount
				else
					num_item++
				true_offerings.Add(I)

		if(num_item < req_num)
			break
		else
			num_check++

	if(num_check >= req_offerings.len)
		for(var/path in req_offerings)
			var/req_num = req_offerings[path]
			for(var/obj/item/I in true_offerings)
				if(req_num <= 0)
					break
				if(istype(I, path))
					if(istype(I, /obj/item/stack))
						var/obj/item/stack/S = I
						if(S.amount <= req_num)
							var/num = S.amount
							S.use(num)
							req_num -= num
						else
							S.use(req_num)
							req_num = 0
					else
						qdel(I)
						req_num--
		return TRUE

	return FALSE

/datum/ritual/cruciform/priest/offering/divine_intervention
	name = "Divine intervention"
	phrase = "Auxilium instaurarent domum tuam."
	desc = "Requests the Eye of the Protector for construction materials. You must offer 200 biomatter."
	req_offerings = list(/obj/item/stack/material/biomatter = 200)
	miracles = list(MATERIAL_REWARD)

/datum/ritual/cruciform/priest/offering/holy_guidance
	name = "Holy guidance"
	phrase = "Domine deus, lux via."
	desc = "Present your prayers to the Eye of the Protector. You must offer an oddity and 40 fruits."
	req_offerings = list(/obj/item/oddity = 1, /obj/item/reagent_containers/food/snacks/grown = 40)
	miracles = list(ALERT, INSPIRATION, ODDITY, STAT_BUFF, ENERGY_REWARD)

/datum/ritual/cruciform/priest/divine_blessing
	name = "Divine Blessing"
	phrase = "Corpus Deus."
	desc = "Increase an oddity's stats by a certain amount but reduce yours by half of that amount."
	success_message = "Your oddity has been blessed."
	fail_message = "You feel cold in your active hand."
	power = 30
	var/list/odditys = list()


/datum/ritual/cruciform/priest/divine_blessing/perform(mob/living/carbon/human/user, obj/item/implant/core_implant/C)
	var/obj/item/I = user.get_active_held_item()
	if(!I)
		fail("You have nothing in your active hand.", user, C)
		return FALSE

	if(I in odditys)
		fail("This oddity has already been blessed.", user, C)
		return FALSE

	GET_COMPONENT_FROM(inspiracion, /datum/component/inspiration, I)
	if(!inspiracion)
		fail("You need to hold an oddity in your active hand.", user, C)
		return FALSE

	if(!inspiracion.stats)
		fail("This oddity cannot be blessed.", user, C)
		return FALSE

	for(var/stat in inspiracion.stats)
		if(inspiracion.stats[stat] == 0)
			continue
		var/stat_gain = rand(1,8)
		inspiracion.stats[stat] += stat_gain
		user.stats.changeStat(stat, -max(round(stat_gain/2),1))
	odditys.Add(I)
	return TRUE

/datum/ritual/cruciform/priest/confirmation
	name = "Confirmation"
	phrase = "Misericordia et veritas non te deserant circumda eas gutturi tuo et describe in tabulis cordis tui..."
	desc = "Ritual of assigning a disciple to a specific duty within the church."
	power = 80
	cooldown = TRUE
	cooldown_time = 1 MINUTE

/datum/ritual/cruciform/priest/confirmation/perform(mob/living/carbon/human/user, obj/item/implant/core_implant/C,list/targets)
	var/obj/item/implant/core_implant/cruciform/CI = get_implant_from_victim(user, /obj/item/implant/core_implant/cruciform)

	if(!CI || !CI.wearer || !ishuman(CI.wearer) || !CI.active)
		fail("Cruciform not found", user, C)
		return FALSE

	var/designation = alert("Which designation should this disciple have?", "Rite of Confirmation", "Acolyte", "Agrolyte", "Custodian")
	var/extra_phrase

	if(designation == "Acolyte")
		CI.make_acolyte()
		extra_phrase = "...acolytus."

	else if(designation == "Agrolyte")
		CI.make_agrolyte()
		extra_phrase = "...hortulanus."

	else if(designation == "Custodian")
		CI.make_custodian()
		extra_phrase = "...custos."

	user.say(extra_phrase)
	set_personal_cooldown(user)
	return TRUE

/datum/ritual/cruciform/priest/adoption
	name = "Adoption"
	phrase = "Dervans semitas iustitiae et vias sanctorum custodiens."
	desc = "Opens church doors for target disciple."
	power = 15

/datum/ritual/cruciform/priest/adoption/perform(mob/living/carbon/human/user, obj/item/implant/core_implant/C,list/targets)
	var/obj/item/implant/core_implant/cruciform/CI = get_implant_from_victim(user, /obj/item/implant/core_implant/cruciform)

	if(!CI || !CI.wearer || !ishuman(CI.wearer) || !CI.active)
		fail("Cruciform not found", user, C)
		return FALSE

	CI.security_clearance = CLEARANCE_COMMON
	return TRUE

/datum/ritual/cruciform/priest/ordination
	name = "Ordination"
	phrase = "Gloriam sapientes possidebunt stultorum exaltatio ignominia."
	desc = "Opens clergy doors for target disciple."
	power = 15

/datum/ritual/cruciform/priest/ordination/perform(mob/living/carbon/human/user, obj/item/implant/core_implant/C,list/targets)
	var/obj/item/implant/core_implant/cruciform/CI = get_implant_from_victim(user, /obj/item/implant/core_implant/cruciform)

	if(!CI || !CI.wearer || !ishuman(CI.wearer) || !CI.active)
		fail("Cruciform not found", user, C)
		return FALSE

	CI.security_clearance = CLEARANCE_CLERGY
	return TRUE

/datum/ritual/cruciform/priest/omission
	name = "Omission"
	phrase = "Via impiorum tenebrosa nesciunt ubi corruant."
	desc = "Removes all access from target disciple's cruciform."
	power = 30

/datum/ritual/cruciform/priest/omission/perform(mob/living/carbon/human/user, obj/item/implant/core_implant/C,list/targets)
	var/obj/item/implant/core_implant/cruciform/CI = get_implant_from_victim(user, /obj/item/implant/core_implant/cruciform)

	if(!CI || !CI.wearer || !ishuman(CI.wearer) || !CI.active)
		fail("Cruciform not found", user, C)
		return FALSE

	if(CI.get_module(CRUCIFORM_INQUISITOR))
		fail("You don\'t have the authority for this.", user, C)
		return FALSE

	if(get_active_mutation(CI.wearer, MUTATION_GODBLOOD))
		fail("[CI.wearer]\'s mutated flesh rejects your will.", user, C)
		return FALSE

	CI.security_clearance = CLEARANCE_NONE
	return TRUE

/datum/ritual/targeted/cruciform/priest/excommunication
	name = "Excommunication"
	phrase = "Excommunicatio \[Target human]!"
	desc = "Strips target disciple of their rank and access. Shouldn\'t be used lightly."
	power = 60
	cooldown = TRUE
	cooldown_time = 5 MINUTE

/datum/ritual/targeted/cruciform/priest/excommunication/perform(mob/living/carbon/human/user, obj/item/implant/core_implant/C, list/targets)
	if(!targets.len)
		fail("Target not found.", user, C, targets)
		return FALSE

	var/obj/item/implant/core_implant/cruciform/CI = targets[1]
	var/mob/living/M = CI.wearer

	if(!CI.active || !CI.wearer)
		fail("Cruciform not found.", user, C)
		return FALSE

	if(CI.get_module(CRUCIFORM_INQUISITOR))
		fail("You don't have the authority for this.", user, C)
		return FALSE

	if(get_active_mutation(CI.wearer, MUTATION_GODBLOOD))
		fail("[CI.wearer]\'s mutated flesh rejects your will.", user, C)
		return FALSE

	CI.remove_specialization()
	CI.security_clearance = CLEARANCE_NONE
	set_personal_cooldown(user)
	log_and_message_admins(" excommunicated [CI.wearer]")
	to_chat(M, span_danger("You have been spiritually separated from the Church and the community of the faithful."))

	return TRUE

/datum/ritual/targeted/cruciform/priest/excommunication/process_target(index, obj/item/implant/core_implant/target, text)
	if(index == 1 && target.address == text && target.active)
		if(target.wearer && target.wearer.stat != DEAD)
			return target

/datum/ritual/cruciform/priest/acolyte/buy_item
	name = "Order armaments"
	phrase = "Et qui non habet, vendat tunicam suam et emat gladium."
	desc = "Allows you to spend armament points to unlock a NT disk."
	success_message = "Your prayers have been heard."
	fail_message = "Your prayers have not been answered."
	power = 20

/datum/ritual/cruciform/priest/acolyte/buy_item/perform(mob/living/carbon/human/H, obj/item/implant/core_implant/C, targets)
	var/list/OBJS = get_front(H)

	var/obj/machinery/power/eotp/EOTP = locate(/obj/machinery/power/eotp) in OBJS
	if(!EOTP)
		fail("You must be in front of the Eye of the Protector.", H, C)
		return FALSE

	eotp.nano_ui_interact(H)
	return TRUE
