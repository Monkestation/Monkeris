//Spawns credits, has many subtypes
/obj/spawner/credits
	name = "random cash"
	icon_state = "cash-green"
	low_price = 100
	top_price = 1000
	bad_type = /obj/spawner/credits
	spawn_tags = SPAWN_TAG_MONEY

/obj/spawner/credits/item_to_spawn()
	return /obj/item/spacecash/bundle

/obj/spawner/credits/post_spawn(list/spawns)
	for(var/obj/item/spacecash/bundle/C in spawns)
		C.worth = rand(low_price, top_price) //Rand conveniently produces integers
		C.update_icon()

/obj/spawner/credits/low_chance
	name = "low chance random cash"
	icon_state = "cash-green-low"
	spawn_nothing_percentage = 75

/obj/spawner/credits/sparechange
	low_price = 1
	top_price = 10
	rarity_value = 1//pennies everywhere
	spawn_frequency = 15

/obj/spawner/credits/c50
	low_price = 1
	top_price = 50
	icon_state = "cash-black"
	rarity_value = 4
	spawn_frequency = 10

/obj/spawner/credits/c100
	low_price = 5
	top_price = 100
	icon_state = "cash-grey"
	rarity_value = 6
	spawn_frequency = 8

/obj/spawner/credits/c500
	low_price = 100
	top_price = 500
	icon_state = "cash-blue"
	rarity_value = 8
	spawn_frequency = 4

/obj/spawner/credits/c1000
	low_price = 500
	top_price = 1000
	icon_state = "cash-green"
	rarity_value = 10
	spawn_frequency = 2
	spawn_blacklisted = TRUE

/obj/spawner/credits/c5000
	low_price = 1000
	top_price = 5000
	icon_state = "cash-orange"
	spawn_blacklisted = TRUE

/obj/spawner/credits/c10000
	low_price = 5000
	top_price = 10000
	icon_state = "cash-red"
	spawn_blacklisted = TRUE

/obj/spawner/pack/randcredits
	name = "random weighted cash"
	icon_state = "cash-green"
	tags_to_spawn = list(SPAWN_MONEY)


/obj/spawner/pack/randcredits/low_chance
	name = "random weighted cash(low chance)"
	icon_state = "cash-green-low"
	spawn_nothing_percentage = 75

/obj/spawner/pack/randcredits/many
	name = "many random weighted cash"
	icon_state = "cash-blue"
	max_amount = 3

/obj/spawner/pack/randcredits/many/low_chance
	icon_state = "cash-blue-low"
	spawn_nothing_percentage = 75
