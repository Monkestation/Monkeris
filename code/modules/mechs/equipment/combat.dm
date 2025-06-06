/obj/item/gun/energy/get_hardpoint_maptext()
	return "[round(cell.charge / charge_cost)]/[round(cell.maxcharge / charge_cost)]"

/obj/item/gun/energy/get_hardpoint_status_value()
	var/obj/item/cell/C = get_cell()
	if(istype(C))
		return C.charge/C.maxcharge
	return null

/obj/item/tool/sword/mech
	name = "mech blade"
	desc = "What are you standing around staring at this for? You shouldn't be seeing this..."
	icon = 'icons/obj/weapons.dmi'
	icon_state = "claymore"
	item_state = "claymore"
	matter = list(MATERIAL_PLASTEEL = 15, MATERIAL_PLASTIC = 5)
	w_class = ITEM_SIZE_BULKY
	worksound = WORKSOUND_HARD_SLASH
	wielded = TRUE
	canremove = FALSE
	// Its Big
	armor_divisor = ARMOR_PEN_DEEP
	tool_qualities = list(QUALITY_CUTTING = 30, QUALITY_HAMMERING = 20, QUALITY_PRYING = 15)
	// its mech sized!!!!!
	structure_damage_factor = STRUCTURE_DAMAGE_BLUNT
	spawn_blacklisted = TRUE

#define OVERKEY_BLADE "blade_overlay"
/obj/item/mech_blade_assembly
	name = "unfinished mech blade"
	desc = "A mech-blade framework lacking a blade."
	icon_state = "mech_blade_assembly"
	matter = list(MATERIAL_PLASTEEL = 15, MATERIAL_PLASTIC = 10)
	var/sharpeners = 0
	var/material/blade_mat = null

/obj/item/mech_blade_assembly/Initialize()
	. = ..()
	AddComponent(/datum/component/overlay_manager)

/obj/item/mech_blade_assembly/examine(mob/user, extra_description = "")
	if(sharpeners)
		extra_description += span_notice("\nIt requires [sharpeners] sharpeners to be sharp enough.")
	else
		extra_description += span_notice("\nIt needs 5 sheets of a metal inserted to form the basic blade.")
	extra_description += span_notice("\nUse a wrench to make this mountable. This is not reversible.")
	..(user, extra_description)

/obj/item/mech_blade_assembly/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/tool_upgrade/productivity/whetstone))
		if(sharpeners)
			user.remove_from_mob(I, TRUE)
			I.forceMove(src)
			to_chat(user ,span_notice("You sharpen the blade on \the [src]."))
			sharpeners--
		return
	if(istool(I))
		var/obj/item/tool/thing = I
		if(thing.has_quality(QUALITY_BOLT_TURNING))
			if(!blade_mat)
				to_chat(user, span_notice("You can't tighten the blade-mechanism onto a blade of air!"))
				return
			to_chat(user, span_notice("You start tightening \the [src] onto the blade made of [blade_mat.display_name]."))
			if(I.use_tool(user, src, WORKTIME_SLOW, QUALITY_BOLT_TURNING, 0, STAT_MEC, 150))
				if(QDELETED(src))
					return
				to_chat(user, span_notice("You tighten the blade on \the [src], creating a mech-mountable blade."))
				var/obj/item/mech_equipment/mounted_system/sword/le_mech_comp = new /obj/item/mech_equipment/mounted_system/sword(get_turf(src))
				var/obj/item/mech_equipment/mounted_system/sword/le_mech_sword = le_mech_comp.holding
				// DULL BLADE gets DULL DAMAGE
				le_mech_sword.force = max(0,(blade_mat.hardness - 35 * sharpeners)/2)
				le_mech_sword.matter = list(blade_mat.name = 5)
				le_mech_comp.material_color = blade_mat.icon_colour
				qdel(src)
				return

	if(!istype(I, /obj/item/stack/material))
		return ..()
	if(blade_mat)
		to_chat(user, span_notice("There is already a blade formed! You can remove it by using it in hand."))
		return
	var/obj/item/stack/material/mat = I
	if(!mat.material.hardness)
		to_chat(user, span_notice("This material can't be sharpened!"))
		return
	if(mat.can_use(5))
		if(mat.use(5))
			to_chat(user , span_notice("You insert 5 sheets of \the [mat] into \the [src], creating a blade requiring [round((mat.material.hardness)/60)] sharpeners to not be dull."))
			blade_mat = mat.material
			sharpeners = round(blade_mat.hardness/60)
			matter[mat.material.name]+= 5
			update_icon()

/obj/item/mech_blade_assembly/attack_self(mob/user)
	if(blade_mat)
		to_chat(user, span_notice("You start removing the blade from \the [src]."))
		if(do_after(user, 3 SECONDS, src, TRUE, TRUE))
			// No duping!!
			if(!blade_mat)
				to_chat(user, span_notice("There is no material left to remove from \the [src]."))
				return
			to_chat(user, span_notice("You remove 5 sheets of [blade_mat.display_name] from \the [src]'s blade attachment point."))
			matter[blade_mat.name]-= 5
			var/obj/item/stack/material/mat_stack = new blade_mat.stack_type(get_turf(user))
			mat_stack.amount = 5
			blade_mat = null
			update_icon()

/obj/item/mech_blade_assembly/update_icon()
	. = ..()
	var/datum/component/overlay_manager/thing = GetComponent(/datum/component/overlay_manager)
	if(thing)
		thing.removeOverlay(OVERKEY_BLADE)
		if(blade_mat)
			var/mutable_appearance/overlay = mutable_appearance(src.icon, "[icon_state]_blade")
			overlay.color = blade_mat.icon_colour
			thing.addOverlay(OVERKEY_BLADE, overlay)

#undef OVERKEY_BLADE

/obj/item/mech_equipment/mounted_system/sword
	name = "\improper NT \"Warborne\" sword"
	desc = "An exosuit-mounted sword. Handle with care."
	icon_state = "mech_blade"
	holding_type = /obj/item/tool/sword/mech
	restricted_hardpoints = list(HARDPOINT_LEFT_HAND, HARDPOINT_RIGHT_HAND)
	matter = list(MATERIAL_PLASTEEL = 15, MATERIAL_PLASTIC = 10)
	origin_tech = list(TECH_COMBAT = 4, TECH_MAGNET = 3)
	spawn_blacklisted = TRUE
	var/material_color = null
	var/obj/visual_bluff = null

/// Spawnable subtypes that are findable in maintenance
/// Plasteel - balanced
/// Osmium - plasteel+
/// Cardboard - meme level with 0 damage
/// Mettalic hydrogen - great

/obj/item/mech_equipment/mounted_system/sword/plasteel
	desc = "An exosuit-mounted sword, with a blade made of plasteel. Handle with care."
	spawn_blacklisted = FALSE
	rarity_value = 70
	spawn_tags = SPAWN_TAG_MECH_QUIPMENT

/obj/item/mech_equipment/mounted_system/sword/plasteel/Initialize()
	var/material/mat_data = get_material_by_name(MATERIAL_PLASTEEL)
	material_color = mat_data.icon_colour
	. = ..()
	holding.force = max(0,(mat_data.hardness/2))
	holding.matter = list(MATERIAL_PLASTEEL = 5)


/obj/item/mech_equipment/mounted_system/sword/osmium
	desc = "An exosuit-mounted sword, with a blade made of osmium. Handle with care."
	spawn_blacklisted = FALSE
	rarity_value = 90
	spawn_tags = SPAWN_TAG_MECH_QUIPMENT

/obj/item/mech_equipment/mounted_system/sword/osmium/Initialize()
	var/material/mat_data = get_material_by_name(MATERIAL_OSMIUM)
	material_color = mat_data.icon_colour
	. = ..()
	holding.force = max(0,(mat_data.hardness/2))
	holding.matter = list(MATERIAL_OSMIUM = 5)

