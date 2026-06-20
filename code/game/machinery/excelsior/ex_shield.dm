/* TODO:
* 1. Shield diffusers (I think only serbs have them?)
* 2. Sound files in var section
* 3. add parts
* 4. Make it so Non-Excelsior cannot fall through the BUBBLE mode ceiling (watertank example)
* 5. Health and damage
*/

// Shield Modes
#define BUBBLE 1
#define LINE 2
#define TESLA 3
















/obj/machinery/excelsior_shieldwallgen
	name = "Excelsior shield generator"
	desc = "A cheap, old, hard-light shield generator."
	description_info = "Press the button to switch modes: BUBBLE > LINE > TESLA"
	icon = 'icons/obj/machines/excelsior/field.dmi'
	anchored = TRUE
	density = TRUE
	icon_state = "Shield_Gen_active"
	circuit = /obj/item/electronics/circuitboard/excelsiorshieldwallgen
	shipside_only = TRUE
	#warn the
	use_power = NO_POWER_USE
	idle_power_usage = 0
	active_power_usage = 0



	// parts
	// - battery
	var/internal_battery = 0
	var/max_internal_battery = 0
	var/obj/item/cell/internal_cell
	var/suitable_cell = /obj/item/cell/large
	// - capacitors
	var/capacitors_level = 0
	// - micro-lasers
	var/microlaser_level = 0





	// shields
	var/shield_path = /obj/effect/excelsior_shield 	// not ship shield gen
	var/shields_active = FALSE
	var/current_mode = BUBBLE
	var/list/shields_we_spawned = list()
	//- modes
	var/bubble_radius = 5
	var/allow_zappy_process = TRUE		// this is a hard process shutdown *for whatever reason*
	var/counter_until_zap = 0

	//sound
	var/sound_power_off = 			'sound/machines/button.ogg'	// TODO: CHANGE!!!
	var/sound_button_pressed =		'sound/machines/button.ogg'
	var/sound_blocked_projectile = 	'sound/machines/button.ogg'	// TODO: CHANGE!!!


	//process
	var/counter_until_turnOn = 0


// ^ shield generator
//-------------------------------------------------------------------------------------------------------------------------------------
// v shield


/obj/effect/excelsior_shield
	name = "Excelsior energy shield"
	desc = "Cheap hard-light, made by an old short-range shield generator."
	description_info = "Allows defenders to fire back."
	icon = 'icons/obj/machines/shielding.dmi'
	icon_state = "shield_normal"	// blue >:)
	anchored = TRUE
	plane = GAME_PLANE
	layer = BELOW_OBJ_LAYER
	density = TRUE
	invisibility = 0
	atmos_canpass = CANPASS_PROC
	throwpass = TRUE
	alpha = 128

	var/obj/machinery/excelsior_shieldwallgen/my_owner








/*--------------------------------------------------------------------------------
--                                   Process                                  --
--------------------------------------------------------------------------------*/




/*--------------------------------------------------------------------------------
--                              Helpers or Checks                             --
--------------------------------------------------------------------------------*/
/obj/machinery/excelsior_shieldwallgen/RefreshParts()
	internal_cell.
	microlaser_level = 0
	capacitors_level = 0
	for(var/obj/item/stock_parts/micro_laser/M in component_parts)
		microlaser_level += M.rating
	for(var/obj/item/stock_parts/capacitor/C in component_parts)
		capacitors_level += C.rating
	..()	// this does NOTHING by the way. I'll just assume someone makes something in the future






/obj/machinery/excelsior_shieldwallgen/emag_act() // TODO? Do we want emag do stuff with this? Im too lazy to think about this
	return






// ^ shield generator
// v shield







/obj/effect/excelsior_shield/CanPass(atom/movable/UFO, turf/target, height=0, air_group=0)
	if(is_excelsior(UFO))
		return TRUE
	var/me_to_object_dir = get_dir(src, UFO)
	var/me_to_myowner_dir = get_dir(src, my_owner)

	if(me_to_object_dir == me_to_myowner_dir || (me_to_object_dir in get_adjacent_dirs(me_to_myowner_dir)))	//Let everything moving OUT pass, check if excelsior if trying to enter
		return TRUE
	return ..()








