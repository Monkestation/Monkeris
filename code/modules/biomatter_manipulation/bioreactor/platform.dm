//Bioreactor platform
//This part is most urgent in whole machine
//It's going through all items at its location and process them into biomass slowly (or almost slowly)
//So, this is doesn't matter how these things inside, you can even drop them from above!


/obj/machinery/multistructure/bioreactor_part/platform
	name = "bioreactor platform"
	icon_state = "platform_5"
	density = FALSE
	layer = LOW_OBJ_LAYER
	idle_power_usage = 200
	active_power_usage = 400
	var/make_glasswalls_after_creation = FALSE

/obj/machinery/multistructure/bioreactor_part/platform/Initialize()
	. = ..()
	update_icon()


/obj/machinery/multistructure/bioreactor_part/platform/Process()
	if(!MS)
		use_power(idle_power_usage)
		return
	if((!is_breached() || MS_bioreactor.is_operational()) && MS_bioreactor.chamber_solution)
		use_power(active_power_usage)
		for(var/atom/movable/M in loc)

			//mob processing
			if(isliving(M))
				var/mob/living/victim = M
				//synthetic things not allowed
				if((issilicon(victim) || victim.mob_classification == CLASSIFICATION_SYNTHETIC) && victim.mob_size <= MOB_SMALL)
					victim.forceMove(MS_bioreactor.misc_output)
					continue
				//if our target has hazard protection, apply damage based on the protection percentage.
				var/hazard_protection = victim.getarmor(null, ARMOR_BIO)
				var/damage = BIOREACTOR_DAMAGE_PER_TICK - (BIOREACTOR_DAMAGE_PER_TICK * (hazard_protection/100))
				victim.apply_damage(damage, BURN, used_weapon = "Biological") // Before ErisMed 4 damage type was CLONE until some CLOWN changed it to simply BRUTE for no reason. TODO: change to better damage type when possible
				victim.adjustOxyLoss(BIOREACTOR_DAMAGE_PER_TICK / 2)	// Snowflake shit, but we need the mob to die within a reasonable time frame

				if(prob(10))
					playsound(loc, 'sound/effects/bubbles.ogg', 45, 1)
				if(victim.health <= -victim.maxHealth)
					MS_bioreactor.biotank_platform.take_amount(victim.mob_size*5)
					MS_bioreactor.biotank_platform.pipes_wearout(victim.mob_size/5, forced = TRUE)
					consume(victim)
				continue

			//object processing
			if(istype(M, /obj/item))
				if(M.anchored)
					continue
				var/obj/item/target = M
				//if we found biomatter, let's start processing
				//it will slowly disappear. Time based at size of object and we manipulate with its alpha (we also check for it)
				if((MATERIAL_BIOMATTER in target.matter) && !target.unacidable)
					target.alpha -= round(100 / target.w_class)
					var/icon/I = new(target.icon, icon_state = target.icon_state)
					//we turn this things to degenerate sprite a bit
					I.Turn(rand(-10, 10))
					target.icon = I
					if(target.alpha <= 50)
						MS_bioreactor.biotank_platform.take_amount(target.matter[MATERIAL_BIOMATTER])
						MS_bioreactor.biotank_platform.pipes_wearout(target.w_class)
						target.matter -= MATERIAL_BIOMATTER
						//if we have other matter, let's spit it out
						for(var/material in target.matter)
							var/stack_type = material_stack_type(material_display_name(material))
							if(stack_type)
								var/obj/item/stack/material/waste = new stack_type(MS_bioreactor.misc_output)
								waste.amount = target.matter[material]
								waste.update_strings()
							target.matter -= material
						consume(target)
				else
					target.forceMove(MS_bioreactor.misc_output)
	else
		//if our machine is non operational, let's go idle powermode and pump out solution
		use_power(idle_power_usage)
		if(MS_bioreactor.chamber_solution)
			MS_bioreactor.pump_solution(forced = 1)


