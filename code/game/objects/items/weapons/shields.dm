//TODO: Fully integrate shield behavior into Blocking and move it to /obj/item.
//Behavior currently routed through blocking but isn't fully integrated. See human.dm


//** Shield Helpers
//These are shared by various items that have shield-like behaviour

//bad_arc is the ABSOLUTE arc of directions from which we cannot block. If you want to fix it to e.g. the user's facing you will need to rotate the dirs yourself.
/proc/check_parry_arc(mob/user, bad_arc, atom/damage_source = null, mob/attacker = null)
	//check attack direction
	var/attack_dir = 0 //direction from the user to the source of the attack
	if(istype(damage_source, /obj/item/projectile))
		var/obj/item/projectile/P = damage_source
		attack_dir = get_dir(get_turf(user), P.starting)
	else if(attacker)
		attack_dir = get_dir(get_turf(user), get_turf(attacker))
	else if(damage_source)
		attack_dir = get_dir(get_turf(user), get_turf(damage_source))

	if(!(attack_dir && (attack_dir & bad_arc)))
		return 1
	return 0

/proc/default_parry_check(mob/user, mob/attacker, atom/damage_source)
	//parry only melee attacks
	if(istype(damage_source, /obj/item/projectile) || (attacker && get_dist(user, attacker) > 1) || user.incapacitated())
		return 0

	//block as long as they are not directly behind us
	var/bad_arc = reverse_direction(user.dir) //arc of directions from which we cannot block
	if(!check_parry_arc(user, bad_arc, damage_source, attacker))
		return 0

	return 1

/obj/item/shield
	name = "shield"
	/// floor for block chance
	var/base_block_chance = 25 // ~65% block at 100 rob while raised
	/// additional blocking chance, scaled proportunately to Robustness
	var/shield_difficulty = 55
	/// % increase to the final block chance of a shield while it's raised
	var/blocking_multiplier = 1.25
	/// duration of slowdown inflicted on a bashed mob
	var/slowdown_time = 1
	/// determines how much of a penetrating projectile's damage is lost. see bullets.dm, beams.dm, & plasma.dm
	var/shield_integrity = 100
	slowdown_blocking = SHIELD_BLOCKING_SLOWDOWN
	style = STYLE_NEG_HIGH
	item_icons = list(
		slot_l_hand_str = 'icons/mob/inhands/equipment/shields_lefthand.dmi',
		slot_r_hand_str = 'icons/mob/inhands/equipment/shields_righthand.dmi',
		)

/obj/item/shield/examine(mob/user, extra_description = "")
	switch(get_block_chance(user))
		if(0 to 30)
			extra_description += "So heavy... You feel doubtful in your ability to parry with this shield."
		if(31 to 45)
			extra_description += "Holding this feels a little clumsy. Perhaps if you were a bit stronger..."
		if(46 to 55)
			extra_description += "A bit hefty, but you feel confident in your ability to parry with this shield."
		if(56 to 70)
			extra_description += "The weight of this shield feels comfortable and maneuverable."
		if(71 to INFINITY)
			extra_description += "You feel ready for a gladiator duel! Bring it on, roaches!"
	if(!user.blocking)
		switch(blocking_multiplier)
			if(1.1 to 1.5)
				extra_description += span_notice("<br>You can raise your guard to increase this shield's performance.")
			if(1.6 to 2.5)
				extra_description += span_warning("<br>You need to raise this shield to use it effectively.")
			if(2.6 to 3)
				extra_description += span_warning("<br>Whew... This shield is almost impossible to use when not raised!")
	else
		extra_description += span_notice("<br>You have raised this shield and are focusing on blocking attacks.")
	..(user, extra_description)

/obj/item/shield/proc/get_wielder_skill(mob/user, stat_type)
	if(user && user.stats)
		return max(1,user.stats.getStat(stat_type))

	return 1 //STAT_LEVEL_MIN doesn't work due to division by zero error

/obj/item/shield/handle_shield(mob/user, damage, atom/damage_source = null, mob/attacker = null, def_zone = null, attack_text = "the attack")

	if(istype(damage_source, /obj/item/projectile) || (attacker && get_dist(user, attacker) > 1) || user.incapacitated())
		return 0

	//block as long as they are not directly behind us
	var/bad_arc = reverse_direction(user.dir) //arc of directions from which we cannot block
	if(check_parry_arc(user, bad_arc, damage_source, attacker))
		if(prob(get_block_chance(user)))
			user.visible_message(span_danger("\The [user] blocks [attack_text] with \the [src]!"))
			return 1
	return 0

