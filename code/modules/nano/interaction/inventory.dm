/*
	This state checks that the src_object is somewhere in the user's first-level inventory (in hands, on ear, etc.), but not further down (such as in bags).
*/
GLOBAL_DATUM_INIT(inventory_state, /datum/nano_topic_state/inventory_state, new)

/datum/nano_topic_state/inventory_state/can_use_topic(src_object, mob/user)
	if(!(src_object in user))
		return STATUS_CLOSE

	return user.shared_nano_interaction()
