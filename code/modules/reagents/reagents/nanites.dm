// Nanobots blood drain per unit
#define NANOBOTS_BLOOD_DRAIN 0.003

/datum/reagent/nanites
	name = ""
	id = "dont use these"
	description = "Microscopic construction robots."
	taste_description = "slimey metal"
	reagent_state = SOLID
	color = "#696969" // ( ͡° ͜ʖ ͡°)
	metabolism = REM/2
	heating_point = 523
	heating_products = list("nanites")
	scannable = 1
	reagent_type = "Nanites"

/datum/reagent/nanites/proc/eat_blood(mob/living/carbon/M) // Yam !
	var/datum/reagent/organic/blood/B = M.get_blood()
	// blood regeneratin 0.1 u every tick so with NANOBOTS_BLOOD_DRAIN = 0.003 human can sustain 30u nanobots without losing blood
	if(B && B.volume)
		B.remove_self(volume * NANOBOTS_BLOOD_DRAIN)

/datum/reagent/nanites/proc/will_occur(mob/living/carbon/M, alien, location)
	if(location == CHEM_BLOOD)
		return TRUE

/datum/reagent/nanites/consumed_amount(mob/living/carbon/M, alien, location)
	if(will_occur(M, alien, location))
		return ..()
	else
		return 0

/datum/reagent/nanites/affect_blood(mob/living/carbon/M, alien, effect_multiplier)
	eat_blood(M)
	if(M.get_blood_volume() < M.total_blood_req + BLOOD_VOLUME_OKAY_MODIFIER)
		var/removed = consumed_amount() * (M.total_blood_req + BLOOD_VOLUME_OKAY_MODIFIER - M.get_blood_volume() / 100)
		removed = min(volume,removed)
		var/datum/reagents/metabolism/met = M.get_metabolism_handler(CHEM_BLOOD)
		met.remove_reagent(id, removed)
		met.add_reagent("nanodead", removed)
	if(will_occur(M, alien, CHEM_BLOOD))
		return TRUE

/datum/reagent/nanites/capped
	name = "Raw Industrial Nanobots"
	id = "nanites"
	description = "Microscopic construction robots. Useless without programming"
	heating_point = null
	heating_products = null

/datum/reagent/nanites/capped/will_occur(mob/living/carbon/M, alien, location)
	return FALSE

/datum/reagent/nanites/dead
	name = "Broken Nanobots"
	id = "nanodead"
	description = "Broken microscopic construction robots."
	taste_description = "slimey metal"
	color = "#535E66"
	metabolism = REM/4
	heating_point = null
	heating_products = null

/datum/reagent/nanites/dead/eat_blood(mob/living/carbon/M)
	return

/datum/reagent/nanites/dead/will_occur(mob/living/carbon/M, alien, location)
	return TRUE

/datum/reagent/nanites/dead/affect_blood(mob/living/carbon/M, alien, effect_multiplier)
	if(..())
		M.add_chemical_effect(CE_TOXIN, 2 * effect_multiplier)

/datum/reagent/nanites/uncapped
	name = "Raw Uncapped Nanobots"
	id = "uncap nanites"
	description = "Microscopic construction robots with safety overridden. Valuable, but useless without programming."
	heating_point = null
	heating_products = null

/datum/reagent/nanites/uncapped/will_occur(mob/living/carbon/M, alien, location)
	if(type == /datum/reagent/nanites/uncapped) // only derived classes are consumed
		return FALSE
	return TRUE

/datum/reagent/nanites/arad
	name = "A-rad"
	id = "arad nanites"
	description = "Microscopic construction robots programmed to aid body with radiation effects."

/datum/reagent/nanites/arad/will_occur(mob/living/carbon/M, alien, location)
	if(..() && M.radiation)
		return TRUE


/datum/reagent/nanites/arad/affect_blood(mob/living/carbon/M, alien, effect_multiplier)
	if(..())
		M.radiation = max(M.radiation - (5 + M.radiation * 0.10) * effect_multiplier, 0)


/datum/reagent/nanites/implant_medics
	name = "Implantoids"
	id = "implant nanites"
	description = "Microscopic construction robots programmed to repair implants."


/datum/reagent/nanites/implant_medics/will_occur(mob/living/carbon/M, alien, location)
	if(..() && ishuman(M))
		var/mob/living/carbon/human/H = M
		constant_metabolism = FALSE
		metabolism = initial(metabolism)
		for(var/obj/item/organ/organ in H.organs) //Grab the organ holding the implant.
			if((organ.damage > 0) && BP_IS_ROBOTIC(organ)) //only robotic organs
				return TRUE
			if(istype(organ, /obj/item/organ/external))
				var/obj/item/organ/external/E = organ
				for(var/obj/item/implant/I in E.implants)
					if(I.malfunction)
						metabolism = 1
						constant_metabolism = TRUE
						return TRUE

