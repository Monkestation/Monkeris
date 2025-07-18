
//Chemical Reagents - Initialises all /datum/reagent into a list indexed by reagent id
/proc/initialize_chemical_reagents()
	var/list/reagent_list = list()

	var/paths = subtypesof(/datum/reagent)

	for(var/path in paths)
		var/datum/reagent/D = new path()
		reagent_list[D.id] = D

	. = reagent_list

/datum/reagent
	var/name = ""
	var/id = "reagent"
	var/description = "A non-descript chemical."
	var/taste_description = "old rotten bandaids"
	var/taste_mult = 1 //how this taste compares to others. Higher values means it is more noticable
	var/datum/reagents/holder
	var/reagent_state = SOLID
	var/list/data
	var/volume = 0
	var/metabolism = REM // This would be 0.2 normally
	var/ingest_met = 0
	var/touch_met = 0
	var/dose = 0
	var/max_dose = 0
	var/overdose = 0
	var/addiction_threshold = 0
	var/addiction_chance = 0
	var/withdrawal_threshold = 0
	var/withdrawal_rate = REM * 2
	var/scannable = 0 // Shows up on health analyzers.
	var/affects_dead = 0
	var/glass_unique_appearance = FALSE
	var/glass_icon_state
	var/glass_name
	var/glass_desc
	var/glass_center_of_mass
	var/color = "#000000"
	var/color_weight = 1
	var/sanity_gain = 0
	var/list/taste_tag = list()
	var/sanity_gain_ingest = 0

	var/chilling_point
	var/chilling_message = "crackles and freezes!"
	var/chilling_sound = 'sound/effects/bubbles.ogg'
	var/list/chilling_products

	var/heating_point
	var/heating_message = "begins to boil!"
	var/heating_sound = 'sound/effects/bubbles.ogg'
	var/list/heating_products

	var/constant_metabolism = FALSE	// if metabolism factor should not change with volume or blood circulation

	var/nerve_system_accumulations = 5 // Nerve system accumulations

	// Catalog stuff
	var/appear_in_default_catalog = TRUE
	var/reagent_type = "FIX DAT SHIT IMIDIATLY"
	var/price_per_unit = 0.125

/datum/reagent/proc/remove_self(amount) // Shortcut
	holder.remove_reagent(id, amount)

/datum/reagent/proc/consumed_amount(mob/living/carbon/M, alien, location)
	if(ishuman(M))
		return consumed_amount_human(M, alien,location) // Since humans should scale off livers , hearts and stomachs
	var/removed = metabolism
	if(location == CHEM_INGEST)
		if(ingest_met)
			removed = ingest_met
		else
			removed = removed/2
	if(touch_met && (location == CHEM_TOUCH))
		removed = touch_met
	// on half of overdose, chemicals will start be metabolized faster,
	// also blood circulation affects chemical strength (meaining if target has low blood volume or has something that lowers blood circulation chemicals will be consumed less and effect will diminished)
	if(location == CHEM_BLOOD)
		if(!constant_metabolism)
			if(overdose)
				removed = CLAMP(metabolism * volume/(overdose/2) * M.get_blood_circulation()/100, metabolism * REAGENTS_MIN_EFFECT_MULTIPLIER, metabolism * REAGENTS_MAX_EFFECT_MULTIPLIER)
			else
				removed = CLAMP(metabolism * volume/(REAGENTS_OVERDOSE/2) * M.get_blood_circulation()/100, metabolism * REAGENTS_MIN_EFFECT_MULTIPLIER, metabolism * REAGENTS_MAX_EFFECT_MULTIPLIER)
	removed = max(round(removed, 0.01), 0.01)
	removed = min(removed, volume)

	return removed

