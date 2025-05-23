//Synthesizer and minimoog. They work the same

/datum/sound_player/synthesizer
	volume = 40

/obj/structure/synthesized_instrument/synthesizer
	name = "The Synthesizer 3.0"
	desc = "This thing emits shockwaves as it plays. This is not good for your hearing."
	icon_state = "synthesizer"
	anchored = TRUE
	density = TRUE
	path = /datum/instrument
	sound_player = /datum/sound_player/synthesizer
	matter = list(MATERIAL_STEEL = 6)

/obj/structure/synthesized_instrument/synthesizer/attackby(obj/item/O, mob/user, params)
	if (istype(O, /obj/item/tool/wrench))
		if (!anchored && !isinspace())
			playsound(src.loc, 'sound/items/Ratchet.ogg', 50, 1)
			to_chat(usr, span_notice(" You begin to tighten \the [src] to the floor..."))
			if (do_after(user, 20))
				if(!anchored && !isinspace())
					user.visible_message( \
						"[user] tightens \the [src]'s casters.", \
						span_notice(" You tighten \the [src]'s casters. Now it can be played again."), \
						span_italics("You hear ratchet."))
					src.anchored = TRUE
		else if(anchored)
			playsound(src.loc, 'sound/items/Ratchet.ogg', 50, 1)
			to_chat(usr, span_notice(" You begin to loosen \the [src]'s casters..."))
			if (do_after(user, 40))
				if(anchored)
					user.visible_message( \
						"[user] loosens \the [src]'s casters.", \
						span_notice(" You loosen \the [src]. Now it can be pulled somewhere else."), \
						span_italics("You hear ratchet."))
					src.anchored = FALSE
	else
		..()

/obj/structure/synthesized_instrument/synthesizer/should_stop_playing(mob/user)
	return !((src && in_range(src, user) && src.anchored) || src.real_instrument.player.song.autorepeat)


//in-hand version
/obj/item/device/synthesized_instrument/synthesizer
	name = "Synthesizer Mini"
	desc = "The power of an entire orchestra in a handy midi keyboard format."
	icon_state = "h_synthesizer"
	path = /datum/instrument
	sound_player = /datum/sound_player/synthesizer
	matter = list(MATERIAL_STEEL = 6)

/obj/structure/synthesized_instrument/synthesizer/minimoog
	name = "space minimoog"
	desc = "This is a minimoog, like a space piano, but more spacey!"
	icon_state = "minimoog"
