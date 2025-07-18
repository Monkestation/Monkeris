/obj/item/device/eftpos
	name = "\improper EFTPOS scanner"
	desc = "Swipe your ID card to make purchases electronically."
	icon = 'icons/obj/device.dmi'
	icon_state = "eftpos"
	w_class = ITEM_SIZE_SMALL
	var/machine_id = ""
	var/eftpos_name = "Default EFTPOS scanner"
	var/transaction_locked = 0
	var/transaction_paid = 0
	var/transaction_amount = 0
	var/transaction_purpose = "Default charge"
	var/access_code = 0
	var/datum/money_account/linked_account

/obj/item/device/eftpos/New()
	..()
	machine_id = "[station_name()] EFTPOS #[num_financial_terminals++]"
	access_code = rand(1111,111111)
	spawn(0)
		print_reference()

		//create a short manual as well
		var/obj/item/paper/R = new(src.loc)
		R.name = "Steps to success: Correct EFTPOS Usage"
		/*
		R.info += "<b>When first setting up your EFTPOS device:</b>"
		R.info += "1. Memorise your EFTPOS command code (provided with all EFTPOS devices).<br>"
		R.info += "2. Confirm that your EFTPOS device is connected to your local accounts database. For additional assistance with this step, contact NanoTrasen IT Support<br>"
		R.info += "3. Confirm that your EFTPOS device has been linked to the account that you wish to recieve funds for all transactions processed on this device.<br>"
		R.info += "<b>When starting a new transaction with your EFTPOS device:</b>"
		R.info += "1. Ensure the device is UNLOCKED so that new data may be entered.<br>"
		R.info += "2. Enter a sum of money and reference message for the new transaction.<br>"
		R.info += "3. Lock the transaction, it is now ready for your customer.<br>"
		R.info += "4. If at this stage you wish to modify or cancel your transaction, you may simply reset (unlock) your EFTPOS device.<br>"
		R.info += "5. Give your EFTPOS device to the customer, they must authenticate the transaction by swiping their ID card and entering their PIN number.<br>"
		R.info += "6. If done correctly, the transaction will be logged to both accounts with the reference you have entered, the terminal ID of your EFTPOS device and the money transferred across accounts.<br>"
		*/
		//Temptative new manual:
		R.info += "<b>First EFTPOS setup:</b><br>"
		R.info += "1. Memorise your EFTPOS command code (provided with all EFTPOS devices).<br>"
		R.info += "2. Connect the EFTPOS to the account in which you want to receive the funds.<br><br>"
		R.info += "<b>When starting a new transaction:</b><br>"
		R.info += "1. Enter the amount of money you want to charge and a purpose message for the new transaction.<br>"
		R.info += "2. Lock the new transaction. If you want to modify or cancel the transaction, you simply have to reset your EFTPOS device.<br>"
		R.info += "3. Give the EFTPOS device to your customer, he/she must finish the transaction by swiping their ID card or a charge card with enough funds.<br>"
		R.info += "4. If everything is done correctly, the money will be transferred. To unlock the device you will have to reset the EFTPOS device.<br>"


		//stamp the paper
		var/image/stampoverlay = image('icons/obj/bureaucracy.dmi')
		stampoverlay.icon_state = "paper_stamp-cent"
		if(!R.stamped)
			R.stamped = new
		R.offset_x += 0
		R.offset_y += 0
		R.ico += "paper_stamp-cent"
		R.stamped += /obj/item/stamp
		R.overlays += stampoverlay
		R.stamps += "<HR><i>This paper has been stamped by the EFTPOS device.</i>"

	//by default, connect to the station account
	//the user of the EFTPOS device can change the target account though, and no-one will be the wiser (except whoever's being charged)
	linked_account = station_account

/obj/item/device/eftpos/proc/print_reference()
	var/obj/item/paper/R = new(src.loc)
	R.name = "Reference: [eftpos_name]"
	R.info = "<b>[eftpos_name] reference</b><br><br>"
	R.info += "Access code: [access_code]<br><br>"
	R.info += "<b>Do not lose or misplace this code.</b><br>"

	//stamp the paper
	var/image/stampoverlay = image('icons/obj/bureaucracy.dmi')
	stampoverlay.icon_state = "paper_stamp-cent"
	if(!R.stamped)
		R.stamped = new
	R.stamped += /obj/item/stamp
	R.overlays += stampoverlay
	R.stamps += "<HR><i>This paper has been stamped by the EFTPOS device.</i>"
	var/obj/item/smallDelivery/D = new(R.loc)
	R.loc = D
	D.wrapped = R
	D.name = "small parcel - 'EFTPOS access code'"

