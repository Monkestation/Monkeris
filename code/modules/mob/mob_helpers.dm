/proc/issmall(A)
	if(A && isliving(A))
		var/mob/living/L = A
		return L.mob_size <= MOB_SMALL
	return 0

/mob/living/proc/isSynthetic()
	return 0

/mob/living/carbon/human/isSynthetic()
	// If they are 100% robotic, they count as synthetic.
	for(var/obj/item/organ/external/E in organs)
		if(!BP_IS_ROBOTIC(E))
			return FALSE
	return TRUE

/mob/living/silicon/isSynthetic()
	return 1

/mob/proc/isMonkey()
	return 0

/mob/living/carbon/human/isMonkey()
	return istype(species, /datum/species/monkey)

/proc/isdeaf(A)
//	if(isliving(A))
//		var/mob/living/M = A
//		return (M.sdisabilities & DEAF) || M.ear_deaf
	return 0

/proc/hasorgans(A) // Fucking really??
	return ishuman(A)

/proc/iscuffed(A)
	if(iscarbon(A))
		var/mob/living/carbon/C = A
		if(C.handcuffed)
			return 1
	return 0

/proc/hassensorlevel(A, level)
	var/mob/living/carbon/human/H = A
	if(istype(H) && istype(H.w_uniform, /obj/item/clothing/under))
		var/obj/item/clothing/under/U = H.w_uniform
		return U.sensor_mode >= level
	return 0

/proc/getsensorlevel(A)
	var/mob/living/carbon/human/H = A
	if(istype(H) && istype(H.w_uniform, /obj/item/clothing/under))
		var/obj/item/clothing/under/U = H.w_uniform
		return U.sensor_mode
	return SUIT_SENSOR_OFF


/proc/hsl2rgb(h, s, l)
	return //TODO: Implement

/*
	Miss Chance
*/

//TODO: Integrate defence zones and targeting body parts with the actual organ system, move these into organ definitions.

//The base miss chance for the different defence zones
var/list/global/base_miss_chance = list(
	BP_HEAD = 5,
	BP_CHEST = 2,
	BP_GROIN = 2,
	BP_L_LEG  = 3,
	BP_R_LEG = 3,
	BP_L_ARM = 3,
	BP_R_ARM = 3
	)

//Used to weight organs when an organ is hit randomly (i.e. not a directed, aimed attack).
//Also used to weight the protection value that armour provides for covering that body part when calculating protection from full-body effects.
var/list/global/organ_rel_size = list(
	BP_HEAD = 20,
	BP_CHEST = 70,
	BP_GROIN = 30,
	BP_L_LEG  = 25,
	BP_R_LEG = 25,
	BP_L_ARM = 25,
	BP_R_ARM = 25
)

/proc/check_zone(zone)
	if(!zone)	return BP_CHEST
	switch(zone)
		if(BP_EYES)
			zone = BP_HEAD
		if(BP_MOUTH)
			zone = BP_HEAD
	return zone

// Returns zone with a certain probability. If the probability fails, or no zone is specified, then a random body part is chosen.
// Do not use this if someone is intentionally trying to hit a specific body part.
/proc/ran_zone(zone, probability)
	if (zone)
		zone = check_zone(zone)
		if (prob(probability))
			return zone

	var/ran_zone = zone
	while (ran_zone == zone)
		ran_zone = pick (
			organ_rel_size[BP_HEAD]; BP_HEAD,
			organ_rel_size[BP_CHEST]; BP_CHEST,
			organ_rel_size[BP_GROIN]; BP_GROIN,
			organ_rel_size[BP_L_ARM]; BP_L_ARM,
			organ_rel_size[BP_R_ARM]; BP_R_ARM,
			organ_rel_size[BP_L_LEG ]; BP_L_LEG ,
			organ_rel_size[BP_R_LEG]; BP_R_LEG,
		)

	return ran_zone

