/obj/effect/overmap/sector/exoplanet/grass
	planet_type = "lush"
	desc = "Planet with abundant flora and fauna."
	//color = "#538224"
	planetary_area = /area/exoplanet/grass
	rock_colors = list(COLOR_ASTEROID_ROCK, COLOR_GRAY80, COLOR_BROWN)
	plant_colors = list("#0e1e14","#1a3e38","#5a7467","#9eab88","#6e7248", "RANDOM")
	planet_colors = list(COLOR_TEAL, COLOR_PALE_GREEN_GRAY)
	map_generators = list(/datum/random_map/noise/exoplanet/grass)

/obj/effect/overmap/sector/exoplanet/grass/generate_atmosphere()
	..()
	if(atmosphere)
		atmosphere.temperature = T20C + rand(10, 30)
		atmosphere.update_values()

/obj/effect/overmap/sector/exoplanet/grass/get_surface_color()
	return grass_color

/obj/effect/overmap/sector/exoplanet/grass/adapt_seed(datum/seed/S)
	..()
	var/carnivore_prob = rand(100)
	if(carnivore_prob < 30)
		S.set_trait(TRAIT_CARNIVOROUS,2)
		if(prob(75))
			S.get_trait(TRAIT_STINGS, 1)
	else if(carnivore_prob < 60)
		S.set_trait(TRAIT_CARNIVOROUS,1)
		if(prob(50))
			S.get_trait(TRAIT_STINGS)
	if(prob(15) || (S.get_trait(TRAIT_CARNIVOROUS) && prob(40)))
		S.set_trait(TRAIT_BIOLUM,1)
		S.set_trait(TRAIT_BIOLUM_COLOUR,get_random_colour(0,75,190))

	if(prob(30))
		S.set_trait(TRAIT_PARASITE,1)
	if(!S.get_trait(TRAIT_LARGE))
		var/vine_prob = rand(100)
		if(vine_prob < 15)
			S.set_trait(TRAIT_SPREAD,2)
		else if(vine_prob < 30)
			S.set_trait(TRAIT_SPREAD,1)

/area/exoplanet/grass
	base_turf = /turf/floor/exoplanet/grass
	ambience = list('sound/effects/wind/wind_2_1.ogg','sound/effects/wind/wind_2_2.ogg','sound/effects/wind/wind_3_1.ogg','sound/effects/wind/wind_4_1.ogg','sound/ambience/eeriejungle2.ogg','sound/ambience/eeriejungle1.ogg')

/area/exoplanet/grass/play_ambience(mob/living/L)
	..()
	if(!L.ear_deaf && L.client && !L.client.ambience_playing)
		L.client.ambience_playing = 1
		L.playsound_local(get_turf(L),sound('sound/ambience/jungle.ogg', repeat = 1, wait = 0, volume = 25, channel = GLOB.ambience_sound_channel))

/datum/random_map/noise/exoplanet/grass
	descriptor = "grass exoplanet"
	smoothing_iterations = 2
	land_type = /turf/floor/exoplanet/grass
	water_type = /turf/floor/exoplanet/water/shallow

	flora_prob = 10
	large_flora_prob = 30
	flora_diversity = 6
	//fauna_types = list(/mob/living/simple_animal/yithian, /mob/living/simple_animal/tindalos, /mob/living/simple_animal/hostile/retaliate/jelly)
	//megafauna_types = list(/mob/living/simple_animal/hostile/retaliate/parrot/space/megafauna)

/turf/floor/exoplanet/grass
	name = "grass"
	icon = 'icons/turf/jungle.dmi'
	icon_state = "greygrass"
	color = "#799c4b"

/turf/floor/exoplanet/grass/Initialize()
	. = ..()
	if(CONFIG_GET(flag/use_overmap))
		var/obj/effect/overmap/sector/exoplanet/E = map_sectors["[z]"]
		if(istype(E) && E.grass_color)
			color = E.grass_color

/turf/floor/exoplanet/grass/fire_act(datum/gas_mixture/air, exposed_temperature, exposed_volume)
	if((temperature > T0C + 200 && prob(5)) || temperature > T0C + 1000)
		SetName("scorched ground")
		icon_state = "scorched"
		color = null