/obj/item/mech_equipment/mounted_system/sword/cardboard
	desc = "An exosuit-mounted sword, with a blade made of ... cardboard? Handle with recklessness."
	spawn_blacklisted = FALSE
	rarity_value = 50
	spawn_tags = SPAWN_TAG_MECH_QUIPMENT

/obj/item/mech_equipment/mounted_system/sword/cardboard/Initialize()
	var/material/mat_data = get_material_by_name(MATERIAL_CARDBOARD)
	material_color = mat_data.icon_colour
	. = ..()
	holding.force = max(0,(mat_data.hardness/2))
	holding.matter = list(MATERIAL_CARDBOARD = 5)

/obj/item/mech_equipment/mounted_system/sword/myhydrogen
	desc = "An exosuit-mounted sword, with a blade made of metallic hydrogen, you can hear air itself being cut. Handle with care."
	spawn_blacklisted = FALSE
	rarity_value = 160
	spawn_tags = SPAWN_TAG_MECH_QUIPMENT

/obj/item/mech_equipment/mounted_system/sword/myhydrogen/Initialize()
	var/material/mat_data = get_material_by_name(MATERIAL_MHYDROGEN)
	material_color = mat_data.icon_colour
	. = ..()
	holding.force = max(0,(mat_data.hardness/2))
	holding.matter = list(MATERIAL_MHYDROGEN = 5)

/obj/item/mech_equipment/mounted_system/sword/Initialize()
	. = ..()
	visual_bluff = new /obj(null)
	visual_bluff.icon = MECH_WEAPON_OVERLAYS_ICON
	visual_bluff.vis_flags = VIS_INHERIT_DIR | VIS_INHERIT_PLANE | VIS_INHERIT_ID | VIS_INHERIT_LAYER
	visual_bluff.color = material_color
	// so it swings gloriously
	var/obj/item/tool/sword/mech/holdin = holding
	holdin.wielded = TRUE
	// i want the desc from the blade itself >:(
	SetName(initial(name))
	desc = initial(desc)

/obj/item/mech_equipment/mounted_system/sword/Destroy()
	if(ismech(loc))
		var/mob/living/exosuit/mech = loc
		mech.vis_contents.Remove(visual_bluff)
	QDEL_NULL(visual_bluff)
	. = ..()

/obj/item/mech_equipment/mounted_system/sword/installed(mob/living/exosuit/_owner, hardpoint)
	. = ..()
	visual_bluff.icon_state = "mech_blade_knife_[hardpoint]"
	_owner.vis_contents.Add(visual_bluff)

/obj/item/mech_equipment/mounted_system/sword/uninstalled()

	owner.vis_contents.Remove(visual_bluff)
	update_icon()
	..()

/obj/item/mech_equipment/mounted_system/sword/update_icon(hardpoint)
	. = ..()
	visual_bluff.icon_state = "mech_blade_knife_[get_hardpoint()]"

/obj/item/mech_equipment/mounted_system/sword/afterattack(atom/target, mob/living/user, inrange, params)
	. = ..()
	if(. && holding && inrange)
		if(!params)
			params = list()
		params["mech"] = TRUE
		params["mech_hand"] = get_hardpoint() == HARDPOINT_LEFT_HAND ? slot_l_hand : slot_r_hand
		holding.swing_attack(target, user, params)

/obj/item/mech_equipment/mounted_system/taser
	name = "mounted taser carbine"
	desc = "A dual fire mode taser system connected to the exosuit's targetting system."
	icon_state = "mech_taser"
	holding_type = /obj/item/gun/energy/taser/mounted/mech
	restricted_hardpoints = list(HARDPOINT_LEFT_HAND, HARDPOINT_RIGHT_HAND)
	restricted_software = list(MECH_SOFTWARE_WEAPONS)
	origin_tech = list(TECH_COMBAT = 3, TECH_MAGNET = 3)
	matter = list(MATERIAL_PLASTEEL = 25, MATERIAL_PLASTIC = 10, MATERIAL_SILVER = 10)

/obj/item/gun/energy/taser/mounted/mech
	restrict_safety = TRUE
	twohanded = FALSE
	charge_cost = MECH_WEAPON_POWER_COST * 0.5 // Pew pew pew pew pew pew pew pew pew pew
	burst = 3
	burst_delay = 1 // PEW PEW PEW
	init_recoil = LMG_RECOIL(1)
	matter = list()
	cell_type = /obj/item/cell/medium/mech

/obj/item/mech_equipment/mounted_system/taser/ion
	name = "mounted ion rifle"
	desc = "An exosuit-mounted ion rifle. Handle with care."
	icon_state = "mech_ionrifle"
	holding_type = /obj/item/gun/energy/ionrifle/mounted/mech
	matter = list(MATERIAL_PLASTEEL = 25, MATERIAL_PLASTIC = 10, MATERIAL_SILVER = 10)
	origin_tech = list(TECH_COMBAT = 2, TECH_MAGNET = 4)

/obj/item/gun/energy/ionrifle/mounted
	bad_type = /obj/item/gun/energy/ionrifle/mounted
	spawn_tags = null

/obj/item/gun/energy/ionrifle/mounted/mech
	use_external_power = TRUE
	restrict_safety = TRUE
	self_recharge = TRUE
	twohanded = FALSE
	charge_cost = MECH_WEAPON_POWER_COST * 0.75
	cell_type = /obj/item/cell/medium/mech
	matter = list()

/obj/item/mech_equipment/mounted_system/taser/laser
	name = "\improper CH-PS \"Immolator\" laser"
	desc = "An exosuit-mounted laser rifle. Handle with care."
	icon_state = "mech_lasercarbine"
	holding_type = /obj/item/gun/energy/laser/mounted/mech
	matter = list(MATERIAL_PLASTEEL = 25, MATERIAL_PLASTIC = 10, MATERIAL_SILVER = 10)
	origin_tech = list(TECH_COMBAT = 4, TECH_MAGNET = 3)

/obj/item/gun/energy/laser/mounted
	bad_type = /obj/item/gun/energy/laser/mounted/mech
	spawn_tags = null

/obj/item/gun/energy/laser/mounted/mech
	name = "\improper CH-PS \"Immolator\" laser"
	use_external_power = TRUE
	restrict_safety = TRUE
	self_recharge = TRUE
	twohanded = FALSE
	charge_cost = MECH_WEAPON_POWER_COST
	burst = 2
	init_firemodes = list()
	burst_delay = 1.5
	matter = list()
	cell_type = /obj/item/cell/medium/mech

/obj/item/mech_equipment/mounted_system/taser/plasma
	name = "mounted plasma cutter"
	desc = "An industrial plasma cutter mounted onto the chassis of the mech. "
	icon_state = "mech_plasma" //TODO: Make a new sprite that doesn't get sec called on you.
	holding_type = /obj/item/gun/energy/plasmacutter/mounted/mech
	restricted_hardpoints = list(HARDPOINT_LEFT_HAND, HARDPOINT_RIGHT_HAND, HARDPOINT_LEFT_SHOULDER, HARDPOINT_RIGHT_SHOULDER)
	origin_tech = list(TECH_MATERIAL = 4, TECH_PLASMA = 4, TECH_ENGINEERING = 6, TECH_COMBAT = 3)
	matter = list(MATERIAL_STEEL = 20, MATERIAL_PLASTEEL = 5)
	spawn_tags = SPAWN_MECH_QUIPMENT
	spawn_blacklisted = FALSE
	rarity_value = 60

/obj/item/gun/energy/plasmacutter
	bad_type = /obj/item/gun/energy/plasmacutter

/obj/item/gun/energy/plasmacutter/mounted
	bad_type = /obj/item/gun/energy/plasmacutter/mounted
	spawn_tags = null

/obj/item/gun/energy/plasmacutter/mounted/mech
	use_external_power = TRUE
	restrict_safety = TRUE
	twohanded = FALSE
	self_recharge = TRUE
	charge_cost = MECH_WEAPON_POWER_COST * 1.5
	projectile_type = /obj/item/projectile/beam/cutter
	matter = list()
	cell_type = /obj/item/cell/medium/mech

