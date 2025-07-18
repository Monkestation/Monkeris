var/global/list/sparring_attack_cache = list()

//Species unarmed attacks
/datum/unarmed_attack
	var/attack_verb = list("attack")	// Empty hand hurt intent verb.
	var/attack_noun = list("fist")
	var/damage = 0						// Extra empty hand attack damage.
	var/attack_sound = "punch"
	var/miss_sound = 'sound/weapons/punchmiss.ogg'
	var/shredding = 0 // Calls the old attack_alien() behavior on objects/mobs when on harm intent.
	var/sharp = FALSE
	var/edge = FALSE

	var/deal_halloss
	var/sparring_variant_type = /datum/unarmed_attack/light_strike

/datum/unarmed_attack/proc/get_sparring_variant()
	if(sparring_variant_type)
		if(!sparring_attack_cache[sparring_variant_type])
			sparring_attack_cache[sparring_variant_type] = new sparring_variant_type()
		return sparring_attack_cache[sparring_variant_type]

/datum/unarmed_attack/proc/is_usable(mob/living/carbon/human/user, mob/living/carbon/human/target, datum/zone)
	if(user.restrained())
		return 0

	// Check if they have a functioning hand.
	var/obj/item/organ/external/E = user.organs_by_name[BP_L_ARM]
	if(E && !E.is_stump())
		return 1

	E = user.organs_by_name[BP_R_ARM]
	if(E && !E.is_stump())
		return 1

	return 0

/datum/unarmed_attack/proc/get_unarmed_damage()
	return damage

/datum/unarmed_attack/proc/apply_effects(mob/living/carbon/human/user,mob/living/carbon/human/target,attack_damage,datum/zone)

	if(target.stat == DEAD)
		return

	var/stun_chance = rand(0, 100)

	if(attack_damage >= 5 && !(target == user) && stun_chance <= attack_damage * 5) // 25% standard chance
		switch(zone) // strong punches can have effects depending on where they hit
			if(BP_HEAD, BP_MOUTH, BP_EYES)
				// Induce blurriness
				target.visible_message(
					span_danger("[target] looks momentarily disoriented."),
					span_danger("You see stars.")
				)
				target.apply_effect(attack_damage*2, EYE_BLUR)
			if(BP_L_ARM)
				if (target.l_hand)
					// Disarm left hand
					//Urist McAssistant dropped the macguffin with a scream just sounds odd. Plus it doesn't work with NO_PAIN
					target.visible_message(
						span_danger("\The [target.l_hand] was knocked right out of [target]'s grasp!")
					)
					target.drop_l_hand()
			if(BP_R_ARM)
				if (target.r_hand)
					// Disarm right hand
					target.visible_message(
						span_danger("\The [target.r_hand] was knocked right out of [target]'s grasp!")
					)
					target.drop_r_hand()
			if(BP_CHEST)
				if(!target.lying)
					var/turf/T = get_step(get_turf(target), get_dir(get_turf(user), get_turf(target)))
					if(!T.density)
						step(target, get_dir(get_turf(user), get_turf(target)))
						target.visible_message(
							span_danger(pick("[target] was sent flying backward!","[target] staggers back from the impact!"))
						)
					else
						target.visible_message(span_danger("[target] slams into [T]!"))
					if(prob(50))
						target.set_dir(GLOB.reverse_dir[target.dir])
					target.apply_effect(attack_damage * 0.4, WEAKEN)
			if(BP_GROIN)
				target.visible_message(
					span_warning("[target] looks like \he is in pain!"),
					span_warning((target.gender=="female") ? "Oh god that hurt!" : "Oh no, not your[pick("testicles", "crown jewels", "clockweights", "family jewels", "marbles", "bean bags", "teabags", "sweetmeats", "goolies")]!")
				)
				target.apply_effects(stutter = attack_damage * 2, agony = attack_damage* 3)
			if(BP_L_LEG, BP_R_LEG)
				if(!target.lying)
					target.visible_message(span_warning("[target] gives way slightly."))
					target.adjustHalLoss(attack_damage*3)
	else if(attack_damage >= 5 && !(target == user) && (stun_chance + attack_damage * 5 >= 100) ) // Chance to get the usual throwdown as well (25% standard chance)
		if(!target.lying)
			target.visible_message(span_danger("[target] [pick("slumps", "falls", "drops")] down to the ground!"))
		else
			target.visible_message(span_danger("[target] has been weakened!"))
		target.apply_effect(3, WEAKEN)