/datum/reagent/nanites/implant_medics/affect_blood(mob/living/carbon/M, alien, effect_multiplier)
	if(..() && ishuman(M))
		var/mob/living/carbon/human/H = M
		for(var/obj/item/organ/organ in H.organs) //Grab the organ holding the implant.
			if(metabolism == 1 && istype(organ, /obj/item/organ/external)) // if metabolism == 1 then broken implant is found see implant_medics/will_occur()
				var/obj/item/organ/external/E = organ
				for(var/obj/item/implant/I in E.implants)
					if(I.malfunction)
						I.restore()
						return
			else if (istype(organ, /obj/item/organ/external) && organ.damage > 0 && BP_IS_ROBOTIC(organ))
				organ.heal_damage((2 + organ.damage * 0.05)* effect_multiplier, (2 + organ.damage * 0.05)* effect_multiplier, 1, 1)
				return
			else if (istype(organ, /obj/item/organ/internal) && organ.damage > 0 && BP_IS_ROBOTIC(organ))
				organ.heal_damage((2 + organ.damage * 0.05)* effect_multiplier)
				return


/datum/reagent/nanites/nantidotes
	name = "Nantidotes"
	id = "nantidotes"
	description = "Microscopic construction robots programmed to purge bloodstream from any foreign bodies, except themselves."

/datum/reagent/nanites/nantidotes/will_occur(mob/living/carbon/M, alien, location)
	if(..() && M.bloodstr)
		for(var/current in M.bloodstr.reagent_list)
			if(!istype(current, /datum/reagent/nanites))
				return TRUE

/datum/reagent/nanites/nantidotes/affect_blood(mob/living/carbon/M, alien, effect_multiplier)
	if(..())
		if(M.bloodstr)
			for(var/current in M.bloodstr.reagent_list)
				var/datum/reagent/R = current
				if(!istype(current, /datum/reagent/nanites))
					R.remove_self(effect_multiplier * 1)

/datum/reagent/nanites/nanosymbiotes
	name = "Nanosymbiotes"
	id = "nanosymbiotes"
	description = "Microscopic construction robots programmed to heal body cells."

/datum/reagent/nanites/nanosymbiotes/will_occur(mob/living/carbon/M, alien, location)
	if(..() && (M.getBruteLoss() || M.getFireLoss() || M.getOxyLoss()))
		return TRUE

/datum/reagent/nanites/nanosymbiotes/affect_blood(mob/living/carbon/M, alien, effect_multiplier)
	if(..())
		M.add_chemical_effect(CE_ONCOCIDAL, 1)
		M.adjustOxyLoss(-(1 + (M.getOxyLoss() * 0.03)) * effect_multiplier)
		M.adjustFireLoss(-(1 + (M.getFireLoss() * 0.03)) * effect_multiplier)
		M.adjustBruteLoss(-(1 + (M.getBruteLoss() * 0.03)) * effect_multiplier)

/datum/reagent/nanites/oxyrush
	name = "Oxyrush"
	id = "oxyrush"
	description = "Microscopic construction robots programmed to keep oxygenation level stable no matter what."

/datum/reagent/nanites/oxyrush/will_occur(mob/living/carbon/M, alien, location)
	if(..() && M.getOxyLoss())
		return TRUE

/datum/reagent/nanites/oxyrush/affect_blood(mob/living/carbon/M, alien, effect_multiplier)
	if(..())
		M.adjustOxyLoss(-30 * effect_multiplier)
		M.add_chemical_effect(CE_OXYGENATED, 2)

/datum/reagent/nanites/trauma_control_system
	name = "Trauma Control System"
	id = "trauma_control_system"
	description = "Microscopic construction robots programmed to restore vitality of damaged organs."

/datum/reagent/nanites/trauma_control_system/will_occur(mob/living/carbon/M, alien, location)
	if(..() && ishuman(M))
		var/mob/living/carbon/human/H = M
		for(var/obj/item/organ/organ in H.organs) //Grab the organ holding the implant.
			if(organ.status & ORGAN_WOUNDED && !BP_IS_ROBOTIC(organ))
				return TRUE

/datum/reagent/nanites/trauma_control_system/affect_blood(mob/living/carbon/M, alien, effect_multiplier)
	if(..())
		M.add_chemical_effect(CE_ONCOCIDAL, 1)
		M.add_chemical_effect(CE_BLOODCLOT, 1)
		M.add_chemical_effect(CE_ANTITOX, 2)
		M.add_chemical_effect(CE_STABLE, 1)
		M.add_chemical_effect(CE_BRAINHEAL, 1)
		M.add_chemical_effect(CE_EYEHEAL, 1)

/datum/reagent/nanites/purgers
	name = "Purgers"
	id = "nanopurgers"
	description = "Microscopic construction robots programmed to purge bloodstream from any nanobots."

/datum/reagent/nanites/purgers/will_occur(mob/living/carbon/M, alien, location)
	if(..() && M.bloodstr)
		for(var/current in M.bloodstr.reagent_list)
			if(istype(current, /datum/reagent/nanites) && !istype(current, /datum/reagent/nanites/purgers))
				return TRUE

