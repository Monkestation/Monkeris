var/datum/admin_secrets/admin_secrets = new()

/datum/admin_secrets
	var/list/datum/admin_secret_category/categories
	var/list/datum/admin_secret_item/items

/datum/admin_secrets/New()
	..()
	categories = init_subtypes(/datum/admin_secret_category)
	items = list()
	var/list/category_assoc = list()
	for(var/datum/admin_secret_category/category in categories)
		category_assoc[category.type] = category

	for(var/item_type in (typesof(/datum/admin_secret_item) - /datum/admin_secret_item))
		var/datum/admin_secret_item/secret_item = item_type
		if(!initial(secret_item.name))
			continue

		var/datum/admin_secret_item/item = new item_type()
		var/datum/admin_secret_category/category = category_assoc[item.category]
		dd_insertObjectList(category.items, item)
		items += item

/datum/admin_secret_category
	var/name = ""
	var/desc = ""
	var/list/datum/admin_secret_item/items

/datum/admin_secret_category/New()
	..()
	items = list()

/datum/admin_secret_category/proc/can_view(mob/user)
	for(var/datum/admin_secret_item/item in items)
		if(item.can_view(user))
			return 1
	return 0

/datum/admin_secret_item
	var/name = ""
	var/category
	var/log = 1
	//var/feedback = 1
	var/permissions = R_EVERYTHING
	var/warn_before_use = 0

/datum/admin_secret_item/dd_SortValue()
	return "[name]"

/datum/admin_secret_item/proc/name()
	return name

/datum/admin_secret_item/proc/can_view(mob/user)
	return check_rights(permissions, 0, user)

/datum/admin_secret_item/proc/can_execute(mob/user)
	if(can_view(user))
		if(!warn_before_use || alert("Execute the command '[name]'?", name, "No","Yes") == "Yes")
			return 1
	return 0

/datum/admin_secret_item/proc/execute(mob/user)
	if(!can_execute(user))
		return 0

	if(log)
		log_and_message_admins("used secret '[name]'", user)

	return 1

/*************************
* Pre-defined categories *
*************************/
/datum/admin_secret_category/admin_secrets
	name = "Admin Secrets"

/datum/admin_secret_category/random_events
	name = "'Random' Events"

/datum/admin_secret_category/fun_secrets
	name = "Fun Secrets"

/datum/admin_secret_category/final_solutions
	name = "Final Solutions"
	desc = "(Warning, these will end the round!)"

/*************************
* Pre-defined base items *
*************************/
/datum/admin_secret_item/admin_secret
	category = /datum/admin_secret_category/admin_secrets
	log = 0
	permissions = R_ADMIN

/datum/admin_secret_item/random_event
	category = /datum/admin_secret_category/random_events
	permissions = R_FUN
	warn_before_use = 1

/datum/admin_secret_item/fun_secret
	category = /datum/admin_secret_category/fun_secrets
	permissions = R_FUN
	warn_before_use = 1

/datum/admin_secret_item/final_solution
	category = /datum/admin_secret_category/final_solutions
	permissions = R_FUN|R_SERVER|R_ADMIN
