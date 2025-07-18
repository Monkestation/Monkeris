
/turf/floor/exoplanet
	name = "space land"
	icon = 'icons/turf/desert.dmi'
	icon_state = "desert"
	var/diggable = 1
	var/dirt_color = "#7c5e42"
	initial_flooring = null
/*
/turf/floor/exoplanet/can_engrave()
	return FALSE
*/
/turf/floor/exoplanet/New()
	if(CONFIG_GET(flag/use_overmap))
		var/obj/effect/overmap/sector/exoplanet/E = map_sectors["[z]"]
		if(istype(E))
			if(E.atmosphere)
				initial_gas = E.atmosphere.gas.Copy()
				temperature = E.atmosphere.temperature
			else
				initial_gas = list()
				temperature = T0C
			//Must be done here, as light data is not fully carried over by ChangeTurf (but overlays are).
			if(E.planetary_area && istype(loc, world.area))
				ChangeArea(src, E.planetary_area)

	seismic_activity = rand(1,6)
	..()

/turf/floor/exoplanet/attackby(obj/item/C, mob/user)
	/*if(diggable && istype(C,/obj/item/shovel))
		visible_message(span_notice("\The [user] starts digging \the [src]"))
		if(do_after(user, 50))
			to_chat(user,span_notice("You dig a deep pit."))
			new /obj/structure/pit(src)
			diggable = 0
		else
			to_chat(user,span_notice("You stop shoveling."))
	else if(istype(C, /obj/item/stack/tile))
		var/obj/item/stack/tile/T = C
		if(T.use(1))
			playsound(src, 'sound/items/Deconstruct.ogg', 80, 1)
			ChangeTurf(/turf/floor, FALSE, FALSE, TRUE)
	else
		..()*/

/turf/floor/exoplanet/explosion_act(target_power, explosion_handler/handler)
	if(target_power > health)
		ChangeTurf(get_base_turf_by_area(src))
	. = ..()

/*
/turf/floor/exoplanet/water/is_flooded(lying_mob, absolute)
	. = absolute ? ..() : lying_mob*/

/turf/floor/exoplanet/water/shallow
	name = "shallow water"
	icon = 'icons/misc/beach.dmi'
	icon_state = "seashallow"
	var/reagent_type = /datum/reagent/water

/turf/floor/exoplanet/water/shallow/attackby(obj/item/O, mob/living/user)
	var/obj/item/reagent_containers/RG = O
	if (reagent_type && istype(RG) && RG.is_open_container() && RG.reagents)
		RG.reagents.add_reagent(reagent_type, min(RG.volume - RG.reagents.total_volume, RG.amount_per_transfer_from_this))
		user.visible_message(span_notice("[user] fills \the [RG] from \the [src]."),span_notice("You fill \the [RG] from \the [src]."))
	else
		return ..()
/*
/turf/floor/exoplanet/water/update_dirt()
	return	// Water doesn't become dirty
*/
/turf/floor/exoplanet/Initialize()
	. = ..()
	update_icon(1)

/turf/floor/exoplanet/update_icon(update_neighbors)
	cut_overlays()
	if(LAZYLEN(decals))
		overlays += decals
	for(var/direction in GLOB.cardinal)
		var/turf/turf_to_check = get_step(src,direction)
		if(!istype(turf_to_check, type))
			var/image/rock_side = image(icon, "edge[pick(0,1,2)]", dir = turn(direction, 180))
			rock_side.plating_decal_layerise()
			switch(direction)
				if(NORTH)
					rock_side.pixel_y += world.icon_size
				if(SOUTH)
					rock_side.pixel_y -= world.icon_size
				if(EAST)
					rock_side.pixel_x += world.icon_size
				if(WEST)
					rock_side.pixel_x -= world.icon_size
			overlays += rock_side
		else if(update_neighbors)
			turf_to_check.update_icon()

/turf/floor/exoplanet/water/update_icon()
	return

/turf/planet_edge
	name = "world's edge"
	desc = "Government didn't want you to see this!"
	density = TRUE
	blocks_air = TRUE
	dynamic_lighting = FALSE
	icon = null
	icon_state = null

