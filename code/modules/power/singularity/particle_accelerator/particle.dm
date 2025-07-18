//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:33

/obj/effect/accelerated_particle
	name = "Accelerated Particles"
	desc = "Dozens of tiny glowing lights zooming at incredible speeds."
	icon = 'icons/obj/machines/particle_accelerator2.dmi'
	icon_state = "particle"//Need a new icon for this
	anchored = TRUE
	density = TRUE
	var/movement_range = 10
	var/energy = 10		//energy in eV
	var/mega_energy = 0	//energy in MeV
	var/frequency = 1
	var/ionizing = 0
	var/particle_type
	var/additional_particles = 0
	var/turf/target
	var/turf/source
	var/movetotarget = 1

/obj/effect/accelerated_particle/weak
	movement_range = 8
	energy = 5

/obj/effect/accelerated_particle/strong
	movement_range = 15
	energy = 15


/obj/effect/accelerated_particle/New(loc, dir = 2)
	src.loc = loc
	src.set_dir(dir)
	if(movement_range > 20)
		movement_range = 20
	spawn(0)
		move(1)
	return


/obj/effect/accelerated_particle/Bump(atom/A)
	if (A)
		if(ismob(A))
			toxmob(A)
		if((istype(A,/obj/machinery/the_singularitygen))||(istype(A,/obj/singularity/)))
			A:energy += energy
	return


/obj/effect/accelerated_particle/Bumped(atom/A)
	if(ismob(A))
		Bump(A)
	return


/obj/effect/accelerated_particle/explosion_act(target_power, explosion_handler/handler)
	qdel(src)
	return 0



/obj/effect/accelerated_particle/proc/toxmob(mob/living/M)
	var/radiation = (energy*2)
	M.apply_effect((radiation*3),IRRADIATE,0)
	M.updatehealth()
	//M << span_red("You feel odd.")
	return


/obj/effect/accelerated_particle/proc/move(lag)
	if(target)
		if(movetotarget)
			if(!step_towards(src,target))
				src.loc = get_step(src, get_dir(src,target))
			if(get_dist(src,target) < 1)
				movetotarget = 0
		else
			if(!step(src, get_step_away(src,source)))
				src.loc = get_step(src, get_step_away(src,source))
	else
		if(!step(src,dir))
			src.loc = get_step(src,dir)
	movement_range--
	if(movement_range <= 0)
		qdel(src)
	else
		sleep(lag)
		move(lag)