/datum/reagent/nanites/purgers/affect_blood(mob/living/carbon/M, alien, effect_multiplier)
	if(..())
		if(M.bloodstr)
			for(var/current in M.bloodstr.reagent_list)
				var/datum/reagent/R = current
				if(istype(current, /datum/reagent/nanites) && !istype(current, /datum/reagent/nanites/purgers))
					R.remove_self(effect_multiplier * 1)

/datum/reagent/nanites/uncapped/control_booster_utility
	name = "Control Booster Utility"
	id = "cbu"
	description = "Microscopic construction robots programmed to enchant immensively mental capabilities."
	heating_point = 523
	heating_products = list("uncap nanites")
	reagent_type = "Nanites/Stimulator"

/datum/reagent/nanites/uncapped/control_booster_utility/affect_blood(mob/living/carbon/M, alien, effect_multiplier)
	if(..())
		M.stats.addTempStat(STAT_MEC, STAT_LEVEL_ADEPT, STIM_TIME, "CBU")
		M.stats.addTempStat(STAT_BIO, STAT_LEVEL_ADEPT, STIM_TIME, "CBU")
		M.stats.addTempStat(STAT_COG, STAT_LEVEL_ADEPT, STIM_TIME, "CBU")

/datum/reagent/nanites/uncapped/control_booster_combat
	name = "Control Booster Combat"
	id = "cbc"
	description = "Microscopic construction robots programmed to enchant combat capabilites to maximum."
	heating_point = 523
	heating_products = list("uncap nanites")
	reagent_type = "Nanites/Stimulator"

/datum/reagent/nanites/uncapped/control_booster_combat/affect_blood(mob/living/carbon/M, alien, effect_multiplier)
	if(..())
		M.stats.addTempStat(STAT_VIG, STAT_LEVEL_ADEPT, STIM_TIME, "CBC")
		M.stats.addTempStat(STAT_TGH, STAT_LEVEL_ADEPT, STIM_TIME, "CBC")
		M.stats.addTempStat(STAT_ROB, STAT_LEVEL_ADEPT, STIM_TIME, "CBC")

/datum/reagent/nanites/uncapped/voice_mimic
	name = "Voice mimics"
	id = "nanovoice"
	description = "Microscopic construction robots programmed to change users voice. You should hit them first, just in case..."
	var/voiceName = "Unknown"
	heating_point = 523
	heating_products = list("uncap nanites")

/datum/reagent/nanites/uncapped/voice_mimic/affect_blood(mob/living/carbon/M, alien, effect_multiplier)
	if(..())
		M.add_chemical_effect(CE_VOICEMIMIC, voiceName)

/datum/reagent/nanites/uncapped/dynamic_handprints
	name = "Handyprints"
	id = "nanohands"
	description = "Microscopic construction robots programmed to change handprints while in bloodstream."
	var/uni_identity
	heating_point = 523
	heating_products = list("uncap nanites")

/datum/reagent/nanites/uncapped/dynamic_handprints/on_mob_add(mob/living/L)
	..()
	var/mob/living/carbon/human/host = L
	if(istype(host))
		for(var/mob/living/carbon/human/H in GLOB.human_mob_list)
			if(host != H && H.fingers_trace)
				host.fingers_trace = H.fingers_trace
				return

/datum/reagent/nanites/uncapped/dynamic_handprints/affect_blood(mob/living/carbon/M, alien, effect_multiplier)
	if(..())
		M.add_chemical_effect(CE_DYNAMICFINGERS, uni_identity)

// FBP med - simple nanites for dealing with wounds and applying robo-chem effects
/datum/reagent/nanites/fbp
	name = "simple nanobots"
	description = "Microscopic construction robots. Useless without programming and have limited use."
	id = "dont use these either"
	constant_metabolism = TRUE

/datum/reagent/nanites/fbp/will_occur(mob/living/carbon/M, alien, location)
	if(location == CHEM_INGEST)
		return TRUE

// "Blood" clot
/datum/reagent/nanites/fbp/repair
	name = "repair nanites"
	description = "Microscopic construction robots programmed to repair internal components."
	id = "fbp_repair"
	overdose = REAGENTS_OVERDOSE / 6

/datum/reagent/nanites/fbp/repair/affect_ingest(mob/living/carbon/M, alien, effect_multiplier)
	M.add_chemical_effect(CE_MECH_REPAIR, 0.75)	//This plus two other metals will be enough to heal wounds

/* Uncomment when CE_MECH_REPLENISH has a use
// "Blood" restore
/datum/reagent/nanites/fbp/replenish
	name = "replenishing nanobots"
	description = "Microscopic construction robots programmed to replenish internal fluids."
	id = "fbp_replenish"

/datum/reagent/nanites/fbp/replenish/affect_ingest(mob/living/carbon/M, alien, effect_multiplier)
	if(!..())
		return
	M.add_chemical_effect(CE_MECH_REPLENISH, 1)
*/
