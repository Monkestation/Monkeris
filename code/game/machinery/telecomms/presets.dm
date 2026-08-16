// ### Preset machines  ###

//Relay

/obj/machinery/telecomms/relay/preset
	network = "eris"

/obj/machinery/telecomms/relay/preset/station
	id = "Station Relay"
	listening_levels = list(1,2,3,4,5)
	autolinkers = list("s_relay")

/obj/machinery/telecomms/relay/preset/telecomms
	id = "Telecomms Relay"
	autolinkers = list("relay")

/obj/machinery/telecomms/relay/preset/mining
	id = "Mining Relay"
	autolinkers = list("m_relay")

/obj/machinery/telecomms/relay/preset/ruskie
	id = "Ruskie Relay"
	hide = 1
	toggled = 0
	autolinkers = list("r_relay")

/obj/machinery/telecomms/relay/preset/pulsar
	name = "teleroachication relay"
	icon_state = "roach_relay"
	desc = "Utilizing the power of a bluespace roach to send massive amounts of data far away."
	id = "Pulsar Relay"
	produces_heat = 0
	autolinkers = list("p_relay")

/obj/machinery/telecomms/relay/preset/centcom
	id = "Centcom Relay"
	hide = 1
	toggled = 1
	//anchored = TRUE
	//use_power = NO_POWER_USE
	//idle_power_usage = 0
	produces_heat = 0
	autolinkers = list("c_relay")

//HUB

/obj/machinery/telecomms/hub/preset
	id = "Hub"
	network = "eris"
	autolinkers = list("hub", "relay", "c_relay", "s_relay", "m_relay", "r_relay", "p_relay", "science", "medical",
	"supply", "service", "common", "command", "engineering", "security", "nt", "unused",
	"receiverA", "broadcasterA")

/obj/machinery/telecomms/hub/preset_cent
	id = "CentCom Hub"
	network = "eris"
	produces_heat = 0
	autolinkers = list("hub_cent", "c_relay", "s_relay", "m_relay", "r_relay", "p_relay",
	 "centcom", "receiverCent", "broadcasterCent")

//Receivers

/obj/machinery/telecomms/receiver/preset_right
	id = "Receiver A"
	network = "eris"
	autolinkers = list("receiverA") // link to relay
	freq_listening = list(FREQ_AI, FREQ_SCI, FREQ_MED, FREQ_NT, FREQ_SUP, FREQ_SRV, FREQ_COMM, FREQ_ENG, FREQ_SEC)

//Common and other radio frequencies for people to freely use
/obj/machinery/telecomms/receiver/preset_right/New()
	for(var/i = MIN_FREQ; i < MAX_FREQ; i += 2)
		freq_listening |= i
	..()

/obj/machinery/telecomms/receiver/preset_cent
	id = "CentCom Receiver"
	network = "eris"
	produces_heat = 0
	autolinkers = list("receiverCent")
	freq_listening = list(FREQ_DTH)


//Buses

/obj/machinery/telecomms/bus/preset_one
	id = "Bus 1"
	network = "eris"
	freq_listening = list(FREQ_SCI, FREQ_MED)
	autolinkers = list("processor1", "science", "medical")

/obj/machinery/telecomms/bus/preset_two
	id = "Bus 2"
	network = "eris"
	freq_listening = list(FREQ_SUP, FREQ_SRV, FREQ_NT)
	autolinkers = list("processor2", "supply", "service", "nt", "unused")

/obj/machinery/telecomms/bus/preset_two/New()
	for(var/i = MIN_FREQ; i < MAX_FREQ; i += 2)
		if(i == FREQ_COMMON)
			continue
		freq_listening |= i
	..()

/obj/machinery/telecomms/bus/preset_three
	id = "Bus 3"
	network = "eris"
	freq_listening = list(FREQ_SEC, FREQ_COMM)
	autolinkers = list("processor3", "security", "command")

/obj/machinery/telecomms/bus/preset_four
	id = "Bus 4"
	network = "eris"
	freq_listening = list(FREQ_ENG, FREQ_AI, FREQ_COMMON)
	autolinkers = list("processor4", "engineering", "common")

/obj/machinery/telecomms/bus/preset_cent
	id = "CentCom Bus"
	network = "eris"
	freq_listening = list(FREQ_DTH)
	produces_heat = 0
	autolinkers = list("processorCent", "centcom")

//Processors

/obj/machinery/telecomms/processor/preset_one
	id = "Processor 1"
	network = "eris"
	autolinkers = list("processor1") // processors are sort of isolated; they don't need backward links

/obj/machinery/telecomms/processor/preset_two
	id = "Processor 2"
	network = "eris"
	autolinkers = list("processor2")

/obj/machinery/telecomms/processor/preset_three
	id = "Processor 3"
	network = "eris"
	autolinkers = list("processor3")

/obj/machinery/telecomms/processor/preset_four
	id = "Processor 4"
	network = "eris"
	autolinkers = list("processor4")

/obj/machinery/telecomms/processor/preset_cent
	id = "CentCom Processor"
	network = "eris"
	produces_heat = 0
	autolinkers = list("processorCent")

//Servers

/obj/machinery/telecomms/server/presets

	network = "eris"

/obj/machinery/telecomms/server/presets/science
	id = "Science Server"
	freq_listening = list(FREQ_SCI)
	autolinkers = list("science")

/obj/machinery/telecomms/server/presets/medical
	id = "Medical Server"
	freq_listening = list(FREQ_MED)
	autolinkers = list("medical")

/obj/machinery/telecomms/server/presets/supply
	id = "Supply Server"
	freq_listening = list(FREQ_SUP)
	autolinkers = list("supply")

/obj/machinery/telecomms/server/presets/service
	id = "Service Server"
	freq_listening = list(FREQ_SRV)
	autolinkers = list("service")

/obj/machinery/telecomms/server/presets/common
	id = "Common Server"
	freq_listening = list(FREQ_COMMON, FREQ_AI) // AI Private and Common
	autolinkers = list("common")

// "Unused" channels, AKA all others.
/obj/machinery/telecomms/server/presets/unused
	id = "Unused Server"
	freq_listening = list()
	autolinkers = list("unused")

/obj/machinery/telecomms/server/presets/unused/New()
	for(var/i = MIN_FREQ; i < MAX_FREQ; i += 2)
		if(i == FREQ_AI || i == FREQ_COMMON)
			continue
		freq_listening |= i
	..()

/obj/machinery/telecomms/server/presets/command
	id = "Command Server"
	freq_listening = list(FREQ_COMM)
	autolinkers = list("command")

/obj/machinery/telecomms/server/presets/engineering
	id = "Engineering Server"
	freq_listening = list(FREQ_ENG)
	autolinkers = list("engineering")

/obj/machinery/telecomms/server/presets/security
	id = "Security Server"
	freq_listening = list(FREQ_SEC)
	autolinkers = list("security")

/obj/machinery/telecomms/server/presets/centcom
	id = "CentCom Server"
	freq_listening = list(FREQ_DTH)
	produces_heat = 0
	autolinkers = list("centcom")

/obj/machinery/telecomms/server/presets/nt
	id = "NT Voice Server"
	freq_listening = list(FREQ_NT)
	autolinkers = list("nt")


//Broadcasters

//--PRESET LEFT--//

/obj/machinery/telecomms/broadcaster/preset_right
	id = "Broadcaster A"
	network = "eris"
	autolinkers = list("broadcasterA")

/obj/machinery/telecomms/broadcaster/preset_cent
	id = "CentCom Broadcaster"
	network = "eris"
	produces_heat = 0
	autolinkers = list("broadcasterCent")
