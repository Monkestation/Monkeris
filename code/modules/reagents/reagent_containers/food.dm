////////////////////////////////////////////////////////////////////////////////
/// Food.
////////////////////////////////////////////////////////////////////////////////
/obj/item/reagent_containers/food
	reagent_flags = INJECTABLE
	possible_transfer_amounts = null
	volume = 50 //Sets the default container amount for all food items.
	var/filling_color = "#FFFFFF" //Used by sandwiches.
	matter = list(MATERIAL_BIOMATTER = 10)
	item_icons = list(
		slot_l_hand_str = 'icons/mob/inhands/misc/food_lefthand.dmi',
		slot_r_hand_str = 'icons/mob/inhands/misc/food_righthand.dmi',
		)