/obj/item/shield/block_bullet(mob/user, obj/item/projectile/damage_source, def_zone)
	var/bad_arc = reverse_direction(user.dir)
	var/list/protected_area
	if(prob(50))
		protected_area = get_partial_protected_area(user)
	else protected_area = get_protected_area(user)
	if(protected_area.Find(def_zone) && check_shield_arc(user, bad_arc, damage_source))
		if(!damage_source.check_penetrate(src))
			visible_message(span_danger("\The [user] blocks [damage_source] with \his [src]!"))
			playsound(user.loc, 'sound/weapons/shield/shieldblock.ogg', 50, 1)
			return 1
	return 0

/obj/item/shield/proc/check_shield_arc(mob/user, bad_arc, atom/damage_source = null, mob/attacker = null)
	//shield direction

	var/shield_dir = 0
	if(user.get_equipped_item(slot_l_hand) == src)
		shield_dir = turn(user.dir, 90)
	else if(user.get_equipped_item(slot_r_hand) == src)
		shield_dir = turn(user.dir, -90)
	//check attack direction
	var/attack_dir = 0 //direction from the user to the source of the attack
	if(istype(damage_source, /obj/item/projectile))
		var/obj/item/projectile/P = damage_source
		attack_dir = get_dir(get_turf(user), P.starting)
	else if(attacker)
		attack_dir = get_dir(get_turf(user), get_turf(attacker))
	else if(damage_source)
		attack_dir = get_dir(get_turf(user), get_turf(damage_source))

	//blocked directions
	if(user.get_equipped_item(slot_back) == src)
		if(attack_dir & bad_arc && attack_dir)
			return TRUE
		else
			return FALSE

	if(wielded && !(attack_dir && (attack_dir & bad_arc)))
		return TRUE
	else if(!(attack_dir == bad_arc) && !(attack_dir == reverse_direction(shield_dir)) && !(attack_dir == (bad_arc | reverse_direction(shield_dir))))
		return TRUE
	return FALSE

/// determines the chance of blocking attacks based on shield stats & blocking state
/obj/item/shield/proc/get_block_chance(mob/user)
	if(user.blocking && user.blocking_item == src)
		return blocking_multiplier *(shield_difficulty/(1+100/get_wielder_skill(user,STAT_ROB))+base_block_chance)
	else
		return shield_difficulty/(1+100/get_wielder_skill(user,STAT_ROB)) + base_block_chance

/obj/item/shield/proc/get_protected_area(mob/user)
	return BP_ALL_LIMBS

/obj/item/shield/proc/get_partial_protected_area(mob/user)
	return get_protected_area(user)

/obj/item/shield/attack(mob/M, mob/user)
	if(isliving(M))
		var/mob/living/L = M
		if(L.slowdown < slowdown_time * 3)
			L.slowdown += slowdown_time
	return ..()

/obj/item/shield/buckler
	name = "tactical shield"
	desc = "A compact personal shield made of pre-preg aramid fibres designed to stop or deflect bullets without slowing down its wielder."
	icon = 'icons/obj/weapons.dmi'
	icon_state = "tactical"
	item_state = "tactical"
	flags = CONDUCT
	slot_flags = SLOT_BELT|SLOT_BACK
	force = WEAPON_FORCE_PAINFUL
	throwforce = WEAPON_FORCE_PAINFUL
	throw_speed = 2
	throw_range = 6
	w_class = ITEM_SIZE_BULKY
	origin_tech = list(TECH_MATERIAL = 2)
	matter = list(MATERIAL_GLASS = 5, MATERIAL_STEEL = 5, MATERIAL_PLASTEEL = 12)
	price_tag = 500
	attack_verb = list("shoved", "bashed")
	shield_integrity = 195
	var/cooldown = 0 //shield bash cooldown. based on world.time
	var/picked_by_human = FALSE
	var/mob/living/carbon/human/picking_human

/obj/item/shield/buckler/handle_shield(mob/user)
	. = ..()
	if(.) playsound(user.loc, 'sound/weapons/Genhit.ogg', 50, 1)

/obj/item/shield/buckler/get_protected_area(mob/user)
	var/list/p_area = list(BP_CHEST)

	if(user.get_equipped_item(slot_back) == src)
		return p_area

	if(user.get_equipped_item(slot_l_hand) == src)
		p_area.Add(BP_L_ARM)
	else if(user.get_equipped_item(slot_r_hand) == src)
		p_area.Add(BP_R_ARM)

	return p_area

/obj/item/shield/buckler/get_partial_protected_area(mob/user)
	var/list/p_area = get_protected_area(user)
	p_area.Add(BP_GROIN, BP_HEAD)
	return p_area

