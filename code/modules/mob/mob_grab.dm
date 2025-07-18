#define UPGRADE_WARMUP	50
#define UPGRADE_KILL_TIMER	100

///Process_Grab()
///Called by client/Move()
///Checks to see if you are grabbing anything and if moving will affect your grab.
/client/proc/Process_Grab()
	for(var/obj/item/grab/G in list(mob.l_hand, mob.r_hand))
		G.reset_kill_state() //no wandering across the station/asteroid while choking someone

/obj/item/grab
	name = "grab"
	icon = 'icons/mob/grab_icons.dmi'
	icon_state = "reinforce"
	flags = NOBLUDGEON
	layer = 21
	abstract = 1
	item_state = "nothing"
	w_class = ITEM_SIZE_COLOSSAL
	spawn_tags = null
	var/obj/screen/grab/hud
	var/mob/living/affecting
	var/mob/living/carbon/human/assailant
	var/state = GRAB_PASSIVE

	var/allow_upgrade = 1
	var/last_action = 0
	var/last_hit_zone = 0
	var/force_down //determines if the affecting mob will be pinned to the ground
	var/dancing //determines if assailant and affecting keep looking at each other.

	var/counter_timer = 3 SECONDS //sets to 3 seconds after being grabbed

/obj/item/grab/Process()
	counter_timer--
	..()

/obj/proc/affect_grab(mob/user, mob/target, state)
	return FALSE

/obj/item/grab/resolve_attackby(obj/O, mob/user, click_params)
	if(ismob(O))
		return ..()
	if(get_dist(O, affecting) > 1)
		return TRUE
	if(istype(O, /obj) || istype(O, /turf/wall/low))
		if(O.affect_grab(assailant, affecting, state))
			qdel(src)
	return TRUE

/obj/item/grab/New(mob/user, mob/victim)
	..()
	loc = user
	assailant = user
	affecting = victim

	if(!confirm())
		return

	affecting.grabbed_by += src

	hud = new /obj/screen/grab(src)
	hud.icon_state = "reinforce"
	icon_state = "grabbed"
	hud.name = "reinforce grab"
	hud.master = src

	//check if assailant is grabbed by victim as well
	if(assailant.grabbed_by)
		for (var/obj/item/grab/G in assailant.grabbed_by)
			if(G.assailant == affecting && G.affecting == assailant)
				G.dancing = 1
				G.adjust_position()
				dancing = 1
	update_slowdown()
	adjust_position()

//Used by throw code to hand over the mob, instead of throwing the grab.
// The grab is then deleted by the throw code.
/obj/item/grab/proc/throw_held()
	if(confirm())
		if(affecting.buckled)
			return null
		if(state >= GRAB_AGGRESSIVE)
			animate(affecting, pixel_x = 0, pixel_y = 0, 4, 1)
			return affecting
	return null


//This makes sure that the grab screen object is displayed in the correct hand.
/obj/item/grab/proc/synch()
	if(affecting)
		hud.screen_loc = src.screen_loc
//		if(assailant.r_hand == src)
//			hud.screen_loc = src.screen_loc
//		else
//			hud.screen_loc = src.screen_loc

