// The lighting system
//
// consists of light fixtures (/obj/machinery/light) and light tube/bulb items (/obj/item/light)


// status values shared between lighting fixtures and items
#define LIGHT_OK 0
#define LIGHT_EMPTY 1
#define LIGHT_BROKEN 2
#define LIGHT_BURNED 3
#define LIGHT_BULB_TEMPERATURE 400 //K - used value for a 60W bulb

/obj/machinery/light_construct
	name = "light fixture frame"
	desc = "A light fixture under construction."
	icon = 'icons/obj/lighting.dmi'
	icon_state = "tube-construct-stage1"
	anchored = TRUE
	layer = WALL_OBJ_LAYER
	var/stage = 1
	var/fixture_type = "tube"
	var/sheets_refunded = 2
	var/obj/machinery/light/newlight = null

/obj/machinery/light_construct/New()
	..()
	if (fixture_type == "bulb")
		icon_state = "bulb-construct-stage1"
	else if (istype(src, /obj/machinery/light_construct/floor))
		icon_state = "floortube-construct-stage1"

/obj/machinery/light_construct/examine(mob/user, extra_description = "")
	if(get_dist(user, src) < 2)
		switch(stage)
			if(1)
				extra_description += "\nIt's an empty frame."
			if(2)
				extra_description += "\nIt's wired."
			if(3)
				extra_description += "\nThe casing is closed."
	..(user, extra_description)

/obj/machinery/light_construct/attackby(obj/item/I, mob/user)

	src.add_fingerprint(user)

	var/list/usable_qualities = list()
	if(stage == 2)
		usable_qualities.Add(QUALITY_SCREW_DRIVING)
	if(stage == 2)
		usable_qualities.Add(QUALITY_WIRE_CUTTING)
	if(stage == 1)
		usable_qualities.Add(QUALITY_BOLT_TURNING)


	var/tool_type = I.get_tool_type(user, usable_qualities, src)
	switch(tool_type)

		if(QUALITY_SCREW_DRIVING)
			if(stage == 2)
				if(I.use_tool(user, src, WORKTIME_NEAR_INSTANT, tool_type, FAILCHANCE_VERY_EASY, required_stat = STAT_MEC))
					switch(fixture_type)
						if ("tube")
							src.icon_state = "tube-empty"
						if("bulb")
							src.icon_state = "bulb-empty"
					src.stage = 3
					user.visible_message("[user.name] closes [src]'s casing.", \
						"You close [src]'s casing.", "You hear a noise.")

					switch(fixture_type)

						if("tube")
							if (!istype(src, /obj/machinery/light_construct/floor))
								newlight = new /obj/machinery/light/built(src.loc)
							else
								newlight = new /obj/machinery/light/floor/built(src.loc)
						if ("bulb")
							newlight = new /obj/machinery/light/small/built(src.loc)

					newlight.dir = src.dir
					src.transfer_fingerprints_to(newlight)
					qdel(src)
					return
				return

		if(QUALITY_WIRE_CUTTING)
			if(stage == 2)
				if(I.use_tool(user, src, WORKTIME_FAST, tool_type, FAILCHANCE_VERY_EASY, required_stat = STAT_MEC))
					src.stage = 1
					switch(fixture_type)
						if ("tube")
							if (!istype(src, /obj/machinery/light_construct/floor))
								src.icon_state = "tube-construct-stage1"
							else
								src.icon_state = "floortube-construct-stage1"
						if("bulb")
							src.icon_state = "bulb-construct-stage1"
					new /obj/item/stack/cable_coil(get_turf(src.loc), 1, "red")
					user.visible_message("[user.name] removes the wiring from [src].", \
						"You remove the wiring from [src].", "You hear a noise.")
				return
			return

		if(QUALITY_BOLT_TURNING)
			if(stage == 1)
				if (src.stage == 1)
					to_chat(user, "You begin deconstructing \a [src].")
					if(I.use_tool(user, src, WORKTIME_NORMAL, tool_type, FAILCHANCE_VERY_EASY, required_stat = STAT_MEC))
						new /obj/item/stack/material/steel( get_turf(src.loc), sheets_refunded )
						user.visible_message("[user.name] deconstructs [src].", \
							"You deconstruct [src].", "You hear a noise.")
						qdel(src)
						return
				return

		if(ABORT_CHECK)
			return

	if(istype(I, /obj/item/stack/cable_coil))
		if (src.stage != 1) return
		var/obj/item/stack/cable_coil/coil = I
		if (coil.use(1))
			switch(fixture_type)
				if ("tube")
					if (!istype(src, /obj/machinery/light_construct/floor))
						src.icon_state = "tube-construct-stage2"
					else
						src.icon_state = "floortube-construct-stage2"
				if("bulb")
					src.icon_state = "bulb-construct-stage2"
			src.stage = 2
			user.visible_message("[user.name] adds wires to [src].", \
				"You add wires to [src].")
		return

	else
		..()

