/proc/count_drones()
	var/drones = 0
	for(var/mob/living/silicon/robot/drone/D in GLOB.drones)
		if(D.key && D.client)
			drones++
	return drones

/obj/machinery/drone_fabricator
	name = "drone fabricator"
	desc = "A large automated factory for producing maintenance drones."

	density = TRUE
	anchored = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 20
	active_power_usage = 5000

	var/fabricator_tag = "Eris"
	var/drone_progress = 0
	var/produce_drones = 1
	var/time_last_drone = 500
	var/drone_type = /mob/living/silicon/robot/drone

	icon = 'icons/obj/machines/drone_fab.dmi'
	icon_state = "drone_fab_idle"

/obj/machinery/drone_fabricator/New()
	..()

/obj/machinery/drone_fabricator/power_change()
	..()
	if (stat & NOPOWER)
		icon_state = "drone_fab_nopower"

/obj/machinery/drone_fabricator/Process()

	if(SSticker.current_state < GAME_STATE_PLAYING)
		return

	if(stat & NOPOWER || !produce_drones)
		if(icon_state != "drone_fab_nopower") icon_state = "drone_fab_nopower"
		return

	if(drone_progress >= 100)
		icon_state = "drone_fab_idle"
		return

	icon_state = "drone_fab_active"
	var/elapsed = world.time - time_last_drone
	drone_progress = round((elapsed/CONFIG_GET(number/drone_build_time))*100)

	if(drone_progress >= 100)
		visible_message("\The [src] voices a strident beep, indicating a drone chassis is prepared.")

/obj/machinery/drone_fabricator/examine(mob/user, extra_description = "")
	if(produce_drones && drone_progress >= 100 && isghost(user) && CONFIG_GET(flag/allow_drone_spawn) && count_drones() < CONFIG_GET(number/max_maint_drones))
		extra_description += "<BR><B>A drone is prepared. Select 'Join As Drone' from the Ghost tab to spawn as a maintenance drone.</B>"
	..(user, extra_description)

/obj/machinery/drone_fabricator/proc/create_drone(client/player, aibound = FALSE)

	if(stat & NOPOWER)
		return

	if(!produce_drones || !CONFIG_GET(flag/allow_drone_spawn) || count_drones() >= CONFIG_GET(number/max_maint_drones))
		return

	if(!player || (!isghost(player.mob) && !aibound))
		return

	announce_ghost_joinleave(player, 0, "They have taken control over a maintenance drone.")
	visible_message("\The [src] churns and grinds as it lurches into motion, disgorging a shiny new drone after a few moments.")
	flick("h_lathe_leave",src)

	time_last_drone = world.time
	if(!aibound)
		var/mob/living/silicon/robot/drone/new_drone = new drone_type(get_turf(src))
		if(player.mob && player.mob.mind) player.mob.mind.reset()
		new_drone.transfer_personality(player)
		new_drone.master_fabricator = src
	else
		var/mob/living/silicon/robot/drone/aibound/new_drone = new /mob/living/silicon/robot/drone/aibound(get_turf(src))
		var/mob/living/silicon/ai/M = player.mob
		new_drone.bound_ai = M // Save AI core in variable to be able to get back to it
		M.bound_drone = new_drone  // Save new drone in variable of AI
		new_drone.real_name = M.name + " controlled drone"
		new_drone.name = new_drone.real_name
		new_drone.laws = M.laws
		M.mind.active = 0 // We want to transfer the key manually
		M.mind.transfer_to(new_drone) // Transfer mind to drone
		new_drone.key = player.key // Manually transfer the key to log them in
		new_drone.master_fabricator = src

	drone_progress = 0

/mob/observer/ghost/verb/join_as_drone()
	set category = "Ghost"
	set name = "Respawn as Drone"
	set desc = "If there is a powered, enabled fabricator in the game world with a prepared chassis, join as a maintenance drone."
	try_drone_spawn(src)

/proc/try_drone_spawn(mob/user, obj/machinery/drone_fabricator/fabricator, aibound = FALSE)

	if(SSticker.current_state < GAME_STATE_PLAYING)
		to_chat(user, span_danger("The game hasn't started yet!"))
		return

	if(!CONFIG_GET(flag/allow_drone_spawn))
		to_chat(user, span_danger("That verb is not currently permitted."))
		return

	if(jobban_isbanned(user.ckey,"Robot"))
		to_chat(user, span_danger("You are banned from playing synthetics and cannot spawn as a drone."))
		return

	if(!user.MayRespawn(1, MINISYNTH) && !aibound)
		return

	if(!fabricator)

		var/list/all_fabricators = list()
		for(var/obj/machinery/drone_fabricator/DF in GLOB.machines)
			if((DF.stat & NOPOWER) || !DF.produce_drones || DF.drone_progress < 100)
				continue
			all_fabricators[DF.fabricator_tag] = DF

		if(!all_fabricators.len)
			to_chat(user, span_danger("There are no available drone spawn points, sorry."))
			return

		var/choice = input(user,"Spawning as a drone will not affect your crew or mouse respawn timers. Which fabricator do you wish to use?") as null|anything in all_fabricators
		if(!choice || !all_fabricators[choice])
			return
		fabricator = all_fabricators[choice]

	if(user && fabricator && !((fabricator.stat & NOPOWER) || !fabricator.produce_drones || fabricator.drone_progress < 100))
		fabricator.create_drone(user.client, aibound)
		fabricator.use_power(fabricator.active_power_usage)
		return 1
	return