/obj/item/grab/Process()
	if(gc_destroyed) // GC is trying to delete us, we'll kill our processing so we can cleanly GC
		return PROCESS_KILL

	if(!confirm())
		return PROCESS_KILL

	if(assailant.client)
		assailant.client.screen -= hud
		assailant.client.screen += hud

	if(assailant.pulling == affecting)
		assailant.stop_pulling()

	if(state <= GRAB_AGGRESSIVE)
		allow_upgrade = 1
		//disallow upgrading if we're grabbing more than one person
		if((assailant.l_hand && assailant.l_hand != src && istype(assailant.l_hand, /obj/item/grab)))
			var/obj/item/grab/G = assailant.l_hand
			if(G.affecting != affecting)
				allow_upgrade = 0
		if((assailant.r_hand && assailant.r_hand != src && istype(assailant.r_hand, /obj/item/grab)))
			var/obj/item/grab/G = assailant.r_hand
			if(G.affecting != affecting)
				allow_upgrade = 0

		//disallow upgrading past aggressive if we're being grabbed aggressively
		for(var/obj/item/grab/G in affecting.grabbed_by)
			if(G == src) continue
			if(G.state >= GRAB_AGGRESSIVE)
				allow_upgrade = 0

		if(allow_upgrade)
			if(state < GRAB_AGGRESSIVE)
				if(state == GRAB_PASSIVE)
					hud.icon_state = "reinforce"
			else
				hud.icon_state = "reinforce_final"
		else
			hud.icon_state = "!reinforce"

	if(state >= GRAB_AGGRESSIVE)
		affecting.drop_l_hand()
		affecting.drop_r_hand()

		if(iscarbon(affecting))
			handle_eye_mouth_covering(affecting, assailant, assailant.targeted_organ)

		if(force_down)
			if(affecting.loc != assailant.loc)
				force_down = 0
			else
				affecting.Weaken(2)

	if(state >= GRAB_NECK)
		affecting.Stun(3)
		if(isliving(affecting))
			var/mob/living/L = affecting
			L.adjustOxyLoss(1)

	if(state >= GRAB_KILL)
		if(iscarbon(affecting))
			var/mob/living/carbon/C = affecting
			C.apply_effect(STUTTER, 5) //It will hamper your voice, being choked and all.
			C.Weaken(5)	//Should keep you down unless you get help.
			C.losebreath = max(C.losebreath + 2, 3)

	update_slowdown()
	adjust_position()

/obj/item/grab/proc/handle_eye_mouth_covering(mob/living/carbon/target, mob/user, target_zone)
	//only display messages when switching between different target zones
	var/announce = (target_zone != last_hit_zone)
	last_hit_zone = target_zone

	switch(target_zone)
		if(BP_MOUTH)
			if(announce)
				user.visible_message(span_warning("\The [user] covers [target]'s mouth!"))
			if(target.silent < 3)
				target.silent = 3
		if(BP_EYES)
			if(announce)
				assailant.visible_message(span_warning("[assailant] covers [affecting]'s eyes!"))
			if(affecting.eye_blind < 3)
				affecting.eye_blind = 3

/obj/item/grab/attack_self()
	return s_click(hud)


//Updating pixelshift, position and direction
//Gets called on process, when the grab gets upgraded or the assailant moves
/obj/item/grab/proc/adjust_position()
	if(!affecting)
		return
	if(affecting.buckled)
		var/obj/O = affecting.buckled
		if (istype(O))
			O.post_buckle_mob(affecting) //A hack to fix offsets on altars and tables
		return
	if(affecting.lying && state != GRAB_KILL)
		animate(affecting, pixel_x = 0, pixel_y = 0, 5, 1, LINEAR_EASING)
		if(force_down)
			affecting.set_dir(SOUTH) //face up
		return
	var/shift = 0
	var/adir = get_dir(assailant, affecting)
	affecting.layer = 4
	switch(state)
		if(GRAB_PASSIVE)
			shift = 8
			if(dancing) //look at partner
				shift = 10
				assailant.set_dir(get_dir(assailant, affecting))
		if(GRAB_AGGRESSIVE)
			shift = 12
		if(GRAB_NECK, GRAB_UPGRADING)
			shift = -10
			adir = assailant.dir
			affecting.set_dir(assailant.dir)
			affecting.loc = assailant.loc
		if(GRAB_KILL)
			shift = 0
			adir = 1
			affecting.set_dir(SOUTH) //face up
			affecting.loc = assailant.loc

	switch(adir)
		if(NORTH)
			animate(affecting, pixel_x = 0, pixel_y =-shift, 5, 1, LINEAR_EASING)
			affecting.layer = 3.9
		if(SOUTH)
			animate(affecting, pixel_x = 0, pixel_y = shift, 5, 1, LINEAR_EASING)
		if(WEST)
			animate(affecting, pixel_x = shift, pixel_y = 0, 5, 1, LINEAR_EASING)
		if(EAST)
			animate(affecting, pixel_x =-shift, pixel_y = 0, 5, 1, LINEAR_EASING)

