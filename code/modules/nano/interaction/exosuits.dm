GLOBAL_DATUM_INIT(mech_state, /datum/nano_topic_state/default/mech, new)

/datum/nano_topic_state/default/mech/can_use_topic(mob/living/exosuit/src_object, mob/user)
	if(istype(src_object))
		if(user in src_object.pilots)
			return ..()
	else return STATUS_CLOSE
	return ..()
