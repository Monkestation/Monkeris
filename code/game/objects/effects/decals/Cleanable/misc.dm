/obj/effect/decal/cleanable/generic
	name = "clutter"
	desc = "Someone should clean that up."
	gender = PLURAL
	density = FALSE
	anchored = TRUE
	icon = 'icons/obj/objects.dmi'
	icon_state = "shards"

/obj/effect/decal/cleanable/ash
	name = "ashes"
	desc = "Ashes to ashes, dust to dust, and into space."
	gender = PLURAL
	icon = 'icons/obj/objects.dmi'
	icon_state = "ash"
	anchored = TRUE

/obj/effect/decal/cleanable/ash/attack_hand(mob/user as mob)
	to_chat(user, span_notice("[src] sifts through your fingers."))
	qdel(src)


/obj/effect/decal/cleanable/dirt
	name = "dirt"
	desc = "Someone should clean that up."
	gender = PLURAL
	density = FALSE
	anchored = TRUE
	icon = 'icons/effects/effects.dmi'
	icon_state = "dirt"
	mouse_opacity = 0

/obj/effect/decal/cleanable/reagents
	desc = "Someone should clean that up."
	gender = PLURAL
	density = FALSE
	anchored = TRUE
	icon = 'icons/obj/reagentfillings.dmi'
	mouse_opacity = 0
	random_rotation = FALSE
	bad_type = /obj/effect/decal/cleanable/reagents
	spawn_tags = null

/obj/effect/decal/cleanable/reagents/proc/add_reagents(datum/reagents/reagents_to_add)
	if(!reagents)
		create_reagents(reagents_to_add.total_volume)

	reagents_to_add.trans_to_holder(reagents, reagents_to_add.total_volume)

/obj/effect/decal/cleanable/reagents/New(datum/reagents/reagents_to_add = null)
	. = ..()
	if(reagents_to_add && reagents_to_add.total_volume)
		reagents = reagents_to_add
		color = reagents.get_color()

/obj/effect/decal/cleanable/reagents/splashed
	name = "splashed liquid"
	icon_state = "splashed"

/obj/effect/decal/cleanable/reagents/splashed/New(datum/reagents/reagents_to_add = null)
	. = ..()
	if(reagents)
		alpha = min(reagents.total_volume * 30, 255)
		START_PROCESSING(SSobj, src)

/obj/effect/decal/cleanable/reagents/splashed/add_reagents(datum/reagents/reagents_to_add)
	alpha = min(alpha + reagents_to_add.total_volume * 30, 255)
	color = BlendRGB(color, reagents_to_add.get_color(), 0.6)
	..()

/obj/effect/decal/cleanable/reagents/splashed/Process()
	if(!reagents.total_volume)
		STOP_PROCESSING(SSobj, src)
		return
	reagents.remove_any(0.05)

/obj/effect/decal/cleanable/reagents/piled
	name = "powder pile"
	icon_state = "powderpile"

/obj/effect/decal/cleanable/reagents/piled/add_reagents(datum/reagents/reagents_to_add)
	color = BlendRGB(color, reagents_to_add.get_color(), 0.8)
	..()

/obj/effect/decal/cleanable/flour
	name = "flour"
	desc = "It's still good. Four second rule!"
	gender = PLURAL
	density = FALSE
	anchored = TRUE
	icon = 'icons/effects/effects.dmi'
	icon_state = "flour"

/obj/effect/decal/cleanable/greenglow
	name = "glowing goo"
	desc = "Jeez. I hope that's not for lunch."
	gender = PLURAL
	density = FALSE
	anchored = TRUE
	light_range = 2
	icon = 'icons/effects/effects.dmi'
	icon_state = "greenglow"
	spawn_frequency = 0

/obj/effect/decal/cleanable/greenglow/Initialize(mapload, ...)
	. = ..()
	START_PROCESSING(SSobj, src)
	set_light(1.5 ,1, "#00FF7F")
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(qdel), src), 120 SECONDS)

/obj/effect/decal/cleanable/greenglow/Process()
	. = ..()
	for(var/mob/living/carbon/l in range(4))
		if(prob(2))
			to_chat(l, span_warning("Your skin itches."))
		l.apply_effect(2, IRRADIATE)

/obj/effect/decal/cleanable/greenglow/Destroy()
	STOP_PROCESSING(SSobj, src)
	. = ..()

/obj/effect/decal/cleanable/cobweb
	name = "cobweb"
	desc = "Somebody should remove that."
	density = FALSE
	anchored = TRUE
	layer = WALL_OBJ_LAYER
	icon = 'icons/effects/effects.dmi'
	icon_state = "cobweb1"

/obj/effect/decal/cleanable/molten_item
	name = "gooey grey mass"
	desc = "It looks like a melted... something."
	density = FALSE
	anchored = TRUE
	layer = OBJ_LAYER
	icon = 'icons/obj/chemical.dmi'
	icon_state = "molten"