/obj/machinery/light_construct/small
	name = "small light fixture frame"
	desc = "A small light fixture under construction."
	icon = 'icons/obj/lighting.dmi'
	icon_state = "bulb-construct-stage1"
	anchored = TRUE
	layer = 5
	stage = 1
	fixture_type = "bulb"
	sheets_refunded = 1

/obj/machinery/light_construct/floor //floorlight
	name = "floorlight fixture frame"
	icon_state = "floortube-construct-stage1"
	layer = 2.5

// the standard tube light fixture
/obj/machinery/light
	name = "light fixture"
	icon = 'icons/obj/lighting.dmi'
	var/base_state = "tube"		// base description and icon_state
	icon_state = "tube1"
	desc = "A lighting fixture."
	anchored = TRUE
	layer = WALL_OBJ_LAYER
	use_power = ACTIVE_POWER_USE
	idle_power_usage = 2
	active_power_usage = 20
	power_channel = STATIC_LIGHT //Lights are calc'd via area so they dont need to be in the machine list
	var/on = FALSE					// 1 if on, 0 if off
	var/on_gs = 0
	var/autoattach = 0			//If this attaches to a wall automatically
	var/brightness_range = 7	// luminosity when on, also used in power calculation
	var/brightness_power = 2
	var/brightness_color = COLOR_LIGHTING_DEFAULT_BRIGHT
	var/status = LIGHT_OK		// LIGHT_OK, _EMPTY, _BURNED or _BROKEN
	var/flick_lighting = 0
	var/light_type = /obj/item/light/tube		// the type of light item
	var/fitting = "tube"
	var/switchcount = 0			// count of number of times switched on/off
								// this is used to calc the probability the light burns out
	var/needsound
	var/rigged = 0				// true if rigged to explode
	var/firealarmed = 0
	var/atmosalarmed = 0

// the smaller bulb light fixture

/obj/machinery/light/floor
	name = "floorlight fixture"
	base_state = "floortube"
	icon_state = "floortube1"
	layer = 2.5

/obj/machinery/light/small
	icon_state = "bulb1"
	base_state = "bulb"
	fitting = "bulb"
	brightness_range = 3
	brightness_power = 1
	desc = "A small lighting fixture."
	light_type = /obj/item/light/bulb

/obj/machinery/light/small/autoattach
	autoattach = 1

/obj/machinery/light/spot
	name = "spotlight"
	fitting = "large tube"
	light_type = /obj/item/light/tube/large
	brightness_range = 12
	brightness_power = 4

/obj/machinery/light/built/New()
	status = LIGHT_EMPTY
	update(0)
	..()

/obj/machinery/light/small/built/New()
	status = LIGHT_EMPTY
	update(0)
	..()

/obj/machinery/light/floor/built/New() //WHAT IT IS?!?!??!?!?
	status = LIGHT_EMPTY
	update(0)
	..()

// create a new lighting fixture
/obj/machinery/light/Initialize()
	. = ..()
	if(autoattach)
		auto_turn_destructive()
		dir = GLOB.reverse_dir[dir]

	if(!src)
		return 0

	var/area/A = get_area(src)
	if(A && !A.requires_power)
		on = TRUE

	var/area/location = get_area(loc)
	if(location)
		if(location.area_light_color)
			brightness_color = location.area_light_color

	update(0)

/obj/machinery/light/Destroy()
	var/area/A = get_area(src)
	if(A)
		on = FALSE
//		A.update_lights()
	. = ..()