/obj/item/device/eftpos/attack_self(mob/user as mob)
	if(get_dist(src,user) <= 1)
		var/dat = "<b>[eftpos_name]</b><br>"
		dat += "<i>This terminal is</i> [machine_id]. <i>Report this code when contacting IT Support</i><br>"
		if(transaction_locked)
			dat += "<a href='byond://?src=\ref[src];choice=toggle_lock'>Back[transaction_paid ? "" : " (authentication required)"]</a><br><br>"

			dat += "Transaction purpose: <b>[transaction_purpose]</b><br>"
			dat += "Value: <b>[transaction_amount][CREDS]</b><br>"
			dat += "Linked account: <b>[linked_account ? linked_account.owner_name : "None"]</b><hr>"
			if(transaction_paid)
				dat += "<i>This transaction has been processed successfully.</i><hr>"
			else
				dat += "<i>Swipe your card below the line to finish this transaction.</i><hr>"
				dat += "<a href='byond://?src=\ref[src];choice=scan_card'>\[------\]</a>"
		else
			dat += "<a href='byond://?src=\ref[src];choice=toggle_lock'>Lock in new transaction</a><br><br>"

			dat += "<a href='byond://?src=\ref[src];choice=trans_purpose'>Transaction purpose: [transaction_purpose]</a><br>"
			dat += "Value: <a href='byond://?src=\ref[src];choice=trans_value'>[transaction_amount][CREDS]</a><br>"
			dat += "Linked account: <a href='byond://?src=\ref[src];choice=link_account'>[linked_account ? linked_account.owner_name : "None"]</a><hr>"
			dat += "<a href='byond://?src=\ref[src];choice=change_code'>Change access code</a><br>"
			dat += "<a href='byond://?src=\ref[src];choice=change_id'>Change EFTPOS ID</a><br>"
			dat += "Scan card to reset access code <a href='byond://?src=\ref[src];choice=reset'>\[------\]</a>"
		user << browse(HTML_SKELETON_TITLE("EFTPOS scanner",dat),"window=eftpos")
	else
		user << browse(null,"window=eftpos")