/obj/item/grab/proc/upgrade_grab(delay_time, hud_icon_state_after, state_after)
	if(!allow_upgrade)
		return // upgrading now is not allowed!
	delay_time = round(delay_time / 8) // the sprites have eight configurations for timer
	var/original_icon = hud.icon_state
	var/original_loc = get_turf(assailant) // used to see if the assailant moved and thus disrupted the upgrade
	var/original_time = world.time
	for(var/counter in 1 to 8)
		sleep(delay_time)
		if(QDELING(src) || !hud)
			break // hud is null after dropped and sleep does not care so we check manually
		if(last_action > original_time || !confirm() || get_turf(assailant) != original_loc) // cannot do a grab attack while upgrading a grab
			hud.icon_state = original_icon //  or move and upgrade a grab or keep upgrading it when the grab is escaped.
			break
		else
			hud.icon_state = "[original_icon][counter]"
			if(counter == 8)
				hud.icon_state = hud_icon_state_after
				state = state_after
				return TRUE
	to_chat(assailant, span_warning("You failed to upgrade your grab."))

/obj/item/grab/proc/s_click(obj/screen/S)
	if(!confirm())
		return
	if(state == GRAB_UPGRADING || state == GRAB_PRENECK)
		return
	if(!assailant.can_click())
		return
	if(!assailant.canmove || assailant.lying)
		qdel(src)
		return

	// Adjust the grab warmup using assailant's ROB stat
	var/assailant_stat = assailant?.stats.getStat(STAT_ROB)
	var/affecting_stat = affecting?.stats.getStat(STAT_ROB)
	var/warmup_increase
	if(assailant_stat > 0)
		// Positive ROB decreases warmup, but not linearly
		warmup_increase = -(assailant_stat ** 0.8)
	else
		// Negative ROB is a flat warmup increase
		warmup_increase = abs(assailant_stat)
	if(affecting_stat > 0)
		warmup_increase += affecting_stat ** 0.8
	else
		warmup_increase -= abs(affecting_stat) ** 0.6

	var/total_warmup = max(0, UPGRADE_WARMUP + round(warmup_increase))

	if(state < GRAB_AGGRESSIVE)
		if(!allow_upgrade)
			return
		icon_state = "grabbed1"
		hud.icon_state = "reinforce_final"
		state = GRAB_AGGRESSIVE
		if(!affecting.lying)
			assailant.visible_message(span_warning("[assailant] has grabbed [affecting] aggressively!"))
			affecting.attack_log += "\[[time_stamp()]\] <font color='orange'>Has been grabbed by [assailant.name] ([assailant.ckey])</font>"
			assailant.attack_log += "\[[time_stamp()]\] <font color='red'>Grabbed [affecting.name] ([affecting.ckey])</font>"
			msg_admin_attack("[assailant] grabbed a [affecting].")
		else
			assailant.visible_message(span_warning("[assailant] pins [affecting] down to the ground!"))
			affecting.attack_log += "\[[time_stamp()]\] <font color='orange'>Has been pinned by [assailant.name] ([assailant.ckey])</font>"
			assailant.attack_log += "\[[time_stamp()]\] <font color='red'>Pinned [affecting.name] ([affecting.ckey])</font>"
			msg_admin_attack("[assailant] pinned down [affecting].")
			apply_pinning(affecting, assailant)


	else if(state < GRAB_NECK)
		if(isslime(affecting))
			to_chat(assailant, span_notice("You squeeze [affecting], but nothing interesting happens."))
			return
		assailant.visible_message(span_warning("[assailant] starts grabbing [affecting] by the neck!"))
		state = GRAB_PRENECK
		hud.icon_state = "reinforce"
		if(upgrade_grab(total_warmup, "kill", GRAB_NECK))
			assailant.visible_message(span_warning("[assailant] grabs [affecting] by the neck!"))
			icon_state = "grabbed+1"
			assailant.set_dir(get_dir(assailant, affecting))
			affecting.attack_log += "\[[time_stamp()]\] <font color='orange'>Has had their neck grabbed by [assailant.name] ([assailant.ckey])</font>"
			assailant.attack_log += "\[[time_stamp()]\] <font color='red'>Grabbed the neck of [affecting.name] ([affecting.ckey])</font>"
			msg_admin_attack("[key_name(assailant)] grabbed the neck of [key_name(affecting)]")
			hud.icon_state = "kill"
			hud.name = "choke"
		else if(!QDELETED(src))
			state = GRAB_AGGRESSIVE
			if(hud)
				hud.icon_state = "reinforce_final"

	else if(state < GRAB_UPGRADING)
		assailant.visible_message(span_danger("[assailant] starts to tighten \his grip on [affecting]'s neck!"))
		hud.icon_state = "kill"
		hud.name = "Kill"
		state = GRAB_UPGRADING
		if(upgrade_grab(total_warmup, "kill_final", GRAB_KILL))
			assailant.visible_message(span_danger("[assailant] has tightened \his grip on [affecting]'s neck!"))
			affecting.attack_log += "\[[time_stamp()]\] <font color='orange'>Has been strangled (kill intent) by [assailant.name] ([assailant.ckey])</font>"
			assailant.attack_log += "\[[time_stamp()]\] <font color='red'>Strangled (kill intent) [affecting.name] ([affecting.ckey])</font>"
			msg_admin_attack("[key_name(assailant)] strangled (kill intent) [key_name(affecting)]")

			affecting.set_dir(WEST)
			if(iscarbon(affecting))
				var/mob/living/carbon/C = affecting
				C.losebreath += 1
		else
			state = GRAB_NECK
	update_slowdown()
	adjust_position()