//Replaces some of the characters with *, used in whispers. pr = probability of no star.
//Will try to preserve HTML formatting. re_encode controls whether the returned text is HTML encoded outside tags.
/proc/stars(n, pr = 25, re_encode = 1)
	if (pr < 0)
		return null
	else if (pr >= 100)
		return n

	var/intag = 0
	var/block = list()
	. = list()
	for(var/i = 1, i <= length(n), i++)
		var/char = copytext_char(n, i, i+1)
		if(!intag && (char == "<"))
			intag = 1
			. += stars_no_html(JOINTEXT(block), pr, re_encode) //stars added here
			block = list()
		block += char
		if(intag && (char == ">"))
			intag = 0
			. += block //We don't mess up html tags with stars
			block = list()
	. += (intag ? block : stars_no_html(JOINTEXT(block), pr, re_encode))
	. = JOINTEXT(.)


//Ingnores the possibility of breaking tags.
/proc/stars_no_html(text, pr, re_encode)
	text = html_decode(text) //We don't want to screw up escaped characters
	. = list()
	for(var/i = 1, i <= length(text), i++)
		var/char = copytext_char(text, i, i+1)
		if(char == " " || prob(pr))
			. += char
		else
			. += "*"
	. = JOINTEXT(.)
	if(re_encode)
		. = html_encode(.)

/proc/slur(phrase)
	phrase = html_decode(phrase)
	var/leng=length(phrase)
	var/counter=length(phrase)
	var/newphrase=""
	var/newletter=""
	while(counter>=1)
		newletter=copytext_char(phrase,(leng-counter)+1,(leng-counter)+2)
		if(rand(1,3)==3)
			if(lowertext(newletter)=="o")	newletter="u"
			if(lowertext(newletter)=="s")	newletter="ch"
			if(lowertext(newletter)=="a")	newletter="ah"
			if(lowertext(newletter)=="c")	newletter="k"
		switch(rand(1,9))
			if(1,3,5,8)	newletter="[lowertext(newletter)]"
			if(2,4,6,9)	newletter="[uppertext(newletter)]"
			if(7)	newletter+="'"
			//if(9,10)	newletter="<b>[newletter]</b>"
			//if(11,12)	newletter="<big>[newletter]</big>"
			//if(13)	newletter="<small>[newletter]</small>"
		newphrase+="[newletter]";counter-=1
	return html_encode(newphrase)

/proc/stutter(n)
	var/te = html_decode(n)
	n = length(n)//length of the entire word
	var/list/t = list()
	var/p = 1//1 is the start of any word
	while(p <= n)//while P, which starts at 1 is less or equal to N which is the length.
		var/n_letter = copytext_char(te, p, p + 1)//copies text from a certain distance. In this case, only one letter at a time.
		if (prob(80) && (lowertext(n_letter) in LIST_OF_CONSONANT|LIST_OF_CONSONANT_RU))
			if (prob(10))
				n_letter = text("[n_letter]-[n_letter]-[n_letter]-[n_letter]")//replaces the current letter with this instead.
			else
				if (prob(20))
					n_letter = text("[n_letter]-[n_letter]-[n_letter]")
				else
					if (prob(5))
						n_letter = null
					else
						n_letter = text("[n_letter]-[n_letter]")
		t += n_letter //since the above is ran through for each letter, the text just adds up back to the original word.
		p++//for each letter p is increased to find where the next letter will be.
	return sanitize(jointext(t, null))

/proc/Gibberish(t, p)//t is the inputted message, and any value higher than 70 for p will cause letters to be replaced instead of added
	/* Turn text into complete gibberish! */
	var/returntext = ""
	for(var/i = 1, i <= length(t), i++)

		var/letter = copytext_char(t, i, i+1)
		if(prob(50))
			if(p >= 70)
				letter = ""

			for(var/j = 1, j <= rand(0, 2), j++)
				letter += pick("#","@","*","&","%","$","/", "<", ">", ";","*","*","*","*","*","*","*")

		returntext += letter

	return returntext


