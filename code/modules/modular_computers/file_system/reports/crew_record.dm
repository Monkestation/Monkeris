GLOBAL_LIST_EMPTY(all_crew_records)
GLOBAL_LIST_INIT(blood_types, list("A-", "A+", "B-", "B+", "AB-", "AB+", "O-", "O+"))
GLOBAL_LIST_INIT(physical_statuses, list("Active", "Disabled", "SSD", "Deceased", "MIA"))
GLOBAL_VAR_INIT(default_physical_status, "Active")
GLOBAL_LIST_INIT(security_statuses, list("None", "Released", "Parolled", "Incarcerated", "*Arrest*"))
GLOBAL_VAR_INIT(default_security_status, "None")
GLOBAL_VAR_INIT(arrest_security_status, "Arrest")

// Kept as a computer file for possible future expansion into servers.
/datum/computer_file/report/crew_record
	filetype = "CDB"
	size = 2
	var/icon/photo_front = null
	var/icon/photo_side = null
	//More variables below.

/datum/computer_file/report/crew_record/New()
	..()
	load_from_mob(null)

/datum/computer_file/report/crew_record/Destroy()
	. = ..()
	GLOB.all_crew_records.Remove(src)

/datum/computer_file/report/crew_record/proc/load_from_mob(mob/living/carbon/human/H)
	if(istype(H))
		if(H.job == ASSISTANT_TITLE) // As stowaways, Vagabond do not show up on the crew manifest.
			GLOB.all_crew_records.Remove(src)
			return
		photo_front = getFlatIcon(H, SOUTH)
		photo_side = getFlatIcon(H, WEST)
	else
		var/mob/living/carbon/human/dummy/mannequin/dummy = new()
		photo_front = getFlatIcon(dummy, SOUTH)
		photo_side = getFlatIcon(dummy, WEST)
		qdel(dummy)

	// Generic record
	set_name(H ? H.real_name : "")
	set_department(H ? GetDepartment(H) : "Unset")
	set_job(H ? GetAssignment(H) : "Unset")
	set_sex(H ? gender2text(H.get_sex()) : "Unset")
	set_age(H ? H.age : 30)
	set_status(GLOB.default_physical_status)

	set_email((H && H.mind) ? H.mind.initial_email_login["login"] : "none")
	set_account((H && H.mind) ? H.mind.initial_account.account_number : "000000")


	set_species(SPECIES_HUMAN)
	//set_branch(H ? (H.char_branch && H.char_branch.name) : "None")
	//set_rank(H ? (H.char_rank && H.char_rank.name) : "None")

	// Medical record
	set_bloodtype(H ? H.b_type : "Unset")
	set_medRecord((H && H.med_record && !jobban_isbanned(H.ckey, "Records") ? html_decode(H.med_record) : "No record supplied"))

	// Security record
	set_criminalStatus(GLOB.default_security_status)
	set_dna(H ? H.dna_trace : "")
	set_fingerprint(H ? H.fingers_trace : "")
	set_secRecord(H && H.sec_record && !jobban_isbanned(H.ckey, "Records") ? html_decode(H.sec_record) : "No record supplied")

	// Employment record
	var/employment_record = "No record supplied"
	if(H)
		if(H.gen_record && !jobban_isbanned(H.ckey, "Records"))
			employment_record = html_decode(H.gen_record)
		if(H.client && H.client.prefs)
			var/list/qualifications
			if(LAZYLEN(qualifications))
				employment_record = "[employment_record ? "[employment_record]\[br\]" : ""][jointext(qualifications, "\[br\]>")]"
	set_emplRecord(employment_record)


	if(H)
		var/stats = list()
		for(var/statName in ALL_STATS)
			var/points = H.stats.getStat(statName,pure = TRUE)
			if(points > STAT_LEVEL_NONE)
				stats += "[statName]: [points] ([statPointsToLevel(points)])"

		set_skillset(jointext(stats,"\n"))

	// Antag record
	set_antagRecord(H && H.exploit_record && !jobban_isbanned(H, "Records") ? html_decode(H.exploit_record) : "")

