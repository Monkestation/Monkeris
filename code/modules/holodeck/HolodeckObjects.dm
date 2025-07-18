// Holographic Items!

// Holographic tables are in code/modules/tables/presets.dm
// Holographic racks are in code/modules/tables/rack.dm

/turf/floor/holofloor
	thermal_conductivity = 0

/turf/floor/holofloor/attackby(obj/item/W as obj, mob/user as mob)
	return
	// HOLOFLOOR DOES NOT GIVE A FUCK

/turf/floor/holofloor/explosion_act(target_power, explosion_handler/handler)
	if(target_power > 800) //No fucks otherwise
		take_damage(target_power / 2, BLAST)
	return 0

/turf/floor/holofloor/set_flooring()
	return

/turf/floor/holofloor/plating
	icon = 'icons/turf/flooring/plating.dmi'
	name = "plating"
	icon_state = "plating"
	initial_flooring = /decl/flooring/reinforced/plating

/turf/floor/holofloor/plating/under
	name = "underplating"
	icon_state = "under"
	icon = 'icons/turf/flooring/plating.dmi'
	initial_flooring = /decl/flooring/reinforced/plating/under

/turf/floor/holofloor/carpet
	name = "carpet"
	icon = 'icons/turf/flooring/carpet.dmi'
	icon_state = "carpet"
	initial_flooring = /decl/flooring/carpet

/turf/floor/holofloor/tiled
	name = "floor"
	icon = 'icons/turf/flooring/tiles_steel.dmi'
	icon_state = "tiles"
	initial_flooring = /decl/flooring/tiling/steel

/turf/floor/holofloor/tiled/bar_dance
	icon_state = "bar_dance"
	initial_flooring = /decl/flooring/tiling/steel/bar_light

/turf/floor/holofloor/tiled/bar_flat
	icon_state = "bar_flat"
	initial_flooring = /decl/flooring/tiling/steel/bar_flat

/turf/floor/holofloor/tiled/bar_light
	icon_state = "bar_light"
	initial_flooring = /decl/flooring/tiling/steel/bar_light

/turf/floor/holofloor/tiled/dark
	name = "floor"
	icon = 'icons/turf/flooring/tiles_dark.dmi'
	icon_state = "tiles"
	initial_flooring = /decl/flooring/tiling/dark

/turf/floor/holofloor/tiled/steel
	name = "floor"
	icon = 'icons/turf/flooring/tiles_steel.dmi'
	icon_state = "tiles"
	initial_flooring = /decl/flooring/tiling/steel

/turf/floor/holofloor/tiled/steel/gray_perforated
	icon_state = "gray_perforated"
	initial_flooring = /decl/flooring/tiling/steel/gray_perforated

/turf/floor/holofloor/wood
	name = "wooden floor"
	icon = 'icons/turf/flooring/wood.dmi'
	icon_state = "wood"
	initial_flooring = /decl/flooring/wood

/turf/floor/holofloor/grass
	name = "lush grass"
	icon = 'icons/turf/flooring/grass.dmi'
	icon_state = "grass0"
	initial_flooring = /decl/flooring/grass

/turf/floor/holofloor/snow
	name = "snow"
	icon = 'icons/turf/floors.dmi'
	icon_state = "snow"

/turf/floor/holofloor/space
	icon = 'icons/turf/space.dmi'
	name = "\proper space"
	icon_state = "0"

/turf/floor/holofloor/reinforced
	icon = 'icons/turf/flooring/tiles.dmi'
	initial_flooring = /decl/flooring/reinforced
	name = "reinforced holofloor"
	icon_state = "reinforced"

/turf/floor/holofloor/space/New()
	icon_state = "[((x + y) ^ ~(x * y) + z) % 25]"

/turf/floor/holofloor/beach
	desc = "Uncomfortably gritty for a hologram."
	icon = 'icons/misc/beach.dmi'
	initial_flooring = null

/turf/floor/holofloor/beach/sand
	name = "sand"
	icon_state = "desert"

/turf/floor/holofloor/beach/coastline
	name = "coastline"
	icon = 'icons/misc/beach2.dmi'
	icon_state = "sandwater"

/turf/floor/holofloor/beach/water
	name = "water"
	icon_state = "seashallow"