/obj/effect/excelsior_shield/bullet_act(obj/item/projectile/P, def_zone)
	if(!P.get_structure_damage())
		return
	if(my_owner.internal_battery <= 0)
		my_owner.turn_off_shields()





















/*--------------------------------------------------------------------------------
 --                  Interactive code (e.g. human clicked me)                  --
 --------------------------------------------------------------------------------*/


/obj/machinery/excelsior_shieldwallgen/examine(mob/user)
	. = ..()
	if(internal_battery)
		desc += span_notice("\The [src]'s cell reads \"[round((internal_battery/max_internal_battery)*100)]%\"")
	else
		desc += span_warning("\The [src] has no cell installed.")



/obj/machinery/excelsior_shieldwallgen/attack_hand(mob/user)
	..()
	playsound(src, sound_button_pressed, 50, 1)
	turn_off_shields()
	switch_shield_mode_forward()
	turn_on_shields_with_delay(2 SECONDS)


//
/obj/machinery/excelsior_shieldwallgen/attackby(obj/item/I, mob/user)

	if(user.a_intent == I_HELP)
		if((QUALITY_PRYING in I.tool_qualities) && internal_battery)
			if(I.use_tool(user, src, WORKTIME_NORMAL, QUALITY_PRYING, FAILCHANCE_EASY,  required_stat = STAT_MEC))
				eject_item(remove_battery(), user)
			return TRUE
		if(istype(I, suitable_cell))
			if(internal_battery)
				to_chat(user, "There is a [internal_battery] already installed here.")
			else if(insert_item(I, user))
				internal_battery = I
			return TRUE

/obj/machinery/excelsior_shieldwallgen/eject_item()
	..()
	RefreshParts()

/obj/machinery/excelsior_shieldwallgen/insert_item()
	..()
	RefreshParts()
//





/obj/machinery/excelsior_shieldwallgen/proc/remove_battery()
	if(internal_battery)
		. = internal_battery
		internal_battery = null

































/*--------------------------------------------------------------------------------
--                               Background code                              --
--------------------------------------------------------------------------------*/


/obj/machinery/excelsior_shieldwallgen/New(loc, old_internal_battery)
	..(loc)
	if(old_internal_battery)
		internal_battery = old_internal_battery

/obj/machinery/excelsior_shieldwallgen/Initialize()
	..()
	turn_on_shields_with_delay(2 SECONDS)	// quirky delay
	zappy_process()
	RefreshParts()






/obj/machinery/excelsior_shieldwallgen/Process()
	..()
	if(counter_until_turnOn <= 0)
		counter_until_turnOn--
	add_power_to_shield(use_power(100))		// attempt to charge from APC



/obj/machinery/excelsior_shieldwallgen/proc/add_power_to_shield(var/received_power)

	received_power *= capacitors_level

	internal_battery += received_power
	if(internal_battery >= max_internal_battery)
		internal_battery = max_internal_battery

/obj/machinery/excelsior_shieldwallgen/proc/turn_on_shields_with_delay(var/get_delay)
	counter_until_turnOn = 2
	if(get_delay < 0)
		CRASH("turn_on_shields_with_delay() delayed with less than 0.")






/obj/machinery/excelsior_shieldwallgen/proc/turn_on_shields()
	if(!src)	// we delayed action previously, lets make sure we live
		return
	if(shields_active)
		return

	switch(current_mode)
		if(BUBBLE)
			bubble_mode_on()
		if(LINE)
			line_mode_on(get_dir(usr, src), shield_length = 5)
		// if(TESLA)
		// 	// zappy_process() starts doing stuff

	shields_active = TRUE




/obj/machinery/excelsior_shieldwallgen/proc/turn_off_shields()
	if(!src)
		return
	if(shields_we_spawned.len > 0)
		QDEL_LAZYLIST(shields_we_spawned)
		shields_we_spawned = list()
	shields_active = FALSE











