/obj/effect/overmap/sector/exoplanet/volcanic
	planet_type = "volcanic"
	desc = "A tectonically unstable planet, extremely rich in minerals."
	//color = "#8e3900"
	planetary_area = /area/exoplanet/volcanic
	rock_colors = list(COLOR_DARK_GRAY)
	plant_colors = list("#a23c05","#3f1f0d","#662929","#ba6222","#7a5b3a","#120309")
	possible_themes = list()
	map_generators = list(/datum/random_map/automata/cave_system/mountains/volcanic, /datum/random_map/noise/exoplanet/volcanic)
	ruin_tags_blacklist = RUIN_HABITAT|RUIN_WATER
	planet_colors = list("#8e3900", COLOR_RED)
	surface_color = "#261e19"
	water_color = "#c74d00"

/obj/effect/overmap/sector/exoplanet/volcanic/get_atmosphere_color()
	return COLOR_GRAY20

/obj/effect/overmap/sector/exoplanet/volcanic/generate_habitability()
	return HABITABILITY_BAD

/obj/effect/overmap/sector/exoplanet/volcanic/generate_atmosphere()
	..()
	if(atmosphere)
		atmosphere.temperature = T20C + rand(220, 800)
		atmosphere.update_values()

/obj/effect/overmap/sector/exoplanet/volcanic/adapt_seed(datum/seed/S)
	..()
	S.set_trait(TRAIT_REQUIRES_WATER,0)
	S.set_trait(TRAIT_HEAT_TOLERANCE, 1000 + S.get_trait(TRAIT_HEAT_TOLERANCE))

/obj/effect/overmap/sector/exoplanet/volcanic/adapt_animal(mob/living/simple_animal/A)
	..()
	A.heat_damage_per_tick = 0 //animals not hot, no burning in lava

/datum/random_map/noise/exoplanet/volcanic
	descriptor = "volcanic exoplanet"
	smoothing_iterations = 5
	land_type = /turf/floor/exoplanet/volcanic
	water_type = /turf/floor/exoplanet/lava
	water_level_min = 5
	water_level_max = 6

	fauna_prob = 1
	flora_prob = 3
	large_flora_prob = 0
	flora_diversity = 3
	//fauna_types = list(/mob/living/simple_animal/thinbug)
	//megafauna_types = list(/mob/living/simple_animal/hostile/drake)

//Squashing most of 1 tile lava puddles
/datum/random_map/noise/exoplanet/volcanic/cleanup()
	for(var/x = 1, x <= limit_x, x++)
		for(var/y = 1, y <= limit_y, y++)
			var/current_cell = get_map_cell(x,y)
			if(noise2value(map[current_cell]) < water_level)
				continue
			var/frendos
			for(var/dx in list(-1,0,1))
				for(var/dy in list(-1,0,1))
					var/tmp_cell = get_map_cell(x+dx,y+dy)
					if(tmp_cell && tmp_cell != current_cell && noise2value(map[tmp_cell]) >= water_level)
						frendos = 1
						break
			if(!frendos)
				map[current_cell] = 1

/area/exoplanet/volcanic
	forced_ambience = list('sound/ambience/magma.ogg')
	base_turf = /turf/floor/exoplanet/volcanic

/turf/floor/exoplanet/volcanic
	name = "volcanic floor"
	icon = 'icons/turf/volcanic.dmi'
	icon_state = "basalt"
	dirt_color = COLOR_GRAY20

/turf/floor/exoplanet/volcanic/New()
	icon_state = "basalt[rand(0,12)]"
	..()

/datum/random_map/automata/cave_system/mountains/volcanic
	iterations = 2
	descriptor = "space volcanic mountains"
	wall_type =  /turf/mineral/volcanic
	mineral_sparse =  /turf/mineral/random/volcanic
	rock_color = COLOR_DARK_GRAY

/datum/random_map/automata/cave_system/mountains/volcanic/get_additional_spawns(value, turf/mineral/T)
	..()
	if(planetary_area)
		T.mined_turf = prob(90) ? planetary_area.base_turf : /turf/floor/exoplanet/lava

/turf/floor/exoplanet/lava
	name = "lava"
	icon = 'icons/turf/volcanic.dmi'
	icon_state = "lava"
	dirt_color = COLOR_GRAY20
	var/list/victims

/turf/floor/exoplanet/lava/update_icon()
	return

/turf/floor/exoplanet/lava/Initialize()
	. = ..()
	set_light(0.95, 0.5, 2, l_color = COLOR_ORANGE)

/turf/floor/exoplanet/lava/Destroy()
	STOP_PROCESSING(SSobj, src)
	. = ..()

/turf/floor/exoplanet/lava/Entered(atom/movable/AM)
	..()
	if(locate(/obj/structure/catwalk/) in src)
		return
//	var/mob/living/L = AM
	/*if (istype(L) && L.can_overcome_gravity())
		return*/
	//if(AM.is_burnable())
	LAZYADD(victims, WEAKREF(AM))
	START_PROCESSING(SSobj, src)

/turf/floor/exoplanet/lava/Exited(atom/movable/AM)
	. = ..()
	LAZYREMOVE(victims, WEAKREF(AM))

/turf/floor/exoplanet/lava/Process()
	if(locate(/obj/structure/catwalk/) in src)
		victims = null
		return PROCESS_KILL
	for(var/datum/weakref/W in victims)
		var/atom/movable/AM = W.resolve()
		if (AM == null || get_turf(AM) != src || !(isliving(AM) || isobj(AM)) || istype(AM,/obj/effect/effect/light)) //|| AM.is_burnable() == FALSE
			victims -= W
			continue
		var/datum/gas_mixture/environment = return_air()
		var/pressure = environment.return_pressure()
		var/destroyed = AM.lava_act(environment, 5000 + environment.temperature, pressure)
		if(destroyed == TRUE)
			victims -= W
	if(!LAZYLEN(victims))
		return PROCESS_KILL

/turf/mineral/volcanic
	name = "volcanic rock"
	color = COLOR_DARK_GRAY

/turf/mineral/random/volcanic
	name = "volcanic rock"
	color = COLOR_DARK_GRAY

/turf/mineral/random/high_chance/volcanic
	name = "volcanic rock"
	color = COLOR_DARK_GRAY
