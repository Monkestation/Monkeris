// Static movement denial
/datum/movement_handler/no_move/MayMove()
	return MOVEMENT_STOP

// Anchor check
/datum/movement_handler/anchored/MayMove()
	return host.anchored ? MOVEMENT_STOP : MOVEMENT_PROCEED
/*
/datum/movement_handler/move_relay/MayMove(mob/mover, is_external)
	var/atom/movable/AM = host.loc
	if(!istype(AM))
		return
	. = AM.DoMove(direction, mover, FALSE)
	if(!(. & MOVEMENT_HANDLED))
		. = MOVEMENT_HANDLED
		AM.relaymove(mover, direction)
*/
// Movement relay
/datum/movement_handler/move_relay/DoMove(direction, mover)
	var/atom/movable/AM = host.loc
	if(!istype(AM))
		return
	. = AM.DoMove(direction, mover, FALSE)
	/*
	AM.relaymove(mover, direction)
	return MOVEMENT_HANDLED
	*/
	if(!(. & MOVEMENT_HANDLED))
		. = MOVEMENT_HANDLED
		AM.relaymove(mover, direction)



// Movement delay
/datum/movement_handler/delay
	var/delay = 1
	var/next_move

/datum/movement_handler/delay/New(host, delay)
	..()
	src.delay = max(1, delay)

/datum/movement_handler/delay/DoMove()
	next_move = world.time + delay

/datum/movement_handler/delay/MayMove()
	return world.time >= next_move ? MOVEMENT_PROCEED : MOVEMENT_STOP

// Relay self
/datum/movement_handler/move_relay_self/DoMove(direction, mover)
	host.relaymove(mover, direction)
	return MOVEMENT_HANDLED
