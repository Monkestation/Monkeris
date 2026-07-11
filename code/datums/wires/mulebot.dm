#define MULE_WIRE_POWER1    (1 << 0)    // power connections
#define MULE_WIRE_POWER2    (1 << 1)
#define MULE_WIRE_AVOIDANCE (1 << 2)    // mob avoidance
#define MULE_WIRE_LOADCHECK (1 << 3)    // load checking (non-crate)
#define MULE_WIRE_MOTOR1    (1 << 4)    // motor wires
#define MULE_WIRE_MOTOR2    (1 << 5)
#define MULE_WIRE_REMOTE_RX (1 << 6)    // remote recv functions
#define MULE_WIRE_REMOTE_TX (1 << 7)    // remote trans status
#define MULE_WIRE_BEACON_RX (1 << 8)    // beacon ping recv



/datum/wires/mulebot
	holder_type = /obj/machinery/bot/mulebot
	wire_count = 10

/datum/wires/mulebot/CanUse(mob/living/L)
	var/obj/machinery/bot/mulebot/M = holder
	if(M.open)
		return 1
	return 0

// So the wires do not open a new window, handle the interaction ourselves.
/datum/wires/mulebot/Interact(mob/living/user)
	if(CanUse(user))
		var/obj/machinery/bot/mulebot/M = holder
		M.interact(user)

/datum/wires/mulebot/UpdatePulsed(index)
	var/listeners = hearers(get_turf(src))
	var/htmlicon = icon2html(holder, listeners)
	switch(index)
		if(MULE_WIRE_POWER1, MULE_WIRE_POWER2)
			holder.visible_message(span_notice("[htmlicon] The charge light flickers."))
		if(MULE_WIRE_AVOIDANCE)
			holder.visible_message(span_notice("[htmlicon] The external warning lights flash briefly."))
		if(MULE_WIRE_LOADCHECK)
			holder.visible_message(span_notice("[htmlicon] The load platform clunks."))
		if(MULE_WIRE_MOTOR1, MULE_WIRE_MOTOR2)
			holder.visible_message(span_notice("[htmlicon] The drive motor whines briefly."))
		else
			holder.visible_message(span_notice("[htmlicon] You hear a radio crackle."))

// HELPER PROCS

/datum/wires/mulebot/proc/Motor1()
	return !(wires_status & MULE_WIRE_MOTOR1)

/datum/wires/mulebot/proc/Motor2()
	return !(wires_status & MULE_WIRE_MOTOR2)

/datum/wires/mulebot/proc/HasPower()
	return !(wires_status & MULE_WIRE_POWER1) && !(wires_status & MULE_WIRE_POWER2)

/datum/wires/mulebot/proc/LoadCheck()
	return !(wires_status & MULE_WIRE_LOADCHECK)

/datum/wires/mulebot/proc/MobAvoid()
	return !(wires_status & MULE_WIRE_AVOIDANCE)

/datum/wires/mulebot/proc/RemoteTX()
	return !(wires_status & MULE_WIRE_REMOTE_TX)

/datum/wires/mulebot/proc/RemoteRX()
	return !(wires_status & MULE_WIRE_REMOTE_RX)

/datum/wires/mulebot/proc/BeaconRX()
	return !(wires_status & MULE_WIRE_BEACON_RX)

#undef MULE_WIRE_POWER1
#undef MULE_WIRE_POWER2
#undef MULE_WIRE_AVOIDANCE
#undef MULE_WIRE_LOADCHECK
#undef MULE_WIRE_MOTOR1
#undef MULE_WIRE_MOTOR2
#undef MULE_WIRE_REMOTE_RX
#undef MULE_WIRE_REMOTE_TX
#undef MULE_WIRE_BEACON_RX
