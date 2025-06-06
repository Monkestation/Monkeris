/*
 * Acid
 */
/obj/effect/acid
	name = "acid"
	desc = "Burbling corrosive stuff. Probably a bad idea to roll around in it."
	icon_state = "acid"
	icon = 'icons/mob/alien.dmi'
	layer = ABOVE_NORMAL_TURF_LAYER

	density = FALSE
	opacity = 0
	anchored = TRUE

	var/atom/target
	var/ticks = 0
	var/target_strength = 0

/obj/effect/acid/New(loc, supplied_target)
	..(loc)
	target = supplied_target

	if(isturf(target)) // Turf take twice as long to take down.
		target_strength = 8
	else
		target_strength = 4
	tick()

/obj/effect/acid/proc/tick()
	if(!target)
		qdel(src)

	ticks++
	if(ticks >= target_strength)
		target.visible_message(span_alium("\The [target] collapses under its own weight into a puddle of goop and undigested debris!"))
		if(istype(target, /turf/wall)) // I hate turf code.
			var/turf/wall/W = target
			W.dismantle_wall()
		else
			qdel(target)
		qdel(src)
		return

	switch(target_strength - ticks)
		if(6)
			visible_message(span_alium("\The [src.target] is holding up against the acid!"))
		if(4)
			visible_message(span_alium("\The [src.target]\s structure is being melted by the acid!"))
		if(2)
			visible_message(span_alium("\The [src.target] is struggling to withstand the acid!"))
		if(0 to 1)
			visible_message(span_alium("\The [src.target] begins to crumble under the acid!"))
	spawn(rand(150, 200)) tick()
