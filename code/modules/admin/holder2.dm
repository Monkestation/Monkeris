GLOBAL_LIST_EMPTY(admin_datums)

/datum/admins
	var/rank			= "Temporary Admin"
	var/client/owner	= null
	var/rights = 0
	var/fakekey			= null

	var/datum/weakref/marked_datum_weak

	var/admincaster_screen = 0	//See newscaster.dm under machinery for a full description
	var/datum/feed_message/admincaster_feed_message = new /datum/feed_message   //These two will act as holders.
	var/datum/feed_channel/admincaster_feed_channel = new /datum/feed_channel
	var/admincaster_signature	//What you'll sign the newsfeeds as

	var/given_profiling = FALSE

/datum/admins/proc/marked_datum()
	if(marked_datum_weak)
		return marked_datum_weak.resolve()

/datum/admins/New(initial_rank = "Temporary Admin", initial_rights = 0, ckey)
	if(!ckey)
		error("Admin datum created without a ckey argument. Datum has been deleted")
		qdel(src)
		return
	admincaster_signature = "[company_name] Officer #[rand(0,9)][rand(0,9)][rand(0,9)]"
	rank = initial_rank
	rights = initial_rights
	GLOB.admin_datums[ckey] = src

/datum/admins/proc/associate(client/C)
	if(istype(C))
		owner = C
		owner.holder = src
		owner.add_admin_verbs()	//TODO
		GLOB.admins |= C
		try_give_devtools(C)
		try_give_profiling(C)

/datum/admins/proc/disassociate()
	if(owner)
		GLOB.admins -= owner
		owner.remove_admin_verbs()
		owner.deadmin_holder = owner.holder
		owner.holder = null

/datum/admins/proc/reassociate()
	if(owner)
		GLOB.admins += owner
		owner.holder = src
		owner.deadmin_holder = null
		owner.add_admin_verbs()

/datum/admins/proc/try_give_devtools(client/C = usr)
	if(!check_rights(R_DEBUG, C = C) || owner.byond_version < 516)
		return
	to_chat(C, span_warning("516 notice: Attempting to give you devtools, may or may not work."))
	winset(C, null, "browser-options=byondstorage,find,refresh,devtools")

/datum/admins/proc/try_give_profiling(client/C = usr)
	if (config.forbid_admin_profiling)
		return

	if (given_profiling)
		return

	if (!check_rights(R_DEBUG, C = C))
		return

	given_profiling = TRUE
	world.SetConfig("APP/admin", owner.ckey, "role=admin")


/*
checks if usr is an admin with at least ONE of the flags in rights_required. (Note, they don't need all the flags)
if rights_required == 0, then it simply checks if they are an admin.
if it doesn't return 1 and show_msg=1 it will prints a message explaining why the check has failed
generally it would be used like so:

/proc/admin_proc()
	if(!check_rights(R_ADMIN)) return
	to_chat(world, "you have enough rights!")

NOTE: It checks usr by default. Supply the "�" argument if you wish to check for a specific client/mob.
*/
/proc/check_rights(rights_required, show_msg=1, client/C = usr)
	if(ismob(C))
		var/mob/M = C
		C = M.client
	if(!C)
		return FALSE
	if(!(istype(C, /client))) // If we still didn't find a client, something is wrong.
		return FALSE
	if(!C.holder)
		if(show_msg)
			C << span_warning("Error: You are not an admin.")
		return FALSE

	if(rights_required)
		if(rights_required & C.holder.rights)
			return TRUE
		else
			if(show_msg)
				C << span_warning("Error: You do not have sufficient rights to do that. You require one of the following flags:[rights2text(rights_required," ")].")
			return FALSE
	else
		return TRUE

//probably a bit iffy - will hopefully figure out a better solution
/proc/check_if_greater_rights_than(client/other)
	if(usr && usr.client)
		if(usr.client.holder)
			if(!other || !other.holder)
				return 1
			if(usr.client.holder.rights != other.holder.rights)
				if( (usr.client.holder.rights & other.holder.rights) == other.holder.rights )
					return 1	//we have all the rights they have and more
		to_chat(usr, "<font color='red'>Error: Cannot proceed. They have more or equal rights to us.</font>")
	return 0
