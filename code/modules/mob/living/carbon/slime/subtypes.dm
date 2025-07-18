/mob/living/carbon/slime/proc/mutation_table(colour)
	var/list/slime_mutation[4]
	switch(colour)
		//Tier 1
		if("grey")
			slime_mutation[1] = "orange"
			slime_mutation[2] = "metal"
			slime_mutation[3] = "blue"
			slime_mutation[4] = "purple"
		//Tier 2
		if("purple")
			slime_mutation[1] = "dark purple"
			slime_mutation[2] = "dark blue"
			slime_mutation[3] = "green"
			slime_mutation[4] = "green"
		if("metal")
			slime_mutation[1] = MATERIAL_SILVER
			slime_mutation[2] = "yellow"
			slime_mutation[3] = MATERIAL_GOLD
			slime_mutation[4] = MATERIAL_GOLD
		if("orange")
			slime_mutation[1] = "dark purple"
			slime_mutation[2] = "yellow"
			slime_mutation[3] = "red"
			slime_mutation[4] = "red"
		if("blue")
			slime_mutation[1] = "dark blue"
			slime_mutation[2] = MATERIAL_SILVER
			slime_mutation[3] = "pink"
			slime_mutation[4] = "pink"
		//Tier 3
		if("dark blue")
			slime_mutation[1] = "purple"
			slime_mutation[2] = "purple"
			slime_mutation[3] = "blue"
			slime_mutation[4] = "blue"
		if("dark purple")
			slime_mutation[1] = "purple"
			slime_mutation[2] = "purple"
			slime_mutation[3] = "orange"
			slime_mutation[4] = "orange"
		if("yellow")
			slime_mutation[1] = "metal"
			slime_mutation[2] = "metal"
			slime_mutation[3] = "orange"
			slime_mutation[4] = "orange"
		if(MATERIAL_SILVER)
			slime_mutation[1] = "metal"
			slime_mutation[2] = "metal"
			slime_mutation[3] = "blue"
			slime_mutation[4] = "blue"
		//Tier 4
		if("pink")
			slime_mutation[1] = "pink"
			slime_mutation[2] = "pink"
			slime_mutation[3] = "light pink"
			slime_mutation[4] = "light pink"
		if("red")
			slime_mutation[1] = "red"
			slime_mutation[2] = "red"
			slime_mutation[3] = "oil"
			slime_mutation[4] = "oil"
		if(MATERIAL_GOLD)
			slime_mutation[1] = MATERIAL_GOLD
			slime_mutation[2] = MATERIAL_GOLD
			slime_mutation[3] = "adamantine"
			slime_mutation[4] = "adamantine"
		if("green")
			slime_mutation[1] = "green"
			slime_mutation[2] = "green"
			slime_mutation[3] = "black"
			slime_mutation[4] = "black"
		// Tier 5
		else
			slime_mutation[1] = colour
			slime_mutation[2] = colour
			slime_mutation[3] = colour
			slime_mutation[4] = colour
	return(slime_mutation)
