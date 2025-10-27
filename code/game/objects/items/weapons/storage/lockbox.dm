//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:32

/obj/item/storage/lockbox
	name = "lockbox"
	desc = "A locked box."
	icon_state = "lockbox+l"
	item_state = "syringe_kit"
	w_class = ITEM_SIZE_BULKY
	max_w_class = ITEM_SIZE_NORMAL
	max_storage_space = 14 //The sum of the w_classes of all the items in this storage item.
	req_access = list(access_armory)
	var/locked = 1
	var/broken = 0
	var/icon_locked = "lockbox+l"
	var/icon_closed = "lockbox"
	var/icon_broken = "lockbox+b"


/obj/item/storage/lockbox/attackby(obj/item/W as obj, mob/user as mob)
	if (isidcard(W))
		if(src.broken)
			to_chat(user, span_warning("It appears to be broken."))
			return
		if(src.allowed(user))
			src.locked = !( src.locked )
			if(src.locked)
				src.icon_state = src.icon_locked
				to_chat(user, span_notice("You lock \the [src]!"))
				return
			else
				src.icon_state = src.icon_closed
				to_chat(user, span_notice("You unlock \the [src]!"))
				return
		else
			to_chat(user, span_warning("Access Denied"))
	else if(istype(W, /obj/item/melee/energy/blade))
		if(emag_act(INFINITY, user, W, "The locker has been sliced open by [user] with an energy blade!", "You hear metal being sliced and sparks flying."))
			var/datum/effect/effect/system/spark_spread/spark_system = new /datum/effect/effect/system/spark_spread()
			spark_system.set_up(5, 0, src.loc)
			spark_system.start()
			playsound(src.loc, 'sound/weapons/blade1.ogg', 50, 1)
			playsound(src.loc, "sparks", 50, 1)
	if(!locked)
		..()
	else
		to_chat(user, span_warning("It's locked!"))
	return


/obj/item/storage/lockbox/show_to(mob/user as mob)
	if(locked)
		to_chat(user, span_warning("It's locked!"))
	else
		..()
	return

/obj/item/storage/lockbox/emag_act(remaining_charges, mob/user, emag_source, visual_feedback = "", audible_feedback = "")
	if(!broken)
		if(visual_feedback)
			visual_feedback = span_warning("[visual_feedback]")
		else
			visual_feedback = span_warning("The locker has been sliced open by [user] with an electromagnetic card!")
		if(audible_feedback)
			audible_feedback = span_warning("[audible_feedback]")
		else
			audible_feedback = span_warning("You hear a faint electrical spark.")

		broken = 1
		locked = 0
		desc = "It appears to be broken."
		icon_state = src.icon_broken
		visible_message(visual_feedback, audible_feedback)
		return 1