/obj/item/shield/buckler/attackby(obj/item/W as obj, mob/user as mob)
	if(istype(W, /obj/item/melee/baton))
		on_bash(W, user)
	else
		..()

/obj/item/shield/buckler/proc/on_bash(obj/item/W, mob/user)
	if(cooldown < world.time - 25)
		user.visible_message(span_warning("[user] bashes [src] with \his [W]!"))
		playsound(user.loc, 'sound/effects/shieldbash.ogg', 50, 1)
		cooldown = world.time

/obj/item/shield/riot
	name = "ballistic shield"
	desc = "A heavy personal shield made of pre-preg aramid fibres designed to stop or deflect bullets and other projectiles at the cost of mobility."
	icon = 'icons/obj/weapons.dmi'
	icon_state = "riot"
	item_state = "riot"
	flags = CONDUCT
	slot_flags = SLOT_BACK
	force = WEAPON_FORCE_PAINFUL
	throwforce = WEAPON_FORCE_PAINFUL
	throw_speed = 1
	throw_range = 4
	w_class = ITEM_SIZE_HUGE
	origin_tech = list(TECH_MATERIAL = 2)
	matter = list(MATERIAL_GLASS = 10, MATERIAL_STEEL = 10, MATERIAL_PLASTEEL = 15)
	price_tag = 500
	//~80% block at 100 rob while raised
	base_block_chance = 15
	shield_difficulty = 35
	blocking_multiplier = 2.5
	attack_verb = list("shoved", "bashed")
	shield_integrity = 205
	slowdown_blocking = HVY_SHIELD_BLOCKING_SLOWDOWN
	var/cooldown = 0 //shield bash cooldown. based on world.time
	var/picked_by_human = FALSE
	var/mob/living/carbon/human/picking_human

/obj/item/shield/riot/handle_shield(mob/user)
	. = ..()
	if(.) playsound(user.loc, 'sound/weapons/shield/shieldmelee.ogg', 50, 1)

/obj/item/shield/riot/get_protected_area(mob/user)
	var/list/p_area = list(BP_CHEST, BP_GROIN, BP_HEAD)

	if(user.get_equipped_item(slot_back) == src)
		return p_area

	if(user.blocking && user.blocking_item == src)
		p_area = BP_ALL_LIMBS
	else
		if(user.get_equipped_item(slot_l_hand) == src)
			p_area = list(BP_L_ARM)
		else if(user.get_equipped_item(slot_r_hand) == src)
			p_area = list(BP_R_ARM)
	return p_area

/obj/item/shield/riot/get_partial_protected_area(mob/user)
	if(user.blocking && user.blocking_item == src)
		return BP_ALL_LIMBS
	else return get_protected_area(user)

/obj/item/shield/riot/New()
	RegisterSignal(src, COMSIG_ITEM_PICKED, PROC_REF(is_picked))
	RegisterSignal(src, COMSIG_ITEM_DROPPED, PROC_REF(is_dropped))
	return ..()

/obj/item/shield/riot/proc/is_picked()
	SIGNAL_HANDLER
	var/mob/living/carbon/human/user = loc
	if(istype(user))
		picked_by_human = TRUE
		picking_human = user
		RegisterSignal(picking_human, COMSIG_HUMAN_START_BLOCKING, PROC_REF(update_state), override = TRUE)
		RegisterSignal(picking_human, COMSIG_HUMAN_STOP_BLOCKING, PROC_REF(update_state), override = TRUE)
		update_state(no_message = TRUE)

/obj/item/shield/riot/proc/is_dropped()
	SIGNAL_HANDLER
	if(picked_by_human && picking_human)
		UnregisterSignal(picking_human, COMSIG_HUMAN_STOP_BLOCKING)
		UnregisterSignal(picking_human, COMSIG_HUMAN_STOP_BLOCKING)
		picked_by_human = FALSE
		picking_human.stop_blocking()
		picking_human = null

/obj/item/shield/riot/proc/update_state(no_message)
	SIGNAL_HANDLER
	if(!picking_human)
		return
	if(picking_human.blocking)
		item_state = "[initial(item_state)]_walk"
		if(!no_message)
			visible_message("[picking_human] raises [gender_datums[picking_human.gender].his] [src.name] to cover [gender_datums[picking_human.gender].him]self!")
	if(!(picking_human.blocking))
		item_state = "[initial(item_state)]_run"
		if(!no_message)
			visible_message("[picking_human] lowers [gender_datums[picking_human.gender].his] [src.name].")
	update_wear_icon()

/obj/item/shield/riot/attackby(obj/item/W as obj, mob/user as mob)
	if(istype(W, /obj/item/melee/baton))
		on_bash(W, user)
	else
		..()