// Global methods
// Used by character creation to create a record for new arrivals.
/proc/CreateModularRecord(mob/living/carbon/human/H)
	var/datum/computer_file/report/crew_record/CR = new/datum/computer_file/report/crew_record()
	GLOB.all_crew_records.Add(CR)
	CR.load_from_mob(H)
	SortModularRecords()
	return CR

/proc/SortModularRecords()
	// improved bubble sort
	if(GLOB.all_crew_records.len > 1)
		for(var/i = 1, i <= GLOB.all_crew_records.len, i++)
			var/flag = FALSE
			for(var/j = 1, j <= GLOB.all_crew_records.len - 1, j++)
				var/datum/computer_file/report/crew_record/CR = GLOB.all_crew_records[j]
				var/datum/computer_file/report/crew_record/CR_NEXT = GLOB.all_crew_records[j+1]
				if(sorttext(CR.get_name(), CR_NEXT.get_name()) == -1)
					flag = TRUE
					GLOB.all_crew_records.Swap(j,j+1)
			if(!flag)
				break

// Gets crew records filtered by set of positions
/proc/department_crew_manifest(list/filter_positions, blacklist = FALSE)
	var/list/matches = list()
	for(var/datum/computer_file/report/crew_record/CR in GLOB.all_crew_records)
		var/rank = CR.get_job()
		if(blacklist)
			if(!(rank in filter_positions))
				matches.Add(CR)
		else
			if(rank in filter_positions)
				matches.Add(CR)
	return matches

// Simple record to HTML (for paper purposes) conversion.
// Not visually that nice, but it gets the work done, feel free to tweak it visually
/proc/record_to_html(datum/computer_file/report/crew_record/CR, access)
	var/dat = "<tt><H2>RECORD DATABASE DATA DUMP</H2><i>Generated on: [stationdate2text()] [stationtime2text()]</i><br>******************************<br>"
	dat += "<table>"
	for(var/datum/report_field/F in CR.fields)
		if(F.verify_access(access))
			dat += "<tr><td><b>[F.display_name()]</b>"
			if(F.needs_big_box)
				dat += "<tr>"
			dat += "<td>[F.get_value()]"
	dat += "</tt>"
	return dat

/proc/get_crewmember_record(name)
	for(var/datum/computer_file/report/crew_record/CR in GLOB.all_crew_records)
		if(CR.get_name() == name)
			return CR
	return null

/proc/GetDepartment(mob/living/carbon/human/H)
	if(H && H.mind && H.mind.assigned_job)
		return H.mind.assigned_job.department
	return "Unassigned"

/proc/GetAssignment(mob/living/carbon/human/H)
	if(!H)
		return "Unassigned"
	if(!H.mind)
		return H.job
	if(H.mind.role_alt_title)
		return H.mind.role_alt_title
	return H.mind.assigned_role





#define GETTER_SETTER(PATH, KEY) /datum/computer_file/report/crew_record/proc/get_##KEY(){var/datum/report_field/F = locate(/datum/report_field/##PATH/##KEY) in fields; if(F) return F.get_value()} \
/datum/computer_file/report/crew_record/proc/set_##KEY(given_value){var/datum/report_field/F = locate(/datum/report_field/##PATH/##KEY) in fields; if(F) F.set_value(given_value)}
#define SETUP_FIELD(NAME, KEY, PATH, ACCESS, ACCESS_EDIT) GETTER_SETTER(PATH, KEY); /datum/report_field/##PATH/##KEY;\
/datum/computer_file/report/crew_record/generate_fields(){..(); var/datum/report_field/##KEY = add_field(/datum/report_field/##PATH/##KEY, ##NAME);\
KEY.set_access(ACCESS, ACCESS_EDIT || ACCESS || access_heads)}

