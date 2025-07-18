//Fuhrer roach is a colossal, slow moving leader
/mob/living/carbon/superior_animal/roach/fuhrer
	name = "Fuhrer Roach"
	desc = "A glorious leader of cockroaches. Literally Hitler."
	icon_state = "fuhrer"

	turns_per_move = 4
	maxHealth = 150
	health = 150

	melee_damage_lower = 8
	melee_damage_upper = 16
	armor_divisor = ARMOR_PEN_MODERATE

	move_to_delay = 7
	mob_size = MOB_MEDIUM
	extra_burrow_chance = 100
	blattedin_revives_left = 0 //He only lives once, cuz he's huge

	meat_type = /obj/item/reagent_containers/food/snacks/meat/roachmeat/fuhrer
	meat_amount = 6

	sanity_damage = 1
	rarity_value = 90

	var/distress_level = 0
	var/distress_calls = 1 //Each fuhrer can only call for help once in its life
	var/retreat_calls = 1 //Can call for retreat once too

	// Armor related variables
	armor = list(
		melee = 10,
		bullet = 10,
		energy = 10,
		bomb = 0,
		bio = 25,
		rad = 50
	)

/mob/living/carbon/superior_animal/roach/fuhrer/bullet_act()
	.=..()
	distress_call()

/mob/living/carbon/superior_animal/roach/fuhrer/attackby()
	.=..()
	distress_call()

/*When its subordinates die, the leader may call for aid.
It may also call when it is personally under attack
Every nearby roach death triggers this proc, and increases the chance of a call
All the burrows in a wide area will request rapid reinforcements, causing a significant number of roaches to
flood into this room and surrounding ones.

Each leader can only call reinforcements once in its life. But it can also sound an evacuation once. If it has no
reinforcements left it will attempt to evacuate*/
/mob/living/carbon/superior_animal/roach/fuhrer/proc/distress_call()
	if (!distress_calls && !retreat_calls)
		return

	distress_level += 1

	/*
	In order to make it more likely that players will be around to witness it, lets add more distress if we can
	see a human player

	*/
	for (var/mob/living/carbon/human/H in view())
		if (H.stat != DEAD && H.client)
			distress_level += 2
			break

	if (distress_level > 0 && prob(distress_level))

		distress_level = -30 //Once a call is successfully triggered, set the chance negative
		//So it will be a while before this guy can send another call

		if (distress_calls)
			distress_calls--
			playsound(src.loc, 'sound/voice/shriek1.ogg', 100, 1, 8, 8)
			spawn(2)
				playsound(src.loc, 'sound/voice/shriek1.ogg', 100, 1, 8, 8)
				//Playing the sound twice will make it sound really horrible

			visible_message(span_danger("[src] emits a horrifying wail as nearby burrows stir to life!"))

			//Add all nearby burrows to the distressed burrows list
			//for (var/obj/structure/burrow/B in range(20, loc))
			for (var/obj/structure/burrow/B in find_nearby_burrows())
				B.distress(TRUE, src)




		//If no distress calls available, sound a retreat instead
		else if (retreat_calls)
			retreat_calls --
			playsound(src.loc, 'sound/voice/hiss6.ogg', 100, 1, 8, 8)
			spawn(2)
				playsound(src.loc, 'sound/voice/hiss6.ogg', 100, 1, 8, 8)
				//Playing the sound twice will make it sound really horrible

			visible_message(span_danger("[src] emits a haunting scream as it turns to flee, taking the nearby horde with it...."))
			for (var/obj/structure/burrow/B in find_nearby_burrows())
				B.evacuate()

/mob/living/carbon/superior_animal/roach/fuhrer/leaveOvermind()
	if(overseer?.leader == src && !QDELETED(overseer)) // this gets called once by dying and another time by the destruction of the overseer, and it doesn't need to delete the second time.
		qdel(overseer) // disband
	. = ..()



/mob/living/carbon/superior_animal/roach/fuhrer/findTarget()
	. = ..() // do we have a target?
	if(overseer && .) // are we in an overmind?
		overseer.targetEnemy(.) // direct an attack on target.

/mob/living/carbon/superior_animal/roach/fuhrer/updatehealth()
	. = ..()
	if(health < maxHealth/2)
		if(overseer)
			overseer.casualties |= src
			overseer.updateHealing()
	else if(health >= maxHealth * 0.75)
		if(overseer)
			overseer.casualties.Remove(src)


// Fuhrers won't slip over on water or soap.
/mob/living/carbon/superior_animal/roach/fuhrer/slip(slipped_on,stun_duration=8)
	return FALSE
