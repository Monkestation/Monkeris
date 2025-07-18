/proc/togglebuildmode(mob/M as mob in GLOB.player_list)
	set name = "Toggle Build Mode"
	set category = "Special Verbs"
	if(M.client)
		if(M.client.buildmode)
			log_admin("[key_name(usr)] has left build mode.")
			M.client.buildmode = 0
			M.client.show_popup_menus = 1
			for(var/obj/effect/bmode/buildholder/H)
				if(H.cl == M.client)
					qdel(H)
		else
			log_admin("[key_name(usr)] has entered build mode.")
			M.client.buildmode = 1
			M.client.show_popup_menus = 0

			var/obj/effect/bmode/buildholder/H = new/obj/effect/bmode/buildholder()
			var/obj/effect/bmode/builddir/A = new/obj/effect/bmode/builddir(H)
			A.master = H
			var/obj/effect/bmode/buildhelp/B = new/obj/effect/bmode/buildhelp(H)
			B.master = H
			var/obj/effect/bmode/buildmode/C = new/obj/effect/bmode/buildmode(H)
			C.master = H
			var/obj/effect/bmode/buildquit/D = new/obj/effect/bmode/buildquit(H)
			D.master = H

			H.builddir = A
			H.buildhelp = B
			H.buildmode = C
			H.buildquit = D
			M.client.screen += A
			M.client.screen += B
			M.client.screen += C
			M.client.screen += D
			H.cl = M.client

/obj/effect/bmode//Cleaning up the tree a bit
	density = TRUE
	anchored = TRUE
	plane = ABOVE_HUD_PLANE
	layer = ABOVE_HUD_LAYER
	dir = NORTH
	icon = 'icons/misc/buildmode.dmi'
	var/obj/effect/bmode/buildholder/master = null

/obj/effect/bmode/set_plane(np)
	plane = np

/obj/effect/bmode/update_plane()
	return

/obj/effect/bmode/Destroy()
	if(master && master.cl)
		master.cl.screen -= src
	master = null
	return ..()

/obj/effect/bmode/builddir
	icon_state = "build"
	screen_loc = "NORTH,WEST"

/obj/effect/bmode/builddir/Click()
	switch(dir)
		if(NORTH)
			set_dir(EAST)
		if(EAST)
			set_dir(SOUTH)
		if(SOUTH)
			set_dir(WEST)
		if(WEST)
			set_dir(NORTHWEST)
		if(NORTHWEST)
			set_dir(NORTH)
	return 1

/obj/effect/bmode/buildhelp
	icon = 'icons/misc/buildmode.dmi'
	icon_state = "buildhelp"
	screen_loc = "NORTH,WEST+1"

/obj/effect/bmode/buildhelp/Click()
	switch(master.cl.buildmode)
		if(1)
			to_chat(usr, span_blue("***********************************************************"))
			to_chat(usr, span_blue("Left Mouse Button        = Construct / Upgrade"))
			to_chat(usr, span_blue("Right Mouse Button       = Deconstruct / Delete / Downgrade"))
			to_chat(usr, span_blue("Left Mouse Button + ctrl = R-Window"))
			to_chat(usr, span_blue("Left Mouse Button + alt  = Airlock"))
			to_chat(usr, "")
			to_chat(usr, span_blue("Use the button in the upper left corner to"))
			to_chat(usr, span_blue("change the direction of built objects."))
			to_chat(usr, span_blue("***********************************************************"))
		if(2)
			to_chat(usr, span_blue("***********************************************************"))
			to_chat(usr, span_blue("Right Mouse Button on buildmode button = Set object type"))
			to_chat(usr, span_blue("Middle Mouse Button on buildmode button= On/Off object type saying"))
			to_chat(usr, span_blue("Middle Mouse Button on turf/obj        = Capture object type"))
			to_chat(usr, span_blue("Left Mouse Button on turf/obj          = Place objects"))
			to_chat(usr, span_blue("Right Mouse Button                     = Delete objects"))
			to_chat(usr, "")
			to_chat(usr, span_blue("Use the button in the upper left corner to"))
			to_chat(usr, span_blue("change the direction of built objects."))
			to_chat(usr, span_blue("***********************************************************"))
		if(3)
			to_chat(usr, span_blue("***********************************************************"))
			to_chat(usr, span_blue("Right Mouse Button on buildmode button = Select var(type) & value"))
			to_chat(usr, span_blue("Left Mouse Button on turf/obj/mob      = Set var(type) & value"))
			to_chat(usr, span_blue("Right Mouse Button on turf/obj/mob     = Reset var's value"))
			to_chat(usr, span_blue("***********************************************************"))
		if(4)
			to_chat(usr, span_blue("***********************************************************"))
			to_chat(usr, span_blue("Left Mouse Button on turf/obj/mob      = Select"))
			to_chat(usr, span_blue("Right Mouse Button on turf/obj/mob     = Throw"))
			to_chat(usr, span_blue("***********************************************************"))
	return 1

