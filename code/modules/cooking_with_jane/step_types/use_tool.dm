//A cooking step that involves using an item on the food.
/datum/cooking_with_jane/recipe_step/use_tool
	class=CWJ_USE_ITEM
	var/tool_type
	var/tool_quality
	var/inherited_quality_modifier = 1

//item_type: The type path of the object we are looking for.
//base_quality_award: The quality awarded by following this step.
//our_recipe: The parent recipe object
/datum/cooking_with_jane/recipe_step/use_tool/New(type, quality, datum/cooking_with_jane/recipe/our_recipe)

	desc = "Use \a [type] tool of quality [quality] or higher."

	tool_type = type
	tool_quality = quality

	..(our_recipe)


/datum/cooking_with_jane/recipe_step/use_tool/check_conditions_met(obj/added_item, datum/cooking_with_jane/recipe_tracker/tracker)
	if(!istype(added_item, /obj/item/tool ))
		return CWJ_CHECK_INVALID

	var/obj/item/tool/our_tool = added_item
	if(!our_tool.has_quality(tool_type))
		return CWJ_CHECK_INVALID

	return CWJ_CHECK_VALID

/datum/cooking_with_jane/recipe_step/use_tool/follow_step(obj/added_item, obj/item/reagent_containers/cooking_with_jane/cooking_container/container)
	var/obj/item/tool/our_tool = added_item
	if(our_tool.worksound && our_tool.worksound != NO_WORKSOUND)
		playsound(usr.loc, our_tool.worksound, 50, 1)
	to_chat(usr, span_notice("You use the [added_item] according to the recipe."))

	if(our_tool.get_tool_quality(tool_type) < tool_quality)
		return to_chat(usr, span_notice("The low quality of the tool hurts the quality of the dish."))

	return CWJ_SUCCESS

//Think about a way to make this more intuitive?
/datum/cooking_with_jane/recipe_step/use_tool/calculate_quality(obj/added_item)
	var/obj/item/tool/our_tool = added_item
	var/raw_quality
	if(usr.a_intent == I_HELP)
		raw_quality = (our_tool.get_tool_quality(tool_type) - tool_quality) * inherited_quality_modifier
	else
		raw_quality = ((our_tool.get_tool_quality(tool_type) * -1) - tool_quality) * inherited_quality_modifier //Purposefully mucking up a recipe should invert the positive bonus into a negative
		to_chat(usr, span_notice("You apply the [added_item] with ill intent, resulting in a worse dish."))
	return clamp_quality(raw_quality)