/obj/item/gun/projectile/get_hardpoint_maptext()
	if(ammo_magazine)
		return "[get_ammo()]/[ammo_magazine.max_ammo]"
	else
		return "NO MAG"

/obj/item/gun/projectile/get_hardpoint_status_value()
	if(ammo_magazine)
		return get_ammo()/ammo_magazine.max_ammo
	return null

#define LOADING_BOX 1
#define LOADING_SINGLE 2
/// This will always assume the gun loads in single mode, removing bullets from magazines and then loading them in
#define LOADING_FLEXIBLE 3

/obj/item/mech_equipment/mounted_system/ballistic
	bad_type = /obj/item/mech_equipment/mounted_system/ballistic
	var/list/obj/item/ammo_magazine/ammunition_storage
	var/accepted_types = list()
	var/ammunition_storage_limit = 1
	var/loading_type = LOADING_BOX

/obj/item/mech_equipment/mounted_system/ballistic/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/ammo_magazine) || istype(I, /obj/item/ammo_casing))
		switch(loadMagazine(I,user))
			if(-1)
				to_chat(user, span_notice("\The [src] does not accept this type of magazine."))
			if(0)
				to_chat(user, span_notice("\The [src] has no slots left in its ammunition storage."))
			if(1)
				to_chat(user, span_notice("You load \the [I] into \the [src]."))
		return
	else
		. = ..()

/obj/item/mech_equipment/mounted_system/ballistic/attack_self(mob/user)
	var/list/mag_removal = list()
	for(var/obj/item/ammo_magazine/mag in ammunition_storage)
		mag_removal["[mag] - [length(mag.stored_ammo)]"] = mag
	mag_removal["All mags"] = null
	var/obj/item/to_remove = null

	if(length(mag_removal) > 1)
		var/choice = input(user, "Select magazine to remove from \the [src]", "Magazine removal", 0) as null|anything in mag_removal
		if(choice == "All mags")
			for(var/slot in 1 to ammunition_storage_limit)
				var/obj/mag = unloadMagazine(slot)
				if(mag)
					mag.forceMove(get_turf(src))
		else
			to_remove = mag_removal[choice]
	else if(length(mag_removal))
		to_remove = mag_removal[mag_removal[1]]
	if(to_remove)
		ammunition_storage[getMagazineSlot(to_remove)] = null
		to_remove.forceMove(get_turf(user))



/obj/item/mech_equipment/mounted_system/ballistic/examine(mob/user, extra_description = "")
	extra_description += span_notice("Ammunition can be inserted inside, or removed by self-attacking.")
	..(user, extra_description)

/obj/item/mech_equipment/mounted_system/ballistic/Initialize()
	. = ..()
	ammunition_storage = new /list(ammunition_storage_limit)

/obj/item/mech_equipment/mounted_system/ballistic/proc/getLoadedMagazine()
	switch(loading_type)
		if(LOADING_FLEXIBLE)
			for(var/obj/item/ammo_magazine/mag in ammunition_storage)
				if(length(mag.stored_ammo))
					ammunition_storage[getMagazineSlot(mag)] = null
					return mag
			for(var/obj/item/ammo_casing/case in ammunition_storage)
				if(case.BB)
					ammunition_storage[getMagazineSlot(case)] = null
					return case.BB
		if(LOADING_BOX)
			for(var/obj/item/ammo_magazine/mag in ammunition_storage)
				if(length(mag.stored_ammo))
					ammunition_storage[getMagazineSlot(mag)] = null
					return mag
		if(LOADING_SINGLE)
			for(var/obj/item/ammo_casing/case in ammunition_storage)
				if(case.BB)
					ammunition_storage[getMagazineSlot(case)] = null
					return case.BB
	return null

/obj/item/mech_equipment/mounted_system/ballistic/proc/getPartialAmmunition()
	switch(loading_type)
		if(LOADING_SINGLE)
			for(var/obj/item/ammo_casing/case in ammunition_storage)
				if(case.amount != case.maxamount)
					return case
			return null
		if(LOADING_BOX)
			for(var/obj/item/ammo_magazine/mag in ammunition_storage)
				if(length(mag.stored_ammo) != mag.max_ammo)
					return mag
			return null
		if(LOADING_FLEXIBLE)
			for(var/obj/item/ammo_magazine/mag in ammunition_storage)
				if(length(mag.stored_ammo) != mag.max_ammo)
					return mag
			for(var/obj/item/ammo_casing/case in ammunition_storage)
				if(case.amount != case.maxamount)
					return case
			return null

/obj/item/mech_equipment/mounted_system/ballistic/proc/getMagazineSlot(obj/magazine)
	for(var/i in 1 to ammunition_storage_limit)
		if(ammunition_storage[i] == magazine)
			return i
	return 0

/obj/item/mech_equipment/mounted_system/ballistic/proc/getEmptySlot()
	for(var/i in 1 to ammunition_storage_limit)
		if(ammunition_storage[i] != null)
			continue
		return i
	return 0

/// -1 for wrong type , 0 for no slot , 1 for succes loading.
/obj/item/mech_equipment/mounted_system/ballistic/proc/loadMagazine(obj/item/loadable, mob/living/user)
	var/obj/item/gun/projectile/wep = holding
	var/chosen_loading_type = null
	if(loading_type == LOADING_FLEXIBLE)
		if(istype(loadable, /obj/item/ammo_magazine))
			chosen_loading_type = LOADING_BOX
		else if(istype(loadable, /obj/item/ammo_casing))
			chosen_loading_type = LOADING_SINGLE
	else if(loading_type == LOADING_BOX)
		if(istype(loadable, /obj/item/ammo_magazine))
			chosen_loading_type = LOADING_BOX
	else if(loading_type == LOADING_SINGLE)
		if(istype(loadable, /obj/item/ammo_casing))
			chosen_loading_type = LOADING_SINGLE

	switch(chosen_loading_type)
		if(LOADING_BOX)
			var/obj/item/ammo_magazine/magazine = loadable
			if(wep.caliber != magazine.caliber)
				return -1
			var/valid = FALSE
			// so we can also acccept HV variants , etc.
			for(var/ammo_type in accepted_types)
				if(magazine.type in typesof(ammo_type))
					valid = TRUE
			if(!valid)
				return -1
			var/slot = getEmptySlot()
			if(!slot)
				var/partial_loaded = FALSE
				while(length(magazine.stored_ammo))
					var/obj/item/ammo_magazine/partial_mag = getPartialAmmunition()
					if(!partial_mag)
						break
					partial_loaded = TRUE
					partial_mag.attackby(magazine, user)
				return partial_loaded ? 2 : 0
			user.remove_from_mob(magazine)
			magazine.forceMove(src)
			ammunition_storage[slot] = magazine
			return 1
		if(LOADING_SINGLE)
			var/obj/item/ammo_casing/bullet = loadable
			if(wep.caliber != bullet.caliber)
				return -1
			var/valid = FALSE
			// so we can also acccept HV variants , etc.
			for(var/ammo_type in accepted_types)
				if(bullet.type in typesof(ammo_type))
					valid = TRUE
			if(!valid)
				return -1
			var/slot = getEmptySlot()
			if(!slot)
				var/partial_loaded = FALSE
				while(!QDELETED(bullet) && bullet.amount)
					var/obj/item/ammo_casing/partial_bullet = getPartialAmmunition()
					if(!partial_bullet)
						break
					partial_loaded = TRUE
					partial_bullet.attackby(bullet, user)
				return partial_loaded ? 2 : 0
			user.remove_from_mob(bullet)
			bullet.forceMove(src)
			ammunition_storage[slot] = bullet
			return 1
		else
			return -1



/obj/item/mech_equipment/mounted_system/ballistic/proc/unloadMagazine(slot)
	if(!ammunition_storage[slot])
		return FALSE
	var/obj/mag = ammunition_storage[slot]
	ammunition_storage[slot] = null
	return mag

