#define AI_CHECK_WIRELESS 1
#define AI_CHECK_RADIO 2

var/list/ai_list = list()
var/list/ai_verbs_default = list(
	/mob/living/silicon/ai/proc/ai_movement_up,
	/mob/living/silicon/ai/proc/ai_movement_down,
	/mob/living/silicon/ai/proc/ai_announcement,
	/mob/living/silicon/ai/proc/ai_emergency_message,
	/mob/living/silicon/ai/proc/ai_camera_track,
	/mob/living/silicon/ai/proc/ai_camera_list,
	/mob/living/silicon/ai/proc/ai_goto_location,
	/mob/living/silicon/ai/proc/ai_remove_location,
	/mob/living/silicon/ai/proc/ai_hologram_change,
	/mob/living/silicon/ai/proc/ai_network_change,
	/mob/living/silicon/ai/proc/ai_roster,
	/mob/living/silicon/ai/proc/ai_statuschange,
	/mob/living/silicon/ai/proc/ai_store_location,
	/mob/living/silicon/ai/proc/ai_checklaws,
	/mob/living/silicon/ai/proc/control_integrated_radio,
	/mob/living/silicon/ai/proc/control_personal_drone,
	/mob/living/silicon/ai/proc/destroy_personal_drone,
	/mob/living/silicon/ai/proc/core,
	/mob/living/silicon/ai/proc/pick_icon,
	/mob/living/silicon/ai/proc/sensor_mode,
	/mob/living/silicon/ai/proc/show_laws_verb,
	/mob/living/silicon/ai/proc/toggle_acceleration,
	/mob/living/silicon/ai/proc/toggle_camera_light,
	/mob/living/silicon/ai/proc/multitool_mode,
	/mob/living/silicon/ai/proc/toggle_hologram_movement,
	/mob/living/silicon/proc/show_crew_sensors,
	/mob/living/silicon/proc/show_email,
	/mob/living/silicon/proc/show_alerts
)

//Not sure why this is necessary...
/proc/AutoUpdateAI(obj/subject)
	var/is_in_use = 0
	if (subject!=null)
		for(var/A in ai_list)
			var/mob/living/silicon/ai/M = A
			if ((M.client && M.machine == subject))
				is_in_use = 1
				subject.attack_ai(M)
	return is_in_use


/mob/living/silicon/ai
	name = "AI"
	icon = 'icons/mob/AI.dmi'
	icon_state = "ai"
	anchored = TRUE // -- TLE
	density = TRUE
	status_flags = CANSTUN|CANPARALYSE|CANPUSH
