//Wireweeds are created by the AI's nanites to spread its connectivity through the ship.
//When they reach any machine, they annihilate them and re-purpose them to the AI's needs. They are the 'hands' of our rogue AI.
//The three acids and chlorine, a strong oxidizer of metals, are killer reagents

/obj/effect/plant/hivemind
	layer = 2
	health = 		80
	max_health = 	80 		//we are a little bit durable
	spread_chance = 100
	var/list/killer_reagents = list("pacid", "sacid", "hclacid", "chlorine")
	//internals
	var/obj/machinery/hivemind_machine/node/node_weed_owner
	var/list/wires_connections = list("0", "0", "0", "0")
	var/areaName

/obj/effect/plant/hivemind/New()
	..()
	icon = 'icons/obj/hivemind.dmi'
	spawn(2)
		update_neighbors()

/obj/effect/plant/hivemind/Destroy()
	if(node_weed_owner)
		node_weed_owner.my_wireweeds.Remove(src)
	return ..()


/obj/effect/plant/hivemind/after_spread(obj/effect/plant/child, turf/target_turf)
	if(node_weed_owner)
		node_weed_owner.add_wireweed(child)
	spawn(1)
		child.dir = get_dir(loc, target_turf) //actually this means nothing for wires, but need for animation
		flick("spread_anim", child)
		child.forceMove(target_turf)
		for(var/obj/effect/plant/hivemind/neighbor in range(1, child))
			neighbor.update_neighbors()


/obj/effect/plant/hivemind/proc/try_assimilate_machinery()
	for(var/obj/machinery/machine_on_my_tile in loc)
		var/can_assimilate = TRUE
		if(machine_on_my_tile.alpha == 0) //which mean that machine is already assimilated
			continue

		//whitelist check
		if(is_type_in_list(machine_on_my_tile, hivemind_ai.list_of_dont_assimilate))
			can_assimilate = FALSE

		//failure chance to convert machine. Then it lower, then faster hivemind learn how to properly assimilate it
		// if(can_assimilate)
		// 	can_assimilate = FALSE
		// 	anim_shake(machine_on_my_tile)
		// 	return

		 //only one machine per turf
		if(can_assimilate && !locate(/obj/machinery/hivemind_machine) in loc)
			assimilate(machine_on_my_tile)
			return

	//modular computers handling
	var/obj/item/modular_computer/console/console = locate() in loc
	if(console && console.alpha != 0)
		assimilate(console)

	//dead bodies handling
	for(var/mob/living/dead_body in loc)
		if(dead_body.stat == DEAD)
			assimilate(dead_body)






/obj/effect/plant/hivemind/proc/assimilate(atom/subject)
	// Machhinery or console? Hide them and  spawn hivemind_machine on top
	if(istype(subject, /obj/machinery) || istype(subject, /obj/item/modular_computer/console))
		var/obj/machinery/hivemind_machine/created_machine
		var/amount_of_hivenodes = LAZYLEN(hivemind_ai.list_of_hive_nodes)
		//New node creation
		if(amount_of_hivenodes < MAX_NODES_AMOUNT)
			var/evopoints_range = amount_of_hivenodes * (hivemind_ai.evo_points_max / MAX_NODES_AMOUNT)	// amount_of_hivenodes * (1000 / 10)
			if(hivemind_ai.evo_points > evopoints_range) 												//one hive per: max_evopoints / max_nodes_amount
				var/can_spawn_new_node = TRUE
				for(var/obj/machinery/hivemind_machine/node/other_node in hivemind_ai.list_of_hive_nodes)
					if(get_dist(other_node, subject) < MIN_NODES_RANGE)
						can_spawn_new_node = FALSE
						break
				if(can_spawn_new_node)
					created_machine = new /obj/machinery/hivemind_machine/node(get_turf(subject))

		//Here we have a little chance to spawn our machinery horror
		if(istype(subject, /obj/machinery))
			var/obj/machinery/victim = subject
			if(prob(15) && victim.circuit)
				new /mob/living/simple_animal/hostile/hivemind/mechiver(get_turf(subject))
				new victim.circuit.type(get_turf(subject))
				qdel(subject)
				return

		//New hivemind machine creation
		if(!created_machine)
			var/list/possible_machines = list()
			//here we compare hivemind's evopoints level with machine's required value
			for(var/hivemachine_path in hivemind_ai.evopoints_price_list)
				var/list/machine_list = hivemind_ai.evopoints_price_list[hivemachine_path]
				if(hivemind_ai.evo_level >= machine_list["level"])
					possible_machines.Add(hivemachine_path)
					//setting of weight of machine
					possible_machines[hivemachine_path] = machine_list["weight"]

			var/picked_machine = pickweight(possible_machines)
			created_machine = new picked_machine(get_turf(subject))

		if(created_machine)
			created_machine.corrupt_machinery(subject)

	//Corpse reanimation
	if(isliving(subject) && !ishivemindmob(subject))
		//human bodies
		if(ishuman(subject))
			var/mob/living/L = subject
			//if our target has cruciform, let's just leave it
			if(is_neotheology_disciple(L))
				return
			for(var/obj/item/W in L)
				L.drop_from_inventory(W)
			var/M = pick(/mob/living/simple_animal/hostile/hivemind/himan, /mob/living/simple_animal/hostile/hivemind/phaser)
			new M(loc)
		//robot corpses
		else if(issilicon(subject))
			new /mob/living/simple_animal/hostile/hivemind/hiborg(loc)
		//other dead bodies
		else
			var/mob/living/simple_animal/hostile/hivemind/resurrected/transformed_mob =  new(loc)
			transformed_mob.take_appearance(subject)

		qdel(subject)


