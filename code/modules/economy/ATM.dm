/*

TODO:
give money an actual use (QM stuff, vending machines)
send money to people (might be worth attaching money to custom database thing for this, instead of being in the ID)
log transactions

*/

#define NO_SCREEN 0
#define CHANGE_SECURITY_LEVEL 1
#define TRANSFER_FUNDS 2
#define VIEW_TRANSACTION_LOGS 3

/obj/machinery/atm
	name = "Automatic Teller Machine"
	desc = "For all your monetary needs!"
	icon = 'icons/obj/terminals.dmi'
	icon_state = "atm"
	anchored = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 10
	var/datum/money_account/authenticated_account
	var/number_incorrect_tries = 0
	var/previous_account_number = 0
	var/max_pin_attempts = 3
	var/ticks_left_locked_down = 0
	var/ticks_left_timeout = 0
	var/machine_id = ""
	var/obj/item/card/id/held_card
	var/editing_security_level = 0
	var/view_screen = NO_SCREEN
	var/datum/effect/effect/system/spark_spread/spark_system
	var/updateflag = 0

/obj/machinery/atm/Initialize()
	. = ..()
	machine_id = "[station_name()] RT #[num_financial_terminals++]"
	spark_system = new /datum/effect/effect/system/spark_spread
	spark_system.set_up(5, 0, src)
	spark_system.attach(src)

/obj/machinery/atm/Process()
	if(stat & NOPOWER)
		update_icon()
		return

	if(ticks_left_timeout > 0)
		ticks_left_timeout--
		if(ticks_left_timeout <= 0)
			authenticated_account = null
	if(ticks_left_locked_down > 0)
		ticks_left_locked_down--
		if(ticks_left_locked_down <= 0)
			number_incorrect_tries = 0

	for(var/obj/item/spacecash/S in src)
		S.forceMove(get_turf(src))
		playsound(loc, pick('sound/items/polaroid1.ogg','sound/items/polaroid2.ogg'), 50, 1)
		break
	update_icon()

/obj/machinery/atm/power_change()
	..()
	if (held_card && !powered(0))
		held_card.loc = src.loc
		authenticated_account = null
		held_card = null
	update_icon()

/obj/machinery/atm/update_icon()
	if(stat & NOPOWER)
		icon_state = "atm_off"
		return
	else if (held_card)
		icon_state = "atm_cardin"
	else
		icon_state = "atm"

/obj/machinery/atm/emag_act(remaining_charges, mob/user)
	if(!emagged)
		return

	//short out the machine, shoot sparks, spew money!
	emagged = 1
	spark_system.start()
	spawn_money(rand(100,500),src.loc)
	//we don't want to grief people by locking their id in an emagged ATM
	release_held_id(user)

	//display a message to the user
	var/response = pick("Initiating withdraw. Have a nice day!", "CRITICAL ERROR: Activating cash chamber panic siphon.","PIN Code accepted! Emptying account balance.", "Jackpot!")
	to_chat(user, span_warning("[icon2html(src, user)] The [src] beeps: \"[response]\""))
	return 1

/obj/machinery/atm/attackby(obj/item/I as obj, mob/user as mob)
	if(istype(I, /obj/item/card))
		if(stat & NOPOWER)
			return
		if(emagged)
			//prevent inserting id into an emagged ATM
			to_chat(user, span_red("[icon2html(src, user)] CARD READER ERROR. This system has been compromised!"))
			return
		else if(istype(I,/obj/item/card/emag))
			I.resolve_attackby(src, user)
			return

		var/obj/item/card/id/idcard = I
		if(!held_card)
			usr.unEquip(I)
			I.forceMove(src)
			playsound(usr.loc, 'sound/machines/id_swipe.ogg', 100, 1)
			held_card = idcard
			if(authenticated_account && held_card.associated_account_number != authenticated_account.account_number)
				authenticated_account = null
		update_icon()
	else if(authenticated_account)
		if(stat & NOPOWER)
			return
		if(istype(I,/obj/item/spacecash))
			var/obj/item/spacecash/cash = I
			//consume the money
			playsound(loc, pick('sound/items/polaroid1.ogg','sound/items/polaroid2.ogg'), 50, 1)

			//create a transaction log entry
			var/datum/transaction/T = new(cash.worth, authenticated_account.owner_name, "Credit deposit", machine_id)
			T.apply_to(authenticated_account)

			to_chat(user, span_info("You insert [I] into [src]."))
			src.attack_hand(user)
			qdel(I)
	else
		..()