/turf/floor/holofloor/desert
	name = "desert sand"
	desc = "Uncomfortably gritty for a hologram."
	icon_state = "asteroid"
	icon = 'icons/turf/flooring/asteroid.dmi'
	initial_flooring = null

/turf/floor/holofloor/desert/New()
	..()
	if(prob(10))
		overlays += "asteroid[rand(0,9)]"

/turf/open/holonofloor // Simulated nothingness

/turf/open/holonofloor/attackby(obj/item/W as obj, mob/user as mob)
	return

/turf/open/holonofloor/ChangeTurf(new_turf_type, force_lighting_update)
	if(new_turf_type == /turf/space) // If we want to become space,
		var/area/A = get_area(src)
		if(istype(A, /area/holodeck/source)) // Check if we are a holodeck source,
			return // And return to prevent becoming space
	..()

/turf/open/holonofloor/update_air_properties()
	var/area/A = get_area(src)
	if(istype(A, /area/holodeck/source)) // Check if we are a holodeck source,
		return // deny air updates
	..()

/obj/structure/railing/holorailing

/obj/structure/railing/holorailing/attackby(obj/item/W as obj, mob/user as mob)
	return

/obj/structure/railing/holorailing/take_damage(amount)
	return

/obj/structure/railing/holorailing/grey
	name = "grey railing"
	desc = "A standard steel railing. Prevents stupid people from falling to their doom."
	icon_modifier = "grey_"
	icon_state = "grey_railing0"

/obj/structure/lattice/hololattice

/obj/structure/lattice/hololattice/attackby(obj/item/I, mob/user)
	return

/obj/structure/catwalk/holo

/obj/structure/catwalk/holo/attackby(obj/item/I, mob/user)
	return

/obj/item/stool/holostool
	damtype = HALLOSS

/obj/item/stool/holostool/attackby(obj/item/W as obj, mob/user as mob)
	if(istool(W) || istype(W,/obj/item/stack))
		return
	..()

/obj/item/stool/holostool/attack(mob/M as mob, mob/user as mob)
	if (prob(5) && isliving(M))
		user.visible_message(span_danger("[user] breaks [src] over [M]'s back, disappearing into mist!"))
		user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
		user.do_attack_animation(M)

		user.remove_from_mob(src)
		qdel(src)
		var/mob/living/T = M
		T.Weaken(10)
		T.damage_through_armor(20, HALLOSS, BP_CHEST, ARMOR_MELEE)
		return
	..()

/obj/item/stool/holostool/bar
	name = "bar stool"
	icon_state = "bar_stool"

/obj/item/stool/holostool/bar/update_icon()
	return

/obj/structure/bed/chair/custom/holochair

/obj/structure/bed/chair/custom/holochair/attackby(obj/item/W as obj, mob/user as mob)
	if(istool(W) || istype(W,/obj/item/stack))
		return
	..()

/obj/structure/bed/chair/custom/holochair/bar
	name = "bar chair"
	desc = "Modern design and soft pad. Served up with the drink and great company."
	icon_state = "bar_chair"

/obj/item/clothing/gloves/boxing/hologlove
	name = "boxing gloves"
	desc = "Because you really needed another excuse to punch your crewmates."
	icon_state = "boxing"
	item_state = "boxing"

/obj/structure/window/reinforced/holowindow/Destroy()
	. = ..()

/obj/structure/window/reinforced/holowindow/attackby(obj/item/W as obj, mob/user as mob)
	if(!istype(W) || W.flags & NOBLUDGEON)
		return

	if(istype(W, /obj/item/tool/screwdriver))
		to_chat(user, (span_notice("It's a holowindow, you can't unfasten it!")))
	else if(istype(W, /obj/item/tool/crowbar) && reinf && state <= 1)
		to_chat(user, (span_notice("It's a holowindow, you can't pry it!")))
	else if(istype(W, /obj/item/tool/wrench) && !anchored && (!state || !reinf))
		to_chat(user, (span_notice("It's a holowindow, you can't dismantle it!")))
	else
		if(W.damtype == BRUTE || W.damtype == BURN)
			hit(W.force)
			if(health <= 7)
				anchored = FALSE
				update_nearby_icons()
				step(src, get_dir(user, src))
		else
			playsound(loc, 'sound/effects/Glasshit.ogg', 75, 1)
		..()
	return

