/* Cards
 * Contains:
 *		DATA CARD
 *		ID CARD
 *		FINGERPRINT CARD HOLDER
 *		FINGERPRINT CARD
 */



/*
 * DATA CARDS - Used for the teleporter
 */
/obj/item/card
	name = "card"
	desc = "Does card things."
	icon = 'icons/obj/card.dmi'
	w_class = ITEM_SIZE_TINY
	bad_type = /obj/item/card
	spawn_blacklisted = TRUE
	var/list/files = list()

/obj/item/card/data
	name = "data disk"
	desc = "A disk of data."
	icon_state = "data"
	item_state = "card-id"
	var/function = "storage"
	var/data = "null"
	var/special

/obj/item/card/data/verb/label(t as text)
	set name = "Label Disk"
	set category = "Object"
	set src in usr

	if (t)
		src.name = text("data disk- '[]'", t)
	else
		src.name = "data disk"
	src.add_fingerprint(usr)
	return

/obj/item/card/data/clown
	name = "\proper the coordinates to clown planet"
	icon_state = "data"
	item_state = "card-id"
	layer = 3
	level = ABOVE_PLATING_LEVEL
	desc = "This card contains coordinates to the fabled Clown Planet. Handle with care."
	function = "teleporter"
	data = "Clown Land"

/*
 * ID CARDS
 */

/obj/item/card/emag_broken
	desc = "A card with a magnetic strip attached to some circuitry. It looks too busted to be used for anything but salvage."
	name = "broken cryptographic sequencer"
	icon_state = "emag"
	item_state = "card-id"
	origin_tech = list(TECH_MAGNET = 2, TECH_COVERT = 2)
	matter = list(MATERIAL_SILVER = 1, MATERIAL_PLASTIC = 1)

/obj/item/card/emag
	desc = "A card with a magnetic strip attached to some circuitry."
	name = "cryptographic sequencer"
	description_antag = "This item has 10 by default. Emagging turrets turns them lethal to everyone. Emagging a door opens it and bolts it. Emagging a non-sentient robot turns them hostile. Emagging a cyborg forces them to obey you. Emagging an APC lets only you acces it."
	icon_state = "emag"
	item_state = "card-id"
	origin_tech = list(TECH_MAGNET = 2, TECH_COVERT = 2)
	var/uses = 10

var/const/NO_EMAG_ACT = -50
/obj/item/card/emag/resolve_attackby(atom/A, mob/user)
	var/used_uses = A.emag_act(uses, user, src)
	if(used_uses == NO_EMAG_ACT)
		return ..(A, user)

	uses -= used_uses
	A.add_fingerprint(user)
	if(used_uses)
		log_and_message_admins("emagged \an [A].")

	if(uses<1)
		user.visible_message(span_warning("\The [src] fizzles and sparks - it seems it's been used once too often, and is now spent."))
		user.drop_item()
		var/obj/item/card/emag_broken/junk = new(user.loc)
		junk.add_fingerprint(user)
		qdel(src)

	return 1

/obj/item/card/id
	name = "identification card"
	desc = "A card used to provide ID and determine access across the ship."
	icon_state = "id"
	item_state = "card-id"
	slot_flags = SLOT_ID

	var/access = list()
	var/registered_name = "Unknown" // The name registered_name on the card
	var/list/associated_email_login = list("login" = "", "password" = "")
	var/associated_account_number = 0

	var/age = "\[UNSET\]"
	var/blood_type = "\[UNSET\]"
	var/dna_hash = "\[UNSET\]"
	var/fingerprint_hash = "\[UNSET\]"
	var/sex = "\[UNSET\]"
	var/icon/front
	var/icon/side

	//alt titles are handled a bit weirdly in order to unobtrusively integrate into existing ID system
	var/assignment	//can be alt title or the actual job
	var/rank			//actual job
	var/dorm = 0			// determines if this ID has claimed a dorm already

	var/formal_name_prefix
	var/formal_name_suffix

/obj/item/card/id/examine(mob/user, extra_description = "")
	set src in oview(1) // TODO: See if this could be safely removed --KIROV
	if(get_dist(user, src) < 2)
		show(user)
		extra_description += desc
		extra_description += text("\n[icon2html(src, user)] [name]: The current assignment on the card is [assignment].")
		extra_description += "\nThe blood type on the card is [blood_type]."
		extra_description += "\nThe DNA hash on the card is [dna_hash]."
		extra_description += "\nThe fingerprint hash on the card is [fingerprint_hash]."
	else
		extra_description += span_warning("It is too far away.")

/obj/item/card/id/proc/prevent_tracking()
	return 0

/obj/item/card/id/proc/show(mob/user as mob)
	if(front && side)
		user << browse_rsc(front, "front.png")
		user << browse_rsc(side, "side.png")
	var/datum/browser/popup = new(user, "idcard", name, 600, 250)
	popup.set_content(dat())
	popup.open()
	return

/obj/item/card/id/proc/update_name()
	name = "[src.registered_name]'s ID Card ([src.assignment])"

/obj/item/card/id/proc/set_id_photo(mob/M)
	front = getFlatIcon(M, SOUTH)
	side = getFlatIcon(M, WEST)

/mob/proc/set_id_info(obj/item/card/id/id_card)
	id_card.age = 0
	id_card.registered_name		= real_name
	id_card.sex 				= capitalize(gender)
	id_card.set_id_photo(src)
	id_card.blood_type		= b_type
	id_card.dna_hash		= dna_trace
	id_card.fingerprint_hash= fingers_trace
	id_card.update_name()

/mob/living/carbon/human/set_id_info(obj/item/card/id/id_card)
	..()
	id_card.age = age

