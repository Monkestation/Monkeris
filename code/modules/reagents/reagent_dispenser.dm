/obj/structure/reagent_dispensers
	name = "dispenser"
	desc = "..."
	icon = 'icons/obj/objects.dmi'
	icon_state = "watertank"
	density = TRUE
	anchored = FALSE
	reagent_flags = DRAINABLE | AMOUNT_VISIBLE
	//sapwn_values
	bad_type = /obj/structure/reagent_dispensers
	rarity_value = 10
	spawn_frequency = 10
	spawn_tags = SPAWN_TAG_REAGENT_DISPENSER
	var/volume = 1500
	var/starting_reagent
	var/amount_per_transfer_from_this = 10
	var/possible_transfer_amounts = list(10,25,50,100)
	var/contents_cost

/obj/structure/reagent_dispensers/Initialize(mapload, bolt=FALSE)
	. = ..()
	create_reagents(volume)
	if(starting_reagent)
		reagents.add_reagent(starting_reagent, volume)
	if(!possible_transfer_amounts)
		src.verbs -= /obj/structure/reagent_dispensers/verb/set_APTFT
	anchored = bolt
	var/turf/T = get_turf(src)
	T?.levelupdate()

/obj/structure/reagent_dispensers/attackby(obj/item/W, mob/user)
	if(istype(W, /obj/item/device/spy_bug))
		user.drop_item()
		W.loc = get_turf(src)

	else if(W.is_refillable())
		return FALSE //so we can refill them via their afterattack.

	else if((QUALITY_BOLT_TURNING in W.tool_qualities) && (user.a_intent == I_HELP))
		if(W.use_tool(user, src, WORKTIME_NEAR_INSTANT, QUALITY_BOLT_TURNING, FAILCHANCE_EASY,  required_stat = STAT_MEC))
			src.add_fingerprint(user)
			if(anchored)
				user.visible_message("\The [user] begins unsecuring \the [src] from the floor.", "You start unsecuring \the [src] from the floor.")
			else
				user.visible_message("\The [user] begins securing \the [src] to the floor.", "You start securing \the [src] to the floor.")

			if(do_after(user, 20, src))
				if(!src) return
				if(set_anchored(!anchored))
					to_chat(user, span_notice("You [anchored? "" : "un"]secured \the [src]!"))
				else
					to_chat(user, span_warning("Ugh. You done something wrong!"))
			return FALSE
	else
		return ..()

/obj/structure/reagent_dispensers/verb/set_APTFT() //set amount_per_transfer_from_this
	set name = "Set transfer amount"
	set category = "Object"
	set src in view(1)
	var/N = input("Amount per transfer from this:","[src]") as null|anything in possible_transfer_amounts
	if (N)
		amount_per_transfer_from_this = N

/obj/structure/reagent_dispensers/proc/explode()
	visible_message(span_danger("\The [src] ruptures!"))
	chem_splash(loc, 5, list(reagents))
	qdel(src)

/obj/structure/reagent_dispensers/take_damage(damage)
	explode()

/obj/structure/reagent_dispensers/get_item_cost(export)
	if(export)
		return ..() + round(reagents.total_volume * 0.125)
	return ..() + contents_cost

//Dispensers
/obj/structure/reagent_dispensers/watertank
	name = "water tank"
	desc = "A water tank. It is used to store high amounts of water."
	icon_state = "watertank"
	amount_per_transfer_from_this = 10
	volume = 1500
	starting_reagent = "water"
	price_tag = 50
	contents_cost = 150

/obj/structure/reagent_dispensers/watertank/derelict
	icon_state = "watertank-derelict"
	spawn_blacklisted = TRUE

/obj/structure/reagent_dispensers/watertank/huge
	name = "high-capacity water tank"
	desc = "A high-capacity water tank. It is used to store HUGE amounts of water."
	icon_state = "hvwatertank"
	volume = 3000
	price_tag = 100
	contents_cost = 300
	rarity_value = 30

/obj/structure/reagent_dispensers/watertank/huge/derelict
	icon_state = "hvwatertank-derelict"
	spawn_blacklisted = TRUE

/obj/structure/reagent_dispensers/fueltank
	name = "fuel tank"
	desc = "A tank full of industrial welding fuel. Do not consume."
	description_antag = "Can have an assembly with a igniter attached for detonation upon a trigger. Can also use a screwdriver to leak fuel when dragged"
	icon = 'icons/obj/objects.dmi'
	icon_state = "weldtank"
	amount_per_transfer_from_this = 10
	volume = 500
	starting_reagent = "fuel"
	price_tag = 50
	contents_cost = 750
	var/modded = FALSE
	var/obj/item/device/assembly_holder/rig

