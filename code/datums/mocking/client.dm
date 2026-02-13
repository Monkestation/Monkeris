/// This should match the interface of /client wherever necessary.
/datum/client_interface
	/// Player preferences datum for the client
	var/datum/preferences/prefs

	/// The view of the client, similar to /client/var/view.
	var/view = "15x15"

	/// Objects on the screen of the client
	var/list/screen = list()

	/// The mob the client controls
	var/mob/mob

	/// The key for this mock interface
	var/key = "mockclient"

/datum/client_interface/proc/get_exp_living(pure_numeric = FALSE)
	if(!prefs?.exp?[EXP_TYPE_LIVING])
		return pure_numeric ? 0 : "No data"
	var/exp_living = text2num(prefs.exp[EXP_TYPE_LIVING])
	return pure_numeric ? exp_living : get_exp_format(exp_living)

// /datum/client_interface/proc/operator""()
// 	return "[key]"
