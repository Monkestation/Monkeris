/client/proc/cmd_admin_drop_everything(mob/M as mob in SSmobs.mob_list | SShumans.mob_list)
	set category = null
	set name = "Drop Everything"
	if(!holder)
		to_chat(src, "Only administrators may use this command.")
		return

	var/confirm = alert(src, "Make [M] drop everything?", "Message", "Yes", "No")
	if(confirm != "Yes")
		return

	for(var/obj/item/W in M)
		if(W.is_equipped())
			M.drop_from_inventory(W)

	log_admin("[key_name(usr)] made [key_name(M)] drop everything!")
	message_admins("[key_name_admin(usr)] made [key_name_admin(M)] drop everything!", 1)

//send an message to somebody as a 'voice in their head'
/client/proc/cmd_admin_subtle_message(mob/M as mob in SSmobs.mob_list | SShumans.mob_list)
	set category = "Special Verbs"
	set name = "Subtle Message"

	if(!ismob(M))	return
	if(!holder)
		to_chat(src, "Only administrators may use this command.")
		return

	var/msg = sanitize(input("Message:", text("Subtle PM to [M.key]")) as text)

	if(!msg)
		return
	if(usr)
		if(usr.client)
			if(usr.client.holder)
				to_chat(M, span_bold("You hear a voice in your head... \italic [msg]"))

	log_admin("SubtlePM: [key_name(usr)] -> [key_name(M)] : [msg]")
	message_admins(span_blue("\bold SubtleMessage: [key_name_admin(usr)] -> [key_name_admin(M)] : [msg]"), 1)


//sends text to all players with no padding
/client/proc/cmd_admin_world_narrate() // Allows administrators to fluff events a little easier -- TLE
	set category = "Special Verbs"
	set name = "Global Narrate"

	if(!holder)
		to_chat(src, "Only administrators may use this command.")
		return

	var/msg = input("Message:", text("Enter the text you wish to appear to everyone:")) as text

	if(!msg)
		return
	to_chat(world, "[msg]")
	log_admin("GlobalNarrate: [key_name(usr)] : [msg]")
	message_admins(span_blue("\bold GlobalNarrate: [key_name_admin(usr)] : [msg]<BR>"), 1)


//send text directly to a player with no padding. Useful for narratives and fluff-text
/client/proc/cmd_admin_direct_narrate(mob/M)	// Targetted narrate -- TLE
	set category = "Special Verbs"
	set name = "Direct Narrate"

	if(!holder)
		to_chat(src, "Only administrators may use this command.")
		return

	if(!M)
		M = input("Direct narrate to who?", "Active Players") as null|anything in get_mob_with_client_list()

	if(!M)
		return

	var/msg = sanitize(input("Message:", text("Enter the text you wish to appear to your target:")) as text)

	if( !msg )
		return

	to_chat(M, msg)
	log_admin("DirectNarrate: [key_name(usr)] to ([M.name]/[M.key]): [msg]")
	message_admins(span_blue("\bold DirectNarrate: [key_name(usr)] to ([M.name]/[M.key]): [msg]<BR>"), 1)


/client/proc/cmd_admin_godmode(mob/M as mob in SSmobs.mob_list | SShumans.mob_list)
	set category = "Special Verbs"
	set name = "Godmode"
	if(!holder)
		to_chat(src, "Only administrators may use this command.")
		return
	M.status_flags ^= GODMODE
	to_chat(usr, span_blue("Toggled [(M.status_flags & GODMODE) ? "ON" : "OFF"]"))

	log_admin("[key_name(usr)] has toggled [key_name(M)]'s nodamage to [(M.status_flags & GODMODE) ? "On" : "Off"]")
	message_admins("[key_name_admin(usr)] has toggled [key_name_admin(M)]'s nodamage to [(M.status_flags & GODMODE) ? "On" : "Off"]", 1)



