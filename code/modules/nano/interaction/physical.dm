GLOBAL_DATUM_INIT(physical_state, /datum/nano_topic_state/physical, new)

/datum/nano_topic_state/physical/can_use_topic(src_object, mob/user)
	. = user.shared_nano_interaction(src_object)
	if(. > STATUS_CLOSE)
		return min(., user.check_physical_distance(src_object))

/mob/proc/check_physical_distance(src_object)
	return STATUS_CLOSE

/mob/observer/ghost/check_physical_distance(src_object)
	return default_can_use_topic(src_object)

/mob/living/check_physical_distance(src_object)
	return shared_living_nano_distance(src_object)

/mob/living/silicon/ai/check_physical_distance(src_object)
	return max(STATUS_UPDATE, shared_living_nano_distance(src_object))
