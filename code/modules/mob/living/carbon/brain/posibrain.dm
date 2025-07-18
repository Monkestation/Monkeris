/obj/item/device/mmi/digital/posibrain
	name = "positronic brain"
	desc = "A cube of shining metal, four inches to a side and covered in shallow grooves."
	icon = 'icons/obj/assemblies.dmi'
	icon_state = "posibrain"
	w_class = ITEM_SIZE_NORMAL
	origin_tech = list(TECH_ENGINEERING = 4, TECH_MATERIAL = 4, TECH_BLUESPACE = 2, TECH_DATA = 4)
	matter = list(MATERIAL_STEEL = 5, MATERIAL_GLASS = 5, MATERIAL_SILVER = 5, MATERIAL_GOLD = 5)
	var/searching = 0
	var/askDelay = 10 * 60 * 1
	req_access = list(access_robotics)
	locked = 0


/obj/item/device/mmi/digital/posibrain/attack_self(mob/user as mob)
	if(brainmob && !brainmob.key && searching == 0)
		//Start the process of searching for a new user.
		to_chat(user, span_notice("You carefully locate the manual activation switch and start the positronic brain's boot process."))
		icon_state = "posibrain-searching"
		src.searching = 1
		var/datum/ghosttrap/G = get_ghost_trap("positronic brain")
		G.request_player(brainmob, "Someone is requesting a personality for a positronic brain.", MINISYNTH, 60 SECONDS)
		spawn(600) reset_search()

/obj/item/device/mmi/digital/posibrain/proc/reset_search() //We give the players sixty seconds to decide, then reset the timer.
	if(src.brainmob && src.brainmob.key) return

	src.searching = 0
	icon_state = "posibrain"

	var/turf/T = get_turf_or_move(src.loc)
	for (var/mob/M in viewers(T))
		M.show_message(span_notice("The positronic brain buzzes quietly, and the golden lights fade away. Perhaps you could try again?"))

/obj/item/device/mmi/digital/posibrain/attack_ghost(mob/observer/ghost/user)
	if(src.brainmob && src.brainmob.key)
		return
	if(!searching)
		to_chat(user, span_warning("The positronic brain has to be activated before you can enter it."))
		return
	var/datum/ghosttrap/G = get_ghost_trap("positronic brain")
	if(!G.assess_candidate(user, check_respawn_timer = FALSE))
		return
	var/response = alert(user, "Are you sure you wish to possess this [src]?", "Possess [src]", "Yes", "No")
	if(response == "Yes")
		G.transfer_personality(user, brainmob, check_respawn_timer=FALSE)
	return

/obj/item/device/mmi/digital/posibrain/examine(mob/user, extra_description = "")
	if(get_dist(user, src) < 2)
		var/msg = "[span_info("*---------*")]\nThis is [icon2html(src, user)] \a <EM>[src]</EM>!\n[desc]\n"
		msg += "<span class='warning'>"

		if(brainmob && brainmob.key)
			switch(brainmob.stat)
				if(CONSCIOUS)
					if(!brainmob.client)
						msg += "It appears to be in stand-by mode.\n" //afk
				if(UNCONSCIOUS)
					msg += "It doesn't seem to be responsive.\n"
				if(DEAD)
					msg += "[span_deadsay("It appears to be completely inactive.")]\n"
		else
			msg += "[span_deadsay("It appears to be completely inactive.")]\n"
		msg += "</span>[span_info("*---------*")]"
		extra_description += msg
	..(user, extra_description)

/obj/item/device/mmi/digital/posibrain/emp_act(severity)
	if(!src.brainmob)
		return
	else
		switch(severity)
			if(1)
				src.brainmob.emp_damage += rand(20,30)
			if(2)
				src.brainmob.emp_damage += rand(10,20)
			if(3)
				src.brainmob.emp_damage += rand(0,10)
	..()

/obj/item/device/mmi/digital/posibrain/New()
	..()
	src.brainmob.name = "[pick(list("PBU","HIU","SINA","ARMA","OSI"))]-[rand(100, 999)]"
	src.brainmob.real_name = src.brainmob.name
