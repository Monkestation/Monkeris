/obj/effect/mine
	name = "Mine"
	desc = "I Better stay away from that thing."
	density = TRUE
	anchored = TRUE
	icon = 'icons/obj/weapons.dmi'
	icon_state = "uglymine"
	var/triggerproc = "explode" //name of the proc thats called when the mine is triggered
	var/triggered = 0

/obj/effect/mine/New()
	icon_state = "uglyminearmed"

/obj/effect/mine/Crossed(AM as mob|obj)
	Bumped(AM)

/obj/effect/mine/Bumped(mob/M as mob|obj)

	if(triggered) return

	if(ishuman(M))
		var/our_viewers = viewers(get_turf(src))
		var/htmlicon = icon2html(src, our_viewers)
		for(var/mob/O in our_viewers)
			to_chat(O, "<font color='red'>[M] triggered the [htmlicon] [src]</font>")
		triggered = 1
		call(src,triggerproc)(M)

/obj/effect/mine/proc/triggerrad(obj)
	var/datum/effect/effect/system/spark_spread/s = new
	s.set_up(3, 1, src)
	s.start()
	obj:radiation += 50
	qdel(src)

/obj/effect/mine/proc/triggerstun(obj)
	if(ismob(obj))
		var/mob/M = obj
		M.Stun(30)
	var/datum/effect/effect/system/spark_spread/s = new
	s.set_up(3, 1, src)
	s.start()
	qdel(src)

/obj/effect/mine/proc/triggern2o(obj)
	//example: n2o triggerproc
	//note: im lazy

	for (var/turf/floor/target in RANGE_TURFS(1,src))
		if(!target.blocks_air)
			target.assume_gas("sleeping_agent", 30)

	qdel(src)

/obj/effect/mine/proc/triggerplasma(obj)
	for (var/turf/floor/target in RANGE_TURFS(1,src))
		if(!target.blocks_air)
			target.assume_gas("plasma", 30)

			target.hotspot_expose(1000, CELL_VOLUME)

	qdel(src)

/obj/effect/mine/proc/triggerkick(obj)
	var/datum/effect/effect/system/spark_spread/s = new
	s.set_up(3, 1, src)
	s.start()
	qdel(obj:client)
	qdel(src)

/obj/effect/mine/proc/explode(obj)
	explosion(get_turf(src), 500, 250)
	qdel(src)

/obj/effect/mine/dnascramble
	name = "Radiation Mine"
	icon_state = "uglymine"
	triggerproc = "triggerrad"

/obj/effect/mine/plasma
	name = "Plasma Mine"
	icon_state = "uglymine"
	triggerproc = "triggerplasma"

/obj/effect/mine/kick
	name = "Kick Mine"
	icon_state = "uglymine"
	triggerproc = "triggerkick"

/obj/effect/mine/n2o
	name = "N2O Mine"
	icon_state = "uglymine"
	triggerproc = "triggern2o"

/obj/effect/mine/stun
	name = "Stun Mine"
	icon_state = "uglymine"
	triggerproc = "triggerstun"
