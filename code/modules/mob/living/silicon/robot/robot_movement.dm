/// For fellow coders , if you wish to control the conditions for a robot to move , you need to touch movement_handlers in init() proc
/// I've spent 2 hours looking for them , but hopefully you don't have to go through my pain of going over and over undocumented code.


/mob/living/silicon/robot/slip_chance(prob_slip)
	if(module && module.no_slip)
		return 0
	..(prob_slip)

/mob/living/silicon/robot/allow_spacemove()

	//Do we have a working jetpack?
	var/obj/item/tank/jetpack/thrust = get_jetpack()

	if(thrust)
		if(thrust.allow_thrust(JETPACK_MOVE_COST, src))
			if (thrust.stabilization_on)
				return TRUE
			return -1

	//If no working jetpack then use the other checks
	if (is_component_functioning("actuator"))
		return ..()



/mob/living/silicon/robot/movement_delay()
	var/tally = ..()
	tally += speed //This var is a placeholder
	if(module_active && istype(module_active,/obj/item/borg/combat/mobility)) //And so is this silly check
		tally-=1
	tally /= speed_factor
	return tally


/mob/living/silicon/robot/SelfMove(turf/n, direct)
	if (!is_component_functioning("actuator"))
		return FALSE

	var/datum/robot_component/actuator/A = get_component("actuator")
	if (cell_use_power(A.active_usage))
		return ..()

