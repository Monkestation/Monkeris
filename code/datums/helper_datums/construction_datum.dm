#define FORWARD -1
#define BACKWARD 1

/datum/construction
	var/list/steps
	var/atom/holder
	var/result
	var/list/steps_desc

/datum/construction/New(atom)
	..()
	holder = atom
	if(!holder) //don't want this without a holder
		spawn
			qdel(src)
	set_desc(steps.len)
	return

/datum/construction/proc/next_step()
	steps.len--
	if(!steps.len)
		spawn_result()
	else
		set_desc(steps.len)
	return

/datum/construction/proc/action(atom/used_atom, mob/user as mob)
	return

/datum/construction/proc/check_step(atom/used_atom, mob/user as mob) //check last step only
	var/valid_step = is_right_key(user, used_atom)
	if(valid_step)
		if(custom_action(valid_step, used_atom, user))
			next_step()
			return 1
	return 0

/datum/construction/proc/is_right_key(atom/used_atom) // returns current step num if used_atom is of the right type.
	var/list/L = steps[steps.len]
	if(istype(used_atom, L["key"]))
		return steps.len
	return 0

/datum/construction/proc/custom_action(step, used_atom, user)
	return 1

/datum/construction/proc/check_all_steps(atom/used_atom, mob/user as mob) //check all steps, remove matching one.
	for(var/i=1;i<=steps.len;i++)
		var/list/L = steps[i];
		if(istype(used_atom, L["key"]))
			if(custom_action(i, used_atom, user))
				steps[i]=null;//stupid byond list from list removal...
				listclearnulls(steps);
				if(!steps.len)
					spawn_result()
				return 1
	return 0


/datum/construction/proc/spawn_result()
	if(result)
		new result(get_turf(holder))
		QDEL_IN(holder, 0)
	return

/datum/construction/proc/set_desc(index as num)
	var/list/step = steps[index]
	holder.desc = step["desc"]
	return

/datum/construction/reversible
	var/index

/datum/construction/reversible/New(atom)
	..()
	index = steps.len
	return

/datum/construction/reversible/proc/update_index(diff as num)
	index+=diff
	if(index==0)
		spawn_result()
	else
		set_desc(index)
	return

/datum/construction/reversible/is_right_key(mob/living/user, atom/used_atom) // returns index step
	var/list/L = steps[index]
	var/list/possibleWays = list()
	if(ispath(L["key"]))
		if(istype(used_atom, L["key"]))
			return FORWARD //to the first step -> forward
	else
		possibleWays[L["key"]] = FORWARD
	if(ispath(L["backkey"]))
		if(L["backkey"] && istype(used_atom, L["backkey"]))
			return BACKWARD //to the last step -> backwards
	else
		possibleWays[L["backkey"]] = BACKWARD
	if(istype(used_atom, /obj/item))
		var/obj/item/I = used_atom
		var/selected = I.get_tool_type(user, possibleWays, holder)
		return selected && possibleWays[selected]
	return FALSE

/datum/construction/reversible/check_step(atom/used_atom, mob/user as mob)
	var/diff = is_right_key(user, used_atom)
	if(diff)
		if(custom_action(index, diff, used_atom, user))
			update_index(diff)
			return 1
	return 0

/datum/construction/reversible/custom_action(index, diff, used_atom, user)
	return 1