/obj/machinery/atm/attack_hand(mob/user)
	if(issilicon(user))
		to_chat(user, span_red("[icon2html(src, user)] Artificial unit recognized. Artificial units do not currently receive monetary compensation, as per system banking regulation #1005."))
		return
	if (..())
		return
	if(get_dist(src,user) <= 1)

		//js replicated from obj/machinery/computer/card
		var/dat = "<h1>Automatic Teller Machine</h1>"
		dat += "For all your monetary needs!<br>"
		dat += "<i>This terminal is</i> [machine_id]. <i>Report this code when contacting IT Support</i><br/>"

		if(emagged > 0)
			dat += "Card: <span style='color: red;'>LOCKED</span><br><br><span style='color: red;'>Unauthorized terminal access detected! This ATM has been locked. Please contact IT Support.</span>"
		else
			dat += "Card: <a href='byond://?src=\ref[src];choice=insert_card'>[held_card ? held_card.name : "------"]</a><br><br>"

			if(ticks_left_locked_down > 0)
				dat += span_alert("Maximum number of pin attempts exceeded! Access to this ATM has been temporarily disabled.")
			else if(authenticated_account)
				if(authenticated_account.suspended)
					dat += span_red(span_bold("Access to this account has been suspended, and the funds within frozen."))
				else
					switch(view_screen)
						if(CHANGE_SECURITY_LEVEL)
							dat += "Select a new security level for this account:<br><hr>"
							var/text = "Zero - Either the account number and pin, or card and pin are required to access this account. "
							text += "Vending machine transactions will only require a card. EFTPOS transactions will require a card and ask for a pin, but not verify the pin is correct."

							if(authenticated_account.security_level != 0)
								text = "<A href='byond://?src=\ref[src];choice=change_security_level;new_security_level=0'>[text]</a>"
							dat += "[text]<hr>"
							text = "One - An account number and pin must be manually entered to access this account and process transactions. Vending machine transactions will require card and pin."
							if(authenticated_account.security_level != 1)
								text = "<A href='byond://?src=\ref[src];choice=change_security_level;new_security_level=1'>[text]</a>"
							dat += "[text]<hr>"
							text = "Two - In addition to account number and pin, a card is required to access this account and process transactions."
							if(authenticated_account.security_level != 2)
								text = "<A href='byond://?src=\ref[src];choice=change_security_level;new_security_level=2'>[text]</a>"
							dat += "[text]<hr><br>"
							dat += "<A href='byond://?src=\ref[src];choice=view_screen;view_screen=0'>Back</a>"
						if(VIEW_TRANSACTION_LOGS)
							dat += "<b>Transaction logs</b><br>"
							dat += "<A href='byond://?src=\ref[src];choice=view_screen;view_screen=0'>Back</a>"
							dat += "<table border=1 style='width:100%'>"
							dat += "<tr>"
							dat += "<td><b>Date</b></td>"
							dat += "<td><b>Time</b></td>"
							dat += "<td><b>Target</b></td>"
							dat += "<td><b>Purpose</b></td>"
							dat += "<td><b>Value</b></td>"
							dat += "<td><b>Source terminal ID</b></td>"
							dat += "</tr>"
							for(var/datum/transaction/T in authenticated_account.transaction_log)
								dat += "<tr>"
								dat += "<td>[T.date]</td>"
								dat += "<td>[T.time]</td>"
								dat += "<td>[T.target_name]</td>"
								dat += "<td>[T.purpose]</td>"
								dat += "<td>[num2text(T.amount,12)][CREDS]</td>"
								dat += "<td>[T.source_terminal]</td>"
								dat += "</tr>"
							dat += "</table>"
							dat += "<A href='byond://?src=\ref[src];choice=print_transaction'>Print</a><br>"
						if(TRANSFER_FUNDS)
							dat += "<b>Account balance:</b> [num2text(authenticated_account.money,12)][CREDS]<br>"
							dat += "<A href='byond://?src=\ref[src];choice=view_screen;view_screen=0'>Back</a><br><br>"
							dat += "<form name='transfer' action='?src=\ref[src]' method='get'>"
							dat += "<input type='hidden' name='src' value='\ref[src]'>"
							dat += "<input type='hidden' name='choice' value='transfer'>"
							dat += "Target account number: <input type='text' name='target_acc_number' value='' style='width:200px; background-color:white;'><br>"
							dat += "Funds to transfer: <input type='text' name='funds_amount' value='' style='width:200px; background-color:white;'><br>"
							dat += "Transaction purpose: <input type='text' name='purpose' value='Funds transfer' style='width:200px; background-color:white;'><br>"
							dat += "<input type='submit' value='Transfer funds'><br>"
							dat += "</form>"
						else
							dat += "Welcome, <b>[authenticated_account.owner_name].</b><br/>"
							dat += "<b>Account balance:</b> [num2text(authenticated_account.money, 12)][CREDS]"
							dat += "<form name='withdrawal' action='?src=\ref[src]' method='get'>"
							dat += "<input type='hidden' name='src' value='\ref[src]'>"
							dat += "<input type='radio' name='choice' value='withdrawal' checked> Cash  <input type='radio' name='choice' value='e_withdrawal'> Chargecard<br>"
							dat += "<input type='text' name='funds_amount' value='' style='width:200px; background-color:white;'><input type='submit' value='Withdraw'>"
							dat += "</form>"
							dat += "<A href='byond://?src=\ref[src];choice=view_screen;view_screen=1'>Change account security level</a><br>"
							dat += "<A href='byond://?src=\ref[src];choice=view_screen;view_screen=2'>Make transfer</a><br>"
							dat += "<A href='byond://?src=\ref[src];choice=view_screen;view_screen=3'>View transaction log</a><br>"
							dat += "<A href='byond://?src=\ref[src];choice=balance_statement'>Print balance statement</a><br>"
							dat += "<A href='byond://?src=\ref[src];choice=logout'>Logout</a><br>"
			else
				dat += "<form name='atm_auth' action='?src=\ref[src]' method='get'>"
				dat += "<input type='hidden' name='src' value='\ref[src]'>"
				dat += "<input type='hidden' name='choice' value='attempt_auth'>"
				dat += "<b>Account:</b> "


				if(held_card && held_card.associated_account_number)
					dat += "<input type='text' id='account_num' name='account_num' style='width:250px; background-color:white;' readonly=1 value='[held_card.associated_account_number]'>"
				else
					dat += "<input type='text' id='account_num' name='account_num' style='width:250px; background-color:white;'>"

				dat += "<br><b>PIN:</b> <input type='text' id='account_pin' name='account_pin' style='width:250px; background-color:white;'><br>"
				dat += "<input type='submit' value='Submit'><br>"
				dat += "</form>"

		user << browse(HTML_SKELETON_TITLE("ATM", dat),"window=atm;size=600x650")
	else
		user << browse(null,"window=atm")