/obj/item/mech_equipment/mounted_system/ballistic/proc/reloadGun()
	var/obj/item/gun/projectile/wep = holding
	switch(loading_type)
		if(LOADING_BOX)
			var/slot = getEmptySlot()
			var/obj/ammo_mag = wep.ammo_magazine
			if(ammo_mag)
				ammo_mag.update_icon()
				if(slot)
					ammunition_storage[slot] = ammo_mag
				else
					ammo_mag.forceMove(get_turf(src))
			// this returns null if we cant get a mag anyway
			wep.ammo_magazine = getLoadedMagazine()
			// Guns reset their firemode on reload
			wep.update_firemode()
			// wheter we succesfully reloaded or not
			return wep.ammo_magazine ? TRUE : FALSE
		if(LOADING_SINGLE)
			var/initial_shells = length(wep.loaded)
			while(length(wep.loaded) < wep.max_shells)
				var/obj/item/ammo_casing/bullet = getLoadedMagazine()
				if(!bullet)
					break
				while(bullet.amount > 1)
					// so we dupe
					var/obj/item/ammo_casing/bullet_dupe = new bullet.type(bullet)
					bullet_dupe.forceMove(wep)
					wep.loaded.Insert(1, bullet_dupe)
				if(bullet.amount == 1 && length(wep.loaded) < wep.max_shells)
					bullet.forceMove(wep)
					wep.loaded.Insert(1, bullet)
				if(!isgun(bullet.loc))
					var/empty_slot = getEmptySlot()
					if(!empty_slot)
						bullet.forceMove(get_turf(src))
					else
						ammunition_storage[empty_slot] = bullet
			return length(wep.loaded) == wep.max_shells ? 1 : (length(wep.loaded) > initial_shells ? 2 : 0 )
		if(LOADING_FLEXIBLE)
			var/initial_shells = length(wep.loaded)
			while(length(wep.loaded) < wep.max_shells)
				var/obj/ammo = getLoadedMagazine()
				if(!ammo)
					break
				if(istype(ammo, /obj/item/ammo_magazine))
					var/obj/item/ammo_magazine/mag = ammo
					while(length(mag.stored_ammo) && length(wep.loaded) < wep.max_shells)
						var/obj/item/ammo_casing/bullet = mag.removeCasing()
						if(!bullet)
							break
						bullet.forceMove(wep)
						wep.loaded.Insert(1, bullet)
					var/slot = getEmptySlot()
					if(slot)
						ammunition_storage[slot] = mag
					else
						mag.forceMove(get_turf(src))
				else
					var/obj/item/ammo_casing/bullet = ammo
					while(bullet.amount > 1)
						// so we dupe
						var/obj/item/ammo_casing/bullet_dupe = new bullet.type(bullet)
						bullet_dupe.forceMove(wep)
						wep.loaded.Insert(1, bullet_dupe)
						if(bullet.amount == 1 && length(wep.loaded) < wep.max_shells)
							bullet.forceMove(wep)
							wep.loaded.Insert(1, bullet)
						if(!isgun(bullet.loc))
							var/empty_slot = getEmptySlot()
							if(!empty_slot)
								bullet.forceMove(get_turf(src))
							else
								ammunition_storage[empty_slot] = bullet

			return length(wep.loaded) == wep.max_shells ? 1 : (length(wep.loaded) > initial_shells ? 2 : 0 )




/obj/item/mech_equipment/mounted_system/ballistic/on_select()
	var/obj/item/gun/wep = holding
	wep.update_firemode()

/obj/item/mech_equipment/mounted_system/ballistic/on_unselect()
	var/obj/item/gun/wep = holding
	wep.update_firemode()

/obj/item/mech_equipment/mounted_system/ballistic/smg
	name = "ML \"C-35R\""
	desc = "A upgraded version of the reverse engineered CR20, retrofitted for mech use. Fires in full auto 600 RPM and has modest accuracy, reloads slowly. Takes in packets of .35 or SMG magazines."
	icon_state = "mech_ballistic2"
	holding_type = /obj/item/gun/projectile/automatic/c20r/mech
	restricted_hardpoints = list(HARDPOINT_LEFT_HAND, HARDPOINT_RIGHT_HAND)
	restricted_software = list(MECH_SOFTWARE_WEAPONS)
	origin_tech = list(TECH_COMBAT = 3, TECH_MAGNET = 2)
	matter = list(MATERIAL_PLASTEEL = 35, MATERIAL_STEEL = 10, MATERIAL_SILVER = 3) // more expensive
	spawn_tags = SPAWN_MECH_QUIPMENT
	spawn_blacklisted = FALSE
	rarity_value = 90
	ammunition_storage_limit = 3
	accepted_types = list(
		/obj/item/ammo_magazine/ammobox/pistol,
		/obj/item/ammo_magazine/smg
	)

/obj/item/gun/projectile/automatic/c20r/mech
	name = 	"ML \"C-35R\""
	restrict_safety = TRUE
	safety = FALSE
	twohanded = FALSE
	init_firemodes = list(
		FULL_AUTO_600
		)
	spawn_blacklisted = TRUE
	spawn_tags = null
	init_recoil = list(0.3, 1, 0.3)
	matter = list()
	var/reloading = FALSE

/obj/item/mech_equipment/mounted_system/ballistic/shotgun
	// named after Srgt Robert Draper's nickname from The Expanse book series
	name = "ML \"Bobby\""
	desc = "A brutal mech-mounted shotgun with an automatic cocking mechanism. Fires in single-shot, cocks itself fast. Takes in shotgun ammo boxes, packets or shell bunches."
	icon_state = "mech_ballistic1"
	holding_type = /obj/item/gun/projectile/shotgun/pump/mech
	restricted_hardpoints = list(HARDPOINT_LEFT_HAND, HARDPOINT_RIGHT_HAND)
	restricted_software = list(MECH_SOFTWARE_WEAPONS)
	spawn_tags = SPAWN_MECH_QUIPMENT
	spawn_blacklisted = FALSE
	rarity_value = 75
	origin_tech = list(TECH_COMBAT = 3, TECH_MAGNET = 2)
	matter = list(MATERIAL_PLASTEEL = 25, MATERIAL_STEEL = 20)
	loading_type = LOADING_FLEXIBLE
	ammunition_storage_limit = 4
	accepted_types = list(
		/obj/item/ammo_magazine/ammobox/shotgun,
		/obj/item/ammo_magazine/ammobox/shotgun_small,
		/obj/item/ammo_casing/shotgun
	)

/obj/item/gun/projectile/shotgun/pump/mech
	name = "ML \"Bobby\""
	restrict_safety = TRUE
	safety = FALSE
	max_shells = 12
	twohanded = FALSE
	wielded = TRUE
	spawn_blacklisted = TRUE
	spawn_tags = null
	matter = list()
	var/loading = FALSE

/obj/item/gun/projectile/shotgun/pump/mech/pump(mob/M)
	..()
	playsound(get_turf(M), 'sound/weapons/shotgunpump.ogg', 120, 1)

/obj/item/gun/projectile/shotgun/pump/mech/get_hardpoint_maptext()
	return "[length(loaded) + (chambered ? 1 : 0)] / [max_shells]"

/obj/item/gun/projectile/shotgun/pump/mech/afterattack(atom/A, mob/living/user)
	if(loading)
		to_chat(user, span_notice("\The [src] is currently reloading!"))
		return
	..()
	pump(user)
	if(!chambered)
		to_chat(user, span_notice("\The [src] has run out of shells! Reloading..."))
		loading = TRUE
		var/obj/item/mech_equipment/mounted_system/ballistic/hold = loc
		spawn(8 SECONDS)
			if(hold.reloadGun())
				to_chat(user, span_notice("\The [src]'s chamber has been refilled with shells."))
			else
				to_chat(user, span_danger("\The [src]'s failed to load!"))
			loading = FALSE
			pump(user)