//	shouldnt_see = list()
	universal_understand = TRUE
	var/list/network = list(NETWORK_FIRST_SECTION,
							NETWORK_SECOND_SECTION,
							NETWORK_THIRD_SECTION,
							NETWORK_FOURTH_SECTION,
							NETWORK_COMMAND,
							NETWORK_ENGINE,
							NETWORK_ENGINEERING,
							NETWORK_CEV_ERIS,
							NETWORK_MINE,
							NETWORK_PRISON,
							NETWORK_MEDICAL,
							NETWORK_RESEARCH,
							NETWORK_RESEARCH_OUTPOST,
							NETWORK_SECURITY,
							NETWORK_TELECOM
							)
	var/obj/machinery/camera/camera = null
	var/list/connected_robots = list()
	var/aiRestorePowerRoutine = 0
	var/viewalerts = 0
	var/icon/holo_icon//Default is assigned when AI is created.
	var/mob/living/exosuit/controlled_mech //For controlled_mech a mech, to determine whether to relaymove or use the AI eye.
	var/obj/item/tool/multitool/aiMulti = null
	var/obj/item/device/radio/headset/heads/ai_integrated/aiRadio = null
	var/camera_light_on = 0	//Defines if the AI toggled the light on the camera it's looking through.
	var/datum/trackable/track = null
	var/last_announcement = ""
	var/control_disabled = 0
	var/datum/announcement/priority/announcement
	var/obj/machinery/ai_powersupply/psupply = null // Backwards reference to AI's powersupply object.
	var/hologram_follow = 1 //This is used for the AI eye, to determine if a holopad's hologram should follow it or not

	//NEWMALF VARIABLES
	var/malfunctioning = 0						// Master var that determines if AI is malfunctioning.
	var/datum/malf_hardware/hardware = null		// Installed piece of hardware.
	var/datum/malf_research/research = null		// Malfunction research datum.
	var/obj/machinery/power/apc/hack = null		// APC that is currently being hacked.
	var/list/hacked_apcs = null					// List of all hacked APCs
	var/APU_power = 0							// If set to 1 AI runs on APU power
	var/hacking = 0								// Set to 1 if AI is hacking APC, cyborg, other AI, or running system override.
	var/system_override = 0						// Set to 1 if system override is initiated, 2 if succeeded.
	var/hack_can_fail = 1						// If 0, all abilities have zero chance of failing.
	var/hack_fails = 0							// This increments with each failed hack, and determines the warning message text.
	var/errored = 0								// Set to 1 if runtime error occurs. Only way of this happening i can think of is admin fucking up with varedit.
	var/bombing_core = 0						// Set to 1 if core auto-destruct is activated
	var/bombing_station = 0						// Set to 1 if station nuke auto-destruct is activated
	var/override_CPUStorage = 0					// Bonus/Penalty CPU Storage. For use by admins/testers.
	var/override_CPURate = 0					// Bonus/Penalty CPU generation rate. For use by admins/testers.

	var/datum/ai_icon/selected_sprite			// The selected icon set
	var/custom_sprite 	= 0 					// Whether the selected icon is custom
	var/carded

	var/multitool_mode = 0

	var/mob/living/silicon/robot/drone/aibound/bound_drone = null
	var/drone_cooldown_time = 30 MINUTES  // Cooldown before creating a new drone
	var/time_destroyed = 0.0

	// Stored when on login and used for custom login out behaviur. Needed for proper removal of click handlers.
	var/client/old_client

	defaultHUD = "Eris"

/mob/living/silicon/ai/proc/add_ai_verbs()
	add_verb(src, ai_verbs_default)

/mob/living/silicon/ai/proc/remove_ai_verbs()
	remove_verb(src, ai_verbs_default)

/mob/living/silicon/ai/MiddleClickOn(atom/A)
	if(!control_disabled && A.AIMiddleClick(src))
		return

	if(controlled_mech) //Are we piloting a mech? Placed here so the modifiers are not overridden.
		controlled_mech.ClickOn(A, src) //Override AI normal click behavior.  , params
		return
	. = ..()

