/mob/living/carbon/superior_animal/golem/coal
	name = "coal golem"
	desc = "A moving pile of rocks with coal clumps in it."
	icon_state = "golem_coal"
	icon_living = "golem_coal"

	// Health related variables
	maxHealth = GOLEM_HEALTH_MED
	health = GOLEM_HEALTH_MED

	// Movement related variables
	move_to_delay = GOLEM_SPEED_MED
	turns_per_move = 5

	// Damage related variables
	melee_damage_lower = GOLEM_DMG_LOW
	melee_damage_upper = GOLEM_DMG_MED

	// Armor related variables
	armor = list(
		melee = 0,
		bullet = GOLEM_ARMOR_MED,
		energy = GOLEM_ARMOR_LOW,
		bomb = 0,
		bio = 0,
		rad = 0
	)

	// Loot related variables
	mineral_name = ORE_CARBON

// enhanced coal golems will grab players, leaving them vulnerable to very high damage golems like gold and platinum
/mob/living/carbon/superior_animal/golem/coal/enhanced
	name = "graphite golem"
	desc = "A moving pile of rocks with unusually large hands and graphite chunks in it."

/mob/living/carbon/superior_animal/golem/coal/enhanced/UnarmedAttack(atom/A, proximity)
	if(istype(A, /mob/living/carbon))
		visible_message(span_danger("<b>[src]</b> grabs at [target_mob]!"))
		playsound(src, 'sound/weapons/thudswoosh.ogg', 50, 1, -1)
		simplegrab(target_mob)
	else // if they're not a carbon just attack them normally. this includes things like simple animals
		. = ..()