//This is used to make sure the victim hasn't managed to yackety sax away before using the grab.
/obj/item/grab/proc/confirm()
	if(!assailant || !affecting)
		qdel(src)
		return 0

	else
		if(!isturf(assailant.loc) || !isturf(affecting.loc) || get_dist(assailant, affecting) > 1)
			qdel(src)
			return 0

	return 1

// Function to compute the current slowdown and is more adjustable and uses number as starting value
// The code will adjust or lower the slowdown depending on STAT_ROB skill, gravity, etc.
/obj/item/grab/proc/update_slowdown()
	// The movment speed of assailant will be determined by the victim whatever their size or things he wears minus how strong the assailant ( ROB )
	// New function should take the victim variables in account : size of mob, under gravity or not
	// ROB check will start in process for the victim so the assailant can have a jump on the victim in first movement tick or some shit unless he's already grabbed
	if(isnull(affecting))
		return //do not upgrade a grab and drop it

	var/affecting_stat = affecting.stats.getStat(STAT_ROB)	// Victim
	var/assailant_stat = assailant.stats.getStat(STAT_ROB)	// Grabber
	var/difference_stat = assailant_stat - affecting_stat

	// Early exit to save processing time
	if(!(affecting.check_gravity() && assailant.check_gravity()))
		slowdown = 0
		return	// Nothing to do here

	// initial value for slowdown
	slowdown = 2

	if(affecting.lying)	//putting in lying for the victim will cause the assailant to expend more effort
		slowdown += 1

	if(affecting.is_dead() || affecting.incapacitated() )	// victim can't resist if he is dead or stunned.
		slowdown *= 0.1
	else
		slowdown += max(0, -0.05 * difference_stat)			// Avoids negative values from making the grabber going supersanic

	// Size check here
	if(assailant.mob_size > affecting.mob_size)
		slowdown *= 0.5
	else if (assailant.mob_size < affecting.mob_size)
		slowdown *= 1.5

