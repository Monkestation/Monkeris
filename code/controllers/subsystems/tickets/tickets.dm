//Defines
//Deciseconds until ticket becomes stale if unanswered. Alerts admins.
#define TICKET_TIMEOUT 10 MINUTES // 10 minutes
//Decisecions before the user is allowed to open another ticket while their existing one is open.
#define TICKET_DUPLICATE_COOLDOWN 5 MINUTES // 5 minutes

//Status defines
#define TICKET_OPEN       1
#define TICKET_CLOSED     2
#define TICKET_RESOLVED   3
#define TICKET_STALE      4

#define TICKET_STAFF_MESSAGE_ADMIN_CHANNEL 1
#define TICKET_STAFF_MESSAGE_PREFIX 2

SUBSYSTEM_DEF(tickets)
	name = "Admin Tickets"
	init_order = INIT_ORDER_TICKETS
	wait = 300
	priority = FIRE_PRIORITY_TICKETS
	flags = SS_BACKGROUND

	var/span_class = "adminticket"
	var/ticket_system_name = "Admin Tickets"
	var/ticket_name = "Admin Ticket"
	var/close_rights = R_ADMIN
	var/rights_needed = R_ADMIN

	/// Text that will be added to the anchor link
	var/anchor_link_extra = ""

	var/ticket_help_type = "Adminhelp"
	var/ticket_help_span = "adminhelp"
	/// The name of the other ticket type to convert to
	var/other_ticket_name = "Mentor"
	/// Which permission to look for when seeing if there is staff available for the other ticket type
	var/other_ticket_permission = R_MENTOR
	var/list/close_messages
	var/list/allTickets = list()	//make it here because someone might ahelp before the system has initialized

	var/ticketCounter = 1

/datum/controller/subsystem/tickets/Initialize()
	if(!close_messages)
		close_messages = list("<font color='red' size='4'><b>- [ticket_name] Rejected! -</b></font>",
				span_boldnotice("Please try to be calm, clear, and descriptive in admin helps, do not assume the staff member has seen any related events, and clearly state the names of anybody you are reporting. If you asked a question, please ensure it was clear what you were asking."),
				"<span class='[span_class]'>Your [ticket_name] has now been closed.</span>")
	return ..()

/datum/controller/subsystem/tickets/fire()
	var/stales = checkStaleness()
	if(LAZYLEN(stales))
		var/report
		for(var/num in stales)
			report += "[num], "
		log_admin("<span class='[span_class]'>Tickets [report] have been open for over [TICKET_TIMEOUT / 600] minutes. Changing status to stale.</span>")
		message_admins("<span class='[span_class]'>Tickets [report] have been open for over [TICKET_TIMEOUT / 600] minutes. Changing status to stale.</span>")

/datum/controller/subsystem/tickets/stat_entry(msg)
	msg += "Tickets: [LAZYLEN(allTickets)]"
	return ..()

/datum/controller/subsystem/tickets/proc/checkStaleness()
	var/stales = list()
	for(var/T in allTickets)
		var/datum/ticket/ticket = T
		if(!(ticket.ticketState == TICKET_OPEN))
			continue
		if(world.time > ticket.timeUntilStale && (!ticket.lastStaffResponse || !ticket.staffAssigned))
			var/id = ticket.makeStale()
			stales += id
	return stales

//Return the current ticket number ready to be called off.
/datum/controller/subsystem/tickets/proc/getTicketCounter()
	return ticketCounter

//Return the ticket counter and increment
/datum/controller/subsystem/tickets/proc/getTicketCounterAndInc()
	. = ticketCounter
	ticketCounter++
	return

/datum/controller/subsystem/tickets/proc/resolveAllOpenTickets() // Resolve all open tickets
	for(var/i in allTickets)
		var/datum/ticket/T = i
		resolveTicket(T.ticketNum)

/**
 * Will either make a new ticket using the given text or will add the text to an existing ticket.
 * Staff will get a message
 * Arguments:
 * C - The client who requests help
 * text - The text the client send
 */