/proc/ninjaspeak(n)
/*
The difference with stutter is that this proc can stutter more than 1 letter
The issue here is that anything that does not have a space is treated as one word (in many instances). For instance, "LOOKING," is a word, including the comma.
It's fairly easy to fix if dealing with single letters but not so much with compounds of letters./N
*/
	var/te = html_decode(n)
	var/t = ""
	n = length(n)
	var/p = 1
	while(p <= n)
		var/n_letter
		var/n_mod = rand(1,4)
		if(p+n_mod>n+1)
			n_letter = copytext_char(te, p, n+1)
		else
			n_letter = copytext_char(te, p, p+n_mod)
		if (prob(50))
			if (prob(30))
				n_letter = text("[n_letter]-[n_letter]-[n_letter]")
			else
				n_letter = text("[n_letter]-[n_letter]")
		else
			n_letter = text("[n_letter]")
		t = text("[t][n_letter]")
		p=p+n_mod
	return sanitize(t)





/// Returns a mob's real name between brackets. Useful when you want to display a mob's name alongside their real name
/mob/proc/get_realname_string()
	if(real_name && real_name != name)
		return " \[[real_name]\]"
	return ""

/proc/findname(msg)
	for(var/mob/M in SSmobs.mob_list | SShumans.mob_list)
		if (M.real_name == text("[msg]"))
			return 1
	return 0


/mob/proc/abiotic(full_body = 0)
	if(full_body && ((src.l_hand && !( src.l_hand.abstract )) || (src.r_hand && !( src.r_hand.abstract )) || (src.back || src.wear_mask)))
		return 1

	if((src.l_hand && !( src.l_hand.abstract )) || (src.r_hand && !( src.r_hand.abstract )))
		return 1

	return 0

//converts intent-strings into numbers and back
var/list/intents = list(I_HELP,I_DISARM,I_GRAB,I_HURT)
/proc/intent_numeric(argument)
	if(istext(argument))
		switch(argument)
			if(I_HELP)		return 0
			if(I_DISARM)	return 1
			if(I_GRAB)		return 2
			else			return 3
	else
		switch(argument)
			if(0)			return I_HELP
			if(1)			return I_DISARM
			if(2)			return I_GRAB
			else			return I_HURT

/// change a mob's act-intent. Input the intent as a string such as "help" or use "right"/"left
/mob/verb/a_intent_change(input as text)
	set name = "a-intent"
	set hidden = 1

	if(ishuman(src) || isbrain(src) || isslime(src))
		switch(input)
			if(I_HELP,I_DISARM,I_GRAB,I_HURT)
				a_intent = input
			if("right")
				a_intent = intent_numeric((intent_numeric(a_intent)+1) % 4)
			if("left")
				a_intent = intent_numeric((intent_numeric(a_intent)+3) % 4)

	else if(isrobot(src))
		if(a_intent == I_HELP)
			a_intent = I_HURT
		else
			a_intent = I_HELP

	if (HUDneed.Find("intent"))
		var/obj/screen/intent/I = HUDneed["intent"]
		I.update_icon()


/proc/is_blind(A)
	if(iscarbon(A))
		var/mob/living/carbon/C = A
		if(C.sdisabilities & BLIND || C.blinded)
			return 1
	return 0

/proc/broadcast_security_hud_message(message, broadcast_source)
	broadcast_hud_message(message, broadcast_source, GLOB.sec_hud_users, /obj/item/clothing/glasses/hud/security)

/proc/broadcast_medical_hud_message(message, broadcast_source)
	broadcast_hud_message(message, broadcast_source, GLOB.med_hud_users, /obj/item/clothing/glasses/hud/health)

/proc/broadcast_hud_message(message, broadcast_source, list/targets, icon)
	var/turf/sourceturf = get_turf(broadcast_source)
	var/htmlicon = icon2html(icon, targets)
	for(var/mob/M in targets)
		var/turf/targetturf = get_turf(M)
		if((targetturf.z == sourceturf.z))
			M.show_message(span_info("[htmlicon] [message]"), 1)

