/datum/job_flavor
	var/title
	var/list/stat_modifiers

/datum/job_flavor/assistant/stat_modifiers = list(
		STAT_ROB = 8,
		STAT_TGH = 8,
		STAT_BIO = 8,
		STAT_MEC = 8,
		STAT_VIG = 8,
		STAT_COG = 8
	)

/datum/job_flavor/assistant/veterinarian
	title = "Cattle Export Vehicle \"Theseus\" Veterinarian"

/datum/job_flavor/assistant/shepherd
	title = "Cattle Export Vehicle \"Theseus\" Shepherd"

/datum/job_flavor/assistant/colonist
	title = "Colony Expansion Vehicle \"Theseus\" Colonist"

/datum/job_flavor/assistant/geoengineer
	title = "Colony Expansion Vehicle \"Theseus\" Geoengineer"

/datum/job_flavor/assistant/ecologist
	title = "Colony Expansion Vehicle \"Theseus\" Ecologist"
	stat_modifiers = list(
		STAT_ROB = 8,
		STAT_TGH = 8,
		STAT_BIO = 16,
		STAT_MEC = 8,
		STAT_VIG = 8,
		STAT_COG = 8
	)

/datum/job_flavor/assistant/ensign
	title = "Command Evacuation Vehicle \"Theseus\" Ensign"
	stat_modifiers = list(
		STAT_ROB = 8,
		STAT_TGH = 16,
		STAT_BIO = 8,
		STAT_MEC = 8,
		STAT_VIG = 8,
		STAT_COG = 8
	)

/datum/job_flavor/assistant/pilot
	title = "Command Evacuation Vehicle \"Theseus\" Pilot"
	stat_modifiers = list(
		STAT_ROB = 8,
		STAT_TGH = 8,
		STAT_BIO = 8,
		STAT_MEC = 8,
		STAT_VIG = 16,
		STAT_COG = 8
	)

/datum/job_flavor/assistant/cmcp_janitor
	title = "Command Evacuation Vehicle \"Theseus\" Command Master Chief Petty Janitor"

/datum/job_flavor/assistant/dc_tech
	title = "Combat Engineer Vehicle \"Theseus\" Damage Control Technician"
	stat_modifiers = list(
		STAT_ROB = 8,
		STAT_TGH = 8,
		STAT_BIO = 8,
		STAT_MEC = 16,
		STAT_VIG = 8,
		STAT_COG = 8
	)

/datum/job_flavor/assistant/field_eng
	title = "Combat Engineer Vehicle \"Theseus\" Field Engineer"
	stat_modifiers = list(
		STAT_ROB = 8,
		STAT_TGH = 8,
		STAT_BIO = 8,
		STAT_MEC = 16,
		STAT_VIG = 8,
		STAT_COG = 8
	)

/datum/job_flavor/assistant/politruk
	title = "Cosmicheskiy Edinstveniy Velikohod \"Theseus\" Politruk"

/datum/job_flavor/assistant/krasnoarmeets
	title = "Cosmicheskiy Edinstveniy Velikohod \"Theseus\" Krasnoarmeets"

/datum/job_flavor/assistant/kosmonavt
	title = "Cosmicheskiy Edinstveniy Velikohod \"Theseus\" Kosmonavt"
	stat_modifiers = list(
		STAT_ROB = 16,
		STAT_TGH = 16,
		STAT_BIO = 16,
		STAT_MEC = 16,
		STAT_VIG = 16,
		STAT_COG = 16
	)

/datum/job_flavor/assistant/reg_officer
	title = "Czech Emigration Vessel \"Theseus\" Registration Officer"

/datum/job_flavor/assistant/refugee
	title = "Czech Emigration Vessel \"Theseus\" Refugee"

/datum/job_flavor/assistant/mig_officer
	title = "Czech Emigration Vessel \"Theseus\" Emigration Officer"

/datum/job_flavor/assistant/protein_farmer
	title = "Cockroach Exile Vessel \"Theseus\" Protein Farmer"
	stat_modifiers = list(
		STAT_ROB = 8,
		STAT_TGH = 8,
		STAT_BIO = 16,
		STAT_MEC = 8,
		STAT_VIG = 8,
		STAT_COG = 8
	)

