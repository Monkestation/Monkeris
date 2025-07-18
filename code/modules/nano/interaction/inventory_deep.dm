/*
	This state checks if src_object is contained anywhere in the user's inventory, including bags, etc.
*/
GLOBAL_DATUM_INIT(deep_inventory_state, /datum/nano_topic_state/deep_inventory_state, new)

/datum/nano_topic_state/deep_inventory_state/can_use_topic(src_object, mob/user)
	if(!user.contains(src_object))
		return STATUS_CLOSE

	return user.shared_nano_interaction()
