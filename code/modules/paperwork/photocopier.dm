/obj/machinery/photocopier
	name = "photocopier"
	icon = 'icons/obj/library.dmi'
	icon_state = "bigscanner"
	var/insert_anim = "bigscanner1"
	anchored = TRUE
	density = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 30
	active_power_usage = 200
	power_channel = STATIC_EQUIP
	var/obj/item/copyitem = null	//what's in the copier!
	var/copies = 1	//how many copies to print!
	// TODO: Make toner an item instead of a value
	var/obj/item/device/toner/toner
	var/maxcopies = 10	//how many copies can be copied at once- idea shamelessly stolen from bs12's copier!

/obj/machinery/photocopier/attack_hand(mob/user as mob)
	ui_interact(user)

/obj/machinery/photocopier/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Photocopier", "Photocopier")
		ui.open()

/obj/machinery/photocopier/ui_state(mob/user)
	return GLOB.default_state

/obj/machinery/photocopier/ui_data(mob/user)
	var/list/data = list()

	data["hasCopyitem"] = !!copyitem
	data["toner"] = toner.toner_amount
	data["copies"] = copies
	data["max_copies"] = maxcopies
	data["isSilicon"] = issilicon(user)

	return data

/obj/machinery/photocopier/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return TRUE

	switch(action)
		if("remove")
			if(copyitem)
				copyitem.loc = usr.loc
				usr.put_in_hands(copyitem)
				to_chat(usr, span_notice("You take \the [copyitem] out of \the [src]."))
				copyitem = null
		if("copy")
			if(stat & (BROKEN|NOPOWER))
				return

			for(var/i = 0; i < copies; i++)
				if(toner.toner_amount <= 0)
					break

				if (istype(copyitem, /obj/item/paper))
					copy(copyitem)
					sleep(15)
				else if (istype(copyitem, /obj/item/photo))
					photocopy(copyitem)
					sleep(15)
				else if (istype(copyitem, /obj/item/paper_bundle))
					var/obj/item/paper_bundle/B = bundlecopy(copyitem)
					sleep(15*B.pages.len)
				else
					to_chat(usr, span_warning("\The [copyitem] can't be copied by \the [src]."))
					break

				use_power(active_power_usage)
		if("set_copies")
			if(params["num_copies"] <= maxcopies)
				copies = params["num_copies"]
		if("aipic")

			if(!issilicon(usr))
				return
			if(stat & (BROKEN|NOPOWER))
				return

			if(toner.toner_amount >= 5)
				var/mob/living/silicon/tempAI = usr
				var/obj/item/device/camera/siliconcam/camera = tempAI.aiCamera

				if(!camera)
					return
				var/obj/item/photo/selection = camera.selectpicture()
				if (!selection)
					return

				var/obj/item/photo/p = photocopy(selection)
				if (p.desc == "")
					p.desc += "Copied by [tempAI.name]"
				else
					p.desc += " - Copied by [tempAI.name]"
				toner.toner_amount -= 5
				sleep(15)
			return

	return TRUE

/obj/machinery/photocopier/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/paper) || istype(I, /obj/item/photo) || istype(I, /obj/item/paper_bundle))
		if(!copyitem)
			user.drop_item()
			copyitem = I
			I.loc = src
			to_chat(user, span_notice("You insert \the [I] into \the [src]."))
			flick(insert_anim, src)
		else
			to_chat(user, span_notice("There is already something in \the [src]."))
	else if(istype(I, /obj/item/device/toner))
		if(toner <= 10) //allow replacing when low toner is affecting the print darkness
			user.drop_item()
			to_chat(user, span_notice("You insert the toner cartridge into \the [src]."))
			var/obj/item/device/toner/T = I
			toner += T.toner_amount
			qdel(I)
		else
			to_chat(user, span_notice("This cartridge is not yet ready for replacement! Use up the rest of the toner."))
	if(QUALITY_BOLT_TURNING in I.tool_qualities)
		if(I.use_tool(user, src, WORKTIME_FAST, QUALITY_BOLT_TURNING, FAILCHANCE_EASY,  required_stat = STAT_MEC))
			anchored = !anchored
			to_chat(user, span_notice("You [anchored ? "wrench" : "unwrench"] \the [src]."))
	return

/obj/machinery/photocopier/take_damage(amount)
	. = ..()
	if(QDELETED(src))
		return .
	if(toner > 0)
		new /obj/effect/decal/cleanable/blood/oil(get_turf(src))
		toner = 0

