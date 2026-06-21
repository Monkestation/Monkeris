GLOBAL_LIST_INIT(department_command, list(DEPARTMENT_COMMAND))
GLOBAL_LIST_INIT(department_security, list(DEPARTMENT_SECURITY))
GLOBAL_LIST_INIT(department_moebius, list(DEPARTMENT_SCIENCE, DEPARTMENT_MEDICAL))
GLOBAL_LIST_INIT(department_engineering, list(DEPARTMENT_ENGINEERING))
GLOBAL_LIST_INIT(department_guild, list(DEPARTMENT_GUILD))
GLOBAL_LIST_INIT(department_church, list(DEPARTMENT_CHURCH))
GLOBAL_LIST_INIT(department_civilian, list(DEPARTMENT_CIVILIAN))

var/list/assistant_occupations = list()


var/list/command_positions = list(JOBS_COMMAND)


var/list/engineering_positions = list(JOBS_ENGINEERING)


var/list/medical_positions = list(JOBS_MEDICAL)


var/list/science_positions = list(JOBS_SCIENCE)


var/list/moebius_positions = list(JOBS_MOEBIUS)

//BS12 EDIT
var/list/cargo_positions = list(JOBS_CARGO)


var/list/church_positions = list(JOBS_CHURCH)


var/list/civilian_positions = list(JOBS_CIVILIAN)


var/list/security_positions = list(JOBS_SECURITY)
var/list/armory_positions = list(JOBS_ARMORY)

var/list/nonhuman_positions = list(JOBS_NONHUMAN)

// list of jobs that can be an intern
var/list/intern_possible_jobs = list(
	JOB_MOEBIUS_SCIENTIST,
	JOB_MOEBIUS_ROBOTICIST,
	JOB_MOEBIUS_PARAMEDIC,
	JOB_MOEBIUS_PSYCHIATRIST,
	JOB_IRONHAMMER_OPERATIVE,
	JOB_TECHNOMANCER,
	JOB_CLUB_WORKER,
	JOB_CLUB_ARTIST,
	JOB_GUILD_TECHNICIAN,
	JOB_GUILD_MINER,
	JOB_NEOTHEOLOGY_CUSTODIAN,
	JOB_ASSISTANT,
)

/proc/guest_jobbans(var/job)
	return ((job in command_positions) || (job in nonhuman_positions) || (job in armory_positions))
