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

#define ASSISTANT_TITLE "Vagabond"

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
#define JOBS_SECURITY "Ironhammer Commander","Ironhammer Gunnery Sergeant","Ironhammer Inspector","Ironhammer Medical Specialist","Ironhammer Operative"
#define JOBS_ARMORY "Captain","First Officer","Communications Officer","Ironhammer Commander","Ironhammer Gunnery Sergeant"
#define JOBS_COMMAND "Captain","First Officer","Communications Officer","Ironhammer Commander","Guild Merchant","Technomancer Exultant","Moebius Biolab Officer","Moebius Expedition Overseer","NeoTheology Preacher"
#define JOBS_ENGINEERING "Technomancer Exultant","Technomancer"
#define JOBS_MEDICAL "Moebius Biolab Officer","Moebius Doctor","Moebius Psychiatrist","Moebius Chemist","Moebius Paramedic","Moebius Bio-Engineer"
#define JOBS_SCIENCE "Moebius Expedition Overseer","Moebius Scientist","Moebius Roboticist"
#define JOBS_MOEBIUS "Moebius Biolab Officer","Moebius Doctor","Moebius Psychiatrist","Moebius Chemist","Moebius Paramedic","Moebius Bio-Engineer","Moebius Expedition Overseer","Moebius Scientist","Moebius Roboticist"
#define JOBS_CARGO "Guild Merchant","Guild Technician","Guild Miner",
#define JOBS_CIVILIAN "Club Manager","Club Worker","Club Artist",ASSISTANT_TITLE
#define JOBS_CHURCH	"NeoTheology Preacher","NeoTheology Acolyte","NeoTheology Agrolyte","NeoTheology Custodian"
#define JOBS_NONHUMAN "AI","Robot","pAI"
#define CREDITS "&cent;"
#define CREDS "&cent;"


#define DEPARTMENT_COMMAND	"Command"
#define DEPARTMENT_MEDICAL	"Medical"
#define DEPARTMENT_ENGINEERING	"Engineering"
#define DEPARTMENT_SCIENCE	"Science"
#define DEPARTMENT_SECURITY "Security"
#define DEPARTMENT_GUILD "Guild"
#define DEPARTMENT_CIVILIAN	"Civilian"
#define DEPARTMENT_CHURCH	"Church"
#define DEPARTMENT_OFFSHIP "Offship"
#define DEPARTMENT_SILICON "Silicon"


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