/obj/machinery/light/update_icon()

	switch(status)		// set icon_states
		if(LIGHT_OK)
			if(firealarmed && on && cmptext(base_state,"tube"))
				icon_state = "[base_state]_alert"
			else if(atmosalarmed && on && cmptext(base_state,"tube"))
				icon_state = "[base_state]_alert_atmos"
			else
				icon_state = "[base_state][on]"
		if(LIGHT_EMPTY)
			icon_state = "[base_state]-empty"
			on = FALSE
		if(LIGHT_BURNED)
			icon_state = "[base_state]-burned"
			on = FALSE
		if(LIGHT_BROKEN)
			icon_state = "[base_state]-broken"
			on = FALSE
	return

/obj/machinery/light/proc/set_blue()
	if(on)
		if(cmptext(base_state,"tube"))
			atmosalarmed = 1
			firealarmed = 0
			brightness_color = COLOR_LIGHTING_BLUE_MACHINERY
		update()

/obj/machinery/light/proc/set_red()
	if(on)
		if(cmptext(base_state,"tube"))
			firealarmed = 1
			atmosalarmed = 0
			brightness_color = COLOR_LIGHTING_RED_MACHINERY
		update()

/obj/machinery/light/proc/reset_color()
	if(on)
		var/area/location = get_area(loc)
		if(!location.is_maintenance)
			firealarmed = 0
			atmosalarmed = 0

			if(location.area_light_color)
				brightness_color = location.area_light_color

			else
				brightness_color = COLOR_LIGHTING_DEFAULT_BRIGHT

		update()


// update the icon_state and luminosity of the light depending on its state
/obj/machinery/light/proc/update(trigger = 1)

	update_icon()
	if(on == TRUE)
		if(needsound == 1)
			playsound(src.loc, 'sound/effects/Custom_lights.ogg', 65, 1)
			needsound = 0
	else
		needsound = 1
	if(on)
		if(light_range != brightness_range || light_power != brightness_power || light_color != brightness_color)
			switchcount++
			if(rigged)
				if(status == LIGHT_OK && trigger)

					log_admin("LOG: Rigged light explosion, last touched by [fingerprintslast]")
					message_admins("LOG: Rigged light explosion, last touched by [fingerprintslast]")

					explode()
			else if( prob( min(60, switchcount*switchcount*0.1) ) )
				if(status == LIGHT_OK && trigger)
					status = LIGHT_BURNED
					icon_state = "[base_state]-burned"
					on = FALSE
					set_light(0, 0)
					active_power_usage = 0 //burnt => no power flow => no power consumption
					idle_power_usage = 0
			else
				set_light(brightness_range, brightness_power, brightness_color)
				active_power_usage = light_power * light_range * 10
				set_power_use(ACTIVE_POWER_USE)
	else
		set_light(0)
		idle_power_usage = (light_power + light_range) * 0.1
		set_power_use(IDLE_POWER_USE)

	if(on != on_gs)
		on_gs = on

/obj/machinery/light/attack_generic(mob/user, damage)
	if(!damage)
		return
	if(status == LIGHT_EMPTY||status == LIGHT_BROKEN)
		to_chat(user, "That object is useless to you.")
		return
	if(!(status == LIGHT_OK||status == LIGHT_BURNED))
		return
	visible_message(span_danger("[user] smashes the light!"))
	attack_animation(user)
	broken()
	return 1

// attempt to set the light's on/off status
// will not switch on if broken/burned/empty
/obj/machinery/light/proc/seton(s)
	on = (s && status == LIGHT_OK)
	update()

// examine verb
/obj/machinery/light/examine(mob/user, extra_description = "")
	switch(status)
		if(LIGHT_OK)
			extra_description += "It is turned [on? "on" : "off"]."
		if(LIGHT_EMPTY)
			extra_description += "The [fitting] has been removed."
		if(LIGHT_BURNED)
			extra_description += "The [fitting] is burnt out."
		if(LIGHT_BROKEN)
			extra_description += "The [fitting] has been smashed."
	..(user, extra_description)

