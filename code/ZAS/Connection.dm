#define CONNECTION_DIRECT 2
#define CONNECTION_SPACE 4
#define CONNECTION_INVALID 8

/*

Overview:
	Connections are made between turfs by SSair.connect(). They represent a single point where two zones converge.

Class Vars:
	A - Always a simulated turf.
	B - A simulated or unsimulated turf.

	zoneA - The archived zone of A. Used to check that the zone hasn't changed.
	zoneB - The archived zone of B. May be null in case of unsimulated connections.

	edge - Stores the edge this connection is in. Can reference an edge that is no longer processed
		   after this connection is removed, so make sure to check edge.coefficient > 0 before re-adding it.

Class Procs:

	mark_direct()
		Marks this connection as direct. Does not update the edge.
		Called when the connection is made and there are no doors between A and B.
		Also called by update() as a correction.

	mark_indirect()
		Unmarks this connection as direct. Does not update the edge.
		Called by update() as a correction.

	mark_space()
		Marks this connection as unsimulated. Updating the connection will check the validity of this.
		Called when the connection is made.
		This will not be called as a correction, any connections failing a check against this mark are erased and rebuilt.

	direct()
		Returns 1 if no doors are in between A and B.

	valid()
		Returns 1 if the connection has not been erased.

	erase()
		Called by update() and connection_manager/erase_all().
		Marks the connection as erased and removes it from its edge.

	update()
		Called by connection_manager/update_all().
		Makes numerous checks to decide whether the connection is still valid. Erases it automatically if not.

*/


/datum/connection
	var/turf/A
	var/turf/B
	var/datum/zone/zoneA
	var/datum/zone/zoneB

	var/datum/connection_edge/edge

	var/state = 0

/datum/connection/New(turf/A, turf/B)
	#ifdef ZASDBG
	ASSERT(SSair.has_valid_zone(A))
	//ASSERT(SSair.has_valid_zone(B))
	#endif
	src.A = A
	src.B = B
	zoneA = A.zone
	if(!B.is_simulated)
		mark_space()
		edge = SSair.get_edge(A.zone,B)
		edge.add_connection(src)
	else
		zoneB = B.zone
		edge = SSair.get_edge(A.zone,B.zone)
		edge.add_connection(src)

/datum/connection/proc/mark_direct()
	if(!direct())
		state |= CONNECTION_DIRECT
		edge.direct++
	//world << "Marked direct."

/datum/connection/proc/mark_indirect()
	if(direct())
		state &= ~CONNECTION_DIRECT
		edge.direct--
	//world << "Marked indirect."

/datum/connection/proc/mark_space()
	state |= CONNECTION_SPACE

/datum/connection/proc/direct()
	return (state & CONNECTION_DIRECT)

/datum/connection/proc/valid()
	return !(state & CONNECTION_INVALID)

/datum/connection/proc/erase()
	if(edge)
		edge.remove_connection(src)
	state |= CONNECTION_INVALID
	//world << "Connection Erased: [state]"

/datum/connection/proc/update()
	//world << "Updated, \..."
	if(!A.is_simulated)
		//world << "Invalid A."
		erase()
		return

	var/block_status = SSair.air_blocked(A,B)
	if(block_status & AIR_BLOCKED)
		//world << "Blocked connection."
		erase()
		return
	else if(block_status & ZONE_BLOCKED)
		mark_indirect()
	else
		mark_direct()

	if(state & CONNECTION_SPACE)
		if(B.is_simulated)
			//world << "Invalid B."
			erase()
			return
		if(A.zone != zoneA)
			//world << "Zone changed, \..."
			if(!A.zone)
				erase()
				//world << "erased."
				return
			if(edge)
				edge.remove_connection(src)
				edge = SSair.get_edge(A.zone, B)
				edge.add_connection(src)
			zoneA = A.zone

		//world << "valid."
		return

	else if(!B.is_simulated)
		//world << "Invalid B."
		erase()
		return

	if(A.zone == B.zone)
		//world << "A == B"
		erase()
		return

	if(A.zone != zoneA || (zoneB && (B.zone != zoneB)))

		//world << "Zones changed, \..."
		if(A.zone && B.zone)
			edge.remove_connection(src)
			edge = SSair.get_edge(A.zone, B.zone)
			edge.add_connection(src)
			zoneA = A.zone
			zoneB = B.zone
		else
			//world << "erased."
			erase()
			return


	//world << "valid."