/datum/controller/subsystem/tickets/proc/newHelpRequest(client/C, text)
	var/ticketNum // Holder for the ticket number
	var/datum/ticket/T
	// Get the open ticket assigned to the client and add a response. If no open tickets then make a new one
	if((T = checkForOpenTicket(C)))
		ticketNum = T.ticketNum
		T.addResponse(C, text)
		T.setCooldownPeriod()
		to_chat(C.mob, "<span class='[span_class]'>Your [ticket_name] #[ticketNum] remains open! Visit \"My tickets\" under the Admin Tab to view it.</span>")
		var/url_message = makeUrlMessage(C, text, ticketNum)
		log_admin(url_message)
		message_admins(url_message)
	else
		newTicket(C, text, text)
		// Play adminhelp sound to all admins who have not disabled it in preferences
		for(var/client/X in GLOB.admins)
			if(X.get_preference_value(/datum/client_preference/staff/play_adminhelp_ping) == GLOB.PREF_HEAR)
				sound_to(X, 'sound/effects/adminhelp.ogg')

/**
 * Will add the URLs usable by staff to the message and return it
 * Arguments:
 * C - The client who send the message
 * msg - The raw message
 * ticketNum - Which ticket number the ticket has
 */
/datum/controller/subsystem/tickets/proc/makeUrlMessage(client/C, msg, ticketNum)
	var/list/L = list()
	L += "<span class='[ticket_help_span]'>[ticket_help_type]: </span><span class='boldnotice'>[key_name(C, TRUE, ticket_help_type)] "
	L += "([ADMIN_QUE(C.mob)]) ([ADMIN_PP(C.mob)]) ([ADMIN_VV(C.mob)]) ([ADMIN_TP(C.mob)]) ([ADMIN_SM(C.mob)]) "
	L += "([admin_jump_link(C.mob)]) (<a href='byond://?_src_=holder;[HrefToken()];openticket=[ticketNum][anchor_link_extra]'>TICKET</a>) "
	L += "[isAI(C.mob) ? "(<a href='byond://?_src_=holder;[HrefToken()];adminchecklaws=\ref[C.mob]'>CL</a>)" : ""] (<a href='byond://?_src_=holder;[HrefToken()];take_question=[ticketNum][anchor_link_extra]'>TAKE</a>) "
	L += "(<a href='byond://?_src_=holder;[HrefToken()];resolve=[ticketNum][anchor_link_extra]'>RESOLVE</a>) (<a href='byond://?_src_=holder;[HrefToken()];autorespond=[ticketNum][anchor_link_extra]'>AUTO</a>) "
	L += " :</span> <span class='[ticket_help_span]'>[msg]</span>"
	return L.Join()

//Open a new ticket and populate details then add to the list of open tickets
/datum/controller/subsystem/tickets/proc/newTicket(client/C, passedContent, title)
	if(!C || !passedContent)
		return

	if(!title)
		title = passedContent

	var/new_ticket_num = getTicketCounterAndInc()
	var/url_title = makeUrlMessage(C, title, new_ticket_num)

	var/datum/ticket/T = new(url_title, title, passedContent, new_ticket_num)
	allTickets += T
	T.client_ckey = C.ckey
	T.locationSent = C.mob?.loc?.name
	T.mobControlled = C.mob

	//Inform the user that they have opened a ticket
	to_chat(C, "<span class='[span_class]'>You have opened [ticket_name] number #[(getTicketCounter() - 1)]! Please be patient and we will help you soon!</span>")
	sound_to(C, "sound/effects/adminhelp.ogg")

	log_admin(url_title)
	message_admins(url_title)

