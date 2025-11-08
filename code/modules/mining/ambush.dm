#define AMBUSH_CLEANUP_DELAY 3 MINUTES //after the ambush ends, living mobs & any remaining burrows will be deleted this many minutes later.

#define AMBUSH_SKIRMISH "ambush_skirmish" //burrows will immediately unload 1 wave of enemies, then close up
#define AMBUSH_SIEGE "ambush_siege" //burrows will periodically spawn mobs according to spawn_interval until the ambush ends.

/datum/ambush_controller

	///the mob that triggered the ambush
	var/mob/living/ambushed_mob
	/// The location of the ambush
	var/turf/ambush_loc
	/// A List of burrows tied to this controller
	var/list/obj/structure/ambush_burrow/burrows = list()
	/// A List of mobs tied to this controller
	var/list/mob/living/carbon/superior_animal/ourmobs = list()
	///Allegedly used to keep processing() from runtiming
	var/processing = TRUE

	///A datum containing the behavior of our ambush
	var/datum/ambush_type/our_datum
	/// Number of burrows created since the start of the ambush
	var/count = 0
	/// A Timestamp of the last created burrow
	var/time_burrow = 0
	// A Timestamp of last spawn wave (in siege mode)
	var/time_spawn = 0
	/// reference to time ambush began
	var/start_time = 0
	///Do ambush burrows appear around the mob who spawned them, even if they move?
	var/following = TRUE

	///Essentially local list of ambushed mobs, to compare ssmobs.ambushed_mobs to
	var/list/our_ambushed_mobs

/datum/ambush_controller/New(turf/trigger_location, new_ambushed_mob, ambush_datum)
	our_datum = new ambush_datum()
	ambushed_mob = new_ambushed_mob

	if(!trigger_location || !our_datum)//if they forgot to pass a wave datum or trigger location, explode
		log_runtime("[src.type] is missing required new() arguments!")
		QDEL_NULL(src)
		return

	if(ambushed_mob) //get the starting location for our ambush
		ambush_loc = ambush_follow_check()
	if(!ambush_loc) //if no ambushed mob, just use the trigger location
		ambush_loc = trigger_location

	var/list/our_ambushed_mobs = new()
	//give mobs in range a warning they're about to be ambushed
	for(var/mob/living/ourmob as anything in hearers(8, ambush_loc))
		//add the mob to ambush reference lists
		our_ambushed_mobs += ourmob
		SSmobs.ambushed_mobs += ourmob
		ourmob.show_message(span_userdanger("You feel the ground tremble beneath you..."),2)
		shake_camera(ourmob, 6, 0.5, 0.25)
	playsound(ambush_loc, 'sound/effects/impacts/rumble4.ogg', 75, TRUE, extrarange = 4)

	start_time = world.time
	START_PROCESSING(SSobj, src)

/// gets the target's current loc if following is on or it hasn't been gotten before.
/datum/ambush_controller/proc/ambush_follow_check()
	if((following || !ambush_loc) && ambushed_mob)
		return ambushed_mob.loc
	else//if no ambushed mob, just use existing loc
		return ambush_loc


/datum/ambush_controller/Destroy()
	processing = FALSE
	//just in case the controller was qdel'd
	for(var/mob/living/ambushee as anything in our_ambushed_mobs)
		SSmobs.ambushed_mobs.Remove(ambushee)
	for(var/obj/structure/ambush_burrow/burrow in burrows)  // Unlink burrows and controller
		qdel(burrow)
	QDEL_NULL(our_datum)
	. = ..()