/obj/item/shield/riot/proc/on_bash(obj/item/W, mob/user)
	if(cooldown < world.time - 25)
		user.visible_message(span_warning("[user] bashes [src] with [W]!"))
		playsound(user.loc, 'sound/effects/shieldbash.ogg', 50, 1)
		cooldown = world.time

/obj/item/shield/riot/dozershield
	name = "bulldozer shield"
	desc = "A crude beast of a shield hewn from slabs of metal welded to a locker door, it has been forged into a wall that stands between you and your foes."
	icon = 'icons/obj/weapons.dmi'
	icon_state = "dozershield"
	item_state = "dozershield"
	flags = CONDUCT
	slot_flags = SLOT_BACK
	force = WEAPON_FORCE_DANGEROUS
	throwforce = WEAPON_FORCE_DANGEROUS
	throw_speed = 1
	throw_range = 4
	w_class = ITEM_SIZE_HUGE
	origin_tech = list()
	matter = list(MATERIAL_GLASS = 20, MATERIAL_STEEL = 20, MATERIAL_PLASTEEL = 10)
	price_tag = 200
	//~82% block at 100 rob while raised
	base_block_chance = 5
	shield_difficulty = 45
	blocking_multiplier = 3
	shield_integrity = 230
	slowdown_hold = 1

/obj/item/shield/riot/dozershield/attackby(obj/item/W as obj, mob/user as mob)
	if(istype(W, /obj/item/tool/hammer) || istype(W, /obj/item/tool/sword))
		on_bash(W, user)
	else
		..()

/obj/item/shield/hardsuit
	name = "hardsuit shield"
	desc = "A massive ballistic shield that seems impossible to wield without mechanical assist."
	icon = 'icons/obj/weapons.dmi'
	icon_state = "hardshield"
	item_state = "hardshield"
	flags = CONDUCT
	slot_flags = SLOT_BACK
	force = WEAPON_FORCE_PAINFUL
	throwforce = WEAPON_FORCE_PAINFUL
	throw_speed = 1
	throw_range = 4
	w_class = ITEM_SIZE_HUGE
	origin_tech = list()
	matter = list()
	price_tag = 0
	//~80% blocking at 100 rob (at lower skill than riot shields)
	base_block_chance = 50
	shield_difficulty = 30
	attack_verb = list("smashed", "bashed")
	shield_integrity = 250
	var/cooldown = 0 //shield bash cooldown. based on world.time
	var/picked_by_human = FALSE
	var/mob/living/carbon/human/picking_human
	slowdown_hold = 3
	var/mob/living/creator
	var/cleanup = TRUE	// Should the shield despawn moments after being discarded by the summoner?
	var/init_procees = TRUE
	bad_type = /obj/item/shield/hardsuit

/obj/item/shield/hardsuit/get_protected_area(mob/user)
	var/list/p_area = list(BP_CHEST, BP_GROIN, BP_HEAD)

	if(user.get_equipped_item(slot_l_hand) == src)
		p_area.Add(BP_L_ARM)
	else if(user.get_equipped_item(slot_r_hand) == src)
		p_area.Add(BP_R_ARM)
	return p_area

/obj/item/shield/hardsuit/get_partial_protected_area(mob/user)
	return BP_ALL_LIMBS

/obj/item/shield/hardsuit/attackby(obj/item/W as obj, mob/user as mob)
	if(istype(W, /obj/item/melee/baton))
		on_bash(W, user)
	else
		..()

/obj/item/shield/hardsuit/proc/on_bash(obj/item/W, mob/user)
	if(cooldown < world.time - 25)
		user.visible_message(span_warning("[user] bashes [src] with \his [W]!"))
		playsound(user.loc, 'sound/effects/shieldbash.ogg', 50, 1)
		cooldown = world.time

/obj/item/shield/hardsuit/Initialize(mapload)
	. = ..()
	if(init_procees)
		START_PROCESSING(SSobj, src)

/obj/item/shield/hardsuit/Destroy()
	STOP_PROCESSING(SSobj, src)
	. = ..()

/obj/item/shield/hardsuit/dropped()
	if(cleanup)
		spawn(1) if(src) qdel(src)

/obj/item/shield/hardsuit/Process()
	if(!creator || loc != creator || (creator.l_hand != src && creator.r_hand != src))
		// Tidy up a bit.
		if(isliving(loc))
			var/mob/living/carbon/human/host = loc
			if(istype(host))
				for(var/obj/item/organ/external/organ in host.organs)
					for(var/obj/item/O in organ.implants)
						if(O == src)
							organ.implants -= src
			host.pinned -= src
			host.embedded -= src
			host.drop_from_inventory(src)
		if(cleanup)
			spawn(1) if(src) qdel(src)

