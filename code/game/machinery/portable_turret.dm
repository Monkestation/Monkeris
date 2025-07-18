/*		Portable Turrets:
		Constructed from metal, a gun of choice, and a prox sensor.
		This code is slightly more documented than normal, as requested by XSI on IRC.
*/

#define TURRET_PRIORITY_TARGET 2
#define TURRET_SECONDARY_TARGET 1
#define TURRET_NOT_TARGET 0

/obj/machinery/porta_turret
	name = "turret"
	icon = 'icons/obj/turrets.dmi'
	icon_state = "turretCover"
	anchored = TRUE

	density = FALSE
	use_power = IDLE_POWER_USE				//this turret uses and requires power
	idle_power_usage = 50		//when inactive, this turret takes up constant 50 Equipment power
	active_power_usage = 300	//when active, this turret takes up constant 300 Equipment power
	power_channel = STATIC_EQUIP	//drains power from the EQUIPMENT channel

	var/raised = 0			//if the turret cover is "open" and the turret is raised
	var/raising= 0			//if the turret is currently opening or closing its cover
	health = 80			//the turret's health
	maxHealth = 80		//turrets maximal health.
	var/resistance = RESISTANCE_FRAGILE 		//reduction on incoming damage
	var/auto_repair = 0		//if 1 the turret slowly repairs itself.
	var/locked = 1			//if the turret's behaviour control access is locked
	var/controllock = 0		//if the turret responds to control panels

	var/obj/item/gun/energy/installation = /obj/item/gun/energy/gun	//the weapon that's installed. Store as path to initialize a new gun on creation.
	var/projectile	//holder for bullettype
	var/eprojectile	//holder for the shot when emagged
	var/reqpower = 500		//holder for power needed
	var/iconholder	//holder for the icon_state. 1 for orange sprite, null for blue.
	var/egun			//holder to handle certain guns switching bullettypes

	var/last_fired = 0		//1: if the turret is cooling down from a shot, 0: turret is ready to fire
	var/shot_delay = 15		//1.5 seconds between each shot

	var/check_arrest = 1	//checks if the perp is set to arrest
	var/check_records = 1	//checks if a security record exists at all
	var/check_weapons = 0	//checks if it can shoot people that have a weapon they aren't authorized to have
	var/check_access = 1	//if this is active, the turret shoots everything that does not meet the access requirements
	var/check_anomalies = 1	//checks if it can shoot at unidentified lifeforms (ie xenos)
	var/check_synth	 = 0 	//if active, will shoot at anything not an AI or cyborg
	var/ailock = 0 			// AI cannot use this

	var/attacked = 0		//if set to 1, the turret gets pissed off and shoots at people nearby (unless they have sec access!)

	var/enabled = 1				//determines if the turret is on
	var/lethal = 0			//whether in lethal or stun mode
	var/disabled = 0

	var/shot_sound 			//what sound should play when the turret fires
	var/eshot_sound			//what sound should play when the emagged turret fires

	var/datum/effect/effect/system/spark_spread/spark_system	//the spark system, used for generating... sparks?

	var/wrenching = 0
	var/last_target					//last target fired at, prevents turrets from erratically firing at all valid targets in range

	var/hackfail = 0				//if the turret has gotten pissed at someone who tried to hack it, but failed, it will immediately reactivate and target them.
	var/debugopen = 0				//if the turret's debug functions are accessible through the control panel
	var/list/registered_names = list() 		//holder for registered IDs for the turret to ignore
	var/list/access_occupy = list()
	var/overridden = 0				//if the security override is 0, security protocols are on. if 1, protocols are broken.

/obj/machinery/porta_turret/One_star
	name = "one star turret"

/obj/machinery/porta_turret/crescent
	enabled = 0
	ailock = 1
	check_synth	 = 0
	check_access = 1
	check_arrest = 1
	check_records = 1
	check_weapons = 1
	check_anomalies = 1



/obj/machinery/porta_turret/stationary
	ailock = 1
	lethal = 1
	installation = /obj/item/gun/energy/laser

/obj/machinery/porta_turret/New()
	..()
	req_access.Cut()
	req_one_access = list(access_security, access_heads, access_occupy)

	//Sets up a spark system
	spark_system = new /datum/effect/effect/system/spark_spread
	spark_system.set_up(5, 0, src)
	spark_system.attach(src)
	var/area/A = get_area(src)
	SEND_SIGNAL_OLD(A, COMSIG_TURRENT, src)
	setup()

