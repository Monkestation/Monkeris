/* TODO:
* 1. Shield diffusers (I think only serbs have them?)
* 2. Sound files in var section
* 3. add parts
*/

// Shield Modes
#define BUBBLE 1
#define LINE 2
#define TESLA 3

//


// Excelsior Shield Generator --- The Machine

/obj/machinery/excelsior_shieldwallgen
	name = "Excelsior shield generator"
	desc = "A cheap, old, communistic shield generator."
	description_info = "Allows defenders to fire back."
	icon = 'icons/obj/machines/excelsior/field.dmi'
	anchored = TRUE
	density = TRUE
	icon_state = "Shield_Gen_active"
	circuit = /obj/item/electronics/circuitboard/excelsiorshieldwallgen
	shipside_only = TRUE

	//battery
	#warn debug number 1
	var/internal_battery = 1
	var/max_internal_battery = 0 // replace with a cell

	var/shield_path = /obj/effect/excelsior_shield	// not taking [/obj/effect/shield], simplify stuff!
	var/shields_active = FALSE
	var/current_mode = BUBBLE
	var/bubble_radius = 4

	var/list/shields_we_spawned = list()


	//sound
	var/sound_power_off = 'sound/machines/button.ogg'	// CHANGE
	var/sound_button_pressed = 'sound/machines/button.ogg'

// Excelsior Shield Generator --- Shield

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
	alpha = 128

	var/obj/machinery/excelsior_shieldwallgen/my_owner


//---------------------------------------------------------------

// Helpers or Checks

/obj/machinery/excelsior_shieldwallgen/emag_act() // TODO? Do we want emag do stuff with this? If no then kinda boring :[
	return

#warn
/obj/effect/excelsior_shield/CanPass(atom/movable/UFO, turf/target, height=0, air_group=0)
	if(is_excelsior(UFO))
		return TRUE
	if(istype(UFO, /obj/item/projectile))
		var/me_to_bullet_dir = get_dir(UFO, src)
		var/me_to_myowner_dir = get_dir(my_owner, src)

		#warn DEAL!!! DEBUG HERE
		log_admin("SHIELD DEBUG: SHIELD to [UFO] got direction: [me_to_bullet_dir]")
		log_admin("SHIELD DEBUG: SHIELD to [my_owner] got direction: [me_to_myowner_dir]")

		if(me_to_bullet_dir == me_to_myowner_dir)
			return TRUE
	return ..()


// Interactive code

/obj/machinery/excelsior_shieldwallgen/attack_hand(mob/user)
	..()
	playsound(src, sound_button_pressed, 50, 1)
	turn_off_shields()
	switch_shield_mode_forward()
	turn_on_shields_with_delay(5 SECONDS)



// Background code --- ON/OFF

/obj/machinery/excelsior_shieldwallgen/Initialize()
	..()
	turn_on_shields_with_delay(5 SECONDS)

/obj/machinery/excelsior_shieldwallgen/proc/turn_on_shields_with_delay(insert_delay)
	spawn(5 SECONDS)
		if(internal_battery > 0)
			shields_active = TRUE
			turn_on_shields()



/obj/machinery/excelsior_shieldwallgen/proc/turn_on_shields()
	if(!src)	// we delayed previously, lets make sure we live
		return

	switch(current_mode)
		if(BUBBLE)
			bubble_mode_on()
		if(LINE)
			line_mode_on()
		if(TESLA)
			tesla_mode_on()

	shields_active = TRUE

/obj/machinery/excelsior_shieldwallgen/proc/turn_off_shields()
	if(!src)
		return
		// turn off bubbles tesla and other stuff here :)
	shields_active = FALSE



/obj/machinery/excelsior_shieldwallgen/proc/switch_shield_mode_forward()
	if(!current_mode == TESLA)
		current_mode++
	current_mode = BUBBLE


// Background code --- Shield Modes Creation
/obj/machinery/excelsior_shieldwallgen/proc/create_shield_at(var/here)
	var/obj/effect/excelsior_shield/created_shield = new(here)
	created_shield.my_owner = src
	shields_we_spawned.Add(created_shield)


/obj/machinery/excelsior_shieldwallgen/proc/bubble_mode_on()
	// all the circle
	var/list/circle = list()
	for(var/turf/turfie in orange(bubble_radius, src))
		circle.Add(turfie)


	// now lets carve our outline
	var/list/outline = list()
	var/list/inside = list()
	for(var/turf/turfie in circle)
		if(get_dist(turfie, src) >= bubble_radius-1) // smooth out the outline! otherwise its gonna be pixel-y
			outline.Add(turfie)
		else
			inside.Add(turfie)
	// time to finish what we started
	for(var/turf/turfie_is_real in outline)
		create_shield_at(turfie_is_real)
	#warn bad
	log_admin("Done!")
	#warn TODO: Add ceiling protection



/obj/machinery/excelsior_shieldwallgen/proc/line_mode_on()
/obj/machinery/excelsior_shieldwallgen/proc/tesla_mode_on()










#undef BUBBLE
#undef LINE
#undef TESLA
