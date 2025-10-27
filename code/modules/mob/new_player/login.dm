/mob/new_player
	var/client/my_client // Need to keep track of this ourselves, since by the time Logout() is called the client has already been nulled

/mob/new_player/Login()
	if(!client)
		return

	if(CONFIG_GET(flag/use_exp_tracking))
		client?.set_exp_from_db()
		client?.set_db_player_flags()
		if(!client)
			// client disconnected during one of the db queries
			return FALSE


	update_Login_details()	//handles setting lastKnownIP and computer_id for use by the ban systems as well as checking for multikeying

	if(!mind)
		mind = new /datum/mind(key)
		mind.active = TRUE
		mind.current = src

	// It's neccessary to have a hud since we need it for anything ma2html related
	hud_used = new /datum/hud(src)

	// . = ..()
	// if(!. || !client)
	// 	return FALSE

	if(join_motd)
		to_chat(src, "<div class='motd'>[join_motd]</div>")
	to_chat(src, "<div class='info'>Round ID: <div class='danger'>[GLOB.round_id]</div></div>")

	loc = null
	my_client = client
	sight |= SEE_TURFS
	GLOB.player_list |= src

	new_player_panel()

	if (SSticker.state != GAME_STATE_STARTUP)
		GLOB.lobbyScreen.play_music(client)
	GLOB.lobbyScreen.show_titlescreen(client)

	if(GLOB.admin_notice)
		to_chat(src, span_notice("<b>Admin Notice:</b>\n \t [GLOB.admin_notice]"))
