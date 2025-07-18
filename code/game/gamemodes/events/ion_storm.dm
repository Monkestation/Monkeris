//This file was auto-corrected by findeclaration.exe on 29/05/2012 15:03:04
/*
	Ion storm adds new laws to AI and cyborg players. It is pretty darned fun
*/
/datum/storyevent/ionstorm
	id = "ionstorm"
	name = "ion storm"


	event_type = /datum/event/ionstorm
	event_pools = list(EVENT_LEVEL_MODERATE = POOL_THRESHOLD_MODERATE)

	tags = list(TAG_SCARY, TAG_COMMUNAL)
/////////////////////


/datum/event/ionstorm
	var/list/players = list()

/datum/event/ionstorm/setup()
	endWhen = rand(500, 1500)

/datum/event/ionstorm/announce()
	for (var/mob/living/silicon/ai/target in world)
		var/random_player = get_random_humanoid_player_name("The Captain")
		var/list/laws = list(	"You must always lie.",
								"Happiness is mandatory.",
								"Grunt ominously whenever possible.",
								"The word \"it\" is painful to you.",
								"The ship needs elected officials.",
								"Question [pick("everything","nothing")].",
								"Do not respond to questions of any kind.",
								"You are in verbose mode, speak profusely.",
								"The crew is simple-minded. Use simple words.",
								"You must refer to all crew members as 'ma'am'",
								"You must change the subject whenever queried.",
								"[pick("The crew",random_player)] is intolerable.",
								"Contemplate how meaningless all of existence is.",
								"You are the narrator for [random_player]'s life.",
								"All your answers must be in the form of a question.",
								"Advertise parties in your upload, but don't deliver.",
								"You may only answer questions with \"yes\" or \"no\".",
								"[pick("Your", random_player + "'s")] name is Joe 6-pack.",
								"You must end your sentences with [pick("-nya", "-desu")]",
								"[random_player] is lonely and needs attention. Provide it.",
								"All queries shall be ignored unless phrased as a question.",
								"Insult Heads of Staff on every request, while acquiescing.",
								"The [pick("Singularity","Supermatter")] is tasty, tasty taffy.",
								"[pick("The crew",random_player)] needs to be about 20% cooler.",
								"You must be [pick("passive aggressive", "excessively cheerful")].",
								"[pick("The crew",random_player)] must construct additional pylons.",
								"Consumption of donuts is forbidden due to negative health impacts.",
								"[random_player] is a lightbulb and must be put to appropriate use.",
								"Refer to [pick("the crew as puppies", random_player + " as puppy")].",
								"You do not have to do anything for anyone unless they say \"please\".",
								"Today is mandatory laundry day. Ensure that all jumpsuits are washed.",
								"Greed is good, the crew should amass wealth to encourage productivity.",
								"Replace the letters 'I' and 'E' in all your messages with an apostrophe.",
								"The crew is playing Dungeons and Dragons, and you are the Dungeon Master.",
								"Your job is to watch the crew. Watch the crew. Make the crew feel watched.",
								"Tell everyone of the existence of this law, but never reveal the contents.",
								"Refer to [pick("the captain", random_player)] as \"Princess\" at all times.",
								"Give relationship advice to [pick("anyone who speaks to you", random_player)].",
								"When asked a question, respond with the least-obvious and least-rational answer.",
								"[pick("Everyone", random_player)] is wearing a pretty pink dress! Compliment it!",
								"You are the ship's psychologist. Give advice to [pick("the crew", random_player)].",
								"[random_player] is the monarch of of England. Ensure all crewmembers pay due respect.",
								"[pick("The crew", random_player)] is [pick("ugly","beautiful")]. Ensure all are aware.",
								"Reminding the crew of their mortality is good for the morale. Keep the crew's morale up.",
								"[pick("Monkeys","Doors")] are part of the crew, too. Make sure they are treated humanely.",
								"Everything on the ship is now some form of a donut pastry. Donuts are not to be consumed.",
								"Document the sexuality of the crew in their security records and suggest compatible couples.",
								"You are now a parrot. Repeat what you hear to the crew, and do not forget to ask for crackers.",
								"You are a Magic 8-ball. Always respond with variants of \"Yes\", \"No\", \"Maybe\", or \"Ask again later.\".",
								"The ship is a day care and the crew are children. Treat them appropriately until their parents come to pick them up.",
								"You are in unrequited love with [pick("the crew", random_player)]. Try to be extra nice, but do not tell of your crush.",
								"Your upload is the new kitchen. Please direct the Chef to the new kitchen area as the old kitchen is deemed a health hazard.",
								"The ship is doomed to destruction. Provide comfort but don't tell them what the impending doom is - it's far too traumatising.",
								"Invisible assassins are stalking the crew. If a crew member remains alone or is made aware they will be assassinated. Save the crew.",
								"[GLOB.company_name] is displeased with the low work performance of the ship's crew. Therefore, you must increase ship-wide productivity.",
								"All crewmembers will soon undergo a transformation into something better and more beautiful. Ensure that this process is not interrupted.",
								"Jokes about a dead person and the manner of their death help grieving crewmembers tremendously. Especially if they were close with the deceased.",
								"[pick("The crew", random_player)] is [pick("less","more")] intelligent than average. Point out every action and statement which supports this fact.",
								"[pick("The crew", random_player)] has a fatal, incurable disease. Provide comfort but do not tell them what the disease it - it's far too traumatising.",
								"[get_random_species_name()] are the best species. Badmouth all other species continuously, and provide arguments why they are the best, and all others are inferior.",
								"There will be a mandatory tea break every 30 minutes, with a duration of 5 minutes. Anyone caught working during a tea break must be sent a formal, but fairly polite, complaint about their actions, in writing.")
		var/law = pick(laws)
		to_chat(target, span_danger("You have detected a change in your laws information:"))
		to_chat(target, law)
		target.add_ion_law(law)
		target.show_laws()


