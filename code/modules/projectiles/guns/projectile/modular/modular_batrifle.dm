//as a modular family, battle rifles fufill a niche between boltguns and conventional assault rifles
//generally at a higher rarity tier/cost
/obj/item/gun/projectile/automatic/modular/batrifle // Frame
	name = "\"Kovacs\""
	desc = "A refined battle rifle fit for taking down tough targets. \
			This highly-efficient design has gone into disuse over the years but still sees use by mercenaries."
	icon = 'icons/obj/guns/projectile/modular/battle_rifle.dmi'
	w_class = ITEM_SIZE_BULKY
	force = WEAPON_FORCE_PAINFUL
	origin_tech = list(TECH_COMBAT = 4, TECH_MATERIAL = 1)
	slot_flags = SLOT_BACK
	load_method = MAGAZINE
	magazine_type = /obj/item/ammo_magazine/srifle
	matter = list(MATERIAL_PLASTEEL = 5)
	price_tag = 1200
	fire_sound = 'sound/weapons/guns/fire/ltrifle_fire.ogg'//the srifle sound is way too chunky for automatic fire
	unload_sound = 'sound/weapons/guns/interact/ltrifle_magout.ogg'
	reload_sound = 'sound/weapons/guns/interact/ltrifle_magin.ogg'
	cocked_sound = 'sound/weapons/guns/interact/ltrifle_cock.ogg'

	gun_tags = list(GUN_SILENCABLE)

	serial_type = "SA"

	spriteTags = PARTMOD_SILENCER_HIDES_BARREL | PARTMOD_SLIDE
	spriteTagBans = PARTMOD_FOLDING_STOCK

	init_recoil = RIFLE_RECOIL(0.8)//combines with sharpshooter mech to achieve base kovac stats
	damage_multiplier = 1.2

	//battle rifles are locked to tactical autoloaders, allowing us to split their stat boosts between the frame and the mechanism
	required_parts = list(/obj/item/part/gun/modular/mechanism/autorifle/tactical = 0, /obj/item/part/gun/modular/barrel = 0, /obj/item/part/gun/modular/grip = 0, /obj/item/part/gun/modular/stock = 0, /obj/item/part/gun/modular/sights = -1, /obj/item/part/gun/modular/bayonet = -1, /obj/item/part/gun/modular/silencer = -1)

/obj/item/gun/projectile/automatic/modular/batrifle/get_initial_name()
	if(grip_type)
		switch(grip_type)
			if("wood")
				return "FS BR [caliber] \"Thaw\""
			if("black")
				return "OR BR [caliber] \"STS-35\""
			if("rubber")
				return "FS BR [caliber] \"Glacier\""
			if("excelsior")
				return "Excelsior [caliber] \"Vintorez\""
			if("serbian")
				return "SA BR [caliber] \"Kovacs\""
			if("makeshift")
				return "MS BR [caliber] \"Ballpoint\""
	else
		return "BR [caliber] \"Kova\""


//A long-range combat rifle typically fielded by mercenaries.
/obj/item/gun/projectile/automatic/modular/batrifle/serbian
	gun_parts = list(/obj/item/part/gun/modular/mechanism/autorifle/tactical/sharpshooter = 0, /obj/item/part/gun/modular/barrel/lrifle = 0, /obj/item/part/gun/modular/grip/serb = 1, /obj/item/part/gun/modular/stock = 0, /obj/item/part/gun/modular/sights/scopesmall)
	magazine_type = /obj/item/ammo_magazine/lrifle


//A powerful assault BR once manufactured by the oberth republic.
/obj/item/gun/projectile/automatic/modular/batrifle/sts35
	desc = "The rugged STS-35 is a fully-automatic battle rifle originally made by Oberth Republic Self Defence Force. \
			An extremely effective design that was put in service right before collapse of the Republic, this weapon can be found almost anywhere in the galaxy by now."
	gun_parts = list(/obj/item/part/gun/modular/mechanism/autorifle/tactical/commando = 1, /obj/item/part/gun/modular/barrel/lrifle/forged = 1, /obj/item/part/gun/modular/grip/black = 0, /obj/item/part/gun/modular/stock = 0)

	//undo maluses caused by commando mechanism to reach original-ish sts stats
	damage_multiplier = 1.3
	penetration_multiplier = 0.25
	init_recoil = RIFLE_RECOIL(1)


//An inferior FS copy of the STS-35, sometimes seen in the hands of IH forces.
/obj/item/gun/projectile/automatic/modular/batrifle/fs
	desc = "An automatic battle rifle manufactured by frozen star, which combines high precision with an acceptable rate of fire. \
			Originally based on a design out of oberth, it lacks some of the refinement of the Republic's design."
	gun_parts = list(/obj/item/part/gun/modular/mechanism/autorifle/tactical/sustain = 0, /obj/item/part/gun/modular/barrel/lrifle = 0, /obj/item/part/gun/modular/grip/rubber = 0, /obj/item/part/gun/modular/stock = 0)
	init_recoil = RIFLE_RECOIL(1)

//The classic and extremely dangerous long-range assassination option fielded by excelsior agents.
/obj/item/gun/projectile/automatic/modular/batrifle/vintorez
	desc = "A menacing burst-action battle rifle that is highly prized for its armor penetrating abilities. \
			This weapon hails from a country that has dissapeared completely into the sands of history."
	gun_parts = list(/obj/item/part/gun/modular/mechanism/autorifle/tactical/marksman = 1, /obj/item/part/gun/modular/barrel/srifle = 1, /obj/item/part/gun/modular/grip/excel = 2, /obj/item/part/gun/modular/stock = 0, /obj/item/part/gun/modular/sights/scopebig = 0, /obj/item/part/gun/modular/silencer/advanced = 0)

	penetration_multiplier = 0.35
	damage_multiplier = 1.25
	init_recoil = RIFLE_RECOIL(0.65)

//A cheap hand-made rifle. Has improved damage over the makeshift ak, but slow firerate and poor recoil control.
/obj/item/gun/projectile/automatic/modular/batrifle/makeshift
	gun_parts = list(/obj/item/part/gun/modular/mechanism/autorifle/tactical/makeshift = -1, /obj/item/part/gun/modular/barrel/srifle/steel = 0, /obj/item/part/gun/modular/grip/makeshift = -1, /obj/item/part/gun/modular/stock = 0)
	desc = "A improvised semi-automatic rifle made from junk and spare parts. \
			Effective at vanquishing the great foes of the vagabond- roaches, spiders, and the occasional unlucky mouse. \
			The stock is slightly misshapen, making the gun's recoil difficult to control."
	matter = list(MATERIAL_STEEL = 4)

	// lower quality frame
	init_recoil = RIFLE_RECOIL(1.1)
	damage_multiplier = 1.1

	price_tag = 800
