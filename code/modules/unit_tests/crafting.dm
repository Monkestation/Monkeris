/datum/unit_test/crafting

/datum/unit_test/crafting/Run()
	for(var/datum/craft_recipe/CR as anything in subtypesof(/datum/craft_recipe))
		if(!initial(CR?.name))
			continue
		CR = new CR
		if(!length(CR.steps))
			if(CR.name)
				TEST_FAIL("ERROR: empty steps for craft recipe [CR.type]")
			qdel(CR)
