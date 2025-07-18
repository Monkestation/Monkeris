/obj/item/clothing/proc/can_attach_accessory(obj/item/clothing/accessory/A)
	if(valid_accessory_slots && istype(A) && (A.slot in valid_accessory_slots))
		.=1
	else
		return 0
	if(accessories.len && restricted_accessory_slots && (A.slot in restricted_accessory_slots))
		for(var/obj/item/clothing/accessory/AC in accessories)
			if (AC.slot == A.slot)
				return 0

/obj/item/clothing/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/clothing/accessory))

		if(!valid_accessory_slots || !valid_accessory_slots.len)
			to_chat(usr, span_warning("You cannot attach accessories of any kind to \the [src]."))
			return

		var/obj/item/clothing/accessory/A = I
		if(can_attach_accessory(A) && user.unEquip(A, src))
			accessories += A
			A.on_attached(src, user)
			src.verbs |= /obj/item/clothing/proc/removetie_verb
			src.update_wear_icon()
		else
			to_chat(user, span_warning("You cannot attach more accessories of this type to [src]."))
		return

	if(accessories.len)
		for(var/obj/item/clothing/accessory/A in accessories)
			A.attackby(I, user)
		return

	..()

/**
 *  Attach accessory A to src
 *
 *  user is the user doing the attaching. Can be null, such as when attaching
 *  items on spawn
 */
/obj/item/clothing/proc/attach_accessory(mob/user, obj/item/clothing/accessory/A)
	accessories += A
	A.on_attached(src, user)
	src.verbs |= /obj/item/clothing/proc/removetie_verb
	src.update_wear_icon()

/obj/item/clothing/attack_hand(mob/user)
	//only forward to the attached accessory if the clothing is equipped (not in a storage)
	if(accessories.len && src.loc == user)
		for(var/obj/item/clothing/accessory/A in accessories)
			A.attack_hand(user)
		return
	return ..()

/obj/item/clothing/examine(mob/user, extra_description = "")
	if(LAZYLEN(accessories))
		for(var/obj/item/clothing/accessory/A in accessories)
			extra_description += "\n\A [A] is attached to it."
	..(user, extra_description)

/obj/item/clothing/proc/remove_accessory(mob/user, obj/item/clothing/accessory/A)
	if(!(A in accessories))
		return

	if(!(A.isRemovable))
		to_chat(user, span_warning("Removing this accessory would ruin it."))
	else
		A.on_removed(user)
		accessories -= A
		update_wear_icon()
	return

/obj/item/clothing/proc/removetie_verb()
	set name = "Remove Accessory"
	set category = "Object"
	set src in usr
	if(!isliving(usr))
		return
	if(usr.stat)
		return
	if(!accessories.len)
		return
	var/obj/item/clothing/accessory/A
	if(accessories.len > 1)
		A = input("Select an accessory to remove from [src]") as null|anything in accessories
	else
		A = accessories[1]
	src.remove_accessory(usr,A)
	if(!accessories.len)
		src.verbs -= /obj/item/clothing/proc/removetie_verb

/obj/item/clothing/emp_act(severity)
	if(accessories.len)
		for(var/obj/item/clothing/accessory/A in accessories)
			A.emp_act(severity)
	..()