/obj/machinery/porta_turret/crescent/New()
	..()
	req_one_access.Cut()
	req_access = list(access_cent_specops)

/obj/machinery/porta_turret/Destroy()
	qdel(spark_system)
	spark_system = null
	QDEL_NULL(installation)
	. = ..()

/obj/machinery/porta_turret/proc/setup()
	if(ispath(installation))
		weapon_setup(installation)
		installation = new installation	//All energy-based weapons are applicable
	else
		eprojectile = installation.projectile_type
		eshot_sound = installation.fire_sound
	projectile = installation.projectile_type
	shot_sound = installation.fire_sound

/obj/machinery/porta_turret/proc/weapon_setup(guntype)
	switch(guntype)
		if(/obj/item/gun/energy/laser/practice)
			iconholder = 1
			eprojectile = /obj/item/projectile/beam

//			if(/obj/item/gun/energy/laser/practice/sc_laser)
//				iconholder = 1
//				eprojectile = /obj/item/projectile/beam

		if(/obj/item/gun/energy/retro)
			iconholder = 1

//			if(/obj/item/gun/energy/retro/sc_retro)
//				iconholder = 1

		if(/obj/item/gun/energy/captain)
			iconholder = 1

		if(/obj/item/gun/energy/lasercannon)
			iconholder = 1

		if(/obj/item/gun/energy/taser)
			eprojectile = /obj/item/projectile/beam
			eshot_sound = 'sound/weapons/Laser.ogg'

		if(/obj/item/gun/energy/stunrevolver)
			eprojectile = /obj/item/projectile/beam
			eshot_sound = 'sound/weapons/Laser.ogg'

		if(/obj/item/gun/energy/gun)
			eprojectile = /obj/item/projectile/beam	//If it has, going to kill mode
			eshot_sound = 'sound/weapons/Laser.ogg'
			egun = 1

		if(/obj/item/gun/energy/nuclear)
			eprojectile = /obj/item/projectile/beam	//If it has, going to kill mode
			eshot_sound = 'sound/weapons/Laser.ogg'
			egun = 1

var/list/turret_icons

/obj/machinery/porta_turret/update_icon()
	if(!turret_icons)
		turret_icons = list()
		turret_icons["open"] = image(icon, "openTurretCover")

	underlays.Cut()
	underlays += turret_icons["open"]

	if(stat & BROKEN)
		icon_state = "destroyed_target_prism"
	else if(raised || raising)
		if(powered() && enabled)
			if(iconholder)
				//lasers have a orange icon
				icon_state = "orange_target_prism"
			else
				//almost everything has a blue icon
				icon_state = "target_prism"
		else
			icon_state = "grey_target_prism"
	else
		icon_state = "turretCover"

/obj/machinery/porta_turret/proc/isLocked(mob/user)
	if(ailock && issilicon(user))
		to_chat(user, span_notice("There seems to be a firewall preventing you from accessing this device."))
		return 1

	if(locked && !issilicon(user))
		to_chat(user, span_notice("Access denied."))
		return 1

	return 0

/obj/machinery/porta_turret/attack_hand(mob/user)
	if(isLocked(user))
		return

	nano_ui_interact(user)

/obj/machinery/porta_turret/nano_ui_interact(mob/user, ui_key = "main", datum/nanoui/ui = null, force_open = NANOUI_FOCUS)
	var/data[0]
	data["access"] = !isLocked(user)
	data["locked"] = locked
	data["enabled"] = enabled
	data["is_lethal"] = 1
	data["lethal"] = lethal

	if(data["access"])
		var/settings[0]
		settings[++settings.len] = list("category" = "Neutralize All Non-Synthetics", "setting" = "check_synth", "value" = check_synth)
		settings[++settings.len] = list("category" = "Check Weapon Authorization", "setting" = "check_weapons", "value" = check_weapons)
		settings[++settings.len] = list("category" = "Check Security Records", "setting" = "check_records", "value" = check_records)
		settings[++settings.len] = list("category" = "Check Arrest Status", "setting" = "check_arrest", "value" = check_arrest)
		settings[++settings.len] = list("category" = "Check Access Authorization", "setting" = "check_access", "value" = check_access)
		settings[++settings.len] = list("category" = "Check misc. Lifeforms", "setting" = "check_anomalies", "value" = check_anomalies)
		data["settings"] = settings

	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)
		ui = new(user, src, ui_key, "turret_control.tmpl", "Turret Controls", 500, 300)
		ui.set_initial_data(data)
		ui.open()
		ui.set_auto_update(1)

