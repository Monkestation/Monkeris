//The Hivemind is a rogue AI using nanites.
//The objective of this AI is to spread across the ship and destroy as much as possible.

#define HIVE_FACTION 			"hive"
#define MAX_NODES_AMOUNT 	2
#define MIN_NODES_RANGE		15
#define ishivemindmob(A) 	istype(A, /mob/living/simple_animal/hostile/hivemind)

var/datum/hivemind/hivemind_ai	// global.

/datum/hivemind // USUALLY if nothing fricks up theres only 1 datum that stores hivemind stuff
	var/name
	var/surname
	var/evo_points = 0
	var/evo_points_max = 1000
	var/evo_level = 0						// level of hivemind in general. This is our progress of evopoints, since they are resets after new node creation
	var/list/list_of_hive_nodes = list() 	// Here are stored "nodes" --- (/obj/machinery/hivemind_machine/node/)

	// Hivemind turns machinery types into his own corrupted stuff. Let's restrict what he corrupts in the list below:
	var/list/list_of_dont_assimilate = list(

		/obj/machinery/light,
		/obj/machinery/atmospherics,
		/obj/machinery/door,
		/obj/machinery/meter,
		/obj/machinery/camera,
		/obj/machinery/light_switch,
		/obj/machinery/firealarm,
		/obj/machinery/alarm,
		/obj/machinery/recharger,
		/obj/machinery/hologram,
		/obj/machinery/holoposter,
		/obj/machinery/button,
		/obj/machinery/status_display,
		/obj/machinery/floor_light,
		/obj/machinery/flasher,
		/obj/machinery/filler_object,
		/obj/machinery/hivemind_machine,
		/obj/machinery/cryopod,
		/obj/machinery/portable_atmospherics/hydroponics/soil,
		/obj/machinery/power/supermatter,
		/obj/machinery/portable_atmospherics/canister
		)

	var/list/global_abilities_cooldown = list()
	var/list/evopoints_price_list = list()


/datum/hivemind/New(_name, _surname)
	..()
	name	= _name		? 	_name	: pick(GLOB.hive_names)		//if name doesnt exist - pick one
	surname	= _surname	? 	_surname : pick(GLOB.hive_surnames)

	var/list/all_hive_machines = subtypesof(/obj/machinery/hivemind_machine) - /obj/machinery/hivemind_machine/node
	//price list building
	//here we create list with evopoints price to compare it at annihilation proc
	// below is us creating price list for every hivemachine. Every hivemachine is now a list with
	for(var/hivemachine_path in all_hive_machines)
		var/obj/machinery/hivemind_machine/created_hivemachine = new hivemachine_path
		evopoints_price_list[hivemachine_path] = list("level" = created_hivemachine.evo_level_required, "weight" = created_hivemachine.spawn_weight)
		qdel(created_hivemachine)
	message_admins("Hivemind [name] [surname] has been created.")


/datum/hivemind/proc/die()
	message_admins("Hivemind [name] [surname] is destroyed.")
	hivemind_ai = null
	qdel(src)
	level_eight_beta_announcement()

/datum/hivemind/proc/get_evopoints()
#warn ensure this is balanced
	if(evo_points < evo_points_max)
		evo_points++

/datum/hivemind/proc/level_up()
#warn ensure this is balanced
	if(evo_points >= evo_level * 100)
		evo_level++
		evo_points = 0