/mob/living/silicon/ai/New(loc, datum/ai_laws/L, obj/item/device/mmi/B, safety = 0)
	announcement = new()
	announcement.title = "A.I. Announcement"
	announcement.announcement_type = "A.I. Announcement"
	announcement.newscast = 1

	var/list/possibleNames = GLOB.ai_names

	var/pickedName = null
	while(!pickedName)
		pickedName = pick(GLOB.ai_names)
		for (var/mob/living/silicon/ai/A in SSmobs.mob_list)
			if (A.real_name == pickedName && possibleNames.len > 1) //fixing the theoretically possible infinite loop
				possibleNames -= pickedName
				pickedName = null

	SetName(pickedName)
	anchored = TRUE
	canmove = 0
	density = TRUE
	loc = loc

	holo_icon = getHologramIcon(icon('icons/mob/AI.dmi',"holo1"))

	if(L)
		if (istype(L, /datum/ai_laws))
			laws = L
	else
		laws = new base_law_type

	aiMulti = new(src)
	aiRadio = new(src)
	common_radio = aiRadio
	aiRadio.myAi = src
	additional_law_channels["Holopad"] = "h"

	aiCamera = new/obj/item/device/camera/siliconcam/ai_camera(src)

	if (istype(loc, /turf))
		add_ai_verbs(src)

	//Languages
	add_language(LANGUAGE_ROBOT, 1)
	add_language(LANGUAGE_COMMON, 1)
	add_language(LANGUAGE_CYRILLIC, 1)
	add_language(LANGUAGE_GERMAN, 1)
	add_language(LANGUAGE_LATIN, 1)
	add_language(LANGUAGE_NEOHONGO, 1)
	add_language(LANGUAGE_SERBIAN, 1)

	if(!safety)//Only used by AIize() to successfully spawn an AI.
		if (!B)//If there is no player/brain inside.
			empty_playable_ai_cores += new/obj/structure/AIcore/deactivated(loc)//New empty terminal.
			qdel(src)//Delete AI.
			return
		else
			if (B.brainmob.mind)
				B.brainmob.mind.transfer_to(src)

			on_mob_init()

	spawn(5)
		new /obj/machinery/ai_powersupply(src)

	hud_list[HEALTH_HUD]      = image('icons/mob/hud.dmi', src, "hudblank")
	hud_list[STATUS_HUD]      = image('icons/mob/hud.dmi', src, "hudblank")
	hud_list[LIFE_HUD] 		  = image('icons/mob/hud.dmi', src, "hudblank")
	hud_list[ID_HUD]          = image('icons/mob/hud.dmi', src, "hudblank")
	hud_list[WANTED_HUD]      = image('icons/mob/hud.dmi', src, "hudblank")
	hud_list[IMPCHEM_HUD]     = image('icons/mob/hud.dmi', src, "hudblank")
	hud_list[IMPTRACK_HUD]    = image('icons/mob/hud.dmi', src, "hudblank")
	hud_list[SPECIALROLE_HUD] = image('icons/mob/hud.dmi', src, "hudblank")

	ai_list += src

	..()

	//Stats
	//The AI gets 100 in all three knowledge stats.
	//These are only ever used to operate machinery and software
	//It doesnt get any physical stats, like robustness, since its a disembodied mind
	stats.changeStat(STAT_BIO, 100)
	stats.changeStat(STAT_MEC, 100)
	stats.changeStat(STAT_COG, 100)

	// AI bound drone related stuff
	time_destroyed = world.time - drone_cooldown_time

/mob/living/silicon/ai/proc/on_mob_init()
	to_chat(src, "<B>You are playing the spaceship's AI. The AI cannot move, but can interact with many objects while viewing them (through cameras).</B>")
	to_chat(src, "<B>To look at other parts of the ship, click on yourself to get a camera menu.</B>")
	to_chat(src, "<B>While observing through a camera, you can use most (networked) devices which you can see, such as computers, APCs, intercoms, doors, etc.</B>")
	to_chat(src, "To use something, simply click on it.")
	to_chat(src, "Use say [get_language_prefix()]b to speak to your cyborgs through binary. Use say :h to speak from an active holopad.")
	to_chat(src, "For department channels, use the following say commands:")

	var/radio_text = ""
	for(var/i = 1 to common_radio.channels.len)
		var/channel = common_radio.channels[i]
		var/key = get_radio_key_from_channel(channel)
		radio_text += "[key] - [channel]"
		if(i != common_radio.channels.len)
			radio_text += ", "

	to_chat(src, radio_text)

	if (!check_special_role(ROLE_MALFUNCTION))
		show_laws()
		to_chat(src, "<b>These laws may be changed by other players, or by you being the contractor.</b>")

	job = "AI"
	setup_icon()

/mob/living/silicon/ai/Destroy()
	ai_list -= src

	QDEL_NULL(eyeobj)
	QDEL_NULL(psupply)
	QDEL_NULL(aiMulti)
	QDEL_NULL(aiRadio)
	QDEL_NULL(aiCamera)

	return ..()