/*
 * Handmade shield
 */

/obj/item/shield/buckler/handmade
	name = "round handmade shield"
	desc = "A handmade stout shield, that protects the wielder while not weighting them down."
	icon_state = "buckler"
	item_state = "buckler"
	flags = null
	throw_speed = 2
	throw_range = 6
	matter = list(MATERIAL_STEEL = 6)
	//~65% block chance at 100 rob while raised
	base_block_chance = 15
	shield_difficulty = 74
	shield_integrity = 170

/obj/item/shield/buckler/handmade/attackby(obj/item/W as obj, mob/user as mob)
	if(istype(W, /obj/item/extinguisher) || istype(W, /obj/item/storage/toolbox) || istype(W, /obj/item/melee))
		on_bash(W, user)
	else
		..()

/obj/item/shield/riot/tray
	name = "tray shield"
	desc = " A makeshift shield made from a toolbelt wrapped around a serving tray. It provides mediocre coverage but is easier to handle than other shields of similar size."
	icon_state = "tray_shield"
	item_state = "tray_shield"
	flags = CONDUCT
	throw_speed = 2
	throw_range = 4
	matter = list(MATERIAL_STEEL = 4)

	//~70% block rate at 100 rob while raised
	//poorer than other riot shields but low stat requirements
	base_block_chance = 23
	shield_difficulty = 10

/obj/item/shield/riot/tray/get_protected_area(mob/user)
	var/list/p_area = list(BP_CHEST, BP_HEAD, BP_L_ARM, BP_R_ARM, BP_GROIN)
	if(user.blocking && user.blocking_item == src && wielded)
		p_area = BP_ALL_LIMBS
	return p_area

/obj/item/shield/riot/tray/get_partial_protected_area(mob/user)
	return BP_ALL_LIMBS

/obj/item/shield/riot/tray/get_block_chance(mob/user)
	return shield_difficulty/(1+100/get_wielder_skill(user,STAT_ROB))+base_block_chance

/*
 * Energy Shield
 */

/obj/item/shield/buckler/energy
	name = "energy combat shield"
	desc = "A shield capable of stopping most projectile and melee attacks. It can be retracted, expanded, and stored anywhere."
	icon = 'icons/obj/weapons.dmi'
	icon_state = "eshield0" // eshield1 for expanded
	item_state = "eshield0"
	flags = CONDUCT
	force = 3
	throwforce = 5
	throw_speed = 1
	throw_range = 4
	w_class = ITEM_SIZE_SMALL
	origin_tech = list(TECH_MATERIAL = 4, TECH_MAGNET = 3, TECH_COVERT = 4)
	attack_verb = list("shoved", "bashed")
	var/active = 0
	base_block_chance = 35
	shield_difficulty = 70
	shield_integrity = 200

/obj/item/shield/buckler/energy/handle_shield(mob/user)
	if(!active)
		return 0 //turn it on first!
	. = ..()

	if(.)
		var/datum/effect/effect/system/spark_spread/spark_system = new
		spark_system.set_up(5, 0, user.loc)
		spark_system.start()
		playsound(user.loc, 'sound/weapons/blade1.ogg', 50, 1)

/obj/item/shield/buckler/energy/attack_self(mob/living/user as mob)
/*	if ((CLUMSY in user.mutations) && prob(50))
		to_chat(user, span_warning("You beat yourself in the head with [src]."))
		user.take_organ_damage(5)
	active = !active
*/
	if(!active)
		active = TRUE
		force = WEAPON_FORCE_PAINFUL
		update_icon()
		w_class = ITEM_SIZE_BULKY
		playsound(user, 'sound/weapons/saberon.ogg', 50, 1)
		to_chat(user, span_notice("\The [src] is now active."))

	else
		active = FALSE
		force = 3
		update_icon()
		w_class = ITEM_SIZE_TINY
		playsound(user, 'sound/weapons/saberoff.ogg', 50, 1)
		to_chat(user, span_notice("\The [src] can now be concealed."))
		if(ishuman(user) && user.blocking)
			astype(user, /mob/living/carbon/human)?.stop_blocking()

	add_fingerprint(user)
	return

/obj/item/shield/buckler/energy/update_icon()
	icon_state = "eshield[active]"
	item_state = "eshield[active]"
	update_wear_icon()
	if(active)
		set_light(1.5, 1.5, COLOR_LIGHTING_BLUE_BRIGHT)
	else
		set_light(0)