/datum/ambush_controller/Process()
	// I'm too scared to test this -Sun
	// Currently, STOP_PROCESSING does NOT instantly remove the object from processing queue
	// This is a quick and dirty fix for runtime error spam caused by this
	if(!processing)
		return

	//our work here is done. End ambush
	if(ambushed_mob.stat == DEAD || (world.time - start_time) - our_datum.setup_time >= our_datum.ambush_duration || count >= our_datum.spawn_cap)
		stop()

	var/burrow_num = burrows.len
	// Check if new burrows can be created
	if((burrow_num < our_datum.max_burrows) && (world.time - time_burrow) > our_datum.burrow_interval)
		time_burrow = world.time
		for(var/mob/ourmob as anything in hearers(8, ambush_loc))
			shake_camera(ourmob, 6, 0.5, 0.25)
		for(var/burrow in 1 to our_datum.burrow_number)
			count++
			spawn_burrow()

	// if we're in siege mode, ambush controller handles spawns directly
	if(our_datum.ambush_type != AMBUSH_SIEGE)
		return

	if((world.time - start_time) <= our_datum.setup_time)
		return

	// Check if a new spawn wave should occur
	if((world.time - time_spawn) <= our_datum.spawn_interval)
		return

	time_spawn = world.time

	for(var/obj/structure/ambush_burrow/ourburrow as anything in burrows)
		if(!get_turf(ourburrow))  // If the burrow is in nullspace for some reason
			burrows -= ourburrow  // Remove it from the pool of burrows
			continue
		ourburrow.spawn_mobs()


///locates an appropriate turf to spawn a burrow, then creates it
/datum/ambush_controller/proc/spawn_burrow()
	ambush_loc = ambush_follow_check()
	// Spawn burrow randomly in a donut around our ambush turf
	var/radius = our_datum.burrow_spawn_range
	var/turf/burrow_turf
	while(radius > 2)
		burrow_turf = pick(getcircle(ambush_loc, radius))
		if(!istype(burrow_turf)) // Try again with a smaller circle
			radius--
			continue
	if(!istype(burrow_turf))  // Something wrong is happening
		log_and_message_admins("Ambush controller failed to create a new burrow around ([ambush_loc.x], [ambush_loc.y], [ambush_loc.z]).")
		return

	//if we are in a closed space or target is not visible, move towards the spawn turf
	while(ambush_loc && check_density_no_mobs(burrow_turf) && burrow_turf != ambush_loc || !can_see(burrow_turf, ambush_loc))
		burrow_turf = get_step(burrow_turf, get_dir(burrow_turf, ambush_loc))
	// If we end up on top of the trigger loc, just spawn next to it
	if(burrow_turf == ambush_loc)
		burrow_turf = get_step(ambush_loc, pick(GLOB.cardinal))

	burrows += new /obj/structure/ambush_burrow(burrow_turf, src, our_datum)  // Spawn burrow at final location

///ends the ambush. Should preferentially be called before cleanup or a qdel
/datum/ambush_controller/proc/stop()
	// Disable processing
	processing = FALSE
	//give mobs in range an indicate that it's over
	for(var/mob/ourmob as anything in hearers(8, ambush_loc))
		ourmob.show_message(span_danger("The shaking in the ground finally subsides."),2)
	for(var/obj/structure/ambush_burrow/burrow in burrows)  //visibly collapse burrows to show players it's over
		burrow.crumble()
	//allow mobs in the original ambush range to once again trigger ambushes
	for(var/mob/living/ambushee as anything in our_ambushed_mobs)
		SSmobs.ambushed_mobs.Remove(ambushee)
	// Clean up controller and all remaining objects after given delay
	addtimer(CALLBACK(src, PROC_REF(cleanup)), AMBUSH_CLEANUP_DELAY)

///properly cleans up the controller. Final step of the deletion chain
/datum/ambush_controller/proc/cleanup()
	// Delete any remaining burrows
	for(var/obj/structure/ambush_burrow/burrow as anything in burrows)
		qdel(burrow)

	// Delete mobs
	for(var/mob/living/carbon/superior_animal/mob as anything in ourmobs)
		if(mob.stat == DEAD)
			continue
		qdel(mob)

	qdel(src)

//inherited from old golem controller. Why is it defined here? Good question
///check that determines if a turf is a wall or already holding a mob
/datum/ambush_controller/proc/check_density_no_mobs(turf/F)
	if(F.density)
		return TRUE
	for(var/atom/A in F)
		if(A.density && !(A.flags & ON_BORDER) && !ismob(A))
			return TRUE
	return FALSE



