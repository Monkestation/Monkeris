/mob/living/carbon/human/proc/check_ability(chem_cost = 0, needs_foundation, gene_cost = 0)
	if(stat == DEAD || (status_flags & FAKEDEATH))
		to_chat(src, span_warning("You are dead"))
		return FALSE

	if(carrion_stored_chemicals < chem_cost)
		to_chat(src, span_warning("You don't have enough chemicals stored to do that."))
		return FALSE

	if(needs_foundation)
		var/turf/T = get_turf(src)
		var/has_foundation = FALSE
		if(T)
			if(!(istype(T,/turf/space)))
				has_foundation = TRUE

		if(!has_foundation)
			to_chat(src, span_warning("You need a solid foundation to do that on."))
			return FALSE

	if(gene_cost)
		var/obj/item/organ/internal/carrion/core/core = random_organ_by_process(BP_SPCORE)
		if(core?.geneticpoints < gene_cost)
			to_chat(src, span_warning("You don't have enough genetic points stored to do that."))
			return FALSE
		else
			core.geneticpoints -= gene_cost

	carrion_stored_chemicals -= chem_cost
	return TRUE

/obj/item/organ/internal/carrion
	max_damage = 15 //resilient
	scanner_hidden = TRUE //sneaky

/obj/item/organ/internal/carrion/chemvessel
	name = "chemical vessel"
	parent_organ_base = BP_CHEST
	organ_efficiency = list(OP_CHEMICALS = 100)
	icon_state = "carrion_chemvessel"

/obj/item/organ/internal/carrion/core
	name = "spider core"
	parent_organ_base = BP_CHEST
	organ_efficiency = list(BP_SPCORE = 100)
	icon_state = "spider_core"
	unique_tag = BP_SPCORE
	max_damage = 400 //this really shouldn't die
	vital = 1
	specific_organ_size = 0
	var/list/absorbed_dna = list()
	var/list/purchasedpowers = list()
	var/list/spiderlist = list()
	var/list/active_spiders = list()
	var/geneticpoints = 10
	var/autoassign_groups = FALSE

	var/mob/living/simple_animal/spider_core/associated_spider = null

	owner_verbs = list(
		/obj/item/organ/internal/carrion/core/proc/carrion_transform,
		/obj/item/organ/internal/carrion/core/proc/EvolutionMenu,
		/obj/item/organ/internal/carrion/core/proc/carrion_fakedeath,
		/obj/item/organ/internal/carrion/core/proc/detach,
		/obj/item/organ/internal/carrion/core/proc/make_spider,
		/obj/item/organ/internal/carrion/core/proc/spider_menu
	)

	var/list/associated_carrion_organs = list()

/obj/item/organ/internal/carrion/core/Destroy()
	owner = null //overrides removed() call
	. = ..()

/obj/item/organ/internal/carrion/core/take_damage(amount, damage_type = BRUTE, wounding_multiplier = 1, sharp = FALSE, edge = FALSE, silent = FALSE)
	return

/obj/item/organ/internal/carrion/core/proc/make_spider()
	set category = "Carrion"
	set name = "Spawn a spider"

	// Organ procs given to a mob will have that mob as both 'src' and 'usr'
	var/obj/item/organ/internal/carrion/core/core = locate() in src
	if(!core)
		return
	src = core // Now, this might be cursed, but if it works, it works ¯\_(ツ)_/¯
	// What else are we gonna do, rework all of the "organs have procs that are verbs and belong to a mob" business?

	var/list/options = list()
	var/obj/item/implant/carrion_spider/S
	if (!spiderlist.len)
		to_chat(owner, span_warning("You dont have any spiders evolved!"))
		return

	for(var/item in spiderlist)
		S = item
		options["[initial(S.name)]([initial(S.spider_price)])"] = S

	var/I = input(owner,"Select the spider you want to spawn: ", "Spider", null) as null|anything in options
	S = options[I]
	if(!S)
		return

	if(owner.check_ability(initial(S.spider_price), null, initial(S.gene_price)))
		var/obj/item/implant/carrion_spider/spider = new S(owner.loc)
		active_spiders += spider
		spider.owner_core = src
		spider.update_owner_mob()
		if(autoassign_groups)
			var/obj/item/implant/carrion_spider/A
			for(var/obj/item/implant/carrion_spider/F in active_spiders)
				if(istype(F, spider.type))
					A = F
					spider.assigned_groups = A.assigned_groups
					break

		owner.put_in_active_hand(spider)