/datum/unarmed_attack/proc/show_attack(mob/living/carbon/human/user, mob/living/carbon/human/target, datum/zone, attack_damage)
	var/obj/item/organ/external/affecting = target.get_organ(zone)
	user.visible_message(span_warning("[user] [pick(attack_verb)] [target] in the [affecting.name]!"))
	playsound(user.loc, attack_sound, 25, 1, -1)

/datum/unarmed_attack/proc/handle_eye_attack(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/obj/item/organ/internal/eyes/eyes = target.random_organ_by_process(OP_EYES)
	eyes.take_damage(rand(6,10), BRUTE)

	user.visible_message(span_danger("[user] presses \his fingers into [target]'s [eyes.name]!")) //no need to check for claws because only humans(monkeys?) can grab(no, humans and monkeys don't have claws)
	to_chat(target, span_danger("You experience[(target.species.flags & NO_PAIN)? "" : " immense pain as you feel" ] digits being pressed into your [eyes.name][(target.species.flags & NO_PAIN)? "." : "!"]"))

/datum/unarmed_attack/bite
	attack_verb = list("bit")
	attack_sound = 'sound/weapons/bite.ogg'
	shredding = 0
	damage = 0
	sharp = FALSE
	edge = FALSE

/datum/unarmed_attack/bite/is_usable(mob/living/carbon/human/user, mob/living/carbon/human/target, datum/zone)

	if (user.wear_mask && (istype(user.wear_mask, /obj/item/clothing/mask/muzzle) || istype(user.wear_mask, /obj/item/grenade)))
		return 0
	if (user == target && (zone in list(BP_HEAD, BP_EYES, BP_MOUTH)))
		return 0
	return 1

/datum/unarmed_attack/punch
	attack_verb = list("punched")
	attack_noun = list("fist")
	damage = 0

/datum/unarmed_attack/punch/show_attack(mob/living/carbon/human/user, mob/living/carbon/human/target, datum/zone, attack_damage)
	var/obj/item/organ/external/affecting = target.get_organ(zone)
	var/organ = affecting.name

	attack_damage = CLAMP(attack_damage, 1, 5) // We expect damage input of 1 to 5 for this proc. But we leave this check juuust in case.

	if(target == user)
		user.visible_message(span_danger("[user] [pick(attack_verb)] \himself in the [organ]!"))
		return 0

	if(!target.lying)
		switch(zone)
			if(BP_HEAD, BP_MOUTH, BP_EYES)
				// ----- HEAD ----- //
				switch(attack_damage)
					if(1 to 2)
						user.visible_message(span_danger("[user] slapped [target] across \his cheek!"))
					if(3 to 4)
						user.visible_message(pick(
							40; span_danger("[user] [pick(attack_verb)] [target] in the head!"),
							30; span_danger("[user] struck [target] in the head[pick("", " with a closed fist")]!"),
							30; span_danger("[user] threw a hook against [target]'s head!")
							))
					if(5)
						user.visible_message(pick(
							30; span_danger("[user] gave [target] a resounding [pick("slap", "punch")] to the face!"),
							40; span_danger("[user] smashed \his [pick(attack_noun)] into [target]'s face!"),
							30; span_danger("[user] gave a strong blow against [target]'s jaw!")
							))
			else
				// ----- BODY ----- //
				switch(attack_damage)
					if(1 to 2)	user.visible_message(span_danger("[user] threw a glancing punch at [target]'s [organ]!"))
					if(1 to 4)	user.visible_message(span_danger("[user] [pick(attack_verb)] [target] in \his [organ]!"))
					if(5)
						user.visible_message(pick(
							50; span_danger("[user] smashed \his [pick(attack_noun)] into [target]'s [organ]!"),
							50; span_danger("[user] landed a striking [pick(attack_noun)] on [target]'s [organ]!")
							))
	else
		//why do we have a separate set of verbs for lying targets?
		user.visible_message(
			span_danger("[user] [pick("punched", "threw a punch against", "struck", "slammed their [pick(attack_noun)] into")] [target]'s [organ]!")
		)

/datum/unarmed_attack/kick
	attack_verb = list("kicked", "kicked", "kicked", "kneed")
	attack_noun = list("kick", "kick", "kick", "knee strike")
	attack_sound = "swing_hit"
	damage = 0

/datum/unarmed_attack/kick/is_usable(mob/living/carbon/human/user, mob/living/carbon/human/target, datum/zone)
	if (user.legcuffed)
		return 0

	if(!(zone in (BP_LEGS + BP_GROIN)))
		return 0

	var/obj/item/organ/external/E = user.organs_by_name[BP_L_LEG]
	if(E && !E.is_stump())
		return 1

	E = user.organs_by_name[BP_R_LEG]
	if(E && !E.is_stump())
		return 1

	return 0

/datum/unarmed_attack/kick/get_unarmed_damage(mob/living/carbon/human/user)
	var/obj/item/clothing/shoes = user.shoes
	if(!istype(shoes))
		return damage
	return damage + (shoes ? shoes.force : 0)

/datum/unarmed_attack/kick/show_attack(mob/living/carbon/human/user, mob/living/carbon/human/target, datum/zone, attack_damage)
	var/obj/item/organ/external/affecting = target.get_organ(zone)
	var/organ = affecting.name

	attack_damage = CLAMP(attack_damage, 1, 5)

	switch(attack_damage)
		if(1 to 2)	user.visible_message(span_danger("[user] threw [target] a glancing [pick(attack_noun)] to the [organ]!")) //it's not that they're kicking lightly, it's that the kick didn't quite connect
		if(3 to 4)	user.visible_message(span_danger("[user] [pick(attack_verb)] [target] in \his [organ]!"))
		if(5)		user.visible_message(span_danger("[user] landed a strong [pick(attack_noun)] against [target]'s [organ]!"))

/datum/unarmed_attack/stomp
	attack_verb = null
	attack_noun = list("stomp")
	attack_sound = "swing_hit"
	damage = 0

/datum/unarmed_attack/stomp/is_usable(mob/living/carbon/human/user, mob/living/carbon/human/target, datum/zone)

	if (user.legcuffed)
		return 0

	if(!istype(target))
		return 0

	if (!user.lying && (target.lying || (zone in list(BP_L_LEG, BP_R_LEG))))
		if(target.grabbed_by == user && target.lying)
			return 0
		var/obj/item/organ/external/E = user.organs_by_name[BP_L_LEG]
		if(E && !E.is_stump())
			return 1

		E = user.organs_by_name[BP_R_LEG]
		if(E && !E.is_stump())
			return 1

		return 0

/datum/unarmed_attack/stomp/get_unarmed_damage(mob/living/carbon/human/user)
	var/obj/item/clothing/shoes = user.shoes
	return damage + (shoes ? shoes.force : 0)

/datum/unarmed_attack/stomp/show_attack(mob/living/carbon/human/user, mob/living/carbon/human/target, datum/zone, attack_damage)
	var/obj/item/organ/external/affecting = target.get_organ(zone)
	var/organ = affecting.name
	var/obj/item/clothing/shoes = user.shoes

	attack_damage = CLAMP(attack_damage, 1, 5)

	switch(attack_damage)
		if(1 to 4)
			var/msg = pick(\
				"[user] stomped on [target]'s [organ]!",
				"[user] slammed \his [shoes ? copytext(shoes.name, 1, -1) : "foot"] down onto [target]'s [organ]!",
			)
			user.visible_message(span_danger(msg))
		if(5)
			//Devastated lol. No. We want to say that the stomp was powerful or forceful, not that it /wrought devastation/
			var/msg = pick(\
				"[user] landed a powerful stomp on [target]'s [organ]!",
				"[user] stomped down hard on [target]'s [organ]!",
				"[user] slammed \his [shoes ? copytext(shoes.name, 1, -1) : "foot"] down hard onto [target]'s [organ]!",
			)
			user.visible_message(span_danger(msg))

/datum/unarmed_attack/light_strike
	deal_halloss = 3
	attack_noun = list("tap","light strike")
	attack_verb = list("tapped", "lightly struck")
	damage = 2
	shredding = 0
	damage = 0
	sharp = FALSE
	edge = FALSE
