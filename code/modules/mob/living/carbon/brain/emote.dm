/mob/living/carbon/brain/emote(act,m_type=1,message = null)
	if(!(container && istype(container, /obj/item/device/mmi)))//No MMI, no emotes
		return

	if (findtext(act, "-", 1, null))
		var/t1 = findtext(act, "-", 1, null)
		act = copytext(act, 1, t1)

	if(findtext(act,"s",-1) && !findtext(act,"_",-2))//Removes ending s's unless they are prefixed with a '_'
		act = copytext(act,1,length(act))

	if(src.stat == DEAD)
		return
	switch(act)
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

		if ("custom")
			return custom_emote(m_type, message)
		if ("alarm")
			to_chat(src, "You sound an alarm.")
			message = "<B>[src]</B> sounds an alarm."
			m_type = 2
		if ("alert")
			to_chat(src, "You let out a distressed noise.")
			message = "<B>[src]</B> lets out a distressed noise."
			m_type = 2
		if ("notice")
			to_chat(src, "You play a loud tone.")
			message = "<B>[src]</B> plays a loud tone."
			m_type = 2
		if ("flash")
			message = "The lights on <B>[src]</B> flash quickly."
			m_type = 1
		if ("blink")
			message = "<B>[src]</B> blinks."
			m_type = 1
		if ("whistle")
			to_chat(src, "You whistle.")
			message = "<B>[src]</B> whistles."
			m_type = 2
		if ("beep")
			to_chat(src, "You beep.")
			message = "<B>[src]</B> beeps."
			m_type = 2
		if ("boop")
			to_chat(src, "You boop.")
			message = "<B>[src]</B> boops."
			m_type = 2
		if ("help")
			to_chat(src, "alarm,alert,notice,flash,blink,whistle,beep,boop")
		else
			to_chat(src, span_blue("Unusable emote '[act]'. Say *help for a list."))

	if (message)
		log_emote("[name]/[key] : [message]")

		send_emote(message, m_type)