/obj/item/organ/internal/carrion/core/nano_ui_interact(mob/user, ui_key, datum/nanoui/ui, force_open, datum/nanoui/master_ui, datum/nano_topic_state/state)
	var/list/data = list()

	var/list/spiders_in_list = list()
	for(var/item in active_spiders)
		var/obj/item/implant/carrion_spider/S = item
		var/turf/T = get_turf(S)
		var/area/area = get_area(S)
		var/location_name = area.name
		var/spider_location = "Unknown location"
		if(T)
			spider_location = "[location_name], [S.loc]([T.x]:[T.y]:[T.z])"
		spiders_in_list += list(
			list(
				"name" = initial(S.name),
				"location" = "[spider_location]",
				"spider" = "\ref[item]",
				"implanted" = S.wearer,
				"assigned_group_1" = S.check_group(SPIDER_GROUP_1),
				"assigned_group_2" = S.check_group(SPIDER_GROUP_2),
				"assigned_group_3" = S.check_group(SPIDER_GROUP_3),
				"assigned_group_4" = S.check_group(SPIDER_GROUP_4)
			)
		)

	data["list_of_spiders"] = spiders_in_list
	data["autoassigning"] = autoassign_groups

	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "carrion_spiders.tmpl", "Carrion Spiders", 600, 400)
		ui.set_initial_data(data)
		ui.open()
		ui.set_auto_update(1)

/obj/item/organ/internal/carrion/core/Topic(href, href_list)
	if(href_list["activate_spider"])
		var/obj/item/implant/carrion_spider/activated_spider = locate(href_list["activate_spider"]) in active_spiders
		if(activated_spider)
			activated_spider.activate()

	if(href_list["pop_out_spider"])
		var/obj/item/implant/carrion_spider/activated_spider = locate(href_list["pop_out_spider"]) in active_spiders
		if(activated_spider)
			activated_spider.uninstall()

	if(href_list["activate_all"])
		for(var/spider in active_spiders)
			var/obj/item/implant/carrion_spider/CS = spider
			if(istype(CS) && !CS.ignore_activate_all)
				CS.activate()

	if(href_list["activate_group_1"])
		for(var/spider in active_spiders)
			var/obj/item/implant/carrion_spider/CS = spider
			if(istype(CS) && CS.check_group(SPIDER_GROUP_1))
				CS.activate()

	if(href_list["activate_group_2"])
		for(var/spider in active_spiders)
			var/obj/item/implant/carrion_spider/CS = spider
			if(istype(CS) && CS.check_group(SPIDER_GROUP_2))
				CS.activate()

	if(href_list["activate_group_3"])
		for(var/spider in active_spiders)
			var/obj/item/implant/carrion_spider/CS = spider
			if(istype(CS) && CS.check_group(SPIDER_GROUP_3))
				CS.activate()

	if(href_list["activate_group_4"])
		for(var/spider in active_spiders)
			var/obj/item/implant/carrion_spider/CS = spider
			if(istype(CS) && CS.check_group(SPIDER_GROUP_4))
				CS.activate()

	if(href_list["toggle_group_1"])
		var/obj/item/implant/carrion_spider/activated_spider = locate(href_list["toggle_group_1"]) in active_spiders
		if(activated_spider)
			activated_spider.toggle_group(SPIDER_GROUP_1)

	if(href_list["toggle_group_2"])
		var/obj/item/implant/carrion_spider/activated_spider = locate(href_list["toggle_group_2"]) in active_spiders
		if(activated_spider)
			activated_spider.toggle_group(SPIDER_GROUP_2)

	if(href_list["toggle_group_3"])
		var/obj/item/implant/carrion_spider/activated_spider = locate(href_list["toggle_group_3"]) in active_spiders
		if(activated_spider)
			activated_spider.toggle_group(SPIDER_GROUP_3)

	if(href_list["toggle_group_4"])
		var/obj/item/implant/carrion_spider/activated_spider = locate(href_list["toggle_group_4"]) in active_spiders
		if(activated_spider)
			activated_spider.toggle_group(SPIDER_GROUP_4)

	if(href_list["toggle_autoassign"])
		autoassign_groups = !autoassign_groups

	if(href_list["P"])
		purchasePower(href_list["P"])
		EvolutionMenu()
	..()