/obj/structure/reagent_dispensers/fueltank/derelict
	icon_state = "weldtank-derelict"
	spawn_blacklisted = TRUE

/obj/structure/reagent_dispensers/fueltank/huge
	name = "high-capacity fuel tank"
	desc = "A high-capacity tank full of industrial welding fuel. Do not consume."
	icon_state = "hvweldtank"
	volume = 1000
	price_tag = 100
	contents_cost = 1500
	rarity_value = 30

/obj/structure/reagent_dispensers/fueltank/huge/derelict
	icon_state = "hvweldtank-derelict"
	spawn_blacklisted = TRUE

/obj/structure/reagent_dispensers/fueltank/examine(mob/user, extra_description = "")
	if(get_dist(user, src) < 2)
		if(modded)
			extra_description += span_warning("\nFuel faucet is open, leaking the fuel!")
		if(rig)
			extra_description += span_notice("\nThere is some kind of device rigged to the tank.")
	..(user, extra_description)

/obj/structure/reagent_dispensers/fueltank/attack_hand()
	if (rig)
		usr.visible_message(span_notice("\The [usr] begins to detach [rig] from \the [src]."), span_notice("You begin to detach [rig] from \the [src]."))
		if(do_after(usr, 20, src))
			usr.visible_message(span_notice("\The [usr] detaches \the [rig] from \the [src]."), span_notice("You detach [rig] from \the [src]"))
			rig.loc = get_turf(usr)
			rig = null
			overlays = new/list()

/obj/structure/reagent_dispensers/fueltank/attackby(obj/item/I, mob/user)
	src.add_fingerprint(user)
	if((QUALITY_SCREW_DRIVING in I.tool_qualities) && (user.a_intent == I_HURT))
		if(I.use_tool(user, src, WORKTIME_FAST, QUALITY_SCREW_DRIVING, FAILCHANCE_EASY,  required_stat = STAT_MEC))
			user.visible_message("[user] screws [src]'s faucet [modded ? "closed" : "open"].", \
				"You screw [src]'s faucet [modded ? "closed" : "open"]")
			modded = !modded
			if (modded)
				message_admins("[key_name_admin(user)] opened fueltank at [loc.loc.name] ([loc.x],[loc.y],[loc.z]), leaking fuel. [ADMIN_JMP(loc)]")
				log_game("[key_name(user)] opened fueltank at [loc.loc.name] ([loc.x],[loc.y],[loc.z]), leaking fuel.")
				leak_fuel(amount_per_transfer_from_this)
	if (istype(I,/obj/item/device/assembly_holder))
		if (rig)
			to_chat(user, span_warning("There is another device in the way."))
			return ..()
		user.visible_message(span_danger("\The [user] begins rigging [I] to \the [src]."), span_warning("You begin rigging [I] to \the [src]"))
		if(do_after(user, 20, src))
			user.visible_message(span_danger("\The [user] rigs [I] to \the [src]."), span_warning("You rig [I] to \the [src].</span>"))

			var/obj/item/device/assembly_holder/H = I
			if (istype(H.left_assembly,/obj/item/device/assembly/igniter) || istype(H.right_assembly,/obj/item/device/assembly/igniter))
				message_admins("[key_name_admin(user)] rigged fueltank at [loc.loc.name] ([loc.x],[loc.y],[loc.z]) for explosion. [ADMIN_JMP(loc)]")
				log_game("[key_name(user)] rigged fueltank at [loc.loc.name] ([loc.x],[loc.y],[loc.z]) for explosion.")

			rig = I
			user.drop_item()
			I.loc = src

			var/icon/test = getFlatIcon(I)
			test.Shift(NORTH,1)
			test.Shift(EAST,6)
			overlays += test

	var/obj/item/tool/T = I
	if(istype(T) && T.use_fuel_cost)
		return 0

	return ..()


