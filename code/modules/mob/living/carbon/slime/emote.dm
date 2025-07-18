/mob/living/carbon/slime/emote(act, m_type=1, message = null)

	if (findtext(act, "-", 1, null))
		var/t1 = findtext(act, "-", 1, null)
		//param = copytext(act, t1 + 1, length(act) + 1)
		act = copytext(act, 1, t1)

	if(findtext(act,"s",-1) && !findtext(act,"_",-2))//Removes ending s's unless they are prefixed with a '_'
		act = copytext(act,1,length(act))

	var/updateicon = 0

	switch(act) //Alphabetical please
		if ("me")
			if(silent)
				return
			if (src.client)
				if (client.prefs.muted & MUTE_IC)
					to_chat(src, span_red("You cannot send IC messages (muted)."))
					return
				if (src.client.handle_spam_prevention(message,MUTE_IC))
					return
				if (stat)
					return
				if(!(message))
					return
				return custom_emote(m_type, message)
		if("bounce")
			message = "<B>The [src.name]</B> bounces in place."
			m_type = 1

		if ("custom")
			return custom_emote(m_type, message)

		if("jiggle")
			message = "<B>The [src.name]</B> jiggles!"
			m_type = 1

		if("light")
			message = "<B>The [src.name]</B> lights up for a bit, then stops."
			m_type = 1

		if("moan")
			message = "<B>The [src.name]</B> moans."
			m_type = 2

		if("shiver")
			message = "<B>The [src.name]</B> shivers."
			m_type = 2

		if("sway")
			message = "<B>The [src.name]</B> sways around dizzily."
			m_type = 1

		if("twitch")
			message = "<B>The [src.name]</B> twitches."
			m_type = 1

		if("vibrate")
			message = "<B>The [src.name]</B> vibrates!"
			m_type = 1

		if("nomood")
			mood = null
			updateicon = 1

		if("pout")
			mood = "pout"
			updateicon = 1

		if("sad")
			mood = "sad"
			updateicon = 1

		if("angry")
			mood = "angry"
			updateicon = 1

		if("frown")
			mood = "mischevous"
			updateicon = 1

		if("smile")
			mood = ":3"
			updateicon = 1

		if ("help") //This is an exception
			to_chat(src, "Help for slime emotes. You can use these emotes with say \"*emote\":\n\nbounce, custom, jiggle, light, moan, shiver, sway, twitch, vibrate. You can also set your face with: \n\nnomood, pout, sad, angry, frown, smile")

		else
			to_chat(src, span_blue("Unusable emote '[act]'. Say *help for a list."))
	if ((message && src.stat == 0))
		send_emote(message, m_type)
	if(updateicon)
		regenerate_icons()
	return
