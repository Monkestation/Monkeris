/mob/living/exosuit/handle_disabilities()
	return

/mob/living/exosuit/Life()

	for(var/thing in pilots)
		var/mob/pilot = thing
		if(pilot.loc != src) // Admin jump or teleport/grab.
			if(pilot.client)
				pilot.client.screen -= HUDneed
				LAZYREMOVE(pilots, pilot)
				UNSETEMPTY(pilots)
		update_pilots()

	if(radio)
		radio.on = (head && head.radio && head.radio.is_functional() && get_cell())

	var/powered = FALSE
	var/obj/item/cell/mech_cell = get_cell()
	for(var/hardpoint in hardpoints)
		var/obj/item/mech_equipment/equip = hardpoints[hardpoint]
		if(QDELETED(equip))
			continue
		if(!(equip.equipment_flags & EQUIPFLAG_PRETICK))
			continue
		equip.pretick()

	if(mech_cell)
		powered = mech_cell.drain_power(0, 0, calc_power_draw()) > 0

	if(!powered)
		//Shut down all systems
		if(head)
			head.active_sensors = FALSE
		for(var/hardpoint in hardpoints)
			var/obj/item/mech_equipment/M = hardpoints[hardpoint]
			if(istype(M) && M.active && M.passive_power_use)
				M.deactivate()
	else
		//Loop through modules to process them if they're flagged to do so
		for(var/hardpoint in hardpoints)
			if(!hardpoints[hardpoint])
				continue

			var/obj/item/mech_equipment/module = hardpoints[hardpoint]
			if(module.equipment_flags & EQUIPFLAG_PROCESS)
				module.Process()

	// for chassis charging cells
	var/chargeUsed = 0
	if(powered && body && body.cell_charge_rate && mech_cell.charge > 1000)
		for(var/obj/item/cell/to_charge in body.storage_compartment)
			if(mech_cell.charge < 1000)
				break
			if(chargeUsed > body.cell_charge_rate)
				break
			var/chargeNeeded = min(to_charge.maxcharge - to_charge.charge, body.cell_charge_rate)
			if(!chargeNeeded)
				continue
			chargeUsed += to_charge.give(mech_cell.drain_power(0,0, chargeNeeded / CELLRATE))


	body.update_air(hatch_closed && use_air && (body && body.has_hatch))

	updatehealth()
	if(health <= 0 && stat != DEAD)
		death()
	. = ..() //Handles stuff like environment
	lying = FALSE // Fuck off, carp.
	handle_vision(powered)

/mob/living/exosuit/get_cell(force)
	RETURN_TYPE(/obj/item/cell)

	if(power == MECH_POWER_ON || force) //For most intents we can assume that a powered off exosuit acts as if it lacked a cell
		. = body ? body.cell : null
		if(!.)
			for(var/obj/item/mech_equipment/power_generator/gen in tickers)
				if(!. && gen.internal_cell)
					. = gen.internal_cell
		return .
	return null


/mob/living/exosuit/proc/calc_power_draw()
	//Passive power stuff here. You can also recharge cells or hardpoints if those make sense
	var/total_draw = 0
	for(var/hardpoint in hardpoints)
		var/obj/item/mech_equipment/I = hardpoints[hardpoint]
		if(!istype(I))
			continue

		total_draw += I.active ? I.active_power_use : I.passive_power_use

	if(head && head.active_sensors)
		total_draw += head.power_use

	if(body)
		total_draw += body.power_use

	return total_draw

/mob/living/exosuit/handle_environment(datum/gas_mixture/environment)
	if(!environment) return
	//Mechs and vehicles in general can be assumed to just tend to whatever ambient temperature
	if(abs(environment.temperature - bodytemperature) > 0 )
		bodytemperature += ((environment.temperature - bodytemperature) / 6)

	if(bodytemperature > material.melting_point * 1.45 ) //A bit higher because I like to assume there's a difference between a mech and a wall
		var/damage = 5
		if(bodytemperature > material.melting_point * 1.75 )
			damage = 10
		if(bodytemperature > material.melting_point * 2.15 )
			damage = 15
		apply_damage(damage, BURN)

		if(prob(damage))
			visible_message(span_danger("\The [src]'s hull bends and buckles under the intense heat!"))

//	hud_heat.Update() // Don't animate for now 'til HUDs are properly converted

/mob/living/exosuit/death(gibbed)
	// Eject the pilots
	hatch_locked = FALSE // So they can get out
	for(var/pilot in pilots)
		eject(pilot, TRUE, TRUE)

	// Salvage moves into the wreck unless we're exploding violently.
	var/obj/wreck = new wreckage_path(drop_location(), src, gibbed)
	wreck.name = "wreckage of \the [name]"
	if(!gibbed)
		if(arms)
			if(arms.loc != src)
				arms = null
		if(legs)
			if(legs.loc != src)
				legs = null
		if(head)
			if(head.loc != src)
				head = null
		if(body)
			if(body.loc != src)
				body = null

	// Handle the rest of things.
	..(gibbed, (gibbed ? "explodes!" : "grinds to a halt before collapsing!"))
	if(!gibbed)
		qdel(src)

/mob/living/exosuit/gib()
	death(1)

	// Get a turf to play with.
	var/turf/T = get_turf(src)
	if(!T)
		qdel(src)
		return

	// Hurl our component pieces about.
	var/list/stuff_to_throw = list()
	for(var/obj/item/thing in list(arms, legs, head, body))
		if(thing) stuff_to_throw += thing
	for(var/hardpoint in hardpoints)
		if(hardpoints[hardpoint])
			var/obj/item/thing = hardpoints[hardpoint]
			thing.screen_loc = null
			stuff_to_throw += thing
	for(var/obj/item/thing in stuff_to_throw)
		thing.forceMove(T)
		thing.throw_at(get_edge_target_turf(src,pick(GLOB.alldirs)),rand(3,6),40)
	explosion(get_turf(src), 200, 50)
	qdel(src)
	return

/mob/living/exosuit/handle_vision(powered)
	if(head)
		sight = head.get_sight(powered)
		see_invisible = head.get_invisible(powered)
	else if(hatch_closed)
		sight &= BLIND
	if(body && (body.pilot_coverage < 100 || body.transparent_cabin) || !hatch_closed || (body && !body.has_hatch))
		sight &= ~BLIND

/mob/living/exosuit/additional_sight_flags()
	return sight

/mob/living/exosuit/additional_see_invisible()
	return see_invisible
