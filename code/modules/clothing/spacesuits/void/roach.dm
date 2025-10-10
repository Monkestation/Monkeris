//kaiser voidsuit
/obj/item/clothing/head/space/void/kaiser
	name = "kaiser voidsuit helmet"
	desc = "An indestructible helmet made from the corpse of a kaiser."
	icon_state = "kaiser_void"
	item_state = "kaiser_void"
	max_heat_protection_temperature = FIRESUIT_MAX_HEAT_PROTECTION_TEMPERATURE
	armor = list(
		melee = 13,
		bullet = 13,
		energy = 13,
		bomb = 75,
		bio = 100,
		rad = 75
	)
	siemens_coefficient = 0.35
	species_restricted = list(SPECIES_HUMAN)


/obj/item/clothing/suit/space/void/kaiser
	name = "kaiser voidsuit"
	desc = "An indestructible suit made from the corpse of a kaiser. Surprisingly flexible."
	item_state = "kaiser_void"
	icon_state = "kaiser_void"
	max_heat_protection_temperature = FIRESUIT_MAX_HEAT_PROTECTION_TEMPERATURE
	armor = list(
		melee = 13,
		bullet = 13,
		energy = 13,
		bomb = 75,
		bio = 100,
		rad = 75
	)
	siemens_coefficient = 0
	breach_threshold = 8
	resilience = 0.07
	species_restricted = list(SPECIES_HUMAN)
	helmet = /obj/item/clothing/head/space/void/kaiser
	spawn_blacklisted = TRUE
	slowdown = MEDIUM_SLOWDOWN * 1.5