/obj/structure/reagent_dispensers/fueltank/bullet_act(obj/item/projectile/Proj)
	if(Proj.get_structure_damage())
		if(istype(Proj.firer))
			message_admins("[key_name_admin(Proj.firer)] shot fueltank at [loc.loc.name] ([loc.x],[loc.y],[loc.z]) [ADMIN_JMP(loc)].")
			log_game("[key_name(Proj.firer)] shot fueltank at [loc.loc.name] ([loc.x],[loc.y],[loc.z]).")

		if(!istype(Proj ,/obj/item/projectile/beam/lastertag) && !istype(Proj ,/obj/item/projectile/beam/practice) )
			explode()
/obj/structure/reagent_dispensers/fueltank/explosion_act(target_power, explosion_handler/handle)
	if(target_power > health)
		explode()
	else
		take_damage(target_power)

/obj/structure/reagent_dispensers/fueltank/ignite_act()
	if(modded)
		explode()

/obj/structure/reagent_dispensers/fueltank/explode()
	explosion(get_turf(src), reagents.total_volume / 2, 50)
	if(src)
		qdel(src)

/obj/structure/reagent_dispensers/fueltank/fire_act(datum/gas_mixture/air, temperature, volume)
	if (modded)
		explode()
	else if (temperature > T0C+500)
		explode()
	return ..()

/obj/structure/reagent_dispensers/fueltank/Move(NewLoc, Dir = 0, step_x = 0, step_y = 0, glide_size_override = 0)
	if ((. = ..()) && modded)
		leak_fuel(amount_per_transfer_from_this/10)

/obj/structure/reagent_dispensers/fueltank/proc/leak_fuel(amount)
	if (reagents.total_volume == 0)
		return

	amount = min(amount, reagents.total_volume)
	reagents.remove_reagent("fuel",amount)
	new /obj/effect/decal/cleanable/liquid_fuel(src.loc, amount,1)

/obj/structure/reagent_dispensers/peppertank
	name = "pepper spray refiller"
	desc = "Contains condensed capsaicin for use in law \"enforcement.\""
	icon_state = "peppertank"
	anchored = TRUE
	density = FALSE
	amount_per_transfer_from_this = 45
	volume = 1000
	starting_reagent = "condensedcapsaicin"
	spawn_blacklisted = TRUE


/obj/structure/reagent_dispensers/water_cooler
	name = "water cooler"
	desc = "A machine that dispenses water to drink."
	amount_per_transfer_from_this = 5
	icon = 'icons/obj/vending.dmi'
	icon_state = "water_cooler"
	possible_transfer_amounts = null
	anchored = TRUE
	volume = 500
	starting_reagent = "water"
	spawn_blacklisted = TRUE
	var/paper_cups = 420 //Paper cups left from the cooler

/obj/structure/reagent_dispensers/water_cooler/examine(mob/user, extra_description = "")
	if (paper_cups > 1)
		extra_description += "There are [paper_cups] paper cups left."
	else if (paper_cups == 1)
		extra_description += "There is one paper cup left."
	else
		extra_description += "There are no paper cups left."
	..(user, extra_description)

/obj/structure/reagent_dispensers/water_cooler/attack_hand(mob/living/user)
	. = ..()
	if(.)
		return
	if(!paper_cups)
		to_chat(user, span_warning("There aren't any cups left!"))
		return
	user.visible_message(span_notice("[user] takes a cup from [src]."), span_notice("You take a paper cup from [src]."))
	var/obj/item/reagent_containers/food/drinks/sillycup/S = new(get_turf(src))
	user.put_in_hands(S)
	paper_cups--

/obj/structure/reagent_dispensers/beerkeg
	name = "beer keg"
	desc = "A beer keg"
	icon_state = "beertankTEMP"
	amount_per_transfer_from_this = 10
	volume = 1000
	starting_reagent = "beer"
	price_tag = 50
	contents_cost = 700
	spawn_blacklisted = TRUE

/obj/structure/reagent_dispensers/rumkeg
	name = "rum keg"
	desc = "A rum keg"
	icon_state = "beertankTEMP"
	amount_per_transfer_from_this = 10
	volume = 1000
	starting_reagent = "rum"
	price_tag = 50
	contents_cost = 700
	spawn_blacklisted = TRUE

/obj/structure/reagent_dispensers/coolanttank
	name = "coolant tank"
	desc = "A tank of industrial coolant"
	icon = 'icons/obj/objects.dmi'
	icon_state = "coolanttank"
	amount_per_transfer_from_this = 10
	volume = 1000
	starting_reagent = "coolant"
	price_tag = 50
	contents_cost = 700


