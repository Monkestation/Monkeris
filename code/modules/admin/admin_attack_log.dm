/mob/var/lastattacker = null
/mob/var/lastattacked = null
/mob/var/attack_log = list()

/proc/log_and_message_admins(message as text, mob/user = usr, turf/location)
	var/turf/T = location ? location : (user ? get_turf(user) : null)
	if(T)
		message = message + " [ADMIN_JMP(T)]"

	log_admin(user ? "[key_name(user)] [message]" : "EVENT [message]")
	message_admins(user ? "[key_name_admin(user)] [message]" : "EVENT [message]")

/proc/log_and_message_admins_many(list/mob/users, message)
	if(!users || !users.len)
		return

	var/list/user_keys = list()
	for(var/mob/user in users)
		user_keys += key_name(user)

	log_admin("[english_list(user_keys)] [message]")
	message_admins("[english_list(user_keys)] [message]")

/proc/admin_attack_log(mob/attacker, mob/victim, attacker_message, victim_message, admin_message)
	if(victim)
		victim.attack_log += text("\[[time_stamp()]\] <font color='orange'>[key_name(attacker)] - [victim_message]</font>")
	if(attacker)
		attacker.attack_log += text("\[[time_stamp()]\] <font color='red'>[key_name(victim)] - [attacker_message]</font>")

	msg_admin_attack("[key_name(attacker)] [admin_message] [key_name(victim)] (INTENT: [attacker? uppertext(attacker.a_intent) : "N/A"]) [ADMIN_JMP(attacker)]")

/proc/admin_attacker_log_many_victims(mob/attacker, list/mob/victims, attacker_message, victim_message, admin_message)
	if(!victims || !victims.len)
		return

	for(var/mob/victim in victims)
		admin_attack_log(attacker, victim, attacker_message, victim_message, admin_message)

/proc/admin_inject_log(mob/attacker, mob/victim, obj/item/weapon, reagents, amount_transferred, violent=0)
	if(violent)
		violent = "violently "
	else
		violent = ""
	admin_attack_log(attacker,
	                 victim,
	                 "used \the [weapon] to [violent]inject - [reagents] - [amount_transferred]u transferred",
	                 "was [violent]injected with \the [weapon] - [reagents] - [amount_transferred]u transferred",
	                 "used \the [weapon] to [violent]inject [reagents] ([amount_transferred]u transferred) into")