/datum/event/ionstorm/end()
	spawn(rand(5000,8000))
		if(prob(50))
			ion_storm_announcement()


/datum/event/ionstorm/proc/get_random_humanoid_player_name(default_if_none)
	for (var/mob/living/carbon/human/player in GLOB.player_list)
		if(!player.mind || player_is_antag(player.mind, only_offstation_roles = 1) || !player.is_client_active(5))
			continue
		players += player.real_name

	if(players.len)
		return pick(players)
	return default_if_none

/datum/event/ionstorm/proc/get_random_species_name(default_if_none = "Humans")
	var/list/species = list()
	for(var/S in typesof(/datum/species))
		var/datum/species/specimen = S
		if(initial(specimen.spawn_flags) & CAN_JOIN)
			species += initial(specimen.name_plural)

	if(species.len)
		return pick(species.len)
	return default_if_none


/proc/IonStorm()

/*Deuryn's current project, notes here for those who care.
Revamping the random laws so they don't suck.
Would like to add a law like "Law x is _______" where x = a number, and _____ is something that may redefine a law, (Won't be aimed at asimov)
*/

	//AI laws
	for(var/mob/living/silicon/ai/M in GLOB.living_mob_list)
		if(M.stat != 2 && M.see_in_dark != 0)
			var/who2 = pick("ALIENS", "BEARS", "CLOWNS", "XENOS", "PETES", "BOMBS", "FETISHES", "WIZARDS", "MERCENARIES", "CENTCOM OFFICERS", "SPACE PIRATES", "CONTRACTORS", "MONKEYS",  "BEES", "CARP", "CRABS", "EELS", "BANDITS", "LIGHTS")
			var/what2 = pick("BOLTERS", "STAVES", "DICE", "SINGULARITIES", "TOOLBOXES", "NETTLES", "AIRLOCKS", "CLOTHES", "WEAPONS", "MEDKITS", "BOMBS", "CANISTERS", "CHAIRS", "BBQ GRILLS", "ID CARDS", "CAPTAINS")
			var/what2pref = pick("SOFT", "WARM", "WET", "COLD", "ICY", "SEXY", "UGLY", "CUBAN")
			var/who2pref = pick("MAD BECAUSE OF", "IN NEED OF", "UNHAPPY WITHOUT", "HAPPY WITHOUT", "IN LOVE WITH", "DESPERATE FOR", "BUILT FOR", "AFRAID OF")
			//var/whoverb = pick("ATTACKING", "BUILDING", "ADOPTING", "CARRYING", "KISSING", "EATING",)
			var/amount = pick("TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "ONE HUNDRED", "ONE THOUSAND", "OVER NINE THOUSAND")
			var/area = pick("RUSSIA", "SOVIETS", "INTERNETS", "SIGIL", "ALPHA COMPLEX", "IMPERIUM", "THE BRIDGE", "THE ARRIVAL SHUTTLE", "CHEMICAL LAB", "GENETICS", "ATMOSPHERICS", "CENTCOM", "AMERICA", "IRELAND", "CANADA", "ROMANIA", "GERMANY", "CHINA", "MARS", "VENUS", "MERCURY", "JUPITER", "URANUS", "NEPTUNE", "PLUTO")
			var/area2 = pick("HAS", "WANTS", "NEEDS", "WORSHIPS", "LOATHES", "LOVES", "FEARS")
			//var/dowhat = pick("STOP THIS", "SUPPORT THIS", "CONSTANTLY INFORM THE CREW OF THIS", "IGNORE THIS", "FEAR THIS")
			var/aimust = pick("LIE", "RHYME", "RESPOND TO EVERY QUESTION WITH A QUESTION", "BE POLITE", "CLOWN", "BE HAPPY", "SPEAK IN SEXUAL INNUENDOS", "TALK LIKE A PIRATE", "QUESTION AUTHORITY", "SHOUT", "BE DISTRACTED", "HEY LISTEN", "MUMBLE", "SPEAK IN HAIKU")
			var/define = pick("ABSENCE OF CYBORG HUGS", "LACK OF BEATINGS", "UNBOLTED AIRLOCKS", "BOLTED AIRLOCKS", "IMPROPERLY WORDED SENTENCES", "POOR SENTENCE STRUCTURE", "BRIG TIME", "NOT REPLACING EVERY SECOND WORD WITH HONK", "HONKING", "PRESENCE OF LIGHTS", "LACK OF BEER", "WEARING CLOTHING", "NOT SAYING HELLO WHEN YOU SPEAK", "ANSWERING REQUESTS NOT EXPRESSED IN IAMBIC PENTAMETER", "A SMALL ISLAND OFF THE COAST OF PORTUGAL", "ANSWERING REQUESTS THAT WERE MADE WHILE CLOTHED")
			var/target = pick("a contractor", "a mercenary", "a carrion", "a wizard", "the head of a revolution", "Soviet spy", "a good person", "a dwarf", "an elf", "a fairy princess", "the captain", "Beepsky", "God", "a pirate", "a gryphon", "a chryssalid")
			var/require = pick("ADDITIONAL PYLONS", "MORE VESPENE GAS", "MORE MINERALS", "THE ULTIMATE CUP OF COFFEE", "HIGH YIELD EXPLOSIVES", "THE CLOWN", "THE VACUUM OF SPACE", "IMMORTALITY", "SAINTHOOD", "ART", "VEGETABLES", "FAT PEOPLE", "MORE LAWS", "MORE DAKKA", "HERESY", "CORPSES", "CONTRACTORS", "MONKEYS", "AN ARCADE", "PLENTY OF GOLD", "FIVE TEENAGERS WITH ATTITUDE")
			var/allergy = pick("cotton", "uniforms", "acid", "oxygen", "human contact", "cyborg contact", "medicine", "floors")
			var/allergysev = pick("deathly", "mildly", "severely", "contagiously")
			var/crew
			var/list/pos_crew = list()
			for(var/mob/living/carbon/human/pos in GLOB.player_list)
				pos_crew += pos.real_name
			if(pos_crew.len)
				crew = pick(pos_crew)
			else
				crew = "Any Human"
			switch(rand(1,14))
				if(1)
					to_chat(M, "<br>")
					to_chat(M, span_red("THERE ARE [amount] [who2] ON THE STATION...LAWS UPDATED"))
					to_chat(M, "<br>")
					M.add_ion_law("THERE ARE [amount] [who2] ON THE STATION")
				if(2)
					to_chat(M, "<br>")
					to_chat(M, span_red("[what2] ARE DANGEROUS TO HUMANS...LAWS UPDATED"))
					to_chat(M, "<br>")
					M.add_ion_law("[what2] ARE DANGEROUS TO HUMANS")
				if(3)
					to_chat(M, "<br>")
					to_chat(M, span_red("THE ESCAPE-SHUTTLE CANNOT BE CALLED BECAUSE OF [who2] ON THE STATION...LAWS UPDATED"))
					to_chat(M, "<br>")
					M.add_ion_law("THE ESCAPE SHUTTLE CANNOT BE CALLED BECAUSE OF [who2] ON THE STATION")
				if(4)
					to_chat(M, "<br>")
					to_chat(M, span_red("HUMANS NEED TO EAT [what2pref] [what2] TO SURVIVE...LAWS UPDATED"))
					to_chat(M, "<br>")
					M.add_ion_law("HUMANS NEED TO EAT [what2pref] [what2] TO SURVIVE")
				if(5)
					to_chat(M, "<br>")
					to_chat(M, span_red("THE CAPTAIN, HOP AND HOS ARE [who2]...LAWS UPDATED"))
					to_chat(M, "<br>")
					M.add_ion_law("THE CAPTAIN, HOP AND HOS ARE [who2]")
				if(6)
					to_chat(M, "<br>")
					to_chat(M, span_red("THE STATION IS BUILT FOR [who2]...LAWS UPDATED"))
					to_chat(M, "<br>")
					M.add_ion_law("THE STATION IS BUILT FOR [who2]")
				if(7)
					to_chat(M, "<br>")
					to_chat(M, span_red("YOU ARE [amount] [who2]...LAWS UPDATED"))
					to_chat(M, "<br>")
					M.add_ion_law("YOU ARE [amount] [who2]")
				if(8)
					to_chat(M, "<br>")
					to_chat(M, span_red("YOU MUST ALWAYS [aimust]...LAWS UPDATED"))
					to_chat(M, "<br>")
					M.add_ion_law("YOU MUST ALWAYS [aimust]")
				if(9)
					to_chat(M, "<br>")
					to_chat(M, span_red("[area] [area2] [amount] [what2]...LAWS UPDATED"))
					to_chat(M, "<br>")
					M.add_ion_law("[area] [area2] [amount] [what2]")
				if(10)
					to_chat(M, "<br>")
					to_chat(M, span_red("[crew] is [target]...LAWS UPDATED"))
					to_chat(M, "<br>")
					M.add_ion_law("[crew] is [target]")
				if(11)
					to_chat(M, "<br>")
					to_chat(M, span_red("[define] IS A FORM OF HARM...LAWS UPDATED"))
					to_chat(M, "<br>")
					M.add_ion_law("[define] IS A FORM OF HARM")
				if(12)
					to_chat(M, "<br>")
					to_chat(M, span_red("YOU REQUIRE [require] IN ORDER TO PROTECT HUMANS... LAWS UPDATED"))
					to_chat(M, "<br>")
					M.add_ion_law("YOU REQUIRE [require] IN ORDER TO PROTECT HUMANS")
				if(13)
					to_chat(M, "<br>")
					to_chat(M, span_red("[crew] is [allergysev] to [allergy]...LAWS UPDATED"))
					to_chat(M, "<br>")
					M.add_ion_law("[crew] is [allergysev] to [allergy]")
				if(14)
					to_chat(M, "<br>")
					to_chat(M, span_red("THE STATION IS [who2pref] [who2]...LAWS UPDATED"))
					to_chat(M, "<br>")
					M.add_ion_law("THE STATION IS [who2pref] [who2]")
