/datum/species/golem
	name = "Golem"
	name_plural = "golems"

	icobase = 'icons/mob/human_races/r_golem.dmi'
	deform = 'icons/mob/human_races/r_golem.dmi'

	language = "Sol Common" //todo?
	unarmed_types = list(/datum/unarmed_attack/stomp, /datum/unarmed_attack/kick, /datum/unarmed_attack/punch)
	flags = NO_BREATHE | NO_PAIN | NO_BLOOD | NO_SCAN | NO_POISON | NO_MINOR_CUT
	spawn_flags = IS_RESTRICTED
	siemens_coefficient = 0

	injury_type =  INJURY_TYPE_HOMOGENOUS

	breath_type = null
	poison_type = null

	blood_color = "#515573"
	flesh_color = "#137E8F"

	has_process = list(
		BP_BRAIN = /obj/item/organ/internal/vital/brain/golem
		)

	death_message = "becomes completely motionless..."

/datum/species/golem/handle_post_spawn(mob/living/carbon/human/H)
	if(H.mind)
		H.mind.assigned_role = "Golem"
	H.real_name = "adamantine golem ([rand(1, 1000)])"
	H.name = H.real_name
	..()