/turf/planet_edge/proc/MineralSpread()
	return

/turf/planet_edge/Initialize()
	. = ..()
	var/obj/effect/overmap/sector/exoplanet/E = map_sectors["[z]"]
	if(!istype(E))
		return
	var/nx = x
	if (x <= TRANSITIONEDGE)
		nx = x + (E.maxx - 2*TRANSITIONEDGE) - 1
	else if (x >= (E.maxx - TRANSITIONEDGE))
		nx = x - (E.maxx  - 2*TRANSITIONEDGE) + 1

	var/ny = y
	if(y <= TRANSITIONEDGE)
		ny = y + (E.maxy - 2*TRANSITIONEDGE) - 1
	else if (y >= (E.maxy - TRANSITIONEDGE))
		ny = y - (E.maxy - 2*TRANSITIONEDGE) + 1

	var/turf/NT = locate(nx, ny, z)
	if(NT)
		vis_contents = list(NT)

	//Need to put a mouse-opaque overlay there to prevent people turning/shooting towards ACTUAL location of vis_content things
	var/obj/effect/overlay/O = new(src)
	O.mouse_opacity = 2
	O.name = "distant terrain"
	O.desc = "You need to come over there to take a better look."

/turf/planet_edge/Bumped(atom/movable/A)
	. = ..()
	var/obj/effect/overmap/sector/exoplanet/E = map_sectors["[z]"]
	if(!istype(E))
		return
	if(E.planetary_area && istype(loc, world.area))
		ChangeArea(src, E.planetary_area)
	var/new_x = A.x
	var/new_y = A.y
	if(x <= TRANSITIONEDGE)
		new_x = E.maxx - TRANSITIONEDGE - 1
	else if (x >= (E.maxx - TRANSITIONEDGE))
		new_x = TRANSITIONEDGE + 1
	else if (y <= TRANSITIONEDGE)
		new_y = E.maxy - TRANSITIONEDGE - 1
	else if (y >= (E.maxy - TRANSITIONEDGE))
		new_y = TRANSITIONEDGE + 1

	var/turf/T = locate(new_x, new_y, A.z)
	if(T && !T.density)
		A.forceMove(T)
		if(isliving(A))
			var/mob/living/L = A
			if(L.pulling)
				var/atom/movable/AM = L.pulling
				AM.forceMove(T)


// Straight copy from space.
/turf/floor/exoplanet/attackby(obj/item/C as obj, mob/user as mob)
	if (istype(C, /obj/item/stack/rods))
		var/obj/structure/lattice/L = locate(/obj/structure/lattice, src)
		if(L)
			return
		var/obj/item/stack/rods/R = C
		if (R.use(1))
			to_chat(user, span_notice("Constructing support lattice ..."))
			playsound(src, 'sound/weapons/Genhit.ogg', 50, 1)
			ReplaceWithLattice()
		return

	if (istype(C, /obj/item/stack/material))
		var/obj/item/stack/material/M = C
		var/material/mat = M.get_material()
		if (!mat.name == MATERIAL_STEEL)
			return

		var/obj/structure/lattice/L = locate(/obj/structure/lattice, src)
		if(L)
			to_chat(user, span_notice("You start constructing underplating on the lattice."))
			playsound(src, 'sound/weapons/Genhit.ogg', 50, 1)
			if(do_after(user, (40 * user.stats.getMult(STAT_MEC, STAT_LEVEL_EXPERT, src))))
				qdel(L)
				M.use(1)
				ChangeTurf(/turf/floor/plating/under)
			return
		else
			to_chat(user, span_warning("The plating is going to need some support."))

	if(istype(C, /obj/item/stack/cable_coil))
		var/obj/item/stack/cable_coil/coil = C
		coil.turf_place(src, user)
		return

	else
		..(C,user)

/turf/floor/exoplanet/take_damage(damage, damage_type = BRUTE, ignore_resistance = FALSE)
	// Exoplanet turfs are indestructible, otherwise they can be destroyed at some point and expose metal plating
	return
