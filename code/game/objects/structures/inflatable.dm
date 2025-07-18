/obj/item/inflatable
	name = "inflatable"
	w_class = ITEM_SIZE_SMALL
	icon = 'icons/obj/inflatable.dmi'
	price_tag = 40
	health = 20
	var/deploy_path = null

/obj/item/inflatable/attack_self(mob/user)
	if(!deploy_path)
		return
	playsound(loc, 'sound/items/zip.ogg', 75, 1)
	to_chat(user, span_notice("You inflate \the [src]."))
	var/obj/structure/inflatable/R = new deploy_path(user.loc)
	src.transfer_fingerprints_to(R)
	R.add_fingerprint(user)
	qdel(src)
/obj/item/inflatable/wall
	name = "inflatable wall"
	desc = "A folded membrane which rapidly expands into a large cubical shape on activation."
	icon_state = "folded_wall"
	atmos_canpass = CANPASS_NEVER
	deploy_path = /obj/structure/inflatable/wall

/obj/item/inflatable/door/
	name = "inflatable door"
	desc = "A folded membrane which rapidly expands into a simple door on activation."
	icon_state = "folded_door"
	deploy_path = /obj/structure/inflatable/door

/obj/structure/inflatable
	name = "inflatable"
	desc = "An inflated membrane. Do not puncture."
	density = TRUE
	anchored = TRUE
	opacity = 0
	icon = 'icons/obj/inflatable.dmi'
	icon_state = "wall"

	atmos_canpass = CANPASS_DENSITY

	var/undeploy_path = null
	health = 30
	explosion_coverage = 1

/obj/structure/inflatable/wall
	name = "inflatable wall"
	undeploy_path = /obj/item/inflatable/wall

/obj/structure/inflatable/New(location)
	..()
	update_nearby_tiles(need_rebuild=1)

/obj/structure/inflatable/Destroy()
	update_nearby_tiles()
	. = ..()

/obj/structure/inflatable/take_damage(damage)
	. = health - damage < 0 ? damage - (damage - health) : damage
	. *= explosion_coverage
	if(health < 0)
		deflate(TRUE)
	playsound(loc, 'sound/effects/Glasshit.ogg', 75, 1)
	return

/obj/structure/inflatable/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	return 0

/obj/structure/inflatable/bullet_act(obj/item/projectile/Proj)
	var/proj_damage = Proj.get_structure_damage()
	if(!proj_damage) return
	take_damage(proj_damage)
	..()
	return


/obj/structure/inflatable/explosion_act(target_power, explosion_handler/handler)
	var/absorbed = take_damage(target_power)
	return absorbed

/obj/structure/inflatable/attack_hand(mob/user as mob)
	add_fingerprint(user)
	return

/obj/structure/inflatable/attackby(obj/item/W as obj, mob/user as mob)
	if(!istype(W) || istype(W, /obj/item/inflatable_dispenser)) return

	if (can_puncture(W))
		visible_message(span_danger("[user] pierces [src] with [W]!"))
		deflate(TRUE)
	if(W.damtype == BRUTE || W.damtype == BURN)
		take_damage(W.force)
		..()
	return

/obj/structure/inflatable/CtrlClick()
	hand_deflate()

/obj/structure/inflatable/proc/deflate(violent=0)
	playsound(loc, 'sound/machines/hiss.ogg', 75, 1)
	if(violent)
		visible_message("[src] rapidly deflates!")
		var/obj/item/inflatable/torn/R = new /obj/item/inflatable/torn(loc)
		src.transfer_fingerprints_to(R)
		qdel(src)
	else
		if(!undeploy_path)
			return
		visible_message("\The [src] slowly deflates.")
		addtimer(CALLBACK(src, PROC_REF(slow_deflate)), 5 SECONDS)

/obj/structure/inflatable/proc/slow_deflate()
	var/obj/item/inflatable/R = new undeploy_path(src.loc)
	src.transfer_fingerprints_to(R)
	qdel(src)


/obj/structure/inflatable/verb/hand_deflate()
	set name = "Deflate"
	set category = "Object"
	set src in oview(1)

	if(isobserver(usr) || usr.restrained() || !usr.Adjacent(src))
		return

	verbs -= /obj/structure/inflatable/verb/hand_deflate
	deflate()

/obj/structure/inflatable/attack_generic(mob/user, damage, attack_verb)
	attack_animation(user)
	take_damage(damage)
	if(health <= 0)
		user.visible_message(span_danger("[user] [attack_verb] open the [src]!"))
	else
		user.visible_message(span_danger("[user] [attack_verb] at [src]!"))
	return TRUE

