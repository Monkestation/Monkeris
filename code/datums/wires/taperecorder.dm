#define TAPE_WIRE_STOP (1 << 0)
#define TAPE_WIRE_PLAY (1 << 1)
#define TAPE_WIRE_RECORD (1 << 3)
#define TAPE_WIRE_WIPE (1 << 4)

/datum/wires/taperecorder
	holder_type = /obj/item/device/taperecorder
	wire_count = 4
	descriptions = list(
		new /datum/wire_description(TAPE_WIRE_STOP, "Stop"),
		new /datum/wire_description(TAPE_WIRE_PLAY, "Play"),
		new /datum/wire_description(TAPE_WIRE_RECORD, "Record"),
		new /datum/wire_description(TAPE_WIRE_WIPE, "Wipe"),
	)

/datum/wires/taperecorder/UpdatePulsed(index)
	var/obj/item/device/taperecorder/T = holder
	switch(index)
		if(TAPE_WIRE_STOP)
			T.stop(0)
		if(TAPE_WIRE_PLAY)
			T.playback_memory(0)
		if(TAPE_WIRE_RECORD)
			T.record(0)
		if(TAPE_WIRE_WIPE)
			T.clear_memory(0)
	SSnano.update_uis(holder)
