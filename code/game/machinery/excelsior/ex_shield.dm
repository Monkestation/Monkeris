/* TODO:
* 1. Shield diffusers (I think only serbs have them?)
* 2. Sound files in var section
* 3. add parts
* 4. Make it so Non-Excelsior cannot fall through the BUBBLE mode ceiling (watertank example)
*/

// Shield Modes
#define BUBBLE 1
#define LINE 2
#define TESLA 3




/obj/machinery/excelsior_shieldwallgen
	name = "Excelsior shield generator"
	desc = "A cheap, old, communistic shield generator. Allows defenders to fire back."
	description_info = "Everyone may go out, but only communistic enough can go in."
	icon = 'icons/obj/machines/excelsior/field.dmi'
	anchored = TRUE
	density = TRUE
	icon_state = "Shield_Gen_active"
	circuit = /obj/item/electronics/circuitboard/excelsiorshieldwallgen
	shipside_only = TRUE

	//battery
	var/obj/item/cell/internal_battery
	var/suitable_cell = /obj/item/cell/large
	// shields
	var/shield_path = /obj/effect/excelsior_shield	// not equal to [/obj/effect/shield], which belongs to ship's shield gen.
	var/shields_active = FALSE
	var/current_mode = BUBBLE
	// shields modes
	var/bubble_radius = 5

	var/list/shields_we_spawned = list()


	//sound
	var/sound_power_off = 			'sound/machines/button.ogg'	// TODO: CHANGE!!!
	var/sound_button_pressed =		'sound/machines/button.ogg'
	var/sound_blocked_projectile = 	'sound/machines/button.ogg'	// TODO: CHANGE!!!





/obj/effect/excelsior_shield
	name = "Excelsior energy shield"
	desc = "Cheap hard-light, made by an old short-range shield generator."
	description_info = "Allows defenders to fire back."
	icon = 'icons/obj/machines/shielding.dmi'
	icon_state = "shield_overcharged"	// red >:)
	anchored = TRUE
	plane = GAME_PLANE
	layer = BELOW_OBJ_LAYER
	density = TRUE
	invisibility = 0
	atmos_canpass = CANPASS_PROC
	throwpass = TRUE
	alpha = 128

	var/obj/machinery/excelsior_shieldwallgen/my_owner


//---------------------------------------------------------------

// Helpers or Checks



/obj/machinery/excelsior_shieldwallgen/emag_act() // TODO? Do we want emag do stuff with this? If no then kinda boring :[
	return




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
	if(!my_owner.internal_battery.checked_use(P.get_structure_damage()))
		my_owner.turn_off_shields()






// Interactive code (e.g. stupid meatbag pressed button)

/obj/machinery/excelsior_shieldwallgen/attack_hand(mob/user)
	..()
	playsound(src, sound_button_pressed, 50, 1)
	turn_off_shields()
	switch_shield_mode_forward()
	turn_on_shields_with_delay(1 SECONDS)

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

/obj/machinery/excelsior_shieldwallgen/examine(mob/user, extra_description)
	. = ..()
	if(internal_battery)
		extra_description += span_notice("\The [src]'s cell reads \"[round(internal_battery.percent(),0.1)]%\"")
	else
		extra_description += span_warning("\The [src] has no cell installed.")





// Background code --- ON/OFF

/obj/machinery/excelsior_shieldwallgen/New(loc, old_internal_battery)
	..(loc)
	if(old_internal_battery)
		internal_battery = old_internal_battery

/obj/machinery/excelsior_shieldwallgen/Initialize()
	..()

/obj/machinery/excelsior_shieldwallgen/proc/remove_battery()
	if(internal_battery)
		. = internal_battery
		internal_battery = null
		#warn TODO: Turn off shields if battery removed and no external power

/obj/machinery/excelsior_shieldwallgen/proc/turn_on_shields_with_delay(insert_delay)
	spawn(5 SECONDS)
		if(internal_battery && internal_battery.check_charge(250))
			turn_on_shields()



/obj/machinery/excelsior_shieldwallgen/proc/turn_on_shields()
	if(!src)	// we delayed previously, lets make sure we live
		return
	if(shields_active)
		return

	switch(current_mode)
		if(BUBBLE)
			bubble_mode_on()
		if(LINE)
			line_mode_on(get_dir(usr, src))
		if(TESLA)
			tesla_mode_on()
	shields_active = TRUE


/obj/machinery/excelsior_shieldwallgen/proc/turn_off_shields()
	if(!src)
		error("Excelsior Shieldgen fucked up.")
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



// Background code --- Shield Modes Creation
/obj/machinery/excelsior_shieldwallgen/proc/create_shield_at(var/turf/here, above = FALSE)
	if(above)

		if(here.z >= 5)
			return

		var/turf/almost_here = locate(here.x, here.y, here.z+1) // +1 floor above. What happens when we're at max floor? Let's not...
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



/obj/machinery/excelsior_shieldwallgen/proc/line_mode_on(var/set_direction)
	var/obj/machinery/excelsior_shieldwallgen/shield_locate = get_step(src, set_direction)
	switch(set_direction)
#warn these are NOT cardinal dirs. fuck around and find out
#warn be watchful here now, check what happens when we're at map border
		// if(NORTH)
		// if(WEST)
		// if(EAST)
		// if(SOUTH)
	create_shield_at(get_turf(shield_locate))

/obj/machinery/excelsior_shieldwallgen/proc/tesla_mode_on()











#undef BUBBLE
#undef LINE
#undef TESLA