/obj/item/device/eftpos/attackby(obj/item/O as obj, user as mob)

	var/obj/item/card/id/I = O.GetIdCard()

	if(I)
		if(linked_account)
			scan_card(I, O)
		else
			to_chat(usr, "[icon2html(src, usr)][span_warning("Unable to connect to linked account.")]")
	else if (istype(O, /obj/item/spacecash/ewallet))
		var/obj/item/spacecash/ewallet/E = O
		if (linked_account)
			if(linked_account.is_valid())
				if(transaction_locked && !transaction_paid)
					if(transaction_amount <= E.worth)
						playsound(src, 'sound/machines/chime.ogg', 50, 1)
						src.visible_message("[icon2html(src, hearers(get_turf(src)))] \The [src] chimes.")
						transaction_paid = 1

						//transfer the money
						E.worth -= transaction_amount

						//create entry in the EFTPOS linked account transaction log
						var/datum/transaction/T = new(transaction_amount, E.owner_name, transaction_purpose ? transaction_purpose : "None supplied.", machine_id)
						T.apply_to(linked_account)
					else
						to_chat(usr, "[icon2html(src, usr)][span_warning("\The [O] doesn't have that much money!")]")
			else
				to_chat(usr, "[icon2html(src, usr)][span_warning("Connected account has been suspended.")]")
		else
			to_chat(usr, "[icon2html(src, usr)][span_warning("EFTPOS is not connected to an account.")]")

	else
		..()

/obj/item/device/eftpos/Topic(href, href_list)
	if(href_list["choice"])
		switch(href_list["choice"])
			if("change_code")
				var/attempt_code = input("Re-enter the current EFTPOS access code", "Confirm old EFTPOS code") as num
				if(attempt_code == access_code)
					var/trycode = input("Enter a new access code for this device (4-6 digits, numbers only)", "Enter new EFTPOS code") as num
					if(trycode >= 1000 && trycode <= 999999)
						access_code = trycode
					else
						alert("That is not a valid code!")
					print_reference()
				else
					to_chat(usr, "[icon2html(src, usr)][span_warning("Incorrect code entered.")]")
			if("change_id")
				var/attempt_code = text2num(input("Re-enter the current EFTPOS access code", "Confirm EFTPOS code"))
				if(attempt_code == access_code)
					eftpos_name = sanitize(input("Enter a new terminal ID for this device", "Enter new EFTPOS ID"), MAX_NAME_LEN) + " EFTPOS scanner"
					print_reference()
				else
					to_chat(usr, "[icon2html(src, usr)][span_warning("Incorrect code entered.")]")
			if("link_account")
				var/attempt_account_num = input("Enter account number to pay EFTPOS charges into", "New account number") as num
				var/attempt_pin = input("Enter pin code", "Account pin") as num
				linked_account = attempt_account_access(attempt_account_num, attempt_pin, 1)
				if(linked_account)
					if(!linked_account.is_valid())
						linked_account = null
						to_chat(usr, "[icon2html(src, usr)][span_warning("Account has been suspended.")]")
				else
					to_chat(usr, "[icon2html(src, usr)][span_warning("Account not found.")]")
			if("trans_purpose")
				var/choice = sanitize(input("Enter reason for EFTPOS transaction", "Transaction purpose"))
				if(choice) transaction_purpose = choice
			if("trans_value")
				var/try_num = input("Enter amount for EFTPOS transaction", "Transaction amount") as num
				if(try_num < 0)
					alert("That is not a valid amount!")
				else
					transaction_amount = try_num
			if("toggle_lock")
				if(transaction_locked)
					if (transaction_paid)
						transaction_locked = 0
						transaction_paid = 0
					else
						var/attempt_code = input("Enter EFTPOS access code", "Reset Transaction") as num
						if(attempt_code == access_code)
							transaction_locked = 0
							transaction_paid = 0
				else if(linked_account)
					transaction_locked = 1
				else
					to_chat(usr, "[icon2html(src, usr)][span_warning("No account connected to send transactions to.")]")
			if("scan_card")
				if(linked_account)
					var/obj/item/I = usr.get_active_held_item()
					if (istype(I, /obj/item/card))
						scan_card(I)
				else
					to_chat(usr, "[icon2html(src, usr)][span_warning("Unable to link accounts.")]")
			if("reset")
				//reset the access code - requires HoP/captain access
				var/obj/item/I = usr.get_active_held_item()
				if (istype(I, /obj/item/card))
					var/obj/item/card/id/C = I
					if(access_cent_captain in C.access || (access_hop in C.access) || (access_captain in C.access))
						access_code = 0
						to_chat(usr, "[icon2html(src, usr)][span_info("Access code reset to 0.")]")
				else if (istype(I, /obj/item/card/emag))
					access_code = 0
					to_chat(usr, "[icon2html(src, usr)][span_info("Access code reset to 0.")]")

	src.attack_self(usr)

/obj/item/device/eftpos/proc/scan_card(obj/item/card/I, obj/item/ID_container)
	if (!istype(I, /obj/item/card/id))
		return

	var/obj/item/card/id/C = I

	if(I==ID_container || ID_container == null)
		usr.visible_message(span_info("\The [usr] swipes a card through \the [src]."))
	else
		usr.visible_message(span_info("\The [usr] swipes \the [ID_container] through \the [src]."))

	if(transaction_locked && !transaction_paid)
		if(!linked_account)
			to_chat(usr, "[icon2html(src, usr)][span_warning("EFTPOS is not connected to an account.")]")
			return

		if(!linked_account.is_valid())
			to_chat(usr, "[icon2html(src, usr)][span_warning("Connected account has been suspended.")]")
			return

		var/attempt_pin = ""
		var/datum/money_account/D = get_account(C.associated_account_number)
		if(D.security_level)
			attempt_pin = input("Enter pin code", "EFTPOS transaction") as num
			D = null
		D = attempt_account_access(C.associated_account_number, attempt_pin, 2)

		if(!D)
			to_chat(usr, "[icon2html(src, usr)][span_warning("Unable to access account. Check security settings and try again.")]")
			return

		if(!D.is_valid())
			to_chat(usr, "[icon2html(src, usr)][span_warning("Your account has been suspended.")]")
			return

		if(!(transaction_amount <= D.money))
			to_chat(usr, "[icon2html(src, usr)][span_warning("You don't have that much money!")]")
			return
		playsound(src, 'sound/machines/chime.ogg', 50, 1)
		src.visible_message("[icon2html(src, hearers(get_turf(src)))] \The [src] chimes.")
		transaction_paid = 1

		//transfer the money
		//create entries in the two account transaction logs
		var/datum/transaction/T = new(-transaction_amount, "[linked_account.owner_name] (via [eftpos_name])", transaction_purpose, machine_id)
		T.apply_to(D)
		//
		T = new(
			transaction_amount, D.owner_name,
			transaction_purpose, machine_id
		)
		T.apply_to(linked_account)

//emag?
/obj/item/device/eftpos/emag_act(remaining_charges, mob/user, emag_source)
	if (!transaction_locked)
		return
	if(transaction_paid)
		to_chat(usr, "[icon2html(src, usr)][span_info("You stealthily swipe \the [emag_source] through \the [src].")]")
		transaction_locked = 0
		transaction_paid = 0
	else
		usr.visible_message(span_info("\The [usr] swipes a card through \the [src]."))
		playsound(src, 'sound/machines/chime.ogg', 50, 1)
		src.visible_message("[icon2html(src, hearers(get_turf(src)))] \The [src] chimes.")
		transaction_paid = 1