/proc/cmd_admin_mute(mob/M as mob, mute_type, automute = 0)
	if(automute)
		if(!CONFIG_GET(flag/automute_on))	return
	else
		if(!usr || !usr.client)
			return
		if(!usr.client.holder)
			to_chat(usr, "<font color='red'>Error: cmd_admin_mute: You don't have permission to do this.</font>")
			return
		if(!M.client)
			to_chat(usr, "<font color='red'>Error: cmd_admin_mute: This mob doesn't have a client tied to it.</font>")
		if(M.client.holder)
			to_chat(usr, "<font color='red'>Error: cmd_admin_mute: You cannot mute an admin/mod.</font>")
	if(!M.client)		return
	if(M.client.holder)	return

	var/muteunmute
	var/mute_string

	switch(mute_type)
		if(MUTE_IC)			mute_string = "IC (say and emote)"
		if(MUTE_OOC)		mute_string = "OOC"
		if(MUTE_PRAY)		mute_string = "pray"
		if(MUTE_ADMINHELP)	mute_string = "adminhelp, admin PM and ASAY"
		if(MUTE_DEADCHAT)	mute_string = "deadchat and DSAY"
		if(MUTE_TTS)		mute_string = "text to speech"
		if(MUTE_ALL)		mute_string = "everything"
		else				return

	if(automute)
		muteunmute = "auto-muted"
		M.client.prefs.muted |= mute_type
		log_admin("SPAM AUTOMUTE: [muteunmute] [key_name(M)] from [mute_string]")
		message_admins("SPAM AUTOMUTE: [muteunmute] [key_name_admin(M)] from [mute_string].", 1)
		to_chat(M, span_alert("You have been [muteunmute] from [mute_string] by the SPAM AUTOMUTE system. Contact an admin."))

		return

	if(M.client.prefs.muted & mute_type)
		muteunmute = "unmuted"
		M.client.prefs.muted &= ~mute_type
	else
		muteunmute = "muted"
		M.client.prefs.muted |= mute_type

	log_admin("[key_name(usr)] has [muteunmute] [key_name(M)] from [mute_string]")
	message_admins("[key_name_admin(usr)] has [muteunmute] [key_name_admin(M)] from [mute_string].", 1)
	to_chat(M, "<span class = 'alert'>You have been [muteunmute] from [mute_string].</span>")

/client/proc/cmd_admin_add_random_ai_law()
	set category = "Fun"
	set name = "Add Random AI Law"
	if(!holder)
		to_chat(src, "Only administrators may use this command.")
		return
	var/confirm = alert(src, "You sure?", "Confirm", "Yes", "No")
	if(confirm == "Yes")
		log_admin("[key_name(src)] has added a random AI law.")
		message_admins("[key_name_admin(src)] has added a random AI law.", 1)

		var/show_log = alert(src, "Show ion message?", "Message", "Yes", "No")
		if(show_log == "Yes")
			command_announcement.Announce("Ion storm detected near the ship. Please check all AI-controlled equipment for errors.", "Anomaly Alert", new_sound = 'sound/AI/ionstorm.ogg')

		IonStorm()

/*
Allow admins to set players to be able to respawn/bypass 30 min wait, without the admin having to edit variables directly
Ccomp's first proc.
*/

/client/proc/get_ghosts(notify = 0, what = 2)
	// what = 1, return ghosts ass list.
	// what = 2, return mob list

	var/list/mobs = list()
	var/list/ghosts = list()
	var/list/sortmob = sortNames(SSmobs.mob_list | SShumans.mob_list)                           // get the mob list.
	var/any=0
	for(var/mob/observer/ghost/M in sortmob)
		mobs.Add(M)                                             //filter it where it's only ghosts
		any = 1                                                 //if no ghosts show up, any will just be 0
	if(!any)
		if(notify)
			to_chat(src, "There doesn't appear to be any ghosts for you to select.")
		return

	for(var/mob/M in mobs)
		var/name = M.name
		ghosts[name] = M                                        //get the name of the mob for the popup list
	if(what==1)
		return ghosts
	else
		return mobs

