/datum/reagent/organic/blood
	data = new/list("donor" = null, "viruses" = null, "species" = SPECIES_HUMAN, "blood_DNA" = null, "blood_type" = null, "blood_colour" = "#A10808", "resistances" = null, "trace_chem" = null, "antibodies" = list(), "carrion" = null)
	name = "Blood"
	id = "blood"
	reagent_state = LIQUID
	metabolism = REM * 5
	color = "#C80000"
	taste_description = "iron"
	taste_mult = 1.3
	glass_icon_state = "glass_red"
	glass_name = "tomato juice"
	glass_desc = "Are you sure this is tomato juice?"
	affects_dead = TRUE
	nerve_system_accumulations = 0

/datum/reagent/organic/blood/initialize_data(newdata)
	..()
	if(data && data["blood_colour"])
		color = data["blood_colour"]
	return

/datum/reagent/organic/blood/get_data() // Just in case you have a reagent that handles data differently.
	var/T = data.Copy()
	return T

/datum/reagent/organic/blood/touch_turf(turf/T)
	if(!istype(T) || volume < 3)
		return TRUE
	if(!data["donor"] || istype(data["donor"], /mob/living/carbon/human))
		blood_splatter(T, src, 1)
	return TRUE

/datum/reagent/organic/blood/affect_ingest(mob/living/carbon/M, alien, effect_multiplier)
	var/effective_dose = dose
	if(issmall(M)) effective_dose *= 2

	if(effective_dose > 5)
		M.add_chemical_effect(CE_TOXIN, effect_multiplier)
	if(effective_dose > 15)
		M.add_chemical_effect(CE_TOXIN, effect_multiplier)

/datum/reagent/organic/blood/affect_blood(mob/living/carbon/M, alien, effect_multiplier)
	M.inject_blood(src, volume)
	remove_self(volume)

#define WATER_LATENT_HEAT 19000 // How much heat is removed when applied to a hot turf, in J/unit (19000 makes 120 u of water roughly equivalent to 4L)
/datum/reagent/water
	name = "Water"
	id = "water"
	description = "A ubiquitous chemical substance that is composed of hydrogen and oxygen."
	reagent_state = LIQUID
	color = "#0064C877"
	metabolism = REM * 10
	taste_description = "water"
	glass_icon_state = "glass_clear"
	glass_name = "water"
	glass_desc = "The father of all refreshments."
	nerve_system_accumulations = 0
	reagent_type = "Water"

/datum/reagent/water/touch_turf(turf/T)
	if(!istype(T))
		return TRUE

	var/datum/gas_mixture/environment = T.return_air()
	var/min_temperature = T0C + 100 // 100C, the boiling point of water

	var/hotspot = (locate(/obj/fire) in T)
	if(hotspot && !istype(T, /turf/space))
		var/datum/gas_mixture/lowertemp = T.remove_air(T:air:total_moles)
		lowertemp.temperature = max(min(lowertemp.temperature-2000, lowertemp.temperature / 2), 0)
		lowertemp.react()
		T.assume_air(lowertemp)
		qdel(hotspot)

	if (environment && environment.temperature > min_temperature) // Abstracted as steam or something
		var/removed_heat = between(0, volume * WATER_LATENT_HEAT, -environment.get_thermal_energy_change(min_temperature))
		environment.add_thermal_energy(-removed_heat)
		if (prob(5))
			T.visible_message(span_warning("The water sizzles as it lands on \the [T]!"))

	else if(volume >= 10)
		T.wet_floor(1)
	return TRUE

/datum/reagent/water/touch_obj(obj/O)
	if(istype(O, /obj/item/reagent_containers/food/snacks/monkeycube))
		var/obj/item/reagent_containers/food/snacks/monkeycube/cube = O
		if(!cube.wrapped)
			cube.Expand()

/datum/reagent/water/touch_mob(mob/living/L, amount)
	if(istype(L))
		L.fire_stacks = 0
		L.ExtinguishMob()
		/*
		var/needed = L.fire_stacks * 10
		if(amount > needed)
			L.fire_stacks = 0
			L.ExtinguishMob()
			remove_self(needed)
		else
			L.adjust_fire_stacks(-(amount / 10))
			remove_self(amount)
		*/

/datum/reagent/water/affect_touch(mob/living/carbon/M, alien, effect_multiplier)
	if(isslime(M))
		var/mob/living/carbon/slime/S = M
		S.adjustToxLoss(7 * effect_multiplier)
		if(!S.client)
			if(S.Target) // Like cats
				S.Target = null
				++S.Discipline
		if(dose >= MTR(effect_multiplier, CHEM_TOUCH))
			S.visible_message(span_warning("[S]'s flesh sizzles where the water touches it!"), span_danger("Your flesh burns in the water!"))

/datum/reagent/toxin/fuel
	name = "Welding fuel"
	id = "fuel"
	description = "Required for welders. Flamable."
	taste_description = "gross metal"
	reagent_state = LIQUID
	color = "#660000"
	touch_met = 5

	glass_icon_state = "dr_gibb_glass"
	glass_name = "welder fuel"
	glass_desc = "Unless you are an industrial tool, this is probably not safe for consumption."

/datum/reagent/toxin/fuel/touch_turf(turf/T)
	new /obj/effect/decal/cleanable/liquid_fuel(T, volume)
	remove_self(volume)
	return TRUE

/datum/reagent/toxin/fuel/affect_blood(mob/living/carbon/M, alien, effect_multiplier)
	M.add_chemical_effect(CE_TOXIN, 2 * (issmall(M) ? effect_multiplier * 2 : effect_multiplier))

/datum/reagent/toxin/fuel/touch_mob(mob/living/L, amount)
	if(istype(L))
		L.adjust_fire_stacks(amount / 10) // Splashing people with welding fuel to make them easy to ignite!

