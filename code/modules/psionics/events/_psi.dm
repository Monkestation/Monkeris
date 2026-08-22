//Oh boy their brains ASSPLODE

/datum/storyevent/psi
	id = "psi"
	name = "Psionic Disruption"

	event_type =/datum/event/psi
	event_pools = list(EVENT_LEVEL_MODERATE = POOL_THRESHOLD_MODERATE)
	tags = list(TAG_DESTRUCTIVE, TAG_NEGATIVE)

/////////////////////////////////////////////////////////

/datum/event/psi
	startWhen = 30
	endWhen = 120

/datum/event/psi/announce()
	minor_announce( \
		"A localized disruption within the neighboring psionic continua has been detected. All psi-operant crewmembers \
		are advised to cease any sensitive activities and report to medical personnel in case of damage.", \
		"Cuchulain Sensor Array Automated Message", \
		'sound/misc/notice1.ogg'
		)

/datum/event/psi/end()
	minor_announce( \
		"The psi-disturbance has ended and baseline normality has been re-asserted. \
		Anything you still can't cope with is therefore your own problem.", \
		"Cuchulain Sensor Array Automated Message", \
		'sound/misc/notice2.ogg'
	)

/datum/event/psi/tick()
	for(var/thing in SSpsi.processing)
		apply_psi_effect(thing)

/datum/event/psi/proc/apply_psi_effect(datum/psi_complexus/psi)
	return