/obj/machinery/porta_turret/proc/HasController()
	var/area/A = get_area(src)
	return A && A.turret_controls.len > 0

/obj/machinery/porta_turret/CanUseTopic(mob/user)
	if(HasController())
		to_chat(user, span_notice("Turrets can only be controlled using the assigned turret controller."))
		return STATUS_CLOSE

	if(isLocked(user))
		return STATUS_CLOSE

	if(!anchored)
		to_chat(usr, span_notice("\The [src] has to be secured first!"))
		return STATUS_CLOSE

	return ..()


/obj/machinery/porta_turret/Topic(href, href_list)
	if(..())
		return 1

	if(href_list["command"] && href_list["value"])
		var/value = text2num(href_list["value"])
		if(href_list["command"] == "enable")
			if(anchored)
				enabled = value
		else if(href_list["command"] == "lethal")
			lethal = value
		else if(href_list["command"] == "check_synth")
			check_synth = value
		else if(href_list["command"] == "check_weapons")
			check_weapons = value
		else if(href_list["command"] == "check_records")
			check_records = value
		else if(href_list["command"] == "check_arrest")
			check_arrest = value
		else if(href_list["command"] == "check_access")
			check_access = value
		else if(href_list["command"] == "check_anomalies")
			check_anomalies = value

		return 1

/obj/machinery/porta_turret/power_change()
	if(powered())
		stat &= ~NOPOWER
		update_icon()
	else
		spawn(rand(0, 15))
			stat |= NOPOWER
			update_icon()