//Set ticket state with key N to open
/datum/controller/subsystem/tickets/proc/openTicket(N)
	var/datum/ticket/T = allTickets[N]
	if(T.ticketState != TICKET_OPEN)
		log_admin("<span class='[span_class]'>[usr.client] / ([usr]) re-opened [ticket_name] number [N]</span>")
		message_admins("<span class='[span_class]'>[usr.client] / ([usr]) re-opened [ticket_name] number [N]</span>")
		T.ticketState = TICKET_OPEN
		return TRUE

//Set ticket state with key N to resolved
/datum/controller/subsystem/tickets/proc/resolveTicket(N)
	var/datum/ticket/T = allTickets[N]
	if(T.ticketState != TICKET_RESOLVED)
		T.ticketState = TICKET_RESOLVED
		log_admin("<span class='[span_class]'>[usr.client] / ([usr]) resolved [ticket_name] number [N]</span>")
		message_admins("<span class='[span_class]'>[usr.client] / ([usr]) resolved [ticket_name] number [N]</span>")
		to_chat(returnClient(N), "<span class='[span_class]'>Your [ticket_name] has now been resolved.</span>")
		return TRUE

/datum/controller/subsystem/tickets/proc/convert_to_other_ticket(ticketId)
	if(!check_rights(rights_needed))
		return
	if(alert("Are you sure to convert this ticket to an '[other_ticket_name]' ticket?",,"Yes","No") != "Yes")
		return
	if(!other_ticket_system_staff_check())
		return
	var/datum/ticket/T = allTickets[ticketId]
	if(T.ticket_converted)
		to_chat(usr, span_warning("This ticket has already been converted!"))
		return
	convert_ticket(T)

/datum/controller/subsystem/tickets/proc/other_ticket_system_staff_check()
	var/list/staff = staff_countup(other_ticket_permission)
	if(!staff[1])
		if(alert("No active staff online to answer the ticket. Are you sure you want to convert the ticket?",, "No", "Yes") != "Yes")
			return FALSE
	return TRUE

/datum/controller/subsystem/tickets/proc/convert_ticket(datum/ticket/T)
	T.ticketState = TICKET_CLOSED
	T.ticket_converted = TRUE
	var/client/C = usr.client
	var/client/owner = get_client_by_ckey(T.client_ckey)
	to_chat(owner, list("<span class='[span_class]'>[C] has converted your ticket to a [other_ticket_name] ticket.</span>",\
									"<span class='[span_class]'>Be sure to use the correct type of help next time!</span>"))
	log_admin("<span class='[span_class]'>[C] has converted ticket number [T.ticketNum] to a [other_ticket_name] ticket.</span>")
	message_admins("<span class='[span_class]'>[C] has converted ticket number [T.ticketNum] to a [other_ticket_name] ticket.</span>")
	create_other_system_ticket(T)

/datum/controller/subsystem/tickets/proc/create_other_system_ticket(datum/ticket/T)
	var/client/C = get_client_by_ckey(T.client_ckey)
	SSmentor_tickets.newTicket(C, T.content, T.raw_title)