/obj/structure/window/reinforced/holowindow/shatter(display_message = 1)
	playsound(src, "shatter", 70, 1)
	if(display_message)
		visible_message("[src] fades away as it shatters!")
	qdel(src)
	return

/obj/structure/window/reinforced/holowindow/disappearing/Destroy()
	. = ..()

/obj/machinery/door/window/holowindoor/Destroy()
	. = ..()

/obj/machinery/door/window/holowindoor/attackby(obj/item/I as obj, mob/user as mob)

	if (src.operating == 1)
		return

	if(src.density && istype(I, /obj/item) && !istype(I, /obj/item/card))
		var/aforce = I.force
		playsound(src.loc, 'sound/effects/Glasshit.ogg', 75, 1)
		visible_message(span_red("<B>[src] was hit by [I].</B>"))
		if(I.damtype == BRUTE || I.damtype == BURN)
			take_damage(aforce)
		return

	src.add_fingerprint(user)
	if (!src.requiresID())
		user = null

	if (src.allowed(user))
		if (src.density)
			open()
		else
			close()

	else if (src.density)
		flick(text("[]deny", src.base_state), src)

	return

/obj/machinery/door/window/holowindoor/shatter(display_message = 1)
	src.density = FALSE
	playsound(src, "shatter", 70, 1)
	if(display_message)
		visible_message("[src] fades away as it shatters!")
	qdel(src)

// Holo type items

/obj/item/holo
	damtype = HALLOSS
	no_attack_log = 1
	bad_type = /obj/item/holo

/obj/item/holo/esword
	desc = "May the force be within you. Sorta."
	icon_state = "sword0"
	force = 3
	throw_speed = 1
	throw_range = 5
	throwforce = 0
	w_class = ITEM_SIZE_SMALL
	flags = NOBLOODY
	var/active = 0
	var/item_color

/obj/item/holo/esword/green
	item_color = "green"

/obj/item/holo/esword/red
	item_color = "red"

/obj/item/holo/esword/handle_shield(mob/user, damage, atom/damage_source = null, mob/attacker = null, def_zone = null, attack_text = "the attack")
	if(active && default_parry_check(user, attacker, damage_source) && prob(50))
		user.visible_message(span_danger("\The [user] parries [attack_text] with \the [src]!"))

		var/datum/effect/effect/system/spark_spread/spark_system = new /datum/effect/effect/system/spark_spread()
		spark_system.set_up(5, 0, user.loc)
		spark_system.start()
		playsound(user.loc, 'sound/weapons/blade1.ogg', 50, 1)
		return 1
	return 0

/obj/item/holo/esword/Initialize(mapload)
	. = ..()
	if(!item_color)
		item_color = pick("red","blue","green","purple")

/obj/item/holo/esword/attack_self(mob/living/user as mob)
	active = !active
	if (active)
		force = 30
		icon_state = "sword[item_color]"
		w_class = ITEM_SIZE_BULKY
		playsound(user, 'sound/weapons/saberon.ogg', 50, 1)
		to_chat(user, span_notice("[src] is now active."))
	else
		force = 3
		icon_state = "sword0"
		w_class = ITEM_SIZE_SMALL
		playsound(user, 'sound/weapons/saberoff.ogg', 50, 1)
		to_chat(user, span_notice("[src] can now be concealed."))

	update_wear_icon()

	add_fingerprint(user)

//BASKETBALL OBJECTS

/obj/item/beach_ball/holoball
	icon = 'icons/obj/basketball.dmi'
	icon_state = "basketball"
	name = "basketball"
	item_state = "basketball"
	desc = "Here's your chance, do your dance at the Space Jam."
	w_class = ITEM_SIZE_BULKY //Stops people from hiding it in their bags/pockets

/obj/structure/holohoop
	name = "basketball hoop"
	desc = "Boom, Shakalaka!"
	icon = 'icons/obj/basketball.dmi'
	icon_state = "hoop"
	anchored = TRUE
	density = TRUE
	throwpass = 1