/mob/living/silicon/ai/proc/setup_icon()
	var/file = file2text("config/custom_sprites.txt")
	var/lines = splittext(file, "\n")

	for(var/line in lines)
	// split & clean up
		var/list/Entry = splittext(line, ":")
		for(var/i = 1 to Entry.len)
			Entry[i] = trim(Entry[i])

		if(Entry.len < 2)
			continue;

		if(Entry[1] == src.ckey && Entry[2] == src.real_name)
			icon = CUSTOM_ITEM_SYNTH
			custom_sprite = 1
			selected_sprite = new/datum/ai_icon("Custom", "[src.ckey]-ai", "4", "[ckey]-ai-crash", "#FFFFFF", "#FFFFFF", "#FFFFFF")
		else
			selected_sprite = default_ai_icon
	updateicon()

/mob/living/silicon/ai/pointed(atom/A as mob|obj|turf in view())
	set popup_menu = 0
	set src = usr.contents
	return 0

/mob/living/silicon/ai/SetName(pickedName as text)
	..()
	announcement.announcer = pickedName
	if(eyeobj)
		eyeobj.name = "[pickedName] (AI Eye)"
/*
	The AI Power supply is a dummy object used for powering the AI since only machinery should be using power.
	The alternative was to rewrite a bunch of AI code instead here we are.
*/
/obj/machinery/ai_powersupply
	name="Power Supply"
	active_power_usage=50000 // Station AIs use significant amounts of power. This, when combined with charged SMES should mean AI lasts for 1hr without external power.
	use_power = ACTIVE_POWER_USE
	power_channel = STATIC_EQUIP
	var/mob/living/silicon/ai/powered_ai
	invisibility = 100

/obj/machinery/ai_powersupply/New(mob/living/silicon/ai/ai)
	powered_ai = ai
	powered_ai.psupply = src
	forceMove(powered_ai.loc)
	anchored = TRUE	//keep anchored! If unachored for any reason - it can't take power with set_power_use()

	..()
	use_power(IDLE_POWER_USE) // Just incase we need to wake up the power system.

/obj/machinery/ai_powersupply/Destroy()
	. = ..()
	powered_ai = null

/obj/machinery/ai_powersupply/Process()
	if(!powered_ai || powered_ai.stat == DEAD)
		qdel(src)
		return
	if(powered_ai.psupply != src) // For some reason, the AI has different powersupply object. Delete this one, it's no longer needed.
		qdel(src)
		return
	if(powered_ai.APU_power)
		set_power_use(NO_POWER_USE)
		return
	if(!powered_ai.anchored)
		loc = powered_ai.loc
		set_power_use(NO_POWER_USE)
		use_power(50000) // Less optimalised but only called if AI is unwrenched. This prevents usage of wrenching as method to keep AI operational without power. Intellicard is for that.
	if(powered_ai.anchored)
		set_power_use(ACTIVE_POWER_USE)

/mob/living/silicon/ai/proc/ai_movement_up()
	set category = "Silicon Commands"
	set name = "Move Upwards"
	zMove(UP)

/mob/living/silicon/ai/proc/ai_movement_down()
	set category = "Silicon Commands"
	set name = "Move Downwards"
	zMove(DOWN)

/mob/living/silicon/ai/proc/pick_icon()
	set category = "Silicon Commands"
	set name = "Set AI Core Display"
	if(stat || aiRestorePowerRoutine)
		return

	if (!custom_sprite)
		var/new_sprite = input("Select an icon!", "AI", selected_sprite) as null|anything in ai_icons
		if(new_sprite) selected_sprite = new_sprite
	updateicon()

// this verb lets the ai see the stations manifest
/mob/living/silicon/ai/proc/ai_roster()
	set category = "Silicon Commands"
	set name = "Show Crew Manifest"
	show_manifest(src)