// Allows a ghost to respawn
/client/proc/allow_character_respawn()
	set category = "Special Verbs"
	set name = "Allow player to respawn"
	set desc = "Let's the player bypass the 30 minute wait to respawn or allow them to re-enter their corpse."
	if(!holder)
		to_chat(src, "Only administrators may use this command.")
	var/list/ghosts= get_ghosts(1,1)

	var/target = input("Please, select a ghost!", "COME BACK TO LIFE!", null, null) as null|anything in ghosts
	if(!target)
		to_chat(src, "Hrm, appears you didn't select a ghost"		) // Sanity check, if no ghosts in the list we don't want to edit a null variable and cause a runtime error.
		return

	var/mob/observer/ghost/G = ghosts[target]
	if(G.has_enabled_antagHUD && CONFIG_GET(flag/antag_hud_restricted))
		var/response = alert(src, "Are you sure you wish to allow this individual to play?","Ghost has used AntagHUD","Yes","No")
		if(response == "No")
			return

	// Time of death is checked in /mob/verb/abandon_mob() which is the Respawn verb
	// Timeofdeath is used for bodies on autopsy, but ghost doesn't need one
	G.timeofdeath = -19999

	var/datum/preferences/P

	if(G.client)
		P = G.client.prefs
	else if(G.ckey)
		P = SScharacter_setup.preferences_datums[G.ckey]
	else
		to_chat(src, "Something went wrong, couldn't find the target's preferences datum")
		return FALSE

	for(var/entry in P.time_of_death) // Set all the prefs' times of death to a huge negative value so any respawn timers will be fine
		P.time_of_death[entry] = -99999

	G.has_enabled_antagHUD = 2
	G.can_reenter_corpse = 1
	G << 'sound/effects/magic/blind.ogg' //Play this sound to a player whenever their respawn time gets reduced
	G.show_message(span_blue("<B>You may now respawn.  You should roleplay as if you learned nothing about the round during your time with the dead.</B>"), 1)
	log_admin("[key_name(usr)] allowed [key_name(G)] to bypass the 30 minute respawn limit")
	message_admins("Admin [key_name_admin(usr)] allowed [key_name_admin(G)] to bypass the 30 minute respawn limit", 1)

/client/proc/toggle_antagHUD_use()
	set category = "Server"
	set name = "Toggle antagHUD usage"
	set desc = "Toggles antagHUD usage for observers"

	if(!holder)
		to_chat(src, "Only administrators may use this command.")
	var/action=""
	if(CONFIG_GET(flag/antag_hud_allowed))
		for(var/mob/observer/ghost/g in get_ghosts())
			if(!g.client.holder)						//Remove the verb from non-admin ghosts
				remove_verb(g, /mob/observer/ghost/verb/toggle_antagHUD)
			if(g.antagHUD)
				g.antagHUD = 0						// Disable it on those that have it enabled
				g.has_enabled_antagHUD = 2				// We'll allow them to respawn
				to_chat(g, span_red("<B>The Administrator has disabled AntagHUD </B>"))
		CONFIG_SET(flag/antag_hud_allowed, 0)
		to_chat(src, span_red("<B>AntagHUD usage has been disabled</B>"))
		action = "disabled"
	else
		for(var/mob/observer/ghost/g in get_ghosts())
			if(!g.client.holder)						// Add the verb back for all non-admin ghosts
				add_verb(g, /mob/observer/ghost/verb/toggle_antagHUD)
			to_chat(g, span_blue("<B>The Administrator has enabled AntagHUD </B>")	) // Notify all observers they can now use AntagHUD
		CONFIG_SET(flag/antag_hud_allowed, 1)
		action = "enabled"
		to_chat(src, span_blue("<B>AntagHUD usage has been enabled</B>"))


	log_admin("[key_name(usr)] has [action] antagHUD usage for observers")
	message_admins("Admin [key_name_admin(usr)] has [action] antagHUD usage for observers", 1)

/client/proc/toggle_antagHUD_restrictions()
	set category = "Server"
	set name = "Toggle antagHUD Restrictions"
	set desc = "Restricts players that have used antagHUD from being able to join this round."
	if(!holder)
		to_chat(src, "Only administrators may use this command.")
	var/action=""
	if(CONFIG_GET(flag/antag_hud_restricted))
		for(var/mob/observer/ghost/g in get_ghosts())
			to_chat(g, span_blue("<B>The administrator has lifted restrictions on joining the round if you use AntagHUD</B>"))
		action = "lifted restrictions"
		CONFIG_SET(flag/antag_hud_restricted, 0)
		to_chat(src, span_blue("<B>AntagHUD restrictions have been lifted</B>"))
	else
		for(var/mob/observer/ghost/g in get_ghosts())
			to_chat(g, span_red("<B>The administrator has placed restrictions on joining the round if you use AntagHUD</B>"))
			to_chat(g, span_red("<B>Your AntagHUD has been disabled, you may choose to re-enabled it but will be under restrictions </B>"))
			g.antagHUD = 0
			g.has_enabled_antagHUD = 0
		action = "placed restrictions"
		CONFIG_SET(flag/antag_hud_restricted, 1)
		to_chat(src, span_red("<B>AntagHUD restrictions have been enabled</B>"))

	log_admin("[key_name(usr)] has [action] on joining the round if they use AntagHUD")
	message_admins("Admin [key_name_admin(usr)] has [action] on joining the round if they use AntagHUD", 1)

