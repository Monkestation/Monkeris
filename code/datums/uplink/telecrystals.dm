/***************
* Telecrystals *
***************/
/datum/uplink_item/item/telecrystal
	category = /datum/uplink_category/telecrystals
	desc = "Acquire the uplink crystals in pure form."

/datum/uplink_item/item/telecrystal/get_goods(obj/item/device/uplink/U, loc)
	return new /obj/item/stack/telecrystal(loc, cost(U.uses))

/datum/uplink_item/item/telecrystal/one
	name = "Telecrystal - 01"
	item_cost = 1

/datum/uplink_item/item/telecrystal/five
	name = "Telecrystals - 05"
	item_cost = 5

/datum/uplink_item/item/telecrystal/ten
	name = "Telecrystals - 10"
	item_cost = 10

/datum/uplink_item/item/telecrystal/twentyfive
	name = "Telecrystals - 25"
	item_cost = 25

/datum/uplink_item/item/telecrystal/all
	name = "Telecrystals - Empty Uplink"

/datum/uplink_item/item/telecrystal/all/cost(telecrystals)
	return max(1, telecrystals)
