//These machines are mostly just here for debugging/spawning. Skeletons of the feature to come.

/obj/machinery/bioprinter
	name = "organ bioprinter"
	desc = "A machine that grows replacement organs."
	icon = 'icons/obj/surgery.dmi'

	anchored = TRUE
	density = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 40

	icon_state = "bioprinter"

	var/prints_prosthetics
	var/stored_matter = 0
	var/max_matter = 300
	var/loaded_dna //Blood sample for DNA hashing.
	var/list/products = list(
		OP_HEART =   list(/obj/item/organ/internal/vital/heart,  50),
		OP_LUNGS =   list(/obj/item/organ/internal/vital/lungs,  40),
		OP_KIDNEY_LEFT = list(/obj/item/organ/internal/kidney/left, 20),
		OP_KIDNEY_RIGHT = list(/obj/item/organ/internal/kidney/right, 20),
		OP_EYES =    list(/obj/item/organ/internal/eyes,   30),
		OP_LIVER =   list(/obj/item/organ/internal/liver,  50),
		OP_STOMACH = list(/obj/item/organ/internal/stomach,  40)
		)

/obj/machinery/bioprinter/prosthetics
	name = "prosthetics fabricator"
	desc = "A machine that prints prosthetic organs."
	prints_prosthetics = TRUE

/obj/machinery/bioprinter/New()
	..()
	if(!SSticker.IsRoundInProgress())
		stored_matter = 200


/obj/machinery/bioprinter/attack_hand(mob/user)

	var/choice = input("What would you like to print?") as null|anything in products
	if(!choice)
		return

	if(stored_matter >= products[choice][2])

		stored_matter -= products[choice][2]
		var/new_organ = products[choice][1]
		var/obj/item/organ/O = new new_organ(get_turf(src))

		if(prints_prosthetics)
			O.nature = MODIFICATION_SILICON
			O.icon_state = "[O.icon_state]_robotic"
			O.name = "robotic [O.name]"
		else if(loaded_dna)
			visible_message(span_notice("The printer injects the stored DNA into the biomass."))
			O.transplant_data = list()
			var/mob/living/carbon/C = loaded_dna["donor"]
			O.transplant_data["species"] =    C.species.name
			O.transplant_data["blood_type"] = loaded_dna["blood_type"]
			O.transplant_data["blood_DNA"] =  loaded_dna["blood_DNA"]

		visible_message(span_info("The bioprinter spits out a new organ."))

	else
		to_chat(user, span_warning("There is not enough matter in the printer."))

/obj/machinery/bioprinter/attackby(obj/item/W, mob/user)

	// DNA sample from syringe.
	if(!prints_prosthetics && istype(W,/obj/item/reagent_containers/syringe))
		var/obj/item/reagent_containers/syringe/S = W
		var/datum/reagent/organic/blood/injected = locate() in S.reagents.reagent_list //Grab some blood
		if(injected && injected.data)
			loaded_dna = injected.data
			to_chat(user, span_info("You inject the blood sample into the bioprinter."))
		return
	// Meat for biomass.
	if(!prints_prosthetics)
		for(var/type in BIOMASS_TYPES)
			if(istype(W,type))
				stored_matter += BIOMASS_TYPES[type]
				user.drop_item()
				to_chat(user, span_info("\The [src] processes \the [W]. Levels of stored biomass now: [stored_matter]"))
				qdel(W)
				return
	// Steel for matter.
	if(prints_prosthetics && istype(W, /obj/item/stack/material) && W.get_material_name() == MATERIAL_STEEL)
		var/obj/item/stack/S = W
		stored_matter += S.amount * 10
		user.drop_item()
		to_chat(user, span_info("\The [src] processes \the [W]. Levels of stored matter now: [stored_matter]"))
		qdel(W)
		return

	return ..()