/*
If a guy was gibbed and you want to revive him, this is a good way to do so.
Works kind of like entering the game with a new character. Character receives a new mind if they didn't have one.
Contractors and the like can also be revived with the previous role mostly intact.
/N */
/client/proc/respawn_character()
	set category = "Special Verbs"
	set name = "Respawn Character"
	set desc = "Respawn a person that has been gibbed/dusted/killed. They must be a ghost for this to work and preferably should not have a body to go back into."
	if(!holder)
		to_chat(src, "Only administrators may use this command.")
		return
	var/input = ckey(input(src, "Please specify which key will be respawned.", "Key", ""))
	if(!input)
		return

	var/mob/observer/ghost/G_found
	for(var/mob/observer/ghost/G in GLOB.player_list)
		if(G.ckey == input)
			G_found = G
			break

	if(!G_found)//If a ghost was not found.
		to_chat(usr, "<font color='red'>There is no active key like that in the game or the person is not currently a ghost.</font>")
		return

	var/mob/living/carbon/human/new_character = new()//The mob being spawned.

	var/datum/data/record/record_found			//Referenced to later to either randomize or not randomize the character.
	if(G_found.mind && !G_found.mind.active)	//mind isn't currently in use by someone/something
		/*Try and locate a record for the person being respawned through data_core.
		This isn't an exact science but it does the trick more often than not.*/
		var/id = md5("[G_found.real_name][G_found.mind.assigned_role]")
		for(var/datum/data/record/t in data_core.locked)
			if(t.fields["id"]==id)
				record_found = t//We shall now reference the record.
				break

	if(record_found)//If they have a record we can determine a few things.
		new_character.real_name		= record_found.fields["name"]
		new_character.gender		= record_found.fields["sex"]
		new_character.age			= record_found.fields["age"]
		new_character.b_type		= record_found.fields["b_type"]
		new_character.dna_trace		= record_found.fields["b_dna"]
		new_character.fingers_trace	= record_found.fields["fingerprint"]
	else
		new_character.gender = pick(MALE,FEMALE)
		var/datum/preferences/A = new()
		A.randomize_appearance_and_body_for(new_character)
		new_character.real_name = G_found.real_name

	if(!new_character.real_name)
		if(new_character.gender == MALE)
			new_character.real_name = capitalize(pick(GLOB.first_names_male)) + " " + capitalize(pick(GLOB.last_names))
		else
			new_character.real_name = capitalize(pick(GLOB.first_names_female)) + " " + capitalize(pick(GLOB.last_names))
	new_character.name = new_character.real_name

	if(G_found.mind && !G_found.mind.active)
		G_found.mind.transfer_to(new_character)	//be careful when doing stuff like this! I've already checked the mind isn't in use
	else
		new_character.mind_initialize()
	if(!new_character.mind.assigned_role)
		new_character.mind.assigned_role = ASSISTANT_TITLE

	new_character.key = G_found.key

	/*
	The code below functions with the assumption that the mob is already a contractor if they have a special role.
	So all it does is re-equip the mob with powers and/or items. Or not, if they have no special role.
	If they don't have a mind, they obviously don't have a special role.
	*/

	//Two variables to properly announce later on.
	var/admin = key_name_admin(src)
	var/player_key = G_found.key

	var/datum/spawnpoint/spawnpoint = SSjob.get_spawnpoint_for(new_character.client, new_character.mind.assigned_role)
	if(!spawnpoint.put_mob(new_character))
		message_admins(span_blue("[admin] has tried to respawn [player_key] as [new_character.real_name] but they declined to spawn in harmful environment."), 1)
		return

	//Now for special roles and equipment.
	SSjob.EquipRank(new_character, new_character.mind.assigned_role)

	//Announces the character on all the systems, based on the record.
	if(!issilicon(new_character))//If they are not a cyborg/AI.
		if(!record_found && !player_is_antag(new_character.mind, only_offstation_roles = 1)) //If there are no records for them. If they have a record, this info is already in there. MODE people are not announced anyway.
			//Power to the user!
			if(alert(new_character,"Warning: No data core entry detected. Would you like to announce the arrival of this character by adding them to various databases, such as medical records?",,"No","Yes")=="Yes")
				data_core.manifest_inject(new_character)

			if(alert(new_character,"Would you like an active AI to announce this character?",,"No","Yes")=="Yes")
				call(/proc/AnnounceArrival)(new_character, new_character.mind.assigned_role)

	message_admins(span_blue("[admin] has respawned [player_key] as [new_character.real_name]."), 1)

	to_chat(new_character, "You have been fully respawned. Enjoy the game.")
	AnnounceArrival(new_character, new_character.mind.assigned_role, spawnpoint.message)	//will not broadcast if there is no message
	return new_character

