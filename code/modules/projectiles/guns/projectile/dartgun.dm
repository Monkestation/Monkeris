/obj/item/projectile/bullet/chemdart
	name = "dart"
	icon_state = "dart"
	damage_types = list(BRUTE = 5)
	sharp = TRUE
	embed = 1 //the dart is shot fast enough to pierce space suits, so I guess splintering inside the target can be a thing. Should be rare due to low damage.
	kill_count = 15 //shorter range
	muzzle_type = null
	var/reagent_amount = 15
	matter = list(MATERIAL_GLASS = 0.2)

/obj/item/projectile/bullet/chemdart/New()
	create_reagents(reagent_amount)
	..()

/obj/item/projectile/bullet/chemdart/on_hit(atom/target, def_zone = null)
	if(isliving(target))
		var/mob/living/L = target
		if(L.can_inject(target_zone = def_zone))
			reagents.trans_to_mob(L, reagent_amount, CHEM_BLOOD)

/obj/item/ammo_casing/chemdart
	name = "chemical dart"
	desc = "A small hardened, hollow dart."
	icon_state = "dart"
	caliber = CAL_DART
	is_caseless = TRUE
	projectile_type = /obj/item/projectile/bullet/chemdart


/obj/item/ammo_magazine/chemdart
	name = "dart cartridge"
	desc = "A rack of hollow darts."
	icon_state = "darts"
	item_state = "rcdammo"
	origin_tech = list(TECH_MATERIAL = 2)
	mag_type = MAGAZINE
	caliber = CAL_DART
	ammo_type = /obj/item/ammo_casing/chemdart
	max_ammo = 5
	mag_well = MAG_WELL_DART
	ammo_states = list(1, 2, 3, 4, 5)

/obj/item/gun/projectile/dartgun
	name = "Z-H P \"Artemis\""
	desc = "Zeng-Hu Pharmaceutical's entry into the arms market, the Z-H P Artemis is a gas-powered dart gun capable of delivering chemical cocktails swiftly across short distances."
	icon = 'icons/obj/guns/projectile/dartgun.dmi'
	icon_state = "dartgun-empty"
	caliber = CAL_DART
	fire_sound = 'sound/weapons/empty.ogg'
	fire_sound_text = "a metallic click"
	matter = list(MATERIAL_STEEL = 20, MATERIAL_PLASTIC = 10)
	gun_parts = list(/obj/item/stack/material/steel = 15 ,/obj/item/stack/material/plastic = 2)
	init_recoil = SMG_RECOIL(1)
	silenced = TRUE
	load_method = MAGAZINE
	magazine_type = /obj/item/ammo_magazine/chemdart
	auto_eject = 0
	mag_well = MAG_WELL_DART
	rarity_value = 10

	var/list/beakers = list() //All containers inside the gun.
	var/list/mixing = list() //Containers being used for mixing.
	var/max_beakers = 3
	var/dart_reagent_amount = 15
	var/beaker_type = /obj/item/reagent_containers/glass/beaker
	var/list/starting_chems

/obj/item/gun/projectile/dartgun/New()
	..()
	if(starting_chems)
		for(var/chem in starting_chems)
			var/obj/B = new beaker_type(src)
			B.reagents.add_reagent(chem, 60)
			beakers += B
	update_icon()

/obj/item/gun/projectile/dartgun/update_icon()
	..()
	if(ammo_magazine)
		icon_state = "dartgun-[round(ammo_magazine.stored_ammo.len,2)]"
	else
		icon_state = "dartgun-empty"
	return

/obj/item/gun/projectile/dartgun/consume_next_projectile()
	. = ..()
	var/obj/item/projectile/bullet/chemdart/dart = .
	if(istype(dart))
		fill_dart(dart)

/obj/item/gun/projectile/dartgun/examine(mob/user, extra_description = "")
	if(LAZYLEN(beakers))
		extra_description += span_notice("\n[src] contains:")
		for(var/obj/item/reagent_containers/glass/beaker/B in beakers)
			if(B.reagents && LAZYLEN(B.reagents.reagent_list))
				for(var/datum/reagent/R in B.reagents.reagent_list)
					extra_description += span_notice("\n[R.volume] units of [R.name]")
	..(user, extra_description)

