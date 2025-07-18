/*
	This state checks if user is somewhere within src_object, as well as the default NanoUI interaction.
*/
GLOBAL_DATUM_INIT(contained_state, /datum/nano_topic_state/contained_state, new)

/datum/nano_topic_state/contained_state/can_use_topic(atom/src_object, mob/user)
	if(!src_object.contains(user))
		return STATUS_CLOSE

	return user.shared_nano_interaction()

/atom/proc/contains(atom/location)
	if(!location)
		return 0
	if(location == src)
		return 1

	return contains(location.loc)
