/obj/structure/closet/crate/secure/loot
	name = "abandoned crate"
	desc = "What could be inside?"
	icon_state = "securecrate"
	var/list/code = list()
	var/list/lastattempt = list()
	var/attempts = 10
	var/codelen = 4
	locked = 1

/obj/structure/closet/crate/secure/loot/New()
	..()
	var/list/digits = list("1", "2", "3", "4", "5", "6", "7", "8", "9", "0")

	for(var/i in 1 to codelen)
		code += pick(digits)
		digits -= code[code.len]

	generate_loot()

/obj/structure/closet/crate/secure/loot/proc/generate_loot()
	var/loot = rand(1, 100)
	switch(loot)
		if(1 to 5) // Common things go, 5%
			new/obj/item/reagent_containers/food/drinks/bottle/rum(src)
			new/obj/item/reagent_containers/food/drinks/bottle/whiskey(src)
			new/obj/item/reagent_containers/food/snacks/grown/ambrosiadeus(src)
			new/obj/item/flame/lighter/zippo(src)
		if(6 to 10)
			new/obj/item/tool/pickaxe/drill(src)
			new/obj/item/device/taperecorder(src)
			new/obj/item/clothing/suit/space(src)
			new/obj/item/clothing/head/space(src)
		if(11 to 15)
			new/obj/item/reagent_containers/glass/beaker/bluespace(src)
		if(16 to 20)
			for(var/i = 0, i < 10, i++)
				new/obj/item/ore/diamond(src)
		if(21 to 25)
			for(var/i = 0, i < 3, i++)
				new/obj/machinery/portable_atmospherics/hydroponics(src)
		if(26 to 30)
			for(var/i = 0, i < 3, i++)
				new/obj/item/reagent_containers/glass/beaker/noreact(src)
		if(31 to 35)
			spawn_money(rand(300,800), src)
		if(36 to 40)
			new/obj/item/melee/baton(src)
		if(41 to 45)
			new/obj/item/clothing/under/shorts/red(src)
			new/obj/item/clothing/under/shorts/blue(src)
		if(46 to 50)
			new/obj/item/clothing/under/chameleon(src)
			for(var/i = 0, i < 7, i++)
				new/obj/item/clothing/accessory/horrible(src)
		if(51 to 52) // Uncommon, 2% each
			new/obj/item/melee/classic_baton(src)
		if(53 to 54)
			new/obj/item/latexballon(src)
		if(55 to 56)
			var/newitem = pick(typesof(/obj/item/toy/prize) - /obj/item/toy/prize)
			new newitem(src)
		if(57 to 60)
			new/obj/item/rig(src)
		if(61 to 62)
			for(var/i = 0, i < 12, ++i)
				new/obj/item/reagent_containers/food/snacks/pie(src)
		if(63 to 64)
			var/t = rand(4,7)
			for(var/i = 0, i < t, ++i)
				var/newcoin = pick(/obj/item/coin/silver, /obj/item/coin/silver, /obj/item/coin/silver, /obj/item/coin/iron, /obj/item/coin/iron, /obj/item/coin/iron, /obj/item/coin/gold, /obj/item/coin/diamond, /obj/item/coin/plasma, /obj/item/coin/uranium, /obj/item/coin/platinum)
				new newcoin(src)
		if(65 to 68)
			var/t = rand(4,7)
			for(var/i = 0, i < t, ++i)
				var/newitem = pick(typesof(/obj/item/stock_parts) - /obj/item/stock_parts - /obj/item/stock_parts/subspace)
				new newitem(src)
		if(69 to 72)
			new/obj/item/tool/pickaxe/drill(src)
		if(73 to 74)
			new/obj/item/tool/pickaxe/jackhammer(src)
		if(75 to 78)
			new/obj/item/tool/pickaxe/diamonddrill(src)
		if(79 to 84)
			new/obj/item/toy/katana(src)
		if(85 to 86)
			new/obj/item/seeds/random(src)
		if(87) // Rarest things, some are unobtainble otherwise, some are just robust,  1% each
			new/obj/item/weed_extract(src)
		if(88)
			new/obj/item/xenos_claw(src)
		if(90)
			new/obj/item/organ/internal/vital/heart(src)
		if(91)
			new/obj/item/tool/sword/katana(src)
		if(92)
			new/obj/item/tool/sword/katana(src)
		if(93) // Why the hell not
			new/obj/item/storage/backpack/clown(src)
			new/obj/item/clothing/under/rank/clown(src)
			new/obj/item/clothing/shoes/clown_shoes(src)
			new/obj/item/clothing/mask/gas/clown_hat(src)
			new/obj/item/bikehorn(src)
			//new/obj/item/stamp/clown(src) I'd add it, but only clowns can use it
			new/obj/item/pen/crayon/rainbow(src)
			new/obj/item/toy/waterflower(src)
		if(94)
			new/obj/item/clothing/under/mime(src)
			new/obj/item/clothing/shoes/color/black(src)
			new/obj/item/clothing/gloves/color/white(src)
			new/obj/item/clothing/mask/gas/mime(src)
			new/obj/item/clothing/head/beret(src)
			new/obj/item/pen/crayon/mime(src)
			new/obj/item/reagent_containers/food/drinks/bottle/bottleofnothing(src)
		if(95 to 97)
			new/obj/item/melee/energy/sword(src)
		if(98)
			new/obj/item/storage/belt/champion(src)
			new/obj/item/clothing/mask/luchador(src)
		if(99 to 100)
			new/obj/item/clothing/head/bearpelt(src)

