/datum/component/butchering
	/// Whether or not this component can be used to butcher currently. Used to temporarily disable an existing butcher component for later
	var/butchering_enabled = TRUE

	/// Whether or not this component is compatible with blunt tools.
	var/can_be_blunt = FALSE

/datum/component/butchering/Initialize(
	disabled = FALSE,
	can_be_blunt = FALSE,
)
	if(disabled)
		src.butchering_enabled = FALSE
	src.can_be_blunt = can_be_blunt
	if(isitem(parent))
		RegisterSignal(parent, COMSIG_IATTACK, PROC_REF(onItemAttack))
		RegisterSignal(parent, COMSIG_APPVAL, PROC_REF(onStatusChange))

///checks if we can butcher, and intercepts the attack chain if we successfully do so
/datum/component/butchering/proc/onItemAttack(atom/target, mob/living/user, params)
	SIGNAL_HANDLER
	var/obj/item/ourparent
	if(isitem(parent))
		ourparent = parent

	if(!(user.a_intent == I_HURT))//are we on harm intent?
		return

	if(isliving(target))
		var/mob/living/ourmob = target
		if(ourmob.stat == DEAD && (ourmob.butcher_results)) //can we butcher it?
			if(butchering_enabled && (can_be_blunt || ourparent.sharp))
				INVOKE_ASYNC(src, PROC_REF(startButcher), ourparent, ourmob, user)
				return TRUE //ends attack chain, so all we do is butcher
	return

///handles the use tool containing our butchering action. needed since signal_handler procs hate do afters
/datum/component/butchering/proc/startButcher(obj/item/source, mob/living/meat, mob/living/user)
	to_chat(user, span_notice("You begin to butcher \the [meat]..."))
	var/needed_quality = QUALITY_CUTTING
	if(!source.has_quality(QUALITY_CUTTING))
		needed_quality = null
	if(source.use_tool(user, meat, WORKTIME_NORMAL, needed_quality, FAILCHANCE_NORMAL, required_stat = STAT_BIO))
		on_butchering(user, meat, source)
/**
 * Handles a user butchering a target
 *
 * Arguments:
 * - [butcher][/mob/living]: The mob doing the butchering
 * - [meat][/mob/living]: The mob being butchered
 * - [source][/obj/item]: The item holding our component, expressly typed
 */
/datum/component/butchering/proc/on_butchering(mob/living/butcher, mob/living/meat, obj/item/source)
	//our final items to spawn
	var/list/butchered = list()
	//did we fail to extract something?
	var/mulched
	var/turf/dropturf = get_turf(meat)
	var/bio = butcher.stats.getStat(STAT_BIO)
	//mult to success chance based on tool quality
	var/toolpowr = 0.5

	if(source.has_quality(QUALITY_CUTTING))//otherwise, we're working with something stupid like a glass shard or a beartrap(truly, advanced cutting tool)
		toolpowr = round((source.get_tool_quality(QUALITY_CUTTING) / 10))

	if(!meat.butcher_results)
		log_runtime(" [meat.type] was butchered without any possible butcher results.")
		meat.gib()

	//for getting the dialogue hinting at relative power
	var/msgpowr = toolpowr * (max((bio / 35), 0.25))
	switch(msgpowr)
		if(0 to 0.8)//go get an actual knife you gross-ass roundstart vagabond
			butcher.visible_message(span_bolddanger("[butcher] can't get anywhere with this tool! Instead, they rip \the [meat] to shreds like an animal!"))
		if(0.9 to 3.5)
			butcher.visible_message(span_danger("[butcher] messily chops up \the [meat]!"))
		if(3.6 to 6)
			butcher.visible_message(span_danger("[butcher] carefully butchers \the [meat]."))
		if(6.1 to 99)
			butcher.visible_message(span_notice("[butcher] precisely dissects \the [meat]."))

	// Chance of triggering an additional hazard effect when butchering an animal.
	var/hazard_chance = 5
	for(var/thing in meat.butcher_results)
		var/obj/result = thing
		//get the base percentage of awarding this result
		var/difficulty = meat.butcher_results[result]
		//takes difficulty and multiplies it by tool and bio stat to get final chance
		var/trueprob = clamp((difficulty * toolpowr) * max((bio / 35), 0.25), 1, 100)
		if(prob(trueprob))
			butchered += result
		else
			mulched++
			hazard_chance = hazard_chance + 10//chance of complications increases for each item you fail to harvest

	if(mulched)
		to_chat(butcher, span_warning("You [LAZYLEN(meat.butcher_results) <= mulched ? "completely destroyed all of" : "lost some of"] the meat from \the [meat]."))

	if(LAZYLEN(butchered))
		for(var/reward in butchered)
			var/obj/item/ourmeat = new reward(dropturf)
			ourmeat.name = "[meat.name] [ourmeat.name]"

	//try to invoke a hazard effect on the butcher
	if(meat.butchery_hazard && prob(hazard_chance))
		butcher.visible_message(span_danger("While cutting up \the [src], [butcher]'s hand slips..."), span_danger("While cutting up \the [src], your hand slips..."))
		meat.butchery_fail(butcher)

	//let's finish up.
	meat.drop_embedded()
	meat.gib()
	if(meat.client)//if a player just got hardgibbed, tattle
		message_admins("[meat] ([key_name(meat)]) was butchered for meat by [butcher] ([key_name(butcher)]) [ADMIN_JMP(butcher)].")

///Enables the butchering mechanic.
/datum/component/butchering/proc/enable_butchering(datum/source)
	SIGNAL_HANDLER
	butchering_enabled = TRUE

///Disables the butchering mechanic.
/datum/component/butchering/proc/disable_butchering(datum/source)
	SIGNAL_HANDLER
	butchering_enabled = FALSE

///signal check to see if our holder is still sharp, for variable butchering items. If not, shut down the component till sharpness comes back.
/datum/component/butchering/proc/onStatusChange(atom/holder)
	SIGNAL_HANDLER
	if(isitem(holder))
		var/obj/item/itemholder = holder
		if(!itemholder.sharp && !can_be_blunt)
			disable_butchering()
		else if(itemholder.sharp && butchering_enabled == FALSE)
			enable_butchering()