/obj/machinery/excelsior_shieldwallgen/proc/switch_shield_mode_forward()
	if(current_mode == TESLA)
		current_mode = BUBBLE
	else
		current_mode++

















/*--------------------------------------------------------------------------------
--        	 Background code --- SUBCATEGORY --- Shield Modes Creation        --
--------------------------------------------------------------------------------*/

/obj/machinery/excelsior_shieldwallgen/proc/create_shield_at(var/turf/here, above = FALSE)
	if(above)

		if(here.z >= 5)
			return

		var/turf/almost_here = locate(here.x, here.y, here.z+1) // +1 floor (above). What happens when we're at max floor? Let's not...
		var/obj/effect/excelsior_shield/created_shield = new(almost_here)
		shields_we_spawned.Add(created_shield)
		return


	var/obj/effect/excelsior_shield/created_shield = new(here)
	created_shield.my_owner = src
	shields_we_spawned.Add(created_shield)




















/obj/machinery/excelsior_shieldwallgen/proc/bubble_mode_on()
	var/big_circle = circlerangeturfs(src, bubble_radius)
	var/small_circle = circlerangeturfs(src, bubble_radius-1)
	var/outline = big_circle - small_circle
	for(var/tile in outline)
		create_shield_at(tile)

	//TODO: Add ceiling protection like so:
	var/turf/tile
	for(tile in small_circle)
		create_shield_at(tile, above = TRUE)

/obj/machinery/excelsior_shieldwallgen/proc/line_mode_on(var/set_direction, var/shield_length)
	var/turf/step_turf = get_step(src, set_direction)
	step_turf = get_cardinal_dir(src, step_turf)	// cardinal doesnt allow mixed dirs like NORTHWEST.
	step_turf = get_step(src, step_turf)
	var/turf/line_turf
	var/halfShield = floor(shield_length/2)

	// this looks awful, but shortening locate() doesnt work (im not creating a new proc),
	// just ignore xyz values that arent modified by anything inside locate()
	create_shield_at(step_turf)
	sleep(2 SECONDS)
	switch(set_direction)
		if(NORTH, SOUTH)
			line_turf = locate(step_turf.x+halfShield, step_turf.y, step_turf.z)
			while(shield_length > 0)
				create_shield_at(line_turf)
				line_turf = locate(line_turf.x-1, line_turf.y, line_turf.z)	// x
				shield_length--
		if(WEST, EAST)
			line_turf = locate(step_turf.x, step_turf.y+halfShield, step_turf.z)
			while(shield_length > 0)
				create_shield_at(line_turf)
				line_turf = locate(line_turf.x, line_turf.y-1, line_turf.z)	// y
				shield_length--












/obj/machinery/excelsior_shieldwallgen/proc/zappy_process()
	if(current_mode == TESLA)
		var/zap_this_one = pick(list_of_zappable_people())
		if(zap_this_one && counter_until_zap <= 0)
			var/obj/item/projectile/beam/stun/P = new(src.loc)
			P.shot_from = src
			P.launch(zap_this_one)
			counter_until_zap = 6-microlaser_level	// 6 is an admin stock parts
		else
			if(counter_until_zap <= 0)
				counter_until_zap--
	spawn(1 SECOND)		// watch carefully
		if(src && allow_zappy_process)
			zappy_process()

//
/obj/machinery/excelsior_shieldwallgen/proc/list_of_zappable_people()
	var/list/mob/living/zappable_mobs = list()
	for(var/mob/living/thing in hearers(7, get_turf(src)))
	//

		if(!is_excelsior(thing))
			zappable_mobs.Add(thing)
	//

	return zappable_mobs
//
#warn debug
// /mob/living/simple_animal/hostile/proc/ListTargets(dist = 7)
// 	var/list/L = hearers(dist, get_turf(src))

// 	for (var/mob/living/exosuit/M in GLOB.mechas_list)
// 		if (M.z == z && get_dist(src, M) <= dist)
// 			L += M

// 	return L






#undef BUBBLE
#undef LINE
#undef TESLA
