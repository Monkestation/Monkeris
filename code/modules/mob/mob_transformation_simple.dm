
//This proc is the most basic of the procs. All it does is make a new mob on the same tile and transfer over a few variables.
//Returns the new mob
//Note that this proc does NOT do MMI related stuff!
/mob/proc/change_mob_type(new_type = null, turf/location = null, new_name = null as text, delete_old_mob = 0 as num, subspecies)

	if(isnewplayer(src))
		to_chat(usr, span_red("cannot convert players who have not entered yet."))
		return

	if(!new_type)
		new_type = input("Mob type path:", "Mob type") as text|null

	if(istext(new_type))
		new_type = text2path(new_type)

	if( !ispath(new_type) )
		to_chat(usr, "Invalid type path (new_type = [new_type]) in change_mob_type(). Contact a coder.")
		return

	if( new_type == /mob/new_player )
		to_chat(usr, span_red("cannot convert into a new_player mob type."))
		return

	var/mob/M
	if(isturf(location))
		M = new new_type( location )
	else
		M = new new_type( src.loc )

	if(!M || !ismob(M))
		to_chat(usr, "Type path is not a mob (new_type = [new_type]) in change_mob_type(). Contact a coder.")
		qdel(M)
		return

	if( istext(new_name) )
		M.name = new_name
		M.real_name = new_name
	else
		M.name = src.name
		M.real_name = src.real_name

	if(mind)
		mind.transfer_to(M)
	else
		M.key = key

	if(subspecies && ishuman(M))
		var/mob/living/carbon/human/H = M
		H.set_species(subspecies)

	if(delete_old_mob)
		QDEL_IN(src, 1)

	return M