/obj/machinery/porta_turret/attackby(obj/item/I, mob/user)

	var/obj/item/card/id/ID = I.GetIdCard()

	if (user.a_intent == I_HELP)
		if(stat & BROKEN)
			if(QUALITY_PRYING in I.tool_qualities)
				//If the turret is destroyed, you can remove it with a crowbar to
				//try and salvage its components
				to_chat(user, span_notice("You begin prying the metal coverings off."))
				if(do_after(user, 20, src))
					if(prob(70))
						to_chat(user, span_notice("You remove the turret and salvage some components."))
						if(installation)
							installation.forceMove(loc)
							installation = null
						if(prob(50))
							new /obj/item/stack/material/steel(loc, rand(1,4))
						if(prob(50))
							new /obj/item/device/assembly/prox_sensor(loc)
					else
						to_chat(user, span_notice("You remove the turret but did not manage to salvage anything."))
					qdel(src) // qdel
			return 1 //No whacking the turret with tools on help intent

		else if(QUALITY_BOLT_TURNING in I.tool_qualities)
			if(enabled)
				to_chat(user, span_warning("You cannot unsecure an active turret!"))
				return
			if(wrenching)
				to_chat(user, span_warning("Someone is already [anchored ? "un" : ""]securing the turret!"))
				return
			if(debugopen)
				to_chat(user, span_warning("You can't secure the turret while the circuitry is exposed!"))
				return
			if(!anchored && isinspace())
				to_chat(user, span_warning("Cannot secure turrets in space!"))
				return

			user.visible_message( \
					span_warning("[user] begins [anchored ? "un" : ""]securing the turret."), \
					span_notice("You begin [anchored ? "un" : ""]securing the turret.") \
				)

			wrenching = 1
			if(do_after(user, 50, src))
				//This code handles moving the turret around. After all, it's a portable turret!
				if(!anchored)
					playsound(loc, 'sound/items/Ratchet.ogg', 100, 1)
					anchored = TRUE
					update_icon()
					to_chat(user, span_notice("You secure the exterior bolts on the turret."))
					if(disabled)
						spawn(200)
							disabled = FALSE
				else if(anchored)
					if(disabled)
						to_chat(user, span_notice("The turret is still recalibrating. Wait some time before trying to move it."))
						return
					playsound(loc, 'sound/items/Ratchet.ogg', 100, 1)
					anchored = FALSE
					disabled = TRUE
					to_chat(user, span_notice("You unsecure the exterior bolts on the turret."))
					update_icon()
			wrenching = 0
			return 1 //No whacking the turret with tools on help intent

		else if(istype(I, /obj/item/card/id)||istype(I, /obj/item/modular_computer))
			if(allowed(user))
				locked = !locked
				to_chat(user, span_notice("Controls are now [locked ? "locked" : "unlocked"]."))
				updateUsrDialog()
			else if((debugopen) && (has_access(access_occupy, list(), ID.GetAccess())))
				registered_names += ID.registered_name
				to_chat(user, span_notice("You transfer the card's ID code to the turret's list of targetting exceptions."))
			else
				to_chat(user, span_notice("Access denied."))
			return 1 //No whacking the turret with tools on help intent

		else if(QUALITY_PULSING in I.tool_qualities)
			if(debugopen)
				if(I.use_tool(user, src, WORKTIME_FAST, QUALITY_PULSING, FAILCHANCE_NORMAL,  required_stat = STAT_COG))
					registered_names.Cut()
					registered_names = list()
					to_chat(user, span_notice("You access the debug board and reset the turret's access list."))

			else
				if(I.use_tool(user, src, WORKTIME_LONG, QUALITY_PULSING, FAILCHANCE_HARD,  required_stat = STAT_COG))
					if((TOOL_USE_SUCCESS) && (isLocked(user)))
						locked = 0
						to_chat(user, span_notice("You manage to hack the ID reader, unlocking the access panel with a satisfying click."))
						updateUsrDialog()
					else if((TOOL_USE_SUCCESS) && (!isLocked(user)))
						locked = 1
						to_chat(user, span_notice("You manage to hack the ID reader and the access panel's locking lugs snap shut."))
						updateUsrDialog()
					else if((TOOL_USE_FAIL) && (!overridden) && (min(prob(35 - STAT_COG), 5)))
						enabled = 1
						hackfail = 1
						user.visible_message(
							span_danger("[user] tripped the security protocol on the [src]! Run!"),
							span_danger("You trip the security protocol! Run!")
						)
						sleep(300)
						hackfail = 0
					else
						to_chat(user, span_warning("You fail to hack the ID reader, but avoid tripping the security protocol."))
			return 1 //No whacking the turret with tools on help intent

		else if(QUALITY_SCREW_DRIVING in I.tool_qualities)
			if(I.use_tool(user, src, WORKTIME_NORMAL, QUALITY_SCREW_DRIVING, FAILCHANCE_HARD,  required_stat = STAT_MEC))
				if(debugopen)
					debugopen = 0
					to_chat(user, span_notice("You carefully shut the secondary maintenance hatch and screw it back into place."))
				else
					debugopen = 1
					to_chat(user, span_notice("You gently unscrew the seconday maintenance hatch, gaining access to the turret's internal circuitry and debug functions."))
					desc = "A hatch on the bottom of the access panel is opened, exposing the circuitry inside."
			return 1 //No whacking the turret with tools on help intent

		else if((QUALITY_WIRE_CUTTING in I.tool_qualities) && (debugopen))
			if(overridden)
				to_chat(user, span_warning("The security protocol override has already been disconnected!"))
			else
				switch(I.use_tool_extended(user, src, WORKTIME_NORMAL, QUALITY_WIRE_CUTTING, FAILCHANCE_VERY_HARD,  required_stat = STAT_MEC))
					if(TOOL_USE_SUCCESS)
						to_chat(user, span_notice("You disconnect the turret's security protocol override!"))
						overridden = 1
						req_one_access.Cut()
						req_one_access = list(access_occupy)
					if(TOOL_USE_FAIL)
						user.visible_message(
							span_danger("[user] cut the wrong wire and tripped the security protocol on the [src]! Run!"),
							span_danger("You accidentally cut the wrong wire, tripping the security protocol! Run!")
						)
						enabled = 1
						hackfail = 1
						sleep(300)
						hackfail = 0
			return 1 //No whacking the turret with tools on help intent

	if (!(I.flags & NOBLUDGEON) && I.force && !(stat & BROKEN))
		//if the turret was attacked with the intention of harming it:
		user.do_attack_animation(src)
		user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)

		if (take_damage(I.force * I.structure_damage_factor))
			playsound(src, 'sound/weapons/smash.ogg', 70, 1)
		else
			playsound(src, 'sound/weapons/Genhit.ogg', 25, 1)

		if(!attacked && !emagged)
			attacked = 1
			spawn()
				sleep(60)
				attacked = 0
		return TRUE
	..()