/obj/item/organ/internal/carrion/core/proc/detach()
	set category = "Carrion"
	set name = "Detach"

	var/obj/item/organ/internal/carrion/core/core = locate() in src
	if(!core)
		return
	src = core

	if(owner.status_flags & FAKEDEATH)
		to_chat(owner, span_warning("We are regenerating our body!"))
		return

	if(alert("Are you sure you want to detach? You will lose your old body and half of your evolved abilities and gene points.",,"Yes","No") == "No")
		return

	gibs(owner.loc, null, /obj/effect/gibspawner/generic, "#666600", "#666600")
	visible_message(span_danger("Something bursts out of [owner]'s chest!"))
	removed() //removed() does all of the work

/obj/item/organ/internal/carrion/core/proc/spider_menu()
	set category = "Carrion"
	set name = "Open spider menu"

	var/obj/item/organ/internal/carrion/core/core = locate() in src
	if(!core)
		return
	src = core
	nano_ui_interact(owner)

/obj/item/organ/internal/carrion/core/removed(mob/living/user)
	if(!associated_spider && owner)
		for(var/obj/item/implant/carrion_spider/control/CS in active_spiders)
			CS.return_mind()

		owner.faction = initial(owner.faction)
		associated_spider = new /mob/living/simple_animal/spider_core(owner.loc)
		owner.mind?.transfer_to(associated_spider)
		..()
		forceMove(associated_spider)

/obj/item/organ/internal/carrion/core/proc/carrion_transform()
	set category = "Carrion"
	set name = "Transform(5)"

	var/obj/item/organ/internal/carrion/core/core = locate() in src
	if(!core)
		return
	src = core

	if (owner.transforming)
		return

	if (!owner)
		return

	if(!absorbed_dna.len)
		to_chat(owner, span_warning("You have no DNA absorbed!"))
		return

	var/S = input("Select the target DNA: ", "Target DNA", null) as null|anything in absorbed_dna

	if(!S)
		return

	if(!owner.check_ability(5))
		return

//	if(HUSK in owner.mutations)
//		owner.mutations -= HUSK
//		if(istype(owner))
//			owner.update_body(0)

	owner.visible_message(span_warning("[owner] transforms!"))
	owner.real_name = S
	owner.dna_trace = sha1(S)
	owner.fingers_trace = md5(S)
	owner.flavor_text = ""

	return 1

/obj/item/organ/internal/carrion/core/proc/carrion_fakedeath()
	set category = "Carrion"
	set name = "Regenerative Stasis (20)"

	var/obj/item/organ/internal/carrion/core/core = locate() in src
	if(!core)
		return
	src = core

	if(!owner.stat && alert("Are we sure we wish to fake our death?",,"Yes","No") == "No")
		return

	if(!(owner.check_ability(20)))
		return

	to_chat(owner, span_notice("We will attempt to regenerate our form."))

	owner.status_flags |= FAKEDEATH
	owner.update_lying_buckled_and_verb_status()
	owner.emote("gasp")
	owner.timeofdeath = world.time

	addtimer(CALLBACK(src, PROC_REF(carrion_revive)), rand(1 MINUTES, 3 MINUTES))

/obj/item/organ/internal/carrion/core/proc/carrion_revive()
	if(!owner)
		return

	owner.rejuvenate()
	for(var/limb_tag in owner.species.has_limbs)
		var/obj/item/organ/external/E = owner.get_organ(limb_tag)
		if(E.is_stump())
			qdel(E)
			var/datum/organ_description/OD = owner.species.has_limbs[limb_tag]
			OD.create_organ(owner)
	owner.status_flags &= ~FAKEDEATH
	owner.update_lying_buckled_and_verb_status()
	owner.update_body()
	owner.update_icons()
	to_chat(owner, span_notice("You have regenerated."))

/obj/item/organ/internal/carrion/core/proc/add_to_associated_organs(obj/item/organ/internal/carrion/I)
	if(istype(I))
		associated_carrion_organs += I
	return

/obj/item/organ/internal/carrion/maw
	name = "carrion maw"
	parent_organ_base = BP_HEAD
	icon_state = "carrion_maw"
	organ_efficiency = list(OP_MAW = 100)
	var/last_call = -5 MINUTES
	var/tearing = FALSE

	owner_verbs = list(
		/obj/item/organ/internal/carrion/maw/proc/consume_flesh,
		/obj/item/organ/internal/carrion/maw/proc/toxic_puddle,
		/obj/item/organ/internal/carrion/maw/proc/spider_call
	)