/obj/item/gun/projectile/automatic/c20r/mech/afterattack(atom/A, mob/living/user)
	. = ..()
	if(!ammo_magazine || (ammo_magazine && !length(ammo_magazine.stored_ammo)))
		if(reloading)
			return
		var/obj/item/mech_equipment/mounted_system/ballistic/hold = loc
		to_chat(user, span_notice("\The [src] is now reloading!"))
		reloading = TRUE
		spawn(6 SECONDS)
			if(hold.reloadGun())
				to_chat(user, span_notice("\The [src]'s magazine has been reloaded."))
			else
				to_chat(user, span_danger("\The [src]'s failed to load!"))
			reloading = FALSE

/obj/item/mech_equipment/mounted_system/ballistic/pk
	name = "SA \"VJP\""
	desc = "A reverse engineered Pulemyot Kalashnikova fitted for mech use. Fires in full auto 400 and has horrible accuracy. Takes in .30 ammunition boxes"
	icon_state = "mech_pk"
	holding_type = /obj/item/gun/projectile/automatic/lmg/pk/mounted/mech
	restricted_hardpoints = list(HARDPOINT_LEFT_HAND, HARDPOINT_RIGHT_HAND)
	restricted_software = list(MECH_SOFTWARE_WEAPONS)
	origin_tech = list(TECH_COMBAT = 5, TECH_MAGNET = 3)
	matter = list(MATERIAL_PLASTEEL = 50, MATERIAL_STEEL = 10)
	spawn_tags = SPAWN_MECH_QUIPMENT
	spawn_blacklisted = FALSE
	rarity_value = 110
	ammunition_storage_limit = 2
	accepted_types = list(
		/obj/item/ammo_magazine/ammobox/lrifle
	)

/obj/item/mech_equipment/mounted_system/ballistic/pk/on_select()
	..()
	var/obj/item/gun/projectile/automatic/lmg/pk/mounted/mech/wep = holding
	wep.cocked = FALSE

/obj/item/mech_equipment/mounted_system/ballistic/pk/on_unselect()
	..()
	var/obj/item/gun/projectile/automatic/lmg/pk/mounted/mech/wep = holding
	wep.cocked = FALSE


/obj/item/gun/projectile/automatic/lmg/pk/mounted
	bad_type = /obj/item/gun/projectile/automatic/lmg/pk/mounted

/obj/item/gun/projectile/automatic/lmg/pk/mounted/mech
	name = 	"SA \"VJP\""
	desc = "A reverse engineered Pulemyot Kalashnikova fitted for mech use. Fires .30 , full auto. Slightly inaccurate, but packs quite a punch."
	restrict_safety = TRUE
	safety = FALSE
	twohanded = FALSE
	init_firemodes = list(
		FULL_AUTO_400
		)
	spawn_tags = null
	spawn_blacklisted = TRUE
	matter = list()
	magazine_type = /obj/item/ammo_magazine/lrifle/pk/mech
	// Used for dramatic purpose.
	var/cocked = FALSE
	var/reloading = FALSE

/obj/item/gun/projectile/automatic/lmg/pk/mounted/mech/afterattack(atom/A, mob/living/user)
	// Dramatic gun cocking!
	if(!cocked)
		playsound(src.loc, 'sound/weapons/guns/interact/lmg_cock.ogg', 300, 1)
		to_chat(user, span_notice("You chamber the [src], preparing it for full-automatic fire."))
		// uh oh
		visible_message(get_turf(src), span_danger("The mech chambers the [src], preparing it for full automatic fire!"))
		cocked = TRUE
		safety = FALSE
		return
	..()
	if((ammo_magazine && ammo_magazine.stored_ammo && !ammo_magazine.stored_ammo.len && !reloading) || (!ammo_magazine && !reloading))
		reloading = TRUE
		playsound(src.loc, 'sound/weapons/guns/interact/lmg_open.ogg', 100, 1)
		var/obj/item/mech_equipment/mounted_system/ballistic/hold = loc
		to_chat(user, span_notice("\The [src]'s magazine has run out. Reloading..."))
		spawn(1 SECOND)
			playsound(src.loc, 'sound/weapons/guns/interact/lmg_cock.ogg', 150, 1)
		spawn(2 SECOND)
			playsound(src.loc, 'sound/weapons/guns/interact/lmg_close.ogg', 100, 1)
			if(hold.reloadGun())
				to_chat(user, span_notice("\The [src]'s magazine has been reloaded."))
			else
				to_chat(user, span_danger("\The [src]'s failed to load!"))
			reloading = FALSE
			// recock your gun
			cocked = FALSE
			// not being able to fire removes the CH(done in reloadGun now)

/obj/item/mech_equipment/mounted_system/mace
	name = "\improper NT \"Warhead\" mace"
	desc = "An exosuit-mounted mace. Doubles as a flail. Handle with care."
	icon_state = "mech_mace"
	holding_type = /obj/item/tool/hammer/mace/mech
	restricted_hardpoints = list(HARDPOINT_LEFT_HAND, HARDPOINT_RIGHT_HAND)
	matter = list(MATERIAL_PLASTEEL = 15, MATERIAL_STEEL = 10)
	origin_tech = list(TECH_COMBAT = 4, TECH_MAGNET = 3)

/obj/item/mech_equipment/mounted_system/attack_self(mob/user)
	. = ..()
	owner.update_icon()

/obj/item/mech_equipment/mounted_system/mace/Initialize()
	. = ..()
	var/obj/item/tool/hammer/mace/mech/holdin = holding
	holdin.wielded = TRUE

/obj/item/mech_equipment/mounted_system/mace/get_overlay_state()
	var/obj/item/tool/hammer/mace/mech/mace = holding
	if(mace.flail_mode)
		icon_state = "mech_mace_flail"
	else
		icon_state = initial(icon_state)
	return "[icon_state][active ? "_flail" : ""]"

/obj/item/tool/hammer/mace/mech
	name = "huge mace"
	desc = "You should not see this. Contact a coder"
	matter = list(MATERIAL_PLASTEEL = 15, MATERIAL_PLASTIC = 5)
	w_class = ITEM_SIZE_BULKY
	wielded = TRUE
	canremove = FALSE
	armor_divisor = ARMOR_PEN_HALF
	tool_qualities = list(QUALITY_HAMMERING = 45) // SEE: attack_self()
	structure_damage_factor = STRUCTURE_DAMAGE_DESTRUCTIVE
	spawn_blacklisted = TRUE
	force = WEAPON_FORCE_BRUTAL
	force_wielded_multiplier = 1.5
	/// Determines what mode our mace is. FALSE is mace, TRUE is flail
	var/flail_mode = FALSE

/obj/item/tool/hammer/mace/mech/attack_self(mob/user)
	flail_mode = !flail_mode

	if(flail_mode)
		name = "huge flail"
		extended_reach = TRUE
		forced_broad_strike = TRUE
		force = WEAPON_FORCE_ROBUST
		armor_divisor = ARMOR_PEN_SHALLOW
		structure_damage_factor = STRUCTURE_DAMAGE_WEAK // lot harder to bash a wall open when your flail keeps glancing off
		tool_qualities = list()
	else
		name = initial(name)
		extended_reach = initial(extended_reach)
		forced_broad_strike = initial(forced_broad_strike)
		force = initial(force)
		armor_divisor = initial(armor_divisor)
		structure_damage_factor = initial(structure_damage_factor)
		tool_qualities = list(QUALITY_HAMMERING = 45) // initial doesn't work on lists