/obj/effect/bmode/buildquit
	icon_state = "buildquit"
	screen_loc = "NORTH,WEST+3"

/obj/effect/bmode/buildquit/Click()
	togglebuildmode(master.cl.mob)
	return 1

/obj/effect/bmode/buildholder
	density = FALSE
	anchored = TRUE
	var/client/cl
	var/obj/effect/bmode/builddir/builddir
	var/obj/effect/bmode/buildhelp/buildhelp
	var/obj/effect/bmode/buildmode/buildmode
	var/obj/effect/bmode/buildquit/buildquit
	var/atom/movable/throw_atom

/obj/effect/bmode/buildholder/Destroy()
	qdel(builddir)
	builddir = null
	qdel(buildhelp)
	buildhelp = null
	qdel(buildmode)
	buildmode = null
	qdel(buildquit)
	buildquit = null
	throw_atom = null
	cl = null
	return ..()

/obj/effect/bmode/buildmode
	icon_state = "buildmode1"
	screen_loc = "NORTH,WEST+2"
	var/varholder = "name"
	var/valueholder = "derp"
	var/objholder = /obj/structure/closet
	var/objsay = 1

/obj/effect/bmode/buildmode/Click(location, control, params)
	var/list/pa = params2list(params)

	if(pa.Find("middle"))
		switch(master.cl.buildmode)
			if(2)
				objsay=!objsay


	if(pa.Find("left"))
		switch(master.cl.buildmode)
			if(1)
				master.cl.buildmode = 2
				src.icon_state = "buildmode2"
			if(2)
				master.cl.buildmode = 3
				src.icon_state = "buildmode3"
			if(3)
				master.cl.buildmode = 4
				src.icon_state = "buildmode4"
			if(4)
				master.cl.buildmode = 1
				src.icon_state = "buildmode1"

	else if(pa.Find("right"))
		switch(master.cl.buildmode)
			if(1)
				return 1
			if(2)
				objholder = text2path(input(usr,"Enter typepath:" ,"Typepath","/obj/structure/closet"))
				if(!ispath(objholder))
					objholder = /obj/structure/closet
					alert("That path is not allowed.")
				else
					if(ispath(objholder,/mob) && !check_rights(R_DEBUG,0))
						objholder = /obj/structure/closet
			if(3)
				var/list/locked = list("vars", "key", "ckey", "client", "firemut", "ishulk", "telekinesis", "xray", "virus", "viruses", "cuffed", "ka", "last_eaten", "urine")

				master.buildmode.varholder = input(usr,"Enter variable name:" ,"Name", "name")
				if(master.buildmode.varholder in locked && !check_rights(R_DEBUG,0))
					return 1
				var/thetype = input(usr,"Select variable type:" ,"Type") in list("text","number","mob-reference","obj-reference","turf-reference")
				if(!thetype) return 1
				switch(thetype)
					if("text")
						master.buildmode.valueholder = input(usr,"Enter variable value:" ,"Value", "value") as text
					if("number")
						master.buildmode.valueholder = input(usr,"Enter variable value:" ,"Value", 123) as num
					if("mob-reference")
						master.buildmode.valueholder = input(usr,"Enter variable value:" ,"Value") as mob in SSmobs.mob_list | SShumans.mob_list
					if("obj-reference")
						master.buildmode.valueholder = input(usr,"Enter variable value:" ,"Value") as obj in world
					if("turf-reference")
						master.buildmode.valueholder = input(usr,"Enter variable value:" ,"Value") as turf in world
	return 1

