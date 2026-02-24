/mob/living/simple_animal/tomato
	name = "tomato"
	desc = "A horrifyingly enormous beef tomato, and it's packing extra beef!"
	icon_state = "tomato"
	icon_living = "tomato"

	speak_chance = 0
	turns_per_move = 5
	maxHealth = 15
	health = 15
	butcher_results = list(/obj/item/reagent_containers/food/snacks/tomatomeat = BUTCHER_NORMAL, \
							/obj/item/reagent_containers/food/snacks/tomatomeat = BUTCHER_DIFFICULT,\
							/obj/item/reagent_containers/food/snacks/tomatomeat = BUTCHER_DIFFICULT)
	response_help  = "prods"
	response_disarm = "pushes aside"
	response_harm   = "smacks"
	harm_intent_damage = 5
	melee_damage_upper = 15
	melee_damage_lower = 10
	attacktext = "mauled"
