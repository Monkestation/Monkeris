/datum/random_map/noise/tundra
	descriptor = "tundra"
	smoothing_iterations = 1

/datum/random_map/noise/tundra/replace_space
	descriptor = "tundra (replacement)"
	target_turf_type = /turf/space

/datum/random_map/noise/tundra/get_map_char(value)
	var/val = min(9,max(0,round((value/cell_range)*10)))
	if(isnull(val)) val = 0
	switch(val)
		if(0)
			return "<font color='#000099'>~</font>"
		if(1)
			return "<font color='#0000BB'>~</font>"
		if(2)
			return "<font color='#0000DD'>~</font>"
		if(3)
			return "<font color='#66AA00'>[pick(list(".",","))]</font>"
		if(4)
			return "<font color='#77CC00'>[pick(list(".",","))]</font>"
		if(5)
			return "<font color='#88DD00'>[pick(list(".",","))]</font>"
		if(6)
			return "<font color='#99EE00'>[pick(list(".",","))]</font>"
		if(7)
			return "<font color='#00BB00'>[pick(list("T","t"))]</font>"
		if(8)
			return "<font color='#00DD00'>[pick(list("T","t"))]</font>"
		if(9)
			return "<font color='#00FF00'>[pick(list("T","t"))]</font>"

/datum/random_map/noise/tundra/get_appropriate_path(value)
	var/val = min(9,max(0,round((value/cell_range)*10)))
	if(isnull(val)) val = 0
	switch(val)
		if(0 to 4)
			return /turf/floor/beach/water/ocean
		else
			return /turf/floor/snow

/datum/random_map/noise/tundra/get_additional_spawns(value, turf/T)
	var/val = min(9,max(0,round((value/cell_range)*10)))
	if(isnull(val)) val = 0
	switch(val)
		if(2)
			if(prob(5))
				new /mob/living/simple_animal/crab(T)
		if(6)
			if(prob(60))
				var/grass_path = pick(typesof(/obj/structure/flora/grass)-/obj/structure/flora/grass)
				new grass_path(T)
			if(prob(5))
				var/mob_type = pick(list(/mob/living/simple_animal/lizard, /mob/living/simple_animal/mouse))
				new mob_type(T)
		if(7)
			if(prob(60))
				new /obj/structure/flora/bush(T)
			else if(prob(30))
				new /obj/structure/flora/tree/pine(T)
			else if(prob(20))
				new /obj/structure/flora/tree/dead(T)
		if(8)
			if(prob(70))
				new /obj/structure/flora/tree/pine(T)
			else if(prob(30))
				new /obj/structure/flora/tree/dead(T)
			else
				new /obj/structure/flora/bush(T)
		if(9)
			new /obj/structure/flora/tree/pine(T)
