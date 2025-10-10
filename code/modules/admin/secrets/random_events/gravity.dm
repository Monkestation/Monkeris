/**********
* Gravity *
**********/
/datum/admin_secret_item/random_event/gravity
	name = "Toggle Station Artificial Gravity"

/datum/admin_secret_item/random_event/gravity/can_execute(mob/user)
	if(!SSticker.IsRoundInProgress())
		return 0

	return ..()

/datum/admin_secret_item/random_event/gravity/execute(mob/user)
	. = ..()
	if(!.)
		return

	gravity_is_on = !gravity_is_on
	if (GLOB.active_gravity_generator)
		GLOB.active_gravity_generator.set_state(gravity_is_on)


	if(gravity_is_on)
		log_admin("[key_name(user)] toggled gravity on.", 1)
		message_admins("[key_name_admin(user)] toggled gravity on.", 1)
		priority_announce("Gravity generators are again functioning within normal parameters. Sorry for any inconvenience.")
	else
		log_admin("[key_name(user)] toggled gravity off.", 1)
		message_admins("[key_name_admin(usr)] toggled gravity off.", 1)
		priority_announce("Feedback surge detected in mass-distributions systems. Artificial gravity has been disabled whilst the system reinitializes. Further failures may result in a gravitational collapse and formation of blackholes. Have a nice day.")