/obj/machinery/porta_turret/emag_act(remaining_charges, mob/user)
	if(!emagged)
		//Emagging the turret makes it go bonkers and stun everyone. It also makes
		//the turret shoot much, much faster.
		to_chat(user, span_warning("You short out [src]'s threat assessment circuits."))
		visible_message("[src] hums oddly...")
		emagged = 1
		iconholder = 1
		controllock = 1
		enabled = 0 //turns off the turret temporarily
		sleep(60) //6 seconds for the contractor to gtfo of the area before the turret decides to ruin his shit
		enabled = 1 //turns it back on. The cover popUp() popDown() are automatically called in process(), no need to define it here
		return 1

/obj/machinery/porta_turret/take_damage(force)
	if(!raised && !raising)
		force = force / 8


	force -= resistance
	if (force <= 0)
		return FALSE

	.=TRUE //Some damage was done
	health -= force
	if (force > 5 && prob(45))
		spark_system.start()
	if(health <= 0)
		die()	//the death process :(

/obj/machinery/porta_turret/bullet_act(obj/item/projectile/Proj)
	var/damage = Proj.get_structure_damage()

	if(!damage)
		if(istype(Proj, /obj/item/projectile/ion))
			Proj.on_hit(loc)
		return

	if(enabled)
		if(!attacked && !emagged)
			attacked = 1
			spawn()
				sleep(60)
				attacked = 0

	..()

	take_damage(damage*Proj.structure_damage_factor)

/obj/machinery/porta_turret/emp_act(severity)
	if(enabled)
		//if the turret is on, the EMP no matter how severe disables the turret for a while
		//and scrambles its settings, with a slight chance of having an emag effect
		check_arrest = prob(50)
		check_records = prob(50)
		check_weapons = prob(50)
		check_access = prob(20)	// check_access is a pretty big deal, so it's least likely to get turned on
		check_anomalies = prob(50)
		if(prob(5))
			emagged = 1

		enabled=0
		spawn(rand(60,600))
			if(!enabled)
				enabled=1

	..()


/obj/machinery/porta_turret/proc/die()	//called when the turret dies, ie, health <= 0
	health = 0
	stat |= BROKEN	//enables the BROKEN bit
	spark_system.start()	//creates some sparks because they look cool
	update_icon()

/obj/machinery/porta_turret/Process()
	//the main machinery process

	if(stat & (NOPOWER|BROKEN))
		//if the turret has no power or is broken, make the turret pop down if it hasn't already
		popDown()
		return

	if(!enabled)
		//if the turret is off, make it pop down
		popDown()
		return

	var/list/targets = list()			//list of primary targets
	var/list/secondarytargets = list()	//targets that are least important

	for(var/mob/M in mobs_in_view(world.view, src))
		assess_and_assign(M, targets, secondarytargets)

	if(!tryToShootAt(targets))
		if(!tryToShootAt(secondarytargets)) // if no valid targets, go for secondary targets
			spawn()
				popDown() // no valid targets, close the cover

	if(auto_repair && (health < maxHealth))
		use_power(20000)
		health = min(health+1, maxHealth) // 1HP for 20kJ

/obj/machinery/porta_turret/proc/assess_and_assign(mob/living/L, list/targets, list/secondarytargets)
	switch(assess_living(L))
		if(TURRET_PRIORITY_TARGET)
			targets += L
		if(TURRET_SECONDARY_TARGET)
			secondarytargets += L

/obj/machinery/porta_turret/proc/assess_living(mob/living/L)
	var/obj/item/card/id/id_card = L.GetIdCard()

	if(id_card && (id_card.registered_name in registered_names))
		return TURRET_NOT_TARGET

	if(!istype(L))
		return TURRET_NOT_TARGET

	if(L.invisibility >= INVISIBILITY_LEVEL_ONE) // Cannot see him. see_invisible is a mob-var
		return TURRET_NOT_TARGET

	if(!L)
		return TURRET_NOT_TARGET

	if(!emagged && (issilicon(L) && !isblitzshell(L)))	// Don't target silica
		return TURRET_NOT_TARGET

	if(L.stat && !emagged)		//if the perp is dead/dying, no need to bother really
		return TURRET_NOT_TARGET	//move onto next potential victim!

	if(get_dist(src, L) > 7)	//if it's too far away, why bother?
		return TURRET_NOT_TARGET

	if(!check_trajectory(L, src))	//check if we have true line of sight
		return TURRET_NOT_TARGET

	if(emagged)		// If emagged not even the dead get a rest
		return L.stat ? TURRET_SECONDARY_TARGET : TURRET_PRIORITY_TARGET

	if(hackfail)
		return TURRET_PRIORITY_TARGET

	if(lethal && locate(/mob/living/silicon/ai) in get_turf(L))		//don't accidentally kill the AI!
		return TURRET_NOT_TARGET

	if(check_synth)	//If it's set to attack all non-silicons, target them!
		if(L.lying)
			return lethal ? TURRET_SECONDARY_TARGET : TURRET_NOT_TARGET
		return TURRET_PRIORITY_TARGET

	if(iscuffed(L)) // If the target is handcuffed, leave it alone
		return TURRET_NOT_TARGET

	if(isanimal(L) || issmall(L)) // Animals are not so dangerous
		return check_anomalies ? TURRET_SECONDARY_TARGET : TURRET_NOT_TARGET

	if(isblitzshell(L)) // Blitzshells are dangerous
		return check_anomalies ? TURRET_PRIORITY_TARGET	: TURRET_NOT_TARGET

	if(ishuman(L))	//if the target is a human, analyze threat level
		if(assess_perp(L) < 4)
			return TURRET_NOT_TARGET	//if threat level < 4, keep going

	if(L.lying)		//if the perp is lying down, it's still a target but a less-important target
		return lethal ? TURRET_SECONDARY_TARGET : TURRET_NOT_TARGET

	return TURRET_PRIORITY_TARGET	//if the perp has passed all previous tests, congrats, it is now a "shoot-me!" nominee