/datum/controller/subsystem/tickets/proc/autoRespond(N)
	if(!check_rights(rights_needed))
		return

	var/datum/ticket/T = allTickets[N]
	var/client/C = usr.client
	if((T.staffAssigned && T.staffAssigned != C) || (T.lastStaffResponse && T.lastStaffResponse != C) || ((T.ticketState != TICKET_OPEN) && (T.ticketState != TICKET_STALE))) //if someone took this ticket, is it the same admin who is autoresponding? if so, then skip the warning
		if(alert(usr, "[T.ticketState == TICKET_OPEN ? "Another admin appears to already be handling this." : "This ticket is already marked as closed or resolved"] Are you sure you want to continue?", "Confirmation", "Yes", "No") != "Yes")
			return
	T.assignStaff(C)

	var/response_phrases = list("Thanks" = "Thanks, have a good day!",
		"Handling It" = "The issue is being looked into, thanks.",
		"Already Resolved" = "The problem has been resolved already.",
		//"Mentorhelp" = "Please redirect your question to Mentorhelp, as they are better experienced with these types of questions.",
		"Happens Again" = "Thanks, let us know if it continues to happen.",
		"Github Discord Issue Report" = "To report a bug, please go to our Github page. Then go to 'Issues'. Then 'New Issue'. Then fill out the report form. If the report would reveal current-round information, file it after the round ends. If you prefer, you can also report it in the Junkyard channel of our Discord.",
		"Clear Cache" = "To fix a blank screen, go to the 'Special Verbs' tab and press 'Reload UI Resources'. If that fails, clear your BYOND cache (instructions provided with 'Reload UI Resources'). If that still fails, please adminhelp again, stating you have already done the following." ,
		"IC Issue" = "This is an In Character (IC) issue and will not be handled by admins. You could speak to IronHammer security forces, a departmental head or any other relevant authority currently aboard the ship.",
		"Reject" = "Reject",
		"Man Up" = "Man Up",
		"Skill Issue" = "Skill Issue",
		"Appeal on the Forums" = "Appealing a ban must occur on the forums. Privately messaging, or adminhelping about your ban will not resolve it."
		)

	var/sorted_responses = list()
	for(var/key in response_phrases)	//build a new list based on the short descriptive keys of the master list so we can send this as the input instead of the full paragraphs to the admin choosing which autoresponse
		sorted_responses += key

	var/message_key = input("Select an autoresponse. This will mark the ticket as resolved.", "Autoresponse") as null|anything in sortTim(sorted_responses, /proc/cmp_text_asc) //use sortTim and cmp_text_asc to sort alphabetically
	var/client/ticket_owner = get_client_by_ckey(T.client_ckey)
	switch(message_key)
		if(null) //they cancelled
			T.staffAssigned = initial(T.staffAssigned) //if they cancel we dont need to hold this ticket anymore
			return
		//if("Mentorhelp")
		//	convert_ticket(T)
		if("Reject")
			if(!closeTicket(N))
				to_chat(C, "Unable to close ticket")
		if("Man Up")
			C.man_up(returnClient(N))
		if("Skill Issue")
			C.skill_issue(returnClient(N))
		else
			to_chat(returnClient(N), "<span class='[span_class]'>[C] is autoresponding with: <span/> [span_adminticketalt("[response_phrases[message_key]]")]")//for this we want the full value of whatever key this is to tell the player so we do response_phrases[message_key]
	sound_to(returnClient(N), "sound/effects/adminhelp.ogg")
	log_admin("[C] has auto responded to [ticket_owner]\'s adminhelp with:[span_adminticketalt(" [message_key] ")]") //we want to use the short named keys for this instead of the full sentence which is why we just do message_key
	T.lastStaffResponse = "Autoresponse: [message_key]"
	resolveTicket(N)

//Set ticket state with key N to closed
/datum/controller/subsystem/tickets/proc/closeTicket(N)
	var/datum/ticket/T = allTickets[N]
	if(T.ticketState != TICKET_CLOSED)
		log_admin("<span class='[span_class]'>[usr.client] / ([usr]) closed [ticket_name] number [N]</span>")
		message_admins("<span class='[span_class]'>[usr.client] / ([usr]) closed [ticket_name] number [N]</span>")
		to_chat(returnClient(N), close_messages)
		T.ticketState = TICKET_CLOSED
		return TRUE

//Check if the user already has a ticket open and within the cooldown period.
/datum/controller/subsystem/tickets/proc/checkForOpenTicket(ckey)
	if (isclient(ckey))
		ckey = astype(ckey, /client).ckey

	for(var/datum/ticket/T in allTickets)
		if(T.client_ckey == ckey && T.ticketState == TICKET_OPEN && (T.ticketCooldown > world.time))
			return T
	return FALSE

//Check if the user has ANY ticket not resolved or closed.
/datum/controller/subsystem/tickets/proc/checkForTicket(ckey)
	if (isclient(ckey))
		ckey = astype(ckey, /client).ckey

	var/list/tickets = list()
	for(var/datum/ticket/T in allTickets)
		if(T.client_ckey == ckey && (T.ticketState == TICKET_OPEN || T.ticketState == TICKET_STALE))
			tickets += T
	if(tickets.len)
		return tickets
	return FALSE

