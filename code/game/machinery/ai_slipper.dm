/obj/machinery/ai_slipper
	name = "\improper AI Liquid Dispenser"
	icon = 'icons/obj/device.dmi'
	description_info = "Will slip anyone that doesn't have no-slips or magboots"
	icon_state = "motion0"
	plane = FLOOR_PLANE
	layer = PROJECTILE_HIT_THRESHHOLD_LAYER
	anchored = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 10
	var/uses = 20
	var/disabled = 1
	var/lethal = 0
	var/locked = 1
	var/cooldown_time = 0
	var/cooldown_timeleft = 0
	var/cooldown_on = 0
	req_access = list(access_ai_upload)


/obj/machinery/ai_slipper/New()
	..()
	update_icon()

/obj/machinery/ai_slipper/power_change()
	..()
	update_icon()

/obj/machinery/ai_slipper/update_icon()
	if (stat & NOPOWER || stat & BROKEN)
		icon_state = "motion0"
	else
		icon_state = disabled ? "motion0" : "motion3"

/obj/machinery/ai_slipper/proc/setState(enabled, uses)
	src.disabled = disabled
	src.uses = uses
	src.power_change()

/obj/machinery/ai_slipper/attackby(obj/item/W, mob/user)
	if(stat & (NOPOWER|BROKEN))
		return
	if (issilicon(user))
		return src.attack_hand(user)
	else // trying to unlock the interface
		if (src.allowed(usr))
			locked = !locked
			to_chat(user, "You [ locked ? "lock" : "unlock"] the device.")
			if (locked)
				if (user.machine==src)
					user.unset_machine()
					user << browse(null, "window=ai_slipper")
			else
				if (user.machine==src)
					src.attack_hand(usr)
		else
			to_chat(user, span_warning("Access denied."))
			return
	return

/obj/machinery/ai_slipper/attack_hand(mob/user as mob)
	if(stat & (NOPOWER|BROKEN))
		return
	if ( (get_dist(src, user) > 1 ))
		if (!issilicon(user))
			to_chat(user, text("Too far away."))
			user.unset_machine()
			user << browse(null, "window=ai_slipper")
			return

	user.set_machine(src)
	var/loc = src.loc
	if (istype(loc, /turf))
		loc = loc:loc
	if (!istype(loc, /area))
		to_chat(user, text("Turret badly positioned - loc.loc is [].", loc))
		return
	var/area/area = loc
	var/t = "<TT><B>AI Liquid Dispenser</B> ([area.name])<HR>"

	if(src.locked && (!issilicon(user)))
		t += "<I>(Swipe ID card to unlock control panel.)</I><BR>"
	else
		t += text("Dispenser [] - <A href='byond://?src=\ref[];toggleOn=1'>[]?</a><br>\n", src.disabled?"deactivated":"activated", src, src.disabled?"Enable":"Disable")
		t += text("Uses Left: [uses]. <A href='byond://?src=\ref[src];toggleUse=1'>Activate the dispenser?</A><br>\n")

	user << browse(HTML_SKELETON_TITLE("AI Liquid Dispenser", t), "window=computer;size=575x450")
	onclose(user, "computer")
	return

/obj/machinery/ai_slipper/Topic(href, href_list)
	..()
	if (src.locked)
		if (!issilicon(usr))
			to_chat(usr, "Control panel is locked!")
			return
	if (href_list["toggleOn"])
		src.disabled = !src.disabled
		update_icon()
	if (href_list["toggleUse"])
		if(cooldown_on || disabled)
			return
		else
			new /obj/effect/effect/foam(src.loc)
			src.uses--
			cooldown_on = 1
			cooldown_time = world.timeofday + 100
			slip_process()
			return

	src.attack_hand(usr)
	return

/obj/machinery/ai_slipper/proc/slip_process()
	while(cooldown_time - world.timeofday > 0)
		var/ticksleft = cooldown_time - world.timeofday

		if(ticksleft > 1e5)
			cooldown_time = world.timeofday + 10	// midnight rollover


		cooldown_timeleft = (ticksleft / 10)
		sleep(5)
	if (uses <= 0)
		return
	if (uses >= 0)
		cooldown_on = 0
	src.power_change()
	return
