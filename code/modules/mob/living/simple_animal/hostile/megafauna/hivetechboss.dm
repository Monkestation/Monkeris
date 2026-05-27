/mob/living/simple_animal/hostile/megafauna/hivemind_tyrant
	name = "Hivemind Tyrant"
	desc = "Hivemind's will, manifested in flesh and metal."

	faction = "hive"
	mob_size = MOB_GIGANTIC
	icon = 'icons/mob/64x64.dmi'
	icon_state = "hivemind_tyrant"
	icon_living = "hivemind_tyrant"
	icon_dead = "hivemind_tyrant"
	pixel_x = -16
	ranged = TRUE
	health = 1850
	maxHealth = 1850 //Only way for it to show up right now is via adminbus OR Champion call (which gives it 150hp). For comparison Kaiser has 2000hp
	break_stuff_probability = 95
	melee_damage_lower = 30
	melee_damage_upper = 35 //similar damage to the mechiver

	mob_classification = CLASSIFICATION_SYNTHETIC

	#warn projectile
	// projectiletype = /obj/item/projectile/goo

	stunned = FALSE

/////////////////////////////////////////////////////////////////////////////////

/mob/living/simple_animal/hostile/megafauna/hivemind_tyrant/death()
	..()
	if(GLOB.hive_data_bool["tyrant_death_kills_hive"])
		delhivetech()

/mob/living/simple_animal/hostile/megafauna/hivemind_tyrant/proc/delhivetech()
	var/othertyrant = 0
	for(var/mob/living/simple_animal/hostile/megafauna/hivemind_tyrant/tyrant_anywhereElse in world)
		if(tyrant_anywhereElse != src)
			othertyrant = 1
	if(othertyrant == 0)
		for(var/obj/machinery/hivemind_machine/NODE in world)
			NODE.destruct()

/////////////////////////////////////////////////////////////////////////////////

/mob/living/simple_animal/hostile/megafauna/hivemind_tyrant/Life()
	. = ..()
	if(!stunned)
		if(!.)
			walk(src, 0)
			return 0
		if(client)
			return 0
	enrage()
/mob/living/simple_animal/hostile/megafauna/hivemind_tyrant/proc/stun_the_tyrant()
	if(!stunned)
		stunned = TRUE
		stunned_in_seconds

/mob/living/simple_animal/hostile/megafauna/hivemind_tyrant/proc/enrage()


/mob/living/simple_animal/hostile/megafauna/hivemind_tyrant/AttackingTarget()
	swing_attack(target_mob)

/mob/living/simple_animal/hostile/megafauna/hivemind_tyrant/OpenFire()
/*procs used here:
* walk(src, 0)
* telegraph()
* random_shots()
* MoveToTarget()
*
*/
//	anger_modifier = CLAMP(((maxHealth - health)/50),0,20)
	ranged_cooldown = world.time + 120
	walk(src, 0)
	spawn(rand(megafauna_min_cooldown, megafauna_max_cooldown))
		if(prob(50))
			random_shots()
			move_to_delay = initial(move_to_delay)
			MoveToTarget()
			return
		else
			select_spiral_attack()
			move_to_delay = initial(move_to_delay)
			MoveToTarget()
			return