/client/proc/cmd_admin_add_freeform_ai_law()
	set category = "Fun"
	set name = "Add Custom AI law"
	if(!holder)
		to_chat(src, "Only administrators may use this command.")
		return
	var/input = sanitize(input(usr, "Please enter anything you want the AI to do. Anything. Serious.", "What?", "") as text|null)
	if(!input)
		return
	for(var/mob/living/silicon/ai/M in SSmobs.mob_list)
		if(M.stat == 2)
			to_chat(usr, "Upload failed. No signal is being detected from the AI.")
		else if(M.see_in_dark == 0)
			to_chat(usr, "Upload failed. Only a faint signal is being detected from the AI, and it is not responding to our requests. It may be low on power.")
		else
			M.add_ion_law(input)
			for(var/mob/living/silicon/ai/O in SSmobs.mob_list)
				to_chat(O, span_red("" + input + "\red...LAWS UPDATED"))
				O.show_laws()

	log_admin("Admin [key_name(usr)] has added a new AI law - [input]")
	message_admins("Admin [key_name_admin(usr)] has added a new AI law - [input]", 1)

	var/show_log = alert(src, "Show ion message?", "Message", "Yes", "No")
	if(show_log == "Yes")
		command_announcement.Announce("Ion storm detected near the ship. Please check all AI-controlled equipment for errors.", "Anomaly Alert", new_sound = 'sound/AI/ionstorm.ogg')

/client/proc/cmd_admin_rejuvenate(mob/living/M as mob in SSmobs.mob_list | SShumans.mob_list)
	set category = "Special Verbs"
	set name = "Rejuvenate"
	if(!holder)
		to_chat(src, "Only administrators may use this command.")
		return
	if(!mob)
		return
	if(!istype(M))
		alert("Cannot revive a ghost")
		return

	M.revive()

	log_admin("[key_name(usr)] healed / revived [key_name(M)]")
	message_admins(span_red("Admin [key_name_admin(usr)] healed / revived [key_name_admin(M)]!"), 1)

/client/proc/cmd_admin_create_centcom_report()
	set category = "Special Verbs"
	set name = "Create Command Report"
	if(!holder)
		to_chat(src, "Only administrators may use this command.")
		return
	var/input = sanitize(input(usr, "Please enter anything you want. Anything. Serious.", "What?", "") as message|null, extra = 0)
	var/customname = sanitizeSafe(input(usr, "Pick a title for the report.", "Title") as text|null)
	if(!input)
		return
	if(!customname)
		customname = "[command_name()] Update"

	//New message handling
	post_comm_message(customname, replacetext(input, "\n", "<br/>"))

	switch(alert("Should this be announced to the general population?",,"Yes","No"))
		if("Yes")
			command_announcement.Announce(input, customname, msg_sanitized = 1, use_text_to_speech = TRUE)
		if("No")
			to_chat(world, span_red("New [GLOB.company_name] Update available at all communication consoles."))
			world << sound('sound/AI/commandreport.ogg')

	log_admin("[key_name(src)] has created a command report: [input]")
	message_admins("[key_name_admin(src)] has created a command report", 1)

//delete an instance/object/mob/etc
/client/proc/cmd_admin_delete(atom/O as obj|mob|turf in range(world.view))
	set category = "Admin"
	set name = "Delete"

	if(!holder)
		to_chat(src, "Only administrators may use this command.")
		return

	if(alert(src, "Are you sure you want to delete:\n[O]\nat ([O.x], [O.y], [O.z])?", "Confirmation", "Yes", "No") == "Yes")
		log_admin("[key_name(usr)] deleted [O] at ([O.x],[O.y],[O.z])")
		message_admins("[key_name_admin(usr)] deleted [O] at ([O.x],[O.y],[O.z])", 1)

		qdel(O)