/obj/effect/plant/hivemind/update_neighbors()
	..()
	update_connections()
	update_icon()
	update_openspace()


/obj/effect/plant/hivemind/spread()
	if(!hivemind_ai || !node_weed_owner || !neighbors.len)
		return

	var/turf/target_turf = pick(neighbors)
	if(target_turf.is_hole && !GLOB.hive_data_bool["spread_on_lower_z_level"])
		// Not removed from neighbors, in case settings are change later
		return

	target_turf = get_connecting_turf(target_turf, loc)
	var/area/target_area = get_area(target_turf)

	// Entering the area for the first time
	if(!(target_area.name in GLOB.hivemind_areas))
		// If area limit is disabled (set to 0), or less than current number of occupied areas - expand and mark that area as occupied
		if(!GLOB.hive_data_float["maximum_controlled_areas"] || GLOB.hivemind_areas.len < GLOB.hive_data_float["maximum_controlled_areas"])
			GLOB.hivemind_areas.Add(target_area.name)
		else
			return

	// Track amount of weed in the area, so at 0 weed area would be marked as unoccupied
	GLOB.hivemind_areas[target_area.name]++

	for(var/i in target_turf.contents)
		if(istype(i, /obj/effect/plant) || istype(i, /obj/effect/dead_plant))
			visible_message("[src] consumes [i]!")
			qdel(i)

	// Created on the same loc, for move animation to play properly
	var/obj/effect/plant/child = new type(get_turf(src), seed, src)
	after_spread(child, target_turf)
	// Update neighboring tiles
	for(var/obj/effect/plant/hivemind/neighbor in range(1, target_turf))
		neighbor.neighbors -= target_turf


/obj/effect/plant/hivemind/life()
	if(hivemind_ai && node_weed_owner)
		try_assimilate_machinery()
		die_from_deadly_smoke_in_air()
		var/obj/machinery/door/door_on_my_tile = locate(/obj/machinery/door) in loc
		if(door_on_my_tile && door_on_my_tile.density)
			plant_interact_with_airlock(door_on_my_tile)
	else
		//slow vanishing after node death
		health -= 10
		alpha = 255 * health/max_health
		check_health()


/obj/effect/plant/hivemind/is_mature()
	return TRUE


/obj/effect/plant/hivemind/refresh_icon()
	overlays.Cut()
	var/image/I
	var/turf/floor/F = loc
	if((locate(/obj/structure/burrow) in loc) && F.flooring.is_plating)
		icon_state = "wires_burrow"
	else
		for(var/i = 1 to 4)
			I = image(src.icon, "wires[wires_connections[i]]", dir = 1<<(i-1))
			overlays += I

	//wallhug
	for(var/direction in GLOB.cardinal + list(NORTHEAST, NORTHWEST)-SOUTH)
		//corners
		if(direction == NORTHEAST || direction == NORTHWEST)
			if(!is_wall(get_step(loc, NORTH)) || !is_wall(get_step(loc, direction-NORTH)))
				continue
		//default
		var/turf/T = get_step(loc, direction)
		if(is_wall(T))
			var/image/wall_hug_overlay = image(icon = src.icon, icon_state = "wall_hug", dir = direction)
			if (T.x < x)
				wall_hug_overlay.pixel_x -= 32
			if (T.x > x)
				wall_hug_overlay.pixel_x += 32
			if (T.y < y)
				wall_hug_overlay.pixel_y -= 32
			if (T.y > y)
				wall_hug_overlay.pixel_y += 32
			wall_hug_overlay.layer = ABOVE_WINDOW_LAYER
			overlays += wall_hug_overlay



/obj/effect/plant/hivemind/proc/is_wall(turf/target)
	if((locate(/obj/structure/window) in target) || istype(target, /turf/wall))
		return TRUE
	return FALSE


/obj/effect/plant/hivemind/proc/update_connections(propagate = 0)
	var/list/dirs = list()
	for(var/obj/effect/plant/hivemind/W in range(1, src) - src)
		if(propagate)
			W.update_connections()
			W.update_icon()
		dirs += get_dir(src, W)

	wires_connections = dirs_to_corner_states(dirs)