/obj/machinery/atm/Topic(href, href_list)
	if (..())
		return
	if(href_list["choice"])
		switch(href_list["choice"])
			if("transfer")
				if(authenticated_account)
					var/transfer_amount = text2num(href_list["funds_amount"])
					transfer_amount = round(transfer_amount, 0.01)
					if(transfer_amount <= 0)
						alert("That is not a valid amount.")
					else if(transfer_amount <= authenticated_account.money)
						var/target_account_number = text2num(href_list["target_acc_number"])
						var/transfer_purpose = href_list["purpose"]
						if(transfer_funds(authenticated_account.account_number, target_account_number, transfer_purpose, machine_id, transfer_amount))
							to_chat(usr, "[icon2html(src, usr)][span_info("Funds transfer successful.")]")
						else
							to_chat(usr, "[icon2html(src, usr)][span_warning("Funds transfer failed.")]")

					else
						to_chat(usr, span_warning("You don't have enough funds to do that!"))
			if("view_screen")
				view_screen = text2num(href_list["view_screen"])
			if("change_security_level")
				if(authenticated_account)
					var/new_sec_level = max( min(text2num(href_list["new_security_level"]), 2), 0)
					authenticated_account.security_level = new_sec_level
			if("attempt_auth")
				if(!ticks_left_locked_down)
					var/tried_account_num = text2num(href_list["account_num"])
					var/tried_pin = text2num(href_list["account_pin"])

					var/card_match_check = held_card && held_card.associated_account_number == tried_account_num ? 2 : 1

					authenticated_account = attempt_account_access(tried_account_num, tried_pin, card_match_check, force_security = TRUE)
					if(!authenticated_account)
						number_incorrect_tries++
						if(previous_account_number == tried_account_num)
							if(number_incorrect_tries > max_pin_attempts)
								//lock down the atm
								ticks_left_locked_down = 30
								playsound(src, 'sound/machines/buzz-two.ogg', 50, 1)

								//create an entry in the account transaction log
								var/datum/money_account/failed_account = get_account(tried_account_num)
								if(failed_account)
									//Just crazy
									var/datum/transaction/T = new(0, failed_account.owner_name, "Unauthorised login attempt", machine_id)
									T.apply_to(failed_account)
							else
								to_chat(usr, span_red("[icon2html(src, usr)] Incorrect pin/account combination entered, [max_pin_attempts - number_incorrect_tries] attempts remaining."))
								previous_account_number = tried_account_num
								playsound(src, 'sound/machines/buzz-sigh.ogg', 50, 1)
						else
							to_chat(usr, span_red("[icon2html(src, usr)] incorrect pin/account combination entered."))
							number_incorrect_tries = 0
					else
						playsound(src, 'sound/machines/twobeep.ogg', 50, 1)
						ticks_left_timeout = 120
						view_screen = NO_SCREEN

						//create a transaction log entry
						var/datum/transaction/T = new(0, authenticated_account.owner_name, "Remote terminal access", machine_id)
						T.apply_to(authenticated_account)

						to_chat(usr, span_notice("Access granted. Welcome, '[authenticated_account.owner_name].'"))

					previous_account_number = tried_account_num
			if("e_withdrawal")
				var/amount = max(text2num(href_list["funds_amount"]),0)
				amount = round(amount, 0.01)
				if(amount <= 0)
					alert("That is not a valid amount.")
				else if(authenticated_account && amount > 0)
					if(amount <= authenticated_account.money)
						playsound(src, 'sound/machines/chime.ogg', 50, 1)


						//remove the money
						//create an entry in the account transaction log
						var/datum/transaction/T = new(-amount, authenticated_account.owner_name, "Credit withdrawal", machine_id)
						if(T.apply_to(authenticated_account))
							//	spawn_money(amount,src.loc)
							spawn_ewallet(amount,src.loc,usr)
					else
						to_chat(usr, span_warning("You don't have enough funds to do that!"))
			if("withdrawal")
				var/amount = max(text2num(href_list["funds_amount"]),0)
				amount = round(amount, 0.01)
				if(amount <= 0)
					alert("That is not a valid amount.")
				else if(authenticated_account && amount > 0)
					if(amount <= authenticated_account.money)
						playsound(src, 'sound/machines/chime.ogg', 50, 1)

						//create an entry in the account transaction log
						var/datum/transaction/T = new(-amount, authenticated_account.owner_name, "Credit withdrawal", machine_id)
						if(T.apply_to(authenticated_account))
							//remove the money
							spawn_money(amount,src.loc,usr)

					else
						to_chat(usr, span_warning("You don't have enough funds to do that!"))
			if("balance_statement")
				if(authenticated_account)
					var/obj/item/paper/R = new(src.loc)
					R.name = "Account balance: [authenticated_account.owner_name]"
					R.info = "<b>Automated Teller Account Statement</b><br><br>"
					R.info += "<i>Account holder:</i> [authenticated_account.owner_name]<br>"
					R.info += "<i>Account number:</i> [authenticated_account.account_number]<br>"
					R.info += "<i>Balance:</i> [authenticated_account.money][CREDS]<br>"
					R.info += "<i>Date and time:</i> [stationtime2text()], [current_date_string]<br><br>"
					R.info += "<i>Service terminal ID:</i> [machine_id]<br>"

					//stamp the paper
					var/image/stampoverlay = image('icons/obj/bureaucracy.dmi')
					stampoverlay.icon_state = "paper_stamp-cent"
					if(!R.stamped)
						R.stamped = new
					R.stamped += /obj/item/stamp
					R.overlays += stampoverlay
					R.stamps += "<HR><i>This paper has been stamped by the Automatic Teller Machine.</i>"

				playsound(loc, pick('sound/items/polaroid1.ogg','sound/items/polaroid2.ogg'), 50, 1)
			if ("print_transaction")
				if(authenticated_account)
					var/obj/item/paper/R = new(src.loc)
					R.name = "Transaction logs: [authenticated_account.owner_name]"
					R.info = "<b>Transaction logs</b><br>"
					R.info += "<i>Account holder:</i> [authenticated_account.owner_name]<br>"
					R.info += "<i>Account number:</i> [authenticated_account.account_number]<br>"
					R.info += "<i>Date and time:</i> [stationtime2text()], [current_date_string]<br><br>"
					R.info += "<i>Service terminal ID:</i> [machine_id]<br>"
					R.info += "<table border=1 style='width:100%'>"
					R.info += "<tr>"
					R.info += "<td><b>Date</b></td>"
					R.info += "<td><b>Time</b></td>"
					R.info += "<td><b>Target</b></td>"
					R.info += "<td><b>Purpose</b></td>"
					R.info += "<td><b>Value</b></td>"
					R.info += "<td><b>Source terminal ID</b></td>"
					R.info += "</tr>"
					for(var/datum/transaction/T in authenticated_account.transaction_log)
						R.info += "<tr>"
						R.info += "<td>[T.date]</td>"
						R.info += "<td>[T.time]</td>"
						R.info += "<td>[T.target_name]</td>"
						R.info += "<td>[T.purpose]</td>"
						R.info += "<td>[T.amount][CREDS]</td>"
						R.info += "<td>[T.source_terminal]</td>"
						R.info += "</tr>"
					R.info += "</table>"

					//stamp the paper
					var/image/stampoverlay = image('icons/obj/bureaucracy.dmi')
					stampoverlay.icon_state = "paper_stamp-cent"
					if(!R.stamped)
						R.stamped = new
					R.stamped += /obj/item/stamp
					R.overlays += stampoverlay
					R.stamps += "<HR><i>This paper has been stamped by the Automatic Teller Machine.</i>"

				playsound(loc, pick('sound/items/polaroid1.ogg','sound/items/polaroid2.ogg'), 50, 1)

			if("insert_card")
				if(!held_card)
					//this might happen if the user had the browser window open when somebody emagged it
					if(emagged > 0)
						to_chat(usr, span_red("[icon2html(src, usr)] The ATM card reader rejected your ID because this machine has been sabotaged!"))
					else
						var/obj/item/I = usr.get_active_held_item()
						if (istype(I, /obj/item/card/id))
							usr.drop_item()
							I.loc = src
							held_card = I
				else
					release_held_id(usr)
			if("logout")
				authenticated_account = null
				//usr << browse(null,"window=atm")
	playsound(loc, 'sound/machines/button.ogg', 100, 1)
	src.attack_hand(usr)

// put the currently held id on the ground or in the hand of the user
/obj/machinery/atm/proc/release_held_id(mob/living/carbon/human/human_user as mob)
	if(!held_card)
		return

	held_card.forceMove(get_turf(src))
	authenticated_account = null

	if(ishuman(human_user) && !human_user.get_active_held_item())
		human_user.put_in_hands(held_card)
	held_card = null
	update_icon()

/obj/machinery/atm/proc/spawn_ewallet(sum, loc, mob/living/carbon/human/human_user as mob)
	var/obj/item/spacecash/ewallet/E = new /obj/item/spacecash/ewallet(loc)
	if(ishuman(human_user) && !human_user.get_active_held_item())
		human_user.put_in_hands(E)
	E.worth = sum
	E.owner_name = authenticated_account.owner_name