/obj/item/card/id/proc/dat()
	var/dat = ("<table><tr><td>")
	dat += text("Name: []</A><BR>", registered_name)
	dat += text("Sex: []</A><BR>\n", sex)
	dat += text("Age: []</A><BR>\n", age)
	dat += text("Rank: []</A><BR>\n", assignment)
	dat += text("Fingerprint: []</A><BR>\n", fingerprint_hash)
	dat += text("Blood Type: []<BR>\n", blood_type)
	dat += text("DNA Hash: []<BR><BR>\n", dna_hash)
	if(front && side)
		dat +="<td align = center valign = top>Photo:<br><img src=front.png height=80 width=80 border=4><img src=side.png height=80 width=80 border=4></td>"
	dat += "</tr></table>"
	return dat

/obj/item/card/id/attack_self(mob/user as mob)
	var/visible_to = viewers(get_turf(src))
	user.visible_message("\The [user] shows you: [icon2html(src, visible_to)] [src.name]. The assignment on the card: [src.assignment]",\
		"You flash your ID card: [icon2html(src, visible_to)] [src.name]. The assignment on the card: [src.assignment]")

	src.add_fingerprint(user)
	return

/obj/item/card/id/GetAccess()
	return access

/obj/item/card/id/GetIdCard()
	return src

/obj/item/card/id/syndicate_command
	name = "syndicate ID card"
	desc = "An ID straight from the Syndicate."
	registered_name = "Syndicate"
	assignment = "Syndicate Overlord"
	access = list(access_syndicate, access_external_airlocks)

/obj/item/card/id/captains_spare
	name = "captain's spare ID"
	desc = "The spare ID of the High Lord himself."
	icon_state = MATERIAL_GOLD
	item_state = "gold_id"
	registered_name = "Captain"
	assignment = "Captain"
	spawn_blacklisted = TRUE

/obj/item/card/id/captains_spare/New()
	access = get_all_station_access()
	..()

/obj/item/card/id/synthetic
	name = "\improper Synthetic ID"
	desc = "Access module for NanoTrasen Synthetics"
	icon_state = "id-robot"
	item_state = "tdgreen"
	assignment = "Synthetic"
	spawn_tags = null
	bad_type = /obj/item/card/id/synthetic

/obj/item/card/id/synthetic/New()
	access = get_all_station_access() + access_synth
	..()

/obj/item/card/id/all_access
	name = "\improper Administrator's spare ID"
	desc = "The spare ID of the Lord of Lords himself."
	icon_state = "data"
	item_state = "tdgreen"
	registered_name = "Administrator"
	assignment = "Administrator"
	spawn_blacklisted = TRUE

/obj/item/card/id/all_access/New()
	access = get_access_ids()
	..()

/obj/item/card/id/centcom
	name = "\improper CentCom. ID"
	desc = "An ID straight from Cent. Com."
	icon_state = "centcom"
	registered_name = "Central Command"
	assignment = "General"

/obj/item/card/id/centcom/New()
	access = get_all_centcom_access()
	..()

/obj/item/card/id/gold
	icon_state = MATERIAL_GOLD
	item_state = "gold_id"

/obj/item/card/id/sci
	icon_state = "id_sci"

/obj/item/card/id/gene
	icon_state = "id_gene"

/obj/item/card/id/chem
	icon_state = "id_chem"

/obj/item/card/id/med
	icon_state = "id_med"

/obj/item/card/id/sci
	icon_state = "id_sci"

/obj/item/card/id/viro
	icon_state = "id_viro"

/obj/item/card/id/heatlab
	icon_state = "id_heatlab"

/obj/item/card/id/rd
	icon_state = "id_rd"

/obj/item/card/id/cmo
	icon_state = "id_cmo"

/obj/item/card/id/det
	icon_state = "id_inspector"

/obj/item/card/id/medcpec
	icon_state = "id_medspec"

/obj/item/card/id/sec
	icon_state = "id_operative"

/obj/item/card/id/hos
	icon_state = "id_hos"

/obj/item/card/id/hop
	icon_state = "id_hop"

/obj/item/card/id/ce
	icon_state = "id_ce"

/obj/item/card/id/engie
	icon_state = "id_engie"

/obj/item/card/id/atmos
	icon_state = "id_atmos"

/obj/item/card/id/car
	icon_state = "id_car"

/obj/item/card/id/hydro
	icon_state = "id_hydro"

/obj/item/card/id/chaplain
	icon_state = "id_chaplain"

/obj/item/card/id/church
	icon_state = "id_nt"

/obj/item/card/id/black
	icon_state = "id_black"

/obj/item/card/id/dkgrey
	icon_state = "id_dkgrey"

/obj/item/card/id/ltgrey
	icon_state = "id_ltgrey"

/obj/item/card/id/white
	icon_state = "id_white"

/obj/item/card/id/blankwhite
	icon_state = "id_blankwhite"

/obj/item/card/id/randomassistant

/obj/item/card/id/randomassistant/Initialize()
	. = ..()
	age = num2text(rand(18, 100))
	var/datum/job_flavor/flavortype = pick(subtypesof(/datum/job_flavor/assistant))
	assignment = initial(flavortype.title)
	access = list(access_maint_tunnels)
	sex = capitalize(pick(MALE, FEMALE))
	registered_name = addtext(random_first_name(sex), " ", random_last_name()) // Is this faster than two concats? Probably!
	dna_hash = sha1("A"+registered_name) // Something is subtly wrong with these IDs
	fingerprint_hash = md5("A"+registered_name)
	blood_type = pick(GLOB.blood_types)
	update_name()
