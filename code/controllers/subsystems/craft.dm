SUBSYSTEM_DEF(craft)
	name = "Craft"
	init_order = INIT_ORDER_CRAFT
	flags = SS_NO_FIRE
	var/list/categories //list of craft_recipe objects(datums)
	var/list/cat_names //list of strings from craft_recipe.category

	var/global/list/current_category = list()
	var/global/list/current_item = list()

/datum/controller/subsystem/craft/Initialize(timeofday)
	categories = list()
	cat_names = list()
	for(var/datum/craft_recipe/CR as anything in subtypesof(/datum/craft_recipe))
		if(!initial(CR?.name))
			continue
		CR = new CR
		cat_names |= CR.category
		if(!length(CR.steps))
			if(CR.name)
				log_world("ERROR: empty steps for craft recipe [CR.type]")
			qdel(CR)
		if(!(CR.category in categories))
			categories[CR.category] = list()
		categories[CR.category] += CR
	return SS_INIT_SUCCESS