/obj/item/organ/internal/carrion/maw/proc/consume_flesh()
	set category = "Carrion"
	set name = "Consume the flesh"

	var/obj/item/organ/internal/carrion/maw/maw = locate() in src
	if(!maw)
		return
	src = maw

	var/food = owner.get_active_held_item()

	if(!food)
		to_chat(owner, span_warning("You can't eat nothing."))
		return

	if(istype(food, /obj/item/grab))
		var/obj/item/grab/grab = food
		var/mob/living/carbon/human/H = grab.affecting
		if (grab.state < GRAB_AGGRESSIVE)
			to_chat(owner, span_warning("Your grip upon [H.name] is too weak."))
			return
		if(istype(H))
			var/obj/item/organ/external/E = H.get_organ(owner.targeted_organ)
			if (tearing) // one at a time, thank you.
				to_chat(owner, span_warning("Your maw is already focused on something."))
				return

			if(E.is_stump())
				to_chat(owner, span_warning("There is nothing there!"))
				return
			tearing = TRUE

			visible_message(span_danger("[owner] bites into [H.name]'s [E.name] and starts tearing it apart!"))
			if(do_after(owner, 5 SECONDS, H))
				tearing = FALSE
				E.take_damage(30, BRUTE)
				var/blacklist = list()
				for (var/obj/item/organ/internal/to_blacklist in E.internal_organs)
					if (istype(to_blacklist, /obj/item/organ/internal/bone/))
						blacklist += to_blacklist
						continue
					if (istype(to_blacklist, /obj/item/organ/internal/vital/brain/))
						blacklist += to_blacklist// removing bones from a valid_organs list based on
				var/list/valid_organs = E.internal_organs - blacklist// E.internal_organs gibs the victim.
				if (!valid_organs.len)
					visible_message(span_danger("[owner] tears up [H]'s [E.name]!"))
					return
				var/obj/item/organ/internal/organ_to_remove = pick(valid_organs)
				organ_to_remove.removed(owner)
				visible_message(span_danger("[owner] tears \a [organ_to_remove] out of [H.name]'s [E.name]!"))
				playsound(loc, 'sound/voice/shriek1.ogg', 50)
				return
			else
				tearing = FALSE
		else
			to_chat(owner, span_warning("You can only tear flesh out of humanoids!"))
			return

	if(istype(food, /obj/item/organ) || istype(food, /obj/item/reagent_containers/food/snacks/meat))
		var/geneticpointgain = 0
		var/chemgain = 0
		var/taste_description = ""

		if(owner.carrion_hunger < 1)
			to_chat(owner, span_warning("You are not hungry."))
			return

		var/obj/item/organ/O = food
		if(istype(O))
			if(BP_IS_ROBOTIC(O))
				to_chat(owner, span_warning("This organ is robotic, you can't eat it."))
				return
			else if(istype(O, /obj/item/organ/internal/carrion))
				var/obj/item/organ/internal/carrion/core/G = owner.random_organ_by_process(BP_SPCORE)
				if(O in G.associated_carrion_organs)
					taste_description = "albeit delicious, your own organs carry no new genetic material"
				else
					owner.carrion_hunger += 3
					geneticpointgain = 4
					chemgain = 50
					taste_description = "carrion organs taste heavenly, you need more!"
			else if(istype(O, /obj/item/organ/internal))
				var/organ_rotten = FALSE
				if (O.status & ORGAN_DEAD)
					organ_rotten = TRUE
				if(O.species != GLOB.all_species[SPECIES_HUMAN])
					chemgain = 5
					taste_description = "this non-human organ is very bland." // no removal of hunger here, getting and storing a ton of monkey organs isn't too easy, and 5 chem points isn't terribly much.
				else
					geneticpointgain = organ_rotten ? 1 : 3
					chemgain = organ_rotten ? 4 : 10
					taste_description = "internal organs are delicious[organ_rotten ? ", but rotten ones less so." : "."]"
			else
				geneticpointgain = 2
				chemgain = 5
				taste_description = "limbs are satisfying."

		else if(istype(food, /obj/item/reagent_containers/food/snacks/meat/human))
			geneticpointgain = 2
			chemgain = 5
			taste_description = "human meat is satisfying."

		else
			chemgain = 5
			owner.carrion_hunger -= 1 //Prevents meat eating spam for infinate chems
			taste_description = "this meat is bland."

		var/obj/item/organ/internal/carrion/core/C = owner.random_organ_by_process(BP_SPCORE)
		if(C)
			C.geneticpoints += min(geneticpointgain, owner.carrion_hunger)

		owner.carrion_hunger = max(owner.carrion_hunger - geneticpointgain, 0)
		owner.ingested.add_reagent("nutriment", chemgain)

		var/chemvessel_efficiency = owner.get_organ_efficiency(OP_CHEMICALS)
		if(chemvessel_efficiency > 1)
			owner.carrion_stored_chemicals = min(owner.carrion_stored_chemicals + 0.01 * chemvessel_efficiency , 0.5 * chemvessel_efficiency)

		to_chat(owner, span_notice("You consume \the [food], [taste_description]."))
		visible_message(span_danger("[owner] devours \the [food]!"))
		qdel(food)

	else
		to_chat(owner, span_warning("You can't eat this!"))

