/client/var/global/list/forbidden_varedit_object_types = list(
										/datum/admins,						//Admins editing their own admin-power object? Yup, sounds like a good idea.,
										/obj/machinery/blackbox_recorder,	//Prevents people messing with feedback gathering
									)

var/list/VVlocked = list("vars", "holder", "client", "virus", "viruses", "cuffed", "last_eaten", "unlock_content", "bound_x", "bound_y", "step_x", "step_y", "force_ending")
var/list/VVicon_edit_lock = list("icon", "icon_state", "overlays", "underlays")
var/list/VVckey_edit = list("key", "ckey")

/*
/client/proc/cmd_modify_object_variables(obj/O as obj|mob|turf|area in world)   // Acceptable 'in world', as VV would be incredibly hampered otherwise
	set category = "Debug"
	set name = "Edit Variables"
	set desc="(target) Edit a target item's variables"
	src.modify_variables(O)

*/

/client/proc/mod_list_add_ass()
	var/class = "text"
	var/list/class_input = list("text","num","type","reference","mob reference", "icon","file","list","edit referenced object","restore to default")
	if(src.holder)
		var/datum/marked_datum = holder.marked_datum()
		if(marked_datum)
			class_input += "marked datum ([marked_datum.type])"

	class = input("What kind of variable?","Variable Type") as null|anything in class_input
	if(!class)
		return

	var/datum/marked_datum = holder.marked_datum()
	if(marked_datum && class == "marked datum ([marked_datum.type])")
		class = "marked datum"

	var/var_value = null

	switch(class)

		if("text")
			var_value = input("Enter new text:","Text") as null|text

		if("num")
			var_value = input("Enter new number:","Num") as null|num

		if("type")
			var_value = input("Enter type:","Type") as null|anything in typesof(/obj,/mob,/area,/turf)

		if("reference")
			var_value = input("Select reference:","Reference") as null|mob|obj|turf|area in world

		if("mob reference")
			var_value = input("Select reference:","Reference") as null|mob in world

		if("file")
			var_value = input("Pick file:","File") as null|file

		if("icon")
			var_value = input("Pick icon:","Icon") as null|icon

		if("marked datum")
			var_value = holder.marked_datum()

	if(!var_value) return

	return var_value


/client/proc/mod_list_add(list/L, atom/O, original_name, objectvar)

	var/class = "text"
	var/list/class_input = list("text","num","type","reference","mob reference", "icon","file","list","edit referenced object","restore to default")
	if(src.holder)
		var/datum/marked_datum = holder.marked_datum()
		if(marked_datum)
			class_input += "marked datum ([marked_datum.type])"

	class = input("What kind of variable?","Variable Type") as null|anything in class_input
	if(!class)
		return

	var/datum/marked_datum = holder.marked_datum()
	if(marked_datum && class == "marked datum ([marked_datum.type])")
		class = "marked datum"

	var/var_value = null

	switch(class)

		if("text")
			var_value = input("Enter new text:","Text") as text

		if("num")
			var_value = input("Enter new number:","Num") as num

		if("type")
			var_value = input("Enter type:","Type") in typesof(/obj,/mob,/area,/turf)

		if("reference")
			var_value = input("Select reference:","Reference") as mob|obj|turf|area in world

		if("mob reference")
			var_value = input("Select reference:","Reference") as mob in world

		if("file")
			var_value = input("Pick file:","File") as file

		if("icon")
			var_value = input("Pick icon:","Icon") as icon

		if("marked datum")
			var_value = holder.marked_datum()

	if(!var_value) return

	switch(alert("Would you like to associate a var with the list entry?",,"Yes","No"))
		if("Yes")
			L += var_value
			L[var_value] = mod_list_add_ass() //haha
		if("No")
			L += var_value
	log_world("### ListVarEdit by [src]: [O.type] [objectvar]: ADDED=[var_value]")
	log_admin("[key_name(src)] modified [original_name]'s [objectvar]: ADDED=[var_value]")
	message_admins("[key_name_admin(src)] modified [original_name]'s [objectvar]: ADDED=[var_value]")