/obj/effect/plant/hivemind/plant_interact_with_airlock(obj/machinery/door/door)
	if(!istype(door) || !hivemind_ai || !node_weed_owner)
		return FALSE

	//if our door isn't broken, we will try to break open. We can do only one action per call
	if(!(door.stat & BROKEN))
		anim_shake(door)
		//first, we open our panel to give our wireweeds access to exposed airlock's electronics
		if(!door.p_open && !istype(door, /obj/machinery/door/window))
			if(prob(50))
				door.p_open = TRUE
				door.update_icon()
			return FALSE
		//but if airlock is welded, we just shake it like we rummage inside
		if(door.welded)
			return FALSE
		//if panel opened, we begin to destruct it from inside of airlock
		if(door.p_open || istype(door, /obj/machinery/door/window))
			//bolts are down? Our wireweeds infest electronics, so this isn't a problem cause it part of us
			if(istype(door, /obj/machinery/door/airlock))
				var/obj/machinery/door/airlock/A = door
				if(A.locked)
					A.unlock()
					return FALSE
			//and then, if airlock is closed, we begin destroy it electronics
			if(door.density)
				door.take_damage(rand(30, 70))
				return FALSE

	return TRUE


/obj/effect/plant/hivemind/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	if(mover == src)
		if(target.density)
			return FALSE

		if(locate(/obj/structure) in target)
			for(var/obj/structure/S in target)
				if(S.density && S.anchored)
					return FALSE

		if(locate(/obj/machinery/door) in target)
			return FALSE

		return TRUE
	else
		return ..()


/obj/effect/plant/hivemind/Adjacent(atom/neighbor)
	var/turf/T = get_turf(neighbor)
	if(locate(/obj/machinery/door) in T)
		for(var/obj/O in T)
			if(istype(O, /obj/machinery/door))
				continue
			if(O.is_block_dir(get_dir(neighbor, src), TRUE))
				return . = ..()
		return TRUE
	else
		. = ..()


//What a pity that we haven't some kind proc as special library to use it somewhere
/obj/effect/plant/hivemind/proc/anim_shake(atom/thing)
	var/init_px = thing.pixel_x
	var/shake_dir = pick(-1, 1)
	animate(thing, transform=turn(matrix(), 8*shake_dir), pixel_x=init_px + 2*shake_dir, time=1)
	animate(transform=null, pixel_x=init_px, time=6, easing=ELASTIC_EASING)




//////////////////////////////////////////////////////////////////
/////////////////////////>RESPONSE CODE<//////////////////////////
//////////////////////////////////////////////////////////////////


//reinforced wires, so we can't take samples from it and inject something
//but we still can slice it with something sharp
/obj/effect/plant/hivemind/attackby(obj/item/W, mob/user)
	user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
	#warn test: punch the living shit out of wires
	if(!(QUALITY_CUTTING in W.tool_qualities || QUALITY_WELDING in W.tool_qualities))	// we gonna cut hivewires with our tools, some dont cut
		return
	else
		var/chosen_tool_quality

	// if(user.a_intent == I_HURT)
	// 	if (W.has_quality(QUALITY_CUTTING))
	// 		tool_quality = QUALITY_CUTTING
	// 	else if (W.has_quality(QUALITY_WELDING))
	// 		tool_quality = QUALITY_WELDING

	if(user.a_intent == I_HURT)
		if(W.use_tool(user, src, WORKTIME_FAST, W.tool_qualities, FAILCHANCE_EASY, required_stat = STAT_MEC))
			user.visible_message(span_danger("[user] cuts down [src]."), span_danger("You cut down [src]."))
			die_off()
			return
		if(W.sharp && W.force >= 10)
			health -= (W.force)
			user.visible_message(span_danger("[user] slices [src]."), span_danger("You slice [src]."))
		else
			to_chat(user, span_danger("You try to slice [src], but this weapon isn't enough!"))
	check_health()


//fire is effective, but there need some time to melt the covering
/obj/effect/plant/hivemind/fire_act()
	health -= rand(1, 4)
	check_health()


//emp is effective too
//it causes electricity failure, so our wireweeds just blowing up inside, what makes them fragile
/obj/effect/plant/hivemind/emp_act(severity)
	if(severity)
		die_off()


//Some acid and there's no problem
/obj/effect/plant/hivemind/proc/die_from_deadly_smoke_in_air()
	for(var/obj/effect/effect/smoke/chem/smoke in loc)
		for(var/lethal in killer_reagents)
			if(smoke.reagents.has_reagent(lethal))
				die_off()
				return



#undef HIVE_FACTION
#undef MAX_NODES_AMOUNT
#undef MIN_NODES_RANGE
#undef ishivemindmob