/mob/living/silicon/ai/var/message_cooldown = 0
/mob/living/silicon/ai/proc/ai_announcement()
	set category = "Silicon Commands"
	set name = "Make Spaceship Announcement"

	if(check_unable(AI_CHECK_WIRELESS | AI_CHECK_RADIO))
		return

	if(message_cooldown)
		to_chat(src, "Please allow one minute to pass between announcements.")
		return
	var/input = input(usr, "Please write a message to announce to the ship's crew.", "A.I. Announcement")
	if(!input)
		return

	if(check_unable(AI_CHECK_WIRELESS | AI_CHECK_RADIO))
		return

	announcement.Announce(input, use_text_to_speech = TRUE)
	message_cooldown = 1
	spawn(600)//One minute cooldown
		message_cooldown = 0

/mob/living/silicon/ai/var/emergency_message_cooldown = 0
/mob/living/silicon/ai/proc/ai_emergency_message()
	set category = "Silicon Commands"
	set name = "Send Emergency Message"

	if(check_unable(AI_CHECK_WIRELESS))
		return
	if(!is_relay_online())
		to_chat(usr, span_warning("No Emergency Bluespace Relay detected. Unable to transmit message."))
		return
	if(emergency_message_cooldown)
		to_chat(usr, span_warning("Arrays recycling. Please stand by."))
		return
	var/input = sanitize(input(usr, "Please choose a message to transmit to [GLOB.boss_short] via quantum entanglement.  Please be aware that this process is very expensive, and abuse will lead to... termination.  Transmission does not guarantee a response. There is a 30 second delay before you may send another message, be clear, full and concise.", "To abort, send an empty message.", ""))
	if(!input)
		return
	to_chat(usr, span_notice("No response from the remote server. Please, contact your system administrator."))
	log_say("[key_name(usr)] has made an IA [GLOB.boss_short] announcement: [input]")
	emergency_message_cooldown = 1
	spawn(300)
		emergency_message_cooldown = 0


/mob/living/silicon/ai/check_eye(mob/user as mob)
	if (!camera)
		return -1
	return 0

/mob/living/silicon/ai/restrained()
	return 0

/mob/living/silicon/ai/emp_act(severity)
	pull_to_core()  // Pull back mind to core if it is controlling a drone
	if (prob(30))
		view_core()
	..()

/mob/living/silicon/ai/Topic(href, href_list)
	if(usr != src)
		return
	if(..())
		return
	if (href_list["mach_close"])
		if (href_list["mach_close"] == "aialerts")
			viewalerts = 0
		var/t1 = text("window=[]", href_list["mach_close"])
		unset_machine()
		src << browse(null, t1)
	if (href_list["switchcamera"])
		switchCamera(locate(href_list["switchcamera"])) in GLOB.cameranet.cameras
	if (href_list["showalerts"])
		open_subsystem(/datum/nano_module/alarm_monitor/all)
	//Carn: holopad requests
	if (href_list["jumptoholopad"])
		var/obj/machinery/hologram/holopad/H = locate(href_list["jumptoholopad"])
		if(stat == CONSCIOUS)
			if(H)
				H.attack_ai(src) //may as well recycle
			else
				to_chat(src, span_notice("Unable to locate the holopad."))
	if (href_list["track"])
		var/mob/target = locate(href_list["track"]) in SSmobs.mob_list | SShumans.mob_list
		if(target && (!ishuman(target) || target.real_name == target.get_face_name()))
			ai_actual_track(target)
		else
			to_chat(src, span_red("System error. Cannot locate [href_list["trackname"]]."))
		return

	return

/mob/living/silicon/ai/reset_view(atom/A)
	if(controlled_mech)
		return ..(controlled_mech)
	if(camera)
		camera.set_light(0)
	if(istype(A,/obj/machinery/camera))
		camera = A
	..()
	if(istype(A,/obj/machinery/camera))
		if(camera_light_on)
			A.set_light(AI_CAMERA_LUMINOSITY)
		else
			A.set_light(0)


/mob/living/silicon/ai/proc/switchCamera(obj/machinery/camera/C)
	if (!C || stat == DEAD) //C.can_use())
		return 0

	if(!src.eyeobj)
		view_core()
		return
	// ok, we're alive, camera is good and in our network...
	eyeobj.setLoc(get_turf(C))
	//machine = src

	return 1