/obj/item/grab/attack(mob/M, mob/living/user)
	if(!affecting)
		return
	if(world.time < (last_action + 20))
		return

	last_action = world.time
	reset_kill_state() //using special grab moves will interrupt choking them

	//clicking on the victim while grabbing them
	if(M == affecting)
		if(ishuman(affecting))
			var/obj/item/organ/external/hit_zone = assailant.targeted_organ
			flick(hud.icon_state, hud)
			switch(assailant.a_intent)
				if(I_HELP)
					if(force_down)
						to_chat(assailant, span_warning("You are no longer pinning [affecting] to the ground."))
						affecting.attack_log += "\[[time_stamp()]\] <font color='orange'>No longer pinned down by [assailant.name] ([assailant.ckey])</font>"
						assailant.attack_log += "\[[time_stamp()]\] <font color='red'>Released from pin [affecting.name] ([affecting.ckey])</font>"
						msg_admin_attack("[key_name(assailant)] Released from pin [key_name(affecting)]")
						force_down = 0
						return
					else if(hit_zone == BP_MOUTH)
						force_vomit(affecting, assailant)
					else
						var/mob/living/carbon/human/H = affecting
						var/obj/item/organ/external/o = H.get_organ(hit_zone)

						if(o.status & ORGAN_BLEEDING)
							slow_bleeding(affecting, assailant, o)
						else
							inspect_organ(affecting, assailant, hit_zone)

				if(I_GRAB)
					if(hit_zone == BP_CHEST || hit_zone == BP_GROIN)
						swing(affecting, assailant)
					else
						jointlock(affecting, assailant, hit_zone)

				if(I_HURT)
					if(hit_zone == BP_EYES)
						attack_eye(affecting, assailant)
					else if(hit_zone == BP_HEAD)
						headbutt(affecting, assailant)
					else if(hit_zone == BP_CHEST)
						if(state < GRAB_NECK)
							dropkick(affecting, assailant)
						else suplex(affecting, assailant)
					else if(hit_zone == BP_GROIN)
						gut_punch(affecting, assailant)
					else
						nerve_strike(affecting, assailant, hit_zone)

				if(I_DISARM)
					pin_down(affecting, assailant)

	//clicking on yourself while grabbing them
	if(M == assailant)
		fireman_throw(affecting, assailant)

/obj/item/grab/dropped()
	loc = null
	if(!destroying)
		qdel(src)

/obj/item/grab/proc/reset_kill_state()
	if(state == GRAB_KILL)
		assailant.visible_message(span_warning("[assailant] lost \his tight grip on [affecting]'s neck!"))
		affecting.attack_log += "\[[time_stamp()]\] <font color='orange'>No longer gripped by [assailant.name] ([assailant.ckey] neck.)</font>"
		assailant.attack_log += "\[[time_stamp()]\] <font color='red'>Lost his grip on [affecting.name] ([affecting.ckey] neck.)</font>"
		msg_admin_attack("[key_name(assailant)] lost his tight grip on [key_name(affecting)] neck.")
		hud.icon_state = "kill"
		state = GRAB_NECK

/obj/item/grab
	var/destroying = 0

/obj/item/grab/Destroy()
	if(affecting)
		if(affecting.buckled)
			var/obj/O = affecting.buckled
			if (istype(O))
				O.post_buckle_mob(affecting) //A hack to fix offsets on altars and tables
		else
			animate(affecting, pixel_x = 0, pixel_y = 0, 4, 1, LINEAR_EASING)
		if (issuperioranimal(affecting))
			var/mob/living/carbon/superior_animal/wrangled = affecting
			if (wrangled.grabbed_by_friend && assailant && (assailant in wrangled.friends))
				wrangled.grabbed_by_friend = FALSE
		affecting.reset_plane_and_layer()
		affecting.grabbed_by -= src
		affecting = null
	if(assailant)
		if(assailant.client)
			assailant.client.screen -= hud
		assailant = null
	qdel(hud)
	hud = null
	destroying = 1 // stops us calling qdel(src) on dropped()
	return ..()


//A stub for bay grab system. This is supposed to check a var on the associated grab datum
/obj/item/grab/proc/force_stand()
	return FALSE
