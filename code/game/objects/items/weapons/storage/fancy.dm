/*
 * The 'fancy' path is for objects like donut boxes that show how many items are in the storage item on the sprite itself
 * .. Sorry for the shitty path name, I couldnt think of a better one.
 *
 * WARNING: var/icon_type is used for both examine text and sprite name. Please look at the procs below and adjust your sprite names accordingly
 *		TODO: Cigarette boxes should be ported to this standard
 *
 * Contains:
 *		Donut Box
 *		Egg Box
 *		Candle Box
 *		Crayon Box
 *		Cigarette Box
 *		MRE containers
 */

/obj/item/storage/fancy
	icon = 'icons/obj/food.dmi'
	icon_state = "donutbox6"
	name = "donut box"
	max_storage_space = 8
	bad_type = /obj/item/storage/fancy
	var/icon_type = "donut"
	var/item_obj				// It can take a path or a list, the populate_contents() must be added when using item_obj in order to work.

/obj/item/storage/fancy/update_icon(itemremoved = 0)
	var/total_contents = LAZYLEN(contents) - itemremoved
	icon_state = "[icon_type]box[total_contents]"

/obj/item/storage/fancy/examine(mob/user, extra_description = "")
	if(get_dist(user, src) < 2)
		var/content_count = LAZYLEN(contents)
		if(!content_count)
			extra_description += "There is no [icon_type]s left in the box."
		else if(content_count == 1)
			extra_description += "There is one [icon_type] left in the box."
		else
			extra_description += "There are [content_count] [icon_type]\s in the box."
	..(user, extra_description)

/*
 * Egg Box
 */

/obj/item/storage/fancy/egg_box
	icon = 'icons/obj/food.dmi'
	icon_state = "eggbox"
	icon_type = "egg"
	name = "egg box"
	storage_slots = 12
	item_obj = /obj/item/reagent_containers/food/snacks/egg
	can_hold = list(
		/obj/item/reagent_containers/food/snacks/egg,
		/obj/item/reagent_containers/food/snacks/boiledegg
		)

/obj/item/storage/fancy/egg_box/populate_contents()
	for(var/i in 1 to storage_slots)
		new item_obj(src)

//MRE food
/obj/item/storage/fancy/mre_cracker
	icon_state = "crackersbox"
	name = "enriched crackers pack"
	storage_slots = 5
	icon_type = "crackers"
	item_obj = /obj/item/reagent_containers/food/snacks/mre_cracker
	can_hold = list(
		/obj/item/reagent_containers/food/snacks/mre_cracker
		)

/obj/item/storage/fancy/mre_cracker/populate_contents()
	for(var/i in 1 to storage_slots)
		new item_obj(src)

/*
 * Candle Box
 */

/obj/item/storage/fancy/candle_box
	name = "candle pack"
	desc = "A pack of wax candles."
	icon = 'icons/obj/candle.dmi'
	icon_state = "candlebox5"
	icon_type = "candle"
	item_state = "candlebox5"
	throwforce = WEAPON_FORCE_HARMLESS
	slot_flags = SLOT_BELT
	storage_slots = 5
	item_obj = /obj/item/flame/candle


/obj/item/storage/fancy/candle_box/populate_contents()
	for(var/i in 1 to storage_slots)
		new item_obj(src)

/*
 * Crayon Box
 */

/obj/item/storage/fancy/crayons
	name = "box of crayons"
	desc = "A box of crayons for all your rune drawing needs."
	icon = 'icons/obj/crayons.dmi'
	icon_state = "crayonbox"
	w_class = ITEM_SIZE_SMALL
	icon_type = "crayon"
	can_hold = list(
		/obj/item/pen/crayon
	)

/obj/item/storage/fancy/crayons/populate_contents()
	new /obj/item/pen/crayon/red(src)
	new /obj/item/pen/crayon/orange(src)
	new /obj/item/pen/crayon/yellow(src)
	new /obj/item/pen/crayon/green(src)
	new /obj/item/pen/crayon/blue(src)
	new /obj/item/pen/crayon/purple(src)
	update_icon()

/obj/item/storage/fancy/crayons/update_icon()
	cut_overlays()
	overlays += image('icons/obj/crayons.dmi',"crayonbox")
	for(var/obj/item/pen/crayon/crayon in contents)
		overlays += image('icons/obj/crayons.dmi',crayon.colourName)