/obj/item/tool/hammer/mace/mech/attackby(mob/living/target, mob/user, params)
	. = ..()
	if(. && ismech(loc) && istype(target) && target != user)
		var/hit_verb = "slammed"
		var/intensity = 1
		if(ishuman(target))
			var/mob/living/carbon/human/targ = target
			if(targ.stats.getStat(STAT_VIG) > STAT_LEVEL_ADEPT)
				intensity = STAT_LEVEL_ADEPT / targ.stats.getStat(STAT_VIG)
				hit_verb = (intensity > 0.6) ? "knocked" : "grazed"
		if(flail_mode)
			target.visible_message(span_notice("[target] gets [hit_verb] by [user]'s [src]!"), span_danger("You get [hit_verb] by [user]'s [src]!"), "You hear something soft hit a metal plate!", 6)
			target.Weaken(3 * intensity)
			target.throw_at(get_turf_away_from_target_complex(target, user, 3), FLOOR(5 * intensity, 1), 1, user)
		else
			target.visible_message(span_notice("[target] gets [hit_verb] by [user]'s [src]!"), span_danger("You get [hit_verb] by [user]'s [src]!"), "You hear something soft hit a metal plate!", 6)
			target.damage_through_armor(20 * intensity, BRUTE, BP_CHEST, ARMOR_MELEE, ARMOR_PEN_HALF, src, FALSE, FALSE, 1)

/obj/item/mech_equipment/mounted_system/bfg
	name = "mounted BFG"
	icon_state = "plasmabfg"
	holding_type = /obj/item/gun/energy/plasma_mech
	restricted_software = list(MECH_SOFTWARE_ADVWEAPONS)
	restricted_hardpoints = list(HARDPOINT_LEFT_HAND, HARDPOINT_RIGHT_HAND)
	origin_tech = list(TECH_MATERIAL = 4, TECH_PLASMA = 4, TECH_ENGINEERING = 6, TECH_COMBAT = 3)
	matter = list(MATERIAL_PLASTEEL = 20, MATERIAL_STEEL = 10, MATERIAL_SILVER = 10)
	spawn_tags = SPAWN_MECH_QUIPMENT
	spawn_blacklisted = FALSE
	rarity_value = 60

/obj/item/gun/energy/plasma_mech
	name = "mounted BFG"
	desc = "A large, bulky weapon that fires a massive energy blast. It's a bit unwieldy, but it packs a punch."
	safety = FALSE
	spawn_tags = null
	spawn_blacklisted = TRUE
	use_external_power = TRUE
	self_recharge = TRUE
	restrict_safety = TRUE
	twohanded = FALSE
	charge_cost = MECH_WEAPON_POWER_COST * 5
	projectile_type = /obj/item/projectile/plasma/aoe/heat/strong/mech
	fire_sound='sound/weapons/energy/melt.ogg'
	burst = 1
	init_firemodes = list(
		WEAPON_CHARGE
		)
	fire_delay = 120
	overcharge_max = 12
	matter = list()
	cell_type = /obj/item/cell/medium/mech

#define CROSSBOW_MAX_AMOUNT 7
#define CROSSBOW_AMOUNT_OF_MATERIAL_PER_SHOT 5

/obj/item/mech_equipment/mounted_system/crossbow
	name = "mounted crossbow"
	icon_state = "crossbow"
	holding_type = /obj/item/gun/energy/crossbow_mech
	restricted_software = list(MECH_SOFTWARE_WEAPONS)
	restricted_hardpoints = list(HARDPOINT_LEFT_HAND, HARDPOINT_RIGHT_HAND)
	origin_tech = list(TECH_MATERIAL = 4, TECH_PLASMA = 4, TECH_ENGINEERING = 6, TECH_COMBAT = 3)
	matter = list(MATERIAL_STEEL = 10, MATERIAL_PLASTEEL = 15)
	spawn_tags = SPAWN_MECH_QUIPMENT
	spawn_blacklisted = FALSE
	rarity_value = 60

/obj/item/mech_equipment/mounted_system/crossbow/attackby(obj/item/I, mob/living/user, params)
	if(!istype(I, /obj/item/stack/material))
		return ..()

	var/obj/item/gun/energy/crossbow_mech/CM = holding
	if(CM.shots_amount == CROSSBOW_MAX_AMOUNT)
		to_chat(user, span_notice("\The [CM] is full!"))
		return

	var/obj/item/stack/material/mat = I
	if(!mat.material.hardness)
		to_chat(user, span_notice("\The [mat] can't be used as a bolt!"))
		return

	// precalc using amount to cut down on calculations. we use EITHER enough to fill up the slot OR the entire stack minus a remainder
	var/using = min(CROSSBOW_AMOUNT_OF_MATERIAL_PER_SHOT * (CROSSBOW_MAX_AMOUNT - CM.shots_amount), mat.amount - (mat.amount % CROSSBOW_AMOUNT_OF_MATERIAL_PER_SHOT))

	if(using == 0)
		to_chat(user, span_notice("There aren't enough sheets in \the [mat]!"))
		return

	to_chat(user , span_notice("You pack [using] sheets of \the [mat] into \the [src]."))
	CM.shots_amount += using / CROSSBOW_AMOUNT_OF_MATERIAL_PER_SHOT
	CM.calculate_damage(mat.material)
	mat.use(using)

/obj/item/gun/energy/crossbow_mech
	name = "mounted crossbow"
	desc = "A large, bulky weapon that fires a plasteel bolt. It's a bit unwieldy, but it packs a punch."
	safety = FALSE
	spawn_tags = null
	spawn_blacklisted = TRUE
	use_external_power = TRUE
	self_recharge = TRUE
	restrict_safety = TRUE
	twohanded = FALSE
	charge_cost = MECH_WEAPON_POWER_COST * 2
	projectile_type = /obj/item/projectile/bullet/bolt/mech
	fire_sound='sound/weapons/energy/melt.ogg'
	burst = 1
	init_firemodes = list(
		WEAPON_CHARGE
		)
	fire_delay = 10
	overcharge_max = 3
	matter = list()
	cell_type = /obj/item/cell/medium/mech
	var/shots_amount = 0
	var/damage_types = list(BRUTE = 34)
	var/bolt_armor_divisor = 2

/obj/item/gun/energy/crossbow_mech/proc/calculate_damage(material/bolt_mat)
	if(!bolt_mat || !istype(bolt_mat))
		CRASH("calculate_damage() called with no/invalid bolt material!")

	damage_types = list(BRUTE = max(0, round((bolt_mat.weight * 1.2), 1)))
	bolt_armor_divisor = max(1, round(log(bolt_mat.hardness / 20) + 1, 1))

/obj/item/gun/energy/crossbow_mech/consume_next_projectile()
	if(cell.use(charge_cost) && shots_amount)
		shots_amount--
		var/obj/item/projectile/bullet/bolt/mech/bolt = new projectile_type
		bolt.damage_types = damage_types
		bolt.armor_divisor = bolt_armor_divisor
		. = bolt

#undef CROSSBOW_MAX_AMOUNT
#undef CROSSBOW_AMOUNT_OF_MATERIAL_PER_SHOT

/// Yes this also drains power from blocking halloss
///  Yes i justify it cause it stops by kinetic power and not by lethality / material hardness
/obj/item/mech_equipment/shield_generator
	name = "mounted shield generator"
	desc = "A large, heavy box carrying a miniaturized shield generator."
	icon_state = "mech_atmoshield"
	restricted_hardpoints = list(HARDPOINT_BACK)
	origin_tech = list(TECH_MATERIAL = 3, TECH_ENGINEERING = 6, TECH_PLASMA = 5)
	// so it has update icon called everytime it moves; and run Process() too
	equipment_flags = EQUIPFLAG_UPDTMOVE|EQUIPFLAG_PROCESS
	active_power_use = 0
	///How much power the shield uses every time Process() is called; using active_power_use would result in some double dipping
	var/power_cost = 10
	///The max amount of charge the capacitor can hold
	var/max_capacitor_charge = 500
	///Internal charge of the shield
	var/current_capacitor_charge = 0
	///What portion of damage is absorbed by the shield; should be a number from 1 to 0, where 1 is 100% absorption and 0 is 0% absorption
	var/absorption_ratio = 1
	/// Are we toggled on ?
	var/on = FALSE
	/// last time we toggled ,. stores world.time
	var/last_toggle = null
	/// A object used to show the shield effects
	var/obj/visual_bluff = null

