#define JOB_AVAILABLE 0
#define JOB_UNAVAILABLE_GENERIC 1
#define JOB_UNAVAILABLE_BANNED 2
#define JOB_UNAVAILABLE_PLAYTIME 3
#define JOB_UNAVAILABLE_ACCOUNTAGE 4
#define JOB_UNAVAILABLE_SLOTFULL 5
/// Job unavailable due to incompatibility with an antag role.
#define JOB_UNAVAILABLE_ANTAG_INCOMPAT 6
#define JOB_UNAVAILABLE_CONDITIONS_UNMET 7

/// Used when the `get_job_unavailable_error_message` proc can't make sense of a given code.
#define GENERIC_JOB_UNAVAILABLE_ERROR "Error: Unknown job availability."

#define JOB_ASSISTANT "Vagabond"

/**
 * =======================
 * WARNING WARNING WARNING
 * WARNING WARNING WARNING
 * WARNING WARNING WARNING
 * =======================
 * These names are used as keys in many locations in the database
 * you cannot change them trivially without breaking job bans and
 * role time tracking, if you do this and get it wrong you will die
 * and it will hurt the entire time
 */

//Jobs depatment lists for use in constant expressions
#define JOB_IRONHAMMER_COMMANDER "Ironhammer Commander"
#define JOB_IRONHAMMER_GUNNERY_SERGEANT "Ironhammer Gunnery Sergeant"
#define JOB_IRONHAMMER_INSPECTOR "Ironhammer Inspector"
#define JOB_IRONHAMMER_MEDICAL_SPECIALIST "Ironhammer Medical Specialist"
#define JOB_IRONHAMMER_OPERATIVE "Ironhammer Operative"

#define JOB_CAPTAIN "Captain"
#define JOB_FIRST_OFFICER "First Officer"

#define JOB_GUILD_MERCHANT "Guild Merchant"
#define JOB_GUILD_TECHNICIAN "Guild Technician"
#define JOB_GUILD_MINER "Guild Miner"

#define JOB_TECHNOMANCER_EXULTANT "Technomancer Exultant"
#define JOB_TECHNOMANCER "Technomancer"

#define JOB_MOEBIUS_BIOLAB_OFFICER "Moebius Biolab Officer"
#define JOB_MOEBIUS_DOCTOR "Moebius Doctor"
#define JOB_MOEBIUS_PSYCHIATRIST "Moebius Psychiatrist"
#define JOB_MOEBIUS_CHEMIST "Moebius Chemist"
#define JOB_MOEBIUS_PARAMEDIC "Moebius Paramedic"
#define JOB_MOEBIUS_BIO_ENGINEER "Moebius Bio-Engineer"
#define JOB_MOEBIUS_EXPEDITION_OVERSEER "Moebius Expedition Overseer"
#define JOB_MOEBIUS_SCIENTIST "Moebius Scientist"
#define JOB_MOEBIUS_ROBOTICIST "Moebius Roboticist"

#define JOB_CLUB_MANAGER "Club Manager"
#define JOB_CLUB_WORKER "Club Worker"
#define JOB_CLUB_ARTIST "Club Artist"

#define JOB_NEOTHEOLOGY_PREACHER "NeoTheology Preacher"
#define JOB_NEOTHEOLOGY_ACOLYTE "NeoTheology Acolyte"
#define JOB_NEOTHEOLOGY_AGROLYTE "NeoTheology Agrolyte"
#define JOB_NEOTHEOLOGY_CUSTODIAN "NeoTheology Custodian"

#define JOB_AI "AI"
#define JOB_ROBOT "Robot"
#define JOB_PAI "pAI"

#define JOBS_SECURITY JOB_IRONHAMMER_COMMANDER, JOB_IRONHAMMER_GUNNERY_SERGEANT, JOB_IRONHAMMER_INSPECTOR, JOB_IRONHAMMER_MEDICAL_SPECIALIST, JOB_IRONHAMMER_OPERATIVE

#define JOBS_ARMORY JOB_CAPTAIN, JOB_FIRST_OFFICER, JOB_IRONHAMMER_COMMANDER, JOB_IRONHAMMER_GUNNERY_SERGEANT

#define JOBS_COMMAND JOB_CAPTAIN, JOB_FIRST_OFFICER, JOB_IRONHAMMER_COMMANDER, JOB_GUILD_MERCHANT, JOB_TECHNOMANCER_EXULTANT, JOB_MOEBIUS_BIOLAB_OFFICER, JOB_MOEBIUS_EXPEDITION_OVERSEER, JOB_NEOTHEOLOGY_PREACHER

#define JOBS_ENGINEERING JOB_TECHNOMANCER_EXULTANT, JOB_TECHNOMANCER

#define JOBS_MEDICAL JOB_MOEBIUS_BIOLAB_OFFICER, JOB_MOEBIUS_DOCTOR, JOB_MOEBIUS_PSYCHIATRIST, JOB_MOEBIUS_CHEMIST, JOB_MOEBIUS_PARAMEDIC, JOB_MOEBIUS_BIO_ENGINEER