// attack with item - insert light (if right type), otherwise try to break the light
/obj/machinery/light/attackby(obj/item/I, mob/user)

	//Light replacer code
	if(istype(I, /obj/item/device/lightreplacer))
		var/obj/item/device/lightreplacer/LR = I
		if(isliving(user))
			var/mob/living/U = user
			LR.ReplaceLight(src, U)
			return

	// attempt to insert light
	if(istype(I, /obj/item/light))
		if(status == LIGHT_OK)
			to_chat(user, span_warning("There is a [fitting] already inserted."))
			return
		else
			src.add_fingerprint(user)
			var/obj/item/light/L = I
			if(istype(L, light_type))
				user.drop_item()

				if(status != LIGHT_EMPTY)
					drop_light_tube(user)
					to_chat(user, span_notice("You replace [L]."))
				else
					to_chat(user, span_notice("You insert [L]."))

				status = L.status
				switchcount = L.switchcount
				rigged = L.rigged
				brightness_range = L.brightness_range
				brightness_power = L.brightness_power
				brightness_color = L.brightness_color
				on = has_power()
				update()

				qdel(L)

				if(on && rigged)
					log_admin("LOG: Rigged light explosion, last touched by [fingerprintslast]")
					message_admins("LOG: Rigged light explosion, last touched by [fingerprintslast]")

					explode()
			else
				to_chat(user, span_warning("This type of light requires a [fitting]."))
				return

		// attempt to break the light
		//If xenos decide they want to smash a light bulb with a toolbox, who am I to stop them? /N

	else if(status != LIGHT_BROKEN && status != LIGHT_EMPTY)


		if(prob(1+I.force * 5))

			to_chat(user, "You hit the light, and it smashes!")
			for(var/mob/M in viewers(get_turf(src)))
				if(M == user)
					continue
				M.show_message("[user.name] smashed the light!", 3, "You hear a tinkle of breaking glass", 2)
			if(on && (I.flags & CONDUCT))
				//if(!user.mutations & COLD_RESISTANCE)
				if (prob(12))
					electrocute_mob(user, get_area(src), src, 0.3)
			broken()

		else
			to_chat(user, "You hit the light!")

	// attempt to stick weapon into light socket
	else if(status == LIGHT_EMPTY)
		if(QUALITY_SCREW_DRIVING in I.tool_qualities)
			if(I.use_tool(user, src, WORKTIME_FAST, QUALITY_SCREW_DRIVING, FAILCHANCE_EASY, required_stat = STAT_MEC))
				user.visible_message("[user.name] opens [src]'s casing.", \
					"You open [src]'s casing.", "You hear a noise.")
				var/obj/machinery/light_construct/newlight = null
				switch(fitting)
					if("tube")
						newlight = new /obj/machinery/light_construct(src.loc)
						newlight.icon_state = "tube-construct-stage2"

					if("bulb")
						newlight = new /obj/machinery/light_construct/small(src.loc)
						newlight.icon_state = "bulb-construct-stage2"
				newlight.dir = src.dir
				newlight.stage = 2
				newlight.fingerprints = src.fingerprints
				newlight.fingerprintshidden = src.fingerprintshidden
				newlight.fingerprintslast = src.fingerprintslast
				qdel(src)
				return

		to_chat(user, "You stick \the [I] into the light socket!")
		if(has_power() && (I.flags & CONDUCT))
			var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
			s.set_up(3, 1, src)
			s.start()
			//if(!user.mutations & COLD_RESISTANCE)
			if (prob(75))
				electrocute_mob(user, get_area(src), src, rand(0.7,1))


// returns whether this light has power
// true if area has power and lightswitch is on
/obj/machinery/light/proc/has_power()
	var/area/A = get_area(src)
	return A && A.lightswitch && (!A.requires_power || A.power_light)

/obj/machinery/light/proc/flick_light(amount = rand(10, 20))
	var/on_s = on // s stands for safety
	if(flick_lighting)
		return
	flick_lighting = TRUE
	spawn(0)
		if(on && status == LIGHT_OK)
			for(var/i in 1 to amount)
				if(status != LIGHT_OK)
					break
				if(on_s != on)
					return
				on_s = !on_s
				on = !on
				update(0)
				sleep(rand(5, 15))
			on = (status == LIGHT_OK)
			update(0)
		flick_lighting = FALSE

// ai attack - make lights flick_light, because why not

/obj/machinery/light/attack_ai(mob/user)
	src.flick_light(1)
	return

