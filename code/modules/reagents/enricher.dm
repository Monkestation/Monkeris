/obj/item/reagent_containers/enricher
	name = "Molitor-Riedel Enricher"
	desc = "Produces incredibly rare cardiac stimulant if you inject it with nutrients, outputs it in bottles ready to use."
	icon = 'icons/obj/faction_item.dmi'
	icon_state = "enricher"
	item_state = "enricher"
	amount_per_transfer_from_this = 10
	possible_transfer_amounts = list(5,10,15,25,30,60,120,240)
	volume = 240
	w_class = ITEM_SIZE_HUGE
	reagent_flags = OPENCONTAINER
	price_tag = 20000
	spawn_frequency = 0
	spawn_blacklisted = TRUE
	origin_tech = list(TECH_BIO = 9, TECH_MATERIAL = 9, TECH_PLASMA = 3)
	unacidable = TRUE //glass doesn't dissolve in acid
	matter = list(MATERIAL_GLASS = 3, MATERIAL_STEEL = 2, MATERIAL_PLASMA = 5, MATERIAL_BIOMATTER = 50)
	var/resuscitator_amount = 0
	var/upgraded = FALSE // can be enriched with the maneki neko to also produce plasma and carpotoxin

/obj/item/reagent_containers/enricher/New()
	..()
	GLOB.all_faction_items[src] = GLOB.department_moebius

/obj/item/reagent_containers/enricher/Destroy()
	for(var/mob/living/carbon/human/H in viewers(get_turf(src)))
		SEND_SIGNAL_OLD(H, COMSIG_OBJ_FACTION_ITEM_DESTROY, src)
	GLOB.all_faction_items -= src
	GLOB.moebius_faction_item_loss++
	..()

/obj/item/reagent_containers/enricher/attackby(obj/item/I, mob/living/user, params)
	if(nt_sword_attack(I, user))
		return FALSE
	if(istype(I, /obj/item/maneki_neko))
		user.remove_from_mob(I)
		qdel(I)
		to_chat(user, span_notice("You upgrade the [src] using the Maneki Neko, its powers now allowing the oddity to synthethize plasma and carpotoxin ontop of resuscitator!"))
		upgraded = TRUE
	..()

/obj/item/reagent_containers/enricher/attack_self()
	if(reagents.total_volume)
		for(var/datum/reagent/reagent in reagents.reagent_list)
			var/reagent_amount = 0
			if(istype(reagent, /datum/reagent/organic/nutriment))
				var/datum/reagent/organic/nutriment/N = reagent
				reagent_amount = N.volume
				N.remove_self(reagent_amount)
				resuscitator_amount += (reagent_amount / 4)
			else
				reagent_amount = reagent.volume
				reagent.remove_self(reagent_amount) //Purge useless reagents out

		if(resuscitator_amount)
			var/obj/item/reagent_containers/glass/bottle/bottle = new /obj/item/reagent_containers/glass/bottle(get_turf(src))
			bottle.reagents.add_reagent("resuscitator", resuscitator_amount)
			bottle.name = "resuscitator bottle"
			visible_message(span_notice("[src] drops [bottle]."))
			if(upgraded)
				var/obj/item/reagent_containers/glass/bottle/plasma = new /obj/item/reagent_containers/glass/bottle(get_turf(src))
				var/obj/item/reagent_containers/glass/bottle/carpotoxin = new /obj/item/reagent_containers/glass/bottle(get_turf(src))
				plasma.reagents.add_reagent("plasma", resuscitator_amount * 2)
				carpotoxin.reagents.add_reagent("carpotoxin", resuscitator_amount * 2)
				plasma.update_icon()
				carpotoxin.update_icon()
			resuscitator_amount = 0
		else
			visible_message("\The [src] beeps, \"Not enough nutriment to produce resuscitator.\".")
	else
		visible_message("\The [src] beeps, \"Insufficient reagents to produce resuscitator.\".")

/obj/item/reagent_containers/enricher/pre_attack(atom/A, mob/user, params)
	if(user.a_intent == I_HURT)
		if(standard_splash_mob(user, A))
			return TRUE
		if(is_drainable() && reagents.total_volume)
			if(istype(A, /obj/structure/sink))
				to_chat(user, span_notice("You pour the solution into [A]."))
				reagents.remove_any(reagents.total_volume)
			else
				playsound(src,'sound/effects/Splash_Small_01_mono.ogg',50,1)
				to_chat(user, span_notice("You splash the solution onto [A]."))
				reagents.splash(A, reagents.total_volume)
			return TRUE
	return ..()

/obj/item/reagent_containers/enricher/afterattack(obj/target, mob/user, flag)
	if(!flag)
		return
	if(standard_pour_into(user, target))
		return TRUE
	if(standard_dispenser_refill(user, target))
		return TRUE