/datum/reagent/proc/consumed_amount_human(mob/living/carbon/human/consumer, alien, location)
	var/removed = metabolism
	if(location == CHEM_INGEST)
		var/calculated_buff = ((consumer.get_organ_efficiency(OP_LIVER) + consumer.get_organ_efficiency(OP_HEART) + consumer.get_organ_efficiency(OP_STOMACH)) / 3) / 100
		if(ingest_met)
			removed = ingest_met * calculated_buff
		else
			removed = (metabolism / 2) * calculated_buff
	if(touch_met && (location == CHEM_TOUCH))
		removed = touch_met // This doesn't get a buff , there is no organ that can count for this , really.
	// on half of overdose, chemicals will start be metabolized faster,
	// also blood circulation affects chemical strength (meaining if target has low blood volume or has something that lowers blood circulation chemicals will be consumed less and effect will diminished)
	if(location == CHEM_BLOOD)
		var/calculated_buff = ((consumer.get_organ_efficiency(OP_LIVER) + consumer.get_organ_efficiency(OP_HEART) * 2) / 3) / 100
		if(!constant_metabolism)
			if(overdose)
				removed = CLAMP(metabolism * volume/(overdose/2) * consumer.get_blood_circulation()/100 * calculated_buff, metabolism * REAGENTS_MIN_EFFECT_MULTIPLIER, metabolism * REAGENTS_MAX_EFFECT_MULTIPLIER)
			else
				removed = CLAMP(metabolism * volume/(REAGENTS_OVERDOSE/2) * consumer.get_blood_circulation()/100 * calculated_buff, metabolism * REAGENTS_MIN_EFFECT_MULTIPLIER, metabolism * REAGENTS_MAX_EFFECT_MULTIPLIER)
	removed = max(round(removed, 0.01), 0.01)
	removed = min(removed, volume)

	return removed

// "Removed" to multiplier
// will return multiplier of how much value is more or less than default metabolism amount
// all chem effects should be multiplied by return of this proc
/datum/reagent/proc/RTM(removed, location)
	if(ingest_met && location == CHEM_INGEST)
		return removed/ingest_met
	if(touch_met && location == CHEM_TOUCH)
		return removed/touch_met
	return removed/metabolism

// reverse convertion
/datum/reagent/proc/MTR(RTM, location)
	if(ingest_met && location == CHEM_INGEST)
		return ingest_met * RTM
	if(touch_met && location == CHEM_TOUCH)
		return touch_met * RTM
	return metabolism * RTM


// This doesn't apply to skin contact - this is for, e.g. extinguishers and sprays.
// The difference is that reagent is not directly on the mob's skin - it might just be on their clothing.
/datum/reagent/proc/touch_mob(mob/M, amount)
	return

/datum/reagent/proc/touch_obj(obj/O, amount) // Acid melting, cleaner cleaning, etc
	return

/datum/reagent/proc/touch_turf(turf/T, amount) // Cleaner cleaning, lube lubbing, etc, all go here
	return

// Called when this reagent is first added to a mob
/datum/reagent/proc/on_mob_add(mob/living/L)

// Called when this reagent is removed while inside a mob
/datum/reagent/proc/on_mob_delete(mob/living/L)
	var/mob/living/carbon/C = L
	if(istype(C))
		C.metabolism_effects.remove_nsa(id)
	return

// Currently, on_mob_life is only called on carbons. Any interaction with non-carbon mobs (lube) will need to be done in touch_mob.
/datum/reagent/proc/on_mob_life(mob/living/carbon/M, alien, location)
	if(!istype(M))
		return FALSE
	if(!affects_dead && M.stat == DEAD)
		return FALSE

	var/removed = consumed_amount(M, alien, location)

	max_dose = max(volume, max_dose)
	dose = min(dose + removed, max_dose)
	if(overdose && (dose > overdose) && (location != CHEM_TOUCH))
		overdose(M, alien)
	if(removed >= (metabolism * 0.1) || removed >= 0.1) // If there's too little chemical, don't affect the mob, just remove it
		switch(location)
			if(CHEM_BLOOD)
				affect_blood(M, alien, RTM(removed, location))
			if(CHEM_INGEST)
				affect_ingest(M, alien, RTM(removed, location))
			if(CHEM_TOUCH)
				affect_touch(M, alien, RTM(removed, location))
	// At this point, the reagent might have removed itself entirely - safety check
	if(volume && holder)
		remove_self(removed)
	return TRUE