//return the client of a ticket number
/datum/controller/subsystem/tickets/proc/returnClient(N)
	var/datum/ticket/T = allTickets[N]
	return get_client_by_ckey(T.client_ckey)

/datum/controller/subsystem/tickets/proc/assignStaffToTicket(client/C, N)
	var/datum/ticket/T = allTickets[N]
	if(T.staffAssigned != null && T.staffAssigned != C && alert("Ticket is already assigned to [T.staffAssigned.ckey]. Are you sure you want to take it?", "Take ticket", "Yes", "No") != "Yes")
		return FALSE
	T.assignStaff(C)
	return TRUE

//Single staff ticket

/datum/ticket
	/// Ticket number.
	var/ticketNum
	/// ckey of the client who opened the ticket.
	var/client_ckey
	/// Time the ticket was opened.
	var/timeOpened
	/// The initial message with links.
	var/title
	/// The title without URLs added.
	var/raw_title
	/// Content of the staff help.
	var/list/content
	/// Last staff member who responded.
	var/lastStaffResponse
	/// When the staff last responded.
	var/lastResponseTime
	/// The location the player was when they sent the ticket.
	var/locationSent
	/// The mob the player was controlling when they sent the ticket.
	var/mobControlled
	/// State of the ticket, open, closed, resolved etc.
	var/ticketState
	/// Has the ticket been converted to another type? (Mhelp to Ahelp, etc.)
	var/ticket_converted = FALSE
	/// When the ticket goes stale.
	var/timeUntilStale
	/// Cooldown before allowing the user to open another ticket.
	var/ticketCooldown
	/// Staff member who has assigned themselves to this ticket.
	var/client/staffAssigned

/datum/ticket/New(tit, raw_tit, cont, num)
	title = tit
	raw_title = raw_tit
	content = list()
	content += cont
	timeOpened = worldtime2text()
	timeUntilStale = world.time + TICKET_TIMEOUT
	setCooldownPeriod()
	ticketNum = num
	ticketState = TICKET_OPEN

//Set the cooldown period for the ticket. The time when it's created plus the defined cooldown time.
/datum/ticket/proc/setCooldownPeriod()
	ticketCooldown = world.time + TICKET_DUPLICATE_COOLDOWN

//Set the last staff who responded as the client passed as an arguement.
/datum/ticket/proc/setLastStaffResponse(client/C)
	lastStaffResponse = C
	lastResponseTime = worldtime2text()

//Return the ticket state as a colour coded text string.
/datum/ticket/proc/state2text()
	if(ticket_converted)
		return "<font color='yellow'>CONVERTED</font>"
	switch(ticketState)
		if(TICKET_OPEN)
			return "<font color='green'>OPEN</font>"
		if(TICKET_RESOLVED)
			return "<font color='blue'>RESOLVED</font>"
		if(TICKET_CLOSED)
			return "<font color='red'>CLOSED</font>"
		if(TICKET_STALE)
			return "<font color='orange'>STALE</font>"

//Assign the client passed to var/staffAsssigned
/datum/ticket/proc/assignStaff(client/C)
	if(!C)
		return
	staffAssigned = C
	return TRUE

/datum/ticket/proc/addResponse(client/C, msg)
	if(C.holder)
		setLastStaffResponse(C)
	msg = "[C]: [msg]"
	content += msg

/datum/ticket/proc/makeStale()
	ticketState = TICKET_STALE
	return ticketNum

/*

UI STUFF

*/

/datum/controller/subsystem/tickets/proc/returnUI(tab = TICKET_OPEN)
	set name = "Open Ticket Interface"
	set category = "Tickets"