/obj/item/organ/internal/carrion/maw/proc/spider_call()
	set category = "Carrion"
	set name = "Spider call (30)"

	var/obj/item/organ/internal/carrion/maw/maw = locate() in src
	if(!maw)
		return
	src = maw

	if(last_call + 5 MINUTES > world.time)
		to_chat(owner, span_warning("Your maw is tired, you can only call for help every 5 minutes."))
		return

	if(owner.check_ability(30))
		playsound(loc, 'sound/voice/shriek1.ogg', 100, 1, 8, 8)
		spawn(2)
			playsound(loc, 'sound/voice/shriek1.ogg', 100, 1, 8, 8) //Same trick as with the fuhrer
		visible_message(span_danger("[owner] emits a frightening screech as you feel the ground tramble!"))
		for (var/obj/structure/burrow/B in find_nearby_burrows())
			for(var/i = 1, i <= 4 ,i++) //4 per burrow
				var/obj/structure/burrow/origin = SSmigration.choose_burrow_target(null, TRUE, 100)
				var/spider_to_spawn = pickweight(list(/mob/living/carbon/superior_animal/giant_spider = 4,\
					/mob/living/carbon/superior_animal/giant_spider/nurse = 2,\
					/mob/living/carbon/superior_animal/giant_spider/hunter = 2))
				new spider_to_spawn(B)
				origin.migrate_to(B, 3 SECONDS, 0)
		last_call = world.time

/obj/item/organ/internal/carrion/maw/proc/toxic_puddle()
	set category = "Carrion"
	set name = "Toxic puddle (10)"

	var/obj/item/organ/internal/carrion/maw/maw = locate() in src
	if(!maw)
		return
	src = maw

	var/turf/T = get_turf(owner)
	if(locate(/obj/effect/decal/cleanable/carrion_puddle) in T)
		to_chat(owner, span_warning("There is already a toxic puddle here."))
		return

	if(owner.check_ability(10, TRUE))
		playsound(src, 'sound/effects/blobattack.ogg', 50, 1)
		new /obj/effect/decal/cleanable/carrion_puddle(T)
		to_chat(owner, span_notice("You vomit a toxic puddle"))

/obj/effect/decal/cleanable/carrion_puddle
	name = "toxic puddle"
	icon = 'icons/effects/effects.dmi'
	desc = "It emits an abhorrent smell, you shouldn't step anywhere near it."
	icon_state = "toxic_puddle"
	anchored = TRUE
	spawn_blacklisted = TRUE

/obj/effect/decal/cleanable/carrion_puddle/Initialize()
	. = ..()
	START_PROCESSING(SSprocessing, src)

/obj/effect/decal/cleanable/carrion_puddle/Destroy()
	STOP_PROCESSING(SSprocessing, src)
	. = ..()

/obj/effect/decal/cleanable/carrion_puddle/Process()
	for(var/mob/living/creature in mobs_in_view(1, src))
		if(creature.faction == "spiders")
			continue
		toxin_attack(creature, rand(1, 3))

/obj/effect/decal/cleanable/solid_biomass/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/mop) || istype(I, /obj/item/soap))
		to_chat(user, span_notice("You started cleaning this [src]."))
		if(do_after(user, 3 SECONDS, src))
			to_chat(user, span_notice("You clean \The [src]."))
			qdel(src)