/obj/machinery/porta_turret/One_star/assess_living(mob/living/L)
	if(L.faction == "onestar")
		return TURRET_NOT_TARGET
	return 	..()

/obj/machinery/porta_turret/proc/assess_perp(mob/living/carbon/human/H)
	if(!H || !istype(H))
		return 0

	if(emagged)
		return 10

	return H.assess_perp(src, check_access, check_weapons, check_records, check_arrest)

/obj/machinery/porta_turret/proc/tryToShootAt(list/mob/living/targets)
	if(targets.len && last_target && (last_target in targets) && target(last_target))
		return 1

	while(targets.len > 0)
		var/mob/living/M = pick(targets)
		targets -= M
		if(target(M))
			return 1


/obj/machinery/porta_turret/proc/popUp()	//pops the turret up
	if(disabled)
		return
	if(raising || raised)
		return
	if(stat & BROKEN)
		return
	set_raised_raising(raised, 1)
	update_icon()

	var/atom/flick_holder = new /atom/movable/porta_turret_cover(loc)
	flick_holder.layer = layer + 0.1
	flick("popup", flick_holder)
	sleep(10)
	qdel(flick_holder)

	set_raised_raising(1, 0)
	update_icon()

/obj/machinery/porta_turret/proc/popDown()	//pops the turret down
	last_target = null
	if(disabled)
		return
	if(raising || !raised)
		return
	if(stat & BROKEN)
		return
	set_raised_raising(raised, 1)
	update_icon()

	var/atom/flick_holder = new /atom/movable/porta_turret_cover(loc)
	flick_holder.layer = layer + 0.1
	flick("popdown", flick_holder)
	sleep(10)
	qdel(flick_holder)

	set_raised_raising(0, 0)
	update_icon()

/obj/machinery/porta_turret/proc/set_raised_raising(raised, raising)
	src.raised = raised
	src.raising = raising
	density = raised || raising

/obj/machinery/porta_turret/proc/target(mob/living/target)
	if(disabled)
		return
	if(target)
		last_target = target
		spawn()
			popUp()				//pop the turret up if it's not already up.
		set_dir(get_dir(src, target))	//even if you can't shoot, follow the target
		spawn()
			shootAt(target)
		return 1
	return

/obj/machinery/porta_turret/proc/shootAt(mob/living/target)
	//any emagged turrets will shoot extremely fast! This not only is deadly, but drains a lot power!
	if(!(emagged || attacked))		//if it hasn't been emagged or attacked, it has to obey a cooldown rate
		if(last_fired || !raised)	//prevents rapid-fire shooting, unless it's been emagged
			return
		last_fired = 1
		spawn()
			sleep(shot_delay)
			last_fired = 0

	var/turf/T = get_turf(src)
	var/turf/U = get_turf(target)
	if(!istype(T) || !istype(U))
		return

	if(!raised) //the turret has to be raised in order to fire - makes sense, right?
		return

	launch_projectile(target)

