/obj/item/implant/carrion_spider/blight
	name = "blight spider"
	icon_state = "spiderling_blight"
	spider_price = 15

/obj/item/implant/carrion_spider/blight/activate()
	..()
	if(wearer)
		wearer.reagents.add_reagent("amatoxin", 10)
		wearer.reagents.add_reagent("pararein", 5)
		to_chat(wearer, span_warning("You feel sick and nauseous"))
		die()
	else
		to_chat(owner_mob, span_warning("[src] doesn't have a host"))
