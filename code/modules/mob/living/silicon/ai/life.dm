/mob/living/silicon/ai/Life()
	if (stat == DEAD)
		return
	else //I'm not removing that shitton of tabs, unneeded as they are. -- Urist
		//Being dead doesn't mean your temperature never changes
		var/turf/T = get_turf(src)

		if (stat!=CONSCIOUS)
			cameraFollow = null
			reset_view(null)

		updatehealth()

		if (!hardware_integrity() || !backup_capacitor())
			death()
			return

		// If our powersupply object was destroyed somehow, create new one.
		if(!psupply)
			create_powersupply()


		// Handle power damage (oxy)
		if(aiRestorePowerRoutine != 0 && !APU_power)
			// Lose power
			adjustOxyLoss(1)
		else
			// Gain Power
			aiRestorePowerRoutine = 0 // Necessary if AI activated it's APU AFTER losing primary power.
			adjustOxyLoss(-1)

		handle_stunned()	// Handle EMP-stun
		lying = 0			// Handle lying down

		malf_process()

		if(APU_power && (hardware_integrity() < 50))
			to_chat(src, span_notice("<b>APU GENERATOR FAILURE! (System Damaged)</b>"))
			stop_apu(1)

		if (!is_blinded())
			if (aiRestorePowerRoutine==2)
				to_chat(src, "Alert cancelled. Power has been restored without our assistance.")
				aiRestorePowerRoutine = 0
//				blind.alpha = 0
				updateicon()
				return
			else if (aiRestorePowerRoutine==3)
				to_chat(src, "Alert cancelled. Power has been restored.")
				aiRestorePowerRoutine = 0
//				blind.alpha = 0
				updateicon()
				return
			else if (APU_power)
				aiRestorePowerRoutine = 0
//				blind.alpha = 0
				updateicon()
				return
		else
			var/area/current_area = get_area(src)

			if (lacks_power())
				if (aiRestorePowerRoutine==0)
					aiRestorePowerRoutine = 1

					pull_to_core()  // Pull back mind to core if it is controlling a drone

					//Now to tell the AI why they're blind and dying slowly.
					to_chat(src, "You've lost power!")

					spawn(20)
						to_chat(src, "Backup battery online. Scanners, camera, and radio interface offline. Beginning fault-detection.")
						sleep(50)
						if (current_area.power_equip)
							if (!istype(T, /turf/space))
								to_chat(src, "Alert cancelled. Power has been restored without our assistance.")
								aiRestorePowerRoutine = 0
//								blind.alpha = 0
								return
						to_chat(src, "Fault confirmed: missing external power. Shutting down main control system to save power.")
						sleep(20)
						to_chat(src, "Emergency control system online. Verifying connection to power network.")
						sleep(50)
						if (istype(T, /turf/space))
							to_chat(src, "Unable to verify! No power connection detected!")
							aiRestorePowerRoutine = 2
							return
						to_chat(src, "Connection verified. Searching for APC in power network.")
						sleep(50)
						var/obj/machinery/power/apc/theAPC = null

						var/PRP
						for (PRP=1, PRP<=4, PRP++)
							for (var/obj/machinery/power/apc/APC in current_area)
								if (!(APC.stat & BROKEN))
									theAPC = APC
									break
							if (!theAPC)
								switch(PRP)
									if (1) src << "Unable to locate APC!"
									else src << "Lost connection with the APC!"
								src:aiRestorePowerRoutine = 2
								return
							if (current_area.power_equip)
								if (!istype(T, /turf/space))
									to_chat(src, "Alert cancelled. Power has been restored without our assistance.")
									aiRestorePowerRoutine = 0
//									blind.alpha = 0 //This, too, is a fix to issue 603
									return
							switch(PRP)
								if (1) src << "APC located. Optimizing route to APC to avoid needless power waste."
								if (2) src << "Best route identified. Hacking offline APC power port."
								if (3) src << "Power port upload access confirmed. Loading control program into APC power port software."
								if (4)
									to_chat(src, "Transfer complete. Forcing APC to execute program.")
									sleep(50)
									to_chat(src, "Receiving control information from APC.")
									sleep(2)
									theAPC.operating = 1
									theAPC.equipment = 3
									theAPC.update()
									aiRestorePowerRoutine = 3
									to_chat(src, "Here are your current laws:")
									show_laws()
									updateicon()
							sleep(50)
							theAPC = null

	process_queued_alarms()
	handle_regular_hud_updates()
	switch(sensor_mode)
		if (SEC_HUD)
			process_sec_hud(src,0,eyeobj)
		if (MED_HUD)
			process_med_hud(src,0,eyeobj)

/mob/living/silicon/ai/proc/lacks_power()
	if(APU_power)
		return 0
	var/turf/T = get_turf(src)
	var/area/A = get_area(src)
	return ((!A.power_equip) && A.requires_power == 1 || istype(T, /turf/space)) && !istype(loc,/obj/item)

/mob/living/silicon/ai/updatehealth()
	if(status_flags & GODMODE)
		health = 100
		stat = CONSCIOUS
		setOxyLoss(0)
	else
		health = 100 - getFireLoss() - getBruteLoss() // Oxyloss is not part of health as it represents AIs backup power. AI is immune against ToxLoss as it is machine.

/mob/living/silicon/ai/rejuvenate()
	..()
	add_ai_verbs(src)

/mob/living/silicon/ai/update_sight()
	if(is_blinded())
		updateicon()
//		blind.screen_loc = ui_entire_screen
//		if (blind.alpha!=255)
//			blind.alpha = 255
		sight = sight&~SEE_TURFS
		sight = sight&~SEE_MOBS
		sight = sight&~SEE_OBJS
		see_in_dark = 0
		see_invisible = SEE_INVISIBLE_LIVING
	else
		update_dead_sight()

/mob/living/silicon/ai/proc/is_blinded()
	var/area/A = get_area(src)
	if (A && !A.power_equip && !istype(loc,/obj/item) && !APU_power)
		return 1
	return 0