/obj/item/storage/fancy/crayons/attackby(obj/item/W as obj, mob/user as mob)
	if(istype(W,/obj/item/pen/crayon))
		switch(W:colourName)
			if("mime")
				to_chat(usr, "This crayon is too sad to be contained in this box.")
				return
			if("rainbow")
				to_chat(usr, "This crayon is too powerful to be contained in this box.")
				return
	..()

////////////
//CIG PACK//
////////////
/obj/item/storage/fancy/cigarettes
	name = "cigarette packet"
	desc = "The most popular brand of Space Cigarettes, sponsors of the Space Olympics."
	icon = 'icons/obj/cigarettes.dmi'
	icon_state = "cigpacket"
	item_state = "cigpacket"
	w_class = ITEM_SIZE_TINY
	throwforce = WEAPON_FORCE_HARMLESS
	slot_flags = SLOT_BELT
	spawn_tags = SPAWN_CIGARETTE
	storage_slots = 6
	item_obj = /obj/item/clothing/mask/smokable/cigarette
	can_hold = list(/obj/item/clothing/mask/smokable/cigarette, /obj/item/flame/lighter)
	icon_type = "cigarette"
	reagent_flags = REFILLABLE | NO_REACT
	var/open = FALSE

/obj/item/storage/fancy/cigarettes/attack_self(mob/user)
	if(open)
		close_all()
	else
		..()
	update_icon()

/obj/item/storage/fancy/cigarettes/open(mob/user)
	. = ..()
	open = TRUE

/obj/item/storage/fancy/cigarettes/close_all()
	. = ..()
	if(contents.len)
		open = FALSE

/obj/item/storage/fancy/cigarettes/show_to(mob/user)
	. = ..()
	update_icon()

/obj/item/storage/fancy/cigarettes/populate_contents()
	for(var/i in 1 to storage_slots)
		new item_obj(src)
	create_reagents(15 * storage_slots)//so people can inject cigarettes without opening a packet, now with being able to inject the whole one

/obj/item/storage/fancy/cigarettes/update_icon()
	if(open)
		icon_state = "[initial(icon_state)][contents.len]"
	else
		icon_state = "[initial(icon_state)]"

/obj/item/storage/fancy/cigarettes/can_be_inserted(obj/item/W, stop_messages = 0)
	if(!open)
		to_chat(usr, span_warning("Open [src] first!"))
		return FALSE
	return ..()

/obj/item/storage/fancy/cigarettes/remove_from_storage(obj/item/W as obj, atom/new_location)
	// Don't try to transfer reagents to lighters
	if(istype(W, /obj/item/clothing/mask/smokable/cigarette))
		var/obj/item/clothing/mask/smokable/cigarette/C = W
		reagents.trans_to_obj(C, (reagents.total_volume/contents.len))
	..()

/obj/item/storage/fancy/cigarettes/attack(mob/living/carbon/M as mob, mob/living/carbon/user as mob)
	if(!ismob(M))
		return

	if(M == user && user.targeted_organ == BP_MOUTH)
		// Find ourselves a cig. Note that we could be full of lighters.
		var/obj/item/clothing/mask/smokable/cigarette/cig = locate() in src

		if(!cig)
			to_chat(user, span_notice("Looks like the packet is out of cigarettes."))
			return

		user.equip_to_slot_if_possible(cig, slot_wear_mask)
	else
		..()

/obj/item/storage/fancy/cigarettes/dromedaryco
	name = "\improper DromedaryCo packet"
	desc = "A packet of six imported DromedaryCo cancer sticks. A label on the packaging reads, \"Wouldn't a slow death make a change?\""
	icon_state = "dromedary_packet"
	item_state = "dromedary_packet"
	item_obj = /obj/item/clothing/mask/smokable/cigarette/dromedaryco

/obj/item/storage/fancy/cigarettes/killthroat
	name = "\improper AcmeCo packet"
	desc = "A packet of six AcmeCo cigarettes. For those who somehow want to obtain the record for the most amount of cancerous tumors."
	icon_state = "acme_packet"
	item_state = "acme_packet" //Doesn't have an inhand state, but neither does dromedary, so, ya know..
	item_obj = /obj/item/clothing/mask/smokable/cigarette/killthroat

/obj/item/storage/fancy/cigarettes/homeless
	name = "\improper Nomads packet"
	desc = "A packet of six Nomads cigarettes. Nomads's Extra strong for when your life is more extra hard"
	icon_state = "nomad_packet"
	item_state = "nomad_packet"
	spawn_tags = SPAWN_TAG_CIGARETTE_MAINTS
	item_obj = /obj/item/clothing/mask/smokable/cigarette/homeless