/obj/item/mech_equipment/shield_generator/Initialize()
	. = ..()
	icon_state = "mech_atmoshield_off"
	visual_bluff = new /obj(null)
	visual_bluff.icon = 'icons/mechs/shield.dmi'
	visual_bluff.icon_state = "shield_null"
	visual_bluff.vis_flags = VIS_INHERIT_DIR | VIS_INHERIT_ID | VIS_INHERIT_PLANE
	visual_bluff.layer = ABOVE_ALL_MOB_LAYER
	current_capacitor_charge = max_capacitor_charge

/obj/item/mech_equipment/shield_generator/Destroy()
	. = ..()
	var/mob/living/exosuit/mech = loc
	if(ismech(mech))
		mech.vis_contents.Remove(visual_bluff)
	QDEL_NULL(visual_bluff)

/obj/item/mech_equipment/shield_generator/uninstalled()
	maptext = null
	if(on)
		toggle_shield()
	owner.vis_contents.Remove(visual_bluff)
	. = ..()

/obj/item/mech_equipment/shield_generator/deactivate()
	. = ..()
	if(!on)
		return

	power_failure()

/obj/item/mech_equipment/shield_generator/attack_self(mob/user)
	. = ..()
	if(.)
		toggle_shield(user)

///Toggle the shield between on and off
/obj/item/mech_equipment/shield_generator/proc/toggle_shield(mob/user)
	on = !on
	last_toggle = world.time
	update_icon()
	playsound(get_turf(src), on ? 'sound/mechs/shield_raise.ogg' : 'sound/mechs/shield_drop.ogg', 50, 3)
	active = on

///Proc that plays an alarm and then toggle the shield
/obj/item/mech_equipment/shield_generator/proc/power_failure()
	playsound(get_turf(src), 'sound/mechs/internaldmgalarm.ogg', 50, 3)
	toggle_shield()

/obj/item/mech_equipment/shield_generator/update_icon(skip)
	. = ..()
	if(skip)
		return ..()
	icon_state = "[initial(icon_state)]_[on ? "on" : "off"]"
	visual_bluff.icon_state = "[on ? "shield" : "shield_null"]"
	var/mob/living/exosuit/mech = loc
	if(!istype(mech))
		return
	if(!(visual_bluff in mech.vis_contents))
		mech.vis_contents.Add(visual_bluff)
	visual_bluff.dir = mech.dir
	if(visual_bluff.dir == NORTH)
		visual_bluff.layer = MECH_UNDER_LAYER
	else
		visual_bluff.layer = MECH_ABOVE_LAYER
	if(last_toggle > world.time - 1 SECOND)
		if(on)
			flick("shield_raise", visual_bluff)
		else
			flick("shield_drop", visual_bluff)

/obj/item/mech_equipment/shield_generator/proc/absorbDamages(damage)
	if(!on || !damage)	//Don't bother if the damage is 0
		return damage

	if(!current_capacitor_charge)	//If somehow the shield is on and capacitor is empty, just turn it off
		power_failure()
		return damage

	flick("shield_impact", visual_bluff)

	//Absorb as much as the capacitor can and only what the shield can absorb
	var/damage_absorbed = (damage * absorption_ratio >= current_capacitor_charge * absorption_ratio ? current_capacitor_charge : damage) * absorption_ratio
	damage -= damage_absorbed
	current_capacitor_charge -= damage_absorbed
	if(!current_capacitor_charge)	//Turn it off if the capacitor is empty
		power_failure()

	return damage

/obj/item/mech_equipment/shield_generator/Process(delta_time)
	//Capactor loses power just maintaining the shield
	if(on)
		current_capacitor_charge -= power_cost
		if(current_capacitor_charge <= 0)
			power_failure()

	var/obj/item/cell/cell = owner.get_cell()
	if(!cell?.charge)	//No battery or no charge
		maptext = "<span class='maptext' style=text-align:center>[!current_capacitor_charge ? "0" : (current_capacitor_charge / max_capacitor_charge) * 100]%"
		return

	//Transfer in increments of power_cost or the remaining charge
	var/transfer_amount = min(power_cost, max_capacitor_charge - current_capacitor_charge, cell.charge)
	cell.use(transfer_amount)
	current_capacitor_charge += transfer_amount
	maptext = "<span class='maptext' style=text-align:center>[!current_capacitor_charge ? "0" : (current_capacitor_charge / max_capacitor_charge) * 100]%"

/obj/item/mech_equipment/shield_generator/ballistic
	name = "ballistic mech shield"
	desc = "A large, bulky shield meant to protect hunkering mechs."
	icon_state = "mech_shield"
	equipment_flags = EQUIPFLAG_UPDTMOVE
	restricted_hardpoints = list(HARDPOINT_LEFT_HAND, HARDPOINT_RIGHT_HAND)
	origin_tech = list(TECH_MATERIAL = 5, TECH_ENGINEERING = 3)
	absorption_ratio = 0.66	//66% of damage is absorbed
	///Boolean to know if the shield is currently being deployed or retracted
	var/performing_action = FALSE

/obj/item/mech_equipment/shield_generator/ballistic/Initialize()
	. = ..()
	icon_state = "mech_shield"
	visual_bluff.icon = 'icons/mechs/bshield.dmi'
	visual_bluff.pixel_x = 0

/obj/item/mech_equipment/shield_generator/ballistic/installed(mob/living/exosuit/_owner, hardpoint)
	. = ..()
	if(!(visual_bluff in _owner.vis_contents))
		_owner.vis_contents.Add(visual_bluff)
	visual_bluff.icon_state = "mech_shield_[hardpoint]"
	update_icon()

/obj/item/mech_equipment/shield_generator/ballistic/absorbDamages(damage)
	if(!on || !damage)
		return damage

	playsound(get_turf(src), 'sound/weapons/shield/shieldblock.ogg', 50, 8)
	return damage * absorption_ratio

/obj/item/mech_equipment/shield_generator/ballistic/update_icon()
	/// Not needed since we already have handling for visual bluffs layering
	/// and since we dont use a shield.

	..(skip = TRUE)
	var/mob/living/exosuit/mech = loc
	if(!istype(mech))
		return
	if(!(visual_bluff in mech.vis_contents))
		mech.vis_contents.Add(visual_bluff)
	visual_bluff.dir = mech.dir
	visual_bluff.icon_state = "mech_shield_[on ? "on_" : ""][get_hardpoint()]"
	switch(get_hardpoint())
		if(HARDPOINT_RIGHT_HAND)
			// i used a switch before and it doesnt work as intended for some fucking reason FOR EAST AND WEST >:( -SPCR
			if(visual_bluff.dir == NORTH)
				visual_bluff.layer = MECH_UNDER_LAYER
			if(visual_bluff.dir == EAST)
				visual_bluff.layer = MECH_ABOVE_LAYER
			if(visual_bluff.dir == SOUTH)
				visual_bluff.layer = MECH_ABOVE_LAYER
			if(visual_bluff.dir == WEST)
				visual_bluff.layer = MECH_UNDER_LAYER
			return
		if(HARDPOINT_LEFT_HAND)
			if(visual_bluff.dir == NORTH)
				visual_bluff.layer = MECH_UNDER_LAYER
			if(visual_bluff.dir == EAST)
				visual_bluff.layer = MECH_UNDER_LAYER
			if(visual_bluff.dir == SOUTH)
				visual_bluff.layer = MECH_ABOVE_LAYER
			if(visual_bluff.dir == WEST)
				visual_bluff.layer = MECH_ABOVE_LAYER
			return

/obj/item/mech_equipment/shield_generator/ballistic/toggle_shield(mob/user)
	if(canremove || performing_action)	//From what I gather, canremove is only TRUE when not installed
		return

	performing_action = TRUE
	//Check if there is a user because in the event this is called when being uninstalled, just skip the do_after and message
	if(user)
		if(!do_after(user, 0.5 SECONDS, owner, FALSE))
			performing_action = FALSE
			return
		owner.visible_message(span_danger("\The [owner] [on ? "deploys" : "retracts"] \the [src]!"), "", "You hear the sound of a heavy metal plate hitting the floor!", 8)

	on = !on
	playsound(get_turf(src), 'sound/weapons/shield/shieldblock.ogg', 300, 8)
	/// movement blocking is handled in MoveBlock()

	performing_action = FALSE
	update_icon()
	active = on

