/obj/effect/overmap/sector/exoplanet/desert
	planet_type = "desert"
	desc = "An arid exoplanet with sparse biological resources but rich mineral deposits underground."
	//color = "#d6cca4"
	planetary_area = /area/exoplanet/desert
	rock_colors = list(COLOR_BEIGE, COLOR_PALE_YELLOW, COLOR_GRAY80, COLOR_BROWN)
	plant_colors = list("#efdd6f","#7b4a12","#e49135","#ba6222","#5c755e","#420d22")
	planet_colors = list(PIPE_COLOR_YELLOW, COLOR_AMBER)
	map_generators = list(/datum/random_map/noise/exoplanet/desert)
	surface_color = "#d6cca4"
	water_color = null


/obj/effect/overmap/sector/exoplanet/desert/generate_atmosphere()
	..()
	if(atmosphere)
		var/limit = 1000
		if(habitability_class <= HABITABILITY_OKAY)
			var/datum/species/human/H = /datum/species/human
			limit = initial(H.heat_level_1) - rand(1,10)
		atmosphere.temperature = min(T20C + rand(20, 100), limit)
		atmosphere.update_values()

/obj/effect/overmap/sector/exoplanet/desert/adapt_seed(datum/seed/S)
	..()
	if(prob(90))
		S.set_trait(TRAIT_REQUIRES_WATER,0)
	else
		S.set_trait(TRAIT_REQUIRES_WATER,1)
		S.set_trait(TRAIT_WATER_CONSUMPTION,1)
	if(prob(75))
		S.set_trait(TRAIT_STINGS,1)
	if(prob(75))
		S.set_trait(TRAIT_CARNIVOROUS,2)
	S.set_trait(TRAIT_SPREAD,0)

/datum/random_map/noise/exoplanet/desert
	descriptor = "desert exoplanet"
	smoothing_iterations = 4
	land_type = /turf/floor/exoplanet/desert

	flora_prob = 5
	large_flora_prob = 0
	flora_diversity = 4
	//fauna_types = list(/mob/living/simple_animal/thinbug, /mob/living/simple_animal/tindalos, /mob/living/simple_animal/hostile/voxslug, /mob/living/simple_animal/hostile/antlion)
	//megafauna_types = list(/mob/living/simple_animal/hostile/antlion/mega)

/datum/random_map/noise/exoplanet/desert/get_additional_spawns(value, turf/T)
	..()
	if(is_edge_turf(T))
		return
	var/v = noise2value(value)
	if(v > 6)
		T.icon_state = "desert[v-1]"
		if(prob(10))
			new/obj/structure/quicksand(T)

/area/exoplanet/desert
	ambience = list('sound/effects/wind/desert0.ogg','sound/effects/wind/desert1.ogg','sound/effects/wind/desert2.ogg','sound/effects/wind/desert3.ogg','sound/effects/wind/desert4.ogg','sound/effects/wind/desert5.ogg')
	base_turf = /turf/floor/exoplanet/desert

/turf/floor/exoplanet/desert
	name = "sand"
	dirt_color = "#ae9e66"

/turf/floor/exoplanet/desert/New()
	icon_state = "desert[rand(0,4)]"
	..()

/turf/floor/exoplanet/desert/fire_act(datum/gas_mixture/air, exposed_temperature, exposed_volume)
	if((temperature > T0C + 1700 && prob(5)) || temperature > T0C + 3000)
		SetName("molten silica")
		icon_state = "sandglass"
		diggable = 0

/obj/structure/quicksand
	name = "sand"
	icon = 'icons/obj/quicksand.dmi'
	icon_state = "intact0"
	density = 0
	anchored = 1
	can_buckle = 1
	buckle_dir = SOUTH
	var/exposed = 0
	var/busy

/obj/structure/quicksand/New()
	icon_state = "intact[rand(0,2)]"
	..()

/obj/structure/quicksand/user_unbuckle_mob(mob/user)
	if(buckled_mob && !user.stat && !user.restrained())
		if(busy)
			to_chat(user, span_warning("[buckled_mob] is already getting out, be patient."))
			return
		var/delay = 60
		if(user == buckled_mob)
			delay *=2
			user.visible_message(
				span_notice("\The [user] tries to climb out of \the [src]."),
				span_notice("You begin to pull yourself out of \the [src]."),
				span_notice("You hear water sloushing.")
				)
		else
			user.visible_message(
				span_notice("\The [user] begins pulling \the [buckled_mob] out of \the [src]."),
				span_notice("You begin to pull \the [buckled_mob] out of \the [src]."),
				span_notice("You hear water sloushing.")
				)
		busy = 1
		if(do_after(user, delay, src))
			busy = 0
			if(user == buckled_mob)
				if(prob(80))
					to_chat(user, span_warning("You slip and fail to get out!"))
					return
				user.visible_message(span_notice("\The [buckled_mob] pulls himself out of \the [src]."))
			else
				user.visible_message(span_notice("\The [buckled_mob] has been freed from \the [src] by \the [user]."))
			unbuckle_mob()
		else
			busy = 0
			to_chat(user, span_warning("You slip and fail to get out!"))
			return

/obj/structure/quicksand/unbuckle_mob()
	..()
	update_icon()

/obj/structure/quicksand/buckle_mob(mob/L)
	..()
	update_icon()

/obj/structure/quicksand/update_icon()
	if(!exposed)
		return
	icon_state = "open"
	cut_overlays()
	if(buckled_mob)
		overlays += buckled_mob
		var/image/I = image(icon,icon_state="overlay")
		I.layer = WALL_OBJ_LAYER
		overlays += I

/obj/structure/quicksand/proc/expose()
	if(exposed)
		return
	visible_message(span_warning("The upper crust breaks, exposing treacherous quicksands underneath!"))
	name = "quicksand"
	desc = "There is no candy at the bottom."
	exposed = 1
	update_icon()

/obj/structure/quicksand/attackby(obj/item/W, mob/user)
	if(!exposed && W.force)
		expose()
	else
		..()

/obj/structure/quicksand/Crossed(atom/movable/AM)
	if(isliving(AM))
		var/mob/living/L = AM
		if(L.throwing) //|| L.can_overcome_gravity()
			return
		buckle_mob(L)
		if(!exposed)
			expose()
		to_chat(L, span_danger("You fall into \the [src]!"))