/obj/effect/decal/cleanable/cobweb2
	name = "cobweb"
	desc = "Somebody should remove that."
	density = FALSE
	anchored = TRUE
	layer = ABOVE_OBJ_LAYER
	icon = 'icons/effects/effects.dmi'
	icon_state = "cobweb2"

//Vomit (sorry)
/obj/effect/decal/cleanable/vomit
	name = "vomit"
	desc = "Gosh, how unpleasant."
	gender = PLURAL
	density = FALSE
	anchored = TRUE
	icon = 'icons/effects/blood.dmi'
	icon_state = "vomit_1"
	random_icon_states = list("vomit_1", "vomit_2", "vomit_3", "vomit_4")
	sanity_damage = 1
	var/list/viruses = list()

	Destroy()
		. = ..()

/obj/effect/decal/cleanable/tomato_smudge
	name = "tomato smudge"
	desc = "It's red."
	density = FALSE
	anchored = TRUE
	icon = 'icons/effects/tomatodecal.dmi'
	random_icon_states = list("tomato_floor1", "tomato_floor2", "tomato_floor3")

/obj/effect/decal/cleanable/egg_smudge
	name = "smashed egg"
	desc = "Seems like this one won't hatch."
	density = FALSE
	anchored = TRUE
	icon = 'icons/effects/tomatodecal.dmi'
	random_icon_states = list("smashed_egg1", "smashed_egg2", "smashed_egg3")

/obj/effect/decal/cleanable/pie_smudge //honk
	name = "smashed pie"
	desc = "It's pie cream from a cream pie."
	density = FALSE
	anchored = TRUE
	icon = 'icons/effects/tomatodecal.dmi'
	random_icon_states = list("smashed_pie")

/obj/effect/decal/cleanable/fruit_smudge
	name = "smudge"
	desc = "Some kind of fruit smear."
	density = FALSE
	anchored = TRUE
	icon = 'icons/effects/blood.dmi'
	icon_state = "mfloor1"
	random_icon_states = list("mfloor1", "mfloor2", "mfloor3", "mfloor4", "mfloor5", "mfloor6", "mfloor7")



/obj/effect/decal/cleanable/rubble
	name = "rubble"
	desc = "Dirt, soil, loose stones, and residue from some kind of digging. Clean it up!"
	density = FALSE
	anchored = TRUE
	icon = 'icons/obj/burrows.dmi'
	icon_state = "asteroid0"
	random_rotation = 2
	random_icon_states = list("asteroid0", "asteroid1", "asteroid2", "asteroid3", "asteroid4", "asteroid5", "asteroid6","asteroid7","asteroid8")

/obj/effect/decal/cleanable/graffiti
	name = "graffiti"
	desc = "A graffiti."
	density = FALSE
	anchored = TRUE
	plane = -1
	icon = 'icons/effects/wall_graffiti.dmi'
	icon_state = "kot"
	random_rotation = 0

/obj/effect/decal/cleanable/graffiti/graffiti_kot
	desc = "A graffiti of a very happy cat."
	icon_state = "kot"

/obj/effect/decal/cleanable/graffiti/graffiti_onestar
	desc = "A graffiti of one star's eye."
	icon_state = "onestar"

/obj/effect/decal/cleanable/graffiti/graffiti_carrion
	desc = "Consume the flesh."
	icon_state = "carrion"

/obj/effect/decal/cleanable/graffiti/graffiti_doodle
	desc = "A vagabond beaten by IH, this is mercenary brutality."
	icon_state = "doodle"

/obj/effect/decal/cleanable/graffiti/graffiti_piss
	desc = "A graffiti of, well."
	icon_state = "piss"

/obj/effect/decal/cleanable/graffiti/graffiti_clown
	desc = "A graffiti of a clown."
	icon_state = "clown"

/obj/effect/decal/cleanable/graffiti/graffiti_skull
	desc = "A graffiti of a skull."
	icon_state = "skull"


/obj/effect/decal/cleanable/graffiti/graffiti_heart
	desc = "A graffiti of a heart."
	icon_state = "heart"

/obj/effect/decal/cleanable/graffiti/graffiti_excelsior
	desc = "Ever Upwards!"
	icon_state = "excelsior"

/obj/effect/decal/cleanable/graffiti/graffiti_ironhammer
	desc = "The best of the best."
	icon_state = "ironhammer"

/obj/effect/decal/cleanable/graffiti/graffiti_moebius
	desc = "Science never stops."
	icon_state = "moebius"

/obj/effect/decal/cleanable/graffiti/graffiti_neotheo
	desc = "Mutants not welcomed."
	icon_state = "neotheo"

/obj/effect/decal/cleanable/graffiti/graffiti_techno
	desc = "Kickstart the Engine."
	icon_state = "techno"

/obj/effect/decal/cleanable/graffiti/graffiti_aster
	desc = "Blood is the oldest currency."
	icon_state = "aster"

/obj/effect/decal/cleanable/graffiti/graffiti_ancapyes
	desc = "The great Capital approves."
	icon_state = "ancapyes"

/obj/effect/decal/cleanable/graffiti/graffiti_ancapno
	desc = "The free market isn't happy."
	icon_state = "ancapno"