//dat
	var/trStyle = "border-top:2px solid; border-bottom:2px solid; padding-top: 5px; padding-bottom: 5px;"
	var/tdStyleleft = "border-top:2px solid; border-bottom:2px solid; width:150px; text-align:center;"
	var/tdStyle = "border-top:2px solid; border-bottom:2px solid;"
	var/datum/ticket/ticket
	var/dat
	dat += "<head><style>.adminticket{border:2px solid}</style></head>"
	dat += "<body><h1>[ticket_system_name]</h1>"

	dat +="<a href='byond://?src=\ref[src];refresh=1'>Refresh</a><br /><a href='byond://?src=\ref[src];showopen=1'>Open Tickets</a><a href='byond://?src=\ref[src];showresolved=1'>Resolved Tickets</a><a href='byond://?src=\ref[src];showclosed=1'>Closed Tickets</a>"
	if(tab == TICKET_OPEN)
		dat += "<h2>Open Tickets</h2>"
	dat += "<table style='width:1300px; border: 3px solid;'>"
	dat +="<tr style='[trStyle]'><th style='[tdStyleleft]'>Control</th><th style='[tdStyle]'>Ticket</th></tr>"
	if(tab == TICKET_OPEN)
		for(var/T in allTickets)
			ticket = T
			if(ticket.ticketState == TICKET_OPEN || ticket.ticketState == TICKET_STALE)
				dat += "<tr style='[trStyle]'><td style ='[tdStyleleft]'><a href='byond://?src=\ref[src];resolve=[ticket.ticketNum]'>Resolve</a><a href='byond://?src=\ref[src];details=[ticket.ticketNum]'>Details</a> <br /> #[ticket.ticketNum] ([ticket.timeOpened]) [ticket.ticketState == TICKET_STALE ? "<font color='red'><b>STALE</font>" : ""] </td><td style='[tdStyle]'><b>[ticket.title]</td></tr>"
			else
				continue
	else  if(tab == TICKET_RESOLVED)
		dat += "<h2>Resolved Tickets</h2>"
		for(var/T in allTickets)
			ticket = T
			if(ticket.ticketState == TICKET_RESOLVED)
				dat += "<tr style='[trStyle]'><td style ='[tdStyleleft]'><a href='byond://?src=\ref[src];resolve=[ticket.ticketNum]'>Resolve</a><a href='byond://?src=\ref[src];details=[ticket.ticketNum]'>Details</a> <br /> #[ticket.ticketNum] ([ticket.timeOpened]) </td><td style='[tdStyle]'><b>[ticket.title]</td></tr>"
			else
				continue
	else if(tab == TICKET_CLOSED)
		dat += "<h2>Closed Tickets</h2>"
		for(var/T in allTickets)
			ticket = T
			if(ticket.ticketState == TICKET_CLOSED)
				dat += "<tr style='[trStyle]'><td style ='[tdStyleleft]'><a href='byond://?src=\ref[src];resolve=[ticket.ticketNum]'>Resolve</a><a href='byond://?src=\ref[src];details=[ticket.ticketNum]'>Details</a> <br /> #[ticket.ticketNum] ([ticket.timeOpened]) </td><td style='[tdStyle]'><b>[ticket.title]</td></tr>"
			else
				continue

	dat += "</table>"
	dat += "<h1>Resolve All</h1>"
	if(ticket_system_name == "Mentor Tickets")
		dat += "<a href='byond://?src=\ref[src];resolveall=1'>Resolve All Open Mentor Tickets</a></body>"
	else
		dat += "<a href='byond://?src=\ref[src];resolveall=1'>Resolve All Open Admin Tickets</a></body>"

	return dat

/datum/controller/subsystem/tickets/proc/showUI(mob/user, tab)
	var/dat = null
	dat = returnUI(tab)
	var/datum/browser/popup = new(user, ticket_system_name, ticket_system_name, 1400, 600)
	popup.set_content(dat)
	popup.open()