/mob/living/silicon/ai/cancel_camera()
	set category = "Silicon Commands"
	set name = "Cancel Camera View"

	//src.cameraFollow = null
	src.view_core()

//Replaces /mob/living/silicon/ai/verb/change_network() in ai.dm & camera.dm
//Adds in /mob/living/silicon/ai/proc/ai_network_change() instead
//Addition by Mord_Sith to define AI's network change ability
/mob/living/silicon/ai/proc/get_camera_network_list()
	if(check_unable())
		return

	var/list/cameralist = new()
	for (var/obj/machinery/camera/C in GLOB.cameranet.cameras)
		if(!C.can_use())
			continue
		var/list/tempnetwork = difflist(C.network,restricted_camera_networks,1)
		for(var/i in tempnetwork)
			cameralist[i] = i

	sortAssoc(cameralist)
	return cameralist

/mob/living/silicon/ai/proc/ai_network_change(network in get_camera_network_list())
	set category = "Silicon Commands"
	set name = "Jump To Network"
	unset_machine()

	if(!network)
		return

	if(!eyeobj)
		view_core()
		return

	src.network = network

	for(var/obj/machinery/camera/C in GLOB.cameranet.cameras)
		if(!C.can_use())
			continue
		if(network in C.network)
			eyeobj.setLoc(get_turf(C))
			break
	to_chat(src, span_notice("Switched to [network] camera network."))
//End of code by Mord_Sith

/mob/living/silicon/ai/proc/ai_statuschange()
	set category = "Silicon Commands"
	set name = "AI Status"

	if(check_unable(AI_CHECK_WIRELESS))
		return

	set_ai_status_displays(src)
	return

//I am the icon meister. Bow fefore me.	//>fefore
/mob/living/silicon/ai/proc/ai_hologram_change()
	set name = "Change Hologram"
	set desc = "Change the default hologram available to AI to something else."
	set category = "Silicon Commands"

	if(check_unable())
		return

	var/input
	if(alert("Would you like to select a hologram based on a crew member or switch to unique avatar?",,"Crew Member","Unique")=="Crew Member")

		var/personnel_list[] = list()

		for(var/datum/data/record/t in data_core.locked)//Look in data core locked.
			personnel_list["[t.fields["name"]]: [t.fields["rank"]]"] = t.fields["image"]//Pull names, rank, and image.

		if(personnel_list.len)
			input = input("Select a crew member:") as null|anything in personnel_list
			var/icon/character_icon = personnel_list[input]
			if(character_icon)
				qdel(holo_icon)//Clear old icon so we're not storing it in memory.
				holo_icon = getHologramIcon(icon(character_icon))
		else
			alert("No suitable records found. Aborting.")

	else
		var/icon_list[] = list(
		"default",
		"floating face",
		"carp"
		)
		input = input("Please select a hologram:") as null|anything in icon_list
		if(input)
			qdel(holo_icon)
			switch(input)
				if("default")
					holo_icon = getHologramIcon(icon('icons/mob/AI.dmi',"holo1"))
				if("floating face")
					holo_icon = getHologramIcon(icon('icons/mob/AI.dmi',"holo2"))
				if("carp")
					holo_icon = getHologramIcon(icon('icons/mob/AI.dmi',"holo4"))
	return

//Toggles the luminosity and applies it by re-entereing the camera.
/mob/living/silicon/ai/proc/toggle_camera_light()
	set name = "Toggle Camera Light"
	set desc = "Toggles the light on the camera the AI is looking through."
	set category = "Silicon Commands"

	if(check_unable())
		return

	camera_light_on = !camera_light_on
	to_chat(src, "Camera lights [camera_light_on ? "activated" : "deactivated"].")
	if(!camera_light_on)
		if(camera)
			camera.set_light(0)
			camera = null
	else
		lightNearbyCamera()



// Handled camera lighting, when toggled.
// It will get the nearest camera from the eyeobj, lighting it.

