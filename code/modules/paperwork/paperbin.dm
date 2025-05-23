/obj/item/paper_bin
	name = "paper bin"
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "paper_bin1"
	item_state = "sheet-metal"
	throwforce = 1
	w_class = ITEM_SIZE_NORMAL
	throw_speed = 3
	throw_range = 7
	layer = OBJ_LAYER - 0.1
	var/amount = 30					//How much paper is in the bin.
	var/list/papers = new/list()	//List of papers put in the bin for reference.


/obj/item/paper_bin/MouseDrop(mob/user as mob)
	if((user == usr && (!( usr.restrained() ) && (!( usr.stat ) && (usr.contents.Find(src) || in_range(src, usr))))))
		if(!isslime(usr) && !isanimal(usr))
			if( !usr.get_active_held_item() )		//if active hand is empty
				var/mob/living/carbon/human/H = user
				var/obj/item/organ/external/temp = H.organs_by_name[BP_R_ARM]

				if (H.hand)
					temp = H.organs_by_name[BP_L_ARM]
				if(temp && !temp.is_usable())
					to_chat(user, span_notice("You try to move your [temp.name], but cannot!"))
					return

				to_chat(user, span_notice("You pick up the [src]."))
				user.put_in_hands(src)

	return

/obj/item/paper_bin/attack_hand(mob/user as mob)
	if (istype(loc, /turf))
		if(ishuman(user))
			var/mob/living/carbon/human/H = user
			var/obj/item/organ/external/temp = H.organs_by_name[BP_R_ARM]
			if (H.hand)
				temp = H.organs_by_name[BP_L_ARM]
			if(temp && !temp.is_usable())
				to_chat(user, span_notice("You try to move your [temp.name], but cannot!"))
				return
		var/response = ""
		if(!papers.len > 0)
			response = alert(user, "Do you take regular paper, or Carbon copy paper?", "Paper type request", "Regular", "Carbon-Copy", "Cancel")
			if (response != "Regular" && response != "Carbon-Copy")
				add_fingerprint(user)
				return
		if(amount >= 1)
			amount--
			if(amount==0)
				update_icon()

			var/obj/item/paper/P
			if(papers.len > 0)	//If there's any custom paper on the stack, use that instead of creating a new paper.
				P = papers[papers.len]
				papers.Remove(P)
			else
				if(response == "Regular")
					P = new /obj/item/paper
				else if (response == "Carbon-Copy")
					P = new /obj/item/paper/carbon

			user.put_in_hands(P)
			to_chat(user, span_notice("You take [P] out of the [src]."))
		else
			to_chat(user, span_notice("[src] is empty!"))

		add_fingerprint(user)
		return
	.=..()

//Pickup paperbins with drag n drop
/obj/item/paper_bin/MouseDrop(over_object)
	if (usr == over_object && usr.Adjacent(src))
		if(pre_pickup(usr))
			pickup(usr)
			return TRUE
		return FALSE
	.=..()


/obj/item/paper_bin/attackby(obj/item/paper/i as obj, mob/user as mob)
	if(!istype(i))
		return

	user.drop_item()
	i.loc = src
	to_chat(user, span_notice("You put [i] in [src]."))
	papers.Add(i)
	update_icon()
	amount++


/obj/item/paper_bin/examine(mob/user, extra_description = "")
	if(get_dist(src, user) <= 1)
		if(amount)
			extra_description += span_notice("There " + (amount > 1 ? "are [amount] papers" : "is one paper") + " in the bin.")
		else
			extra_description += span_notice("There are no papers in the bin.")
	else
		extra_description += span_notice("If you got closer you could see how much paper is in it.")
	..(user, extra_description)

/obj/item/paper_bin/update_icon()
	if (amount < 1)
		icon_state = "paper_bin0"
	else
		icon_state = "paper_bin1"