/client/proc/cmd_admin_list_open_jobs()
	set category = "Admin"
	set name = "List free slots"

	if(!holder)
		to_chat(src, "Only administrators may use this command.")
		return
	for(var/datum/job/job in SSjob.occupations)
		to_chat(src, "[job.title]: [job.total_positions]")


/client/proc/cmd_admin_explosion(atom/O as obj|mob|turf in range(world.view))
	set category = "Special Verbs"
	set name = "Explosion"

	if(!check_rights(R_DEBUG|R_FUN))	return
	var/explosion_power = input("Explosion power. From 100 to infinity") as num
	var/explosion_falloff = input("Explosion falloff. Should not be 0") as num
	var/additive_falloff = input("Additive falloff for this explosion?") as num
	var/multiplicative_falloff = input("Multiplicative falloff for this explosion?") as num
	var/eflags = additive_falloff ? EFLAG_ADDITIVEFALLOFF : 0 | multiplicative_falloff ? EFLAG_EXPONENTIALFALLOFF : 0
	if(explosion_power > 1000 || explosion_power / 15 > explosion_falloff)
		if(alert(src, "Are you sure you want to do this? Explosions above 1k cause lots of turf changes and ones with little falloff might be laggy if they go for too long.", "Confirmation", "Yes", "No") == "No")
			return
	explosion(get_turf(O), explosion_power, explosion_falloff, eflags)
	log_admin("[key_name(usr)] created an explosion with power:[explosion_power] falloff:[explosion_falloff] multiplicative:[!!multiplicative_falloff] additive : [!!additive_falloff] at ([O.x],[O.y],[O.z])")
	message_admins("[key_name_admin(usr)]created an explosion with power:[explosion_power] falloff:[explosion_falloff] multiplicative:[!!multiplicative_falloff] additive : [!!additive_falloff] at ([O.x],[O.y],[O.z])", 1)

/client/proc/cmd_admin_emp(atom/O as obj|mob|turf in range(world.view))
	set category = "Special Verbs"
	set name = "EM Pulse"

	if(!check_rights(R_DEBUG|R_FUN))
		return

	var/heavy = input("Range of heavy pulse.", text("Input"))  as num|null
	if(heavy == null)
		return
	var/light = input("Range of light pulse.", text("Input"))  as num|null
	if(light == null)
		return

	if(heavy || light)
		empulse(O, heavy, light)
		log_admin("[key_name(usr)] created an EM Pulse ([heavy],[light]) at ([O.x],[O.y],[O.z])")
		message_admins("[key_name_admin(usr)] created an EM PUlse ([heavy],[light]) at ([O.x],[O.y],[O.z])", 1)

/client/proc/cmd_admin_gib(mob/M as mob in SSmobs.mob_list | SShumans.mob_list)
	set category = "Special Verbs"
	set name = "Gib"

	if(!check_rights(R_ADMIN|R_FUN))
		return

	var/confirm = alert(src, "You sure?", "Confirm", "Yes", "No")
	if(confirm != "Yes")
		return
	//Due to the delay here its easy for something to have happened to the mob
	if(!M)
		return

	log_admin("[key_name(usr)] has gibbed [key_name(M)]")
	message_admins("[key_name_admin(usr)] has gibbed [key_name_admin(M)]", 1)

	if(isobserver(M))
		gibs(M.loc)
		return

	M.gib()

/client/proc/cmd_admin_gib_self()
	set name = "Gibself"
	set category = "Fun"

	var/confirm = alert(src, "You sure?", "Confirm", "Yes", "No")
	if(confirm == "Yes")
		if(isobserver(mob)) // so they don't spam gibs everywhere
			return
		else
			mob.gib()

		log_admin("[key_name(usr)] used gibself.")
		message_admins(span_blue("[key_name_admin(usr)] used gibself."), 1)

/client/proc/update_world()
	// If I see anyone granting powers to specific keys like the code that was here,
	// I will both remove their SVN access and permanently ban them from my servers.
	return

//displays the contents of an instance
/client/proc/cmd_admin_check_contents(mob/living/M as mob in SSmobs.mob_list | SShumans.mob_list)
	set category = "Special Verbs"
	set name = "Check Contents"

	var/list/L = M.get_contents()
	for(var/t in L)
		to_chat(usr, "[t]")