/mob/living/silicon/ai/proc/lightNearbyCamera()
	if(camera_light_on && camera_light_on < world.timeofday)
		if(src.camera)
			var/obj/machinery/camera/camera = near_range_camera(src.eyeobj)
			if(camera && src.camera != camera)
				src.camera.set_light(0)
				if(!camera.light_disabled)
					src.camera = camera
					src.camera.set_light(AI_CAMERA_LUMINOSITY)
				else
					src.camera = null
			else if(isnull(camera))
				src.camera.set_light(0)
				src.camera = null
		else
			var/obj/machinery/camera/camera = near_range_camera(src.eyeobj)
			if(camera && !camera.light_disabled)
				src.camera = camera
				src.camera.set_light(AI_CAMERA_LUMINOSITY)
		camera_light_on = world.timeofday + 1 * 20 // Update the light every 2 seconds.


/mob/living/silicon/ai/attackby(obj/item/W as obj, mob/user as mob)
	if(istype(W, /obj/item/device/aicard))
		pull_to_core()  // Pull back mind to core if it is controlling a drone
		var/obj/item/device/aicard/card = W
		card.grab_ai(src, user)

	var/tool_type = W.get_tool_type(user, list(QUALITY_BOLT_TURNING), src)
	if(tool_type == QUALITY_BOLT_TURNING)
		if(anchored)
			user.visible_message(span_notice("\The [user] starts to unbolt \the [src] from the plating..."))
			if(!do_after(user,40, src))
				user.visible_message(span_notice("\The [user] decides not to unbolt \the [src]."))
				return
			user.visible_message(span_notice("\The [user] finishes unfastening \the [src]!"))
			anchored = FALSE
			return
		else
			user.visible_message(span_notice("\The [user] starts to bolt \the [src] to the plating..."))
			if(!do_after(user,40,src))
				user.visible_message(span_notice("\The [user] decides not to bolt \the [src]."))
				return
			user.visible_message(span_notice("\The [user] finishes fastening down \the [src]!"))
			anchored = TRUE
			return
	else
		return ..()

/mob/living/silicon/ai/proc/control_integrated_radio()
	set name = "Radio Settings"
	set desc = "Allows you to change settings of your radio."
	set category = "Silicon Commands"

	if(check_unable(AI_CHECK_RADIO))
		return

	to_chat(src, "Accessing Subspace Transceiver control...")
	if (src.aiRadio)
		src.aiRadio.interact(src)

/mob/living/silicon/ai/proc/sensor_mode()
	set name = "Set Sensor Augmentation"
	set category = "Silicon Commands"
	set desc = "Augment visual feed with internal sensor overlays"
	toggle_sensor_mode()

/mob/living/silicon/ai/proc/toggle_hologram_movement()
	set name = "Toggle Hologram Movement"
	set category = "Silicon Commands"
	set desc = "Toggles hologram movement based on moving with your virtual eye."

	hologram_follow = !hologram_follow
	to_chat(usr, span_info("Your hologram will now [hologram_follow ? "follow" : "no longer follow"] you."))

/mob/living/silicon/ai/proc/check_unable(flags = 0, feedback = 1)
	if(stat == DEAD)
		if(feedback) to_chat(src, span_warning("You are dead!"))
		return 1

	if(aiRestorePowerRoutine)
		if(feedback) to_chat(src, span_warning("You lack power!"))
		return 1

	if((flags & AI_CHECK_WIRELESS) && src.control_disabled)
		if(feedback) to_chat(src, span_warning("Wireless control is disabled!"))
		return 1
	if((flags & AI_CHECK_RADIO) && src.aiRadio.disabledAi)
		if(feedback) to_chat(src, span_warning("System Error - Transceiver Disabled!"))
		return 1
	return 0

/mob/living/silicon/ai/proc/is_in_chassis()
	return istype(loc, /turf)

