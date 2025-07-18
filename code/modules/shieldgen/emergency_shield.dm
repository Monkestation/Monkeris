
/obj/machinery/shield
	name = "Emergency energy shield"
	desc = "An energy shield used to contain hull breaches."
	icon = 'icons/effects/effects.dmi'
	description_info = "Generates atmospheric blocking-shields when in contact with space"
	description_antag = "The shields block bullets, but not lasers."
	icon_state = "shield-old"
	density = TRUE
	opacity = 0
	anchored = TRUE
	unacidable = 1
	var/const/maxShieldHealth = 200
	var/shieldHealth = maxShieldHealth //The shield can only take so much beating (prevents perma-prisons)
	var/shield_generate_power = 7500	//how much power we use when regenerating
	var/shield_idle_power = 1500		//how much power we use when just being sustained.

/obj/machinery/shield/malfai
	name = "emergency forcefield"
	desc = "A powerful forcefield which seems to be projected by the vessel's emergency atmosphere containment field."
	description_antag = "This special shield is overcharged, it has double the shieldHealth of a normal one and only blocks bullets."
	shieldHealth = 400

/obj/machinery/shield/proc/check_failure()
	if (shieldHealth <= 0)
		visible_message(span_notice("\The [src] dissipates!"))
		qdel(src)
		return

/obj/machinery/shield/New()
	set_dir(pick(1,2,3,4))
	..()
	update_nearby_tiles(need_rebuild=1)

/obj/machinery/shield/Destroy()
	update_nearby_tiles()
	. = ..()

/obj/machinery/shield/CanPass(atom/movable/mover, turf/target, height, air_group)
	if(!height || air_group) return 0
	else return ..()

/obj/machinery/shield/attackby(obj/item/W as obj, mob/user as mob)
	if(!istype(W)) return

	//Calculate damage
	var/aforce = W.force
	if(W.damtype == BRUTE || W.damtype == BURN)
		src.shieldHealth -= aforce

	//Play a fitting sound
	playsound(src.loc, 'sound/effects/EMPulse.ogg', 75, 1)

	check_failure()
	set_opacity(TRUE)
	spawn(20)
		if(src)
			set_opacity(FALSE)

	..()

/obj/machinery/shield/bullet_act(obj/item/projectile/Proj)
	shieldHealth -= Proj.get_structure_damage()
	..()
	check_failure()
	set_opacity(TRUE)
	spawn(20)
		if(src)
			set_opacity(FALSE)

/obj/machinery/shield/emp_act(severity)
	switch(severity)
		if(1)
			qdel(src)
		if(2)
			if(prob(50))
				qdel(src)
		if(3)
			if(prob(25))
				qdel(src)


/obj/machinery/shield/hitby(AM as mob|obj)
	//Let everyone know we've been hit!
	visible_message(span_notice("<B>The\ [src] was hit by [AM].</B>"))

	//Super realistic, resource-intensive, real-time damage calculations.
	var/tforce = 0
	if(ismob(AM))
		tforce = 40
	else
		tforce = AM:throwforce

	shieldHealth -= tforce

	//This seemed to be the best sound for hitting a force field.
	playsound(loc, 'sound/effects/EMPulse.ogg', 100, 1)

	check_failure()

	//The shield becomes dense to absorb the blow.. purely asthetic.
	set_opacity(TRUE)
	spawn(20)
		if(src)
			set_opacity(FALSE)

	..()
	return
/obj/machinery/shieldgen
	name = "Emergency shield projector"
	desc = "Used to seal minor hull breaches."
	icon = 'icons/obj/objects.dmi'
	icon_state = "shieldoff"
	density = TRUE
	opacity = 0
	anchored = FALSE
	req_access = list(access_engine)
	var/const/maxShieldHealth = 100
	var/shieldHealth = maxShieldHealth
	var/active = 0
	var/malfunction = 0 //Malfunction causes parts of the shield to slowly dissapate
	var/list/deployed_shields = list()
	var/list/regenerating = list()
	var/is_open = 0 //Whether or not the wires are exposed
	var/locked = 0
	var/check_delay = 60	//periodically recheck if we need to rebuild a shield
	use_power = NO_POWER_USE
	idle_power_usage = 0

/obj/machinery/shieldgen/Destroy()
	collapse_shields()
	. = ..()

/obj/machinery/shieldgen/proc/shields_up()
	if(active) return 0 //If it's already turned on, how did this get called?

	src.active = 1
	update_icon()

	create_shields()

	idle_power_usage = 0
	for(var/obj/machinery/shield/shield_tile in deployed_shields)
		idle_power_usage += shield_tile.shield_idle_power
	set_power_use(IDLE_POWER_USE)

/obj/machinery/shieldgen/proc/shields_down()
	if(!active) return 0 //If it's already off, how did this get called?

	src.active = 0
	update_icon()

	collapse_shields()

	set_power_use(NO_POWER_USE)

/obj/machinery/shieldgen/proc/create_shields()
	for(var/turf/target_tile in range(2, src))
		if (istype(target_tile,/turf/space) && !(locate(/obj/machinery/shield) in target_tile))
			if (malfunction && prob(33) || !malfunction)
				var/obj/machinery/shield/S = new/obj/machinery/shield(target_tile)
				deployed_shields += S
				use_power(S.shield_generate_power)

