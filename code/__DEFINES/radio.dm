/*
Frequency range: 1200 to 1600
Radiochat range: 1441 to 1489 (most devices refuse to be tune to other frequency, even during mapmaking)

Radio:
1459 - standard radio chat
1364 - NT department
1351 - Science
1353 - Command
1355 - Medical
1357 - Engineering
1359 - Security
1341 - deathsquad
1443 - Confession Intercom
1347 - Cargo techs
1349 - Service people

Devices:
1451 - tracking implant
1457 - RSD default
1201 - Player-build blast doors and shutters.

On the map:
1311 for prison shuttle console (in fact, it is not used)
1435 for status displays
1437 for atmospherics/fire alerts
1438 for engine components
1439 for air pumps, air scrubbers, atmo control
1441 for atmospherics - supply tanks
1443 for atmospherics - distribution loop/mixed air tank
1445 for bot nav beacons
1447 for mulebot, secbot and ed209 control
1449 for airlock controls, electropack, magnets
1451 for toxin lab access
1453 for engineering access
1455 for AI access
1461 for circuits
*/

#define RADIO_CHANNEL_COMMON "Common"
#define RADIO_KEY_COMMON "h"

#define RADIO_CHANNEL_SCIENCE "Science"
#define RADIO_KEY_SCIENCE "n"

#define RADIO_CHANNEL_COMMAND "Command"
#define RADIO_KEY_COMMAND "c"

#define RADIO_CHANNEL_MEDICAL "Medical"
#define RADIO_KEY_MEDICAL "m"

#define RADIO_CHANNEL_ENGINEERING "Engineering"
#define RADIO_KEY_ENGINEERING "e"

#define RADIO_CHANNEL_SECURITY "Security"
#define RADIO_KEY_SECURITY "s"

#define RADIO_CHANNEL_SPEC_OPS "Special Ops"
#define RADIO_KEY_SPEC_OPS "o" // Verify key

#define RADIO_CHANNEL_MERCENARY "Mercenary"
#define RADIO_KEY_MERCENARY "y"

#define RADIO_CHANNEL_PIRATE "Pirate"
#define RADIO_KEY_PIRATE "x"

#define RADIO_CHANNEL_SUPPLY "Supply"
#define RADIO_KEY_SUPPLY "u"

#define RADIO_CHANNEL_NT_VOICE "NT Voice"
#define RADIO_KEY_NT_VOICE "t"

#define RADIO_CHANNEL_SERVICE "Service"
#define RADIO_KEY_SERVICE "v"

#define RADIO_CHANNEL_AI_PRIVATE "AI Private"
#define RADIO_KEY_AI_PRIVATE "p"

#define RADIO_CHANNEL_MEDICAL_I "Medical(I)"
#define RADIO_KEY_MEDICAL_I "mi" // Verify key

#define RADIO_CHANNEL_SECURITY_I "Security(I)"
#define RADIO_KEY_SECURITY_I "si" // Verify key

#define MIN_FREQ 1441
#define MAX_FREQ 1489
#define FREQ_RADIO_LOW 1200
#define FREQ_RADIO_HIGH 1600

#define FREQ_BOT 1447
#define FREQ_COMM 1353
#define FREQ_AI 1343
#define FREQ_DTH 1341
#define FREQ_SYND 1213

// For player built blast doors.
#define FREQ_BLAST_DOOR 1201
#define FREQ_YARR 1220

// department channels
#define FREQ_COMMON 1459
#define FREQ_NT 1364
#define FREQ_SEC 1359
#define FREQ_ENG 1357
#define FREQ_MED 1355
#define FREQ_SCI 1351
#define FREQ_SRV 1349
#define FREQ_SUP 1347

// internal department channels
#define FREQ_MED_I 1485
#define FREQ_SEC_I 1475


#define TRANSMISSION_WIRE	0
#define TRANSMISSION_RADIO	1

/* filters */
//When devices register with the radio controller, they might register under a certain filter.
//Other devices can then choose to send signals to only those devices that belong to a particular filter.
//This is done for performance, so we don't send signals to lots of machines unnecessarily.

//This filter is special because devices belonging to default also recieve signals sent to any other filter.
#define RADIO_DEFAULT "radio_default"

#define RADIO_TO_AIRALARM "radio_airalarm" //air alarms
#define RADIO_FROM_AIRALARM "radio_airalarm_rcvr" //devices interested in recieving signals from air alarms
#define RADIO_CHAT "radio_telecoms"
#define RADIO_ATMOSIA "radio_atmos"
#define RADIO_NAVBEACONS "radio_navbeacon"
#define RADIO_AIRLOCK "radio_airlock"
#define RADIO_SECBOT "radio_secbot"
#define RADIO_MULEBOT "radio_mulebot"
#define RADIO_MAGNETS "radio_magnet"
#define RADIO_BLASTDOORS "radio_blastdoors"