/obj/structure/holohoop/affect_grab(mob/living/user, mob/living/target, state)
	if(state == GRAB_PASSIVE)
		to_chat(user, span_warning("You need a better grip to do that!"))
		return FALSE
	target.forceMove(src.loc)
	target.Weaken(5)
	visible_message(span_warning("[user] dunks [target] into the [src]!"))
	return TRUE

/obj/structure/holohoop/attackby(obj/item/W as obj, mob/user as mob)
	if (istype(W, /obj/item) && get_dist(src,user)<2)
		user.drop_item(src.loc)
		visible_message(span_notice("[user] dunks [W] into the [src]!"), 3)
		return

/obj/structure/holohoop/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	if (istype(mover,/obj/item) && mover.throwing)
		var/obj/item/I = mover
		if(istype(I, /obj/item/projectile))
			return
		if(prob(50))
			I.forceMove(src.loc)
			visible_message(span_notice("Swish! \the [I] lands in \the [src]."))
		else
			visible_message(span_warning("\The [I] bounces off of \the [src]'s rim!"))
		return 0
	else
		return ..(mover, target, height, air_group)


/obj/machinery/readybutton
	name = "Ready Declaration Device"
	desc = "This device is used to declare ready. If all devices in an area are ready, the event will begin!"
	icon = 'icons/obj/monitors.dmi'
	icon_state = "auth_off"
	var/ready = 0
	var/area/currentarea = null
	var/eventstarted = 0

	anchored = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 2
	active_power_usage = 6
	power_channel = STATIC_ENVIRON

/obj/machinery/readybutton/attack_ai(mob/user as mob)
	to_chat(user, "The ship AI is not to interact with these devices!")
	return

/obj/machinery/readybutton/New()
	..()


/obj/machinery/readybutton/attackby(obj/item/W as obj, mob/user as mob)
	to_chat(user, "The device is a solid button, there's nothing you can do with it!")

/obj/machinery/readybutton/attack_hand(mob/user as mob)

	if(user.stat || stat & (NOPOWER|BROKEN))
		to_chat(user, "This device is not powered.")
		return

	if(!user.IsAdvancedToolUser())
		return 0

	currentarea = get_area(src.loc)
	if(!currentarea)
		qdel(src)

	if(eventstarted)
		to_chat(usr, "The event has already begun!")
		return

	ready = !ready

	update_icon()

	var/numbuttons = 0
	var/numready = 0
	for(var/obj/machinery/readybutton/button in currentarea)
		numbuttons++
		if (button.ready)
			numready++

	if(numbuttons == numready)
		begin_event()

/obj/machinery/readybutton/update_icon()
	if(ready)
		icon_state = "auth_on"
	else
		icon_state = "auth_off"

/obj/machinery/readybutton/proc/begin_event()

	eventstarted = 1

	for(var/obj/structure/window/reinforced/holowindow/disappearing/W in currentarea)
		qdel(W)

	for(var/mob/M in currentarea)
		to_chat(M, "FIGHT!")

//Holocarp

/mob/living/simple_animal/hostile/carp/holodeck
	icon = 'icons/mob/AI.dmi'
	icon_state = "holo4"
	icon_dead = "holo4"
	alpha = 127
	icon_gib = null
	meat_amount = 0
	meat_type = null

/mob/living/simple_animal/hostile/carp/holodeck/New()
	..()
	set_light(2) //hologram lighting

/mob/living/simple_animal/hostile/carp/holodeck/proc/set_safety(safe)
	if (safe)
		faction = "neutral"
		melee_damage_lower = 0
		melee_damage_upper = 0
		environment_smash = 0
		destroy_surroundings = 0
	else
		faction = "carp"
		melee_damage_lower = initial(melee_damage_lower)
		melee_damage_upper = initial(melee_damage_upper)
		environment_smash = initial(environment_smash)
		destroy_surroundings = initial(destroy_surroundings)

/mob/living/simple_animal/hostile/carp/holodeck/gib()
	derez() //holograms can't gib

/mob/living/simple_animal/hostile/carp/holodeck/death()
	..()
	derez()

/mob/living/simple_animal/hostile/carp/holodeck/proc/derez()
	visible_message(span_notice("\The [src] fades away!"))
	qdel(src)