/obj/structure/inflatable/door //Based on mineral door code
	name = "inflatable door"
	density = TRUE
	anchored = TRUE
	opacity = FALSE

	icon_state = "door_closed"
	undeploy_path = /obj/item/inflatable/door

	var/state = 0 //closed, 1 == open
	var/isSwitchingStates = 0

/obj/structure/inflatable/door/attack_ai(mob/user as mob) //those aren't machinery, they're just big fucking slabs of a mineral
	if(isAI(user)) //so the AI can't open it
		return
	else if(isrobot(user)) //but cyborgs can
		if(get_dist(user,src) <= 1) //not remotely though
			return TryToSwitchState(user)

/obj/structure/inflatable/door/attack_hand(mob/user as mob)
	return TryToSwitchState(user)

/obj/structure/inflatable/door/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	if(air_group)
		return state
	if(istype(mover, /obj/effect/beam))
		return !opacity
	return !density

/obj/structure/inflatable/door/proc/TryToSwitchState(atom/user)
	if(isSwitchingStates) return
	if(ismob(user))
		var/mob/M = user
		if(M.client)
			if(iscarbon(M))
				var/mob/living/carbon/C = M
				if(!C.handcuffed)
					SwitchState()
			else
				SwitchState()
	else if(istype(user, /mob/living/exosuit))
		SwitchState()

/obj/structure/inflatable/door/proc/SwitchState()
	if(state)
		Close()
	else
		Open()
	update_nearby_tiles()

/obj/structure/inflatable/door/proc/Open()
	isSwitchingStates = 1
	flick("door_opening", src)
	sleep(10)
	density = FALSE
	state = 1
	update_icon()
	isSwitchingStates = 0

/obj/structure/inflatable/door/proc/Close()
	isSwitchingStates = 1
	flick("door_closing", src)
	sleep(10)
	density = TRUE
	state = 0
	update_icon()
	isSwitchingStates = 0

/obj/structure/inflatable/door/update_icon()
	if(state)
		icon_state = "door_open"
	else
		icon_state = "door_closed"

/obj/structure/inflatable/door/deflate(violent=0)
	playsound(loc, 'sound/machines/hiss.ogg', 75, 1)
	if(violent)
		visible_message("[src] rapidly deflates!")
		var/obj/item/inflatable/door/torn/R = new /obj/item/inflatable/door/torn(loc)
		src.transfer_fingerprints_to(R)
		qdel(src)
	else
		visible_message("[src] slowly deflates.")
		spawn(50)
			var/obj/item/inflatable/door/R = new /obj/item/inflatable/door(loc)
			src.transfer_fingerprints_to(R)
			qdel(src)

/obj/item/inflatable/torn
	name = "torn inflatable wall"
	desc = "A folded membrane which rapidly expands into a large cubical shape on activation. It is too torn to be usable."
	icon = 'icons/obj/inflatable.dmi'
	icon_state = "folded_wall_torn"

/obj/item/inflatable/torn/attack_self(mob/user)
	to_chat(user, span_notice("The inflatable wall is too torn to be inflated!"))
	add_fingerprint(user)

/obj/item/inflatable/door/torn
	name = "torn inflatable door"
	desc = "A folded membrane which rapidly expands into a simple door on activation. It is too torn to be usable."
	icon = 'icons/obj/inflatable.dmi'
	icon_state = "folded_door_torn"

/obj/item/inflatable/door/torn/attack_self(mob/user)
	to_chat(user, span_notice("The inflatable door is too torn to be inflated!"))
	add_fingerprint(user)

/obj/item/storage/briefcase/inflatable
	name = "inflatable barrier box"
	desc = "Contains inflatable walls and doors."
	icon_state = "inf_box"
	item_state = "syringe_kit"
	w_class = ITEM_SIZE_NORMAL
	max_storage_space = 28
	can_hold = list(/obj/item/inflatable)
	var/init_inflatable_count = 4

/obj/item/storage/briefcase/inflatable/New()
	..()
	while(init_inflatable_count)
		new /obj/item/inflatable/door(src)
		new /obj/item/inflatable/wall(src)
		init_inflatable_count -= 1
	init_inflatable_count = initial(init_inflatable_count)

/obj/item/storage/briefcase/inflatable/empty/init_inflatable_count = 0

