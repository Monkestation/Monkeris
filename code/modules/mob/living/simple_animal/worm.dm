/mob/living/simple_animal/space_worm
	name = "space worm segment"
	desc = "A part of a space worm."
	icon = 'icons/mob/animal.dmi'
	icon_state = "spaceworm"
	status_flags = 0

	speak_emote = list("transmits") //not supposed to be used under AI control
	emote_see = list("transmits")  //I'm just adding it so it doesn't runtime if controlled by player who speaks

	response_help  = "touches"
	response_disarm = "flails at"
	response_harm   = "punches the"

	harm_intent_damage = 2

	maxHealth = 30
	health = 30

	universal_speak =1

	stop_automated_movement = 1
	animate_movement = SYNC_STEPS

	minbodytemp = 0
	maxbodytemp = 350
	min_oxy = 0
	max_co2 = 0
	max_tox = 0

	a_intent = I_HURT //so they don't get pushed around

	environment_smash = 2

	speed = -1

	var/mob/living/simple_animal/space_worm/previous //next/previous segments, correspondingly
	var/mob/living/simple_animal/space_worm/next     //head is the nextest segment

	var/stomachProcessProbability = 50
	var/digestionProbability = 20
	var/flatPlasmaValue = 5 //flat plasma amount given for non-items

	var/atom/currentlyEating //what the worm is currently eating
	var/eatingDuration = 0 //how long he's been eating it for

/mob/living/simple_animal/space_worm/head
	name = "space worm head"
	icon_state = "spacewormhead"
	icon_dead = "spaceworm_dead"

	maxHealth = 20
	health = 20

	melee_damage_lower = 10
	melee_damage_upper = 15
	attacktext = "bitten"

	animate_movement = SLIDE_STEPS

/mob/living/simple_animal/space_worm/head/New(location, segments = 6)
	. = ..()

	var/mob/living/simple_animal/space_worm/current = src

	for(var/i = 1 to segments)
		var/mob/living/simple_animal/space_worm/newSegment = new /mob/living/simple_animal/space_worm(loc)
		current.Attach(newSegment)
		current = newSegment

/mob/living/simple_animal/space_worm/head/update_icon()
	if(stat == CONSCIOUS || stat == UNCONSCIOUS)
		icon_state = "spacewormhead[previous?1:0]"
		if(previous)
			set_dir(get_dir(previous,src))
	else
		icon_state = "spacewormheaddead"

/mob/living/simple_animal/space_worm/Life()
	..()

	if(next && !(next in view(src,1)))
		Detach()

	if(stat == DEAD) //dead chunks fall off and die immediately
		if(previous)
			previous.Detach()
		if(next)
			Detach(1)

	if(prob(stomachProcessProbability))
		ProcessStomach()

	update_icon()

	return

/mob/living/simple_animal/space_worm/Destroy() //if a chunk a destroyed, make a new worm out of the split halves
	if(previous)
		previous.Detach()
	. = ..()

/mob/living/simple_animal/space_worm/Move(NewLoc, Dir = 0, step_x = 0, step_y = 0, glide_size_override = 0)
	var/attachementNextPosition = loc
	if(..())
		if(previous)
			previous.Move(attachementNextPosition, glide_size_override=glide_size_override)
		update_icon()

/mob/living/simple_animal/space_worm/Bump(atom/obstacle)
	if(currentlyEating != obstacle)
		currentlyEating = obstacle
		eatingDuration = 0

	if(!AttemptToEat(obstacle))
		eatingDuration++
	else
		currentlyEating = null
		eatingDuration = 0

	return

/mob/living/simple_animal/space_worm/update_icon() //only for the sake of consistency with the other update icon procs
	if(stat == CONSCIOUS || stat == UNCONSCIOUS)
		if(previous) //midsection
			icon_state = "spaceworm[get_dir(src,previous) | get_dir(src,next)]" //see 3 lines below
		else //tail
			icon_state = "spacewormtail"
			set_dir(get_dir(src,next)) //next will always be present since it's not a head and if it's dead, it goes in the other if branch
	else
		icon_state = "spacewormdead"

	return

/mob/living/simple_animal/space_worm/proc/AttemptToEat(atom/target)
	if(istype(target,/turf/wall))
		var/turf/wall/W = target
		if(((W.hardness < 100) && eatingDuration >= 100) || eatingDuration >= 200) //need 20 ticks to eat an rwall, 10 for a regular one
			W.dismantle_wall(src)
			return 1
	else if(istype(target,/atom/movable))
		if(ismob(target) || eatingDuration >= 50) //5 ticks to eat stuff like airlocks
			var/atom/movable/objectOrMob = target
			contents += objectOrMob
			return 1

	return 0

/mob/living/simple_animal/space_worm/proc/Attach(mob/living/simple_animal/space_worm/attachement)
	if(!attachement)
		return

	previous = attachement
	attachement.next = src

	return

/mob/living/simple_animal/space_worm/proc/Detach(die = 0)
	var/mob/living/simple_animal/space_worm/newHead = new /mob/living/simple_animal/space_worm/head(loc,0)
	var/mob/living/simple_animal/space_worm/newHeadPrevious = previous

	previous = null //so that no extra heads are spawned

	newHead.Attach(newHeadPrevious)

	if(die)
		newHead.death()

	qdel(src)

/mob/living/simple_animal/space_worm/proc/ProcessStomach()
	for(var/atom/movable/stomachContent in contents)
		if(prob(digestionProbability))
			if(istype(stomachContent,/obj/item/stack)) //converts to plasma, keeping the stack value
				if(!istype(stomachContent,/obj/item/stack/material/plasma))
					var/obj/item/stack/oldStack = stomachContent
					new /obj/item/stack/material/plasma(src, oldStack.get_amount())
					qdel(oldStack)
					continue
			else if(istype(stomachContent,/obj/item)) //converts to plasma, keeping the w_class
				var/obj/item/oldItem = stomachContent
				new /obj/item/stack/material/plasma(src, oldItem.w_class)
				qdel(oldItem)
				continue
			else
				new /obj/item/stack/material/plasma(src, flatPlasmaValue) //just flat amount
				qdel(stomachContent)
				continue

	if(previous)
		for(var/atom/movable/stomachContent in contents) //transfer it along the digestive tract
			previous.contents += stomachContent
	else
		for(var/atom/movable/stomachContent in contents) //or poop it out
			loc.contents += stomachContent

	return