/obj/item/storage/fancy/cigarettes/lucky
	name = "\improper Lucky Strikes packet"
	desc = "A packet of six Lucky Strikes cigarettes. For some reason the Syndicate loved these things back in the war, still around as surplus today."
	icon_state = "luck_packet"
	item_state = "luck_packet"
	item_obj = /obj/item/clothing/mask/smokable/cigarette/lucky

/obj/item/storage/fancy/cigarettes/robusto
	name = "\improper Red Robusto packet"
	desc = "A packet of six Red Robusto Cigarettes. Old Nanotrasen cigs, some say they make you more robust..."
	icon_state = "robusto_packet"
	item_state = "robusto_packet"
	spawn_tags = SPAWN_TAG_CIGARETTE_MAINTS
	item_obj = /obj/item/clothing/mask/smokable/cigarette/robusto

/obj/item/storage/fancy/cigarettes/buckshot
	name = "\improper Klassika Filter packet"
	desc = "A packet of six Klassika Filter Cigarettes. Old unknown brand, says 'Klassika Filter' on the front..."
	icon_state = "klassika_packet"
	item_state = "klassika_packet"
	spawn_tags = SPAWN_TAG_CIGARETTE_MAINTS
	item_obj = /obj/item/clothing/mask/smokable/cigarette/buckshot

/obj/item/storage/fancy/cigarettes/quasimorph
	name = "\improper Kosmos packet"
	desc = "A packet of six Kosmos Cigarettes. Old Russian brand, says 'Космос' on the front, along with a white rocket."
	icon_state = "kosmos_packet"
	item_state = "kosmos_packet"
	spawn_tags = SPAWN_TAG_CIGARETTE_MAINTS
	item_obj = /obj/item/clothing/mask/smokable/cigarette/quasimorph

/obj/item/storage/fancy/cigcartons
	name = "carton of cigarettes"
	desc = "A box containing 10 packets of cigarettes."
	icon_state = "cigpacketcarton"
	item_state = "cigpacketcarton"
	icon = 'icons/obj/cigarettes.dmi'
	w_class = ITEM_SIZE_NORMAL
	throwforce = WEAPON_FORCE_HARMLESS
	storage_slots = 10
	item_obj = /obj/item/storage/fancy/cigarettes
	can_hold = list(/obj/item/storage/fancy/cigarettes)
	icon_type = "packet"
	reagent_flags = REFILLABLE | NO_REACT

/obj/item/storage/fancy/cigcartons/update_icon()
	if(contents.len > 0)
		icon_state = "[initial(icon_state)]1"
	else
		icon_state = "[initial(icon_state)]"

/obj/item/storage/fancy/cigcartons/populate_contents()
	for(var/i in 1 to storage_slots)
		new item_obj(src)
	update_icon()

/obj/item/storage/fancy/cigcartons/dromedaryco
	name = "carton of DromedaryCo cigarettes"
	desc = "A box containing 10 packets of DromedaryCo cigarettes."
	icon_state = "Dpacketcarton"
	item_state = "Dpacketcarton"
	item_obj = /obj/item/storage/fancy/cigarettes/dromedaryco

/obj/item/storage/fancy/cigcartons/killthroat
	name = "carton of AcmeCo cigarettes"
	desc = "A box containing 10 packets of AcmeCo cigarettes."
	icon_state = "Bpacketcarton"
	item_state = "Bpacketcarton"
	item_obj = /obj/item/storage/fancy/cigarettes/killthroat

/obj/item/storage/fancy/cigcartons/homeless
	name = "carton of Nomad cigarettes"
	desc = "A box containing 10 packets of Nomad cigarettes."
	icon_state = "Cpacketcarton"
	item_state = "Cpacketcarton"
	item_obj = /obj/item/storage/fancy/cigarettes/homeless

/obj/item/storage/fancy/cigar
	name = "cigar case"
	desc = "A case for holding your cigars when you are not smoking them. Fancy!"
	icon_state = "cigarcase"
	item_state = "cigarcase"
	icon = 'icons/obj/cigarettes.dmi'
	w_class = ITEM_SIZE_TINY
	throwforce = WEAPON_FORCE_HARMLESS
	slot_flags = SLOT_BELT
	storage_slots = 6
	can_hold = list(/obj/item/clothing/mask/smokable/cigarette/cigar)
	icon_type = "cigar"
	reagent_flags = REFILLABLE | NO_REACT
	item_obj = /obj/item/clothing/mask/smokable/cigarette/cigar
	var/open = FALSE