//changes how far we can see
/client/proc/toggle_view_range()
	set category = "Special Verbs"
	set name = "Change View Range"
	set desc = "switches between 1x and custom views"

	if(view == world.view)
		view = input("Select view range:", "FUCK YE", 7) in list(1,2,3,4,5,6,7,8,9,10,11,12,13,14,128)
	else
		view = world.view
	if(mob)
		mob.parallax.update()
	log_admin("[key_name(usr)] changed their view range to [view].")
	//message_admins(span_blue("[key_name_admin(usr)] changed their view range to [view]."), 1)	//why? removed by order of XSI

//allows us to call the emergency shuttle
/client/proc/admin_call_shuttle()

	set category = "Admin"
	set name = "Call Evacuation"

	if(!evacuation_controller)
		return

	if(!check_rights(R_ADMIN))
		return

	if(alert(src, "Are you sure?", "Confirm", "Yes", "No") != "Yes")
		return

	var/choice = input("Is this an emergency evacuation or a crew transfer?") in list("Emergency", "Crew Transfer")
	evacuation_controller.call_evacuation(usr, (choice == "Emergency"))

	log_admin("[key_name(usr)] admin-called the emergency shuttle.")
	message_admins(span_blue("[key_name_admin(usr)] admin-called the emergency shuttle."), 1)

//allows us to cancel the emergency shuttle, sending it back to centcom
/client/proc/admin_cancel_shuttle()
	set category = "Admin"
	set name = "Cancel Evacuation"

	if(!check_rights(R_ADMIN))
		return

	if(alert(src, "You sure?", "Confirm", "Yes", "No") != "Yes")
		return

	if(!evacuation_controller)
		return

	evacuation_controller.cancel_evacuation()

	log_admin("[key_name(usr)] admin-recalled the emergency shuttle.")
	message_admins(span_blue("[key_name_admin(usr)] admin-recalled the emergency shuttle."), 1)

/client/proc/admin_deny_shuttle()
	set category = "Admin"
	set name = "Toggle Deny Evac"

	if(!evacuation_controller)
		return

	if(!check_rights(R_ADMIN))	return

	evacuation_controller.deny = !evacuation_controller.deny

	log_admin("[key_name(src)] has [evacuation_controller.deny ? "denied" : "allowed"] the shuttle to be called.")
	message_admins("[key_name_admin(usr)] has [evacuation_controller.deny ? "denied" : "allowed"] the shuttle to be called.")

/client/proc/cmd_admin_attack_log(mob/M as mob in SSmobs.mob_list | SShumans.mob_list)
	set category = "Special Verbs"
	set name = "Attack Log"

	to_chat(usr, span_red(text("<b>Attack Log for []</b>", mob)))
	for(var/t in M.attack_log)
		to_chat(usr, t)

/client/proc/everyone_random()
	set category = "Fun"
	set name = "Make Everyone Random"
	set desc = "Make everyone have a random appearance. You can only use this before rounds!"

	if(!check_rights(R_FUN))
		return

	if(SSticker.current_state != GAME_STATE_PREGAME)
		to_chat(usr, "Nope you can't do this, the game's already started. This only works before rounds!")
		return

	if(SSticker.random_players)
		SSticker.random_players = 0
		message_admins("Admin [key_name_admin(usr)] has disabled \"Everyone is Special\" mode.", 1)
		to_chat(usr, "Disabled.")
		return


	var/notifyplayers = alert(src, "Do you want to notify the players?", "Options", "Yes", "No", "Cancel")
	if(notifyplayers == "Cancel")
		return

	log_admin("Admin [key_name(src)] has forced the players to have random appearances.")
	message_admins("Admin [key_name_admin(usr)] has forced the players to have random appearances.", 1)

	if(notifyplayers == "Yes")
		to_chat(world, span_blue("<b>Admin [usr.key] has forced the players to have completely random identities!</b>"))

	to_chat(usr, "<i>Remember: you can always disable the randomness by using the verb again, assuming the round hasn't started yet</i>.")

	SSticker.random_players = 1

/client/proc/toggle_random_events()
	set category = "Server"
	set name = "Toggle random events on/off"

	set desc = "Toggles random events such as meteors, black holes, blob (but not space dust) on/off"
	if(!check_rights(R_SERVER))
		return

	if(!config.allow_random_events)
		config.allow_random_events = 1
		to_chat(usr, "Random events enabled")
		message_admins("Admin [key_name_admin(usr)] has enabled random events.", 1)
	else
		config.allow_random_events = 0
		to_chat(usr, "Random events disabled")
		message_admins("Admin [key_name_admin(usr)] has disabled random events.", 1)
