/obj/item/plastique
	name = "plastic explosive"
	desc = "Used to make holes in specific areas without too much extra hole."
	gender = PLURAL
	icon = 'icons/obj/assemblies.dmi'
	icon_state = "plastic-explosive0"
	item_state = "plasticx"
	flags = NOBLUDGEON
	w_class = ITEM_SIZE_SMALL
	origin_tech = list(TECH_COVERT = 2)
	var/datum/wires/explosive/c4/wires
	var/timer = 10
	var/atom/target
	var/open_panel = 0
	var/image_overlay

/obj/item/plastique/New()
	wires = new(src)
	image_overlay = image('icons/obj/assemblies.dmi', "plastic-explosive2")
	..()

/obj/item/plastique/Destroy()
	qdel(wires)
	wires = null
	return ..()

/obj/item/plastique/attackby(obj/item/I, mob/user)
	if(QUALITY_SCREW_DRIVING in I.tool_qualities)
		if(I.use_tool(user, src, WORKTIME_FAST, QUALITY_SCREW_DRIVING, FAILCHANCE_EASY, required_stat = STAT_MEC))
			open_panel = !open_panel
			to_chat(user, span_notice("You [open_panel ? "open" : "close"] the wire panel."))
	else if(istool(I))
		wires.Interact(user)
	else
		..()

/obj/item/plastique/attack_self(mob/user as mob)
	var/newtime = input(usr, "Please set the timer.", "Timer", 10) as num
	if(user.get_active_held_item() == src)
		newtime = CLAMP(newtime, 2, 60000)
		timer = newtime
		to_chat(user, "Timer set for [timer] seconds.")

/obj/item/plastique/afterattack(atom/movable/target, mob/user, flag)
	if (!flag)
		return
	if(isturf(target))
		var/turf/turf = target
		if(!turf.is_simulated)
			return
	if (ismob(target) || istype(target, /turf/shuttle) || istype(target, /obj/item/storage/) || istype(target, /obj/item/clothing/under))
		return
	to_chat(user, "Planting the explosive charge...")
	user.do_attack_animation(target)

	if(do_after(user, 2 SECONDS, target) && in_range(user, target))
		user.drop_item()
		src.target = target
		loc = null

		if (ismob(target))
			add_logs(user, target, "planted [name] on")
			user.visible_message(span_danger("[user.name] finished planting the explosive on [target.name]!"))
			message_admins("[key_name(user, user.client)][ADMIN_QUE(user)]] planted [src.name] on [key_name(target)][ADMIN_QUE(target)] with [timer] second fuse",0,1)
			log_game("[key_name(user)] planted [src.name] on [key_name(target)] with [timer] second fuse")

		else
			message_admins("[key_name(user, user.client)][ADMIN_QUE(user)]] planted [src.name] on [target.name] at ([target.x],[target.y],[target.z] - [ADMIN_JMP(target)] with [timer] second fuse",0,1)
			log_game("[key_name(user)] planted [src.name] on [target.name] at ([target.x],[target.y],[target.z]) with [timer] second fuse")

		target.overlays += image_overlay
		to_chat(user, "Bomb has been planted. Timer is counting down from [timer].")
		spawn(timer*10)
			explode(get_turf(target))

/obj/item/plastique/proc/explode(location)
	var/cur_turf = get_turf(src)
	if(!target)
		target = get_atom_on_turf(src)
	if(!target)
		target = src
	if(target != src)
		target.explosion_act(1000, null)
	else if(location)
		target = get_turf(location)
		target.explosion_act(1000, null)
	explosion(cur_turf, 400, 180)
	/*
	if(target)
		if (istype(target, /turf/wall))
			var/turf/wall/W = target
			W.dismantle_wall(no_product = TRUE)
		else if(isliving(target))
			target.explosion_act(1000) // c4 can't gib mobs anymore.
		else
			target.explosion_act(1000)
	*/

	//Girders are a pain, just delete em
	//for (var/obj/structure/girder/G in loc)
	//	qdel(G)

	if(target)
		target.overlays -= image_overlay
	qdel(src)

/obj/item/plastique/attack(mob/M, mob/user, def_zone)
	return