/obj/item/storage/fancy/cigar/can_interact(mob/user)
	if((!ishuman(user) && (loc != user)) || user.stat || user.restrained())
		return 1
	if(istype(loc, /obj/item/storage))
		return 2
	return 0


/obj/item/storage/fancy/cigar/verb/quick_open_close(mob/user)
	set name = "Close cigar case"
	set category = "Object"
	set src in view(1)
	if(!is_worn())
		if(can_interact(user) == 1)	//can't use right click verbs inside bags so only need to check for ablity
			return

		open_close(user)
	else
		to_chat(user, span_notice("You cannot open \the [src] while it\'s equipped!"))

/obj/item/storage/fancy/cigar/AltClick(mob/user)
	if(!is_worn())
		var/able = can_interact(user)

		if(able == 1)
			return

		if(able == 2)
			to_chat(user, span_notice("You cannot open \the [src] while it\'s in a container."))
			return

		open_close(user)
	else
		to_chat(user, span_notice("You cannot open \the [src] while it\'s equipped!"))

/obj/item/storage/fancy/cigar/proc/open_close(mob/living/carbon/human/H, user)
	close_all()
	if(!is_worn())
		if(!open)
			to_chat(user, span_notice("You open \the [src]."))
			w_class = ITEM_SIZE_SMALL
			open = TRUE
		else
			to_chat(user, span_notice("You close \the [src]."))
			w_class = ITEM_SIZE_TINY
			open = FALSE
		playsound(loc, 'sound/machines/click.ogg', 100, 1)
		update_icon()
	else
		to_chat(user, span_notice("You cannot open \the [src] while it\'s equipped!"))

/obj/item/storage/fancy/cigar/attackby(obj/item/W, mob/user)
	if(!open)
		to_chat(user, span_notice("You try to access \the [src] but it\'s closed!"))
		return
	. = ..()

/obj/item/storage/fancy/cigar/open(mob/user)
	if(!open)
		to_chat(user, span_notice("\The [src] is closed."))
		return

	. = ..()

/obj/item/storage/fancy/cigar/populate_contents()
	for(var/i in 1 to storage_slots)
		new item_obj(src)
	create_reagents(15 * storage_slots)
	update_icon()

/obj/item/storage/fancy/cigar/update_icon()
	if(open)
		icon_state = "[initial(icon_state)][contents.len]"
	else
		icon_state = "cigarcase"

/obj/item/storage/fancy/cigar/remove_from_storage(obj/item/W as obj, atom/new_location)
		var/obj/item/clothing/mask/smokable/cigarette/cigar/C = W
		if(!istype(C)) return
		reagents.trans_to_obj(C, (reagents.total_volume/contents.len))
		..()

/*
 * Vial Box
 */

/obj/item/storage/fancy/vials
	icon = 'icons/obj/vialbox.dmi'
	icon_state = "vialbox6"
	icon_type = "vial"
	name = "vial storage box"
	storage_slots = 6
	can_hold = list(/obj/item/reagent_containers/glass/beaker/vial)
	item_obj = /obj/item/reagent_containers/glass/beaker/vial

/obj/item/storage/fancy/vials/populate_contents()
	for(var/i in 1 to storage_slots)
		new item_obj(src)

/obj/item/storage/lockbox/vials
	name = "secure vial storage box"
	desc = "A locked box for keeping things away from children."
	icon = 'icons/obj/vialbox.dmi'
	icon_state = "vialbox0"
	item_state = "syringe_kit"
	max_w_class = ITEM_SIZE_SMALL
	can_hold = list(/obj/item/reagent_containers/glass/beaker/vial)
	max_storage_space = 12 //The sum of the w_classes of all the items in this storage item.
	storage_slots = 6
	req_access = list(access_virology)

/obj/item/storage/lockbox/vials/Initialize()
	. = ..()
	update_icon()

/obj/item/storage/lockbox/vials/update_icon(itemremoved = 0)
	var/total_contents = src.contents.len - itemremoved
	src.icon_state = "vialbox[total_contents]"
	src.cut_overlays()
	if (!broken)
		overlays += image(icon, src, "led[locked]")
		if(locked)
			overlays += image(icon, src, "cover")
	else
		overlays += image(icon, src, "ledb")
	return

/obj/item/storage/lockbox/vials/attackby(obj/item/W, mob/user)
	..()
	update_icon()
