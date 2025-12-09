//This is being used as a tutorial piece for how to convert guns to modguns, hence the extremely gratutious comments
//comments can be removed later/when it's merged

/obj/item/gun/projectile/automatic/modular/drozd // Frame
	///only put the base name of the gun here. Other info will be filled in by parts.
	name = "\"Drozd\""
	//remove any information about the specific caliber of the gun. Stat qualities (like dmg, recoil mod) are fine.
	desc = "An excellent fully automatic Heavy SMG. Rifled to take a larger caliber than a typical submachine gun, but unlike \
			other heavy SMGs makes use of increased caliber to achieve excellent damage capabilities. \
			Suffers a bit less from poor recoil control and ineffective armor penetration."
	//new .dmi location, inside the projectile/modular file.
	icon = 'icons/obj/guns/projectile/modular/drozd.dmi'

	//copy these stats from base gun
	w_class = ITEM_SIZE_NORMAL
	force = WEAPON_FORCE_PAINFUL

	slot_flags = SLOT_BELT
	load_method = MAGAZINE

	magazine_type = /obj/item/ammo_magazine/msmg
	gun_tags = list(GUN_SILENCABLE)

	serial_type = "Excelsior"

	//need this if the og gun has it, in this case, do not add.
	//auto_eject_sound = 'sound/weapons/smg_empty_alarm.ogg'
	//auto_eject = TRUE

	// Spawns in gun part loot
	spawn_blacklisted = FALSE
	spawn_tags = SPAWN_TAG_GUN_PART

	//nerf from base gun. Since this is only a frame.
	origin_tech = list(TECH_COMBAT = 5, TECH_MATERIAL = 1)
	matter = list(MATERIAL_PLASTEEL = 5)
	price_tag = 1200

	//take from gun type. Though, since this is a high caliber smg, it could also use heavier ones.
	//somewhat up to your discretion imo
	fire_sound = 'sound/weapons/guns/fire/smg_fire.ogg'
	unload_sound = 'sound/weapons/guns/interact/smg_magout.ogg'
	reload_sound = 'sound/weapons/guns/interact/smg_magin.ogg'
	cocked_sound = 'sound/weapons/guns/interact/smg_cock.ogg'

	//these vars contains information about the gun's sprite
	spriteTags = PARTMOD_SLIDE //this gun has a slide, meaning that sprites have a "-e" variant with the slide pulled back
	spriteTagBans = PARTMOD_FOLDING_STOCK // Folding stock does not modify handheld sprite

	//special stats associated with the gun. copy from base firearm, within reason
	//also see the parts of the gun
	init_recoil = SMG_RECOIL(0.7)

	//The required parts of a firearm are as follows:

	//ESSENTIAL PARTS: All guns MUST have these
	//-Grip: determines the base skin of the firearm, and its name. Largely cosmetic.
	//-Mechanism: Determines which calibers a gun can fire. often effects stats.
	//-Barrel: Determines which specific caliber this gun can -currently- fire. sometimes effects stats.

	//OPTIONAL PARTS: Guns MAY support these depending on type/size (eventually, most guns larger than a pistol should support them)
	//-Stock: When extended, increases the stability/handling of the gun when two-handed.
	//-Sights: Allows the gun to scope in.
	//-Bayonet: Increases the melee damage guns do.
	required_parts = list(/obj/item/part/gun/modular/mechanism/smg/highcaliber = 0, /obj/item/part/gun/modular/barrel/magnum = 0, /obj/item/part/gun/modular/grip/excel = 0)


//Each gun will eventually need grip sprite variants (changes overall gun skin) For EACH grip type.
//This is not currently your problem, unless you want it to be...
//Just pick the 'default' correct grip for that weapon in required_parts (in this case, the excel version)

//for each new name, try to follow the theme of the existing gun name.
//the Drozd is named after a russian songbird. (and an anti-missile armor system, but let's not mix metaphors)
/obj/item/gun/projectile/automatic/modular/drozd/get_initial_name()
	if(grip_type)
		switch(grip_type)
			if("wood")
				return "Excelsior SMG [caliber] \"Robin\""
			if("black")
				return "BM SMG [caliber] \"Sokol\""
			if("rubber")
				return "FS SMG [caliber] \"Sparrow\""
			if("excelsior")
				return "Excelsior SMG [caliber] \"Drozd\""
			if("serbian")
				return "SA SMG [caliber] \"Sova\""
			if("makeshift")
				return "MS SMG [caliber] \"Cage\""
	else
		//for unfinished weapon. Up to your interpretation, should be simpler than normal
		return "SMG [caliber] \"Droz\""

//This is the finished version of your gun, with all modifications installed.

//for any parts which are generic in the main required_parts definiton, you must instead put a specific one here
//the number beside each gun part is that part's default quality.
//This can be used as an additional layer of gun balancing
//(though I wouldn't reccomend messing with it too much for 1-1 conversions)
/obj/item/gun/projectile/automatic/modular/drozd/finished
	gun_parts = list(/obj/item/part/gun/modular/mechanism/smg/highcaliber = 0, /obj/item/part/gun/modular/barrel/magnum = 0, /obj/item/part/gun/modular/grip/excel = 0)
	magazine_type = /obj/item/ammo_magazine/msmg // For the rare case the blacklist is ignored
	spawn_tags = SPAWN_TAG_GUN_PROJECTILE //remember to change from frame