/obj/machinery/shieldgen/proc/collapse_shields()
	for(var/obj/machinery/shield/shield_tile in deployed_shields)
		qdel(shield_tile)

/obj/machinery/shieldgen/power_change()
	..()
	if(!active) return
	if (stat & NOPOWER)
		collapse_shields()
	else
		create_shields()
	update_icon()

/obj/machinery/shieldgen/Process()
	if (!active || (stat & NOPOWER))
		return

	if(malfunction)
		if(deployed_shields.len && prob(5))
			qdel(pick(deployed_shields))
	else
		if (check_delay <= 0)
			create_shields()

			var/new_power_usage = 0
			for(var/obj/machinery/shield/shield_tile in deployed_shields)
				new_power_usage += shield_tile.shield_idle_power

			if (new_power_usage != idle_power_usage)
				idle_power_usage = new_power_usage
				use_power(0)

			check_delay = 60
		else
			check_delay--

/obj/machinery/shieldgen/proc/checkhp()
	if(shieldHealth <= 30)
		src.malfunction = 1
	if(shieldHealth <= 0)
		spawn(0)
			explosion(get_turf(src), 50, 50)
		qdel(src)
	update_icon()
	return

/obj/machinery/shieldgen/take_damage(amount)
	shieldHealth -= amount / 2
	checkhp()
	return 0


/obj/machinery/shieldgen/emp_act(severity)
	switch(severity)
		if(1)
			src.shieldHealth /= 2 //cut shieldHealth in half
			malfunction = 1
			locked = pick(0,1)
		if(2)
			if(prob(50))
				src.shieldHealth *= 0.3 //chop off a third of the shieldHealth
				malfunction = 1
	checkhp()

/obj/machinery/shieldgen/attack_hand(mob/user as mob)
	if(locked)
		to_chat(user, "The machine is locked, you are unable to use it.")
		return
	if(is_open)
		to_chat(user, "The panel must be closed before operating this machine.")
		return
	var/iconhtml = icon2html(src, hearers(get_turf(src)))
	if (src.active)
		user.visible_message(span_blue("[iconhtml] [user] deactivated the shield generator."), \
			span_blue("[iconhtml] You deactivate the shield generator."), \
			"You hear heavy droning fade out.")
		src.shields_down()
	else
		if(anchored)
			user.visible_message(span_blue("[iconhtml] [user] activated the shield generator."), \
				span_blue("[iconhtml] You activate the shield generator."), \
				"You hear heavy droning.")
			src.shields_up()
		else
			to_chat(user, "The device must first be secured to the floor.")
	return

/obj/machinery/shieldgen/emag_act(remaining_charges, mob/user)
	if(!malfunction)
		malfunction = 1
		update_icon()
		return TRUE

/obj/machinery/shieldgen/attackby(obj/item/I, mob/user)

	var/tool_type = I.get_tool_type(user, list(QUALITY_BOLT_TURNING, QUALITY_SCREW_DRIVING), src)
	switch(tool_type)

		if(QUALITY_BOLT_TURNING)
			if(locked)
				to_chat(user, span_notice("The bolts are covered, unlocking this would retract the covers."))
				return
			if(I.use_tool(user, src, WORKTIME_NEAR_INSTANT, tool_type, FAILCHANCE_EASY,  required_stat = STAT_MEC))
				if(anchored)
					to_chat(user, span_notice("You unsecure the [src] from the floor!"))
					if(active)
						to_chat(user, span_notice("The [src] shuts off!"))
						src.shields_down()
					anchored = FALSE
				else
					if(istype(get_turf(src), /turf/space)) return //No wrenching these in space!
					to_chat(user, span_notice("You secure the [src] to the floor!"))
					anchored = TRUE
			return

		if(QUALITY_SCREW_DRIVING)
			if(I.use_tool(user, src, WORKTIME_NEAR_INSTANT, tool_type, FAILCHANCE_EASY,  required_stat = STAT_MEC, instant_finish_tier = 30))
				is_open = !is_open
				to_chat(user, span_notice("You [is_open ? "open" : "close"] the panel of \the [src] with [I]."))
			return

		if(ABORT_CHECK)
			return

	if(istype(I, /obj/item/stack/cable_coil) && malfunction && is_open)
		var/obj/item/stack/cable_coil/coil = I
		to_chat(user, span_notice("You begin to replace the wires."))
		if(do_after(user, 30,src))
			if (coil.use(1))
				shieldHealth = maxShieldHealth
				malfunction = 0
				to_chat(user, span_notice("You repair the [src]!"))
				update_icon()

	else if(istype(I, /obj/item/card/id) || istype(I, /obj/item/modular_computer))
		if(src.allowed(user))
			src.locked = !src.locked
			to_chat(user, "The controls are now [src.locked ? "locked." : "unlocked."]")
		else
			to_chat(user, span_warning("Access denied."))

	else
		..()


/obj/machinery/shieldgen/update_icon()
	if(active && !(stat & NOPOWER))
		src.icon_state = malfunction ? "shieldonbr":"shieldon"
	else
		src.icon_state = malfunction ? "shieldoffbr":"shieldoff"
	return