// AMBUSH TYPE DEFINES

/datum/ambush_type
	//ambush behavior vars
	/// Determines the logic burrows follow when spawning mobs
	var/ambush_type = AMBUSH_SKIRMISH
	/// Once this time passes, ambush ends
	var/ambush_duration = 20 SECONDS
	/// If set, ambush ends once this many burrows have spawned
	var/spawn_cap = 8
	/// Amnt. of prep time given between when the burrows first appear & mobs start spawning
	var/setup_time = 4 SECONDS

	//burrow vars
	/// If set, total number of burrows that can exist at any single time
	var/max_burrows = 4
	/// the number of burrows to spawn in a single wave
	var/burrow_number = 2
  /// Number of seconds that pass between each new burrow spawn wave
	var/burrow_interval = 10 SECONDS
	///the starting range at which the ambush controller will try to place burrows
	var/burrow_spawn_range = 6

	//mob vars
 	/// Number of mobs spawned by each burrow on spawn event
	var/mob_spawn = 3
	/// Probability of a mob being a special one instead of a normal one
	var/special_probability = 35
	/// Types of mobs normally spawned by the ambush
	var/list/normal_types = list(/mob/living/carbon/superior_animal/roach,
								/mob/living/carbon/superior_animal/roach/hunter,
								/mob/living/carbon/superior_animal/roach/support)
	/// Types of unusual mobs to be passed to the spawn pool according to special_probability
	var/list/special_types = list(/mob/living/carbon/superior_animal/roach/fuhrer,
								/mob/living/carbon/superior_animal/roach/nanite,
								/mob/living/carbon/superior_animal/roach/tank,
								/mob/living/carbon/superior_animal/roach/toxic)

	///Sound played before the ambush triggers
	//var/ambush_sound = 'sound/effects/impacts/rumble4.ogg'

	//siege-specific vars
	/// Number of seconds that pass between spawn events of burrows - if siege mode is enabled.
	var/spawn_interval = 15 SECONDS

/datum/ambush_type/golem
	max_burrows = 6
	burrow_number = 3

	special_probability = 5

	normal_types = list(/mob/living/carbon/superior_animal/golem/coal,
						/mob/living/carbon/superior_animal/golem/iron)

	special_types = list(/mob/living/carbon/superior_animal/golem/silver,
						/mob/living/carbon/superior_animal/golem/gold,
						/mob/living/carbon/superior_animal/golem/plasma,
						/mob/living/carbon/superior_animal/golem/uranium)


// /datum/golem_wave/negligible
// 	burrow_count = 2
// 	burrow_interval = 24 SECONDS
// 	golem_spawn = 2
// 	spawn_interval = 20 SECONDS
// 	special_probability = 0
// 	mineral_multiplier = 1.4

// /datum/golem_wave/typical
// 	burrow_count = 3
// 	burrow_interval = 24 SECONDS
// 	golem_spawn = 3
// 	spawn_interval = 18 SECONDS
// 	special_probability = 10
// 	mineral_multiplier = 1.7

// /datum/golem_wave/substantial
// 	burrow_count = 3
// 	burrow_interval = 24 SECONDS
// 	golem_spawn = 3
// 	spawn_interval = 18 SECONDS
// 	special_probability = 20
// 	mineral_multiplier = 2

// /datum/golem_wave/major
// 	burrow_count = 4
// 	burrow_interval = 20 SECONDS
// 	golem_spawn = 4
// 	spawn_interval = 14 SECONDS
// 	special_probability = 30
// 	mineral_multiplier = 2.3

// /datum/golem_wave/abnormal
// 	burrow_count = 5
// 	burrow_interval = 18 SECONDS
// 	golem_spawn = 4
// 	spawn_interval = 12 SECONDS
// 	special_probability = 30
// 	mineral_multiplier = 3.0