/datum/controller/subsystem/tickets/proc/showDetailUI(mob/user, ticketID)
	var/datum/ticket/T = allTickets[ticketID]
	var/status = "[T.state2text()]"

	var/dat = "<h1>[ticket_system_name]</h1>"

	dat +="<a href='byond://?src=\ref[src];refresh=1'>Show All</a><a href='byond://?src=\ref[src];refreshdetail=[T.ticketNum]'>Refresh</a>"

	dat += "<h2>Ticket #[T.ticketNum]</h2>"

	dat += "<h3>[T.client_ckey] / [T.mobControlled] opened this [ticket_name] at [T.timeOpened] at location [T.locationSent]</h3>"
	dat += "<h4>Ticket Status: [status]"
	dat += "<table style='width:950px; border: 3px solid;'>"
	dat += "<tr><td>[T.title]</td></tr>"

	if(T.content.len > 1)
		for(var/i = 2, i <= T.content.len, i++)
			dat += "<tr><td>[T.content[i]]</td></tr>"

	dat += "</table><br /><br />"
	dat += "<a href='byond://?src=\ref[src];detailreopen=[T.ticketNum]'>Re-Open</a><a href='byond://?src=\ref[src];detailresolve=[T.ticketNum]'>Resolve</a><br /><br />"

	if(!T.staffAssigned)
		dat += "No staff member assigned to this [ticket_name] - <a href='byond://?src=\ref[src];assignstaff=[T.ticketNum]'>Take Ticket</a><br />"
	else
		dat += "[T.staffAssigned] is assigned to this Ticket. - <a href='byond://?src=\ref[src];assignstaff=[T.ticketNum]'>Take Ticket</a> - <a href='byond://?src=\ref[src];unassignstaff=[T.ticketNum]'>Unassign Ticket</a><br />"

	if(T.lastStaffResponse)
		dat += "<b>Last Staff response Response:</b> [T.lastStaffResponse] at [T.lastResponseTime]"
	else
		dat +="<font color='red'>No Staff Response</font>"

	dat += "<br /><br />"

	dat += "<a href='byond://?src=\ref[src];detailclose=[T.ticketNum]'>Close Ticket</a>"
	// dat += "<a href='byond://?src=\ref[src];convert_ticket=[T.ticketNum]'>Convert Ticket</a>"

	var/datum/browser/popup = new(user, "[ticket_system_name]detail", "[ticket_system_name] #[T.ticketNum]", 1000, 600)
	popup.set_content(dat)
	popup.open()

/datum/controller/subsystem/tickets/proc/userDetailUI(mob/user)
//dat
	var/tickets = checkForTicket(user.client)
	var/dat
	dat += "<h1>Your open [ticket_system_name]</h1>"
	dat += "<table>"
	for(var/datum/ticket/T in tickets)
		dat += "<tr><td><h2>Ticket #[T.ticketNum]</h2></td></tr>"
		for(var/i = 1, i <= T.content.len, i++)
			dat += "<tr><td>[T.content[i]]</td></tr>"
	dat += "</table>"

	var/datum/browser/popup = new(user, "[ticket_system_name]userticketsdetail", ticket_system_name, 1000, 600)
	popup.set_content(dat)
	popup.open()

/**
 * Sends a message to the designated staff
 * Arguments:
 * msg - The message being send
 * alt - If an alternative prefix should be used or not. Defaults to TICKET_STAFF_MESSAGE_PREFIX
 * important - If the message is important. If TRUE it will ignore the PREF_HEAR preferences,
               send a sound and flash the window. Defaults to FALSE
 */
/datum/controller/subsystem/tickets/proc/message_staff(msg, prefix_type = TICKET_STAFF_MESSAGE_PREFIX, important = FALSE)
	switch(prefix_type)
		if(TICKET_STAFF_MESSAGE_ADMIN_CHANNEL)
			msg = "<span class='admin_channel'>ADMIN TICKET: [msg]</span>"
		if(TICKET_STAFF_MESSAGE_PREFIX)
			msg = span_adminticket("[span_prefix("ADMIN TICKET:")] [msg]")
	message_adminTicket(msg, important)