/client/proc/mod_list(list/L, atom/O, original_name, objectvar)
	if(!check_rights(R_ADMIN))
		return
	if(!istype(L,/list)) src << "Not a List."

	if(L.len > 1000)
		var/confirm = alert(src, "The list you're trying to edit is very long, continuing may crash the server.", "Warning", "Continue", "Abort")
		if(confirm != "Continue")
			return

	var/assoc = 0
	if(L.len > 0)
		var/a = L[1]
		if(istext(a) && L[a] != null)
			assoc = 1 //This is pretty weak test but i can't think of anything else
			to_chat(usr, "List appears to be associative.")

	var/list/names = null
	if(!assoc)
		names = sortList(L)

	var/variable
	var/assoc_key
	if(assoc)
		variable = input("Which var?","Var") as null|anything in L + "(ADD VAR)"
	else
		variable = input("Which var?","Var") as null|anything in names + "(ADD VAR)"

	if(variable == "(ADD VAR)")
		mod_list_add(L, O, original_name, objectvar)
		return

	if(assoc)
		assoc_key = variable
		variable = L[assoc_key]

	if(!assoc && !variable || assoc && !assoc_key)
		return

	var/default

	var/dir

	if(variable in VVlocked)
		if(!check_rights(R_DEBUG))
			return
	if(variable in VVckey_edit)
		if(!check_rights(R_FUN|R_DEBUG))
			return
	if(variable in VVicon_edit_lock)
		if(!check_rights(R_FUN|R_DEBUG))
			return

	if(isnull(variable))
		to_chat(usr, "Unable to determine variable type.")

	else if(isnum(variable))
		to_chat(usr, "Variable appears to be <b>NUM</b>.")
		default = "num"
		dir = 1

	else if(istext(variable))
		to_chat(usr, "Variable appears to be <b>TEXT</b>.")
		default = "text"

	else if(isloc(variable))
		to_chat(usr, "Variable appears to be <b>REFERENCE</b>.")
		default = "reference"

	else if(isicon(variable))
		to_chat(usr, "Variable appears to be <b>ICON</b>.")
		variable = "[icon2html(variable, usr)]"
		default = "icon"

	else if(isatom(variable) || isdatum(variable))
		to_chat(usr, "Variable appears to be <b>TYPE</b>.")
		default = "type"

	else if(istype(variable,/list))
		to_chat(usr, "Variable appears to be <b>LIST</b>.")
		default = "list"

	else if(isclient(variable))
		to_chat(usr, "Variable appears to be <b>CLIENT</b>.")
		default = "cancel"

	else
		to_chat(usr, "Variable appears to be <b>FILE</b>.")
		default = "file"

	to_chat(usr, "Variable contains: [variable]")
	if(dir)
		switch(variable)
			if(1)
				dir = "NORTH"
			if(2)
				dir = "SOUTH"
			if(4)
				dir = "EAST"
			if(8)
				dir = "WEST"
			if(5)
				dir = "NORTHEAST"
			if(6)
				dir = "SOUTHEAST"
			if(9)
				dir = "NORTHWEST"
			if(10)
				dir = "SOUTHWEST"
			else
				dir = null

		if(dir)
			to_chat(usr, "If a direction, direction is: [dir]")

	var/class = "text"
	var/list/class_input = list("text","num","type","reference","mob reference", "icon","file","list","edit referenced object","restore to default")

	if(src.holder)
		var/datum/marked_datum = holder.marked_datum()
		if(marked_datum)
			class_input += "marked datum ([marked_datum.type])"

	class_input += "DELETE FROM LIST"
	class = input("What kind of variable?","Variable Type",default) as null|anything in class_input

	if(!class)
		return

	var/datum/marked_datum = holder.marked_datum()
	if(marked_datum && class == "marked datum ([marked_datum.type])")
		class = "marked datum"

	var/original_var
	if(assoc)
		original_var = L[assoc_key]
	else
		original_var = L[L.Find(variable)]

	var/new_var
	switch(class) //Spits a runtime error if you try to modify an entry in the contents list. Dunno how to fix it, yet.

		if("list")
			mod_list(variable, O, original_name, objectvar)

		if("restore to default")
			new_var = initial(variable)
			if(assoc)
				L[assoc_key] = new_var
			else
				L[L.Find(variable)] = new_var

		if("edit referenced object")
			modify_variables(variable)

		if("DELETE FROM LIST")
			log_world("### ListVarEdit by [src]: [O.type] [objectvar]: REMOVED=[html_encode("[variable]")]")
			log_admin("[key_name(src)] modified [original_name]'s [objectvar]: REMOVED=[variable]")
			message_admins("[key_name_admin(src)] modified [original_name]'s [objectvar]: REMOVED=[variable]")
			L -= variable
			return

		if("text")
			new_var = input("Enter new text:","Text") as text
			if(assoc)
				L[assoc_key] = new_var
			else
				L[L.Find(variable)] = new_var

		if("num")
			new_var = input("Enter new number:","Num") as num
			if(assoc)
				L[assoc_key] = new_var
			else
				L[L.Find(variable)] = new_var

		if("type")
			new_var = input("Enter type:","Type") in typesof(/obj,/mob,/area,/turf)
			if(assoc)
				L[assoc_key] = new_var
			else
				L[L.Find(variable)] = new_var

		if("reference")
			new_var = input("Select reference:","Reference") as mob|obj|turf|area in world
			if(assoc)
				L[assoc_key] = new_var
			else
				L[L.Find(variable)] = new_var

		if("mob reference")
			new_var = input("Select reference:","Reference") as mob in world
			if(assoc)
				L[assoc_key] = new_var
			else
				L[L.Find(variable)] = new_var

		if("file")
			new_var = input("Pick file:","File") as file
			if(assoc)
				L[assoc_key] = new_var
			else
				L[L.Find(variable)] = new_var

		if("icon")
			new_var = input("Pick icon:","Icon") as icon
			if(assoc)
				L[assoc_key] = new_var
			else
				L[L.Find(variable)] = new_var

		if("marked datum")
			new_var = holder.marked_datum()
			if(!new_var)
				return
			if(assoc)
				L[assoc_key] = new_var
			else
				L[L.Find(variable)] = new_var

	log_world("### ListVarEdit by [src]: [O.type] [objectvar]: [original_var]=[new_var]")
	log_admin("[key_name(src)] modified [original_name]'s [objectvar]: [original_var]=[new_var]")
	message_admins("[key_name_admin(src)] modified [original_name]'s varlist [objectvar]: [original_var]=[new_var]")

