/obj/item/modular_computer/examine(mob/user, extra_description = "")
	if(damage > broken_damage)
		extra_description += span_danger("It is heavily damaged!")
	else if(damage)
		extra_description += "It is damaged."
	..(user, extra_description)

/obj/item/modular_computer/proc/break_apart()
	visible_message("\The [src] breaks apart!")
	var/turf/newloc = get_turf(src)
	new /obj/item/stack/material/steel(newloc, round(steel_sheet_cost/2))
	for(var/obj/item/computer_hardware/H in get_all_components())
		uninstall_component(H)
		H.forceMove(newloc)
		if(prob(25))
			H.take_damage(rand(10,30))
	qdel(src)

/obj/item/modular_computer/take_damage(amount, component_probability, damage_casing = 1, randomize = 1)
	if(!modifiable)
		return

	if(randomize)
		// 75%-125%, rand() works with integers, apparently.
		amount *= (rand(75, 125) / 100)
	amount = round(amount)
	if(damage_casing)
		damage += amount
		damage = between(0, damage, max_damage)

	if(component_probability)
		for(var/obj/item/computer_hardware/H in get_all_components())
			if(prob(component_probability))
				H.take_damage(round(amount / 2))

	if(damage >= max_damage)
		break_apart()

// EMPs are similar to explosions, but don't cause physical damage to the casing. Instead they screw up the components
/obj/item/modular_computer/emp_act(severity)
	take_damage(rand(100,200) / severity, 50 / severity, 0)

// "Stun" weapons can cause minor damage to components (short-circuits?)
// "Burn" damage is equally strong against internal components and exterior casing
// "Brute" damage mostly damages the casing.
/obj/item/modular_computer/bullet_act(obj/item/projectile/P)
	for(var/i in P.damage_types)
		if(i == BRUTE)
			take_damage(P.damage_types[i], P.damage_types[i] / 2)
		// TODO: enable after baymed
		/*if(PAIN)
			take_damage(Proj.damage, Proj.damage / 3, 0)*/
		if(i == BURN)
			take_damage(P.damage_types[i], P.damage_types[i] / 1.5)
