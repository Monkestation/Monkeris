// Asters Guild faction posters

/obj/item/poster/asters
	name = "rolled-up asters poster"
	desc = "The poster comes with its own automatic adhesive mechanism, for easy pinning to any vertical surface."
	poster_type = /obj/structure/sign/poster/asters/random
	icon_state = "rolled_poster_asters"

/obj/structure/sign/poster/asters/random
	name = "Random Asters Poster"
	random_basetype = /obj/structure/sign/poster/asters
	never_random = TRUE

/obj/structure/sign/poster/asters
	poster_item_name = "motivational poster"
	poster_item_desc = "An official Aster-issued poster to foster a compliant and obedient workforce. It comes with state-of-the-art adhesive backing, for easy pinning to any vertical surface."
	poster_item_icon_state = "rolled_legit"
	printable = TRUE

//This is being hardcoded here to ensure we don't print directionals from the library management computer because they act wierd as a poster item
/obj/structure/sign/poster/asters/random/directional
	printable = FALSE

/obj/structure/sign/poster/asters/asterite
	name = "Voyage of The Asterites"
	desc = "A flourished bit of symbolism representing the first Asterite's great exodus from Humanity's origin, now posed to to inherit the stars themselves. \
	At least, that's what the small text says."
	icon_state = "asters_asterite"
MAPPING_DIRECTIONAL_HELPERS_LIBRARY(/obj/structure/sign/poster/asters/asterite, 32)

/obj/structure/sign/poster/asters/blurb
	name = "The Asterite's Message"
	desc = "A poster labeling the good will and intentions of The Aster's Guild under Hanseatic principles of free will and enterprise."
	icon_state = "asters_blurb"
MAPPING_DIRECTIONAL_HELPERS_LIBRARY(/obj/structure/sign/poster/asters/blurb, 32)

/obj/structure/sign/poster/asters/social_pyramid
	name = "The Modern Atlas"
	desc = "At the pyramid's bottom comes the great employer, who holds up society upon his back. To the top, the worker who reaps its benefits."
	icon_state = "asters_social_pyramid"
MAPPING_DIRECTIONAL_HELPERS_LIBRARY(/obj/structure/sign/poster/asters/social_pyramid, 32)

/obj/structure/sign/poster/asters/cev_eris
	name = "CEV Eris"
	desc = "A poster celebrating the maiden voyage of the Cosmic Exploration Vessel \"Eris\"."
	icon_state = "asters_cev_eris"
MAPPING_DIRECTIONAL_HELPERS_LIBRARY(/obj/structure/sign/poster/asters/cev_eris, 32)

/obj/structure/sign/poster/asters/rock_and_stone
	name = "Rock & Stone"
	desc = "\"Rock and stone!\""
	icon_state = "asters_rock_and_stone"
MAPPING_DIRECTIONAL_HELPERS_LIBRARY(/obj/structure/sign/poster/asters/rock_and_stone, 32)

/obj/structure/sign/poster/asters/workplace_gaming
	name = "Workplace Gaming"
	desc = "This poster wishes to remind you that in the event this reality is a virtual simulation, you will be scored on workplace output, not your paycheck. \
	\"So lets go and highscore!\""
	icon_state = "asters_workplace_gaming"
MAPPING_DIRECTIONAL_HELPERS_LIBRARY(/obj/structure/sign/poster/asters/workplace_gaming, 32)


/obj/structure/sign/poster/asters/mine_ore_1
	name = "Mine Ore"
	desc = "This poster wishes to remind you that an astral miner's work is what allows industry to function, and if you're among them to take pride within your work - \
	\"but not too much!\""
	icon_state = "asters_mine_ore_1"
MAPPING_DIRECTIONAL_HELPERS_LIBRARY(/obj/structure/sign/poster/asters/mine_ore_1, 32)


/obj/structure/sign/poster/asters/mine_ore_2
	name = "Mine More Ore"
	desc = "\"Remember miners, do not die!\""
	icon_state = "asters_mine_ore_2"
MAPPING_DIRECTIONAL_HELPERS_LIBRARY(/obj/structure/sign/poster/asters/mine_ore_2, 32)

/obj/structure/sign/poster/asters/move_freight_1
	name = "Move Freight"
	desc = "This poster explains the important aspect within Humanity's logistical supply chain the humble technician's role is."
	icon_state = "asters_move_freight_1"
MAPPING_DIRECTIONAL_HELPERS_LIBRARY(/obj/structure/sign/poster/asters/move_freight_1, 32)

/obj/structure/sign/poster/asters/move_freight_2
	name = "Move More Freight"
	desc = "\"Move freight!\""
	icon_state = "asters_move_freight_2"
MAPPING_DIRECTIONAL_HELPERS_LIBRARY(/obj/structure/sign/poster/asters/move_freight_2, 32)

/obj/structure/sign/poster/asters/cargonia
	name = "Cargo Takes Flight"
	desc = "An inspirational poster of a cargo technician looking stoic as stylized rocket plume streaks sharply in the background, taking goods off to destination unknown."
	icon_state = "asters_cargonia"
MAPPING_DIRECTIONAL_HELPERS_LIBRARY(/obj/structure/sign/poster/asters/cargonia, 32)