/proc/mobs_in_area(area/A)
	var/list/mobs = new
	for(var/mob/living/M in SSmobs.mob_list | SShumans.mob_list)
		if(get_area(M) == A)
			mobs += M
	return mobs

//Announces that a ghost has joined/left, mainly for use with wizards
/proc/announce_ghost_joinleave(O, joined_ghosts = 1, message = "")
	var/client/C
	//Accept any type, sort what we want here
	if(ismob(O))
		var/mob/M = O
		if(M.client)
			C = M.client
	else if(isclient(O))
		C = O
	else if(istype(O, /datum/mind))
		var/datum/mind/M = O
		if(M.current && M.current.client)
			C = M.current.client
		else if(M.original && M.original.client)
			C = M.original.client

	if(C)
		var/name
		if(C.mob)
			var/mob/M = C.mob
			if(M.mind && M.mind.name)
				name = M.mind.name
			if(M.real_name && M.real_name != name)
				if(name)
					name += " ([M.real_name])"
				else
					name = M.real_name
		if(!name)
			name = (C.holder && C.holder.fakekey) ? C.holder.fakekey : C.key
		if(joined_ghosts)
			deadchat_broadcast("The ghost of [span_name("[name]")] now [pick("skulks","lurks","prowls","creeps","stalks")] among the dead. [message]")
		else
			deadchat_broadcast("[span_name("[name]")] no longer [pick("skulks","lurks","prowls","creeps","stalks")] in the realm of the dead. [message]")

/mob/proc/switch_to_camera(obj/machinery/camera/C)
	if (!C.can_use() || stat || (get_dist(C, src) > 1 || machine != src || blinded || !canmove))
		return 0
	check_eye(src)
	return 1

/mob/living/silicon/ai/switch_to_camera(obj/machinery/camera/C)
	if(!C.can_use() || !is_in_chassis())
		return 0

	eyeobj.setLoc(C)
	return 1

// Returns true if the mob has a client which has been active in the last given X minutes.
/mob/proc/is_client_active(active = 1)
	return client && client.inactivity < active MINUTES

/mob/proc/can_eat()
	return 1

/mob/proc/can_force_feed()
	return 1

#define SAFE_PERP -50
/mob/living/proc/assess_perp(obj/access_obj, check_access, auth_weapons, check_records, check_arrest)
	if(stat == DEAD)
		return SAFE_PERP

	return 0

/mob/living/carbon/assess_perp(obj/access_obj, check_access, auth_weapons, check_records, check_arrest)
	if(handcuffed)
		return SAFE_PERP

	return ..()

/mob/living/carbon/human/assess_perp(obj/access_obj, check_access, auth_weapons, check_records, check_arrest)
	var/threatcount = ..()
	if(. == SAFE_PERP)
		return SAFE_PERP

	//Agent cards lower threatlevel.
	var/obj/item/card/id/id = GetIdCard()
	if(id && istype(id, /obj/item/card/id/syndicate))
		threatcount -= 2
	// A proper	CentCom id is hard currency.
	else if(id && istype(id, /obj/item/card/id/centcom))
		return SAFE_PERP

	if(check_access && !access_obj.allowed(src))
		threatcount += 4

	if(auth_weapons && !access_obj.allowed(src))
		if(isgun(l_hand) || istype(l_hand, /obj/item/melee))
			threatcount += 4

		if(isgun(r_hand) || istype(r_hand, /obj/item/melee))
			threatcount += 4

		if(isgun(belt) || istype(belt, /obj/item/melee))
			threatcount += 2

		if(species.name != SPECIES_HUMAN)
			threatcount += 2

	if(check_records || check_arrest)
		var/perpname = name
		if(id)
			perpname = id.registered_name

		var/datum/data/record/R = find_security_record("name", perpname)
		if(check_records && !R)
			threatcount += 4

		if(check_arrest && R && (R.fields["criminal"] == "*Arrest*"))
			threatcount += 4

	return threatcount