/obj/machinery/porta_turret/proc/launch_projectile(mob/living/target)
	update_icon()
	var/obj/item/projectile/A
	if(emagged || lethal)
		A = new eprojectile(loc)
		playsound(loc, eshot_sound, 75, 1)
	else
		A = new projectile(loc)
		playsound(loc, shot_sound, 75, 1)

	// Lethal/emagged turrets use twice the power due to higher energy beams
	// Emagged turrets again use twice as much power due to higher firing rates
	use_power(reqpower * (2 * (emagged || lethal)) * (2 * emagged))

	//Turrets aim for the center of mass by default.
	//If the target is grabbing someone then the turret smartly aims for extremities
	var/def_zone = get_exposed_defense_zone(target)
	//Shooting Code:
	A.launch(target, def_zone)

/datum/turret_checks
	var/enabled
	var/lethal
	var/check_synth
	var/check_access
	var/check_records
	var/check_arrest
	var/check_weapons
	var/check_anomalies
	var/ailock

/obj/machinery/porta_turret/proc/setState(datum/turret_checks/TC)
	if(controllock)
		return
	src.enabled = TC.enabled
	src.lethal = TC.lethal
	src.iconholder = TC.lethal

	check_synth = TC.check_synth
	check_access = TC.check_access
	check_records = TC.check_records
	check_arrest = TC.check_arrest
	check_weapons = TC.check_weapons
	check_anomalies = TC.check_anomalies
	ailock = TC.ailock

	src.power_change()

/*
		Portable turret constructions
		Known as "turret frame"s
*/

/obj/machinery/porta_turret_construct
	name = "turret frame"
	icon = 'icons/obj/turrets.dmi'
	icon_state = "turret_frame"
	density = TRUE
	var/build_step = 0			//the current step in the building process
	var/finish_name="turret"	//the name applied to the product turret
	var/obj/item/gun/energy/installation		//the gun type installed
	var/gun_charge = 0			//the gun charge of the gun type installed