/client/proc/modify_variables(atom/O, param_var_name = null, autodetect_class = 0)
	if(!check_rights(R_ADMIN))
		return

	for(var/p in forbidden_varedit_object_types)
		if( istype(O,p) )
			to_chat(usr, span_danger("It is forbidden to edit this object's variables."))
			return

	var/class
	var/variable
	var/var_value

	if(param_var_name)
		if(!(param_var_name in O.vars))
			to_chat(src, "A variable with this name ([param_var_name]) doesn't exist in this atom ([O])")
			return

		if(param_var_name in VVlocked)
			if(!check_rights(R_DEBUG))
				return
		if(param_var_name in VVckey_edit)
			if(!check_rights(R_FUN|R_DEBUG))
				return
		if(param_var_name in VVicon_edit_lock)
			if(!check_rights(R_FUN|R_DEBUG))
				return

		variable = param_var_name

		var_value = O.vars[variable]

		if(autodetect_class)
			if(isnull(var_value))
				to_chat(usr, "Unable to determine variable type.")
				class = null
				autodetect_class = null
			else if(isnum(var_value))
				to_chat(usr, "Variable appears to be <b>NUM</b>.")
				class = "num"
				dir = 1

			else if(istext(var_value))
				to_chat(usr, "Variable appears to be <b>TEXT</b>.")
				class = "text"

			else if(isloc(var_value))
				to_chat(usr, "Variable appears to be <b>REFERENCE</b>.")
				class = "reference"

			else if(isicon(var_value))
				to_chat(usr, "Variable appears to be <b>ICON</b>.")
				var_value = "[icon2html(var_value, usr)]"
				class = "icon"

			else if(isatom(var_value) || isdatum(var_value))
				to_chat(usr, "Variable appears to be <b>TYPE</b>.")
				class = "type"

			else if(istype(var_value,/list))
				to_chat(usr, "Variable appears to be <b>LIST</b>.")
				class = "list"

			else if(isclient(var_value))
				to_chat(usr, "Variable appears to be <b>CLIENT</b>.")
				class = "cancel"

			else
				to_chat(usr, "Variable appears to be <b>FILE</b>.")
				class = "file"

	else

		var/list/names = list()
		for (var/V in O.vars)
			names += V

		sortList(names)

		variable = input("Which var?","Var") as null|anything in names
		if(!variable)	return
		var_value = O.vars[variable]

		if(variable in VVlocked)
			if(!check_rights(R_DEBUG)) return
		if(variable in VVckey_edit)
			if(!check_rights(R_FUN|R_DEBUG)) return
		if(variable in VVicon_edit_lock)
			if(!check_rights(R_FUN|R_DEBUG)) return

	if(!autodetect_class)

		var/dir
		var/default
		if(isnull(var_value))
			to_chat(usr, "Unable to determine variable type.")

		else if(isnum(var_value))
			to_chat(usr, "Variable appears to be <b>NUM</b>.")
			default = "num"
			dir = 1

		else if(istext(var_value))
			to_chat(usr, "Variable appears to be <b>TEXT</b>.")
			default = "text"

		else if(isloc(var_value))
			to_chat(usr, "Variable appears to be <b>REFERENCE</b>.")
			default = "reference"

		else if(isicon(var_value))
			to_chat(usr, "Variable appears to be <b>ICON</b>.")
			var_value = "[icon2html(var_value, usr)]"
			default = "icon"

		else if(isatom(var_value) || isdatum(var_value))
			to_chat(usr, "Variable appears to be <b>TYPE</b>.")
			default = "type"

		else if(istype(var_value,/list))
			to_chat(usr, "Variable appears to be <b>LIST</b>.")
			default = "list"

		else if(isclient(var_value))
			to_chat(usr, "Variable appears to be <b>CLIENT</b>.")
			default = "cancel"

		else
			to_chat(usr, "Variable appears to be <b>FILE</b>.")
			default = "file"

		to_chat(usr, "Variable contains: [var_value]")
		if(dir)
			switch(var_value)
				if(1)
					dir = "NORTH"
				if(2)
					dir = "SOUTH"
				if(4)
					dir = "EAST"
				if(8)
					dir = "WEST"
				if(5)
					dir = "NORTHEAST"
				if(6)
					dir = "SOUTHEAST"
				if(9)
					dir = "NORTHWEST"
				if(10)
					dir = "SOUTHWEST"
				else
					dir = null
			if(dir)
				to_chat(usr, "If a direction, direction is: [dir]")

		var/list/class_input = list("text","num","type","reference","mob reference", "icon","file","list","edit referenced object","restore to default")
		if(src.holder)
			var/datum/marked_datum = holder.marked_datum()
			if(marked_datum)
				class_input += "marked datum ([marked_datum.type])"
		class = input("What kind of variable?","Variable Type",default) as null|anything in class_input

		if(!class)
			return

	var/original_name

	if (!isatom(O))
		original_name = "\ref[O] ([O])"
	else
		original_name = O:name

	var/datum/marked_datum = holder.marked_datum()
	if(marked_datum && class == "marked datum ([marked_datum.type])")
		class = "marked datum"

	switch(class)

		if("list")
			mod_list(O.vars[variable], O, original_name, variable)
			return

		if("restore to default")
			O.vars[variable] = initial(O.vars[variable])

		if("edit referenced object")
			return .(O.vars[variable])

		if("text")
			var/var_new = input("Enter new text:","Text",O.vars[variable]) as null|text
			if(var_new==null) return
			O.vars[variable] = var_new

		if("num")
			if(variable=="light_range")
				var/var_new = input("Enter new number:","Num",O.vars[variable]) as null|num
				if(var_new == null) return
				O.set_light(var_new)
			else if(variable=="stat")
				var/var_new = input("Enter new number:","Num",O.vars[variable]) as null|num
				if(var_new == null) return
				if((O.vars[variable] == 2) && (var_new < 2))//Bringing the dead back to life
					GLOB.dead_mob_list -= O
					GLOB.living_mob_list += O
				if((O.vars[variable] < 2) && (var_new == 2))//Kill he
					GLOB.living_mob_list -= O
					GLOB.dead_mob_list += O
				O.vars[variable] = var_new
			else
				var/var_new =  input("Enter new number:","Num",O.vars[variable]) as null|num
				if(var_new==null) return
				O.vars[variable] = var_new

		if("type")
			var/var_new = input("Enter type:","Type",O.vars[variable]) as null|anything in typesof(/obj,/mob,/area,/turf)
			if(var_new==null) return
			O.vars[variable] = var_new

		if("reference")
			var/var_new = input("Select reference:","Reference",O.vars[variable]) as null|mob|obj|turf|area in world
			if(var_new==null) return
			O.vars[variable] = var_new

		if("mob reference")
			var/var_new = input("Select reference:","Reference",O.vars[variable]) as null|mob in world
			if(var_new==null) return
			O.vars[variable] = var_new

		if("file")
			var/var_new = input("Pick file:","File",O.vars[variable]) as null|file
			if(var_new==null) return
			O.vars[variable] = var_new

		if("icon")
			var/var_new = input("Pick icon:","Icon",O.vars[variable]) as null|icon
			if(var_new==null) return
			O.vars[variable] = var_new

		if("marked datum")
			O.vars[variable] = holder.marked_datum()

	log_world("### VarEdit by [src]: [O.type] [variable]=[html_encode("[O.vars[variable]]")]")
	log_admin("[key_name(src)] modified [original_name]'s [variable] to [O.vars[variable]]")
	message_admins("[key_name_admin(src)] modified [original_name]'s [variable] to [O.vars[variable]]")