/datum/reagent/proc/apply_sanity_effect(mob/living/carbon/human/H, effect_multiplier)
	if(!ishuman(H))
		return
	else
		H.sanity.onReagent(src, effect_multiplier)

/datum/reagent/proc/affect_blood(mob/living/carbon/M, alien, effect_multiplier)

/datum/reagent/proc/affect_ingest(mob/living/carbon/M, alien, effect_multiplier)
	affect_blood(M, alien, effect_multiplier * 0.8)	// some of chemicals lost in digestive process

	apply_sanity_effect(M, effect_multiplier)

/datum/reagent/proc/affect_touch(mob/living/carbon/M, alien, effect_multiplier)

/datum/reagent/proc/overdose(mob/living/carbon/M, alien) // Overdose effect. Doesn't happen instantly.
	M.add_chemical_effect(CE_TOXIN, dose / 4)
	return

/datum/reagent/proc/create_overdose_wound(obj/item/organ/internal/I, mob/user, datum/component/internal_wound/base_type, wound_descriptor = "poisoning", silent = FALSE)
	if(!istype(I))
		return
	if(I.nature != initial(base_type.wound_nature))
		return

	var/wound_path = pick(subtypesof(base_type))
	var/wound_name = "[name] [wound_descriptor]"
	I.add_wound(wound_path, wound_name)
	if(!silent && BP_IS_ORGANIC(I))
		to_chat(user, span_warning("You feel a sharp pain in your [I.parent.name]."))

/datum/reagent/proc/initialize_data(newdata) // Called when the reagent is created.
	if(!isnull(newdata))
		data = newdata
	return

/datum/reagent/proc/mix_data(newdata, newamount) // You have a reagent with data, and new reagent with its own data get added, how do you deal with that?
	if(!data)
		data = list()
	return

/datum/reagent/proc/get_data() // Just in case you have a reagent that handles data differently.
	if(data && istype(data, /list))
		return data.Copy()
	else if(data)
		return data
	return null

// Addiction
// Addiction
/datum/reagent/proc/addiction_act_stage1(mob/living/carbon/human/M)
	if(prob(30))
		to_chat(M, span_notice("You feel like having some [name] right about now."))

/datum/reagent/proc/addiction_act_stage2(mob/living/carbon/human/M)
	if(prob(30))
		to_chat(M, span_notice("You feel like you need [name]. You just can't get enough."))

/datum/reagent/proc/addiction_act_stage3(mob/living/carbon/human/M)
	if(prob(30))
		to_chat(M, span_danger("You have an intense craving for [name]."))
		M.sanity.changeLevel(-5)

/datum/reagent/proc/addiction_act_stage4(mob/living/carbon/human/M)
	if(prob(30))
		to_chat(M, span_danger("You're not feeling good at all! You really need some [name]."))
		M.sanity.changeLevel(-10)

/datum/reagent/proc/addiction_end(mob/living/carbon/human/M)
	to_chat(M, span_notice("You feel like you've gotten over your need for [name]."))
	M.sanity.changeLevel(15)

// Withdrawal
/datum/reagent/proc/withdrawal_start(mob/living/carbon/M)
	return

/datum/reagent/proc/withdrawal_act(mob/living/carbon/M)
	return

/datum/reagent/proc/withdrawal_end(mob/living/carbon/M)
	return


/datum/reagent/Destroy() // This should only be called by the holder, so it's already handled clearing its references
	. = ..()
	holder = null

/* DEPRECATED - TODO: REMOVE EVERYWHERE */

/datum/reagent/proc/reaction_turf(turf/target)
	touch_turf(target)

/datum/reagent/proc/reaction_obj(obj/target)
	touch_obj(target)

/datum/reagent/proc/reaction_mob(mob/target)
	touch_mob(target)

/datum/reagent/proc/custom_temperature_effects(temperature)
	return
