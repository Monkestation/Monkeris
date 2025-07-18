//A set of constants used to determine which type of mute an admin wishes to apply:
//Please read and understand the muting/automuting stuff before changing these. MUTE_IC_AUTO etc = (MUTE_IC << 1)
//Therefore there needs to be a gap between the flags for the automute flags
#define MUTE_IC (1<<0)
#define MUTE_OOC (1<<1)
#define MUTE_PRAY (1<<2)
#define MUTE_ADMINHELP (1<<3)
#define MUTE_DEADCHAT (1<<4)
#define MUTE_TTS (1<<5)
#define MUTE_ALL (~0)

// Number of identical messages required to get the spam-prevention auto-mute thing to trigger warnings and automutes.
#define SPAM_TRIGGER_WARNING  5
#define SPAM_TRIGGER_AUTOMUTE 10

//Some constants for DB_Ban
#define BANTYPE_PERMA 1
#define BANTYPE_TEMP 2
#define BANTYPE_JOB_PERMA 3
#define BANTYPE_JOB_TEMP 4
/// used to locate stuff to unban.
#define BANTYPE_ANY_FULLBAN 5

#define STICKYBAN_DB_CACHE_TIME (10 SECONDS)
#define STICKYBAN_ROGUE_CHECK_TIME 5

#define ROUNDSTART_LOGOUT_REPORT_TIME 6000 // Amount of time (in deciseconds) after the rounds starts, that the player disconnect report is issued.

/// When passed in as the duration for ban_panel, will make the ban default to permanent
#define BAN_PANEL_PERMANENT "permanent"

// Admin permissions.
#define R_FUN           (1<<0)
#define R_SERVER        (1<<1)
#define R_DEBUG         (1<<2)
#define R_PERMISSIONS   (1<<3)
#define R_MENTOR        (1<<4)
#define R_ADMIN         (1<<5)
#define R_BAN           (1<<6)

#define R_EVERYTHING (1<<7)-1 //the sum of all other rank permissions, used for +EVERYTHING


#define ADMIN_QUE(user) "(<a href='byond://?_src_=holder;[HrefToken(forceGlobal = TRUE)];adminmoreinfo=[REF(user)]'>?</a>)"
#define ADMIN_FLW(user) "(<a href='byond://?_src_=holder;[HrefToken(forceGlobal = TRUE)];adminplayerobservefollow=[REF(user)]'>FLW</a>)"
#define ADMIN_PP(user) "(<a href='byond://?_src_=holder;[HrefToken(forceGlobal = TRUE)];adminplayeropts=[REF(user)]'>PP</a>)"
#define ADMIN_SM(user) "(<a href='byond://?_src_=holder;[HrefToken(forceGlobal = TRUE)];subtlemessage=[REF(user)]'>SM</a>)"
#define ADMIN_SC(user) "(<A href='byond://?_src_=holder;[HrefToken(forceGlobal = TRUE)];adminspawncookie=\ref[src]'>SC</a>)"
#define ADMIN_VV(atom) "(<a href='byond://?_src_=vars;[HrefToken(forceGlobal = TRUE)];Vars=[REF(atom)]'>VV</a>)"
#define ADMIN_TP(user) "(<a href='byond://?_src_=holder;[HrefToken(forceGlobal = TRUE)];traitor=[REF(user)]'>TP</a>)"
#define ADMIN_LOOKUP(user) "[key_name_admin(user)][ADMIN_QUE(user)]"
#define ADMIN_LOOKUPFLW(user) "[key_name_admin(user)][ADMIN_QUE(user)] [ADMIN_FLW(user)]"
#define ADMIN_JMP(src) "(<a href='byond://?_src_=holder;[HrefToken(forceGlobal = TRUE)];adminplayerobservecoodjump=1;X=[src.x];Y=[src.y];Z=[src.z]'>JMP</a>)"
#define COORD(src) "[src ? src.Admin_Coordinates_Readable() : "nonexistent location"]"
#define AREACOORD(src) "[src ? src.Admin_Coordinates_Readable(TRUE) : "nonexistent location"]"
#define ADMIN_COORDJMP(src) "[src ? src.Admin_Coordinates_Readable(FALSE, TRUE) : "nonexistent location"]"
#define ADMIN_VERBOSEJMP(src) "[src ? src.Admin_Coordinates_Readable(TRUE, TRUE) : "nonexistent location"]"

#define ADMIN_FULLMONTY_NONAME(user) "[ADMIN_QUE(user)] [ADMIN_PP(user)] [ADMIN_VV(user)] [ADMIN_SM(user)] [ADMIN_FLW(user)] [ADMIN_TP(user)] [ADMIN_SC(user)]"
#define ADMIN_FULLMONTY(user) "[key_name_admin(user)] [ADMIN_FULLMONTY_NONAME(user)]"

/// for [/proc/check_asay_links], if there are any actionable refs in the asay message, this index in the return list contains the new message text to be printed
#define ASAY_LINK_NEW_MESSAGE_INDEX "!asay_new_message"
/// for [/proc/check_asay_links], if there are any admin pings in the asay message, this index in the return list contains a list of admins to ping
#define ASAY_LINK_PINGED_ADMINS_INDEX "!pinged_admins"

/atom/proc/Admin_Coordinates_Readable(area_name, admin_jump_ref)
	var/turf/T = Safe_COORD_Location()
	return T ? "[area_name ? "[get_area_name(T, TRUE)] " : " "]([T.x],[T.y],[T.z])[admin_jump_ref ? " [ADMIN_JMP(T)]" : ""]" : "nonexistent location"

/atom/proc/Safe_COORD_Location()
	var/atom/A = drop_location()
	if(!A)
		return //not a valid atom.
	var/turf/T = get_step(A, 0) //resolve where the thing is.
	if(!T) //incase it's inside a valid drop container, inside another container. ie if a mech picked up a closet and has it inside it's internal storage.
		var/atom/last_try = A.loc?.drop_location() //one last try, otherwise fuck it.
		if(last_try)
			T = get_step(last_try, 0)
	return T

/turf/Safe_COORD_Location()
	return src
