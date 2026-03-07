/mob/living/simple_animal/hostile/carp/pike
	name = "space pike"
	desc = "A bigger, angrier cousin of the space carp."
	icon = 'icons/mob/spaceshark.dmi'
	icon_state = "shark"
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/carp = list(8, BUTCHER_DIFFICULT))
	move_to_delay = 2
	speed = 0
	mob_size = MOB_LARGE

	pixel_x = -16

	health = 75
	maxHealth = 75

	harm_intent_damage = 5
	melee_damage_lower = 20
	melee_damage_upper = 25

	break_stuff_probability = 100
