//CORTICAL BORER ORGANS.

/obj/item/organ/internal/borer
	name = "cortical borer"
	icon = 'icons/obj/objects.dmi'
	icon_state = "borer"
	organ_tag = BP_BRAIN
	desc = "A disgusting space slug."
	parent_organ_base = BP_HEAD
	vital = 1

/obj/item/organ/internal/borer/Process()
	// Borer husks regenerate health, feel no pain, and are resistant to stuns and brainloss.
	for(var/chem in list("tricordrazine","tramadol","hyperzine","alkysine"))
		if(owner.reagents.get_reagent_amount(chem) < 3)
			owner.reagents.add_reagent(chem, 5)

	// They're also super gross and ooze ichor.
	if(prob(5))
		var/mob/living/carbon/human/H = owner
		if(!istype(H))
			return

		var/datum/reagent/organic/blood/B = locate(/datum/reagent/organic/blood) in H.vessel.reagent_list
		blood_splatter(H,B,1)
		var/obj/effect/decal/cleanable/blood/splatter/goo = locate() in get_turf(owner)
		if(goo)
			goo.name = "husk ichor"
			goo.desc = "It's thick and stinks of decay."
			goo.basecolor = "#412464"
			goo.update_icon()

/obj/item/organ/internal/borer/removed_mob(mob/living/user)
	var/mob/living/simple_animal/borer/B = owner.get_brain_worms()
	if(B)
		B.leave_host()
		B.ckey = owner.ckey

	..()

	QDEL_IN(src, 0)