/mob/living/simple_animal/hostile/assess_perp(obj/access_obj, check_access, auth_weapons, check_records, check_arrest)
	var/threatcount = ..()
	if(. == SAFE_PERP)
		return SAFE_PERP

	if(!istype(src, /mob/living/simple_animal/hostile/retaliate/goat))
		threatcount += 4
	return threatcount




#undef SAFE_PERP

/mob/proc/get_multitool(obj/item/tool/multitool/P)
	if(istype(P))
		return P

/mob/observer/ghost/get_multitool()
	return can_admin_interact() && ..(ghost_multitool)

/mob/living/carbon/human/get_multitool()
	return ..(get_active_held_item())

/mob/living/silicon/robot/get_multitool()
	return ..(get_active_held_item())

/mob/living/silicon/ai/get_multitool()
	return ..(aiMulti)


//This proc returns true if the mob has no health problems. EG, no damaged organs, alive, not poisoned, etc
//It is used by cryopods to allow people to quickly respawn during peaceful times
/mob/proc/in_perfect_health()
	return

/mob/living/in_perfect_health()
	if (stat == DEAD)
		return FALSE

	if (brainloss || bruteloss || cloneloss || fireloss || halloss || oxyloss || toxloss)
		return FALSE


	return TRUE

/mob/living/carbon/human/in_perfect_health()
	for (var/a in bad_external_organs)
		return FALSE

	for (var/obj/item/organ/o in internal_organs)
		if (o.damage)
			return FALSE

	return ..()

/mob/proc/get_sex()
	return gender

//Tries to find the mob's email.
/proc/find_email(real_name)
	for(var/mob/mob in GLOB.living_mob_list)
		if(mob.real_name == real_name)
			if(!mob.mind)
				return
			return mob.mind.initial_email_login["login"]

/proc/get_both_hands(mob/living/carbon/M)
	if(!istype(M))
		return
	var/list/hands = list(M.l_hand, M.r_hand)
	return hands

/mob/proc/drop_embedded()
	//Embedded list is defined at mob level so we can have this here too
	for(var/obj/A in embedded)
		if (A.loc == src)
			A.forceMove(loc)
			if(isitem(A))
				var/obj/item/I = A
				I.on_embed_removal(src)
			A.tumble()
	embedded = list()

/mob/proc/skill_to_evade_traps()
	var/prob_evade = 0
	var/base_prob_evade = 30
	if(MOVING_DELIBERATELY(src))
		prob_evade += base_prob_evade
	if(!stats)
		return prob_evade
	prob_evade += base_prob_evade * (stats.getStat(STAT_VIG)/STAT_LEVEL_GODLIKE - weight_coeff())
	if(stats.getPerk(PERK_SURE_STEP))
		prob_evade += base_prob_evade*30/STAT_LEVEL_GODLIKE
	if(stats.getPerk(PERK_RAT))
		prob_evade += base_prob_evade/1.5
	return prob_evade

/mob/proc/mob_playsound(atom/source, soundin, vol as num, vary, extrarange as num, falloff, is_global, frequency, is_ambiance = 0,  ignore_walls = TRUE, zrange = 2, override_env, envdry, envwet, use_pressure = TRUE)
	if(isliving(src))
		var/mob/living/L = src
		vol *= L.noise_coeff + weight_coeff()
		extrarange *= L.noise_coeff + weight_coeff()
	playsound(source, soundin, vol, vary, extrarange, falloff, is_global, frequency, is_ambiance,  ignore_walls, zrange, override_env, envdry, envwet, use_pressure)

/mob/proc/weight_coeff()
	. = 0
	var/max_w_class = get_max_w_class()
	if(max_w_class > ITEM_SIZE_TINY)
		return max_w_class/(ITEM_SIZE_TITANIC)