// attack with hand - remove tube/bulb
// if hands aren't protected and the light is on, burn the player
/obj/machinery/light/attack_hand(mob/user)

	add_fingerprint(user)

	if(status == LIGHT_EMPTY)
		to_chat(user, "There is no [fitting] in this light.")
		return

	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		if(H.species.can_shred(H))
			for(var/mob/M in viewers(get_turf(src)))
				M.show_message(span_danger("[user.name] smashed the light!"), 3, span_warning("You hear a tinkle of breaking glass"), 2)
			broken()
			return

	// make it burn hands if not wearing fire-insulated gloves
	if(on)
		var/prot = FALSE
		var/mob/living/carbon/human/H = user

		if(istype(H))
			if(H.species.heat_level_1 > LIGHT_BULB_TEMPERATURE)
				prot = TRUE
			else if(H.gloves)
				var/obj/item/clothing/gloves/G = H.gloves
				if(G.max_heat_protection_temperature)
					if(G.max_heat_protection_temperature > LIGHT_BULB_TEMPERATURE)
						prot = TRUE
		else
			prot = TRUE

		if(prot) // || (COLD_RESISTANCE in user.mutations)
			to_chat(user, span_notice("You remove the light [fitting]"))
		else if(get_active_mutation(user, MUTATION_TELEKINESIS))
			to_chat(user, span_notice("You telekinetically remove the light [fitting]."))
		else
			to_chat(user, "You try to remove the light [fitting], but it's too hot and you don't want to burn your hand.")
			return				// if burned, don't remove the light
	else
		to_chat(user, span_notice("You remove the light [fitting]."))

	drop_light_tube(user)


/obj/machinery/light/attack_tk(mob/user)
	if(status == LIGHT_EMPTY)
		to_chat(user, "There is no [fitting] in this light.")
		return

	to_chat(user, span_notice("You telekinetically remove the light [fitting]."))
	drop_light_tube()


// create a light tube/bulb item and put it in the drop location
/obj/machinery/light/proc/drop_light_tube(mob/living/user)
	var/obj/item/light/L = new light_type(drop_location())
	L.status = status
	L.rigged = rigged
	L.brightness_range = brightness_range
	L.brightness_power = brightness_power
	L.brightness_color = brightness_color

	// light item inherits the switchcount, then zero it
	L.switchcount = switchcount
	switchcount = 0

	L.update()

	status = LIGHT_EMPTY
	set_light(0, 0)
	update()

	// If the target is a mob, try to put the bulb in mob's hand
	if(user)
		L.add_fingerprint(user)
		user.put_in_active_hand(L)


// break the light and make sparks if was on

/obj/machinery/light/proc/broken(skip_sound_and_sparks = 0)
	if(status == LIGHT_EMPTY)
		return

	if(!skip_sound_and_sparks)
		if(status == LIGHT_OK || status == LIGHT_BURNED)
			playsound(src.loc, 'sound/effects/Glasshit.ogg', 75, 1)
		if(on)
			var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
			s.set_up(3, 1, src)
			s.start()
	status = LIGHT_BROKEN
	set_light(0, 0)
	update()

/obj/machinery/light/proc/fix()
	if(status == LIGHT_OK)
		return
	status = LIGHT_OK
	on = TRUE
	update()

// explosion effect
// destroy the whole light fixture or just shatter it

/obj/machinery/light/take_damage(amount)
	. = ..()
	if(QDELETED(src))
		return 0
	broken()

// called when area power state changes
/obj/machinery/light/power_change()
	seton(has_power())

// called when on fire

/obj/machinery/light/fire_act(datum/gas_mixture/air, exposed_temperature, exposed_volume)
	if(prob(max(0, exposed_temperature - 673)))   //0% at <400C, 100% at >500C
		broken()

// explode the light

/obj/machinery/light/proc/explode()
	broken()	// break it first to give a warning
	sleep(2)
	explosion(get_turf(src), 60, 20)
	sleep(1)
	qdel(src)

// the light item
// can be tube or bulb subtypes
// will fit into empty /obj/machinery/light of the corresponding type