/datum/job_flavor/assistant/biotechnician
	title = "Cockroach Exile Vessel \"Theseus\" Biotechnician"
	stat_modifiers = list(
		STAT_ROB = 8,
		STAT_TGH = 8,
		STAT_BIO = 16,
		STAT_MEC = 8,
		STAT_VIG = 8,
		STAT_COG = 8
	)

/datum/job_flavor/assistant/bioterror_spec
	title = "Cockroach Exile Vessel \"Theseus\" Bioterror Specialist"
	stat_modifiers = list(
		STAT_ROB = 8,
		STAT_TGH = 8,
		STAT_BIO = 16,
		STAT_MEC = 8,
		STAT_VIG = 16,
		STAT_COG = 8
	)

/datum/job_flavor/assistant/bomber
	title = "Capital Extermination Vessel \"Theseus\" Bomber"
	stat_modifiers = list(
		STAT_ROB = 8,
		STAT_TGH = 8,
		STAT_BIO = 8,
		STAT_MEC = 8,
		STAT_VIG = 16,
		STAT_COG = 8
	)

/datum/job_flavor/assistant/m_arms
	title = "Capital Extermination Vessel \"Theseus\" Master at Arms"
	stat_modifiers = list(
		STAT_ROB = 16,
		STAT_TGH = 16,
		STAT_BIO = 8,
		STAT_MEC = 8,
		STAT_VIG = 8,
		STAT_COG = 8
	)

/datum/job_flavor/assistant/loader
	title = "Capital Extermination Vessel \"Theseus\" Loader"
	stat_modifiers = list(
		STAT_ROB = 8,
		STAT_TGH = 16,
		STAT_BIO = 8,
		STAT_MEC = 8,
		STAT_VIG = 8,
	)

/datum/job_flavor/assistant/cat_psy
	title = "Cat Exhibition Vessel \"Theseus\" Cat Psychologist"

/datum/job_flavor/assistant/feline_herder
	title = "Cat Exhibition Vessel \"Theseus\" Feline Herder"

/datum/job_flavor/assistant/breeder
	title = "Cat Exhibition Vessel \"Theseus\" Breeder"

/datum/job_flavor/assistant/mixologist
	title = "Corporate Entertain Vehicle \"Theseus\" Mixologist"
	stat_modifiers = list(
		STAT_ROB = 8,
		STAT_TGH = 8,
		STAT_BIO = 16,
		STAT_MEC = 8,
		STAT_VIG = 8,
	)

/datum/job_flavor/assistant/stripper
	title = "Corporate Entertain Vehicle \"Theseus\" Stripper"

/datum/job_flavor/assistant/officiant
	title = "Corporate Entertain Vehicle \"Theseus\" Officiant"

/datum/job_flavor/assistant/quartermaster
	title = "Class \"Emigrator\" Vessel \"Theseus\" Quartermaster"

/datum/job_flavor/assistant/deck_chief
	title = "Class \"Emigrator\" Vessel \"Theseus\" Deck Chief"

/datum/job_flavor/assistant/deck_tech
	title = "Class \"Emigrator\" Vessel \"Theseus\" Deck Technician"

/datum/job_flavor/assistant/patriarch
	title = "Christian Era Vector \"Theseus\" Patriarch"

/datum/job_flavor/assistant/protodeacon
	title = "Christian Era Vector \"Theseus\" Protodeacon"

/datum/job_flavor/assistant/archimandrite
	title = "Christian Era Vector \"Theseus\" Archimandrite"

/datum/job_flavor/assistant/prisoner
	title = "Convict Exploitation Vehicle \"Theseus\" Prisoner"

/datum/job_flavor/assistant/guard
	title = "Convict Exploitation Vehicle \"Theseus\" Guard"

/datum/job_flavor/assistant/warden
	title = "Convict Exploitation Vehicle \"Theseus\" Warden"

/datum/job_flavor/assistant/smuggler
	title = "Cargo Export Vehicle \"Theseus\" Smuggler"

/datum/job_flavor/assistant/salesman
	title = "Cargo Export Vehicle \"Theseus\" Salesman"

/datum/job_flavor/assistant/stockmarket
	title = "Capital Exchange Venue \"Theseus\" Market Analyst"

/datum/job_flavor/assistant/executive
	title = "Capital Exchange Venue \"Theseus\" Executive"