// Fear not the preprocessor, for it is a friend. To add a field, use one of these, depending on value type and if you need special access to see it.
// It will also create getter/setter procs for record datum, named like /get_[key here]() /set_[key_here](value) e.g. get_name() set_name(value)
// Use getter setters to avoid errors caused by typoing the string key.
#define FIELD_SHORT(NAME, KEY, ACCESS, ACCESS_EDIT) SETUP_FIELD(NAME, KEY, simple_text/crew_record, ACCESS, ACCESS_EDIT)
#define FIELD_LONG(NAME, KEY, ACCESS, ACCESS_EDIT) SETUP_FIELD(NAME, KEY, pencode_text/crew_record, ACCESS, ACCESS_EDIT)
#define FIELD_NUM(NAME, KEY, ACCESS, ACCESS_EDIT) SETUP_FIELD(NAME, KEY, number/crew_record, ACCESS, ACCESS_EDIT)
#define FIELD_LIST(NAME, KEY, OPTIONS, ACCESS, ACCESS_EDIT) FIELD_LIST_EDIT(NAME, KEY, OPTIONS, ACCESS, ACCESS_EDIT)
#define FIELD_LIST_EDIT(NAME, KEY, OPTIONS, ACCESS, ACCESS_EDIT) SETUP_FIELD(NAME, KEY, options/crew_record, ACCESS, ACCESS_EDIT);\
/datum/report_field/options/crew_record/##KEY/get_options(){return OPTIONS}

// GENERIC RECORDS
FIELD_SHORT("Name", name, null, access_change_ids)
FIELD_SHORT("Department", department, null, access_change_ids)
FIELD_SHORT("Job", job, null, access_change_ids)
FIELD_LIST("Sex", sex, record_genders(), null, access_change_ids)
FIELD_NUM("Age", age, null, access_change_ids)
FIELD_LIST_EDIT("Status", status, GLOB.physical_statuses, null, access_moebius)

FIELD_SHORT("Species",species, null, access_change_ids)
FIELD_SHORT("Email",email, null, access_change_ids)
FIELD_NUM("Account",account, null, access_change_ids)

// MEDICAL RECORDS
FIELD_LIST("Blood Type", bloodtype, GLOB.blood_types, access_moebius, access_moebius)
FIELD_LONG("Medical Record", medRecord, access_moebius, access_moebius)

// SECURITY RECORDS
FIELD_LIST("Criminal Status", criminalStatus, GLOB.security_statuses, access_security, access_security)
FIELD_LONG("Security Record", secRecord, access_security, access_security)
FIELD_SHORT("DNA", dna, access_security, access_security)
FIELD_SHORT("Fingerprint", fingerprint, access_security, access_security)

// EMPLOYMENT RECORDS
FIELD_LONG("Employment Record", emplRecord, access_heads, access_heads)
FIELD_LONG("Qualifications", skillset, access_heads, access_heads)

// ANTAG RECORDS
FIELD_LONG("Exploitable Information", antagRecord, access_syndicate, access_syndicate)

/datum/report_field/options/crew_record/criminalStatus/set_value(given_value)
	..()
	var/datum/computer_file/report/crew_record/C = owner
	for(var/h in GLOB.human_mob_list)
		var/mob/living/carbon/human/H = h
		if(H.get_id_name(H.name) == C.get_name())
			BITSET(H.hud_updateflag, WANTED_HUD)

//Options builderes
/datum/report_field/options/crew_record/rank/proc/record_ranks()
	//var/datum/computer_file/report/crew_record/record = owner
	//var/datum/mil_branch/branch = mil_branches.get_branch(record.get_branch())
	//if(!branch)
	//	return
	. = list()
	. |= "Unset"
	/*
	for(var/rank in branch.ranks)
		var/datum/mil_rank/RA = branch.ranks[rank]
		. |= RA.name
	*/

/datum/report_field/options/crew_record/sex/proc/record_genders()
	. = list()
	. |= "Unset"
	for(var/G in gender_datums)
		. |= gender2text(G)

/datum/report_field/options/crew_record/branch/proc/record_branches()
	. = list()
	. |= "Unset"
	/*for(var/B in mil_branches.branches)
		var/datum/mil_branch/BR = mil_branches.branches[B]
		. |= BR.name
*/
#undef GETTER_SETTER
#undef SETUP_FIELD
#undef FIELD_SHORT
#undef FIELD_LONG
#undef FIELD_NUM
#undef FIELD_LIST
#undef FIELD_LIST_EDIT