/obj/machinery/multistructure/bioreactor_part/platform/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/stack/material/glass/reinforced))
		var/obj/item/stack/material/glass = I
		var/list/glassless_dirs = get_opened_dirs()
		if(glass.use(glassless_dirs.len))
			to_chat(user, span_notice("[user] you careful placing [I] into [src]'s holders, making glass wall."))
			if(do_after(user, 3*glassless_dirs.len SECONDS, src))
				make_windows()
		else
			to_chat(user, span_warning("Not enough amount of [I]."))
	..()


//This proc called on object/mob consumption
/obj/machinery/multistructure/bioreactor_part/platform/proc/consume(atom/movable/object)
	if(ishuman(object))
		var/mob/living/carbon/human/H = object
		for(var/obj/item/item in H.contents)
			//non robotic limbs will be consumed
			if(istype(item, /obj/item/organ))
				var/obj/item/organ/organ = item
				if(istype(organ, /obj/item/organ/external) && organ.nature == MODIFICATION_ORGANIC)
					continue
				var/obj/machinery/multistructure/bioreactor_part/platform/neighbor_platform = pick(MS_bioreactor.platforms)
				organ.forceMove(get_turf(neighbor_platform))
				organ.removed()
				continue
	if(istype(object, /obj/item/organ/internal/vital/brain))
		var/obj/item/organ/internal/vital/brain/B = object
		if(B.brainmob && B.brainmob.mind && B.brainmob.mind.key)
			var/mob/M = key2mob(B.brainmob.mind.key)
			to_chat(M, span_notice("Your remains have been dissolved and reused. Your crew respawn time is reduced by [(BIOREACTOR_RESPAWN_BONUS)/600] minutes."))
			M << 'sound/effects/magic/blind.ogg'  //Play this sound to a player whenever their respawn time gets reduced
			M.set_respawn_bonus("CORPSE_DISSOLVING", BIOREACTOR_RESPAWN_BONUS)

	qdel(object)
	//now let's add some dirt to the glass
	for(var/obj/structure/window/reinforced/bioreactor/glass in loc)
		if(glass.dir != MS_bioreactor.platform_enter_side && prob(10))
			glass.apply_dirt(1)
	if(prob(30))
		playsound(loc, 'sound/effects/bubbles.ogg', 50, 1)


/obj/machinery/multistructure/bioreactor_part/platform/update_icon()
	var/corner_dir = 0		//used at sprite determination, direction point to center of whole bioreactor chamber
	for(var/direction in GLOB.cardinal)
		if(locate(type) in get_step(src, direction))
			corner_dir += direction
	if(corner_dir in list(9, 6, 5, 10))
		icon_state = "platform_[corner_dir]"


//There we going for open directions (dirs without neighbor platform and glass) and return list with them. It can be empty if everything okay
/obj/machinery/multistructure/bioreactor_part/platform/proc/get_opened_dirs()
	var/list/open_dirs = list()
	for(var/direction in GLOB.cardinal)
		if(!locate(type) in get_step(src, direction))
			open_dirs += direction
		for(var/obj/structure/window/reinforced/bioreactor/exist_glass in loc)
			if(exist_glass.dir == direction)
				open_dirs -= exist_glass.dir
	return open_dirs


//Here we make our glass walls. First, we get open dirs (directions without platforms), then we check existed glass on.
//We remove window dirs from this list and, in the end, just creating our windows
/obj/machinery/multistructure/bioreactor_part/platform/proc/make_windows()
	var/list/open_dirs = get_opened_dirs()
	for(var/remaining_dir in open_dirs)
		var/obj/structure/window/reinforced/bioreactor/glass = new(loc)
		apply_window(glass, remaining_dir)


//There we apply sprites and directions to created glass
/obj/machinery/multistructure/bioreactor_part/platform/proc/apply_window(obj/structure/window/reinforced/glass, direction)
	if(MS_bioreactor.platform_enter_side == direction)
		glass.icon_state = "platform_door"
	else
		glass.icon_state = "[icon_state]-glass_[direction]"
	glass.dir = direction
	glass.update_icon()


//Here we go through our windows and check it for breach. If somewhere glass will be missing, we return TRUE and turn our bioreactor var
/obj/machinery/multistructure/bioreactor_part/platform/proc/is_breached()
	var/list/glass_dirs = get_opened_dirs()
	for(var/obj/structure/window/reinforced/bioreactor/glass in loc)
		if(glass.dir in glass_dirs)
			glass_dirs -= glass.dir
	if(glass_dirs.len)
		MS_bioreactor.chamber_breached = TRUE
		return TRUE
	return FALSE




