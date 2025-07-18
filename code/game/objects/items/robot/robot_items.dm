//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:32

/**********************************************************************
						Cyborg Spec Items
***********************************************************************/
//Might want to move this into several files later but for now it works here
// Consider changing this to a child of the stun baton class. ~Z
/obj/item/borg
	bad_type = /obj/item/borg
	spawn_tags = null

/obj/item/borg/stun
	name = "electrified arm"
	icon = 'icons/obj/decals.dmi'
	icon_state = "shock"

/obj/item/borg/stun/apply_hit_effect(mob/living/M, mob/living/silicon/robot/user, hit_zone)
	if(!istype(user))
		return

	user.visible_message(span_danger("\The [user] has prodded \the [M] with \a [src]!"))

	if(!user.cell || !user.cell.checked_use(1250)) //Slightly more than a baton.
		return

	playsound(loc, 'sound/weapons/Egloves.ogg', 50, 1, -1)

	M.apply_effect(5, STUTTER)
	M.stun_effect_act(0, 70, check_zone(hit_zone), src)

	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		H.forcesay(GLOB.hit_appends)

/obj/item/borg/overdrive
	name = "overdrive"
	icon = 'icons/obj/decals.dmi'
	icon_state = "shock"

/**********************************************************************
						HUD/SIGHT things
***********************************************************************/
/obj/item/borg/sight
	icon = 'icons/obj/decals.dmi'
	icon_state = "securearea"
	var/sight_mode
	var/obj/screen/overlay

/obj/item/borg/sight/xray
	name = "\proper x-ray vision"
	sight_mode = BORGXRAY



/obj/item/borg/sight/thermal
	name = "\proper thermal vision"
	sight_mode = BORGTHERM
	icon_state = "thermal"
	icon = 'icons/inventory/eyes/icon.dmi'

/obj/item/borg/sight/thermal/New()
	..()
	overlay = global_hud.thermal

/obj/item/borg/sight/meson
	name = "\proper meson vision"
	sight_mode = BORGMESON
	icon_state = "meson"
	icon = 'icons/inventory/eyes/icon.dmi'

/obj/item/borg/sight/meson/New()
	..()
	overlay = global_hud.meson

/obj/item/borg/sight/material
	name = "\proper material scanner vision"
	sight_mode = BORGMATERIAL

/obj/item/borg/sight/hud
	name = "hud"
	var/obj/item/clothing/glasses/hud/hud


/obj/item/borg/sight/hud/med
	name = "medical hud"
	icon_state = "healthhud"
	icon = 'icons/inventory/eyes/icon.dmi'

/obj/item/borg/sight/hud/med/New()
	..()
	hud = new /obj/item/clothing/glasses/hud/health(src)
	return

/obj/item/borg/sight/hud/sec
	name = "security hud"
	icon_state = "securityhud"
	icon = 'icons/inventory/eyes/icon.dmi'

/obj/item/borg/sight/hud/med/New()
	..()
	hud = new /obj/item/clothing/glasses/hud/security(src)
	return