/obj/item/light
	icon = 'icons/obj/lighting.dmi'
	force = WEAPON_FORCE_HARMLESS
	throwforce = WEAPON_FORCE_HARMLESS
	w_class = ITEM_SIZE_TINY
	var/status = 0		// LIGHT_OK, LIGHT_BURNED or LIGHT_BROKEN
	var/base_state
	var/switchcount = 0	// number of times switched
	matter = list(MATERIAL_STEEL = 1)
	var/rigged = 0		// true if rigged to explode
	var/brightness_range = 2 //how much light it gives off
	var/brightness_power = 1
	var/brightness_color = null
	preloaded_reagents = list("silicon" = 10, "tungsten" = 5)

/obj/item/light/tube
	name = "light tube"
	desc = "A replacement light tube."
	icon_state = "ltube"
	base_state = "ltube"
	item_state = "c_tube"
	matter = list(MATERIAL_GLASS = 1)
	brightness_range = 8
	brightness_power = 3

/obj/item/light/tube/large
	w_class = ITEM_SIZE_SMALL
	name = "large light tube"
	brightness_range = 15
	brightness_power = 4

/obj/item/light/bulb
	name = "light bulb"
	desc = "A replacement light bulb."
	icon_state = "lbulb"
	base_state = "lbulb"
	item_state = "contvapour"
	matter = list(MATERIAL_GLASS = 1)
	brightness_range = 5
	brightness_power = 2

/obj/item/light/throw_impact(atom/hit_atom)
	..()
	shatter()

/obj/item/light/bulb/fire
	name = "fire bulb"
	desc = "A replacement fire bulb."
	icon_state = "fbulb"
	base_state = "fbulb"
	item_state = "egg4"
	matter = list(MATERIAL_GLASS = 1)
	brightness_range = 5
	brightness_power = 2

// update the icon state and description of the light

/obj/item/light/proc/update()
	switch(status)
		if(LIGHT_OK)
			icon_state = base_state
			desc = "A replacement [name]."
		if(LIGHT_BURNED)
			icon_state = "[base_state]-burned"
			desc = "A burnt-out [name]."
		if(LIGHT_BROKEN)
			icon_state = "[base_state]-broken"
			desc = "A broken [name]."


/obj/item/light/New()
	..()
	switch(name)
		if("light tube")
			brightness_range = rand(6,9)
		if("light bulb")
			brightness_range = rand(4,6)
	update()


// attack bulb/tube with object
// if a syringe, can inject plasma to make it explode
/obj/item/light/attackby(obj/item/I, mob/user)
	..()
	if(istype(I, /obj/item/reagent_containers/syringe))
		var/obj/item/reagent_containers/syringe/S = I

		to_chat(user, "You inject the solution into [src].")

		if(S.reagents.has_reagent("plasma", 5))

			log_admin("LOG: [user.name] ([user.ckey]) injected a light with plasma, rigging it to explode.")
			message_admins("LOG: [user.name] ([user.ckey]) injected a light with plasma, rigging it to explode.")

			rigged = 1

		S.reagents.clear_reagents()
	else
		..()
	return

// called after an attack with a light item
// shatter light, unless it was an attempt to put it in a light socket
// now only shatter if the intent was harm

/obj/item/light/afterattack(atom/target, mob/user, proximity)
	if(!proximity) return
	if(istype(target, /obj/machinery/light))
		return
	if(user.a_intent != I_HURT)
		return

	shatter()

/obj/item/light/proc/shatter()
	if(status == LIGHT_OK || status == LIGHT_BURNED)
		src.visible_message(span_red("[name] shatters."), span_red("You hear a small glass object shatter."))
		status = LIGHT_BROKEN
		force = WEAPON_FORCE_WEAK
		sharp = TRUE
		playsound(src.loc, 'sound/effects/Glasshit.ogg', 75, 1)
		update()


/atom/proc/auto_turn_destructive()
	//Automatically turns based on nearby walls, destroys if not found.
	var/turf/wall/T = null
	var/gotdir = 0
	for(var/i = 1, i <= 8; i += i)
		T = get_ranged_target_turf(src, i, 1)

		if(istype(T))
			//If someone knows a better way to do this, let me know. -Giacom
			switch(i)
				if(NORTH)
					src.set_dir(SOUTH)
				if(SOUTH)
					src.set_dir(NORTH)
				if(WEST)
					src.set_dir(EAST)
				if(EAST)
					src.set_dir(WEST)
			gotdir = dir
			break
	if(!gotdir)
		qdel(src)