/obj/item/organ/internal/carrion/spinneret
	name = "carrion spinneret"
	parent_organ_base = BP_GROIN
	icon_state = "carrion_spinneret"
	organ_efficiency = list(OP_SPINNERET = 100)
	owner_verbs = list(
		/obj/item/organ/internal/carrion/spinneret/proc/make_nest,
		/obj/item/organ/internal/carrion/spinneret/proc/bloodpurge,
		/obj/item/organ/internal/carrion/spinneret/proc/make_stickyweb
	)

/obj/item/organ/internal/carrion/spinneret/proc/make_stickyweb()
	set category = "Carrion"
	set name = "Make a web (5)"

	var/obj/item/organ/internal/carrion/spinneret/spinneret = locate() in src
	if(!spinneret)
		return
	src = spinneret

	if(locate(/obj/effect/spider/stickyweb) in get_turf(src))
		to_chat(owner, span_warning("There is alredy web on the floor!"))
		return

	if(owner.check_ability(5,TRUE))
		visible_message(span_notice("\The [owner] begins to secrete a sticky substance."))
		new /obj/effect/spider/stickyweb(get_turf(src))
		update_openspace()

/obj/item/organ/internal/carrion/spinneret/proc/bloodpurge()
	set category = "Carrion"
	set name = "Blood Purge (25)"

	var/obj/item/organ/internal/carrion/spinneret/spinneret = locate() in src
	if(!spinneret)
		return
	src = spinneret

	if(owner.check_ability(25))
		to_chat(owner, span_notice("You cleanse your blood of all chemicals and poisons."))
		owner.radiation = 0
		owner.reagents.update_total()
		owner.reagents.trans_to_turf(owner.loc, owner.reagents.total_volume)

/obj/item/organ/internal/carrion/spinneret/proc/make_nest()
	set category = "Carrion"
	set name = "Make a spider nest (30, 1)"

	var/obj/item/organ/internal/carrion/spinneret/spinneret = locate() in src
	if(!spinneret)
		return
	src = spinneret

	if (owner.check_ability(30,TRUE, 1))
		new /obj/structure/spider_nest(owner.loc)

/obj/structure/spider_nest
	name = "spider nest"
	desc = "A nest that periodicaly produces spiders"
	icon_state = "spider_nest"
	anchored = TRUE
	density = FALSE
	breakable = TRUE
	var/spider_spawns

/obj/structure/spider_nest/New()
	. = ..()
	spider_spawns = rand(3,8)
	addtimer(CALLBACK(src, PROC_REF(spawn_spider)), 30 SECONDS)

/obj/structure/spider_nest/attackby(obj/item/I, mob/living/user)
	..()
	if(I.force >= WEAPON_FORCE_PAINFUL)
		playsound(loc, 'sound/voice/shriek1.ogg', 85, 1, 8, 8)
		spawn_spider()
		attack_animation(user)
		visible_message(span_warning("\The [src] bursts open!"))
		qdel(src)

/obj/structure/spider_nest/bullet_act(obj/item/projectile/P, def_zone)
	playsound(loc, 'sound/voice/shriek1.ogg', 85, 1, 8, 8)
	spawn_spider()
	visible_message(span_warning("[src] bursts open!"))
	qdel(src)
	..()

/obj/structure/spider_nest/proc/spawn_spider()
	var/spider_to_spawn = pickweight(list(/mob/living/carbon/superior_animal/giant_spider = 4,\
		/mob/living/carbon/superior_animal/giant_spider/nurse = 2,\
		/mob/living/carbon/superior_animal/giant_spider/hunter = 2))
	new spider_to_spawn(loc)
	visible_message(span_warning("A spider spews out of \The [src]"))
	spider_spawns--
	if(spider_spawns)
		addtimer(CALLBACK(src, PROC_REF(spawn_spider)), 1 MINUTES)

/mob/proc/make_carrion()
	var/mob/living/carbon/human/user = src
	if(istype(user))
		var/obj/item/organ/external/chest = user.get_organ(BP_CHEST)
		if(chest)
			var/obj/item/organ/internal/carrion/core/C = new /obj/item/organ/internal/carrion/core
			C.replaced(chest)
		user.faction = "spiders"
