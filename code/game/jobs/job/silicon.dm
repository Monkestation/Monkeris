/datum/job/ai
	title = "AI"
	flag = AI
	department_flag = COMMAND
	department = DEPARTMENT_COMMAND
	exp_required_type = "AI"
	exp_granted_type = EXP_TYPE_CREW
	faction = "CEV Eris"
	total_positions = 1 // Not used for AI, see is_position_available below and modules/mob/living/silicon/ai/latejoin.dm
	spawn_positions = 1 // |-> above message is partly true, it is used by /AssignRole so we still need to set it to 1
	selection_color = "#b5b7cb"
	supervisors = "your laws"
	req_admin_notify = 1
	account_allowed = 0
	wage = WAGE_NONE
	outfit_type = /decl/hierarchy/outfit/job/silicon/ai

/datum/job/ai/equip(mob/living/carbon/human/H, alt_title)
	return FALSE

/datum/job/ai/is_position_available()
	return (empty_playable_ai_cores.len != 0)

/obj/landmark/join/start/AI
	icon_state = "player-grey"
	name = "AI"
	join_tag = /datum/job/ai
	delete_me = FALSE//do we really need this huh??

/obj/landmark/join/start/triai
	icon_state = "ai-green"
	name = "triai"
	join_tag = "triai"

/datum/job/cyborg
	title = "Robot"
	flag = CYBORG
	department = DEPARTMENT_SILICON
	department_flag = MISC
	exp_granted_type = EXP_TYPE_CREW
	faction = "CEV Eris"
	total_positions = 2
	spawn_positions = 2
	alt_titles = list("Drone", "Cyborg")
	supervisors = "your laws and the AI"
	selection_color = "#cdcfe0"
	account_allowed = 0
	wage = WAGE_NONE

	outfit_type = /decl/hierarchy/outfit/job/silicon/cyborg

/datum/job/cyborg/equip(mob/living/carbon/human/H, alt_title)
	return FALSE

/obj/landmark/join/start/cyborg
	join_tag = /datum/job/cyborg