/proc/build_click(mob/user, buildmode, params, obj/object)
	var/obj/effect/bmode/buildholder/holder
	for(var/obj/effect/bmode/buildholder/H)
		if(H.cl == user.client)
			holder = H
			break
	if(!holder) return
	var/list/pa = params2list(params)

	switch(buildmode)
		if(1)
			if(istype(object,/turf) && pa.Find("left") && !pa.Find("alt") && !pa.Find("ctrl") )
				if(istype(object,/turf/space))
					var/turf/T = object
					T.ChangeTurf(/turf/floor)
					return
				if(istype(object,/turf/open))
					var/turf/T = object
					T.ChangeTurf(/turf/floor)
					return
				else if(istype(object,/turf/floor))
					var/turf/T = object
					T.ChangeTurf(/turf/wall)
					return
				else if(istype(object,/turf/wall))
					var/turf/T = object
					T.ChangeTurf(/turf/wall/reinforced)
					return
			else if(pa.Find("right"))
				if(istype(object,/turf/wall))
					var/turf/T = object
					T.ChangeTurf(/turf/floor)
					return
				else if(istype(object,/turf/floor))
					var/turf/T = object
					T.ChangeTurf(/turf/space)
					return
				else if(istype(object,/turf/wall/reinforced))
					var/turf/T = object
					T.ChangeTurf(/turf/wall)
					return
				else if(isobj(object))
					qdel(object)
					return
			else if(istype(object,/turf) && pa.Find("alt") && pa.Find("left"))
				new/obj/machinery/door/airlock(get_turf(object))
			else if(istype(object,/turf) && pa.Find("ctrl") && pa.Find("left"))
				switch(holder.builddir.dir)
					if(NORTH)
						var/obj/structure/window/reinforced/WIN = new/obj/structure/window/reinforced(get_turf(object))
						WIN.set_dir(NORTH)
					if(SOUTH)
						var/obj/structure/window/reinforced/WIN = new/obj/structure/window/reinforced(get_turf(object))
						WIN.set_dir(SOUTH)
					if(EAST)
						var/obj/structure/window/reinforced/WIN = new/obj/structure/window/reinforced(get_turf(object))
						WIN.set_dir(EAST)
					if(WEST)
						var/obj/structure/window/reinforced/WIN = new/obj/structure/window/reinforced(get_turf(object))
						WIN.set_dir(WEST)
					if(NORTHWEST)
						var/obj/structure/window/reinforced/WIN = new/obj/structure/window/reinforced(get_turf(object))
						WIN.set_dir(NORTHWEST)
		if(2)
			if(pa.Find("left"))
				if(ispath(holder.buildmode.objholder,/turf))
					var/turf/T = get_turf(object)
					T.ChangeTurf(holder.buildmode.objholder)
				else
					var/obj/A = new holder.buildmode.objholder (get_turf(object))
					A.set_dir(holder.builddir.dir)
			else if(pa.Find("right"))
				if(isobj(object)) qdel(object)
			if(pa.Find("middle"))
				holder.buildmode.objholder = text2path("[object.type]")
				if(holder.buildmode.objsay)	to_chat(usr, "[object.type]")


		if(3)
			if(pa.Find("left")) //I cant believe this shit actually compiles.
				if(object.vars.Find(holder.buildmode.varholder))
					log_admin("[key_name(usr)] modified [object.name]'s [holder.buildmode.varholder] to [holder.buildmode.valueholder]")
					object.vars[holder.buildmode.varholder] = holder.buildmode.valueholder
				else
					to_chat(usr, span_red("[initial(object.name)] does not have a var called '[holder.buildmode.varholder]'"))
			if(pa.Find("right"))
				if(object.vars.Find(holder.buildmode.varholder))
					log_admin("[key_name(usr)] modified [object.name]'s [holder.buildmode.varholder] to [holder.buildmode.valueholder]")
					object.vars[holder.buildmode.varholder] = initial(object.vars[holder.buildmode.varholder])
				else
					to_chat(usr, span_red("[initial(object.name)] does not have a var called '[holder.buildmode.varholder]'"))

		if(4)
			if(pa.Find("left"))
				if(istype(object, /atom/movable))
					holder.throw_atom = object
			if(pa.Find("right"))
				if(holder.throw_atom)
					holder.throw_atom.throw_at(object, 10, 1)
					log_admin("[key_name(usr)] threw [holder.throw_atom] at [object]")