/datum/controller/subsystem/tickets/Topic(href, href_list)

	if(href_list["refresh"])
		showUI(usr)
		return

	if(href_list["refreshdetail"])
		var/indexNum = text2num(href_list["refreshdetail"])
		showDetailUI(usr, indexNum)
		return

	if(href_list["showopen"])
		showUI(usr, TICKET_OPEN)
		return
	if(href_list["showresolved"])
		showUI(usr, TICKET_RESOLVED)
		return
	if(href_list["showclosed"])
		showUI(usr, TICKET_CLOSED)
		return

	if(href_list["details"])
		var/indexNum = text2num(href_list["details"])
		showDetailUI(usr, indexNum)
		return

	if(href_list["resolve"])
		var/indexNum = text2num(href_list["resolve"])
		if(resolveTicket(indexNum))
			showUI(usr)

	if(href_list["detailresolve"])
		var/indexNum = text2num(href_list["detailresolve"])
		if(resolveTicket(indexNum))
			showDetailUI(usr, indexNum)

	if(href_list["detailclose"])
		var/indexNum = text2num(href_list["detailclose"])
		if(!check_rights(close_rights))
			to_chat(usr, span_warning("Not enough rights to close this ticket."))
			return
		if(alert("Are you sure? This will send a negative message.",,"Yes","No") != "Yes")
			return
		if(closeTicket(indexNum))
			showDetailUI(usr, indexNum)

	if(href_list["detailreopen"])
		var/indexNum = text2num(href_list["detailreopen"])
		if(openTicket(indexNum))
			showDetailUI(usr, indexNum)

	if(href_list["assignstaff"])
		var/indexNum = text2num(href_list["assignstaff"])
		takeTicket(indexNum)
		showDetailUI(usr, indexNum)

	if(href_list["unassignstaff"])
		var/indexNum = text2num(href_list["unassignstaff"])
		unassignTicket(indexNum)
		showDetailUI(usr, indexNum)

	if(href_list["autorespond"])
		var/indexNum = text2num(href_list["autorespond"])
		autoRespond(indexNum)

	/*if(href_list["convert_ticket"])
		var/indexNum = text2num(href_list["convert_ticket"])
		convert_to_other_ticket(indexNum)*/

	if(href_list["resolveall"])
		/*if(ticket_system_name == "Mentor Tickets")
			usr.client.resolveAllMentorTickets()
		else*/
		usr.client.resolveAllAdminTickets()

/datum/controller/subsystem/tickets/proc/takeTicket(index)
	if(assignStaffToTicket(usr.client, index))
		log_admin("<span class='[span_class]'>[usr.client] / ([usr]) has taken [ticket_name] number [index]</span>")
		message_admins("<span class='[span_class]'>[usr.client] / ([usr]) has taken [ticket_name] number [index]</span>")
		to_chat(returnClient(index), "<span class='[span_class]'>Your [ticket_name] is being handled by [usr.client].</span>")

/datum/controller/subsystem/tickets/proc/unassignTicket(index)
	var/datum/ticket/T = allTickets[index]
	if(T.staffAssigned != null && (T.staffAssigned == usr.client || alert("Ticket is already assigned to [T.staffAssigned]. Do you want to unassign it?","Unassign ticket","No","Yes") == "Yes"))
		T.staffAssigned = null
		to_chat(returnClient(index), "<span class='[span_class]'>Your [ticket_name] has been unassigned. Another staff member will help you soon.</span>")
		log_admin("<span class='[span_class]'>[usr.client] / ([usr]) has unassigned [ticket_name] number [index]</span>")
		message_admins("<span class='[span_class]'>[usr.client] / ([usr]) has unassigned [ticket_name] number [index]</span>")

#undef TICKET_STAFF_MESSAGE_ADMIN_CHANNEL
#undef TICKET_STAFF_MESSAGE_PREFIX
