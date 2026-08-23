/obj/item/reagent_containers/food/snacks/examine(mob/user, extra_description = "")
	var/show_quality = ishuman(user) && user.stats.getPerk(PERK_CLUB)
	#ifdef CWJ_DEBUG
	show_quality = TRUE
	#endif
	if(show_quality)
		extra_description += span_notice("\nThe food's level of quality is [food_quality]\n")
	if(cooking_description_modifier)
		extra_description += cooking_description_modifier
	extra_description += food_descriptor

	if (bitecount==0)
		extra_description += span_notice("\nThe [src] is unbitten.")
	else if (bitecount==1)
		extra_description += span_notice("\nThe [src] was bitten by someone!")
	else if (bitecount<=3)
		extra_description += span_notice("\nThe [src] was bitten [bitecount] time\s!")
	else
		extra_description += span_notice("\nThe [src] was bitten multiple times!")
	..(user, extra_description)
