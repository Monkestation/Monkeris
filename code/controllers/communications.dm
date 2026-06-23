/*
  HOW IT WORKS

  The SSradio is a global object maintaining all radio transmissions, think about it as about "ether".
  Note that walkie-talkie, intercoms and headsets handle transmission using nonstandard way.
  procs:

    add_object(obj/device as obj, var/new_frequency as num, var/filter as text|null = null)
      Adds listening object.
      parameters:
        device - device receiving signals, must have proc receive_signal (see description below).
          one device may listen several frequencies, but not same frequency twice.
        new_frequency - see possibly frequencies below;
        filter - thing for optimization. Optional, but recommended.
                 All filters should be consolidated in this file, see defines later.
                 Device without listening filter will receive all signals (on specified frequency).
                 Device with filter will receive any signals sent without filter.
                 Device with filter will not receive any signals sent with different filter.
      returns:
       Reference to frequency object.

    remove_object (obj/device, old_frequency)
      Obliviously, after calling this proc, device will not receive any signals on old_frequency.
      Other frequencies will left unaffected.

   return_frequency(var/frequency as num)
      returns:
       Reference to frequency object. Use it if you need to send and do not need to listen.

  radio_frequency is a global object maintaining list of devices that listening specific frequency.
  procs:

    post_signal(obj/source as obj|null, datum/signal/signal, var/filter as text|null = null, var/range as num|null = null)
      Sends signal to all devices that wants such signal.
      parameters:
        source - object, emitted signal. Usually, devices will not receive their own signals.
        signal - see description below.
        filter - described above.
        range - radius of regular byond's square circle on that z-level. null means everywhere, on all z-levels.

  obj/proc/receive_signal(datum/signal/signal, var/receive_method as num, var/receive_param)
    Handler from received signals. By default does nothing. Define your own for your object.
    Avoid of sending signals directly from this proc, use spawn(-1). DO NOT use sleep() here or call procs that sleep please. If you must, use spawn()
      parameters:
        signal - see description below. Extract all needed data from the signal before doing sleep(), spawn() or return!
        receive_method - may be TRANSMISSION_WIRE or TRANSMISSION_RADIO.
          TRANSMISSION_WIRE is currently unused.
        receive_param - for TRANSMISSION_RADIO here comes frequency.

  datum/signal
    vars:
    source
      an object that emitted signal. Used for debug and bearing.
    data
      list with transmitting data. Usual use pattern:
        data["msg"] = "hello world"
    encryption
      Some number symbolizing "encryption key".
      Note that game actually do not use any cryptography here.
      If receiving object don't know right key, it must ignore encrypted signal in its receive_signal.

*/

// For information on what objects or departments use what frequencies,
// see __DEFINES/radio.dm. Mappers may also select additional frequencies for
// use in maps, such as in intercoms.

GLOBAL_LIST_INIT(radiochannels, list(
	"[RADIO_CHANNEL_COMMON]"		= FREQ_COMMON,
	"[RADIO_CHANNEL_SCIENCE]"		= FREQ_SCI,
	"[RADIO_CHANNEL_COMMAND]"		= FREQ_COMM,
	"[RADIO_CHANNEL_MEDICAL]"		= FREQ_MED,
	"[RADIO_CHANNEL_ENGINEERING]"	= FREQ_ENG,
	"[RADIO_CHANNEL_SECURITY]" 		= FREQ_SEC,
	"[RADIO_CHANNEL_SPEC_OPS]" 		= FREQ_DTH,
	"[RADIO_CHANNEL_MERCENARY]" 	= FREQ_SYND,
	"[RADIO_CHANNEL_PIRATE]"        = FREQ_YARR,
	"[RADIO_CHANNEL_SUPPLY]" 		= FREQ_SUP,
	"[RADIO_CHANNEL_NT_VOICE]"		= FREQ_NT,
	"[RADIO_CHANNEL_SERVICE]" 		= FREQ_SRV,
	"[RADIO_CHANNEL_AI_PRIVATE]"	= FREQ_AI,
	"[RADIO_CHANNEL_MEDICAL_I]"		= FREQ_MED_I,
	"[RADIO_CHANNEL_SECURITY_I]"	= FREQ_SEC_I
))

// central command channels, i.e deathsquid
#define CEFREQ_NTS list(FREQ_DTH)

// Antag channels, i.e. Syndicate
#define ANTAG_FREQS list(FREQ_SYND, FREQ_YARR)

//Department channels, arranged lexically
#define DEPT_FREQS list(FREQ_AI, FREQ_COMM, FREQ_ENG, FREQ_MED, FREQ_NT, FREQ_SEC, FREQ_SCI, FREQ_SRV, FREQ_SUP)