/obj/machinery/photocopier/proc/copy(obj/item/paper/copy)
	var/obj/item/paper/c = new /obj/item/paper (loc)
	if(toner > 10)	//lots of toner, make it dark
		c.info = "<font color = #101010>"
	else			//no toner? shitty copies for you!
		c.info = "<font color = #808080>"
	var/copied = html_decode(copy.info)
	copied = replacetext(copied, "<font face=\"[c.deffont]\" color=", "<font face=\"[c.deffont]\" nocolor=")	//state of the art techniques in action
	copied = replacetext(copied, "<font face=\"[c.crayonfont]\" color=", "<font face=\"[c.crayonfont]\" nocolor=")	//This basically just breaks the existing color tag, which we need to do because the innermost tag takes priority.
	c.info += copied
	c.info += "</font>"//</font>
	c.name = copy.name // -- Doohl
	c.fields = copy.fields
	c.stamps = copy.stamps
	c.stamped = copy.stamped
	c.ico = copy.ico
	c.offset_x = copy.offset_x
	c.offset_y = copy.offset_y
	var/list/temp_overlays = copy.overlays       //Iterates through stamps
	var/image/img                                //and puts a matching
	for(var/j = 1; j <= min(temp_overlays.len, copy.ico.len); j++) //gray overlay onto the copy
		if (findtext(copy.ico[j], "cap") || findtext(copy.ico[j], "cent"))
			img = image('icons/obj/bureaucracy.dmi', "paper_stamp-circle")
		else if (findtext(copy.ico[j], "deny"))
			img = image('icons/obj/bureaucracy.dmi', "paper_stamp-x")
		else
			img = image('icons/obj/bureaucracy.dmi', "paper_stamp-dots")
		img.pixel_x = copy.offset_x[j]
		img.pixel_y = copy.offset_y[j]
		c.overlays += img
	c.updateinfolinks()
	toner--
	if(toner == 0)
		visible_message(span_notice("A red light on \the [src] flashes, indicating that it is out of toner."))
	return c


/obj/machinery/photocopier/proc/photocopy(obj/item/photo/photocopy)
	var/obj/item/photo/p = photocopy.copy()
	p.loc = src.loc

	var/icon/I = icon(photocopy.icon, photocopy.icon_state)
	if(toner > 10)	//plenty of toner, go straight greyscale
		I.MapColors(rgb(77,77,77), rgb(150,150,150), rgb(28,28,28), rgb(0,0,0))		//I'm not sure how expensive this is, but given the many limitations of photocopying, it shouldn't be an issue.
		p.img.MapColors(rgb(77,77,77), rgb(150,150,150), rgb(28,28,28), rgb(0,0,0))
		p.tiny.MapColors(rgb(77,77,77), rgb(150,150,150), rgb(28,28,28), rgb(0,0,0))
	else			//not much toner left, lighten the photo
		I.MapColors(rgb(77,77,77), rgb(150,150,150), rgb(28,28,28), rgb(100,100,100))
		p.img.MapColors(rgb(77,77,77), rgb(150,150,150), rgb(28,28,28), rgb(100,100,100))
		p.tiny.MapColors(rgb(77,77,77), rgb(150,150,150), rgb(28,28,28), rgb(100,100,100))
	p.icon = I
	toner -= 5	//photos use a lot of ink!
	if(toner < 0)
		toner = 0
		visible_message(span_notice("A red light on \the [src] flashes, indicating that it is out of toner."))

	return p

//If need_toner is 0, the copies will still be lightened when low on toner, however it will not be prevented from printing. TODO: Implement print queues for fax machines and get rid of need_toner
/obj/machinery/photocopier/proc/bundlecopy(obj/item/paper_bundle/bundle, need_toner = TRUE)
	var/obj/item/paper_bundle/p = new /obj/item/paper_bundle(src)
	for(var/obj/item/W in bundle.pages)
		if(toner <= 0 && need_toner)
			toner = 0
			visible_message(span_notice("A red light on \the [src] flashes, indicating that it is out of toner."))
			break

		if(istype(W, /obj/item/paper))
			W = copy(W)
		else if(istype(W, /obj/item/photo))
			W = photocopy(W)
		W.loc = p
		p.pages += W

	p.loc = src.loc
	p.update_icon()
	p.icon_state = "paper_words"
	p.name = bundle.name
	p.pixel_y = rand(-8, 8)
	p.pixel_x = rand(-9, 9)
	return p

/obj/item/device/toner
	name = "toner cartridge"
	icon_state = "tonercartridge"
	price_tag = 100
	var/toner_amount = 30