/obj/structure/reagent_dispensers/cahorsbarrel
	name = "NeoTheology Cahors barrel"
	desc = "Barrel a day - keeps liver away."
	icon_state = "barrel"
	volume = 400
	starting_reagent = "ntcahors"
	price_tag = 50
	contents_cost = 950
	spawn_blacklisted = TRUE


/obj/structure/reagent_dispensers/acid
	name = "sulphuric acid dispenser"
	desc = "A dispenser of acid for industrial processes."
	icon_state = "acidtank"
	amount_per_transfer_from_this = 10
	anchored = TRUE
	density = FALSE
	volume = 1000
	starting_reagent = "sacid"
	spawn_blacklisted = TRUE

//this is big movable beaker
/obj/structure/reagent_dispensers/bidon
	name = "B.I.D.O.N. canister"
	desc = "Bulk Industrial Dispenser Omnitech-Nanochem. A canister with acid-resistant linings intended for handling big volumes of chemicals."
	icon = 'icons/obj/machines/chemistry.dmi'
	icon_state = "bidon"
	rarity_value = 15
	matter = list(MATERIAL_STEEL = 16, MATERIAL_GLASS = 8, MATERIAL_PLASTIC = 6)
	reagent_flags = AMOUNT_VISIBLE
	amount_per_transfer_from_this = 30
	possible_transfer_amounts = list(10,30,60,120,200)
	var/filling_states = list(10,20,30,40,50,60,70,80,100)
	unacidable = 1
	anchored = FALSE
	density = TRUE
	volume = 600
	var/lid = TRUE

/obj/structure/reagent_dispensers/bidon/advanced
	name = "stasis B.I.D.O.N. canister"
	desc = "An advanced B.I.D.O.N. canister with stasis function."
	icon_state = "bidon_adv"
	matter = list(MATERIAL_STEEL = 20, MATERIAL_GLASS = 12, MATERIAL_SILVER = 8)
	reagent_flags = TRANSPARENT
	filling_states = list(20,40,60,80,100)
	volume = 900
	rarity_value = 60

/obj/structure/reagent_dispensers/bidon/Initialize(mapload, ...)
	. = ..()
	update_icon()

/obj/structure/reagent_dispensers/bidon/examine(mob/user, extra_description = "")
	if(get_dist(user, src) < 2)
		if(lid)
			extra_description += span_notice("\nIt has lid on it.")
		if(reagents.total_volume)
			extra_description += span_notice("\nIt's filled with [reagents.total_volume]/[volume] units of reagents.")
	..(user, extra_description)

/obj/structure/reagent_dispensers/bidon/attack_hand(mob/user)
	lid = !lid
	if(lid)
		to_chat(user, span_notice("You put the lid on."))
		reagent_flags &= ~(REFILLABLE | DRAINABLE | DRAWABLE | INJECTABLE)
	else
		reagent_flags |= REFILLABLE | DRAINABLE | DRAWABLE | INJECTABLE
		to_chat(user, span_notice("You removed the lid."))
	playsound(src,'sound/items/trayhit2.ogg',50,1)
	update_icon()

/obj/structure/reagent_dispensers/bidon/attackby(obj/item/I, mob/user)
	if(lid)
		to_chat(user, span_notice("Remove the lid first."))
		return
	else
		. = ..()
	update_icon()

/obj/structure/reagent_dispensers/bidon/update_icon()
	cut_overlays()
	if(lid)
		var/mutable_appearance/lid_icon = mutable_appearance(icon, "[icon_state]_lid")
		add_overlay(lid_icon)
	if(reagents.total_volume)
		var/mutable_appearance/filling = mutable_appearance('icons/obj/reagentfillings.dmi', "[icon_state][get_filling_state()]")
		if(!istype(src,/obj/structure/reagent_dispensers/bidon/advanced))
			filling.color = reagents.get_color()
		add_overlay(filling)

/obj/structure/reagent_dispensers/bidon/proc/get_filling_state()
	var/percent = round((reagents.total_volume / volume) * 100)
	for(var/increment in filling_states)
		if(increment >= percent)
			return increment

/obj/structure/reagent_dispensers/bidon/advanced/examine(mob/user, extra_description = "")
	if(get_dist(user, src) < 2 && LAZYLEN(reagents.reagent_list))
		for(var/datum/reagent/R as anything in reagents.reagent_list)
			extra_description += span_notice("\n[R.volume] units of [R.name]")
	..(user, extra_description)