GLOBAL_LIST_INIT(freqtospan, list(
	"[FREQ_COMM]" = "comradio",
	"[FREQ_AI]"   = "airadio",
	"[FREQ_SEC]"  = "secradio",
	"[FREQ_ENG]"  = "engradio",
	"[FREQ_SCI]"  = "sciradio",
	"[FREQ_MED]"  = "medradio",
	"[FREQ_SUP]"  = "supradio",
	"[FREQ_SRV]"  = "srvradio",
	"[FREQ_NT]"   = "ntradio"
))

/proc/get_radio_span(freq)
	var/returntext = GLOB.freqtospan["[freq]"]

	if(freq in ANTAG_FREQS)
		return "syndradio"
	if(freq in CEFREQ_NTS)
		return "centradio"
	if(freq in DEPT_FREQS)
		return "deptradio"

	if(returntext)
		return returntext
	return "radio"

//callback used by objects to react to incoming radio signals
/obj/proc/receive_signal(datum/signal/signal, receive_method, receive_param)
	return null

// TODO: Make devices weakrefs
/datum/radio_frequency
	var/frequency
	/// List of filters -> list of devices
	var/list/list/datum/weakref/devices = list()

/datum/radio_frequency/New(freq)
	frequency = freq

//If range > 0, only post to devices on the same z_level and within range
//Use range = -1, to restrain to the same z_level without limiting range
/datum/radio_frequency/proc/post_signal(obj/source as obj|null, datum/signal/signal, filter = null as text|null, range = null as num|null)
	// Ensure the signal's data is fully filled
	signal.source = source
	signal.frequency = frequency

	//Apply filter to the signal. If none supply, broadcast to every devices
	//_default channel is always checked
	var/list/filter_list

	if(filter)
		filter_list = list(filter,"_default")
	else
		filter_list = devices

	//If checking range, find the source turf
	var/turf/start_point
	if(range)
		start_point = get_turf(source)
		if(!start_point)
			return

	//Send the data
	for(var/current_filter in filter_list)
		for(var/datum/weakref/device_ref as anything in devices[current_filter])
			var/obj/device = device_ref.resolve()
			if(!device)
				devices[current_filter] -= device_ref
				continue
			if(device == source)
				continue
			if(range)
				var/turf/end_point = get_turf(device)
				if(!end_point)
					continue
				if(start_point.z != end_point.z || (range > 0 && get_dist(start_point, end_point) > range))
					continue
			device.receive_signal(signal, TRANSMISSION_RADIO, frequency)
			CHECK_TICK


// /datum/radio_frequency/proc/send_to_filter(obj/source, datum/signal/signal, filter, turf/start_point = null, range = null)
// 	if (range && !start_point)
// 		return
// 	for(var/obj/device in devices[filter])
// 		if(device == source)
// 			continue
// 		if(range)
// 			var/turf/end_point = get_turf(device)
// 			if(!end_point)
// 				continue
// 			if(start_point.z != end_point.z || get_dist(start_point, end_point) > range)
// 				continue
// 		device.receive_signal(signal, TRANSMISSION_RADIO, frequency)

/datum/radio_frequency/proc/add_listener(obj/device, filter as text|null)
	if (!filter)
		filter = "_default"

	var/datum/weakref/new_listener = WEAKREF(device)
	if(isnull(new_listener))
		return stack_trace("null, non-datum, or qdeleted device")
	var/list/devices_line = devices[filter]
	if(!devices_line)
		devices[filter] = devices_line = list()
	devices_line += new_listener

/datum/radio_frequency/proc/remove_listener(obj/device)
	for(var/devices_filter in devices)
		var/list/devices_line = devices[devices_filter]
		if(!devices_line)
			devices -= devices_filter
		devices_line -= WEAKREF(device)
		if(!devices_line.len)
			devices -= devices_filter

/datum/signal
	var/obj/source

	var/transmission_method = 0 //unused at the moment
	//0 = wire
	//1 = radio transmission
	//2 = subspace transmission

	var/list/data = list()
	var/encryption

	var/frequency = 0

/datum/signal/proc/copy_from(datum/signal/model)
	source = model.source
	transmission_method = model.transmission_method
	data = model.data
	encryption = model.encryption
	frequency = model.frequency

/datum/signal/proc/debug_print()
	if (source)
		. = "signal = {source = '[source]' ([source:x],[source:y],[source:z])\n"
	else
		. = "signal = {source = '[source]' ()\n"
	for (var/i in data)
		. += "data\[\"[i]\"\] = \"[data[i]]\"\n"
		if(islist(data[i]))
			var/list/L = data[i]
			for(var/t in L)
				. += "data\[\"[i]\"\] list has: [t]"