#define JOBS_SCIENCE JOB_MOEBIUS_EXPEDITION_OVERSEER, JOB_MOEBIUS_SCIENTIST, JOB_MOEBIUS_ROBOTICIST

#define JOBS_MOEBIUS JOB_MOEBIUS_BIOLAB_OFFICER, JOB_MOEBIUS_DOCTOR, JOB_MOEBIUS_PSYCHIATRIST, JOB_MOEBIUS_CHEMIST, JOB_MOEBIUS_PARAMEDIC, JOB_MOEBIUS_BIO_ENGINEER, JOB_MOEBIUS_EXPEDITION_OVERSEER, JOB_MOEBIUS_SCIENTIST, JOB_MOEBIUS_ROBOTICIST

#define JOBS_CARGO JOB_GUILD_MERCHANT, JOB_GUILD_TECHNICIAN, JOB_GUILD_MINER

#define JOBS_CIVILIAN JOB_CLUB_MANAGER, JOB_CLUB_WORKER, JOB_CLUB_ARTIST, JOB_ASSISTANT

#define JOBS_CHURCH JOB_NEOTHEOLOGY_PREACHER, JOB_NEOTHEOLOGY_ACOLYTE, JOB_NEOTHEOLOGY_AGROLYTE, JOB_NEOTHEOLOGY_CUSTODIAN

#define JOBS_NONHUMAN JOB_AI, JOB_ROBOT, JOB_PAI

#define CREDITS "&cent;"
#define CREDS "&cent;"


#define DEPARTMENT_COMMAND		"Command"
#define DEPARTMENT_MEDICAL		"Medical"
#define DEPARTMENT_ENGINEERING	"Engineering"
#define DEPARTMENT_SCIENCE		"Science"
#define DEPARTMENT_SECURITY 	"Security"
#define DEPARTMENT_GUILD 		"Guild"
#define DEPARTMENT_CIVILIAN		"Civilian"
#define DEPARTMENT_CHURCH		"Church"
#define DEPARTMENT_OFFSHIP 		"Offship"
#define DEPARTMENT_SILICON		"Silicon"


// Department Bitfields (dawg these are so unorganized i dont even know what is what)
#define ENGINEERING		(1<<0)
#define IRONHAMMER 		(1<<1)
#define MEDICAL 		(1<<2)
#define SCIENCE 		(1<<3)
#define CIVILIAN 		(1<<4)
#define COMMAND 		(1<<5)
#define MISC 			(1<<6)
#define SERVICE 		(1<<7)
#define GUILD 			(1<<8)
#define CHURCH 			(1<<9)

#define ENGSEC 			(1<<0)

#define CAPTAIN 		(1<<0)
#define IHC 			(1<<1)
#define GUNSERG 		(1<<2)
#define INSPECTOR 		(1<<3)
#define IHOPER 			(1<<4)
#define MEDSPEC 		(1<<5)
#define EXULTANT 		(1<<6)
#define TECHNOMANCER 	(1<<7)
#define AI	 			(1<<8)
#define CYBORG 			(1<<9)


#define MEDSCI 			(1<<1)

#define MEO 			(1<<0)
#define SCIENTIST 		(1<<1)
#define CHEMIST 		(1<<2)
#define MBO 			(1<<3)
#define DOCTOR 			(1<<4)
#define PSYCHIATRIST 	(1<<5)
#define ROBOTICIST 		(1<<6)
#define PARAMEDIC 		(1<<7)
#define BIOENGINEER 	(1<<8)


#define FIRSTOFFICER 	(1<<0)
#define CLUBMANAGER 	(1<<1)
#define CLUBWORKER 		(1<<2)
#define MERCHANT 		(1<<3)
#define GUILDTECH 		(1<<4)
#define MINER 			(1<<5)
#define ARTIST 			(1<<6)
#define ASSISTANT 		(1<<7)


#define CHAPLAIN 		(1<<0)
#define ACOLYTE 		(1<<1)
#define JANITOR 		(1<<2)
#define BOTANIST 		(1<<3)

// exp

#define EXP_TYPE_LIVING "Living"
#define EXP_TYPE_CREW "Crew"

#define EXP_TYPE_ANTAG "Antag"
#define EXP_TYPE_SPECIAL "Special"
#define EXP_TYPE_GHOST "Ghost"
#define EXP_TYPE_ADMIN "Admin"

#define ALL_DEPARTMENTS list(DEPARTMENT_COMMAND, DEPARTMENT_MEDICAL, DEPARTMENT_ENGINEERING, DEPARTMENT_SCIENCE, DEPARTMENT_SECURITY, DEPARTMENT_GUILD, DEPARTMENT_CIVILIAN, DEPARTMENT_CHURCH)
#define ASTER_DEPARTMENTS list(DEPARTMENT_COMMAND, DEPARTMENT_GUILD)

/// Fallback time if none of the config entries are set for USE_LOW_LIVING_HOUR_INTERN
#define INTERN_THRESHOLD_FALLBACK_HOURS 15