/obj/machinery/porta_turret_construct/attackby(obj/item/I, mob/user)

	var/list/usable_qualities = list()
	if((build_step == 0 && !anchored) || build_step == 1 || build_step == 2 || build_step == 3)
		usable_qualities.Add(QUALITY_BOLT_TURNING)
	if((build_step == 0 && !anchored) || build_step == 7)
		usable_qualities.Add(QUALITY_PRYING)
	if(build_step == 2 || build_step == 7)
		usable_qualities.Add(QUALITY_WELDING)
	if(build_step == 5 || build_step == 6)
		usable_qualities.Add(QUALITY_SCREW_DRIVING)

	var/tool_type = I.get_tool_type(user, usable_qualities, src)
	switch(tool_type)

		if(QUALITY_BOLT_TURNING)
			if(build_step == 0 && !anchored)
				if(I.use_tool(user, src, WORKTIME_FAST, tool_type, FAILCHANCE_VERY_EASY, required_stat = STAT_MEC))
					to_chat(user, span_notice("You secure the external bolts."))
					anchored = TRUE
					build_step = 1
					return
			if(build_step == 1)
				if(I.use_tool(user, src, WORKTIME_FAST, tool_type, FAILCHANCE_VERY_EASY, required_stat = STAT_MEC))
					to_chat(user, span_notice("You unfasten the external bolts."))
					anchored = FALSE
					build_step = 0
					return
			if(build_step == 2)
				if(I.use_tool(user, src, WORKTIME_FAST, tool_type, FAILCHANCE_VERY_EASY, required_stat = STAT_MEC))
					to_chat(user, span_notice("You bolt the metal armor into place."))
					build_step = 3
					return
			if(build_step == 3)
				if(I.use_tool(user, src, WORKTIME_FAST, tool_type, FAILCHANCE_VERY_EASY, required_stat = STAT_MEC))
					to_chat(user, span_notice("You remove the turret's metal armor bolts."))
					build_step = 2
					return
			return

		if(QUALITY_PRYING)
			if(build_step == 0 && !anchored)
				if(I.use_tool(user, src, WORKTIME_FAST, tool_type, FAILCHANCE_VERY_EASY, required_stat = STAT_MEC))
					to_chat(user, span_notice("You dismantle the turret construction."))
					new /obj/item/stack/material/steel( loc, 8)
					qdel(src)
					return
			if(build_step == 7)
				if(I.use_tool(user, src, WORKTIME_FAST, tool_type, FAILCHANCE_VERY_EASY, required_stat = STAT_MEC))
					to_chat(user, span_notice("You pry off the turret's exterior armor."))
					new /obj/item/stack/material/steel(loc, 2)
					build_step = 6
					return
			return

		if(QUALITY_WELDING)
			if(build_step == 2)
				if(I.use_tool(user, src, WORKTIME_FAST, tool_type, FAILCHANCE_VERY_EASY, required_stat = STAT_MEC))
					to_chat(user, "You remove the turret's interior metal armor.")
					new /obj/item/stack/material/steel( loc, 2)
					build_step = 1
					return
			if(build_step == 7)
				if(I.use_tool(user, src, WORKTIME_FAST, tool_type, FAILCHANCE_VERY_EASY, required_stat = STAT_MEC))
					build_step = 8
					to_chat(user, span_notice("You weld the turret's armor down."))

					//The final step: create a full turret
					var/obj/machinery/porta_turret/Turret = new /obj/machinery/porta_turret(loc)
					Turret.name = finish_name
					Turret.installation = installation
					installation.forceMove(Turret)
					installation = null
					Turret.enabled = 0
					Turret.setup()

					qdel(src)
					return
			return

		if(QUALITY_SCREW_DRIVING)
			if(build_step == 5)
				if(I.use_tool(user, src, WORKTIME_FAST, tool_type, FAILCHANCE_VERY_EASY, required_stat = STAT_MEC))
					to_chat(user, span_notice("You close the internal access hatch."))
					build_step = 6
					return
			if(build_step == 6)
				if(I.use_tool(user, src, WORKTIME_FAST, tool_type, FAILCHANCE_VERY_EASY, required_stat = STAT_MEC))
					to_chat(user, span_notice("You open the internal access hatch."))
					build_step = 5
					return
			return

		if(ABORT_CHECK)
			return


	switch(build_step)
		if(1)
			if(istype(I, /obj/item/stack/material) && I.get_material_name() == MATERIAL_STEEL)
				var/obj/item/stack/M = I
				if(M.use(2))
					to_chat(user, span_notice("You add some metal armor to the interior frame."))
					build_step = 2
					icon_state = "turret_frame2"
				else
					to_chat(user, span_warning("You need two sheets of metal to continue construction."))
				return

		if(3)
			if(istype(I, /obj/item/gun/energy)) //the gun installation part

				if(isrobot(user))
					return
				if(!user.unEquip(I))
					to_chat(user, span_notice("\the [I] is stuck to your hand, you cannot put it in \the [src]"))
					return
				installation = I //We store the gun for the turret to use
				installation.forceMove(src) //We physically store it inside of us until the construction is complete.
				to_chat(user, span_notice("You add [I] to the turret."))
				build_step = 4
				return

			//attack_hand() removes the gun

		if(4)
			if(isproxsensor(I))
				build_step = 5
				if(!user.unEquip(I))
					to_chat(user, span_notice("\the [I] is stuck to your hand, you cannot put it in \the [src]"))
					return
				to_chat(user, span_notice("You add the prox sensor to the turret."))
				qdel(I)
				return

			//attack_hand() removes the prox sensor

		if(6)
			if(istype(I, /obj/item/stack/material) && I.get_material_name() == MATERIAL_STEEL)
				var/obj/item/stack/M = I
				if(M.use(2))
					to_chat(user, span_notice("You add some metal armor to the exterior frame."))
					build_step = 7
				else
					to_chat(user, span_warning("You need two sheets of metal to continue construction."))
				return

	if(istype(I, /obj/item/pen))	//you can rename turrets like bots!
		var/t = sanitizeSafe(input(user, "Enter new turret name", name, finish_name) as text, MAX_NAME_LEN)
		if(!t)
			return
		if(!in_range(src, usr) && loc != usr)
			return

		finish_name = t
		return

	..()


/obj/machinery/porta_turret_construct/attack_hand(mob/user)
	switch(build_step)
		if(4)
			if(!installation)
				return
			build_step = 3
			installation.forceMove(loc)
			installation = null
			to_chat(user, span_notice("You remove [installation] from the turret frame."))
		if(5)
			to_chat(user, span_notice("You remove the prox sensor from the turret frame."))
			new /obj/item/device/assembly/prox_sensor(loc)
			build_step = 4

/obj/machinery/porta_turret_construct/Destroy()
	QDEL_NULL(installation)
	.=..()

/obj/machinery/porta_turret_construct/attack_ai()
	return

/atom/movable/porta_turret_cover
	icon = 'icons/obj/turrets.dmi'


#undef TURRET_PRIORITY_TARGET
#undef TURRET_SECONDARY_TARGET
#undef TURRET_NOT_TARGET