/// Pass all attack attempts to afterattack if we're installed
/obj/item/mech_equipment/shield_generator/ballistic/resolve_attackby(atom/A, mob/user, params)
	if(ismech(loc))
		return FALSE
	else
		return ..()

/obj/item/mech_equipment/shield_generator/ballistic/afterattack(atom/target, mob/living/user, inrange, params)
	. = ..()
	// the target != loc is necesarry cause it would just body slam itself when installed(epic jumpscare) - SPCR 2023
	if(inrange && ismech(loc) && target != loc)
		var/list/mob/living/targets = list()
		if(!isturf(target))
			target = get_turf(target)
		for(var/mob/living/knocked in target.contents)
			targets.Add(knocked)
		do_attack_animation(target, TRUE)

		for(var/mob/living/knockable in targets)
			if(ishuman(knockable))
				var/mob/living/carbon/human/targ = knockable
				if(targ.stats.getStat(STAT_VIG) > STAT_LEVEL_EXPERT)
					targ.visible_message(span_danger("[targ] dodges the shield slam!"), "You dodge [loc]'s shield slam!", "You hear a woosh.", 6)
					targets.Remove(knockable)
					continue
				targ.visible_message(span_danger("[targ] gets slammed by [loc]'s [src]!"), span_notice("You get slammed by [loc]'s [src]!"), "You hear something soft hit a metal plate!", 6)
				targ.Weaken(1)
				targ.throw_at(get_turf_away_from_target_complex(target,user,3), 5, 1, loc)
				targ.damage_through_armor(20, BRUTE, BP_CHEST, ARMOR_MELEE, 1, src, FALSE, FALSE, 1)
			else
				knockable.visible_message(span_danger("[knockable] gets slammed by [loc]'s [src]!"), span_notice("You get slammed by [loc]'s [src]!"), "You hear something soft hit a metal plate!", 6)
				knockable.Weaken(1)
				knockable.throw_at(get_turf_away_from_target_complex(target,user,3), 3, 1, loc)
				knockable.damage_through_armor(20, BRUTE, BP_CHEST, ARMOR_MELEE, 2, src, FALSE, FALSE, 1)

		if(length(targets))
			playsound(get_turf(src), 'sound/effects/shieldbash.ogg', 100, 3)

/obj/item/mech_equipment/shield_generator/ballistic/Process(delta_time)
	STOP_PROCESSING(SSobj, src)	//Ballistic shield doesn't need to process anything

/obj/item/mech_equipment/mounted_system/baton
	name = "\improper IHS \"Compliance\" baton "
	desc = "An exosuit-mounted baton. Double the zap for 3 times the size."
	icon_state = "mech_baton_off"
	holding_type = /obj/item/melee/baton/mounted
	restricted_hardpoints = list(HARDPOINT_LEFT_HAND, HARDPOINT_RIGHT_HAND)
	matter = list(MATERIAL_PLASTEEL = 15, MATERIAL_PLASTIC = 10)
	origin_tech = list(TECH_COMBAT = 4)
	equipment_flags = EQUIPFLAG_PRETICK
	spawn_tags = SPAWN_MECH_QUIPMENT
	spawn_blacklisted = FALSE
	rarity_value = 60

/obj/item/mech_equipment/mounted_system/baton/pretick()
	if(owner && !(owner.power == MECH_POWER_ON))
		var/obj/item/melee/baton/mounted/batong = holding
		batong.set_status(FALSE)
		update_icon()
		owner.update_icon()

/obj/item/mech_equipment/mounted_system/baton/update_icon(hardpoint)
	. = ..()
	if(owner)
		var/obj/item/melee/baton/mounted/batong = holding
		icon_state = "mech_baton[batong.status ? "" : "_off"]"


/obj/item/mech_equipment/mounted_system/baton/attack_self(mob/user)
	var/obj/item/melee/baton/mounted/batong = holding
	if(!owner)
		return
	if(batong.status == FALSE)
		if(owner.power == MECH_POWER_ON)
			to_chat(user, "You toggle \the [src] on.")
			batong.set_status(TRUE)
		else
			to_chat(user, "You try to power [src], but nothing happens.")
	else
		to_chat(user, "You toggle \the [src] off.")
		batong.set_status(FALSE)
	update_icon()
	owner.update_icon()


/obj/item/mech_equipment/mounted_system/sprayer
	name = "ML \"Washer\" sprayer"
	desc = "A upsized chemical sprayer for mechs"
	icon_state = "sprayer"
	holding_type = /obj/item/reagent_containers/spray/chemsprayer
	restricted_hardpoints = list(HARDPOINT_LEFT_SHOULDER, HARDPOINT_RIGHT_SHOULDER)
	restricted_software = list(MECH_SOFTWARE_WEAPONS)
	origin_tech = list(TECH_COMBAT = 3, TECH_MAGNET = 2)
	matter = list(MATERIAL_PLASTEEL = 3, MATERIAL_STEEL = 10, MATERIAL_SILVER = 3, MATERIAL_GLASS = 10) // more expensive
	spawn_tags = SPAWN_MECH_QUIPMENT
	spawn_blacklisted = FALSE
	rarity_value = 90

/obj/item/mech_equipment/mounted_system/sprayer/attackby(obj/item/I, mob/living/user, params)
	if(I.is_drainable() && I.reagents.total_volume && user.a_intent != I_GRAB)
		to_chat(user, span_notice("You transfer 10 units of substance from \the [I] to \the [src]'s internal chemical storage."))
		I.reagents.trans_to_holder(holding.reagents, 10, 1, FALSE)
	else if(I.reagents && I.reagent_flags & REFILLABLE && user.a_intent == I_GRAB)
		to_chat(user, span_notice("You drain 10 units of substance from \the [src] to \the [I]."))
		holding.reagents.trans_to_holder(I.reagents, 10, 1, FALSE)
	else
		to_chat(user, span_notice("You need to be on GRAB intent to drain from \the [src]."))

/obj/item/mech_equipment/mounted_system/sprayer/afterattack(atom/target, mob/living/user, inrange, params)
	if(!ismech(user.loc))
		return
	var/obj/item/reagent_containers/spray/chemsprayer/sprayer = holding
	sprayer.Spray_at(target, user, )

	playsound(get_turf(src), 'sound/effects/spray2.ogg', 50, 1, -6)

	user.setClickCooldown(4)

	if(sprayer.reagents.has_reagent("sacid"))
		message_admins("[key_name_admin(user)] fired sulphuric acid from \a [src] mounted on a mech..")
		log_game("[key_name(user)] fired sulphuric acid from \a [src].")
	if(sprayer.reagents.has_reagent("pacid"))
		message_admins("[key_name_admin(user)] fired Polyacid from \a [src] mounted on a mech.")
		log_game("[key_name(user)] fired Polyacid from \a [src].")
	if(sprayer.reagents.has_reagent("lube"))
		message_admins("[key_name_admin(user)] fired Space lube from \a [src] mounted on a mech.")
		log_game("[key_name(user)] fired Space lube from \a [src].")
	return



/obj/item/mech_equipment/mounted_system/binoculars
	name = "TM \"32K\" binoculars"
	desc = "A shoulder-mounted mech binocular system. "
	icon_state = "mech_binoculars"
	restricted_hardpoints = list(HARDPOINT_LEFT_SHOULDER, HARDPOINT_RIGHT_SHOULDER)
	holding_type = /obj/item/device/binoculars/mech
	spawn_tags = SPAWN_MECH_QUIPMENT
	spawn_blacklisted = FALSE
	rarity_value = 50