/obj/structure/closet/crate/secure/loot/togglelock(mob/user as mob)
	if(!locked)
		return

	to_chat(user, span_notice("The crate is locked with a Deca-code lock."))
	var/input = input(user, "Enter [codelen] digits.", "Deca-Code Lock", "") as text
	if(!Adjacent(user))
		return

	if(input == null || length(input) != codelen)
		to_chat(user, span_notice("You leave the crate alone."))
	else if(check_input(input))
		to_chat(user, span_notice("The crate unlocks!"))
		playsound(user, 'sound/machines/lockreset.ogg', 50, 1)
		set_locked(0)
	else
		visible_message(span_warning("A red light on \the [src]'s control panel flashes briefly."))
		attempts--
		if (attempts == 0)
			to_chat(user, span_danger("The crate's anti-tamper system activates!"))
			explosion(get_turf(src), 300, 50)
			qdel(src)

/obj/structure/closet/crate/secure/loot/emag_act(remaining_charges, mob/user)
	if (locked)
		to_chat(user, span_notice("The crate unlocks!"))
		locked = 0

/obj/structure/closet/crate/secure/loot/proc/check_input(input)
	if(length(input) != codelen)
		return 0

	. = 1
	lastattempt.Cut()
	for(var/i in 1 to codelen)
		var/guesschar = copytext(input, i, i+1)
		lastattempt += guesschar
		if(guesschar != code[i])
			. = 0

/obj/structure/closet/crate/secure/loot/attackby(obj/item/W as obj, mob/user as mob)
	if(locked)
		if (istype(W, /obj/item/tool/multitool)) // Greetings Urist McProfessor, how about a nice game of cows and bulls?
			to_chat(user, span_notice("DECA-CODE LOCK ANALYSIS:"))
			if (attempts == 1)
				to_chat(user, span_warning("* Anti-Tamper system will activate on the next failed access attempt."))
			else
				to_chat(user, span_notice("* Anti-Tamper system will activate after [src.attempts] failed access attempts."))
			if(lastattempt.len)
				var/bulls = 0
				var/cows = 0

				var/list/code_contents = code.Copy()
				for(var/i in 1 to codelen)
					if(lastattempt[i] == code[i])
						++bulls
					else if(lastattempt[i] in code_contents)
						++cows
					code_contents -= lastattempt[i]
				to_chat(user, span_notice("Last code attempt had [bulls] correct digits at correct positions and [cows] correct digits at incorrect positions."))
			return
	..()