/*
/mob/proc/get_accumulated_vision_handlers()
	var/result[2]
	var/asight = 0
	var/ainvis = 0
	for(var/atom/vision_handler in additional_vision_handlers)
		//Grab their flags
		asight |= vision_handler.additional_sight_flags()
		ainvis = min(ainvis, vision_handler.additional_see_invisible())
	result[1] = asight
	result[2] = ainvis

	return result
*/

/mob/proc/set_faction(target_faction)
	faction = target_faction ? target_faction : initial(faction)


// Steps used to modify wounding multiplier. Should be used alongside edge/sharp when determining final damage of BRUTE-type attacks.
/proc/step_wounding(wounding, is_increase = FALSE) // Usually mobs are the ones attacking (no), so this should be okay here? If it gets lucky a macro would be slightly faster
	if(is_increase)
		switch(wounding)
			if(WOUNDING_TRIVIAL)
				return WOUNDING_TINY
			if(WOUNDING_TINY)
				return WOUNDING_SMALL
			if(WOUNDING_SMALL)
				return WOUNDING_INTERMEDIATE
			if(WOUNDING_INTERMEDIATE)
				return WOUNDING_NORMAL
			if(WOUNDING_NORMAL)
				return WOUNDING_WIDE
			if(WOUNDING_WIDE)
				return WOUNDING_EXTREME
			if(WOUNDING_EXTREME)
				return WOUNDING_EXTREME
	else
		switch(wounding)
			if(WOUNDING_TRIVIAL)
				return WOUNDING_TRIVIAL
			if(WOUNDING_TINY)
				return WOUNDING_TRIVIAL
			if(WOUNDING_SMALL)
				return WOUNDING_TINY
			if(WOUNDING_INTERMEDIATE)
				return WOUNDING_SMALL
			if(WOUNDING_NORMAL)
				return WOUNDING_INTERMEDIATE
			if(WOUNDING_WIDE)
				return WOUNDING_NORMAL
			if(WOUNDING_EXTREME)
				return WOUNDING_WIDE

/proc/step_wounding_double(wounding, is_increase = FALSE)
	if(is_increase)
		switch(wounding)
			if(WOUNDING_TRIVIAL)
				return WOUNDING_SMALL
			if(WOUNDING_TINY)
				return WOUNDING_INTERMEDIATE
			if(WOUNDING_SMALL)
				return WOUNDING_NORMAL
			if(WOUNDING_INTERMEDIATE)
				return WOUNDING_WIDE
			if(WOUNDING_NORMAL)
				return WOUNDING_EXTREME
			if(WOUNDING_WIDE)
				return WOUNDING_EXTREME
			if(WOUNDING_EXTREME)
				return WOUNDING_EXTREME
	else
		switch(wounding)
			if(WOUNDING_TRIVIAL)
				return WOUNDING_TRIVIAL
			if(WOUNDING_TINY)
				return WOUNDING_TRIVIAL
			if(WOUNDING_SMALL)
				return WOUNDING_TRIVIAL
			if(WOUNDING_INTERMEDIATE)
				return WOUNDING_TINY
			if(WOUNDING_NORMAL)
				return WOUNDING_SMALL
			if(WOUNDING_WIDE)
				return WOUNDING_INTERMEDIATE
			if(WOUNDING_EXTREME)
				return WOUNDING_NORMAL

// Determine wounding level. If var/wounding is provided, the attack should come from a projectile. This isn't the case yet, as we default to var/wounding = 1 until melee rework.
/proc/wound_check(injurytype, wounding, edge, sharp)
	if(sharp && (!edge)) // impaling/piercing, 2x damage, affected by injurytype
		switch(injurytype)
			if(INJURY_TYPE_HOMOGENOUS)
				return wounding ? step_wounding_double(wounding) : 1
			if(INJURY_TYPE_UNLIVING)
				return wounding ? step_wounding(wounding) : 1.5
			else
				return wounding ? wounding : 2
	if(sharp && edge) // cutting, 1.5x damage
		return wounding ? wounding : 1.5
	return wounding ? wounding : 1 // crushing, 1x damage