//GLASS WALLS
/obj/structure/window/reinforced/bioreactor
	name = "bioreactor glass"
	icon = 'icons/obj/machines/bioreactor.dmi'
	layer = ABOVE_MOB_LAYER
	var/contamination_level = 0
	var/max_contamination_lvl = 5


/obj/structure/window/reinforced/bioreactor/examine(mob/user, extra_description = "")
	switch(contamination_level)
		if(1)
			extra_description += span_notice("There are a few stains on it. Except this, [src] looks pretty clean.")
		if(2)
			extra_description += span_notice("You see a sign of biomatter on this [src]. Better to clean it up.")
		if(3)
			extra_description += span_warning("This [src] has clear signs and stains of biomatter.")
		if(4)
			extra_description += span_warning("You see a high amount of biomatter on \the [src]. It's dirty as hell.")
		if(5)
			extra_description += span_warning("Now it's hard to see what's inside. Better to clean this [src].")
		else
			extra_description += span_notice("This [src] is so clean, that you can see your reflection. Is that something green at your teeth?")
	..(user, extra_description)

/obj/structure/window/reinforced/bioreactor/update_icon()
	overlays.Cut()
	..()
	if(contamination_level)
		var/biomass_alpha = min((50*contamination_level), 255)
		var/icon/default = new /icon(icon, icon_state)
		var/icon/biomass = new /icon('icons/obj/machines/bioreactor.dmi', "glass_biomass")
		biomass.Turn(-40, 40)
		biomass.Blend(rgb(0, 0, 0, biomass_alpha))
		default.Blend(biomass, ICON_MULTIPLY)
		overlays += default


/obj/structure/window/reinforced/bioreactor/proc/apply_dirt(amount)
	contamination_level += amount
	if(contamination_level >= max_contamination_lvl)
		contamination_level = max_contamination_lvl
		opacity = TRUE
	if(contamination_level <= 0)
		contamination_level = 0
		opacity = FALSE
	update_icon()


/obj/structure/window/reinforced/bioreactor/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/mop) || istype(I, /obj/item/soap))
		if(istype(I, /obj/item/mop))
			if(I.reagents && !I.reagents.total_volume)
				to_chat(user, span_warning("Your [I] is dry!"))
				return
		if(user.loc != loc)
			to_chat(user, span_warning("You need to be inside to clean it up."))
			return
		to_chat(user, span_notice("You begin cleaning [src] with [I]..."))
		if(do_after(user, CLEANING_TIME * contamination_level, src))
			to_chat(user, span_notice("You clean \the [src]."))
			toxin_attack(user, 5*contamination_level)
			apply_dirt(-contamination_level)
			if(contamination_level >= 4)
				spill_biomass(user.loc, GLOB.cardinal)
		else
			to_chat(user, span_warning("You need to stand still to clean it properly."))
	else
		..()


/obj/structure/window/reinforced/bioreactor/MouseDrop_T(mob/victim, mob/user as mob)
	if(!ismob(victim) || !ishuman(user) || victim.anchored)
		return
	var/base_chance = 70
	if(victim == user)
		to_chat(user, span_notice("You try to climb over \the [src]..."))
		if(do_after(user, 3 SECONDS, src))
			if(prob(base_chance - 10*contamination_level))
				to_chat(user, span_notice("You successfully climbed \the [src]!"))
				if(user.loc != loc)
					user.forceMove(get_step(src, loc))
				else
					user.forceMove(get_step(src, user.dir))
			else
				to_chat(user, span_warning("You slipped!"))
				user.Weaken(1)
	else
		to_chat(user, span_notice("You try to push \the [victim] over \the [src]"))
		to_chat(victim, span_warning("\The [user] is trying to push you over \the [src]!"))
		if(do_after(user, 3 SECONDS, src))
			victim.visible_message(span_warning("\The [user] pushes \the [victim] over \the [src]!"))
			victim.forceMove(get_step(src, user.dir))