/obj/item/gun/projectile/dartgun/attackby(obj/item/I as obj, mob/user as mob)
	if(istype(I, /obj/item/reagent_containers/glass))
		if(!istype(I, beaker_type))
			to_chat(user, span_notice("[I] doesn't seem to fit into [src]."))
			return
		if(beakers.len >= max_beakers)
			to_chat(user, span_notice("[src] already has [max_beakers] beakers in it - another one isn't going to fit!"))
			return
		var/obj/item/reagent_containers/glass/beaker/B = I
		user.drop_item()
		B.loc = src
		beakers += B
		to_chat(user, span_notice("You slot [B] into [src]."))
		src.updateUsrDialog()
		return 1
	..()

//fills the given dart with reagents
/obj/item/gun/projectile/dartgun/proc/fill_dart(obj/item/projectile/bullet/chemdart/dart)
	if(mixing.len)
		var/mix_amount = dart.reagent_amount/mixing.len
		for(var/obj/item/reagent_containers/glass/beaker/B in mixing)
			B.reagents.trans_to_obj(dart, mix_amount)

/obj/item/gun/projectile/dartgun/attack_self(mob/user)
	user.set_machine(src)
	var/dat = "<b>[src] mixing control:</b><br><br>"

	if (beakers.len)
		var/i = 1
		for(var/obj/item/reagent_containers/glass/beaker/B in beakers)
			dat += "Beaker [i] contains: "
			if(B.reagents && B.reagents.reagent_list.len)
				for(var/datum/reagent/R in B.reagents.reagent_list)
					dat += "<br>    [R.volume] units of [R.name], "
				if (check_beaker_mixing(B))
					dat += text("<A href='byond://?src=\ref[src];stop_mix=[i]'><font color='green'>Mixing</font></A> ")
				else
					dat += text("<A href='byond://?src=\ref[src];mix=[i]'><font color='red'>Not mixing</font></A> ")
			else
				dat += "nothing."
			dat += " \[<A href='byond://?src=\ref[src];eject=[i]'>Eject</A>\]<br>"
			i++
	else
		dat += "There are no beakers inserted!<br><br>"

	if(ammo_magazine)
		if(ammo_magazine.stored_ammo && ammo_magazine.stored_ammo.len)
			dat += "The dart cartridge has [ammo_magazine.stored_ammo.len] shots remaining."
		else
			dat += "<font color='red'>The dart cartridge is empty!</font>"
		dat += " \[<A href='byond://?src=\ref[src];eject_cart=1'>Eject</A>\]"

	user << browse(HTML_SKELETON_TITLE("Dart Gun", dat), "window=dartgun")
	onclose(user, "dartgun", src)

/obj/item/gun/projectile/dartgun/proc/check_beaker_mixing(obj/item/B)
	if(!mixing || !beakers)
		return 0
	for(var/obj/item/M in mixing)
		if(M == B)
			return 1
	return 0

/obj/item/gun/projectile/dartgun/Topic(href, href_list)
	if(..()) return 1
	src.add_fingerprint(usr)
	if(href_list["stop_mix"])
		var/index = text2num(href_list["stop_mix"])
		if(index <= beakers.len)
			for(var/obj/item/M in mixing)
				if(M == beakers[index])
					mixing -= M
					break
	else if (href_list["mix"])
		var/index = text2num(href_list["mix"])
		if(index <= beakers.len)
			mixing += beakers[index]
	else if (href_list["eject"])
		var/index = text2num(href_list["eject"])
		if(index <= beakers.len)
			if(beakers[index])
				var/obj/item/reagent_containers/glass/beaker/B = beakers[index]
				to_chat(usr, "You remove [B] from [src].")
				mixing -= B
				beakers -= B
				B.loc = get_turf(src)
	else if (href_list["eject_cart"])
		unload_ammo(usr)
	src.updateUsrDialog()
	return
