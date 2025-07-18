/obj/structure/bed/chair/e_chair
	name = "electric chair"
	desc = "Looks absolutely SHOCKING!"
	icon_state = "echair0"
	var/obj/item/assembly/shock_kit/part = new()
	var/last_time = 1

/obj/structure/bed/chair/e_chair/New()
	..()
	overlays += image('icons/obj/objects.dmi', src, "echair_over", MOB_LAYER + 1, dir)
	return

/obj/structure/bed/chair/e_chair/attackby(obj/item/tool/tool, mob/user)
	if(!tool.use_tool(user, src, WORKTIME_NORMAL, QUALITY_BOLT_TURNING, FAILCHANCE_VERY_EASY, required_stat = STAT_MEC))
		return
	var/obj/structure/bed/chair/C = new /obj/structure/bed/chair(loc)
	C.set_dir(dir)
	part.loc = loc
	part.master = null
	part = null
	qdel(src)

/obj/structure/bed/chair/e_chair/verb/toggle()
	set name = "Toggle Electric Chair"
	set category = "Object"
	set src in oview(1)

	icon_state = "echair1"
	to_chat(usr, span_notice("You switch on [src]."))
	shock()

	return

/obj/structure/bed/chair/e_chair/rotate()
	..()
	overlays.Cut()
	overlays += image('icons/obj/objects.dmi', src, "echair_over", MOB_LAYER + 1, dir)	//there's probably a better way of handling this, but eh. -Pete
	return

/obj/structure/bed/chair/e_chair/proc/shock()
	if(last_time + 50 > world.time)
		return
	last_time = world.time

	// special power handling
	var/area/A = get_area(src)
	if(!isarea(A))
		return
	if(!A.powered(STATIC_EQUIP))
		return
	A.use_power(STATIC_EQUIP, 5000)
	var/light = A.power_light
	A.updateicon()

	flick("echair1", src)
	var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
	s.set_up(12, 1, src)
	s.start()
	if(buckled_mob)
		buckled_mob.burn_skin(110)
		to_chat(buckled_mob, span_danger("You feel a deep shock course through your body!"))
		sleep(1)
		buckled_mob.burn_skin(110)
		buckled_mob.Stun(600)
	visible_message(span_danger("The electric chair went off!"), span_danger("You hear a deep sharp shock!"))
	icon_state = "echair0"

	A.power_light = light
	A.updateicon()

	return