/mob/living/silicon/ai/explosion_act(target_power, explosion_handler/handler)
	if(target_power > maxHealth)
		qdel(src)
	else
		adjustBruteLoss(target_power)

/mob/living/silicon/ai/proc/multitool_mode()
	set name = "Toggle Multitool Mode"
	set category = "Silicon Commands"

	multitool_mode = !multitool_mode
	to_chat(src, span_notice("Multitool mode: [multitool_mode ? "E" : "Dise"]ngaged"))

/mob/living/silicon/ai/updateicon()
	if(!selected_sprite) selected_sprite = default_ai_icon

	if(stat == DEAD)
		icon_state = selected_sprite.dead_icon
		set_light(3, 1, selected_sprite.dead_light)
	else if(aiRestorePowerRoutine)
		icon_state = selected_sprite.nopower_icon
		set_light(1, 1, selected_sprite.nopower_light)
	else
		icon_state = selected_sprite.alive_icon
		set_light(1, 1, selected_sprite.alive_light)

// Pass lying down or getting up to our pet human, if we're in a rig.
/mob/living/silicon/ai/lay_down()
	set name = "Rest"
	set category = "IC"

	resting = 0
	var/obj/item/rig/rig = src.get_rig()
	if(rig)
		rig.force_rest(src)

#undef AI_CHECK_WIRELESS
#undef AI_CHECK_RADIO

// Handles all necessary power checks: Area power, inteliCard and Malf AI APU power and manual override.
//just a plug for now untill baymed arrives
/mob/living/silicon/ai/proc/has_power(respect_override = 1)
	return 1

// shortcuts for UI
/mob/living/silicon/ai/proc/take_photo()
	var/obj/item/device/camera/siliconcam/ai_camera/cam = aiCamera
	cam.take_image()

/mob/living/silicon/ai/proc/view_photos()
	var/obj/item/device/camera/siliconcam/ai_camera/cam = aiCamera
	cam.view_images()

// Control a tiny drone
/mob/living/silicon/ai/proc/control_personal_drone()
	set name = "Control Personal Drone"
	set desc = "Take control of your own AI-bound maintenance drone."
	set category = "Silicon Commands"

	if(aiRestorePowerRoutine)  // Cannot switch if lack of power
		to_chat(src, span_warning("You lack power!"))
	else
		go_into_drone()

// Destroy AI tiny drone
/mob/living/silicon/ai/proc/destroy_personal_drone()
	set name = "Destroy Personal Drone"
	set desc = "Destroy your AI-bound maintenance drone."
	set category = "Silicon Commands"

	if(aiRestorePowerRoutine)  // Cannot switch if lack of power
		to_chat(src, span_warning("You lack power!"))
	else
		destroy_drone()

/mob/living/silicon/ai/proc/pull_to_core()
	if (bound_drone?.mind)  // If drone exists and AI is inside it
		bound_drone.mind.active = 0 // We want to transfer the key manually
		bound_drone.mind.transfer_to(src) // Pull back mind to AI core
		key = bound_drone.key // Manually transfer the key to log them in

/mob/living/silicon/ai/proc/go_into_drone()
	// Switch to drone or spawn a new one
	if(!bound_drone)
		if (world.time - time_destroyed > drone_cooldown_time)
			try_drone_spawn(src, aibound = TRUE)
		else
			var/remaining = (drone_cooldown_time - (world.time - time_destroyed)) / 10
			to_chat(src, span_warning("Security routines hardcoded into your core force you to wait [remaining] seconds before creating a new AI bound drone."))
	else if(mind)
		mind.active = 0 // We want to transfer the key manually
		mind.transfer_to(bound_drone) // Transfer mind to drone
		bound_drone.laws = laws // Resync laws in case they have been changed
		bound_drone.key = key // Manually transfer the key to log them in

/mob/living/silicon/ai/proc/destroy_drone()
	if(bound_drone)
		bound_drone.death(TRUE)
	else
		to_chat(src, span_warning("You have no active AI-bound maintenance drone."))
