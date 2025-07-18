// Attempts to offload processing for the spreading plants from the MC.
// Processes vines/spreading plants.

#define PLANTS_PER_TICK 500 // Cap on number of plant segments processed.
#define PLANT_TICK_TIME 75  // Number of ticks between the plant processor cycling.

// Debug for testing seed genes.
/client/proc/show_plant_genes()
	set category = "Debug"
	set name = "Show Plant Genes"
	set desc = "Prints the round's plant gene masks."

	if(!holder)	return

	if(!SSplants || !SSplants.gene_tag_masks)
		to_chat(usr, "Gene masks not set.")
		return

	for(var/mask in SSplants.gene_tag_masks)
		to_chat(usr, "[mask]: [SSplants.gene_tag_masks[mask]]")

SUBSYSTEM_DEF(plants)
	name = "Plants"
	priority = FIRE_PRIORITY_PLANTS
	init_order = INIT_ORDER_PLANTS
	flags = SS_TICKER
	wait = PLANT_TICK_TIME

	var/plants_per_tick = PLANTS_PER_TICK
	var/plant_tick_time = PLANT_TICK_TIME
	var/list/product_descs = list()         // Stores generated fruit descs.
	var/list/plant_queue = list()           // All queued plants.
	var/list/seeds = list()                 // All seed data stored here.
	var/list/gene_tag_masks = list()        // Gene obfuscation for delicious trial and error goodness.
	var/list/plant_icon_cache = list()      // Stores images of growth, fruits and seeds.
	var/list/plant_sprites = list()         // List of all harvested product sprites.
	var/list/plant_product_sprites = list() // List of all growth sprites plus number of growth stages.

	var/processed = 0                      // something something. plants processed counter?

/datum/controller/subsystem/plants/New()
	if(SSplants && SSplants != src)
		log_debug("Rebuilding plant controller.")
		qdel(SSplants)
	SSplants = src

// Predefined/roundstart varieties use a string key to make it
// easier to grab the new variety when mutating. Post-roundstart
// and mutant varieties use their uid converted to a string instead.
// Looks like shit but it's sort of necessary.
/datum/controller/subsystem/plants/Initialize()
	// Build the icon lists.
	for(var/icostate in icon_states('icons/obj/hydroponics_growing.dmi'))
		var/split = findtext(icostate,"-")
		if(!split)
			// invalid icon_state
			continue

		var/ikey = copytext(icostate,(split+1))
		if(ikey == "dead")
			// don't count dead icons
			continue
		ikey = text2num(ikey)
		var/base = copytext(icostate,1,split)

		if(!(plant_sprites[base]) || (plant_sprites[base]<ikey))
			plant_sprites[base] = ikey

	for(var/icostate in icon_states('icons/obj/hydroponics_products.dmi'))
		var/split = findtext(icostate,"-")
		if(split)
			plant_product_sprites |= copytext(icostate,1,split)

	// Populate the global seed datum list.
	for(var/type in typesof(/datum/seed)-/datum/seed)
		var/datum/seed/S = new type
		seeds[S.name] = S
		S.uid = "[seeds.len]"
		S.roundstart = 1

	// Make sure any seed packets that were mapped in are updated
	// correctly (since the seed datums did not exist a tick ago).
	for(var/obj/item/seeds/S in world)
		S.update_seed()

	//Might as well mask the gene types while we're at it.
	var/list/used_masks = list()
	var/list/plant_traits = ALL_GENES
	while(plant_traits && plant_traits.len)
	//very ugly, but easyer then having to code dive into gene extractor aswel, for now
		var/gene_tag = pick(plant_traits)
		var/gene_mask = gene_tag

		while(gene_mask in used_masks)
			gene_mask = gene_tag

		used_masks += gene_mask
		plant_traits -= gene_tag
		gene_tag_masks[gene_tag] = gene_mask
	..()

// Proc for creating a random seed type.
/datum/controller/subsystem/plants/proc/create_random_seed(survive_on_station)
	var/datum/seed/seed = new()
	seed.randomize()
	seed.uid = SSplants.seeds.len + 1
	seed.name = "[seed.uid]"
	seeds[seed.name] = seed

	if(survive_on_station)
		if(seed.consume_gasses)
			seed.consume_gasses["plasma"] = null
			seed.consume_gasses["carbon_dioxide"] = null
		if(seed.chems && !isnull(seed.chems["pacid"]))
			seed.chems["pacid"] = null // Eating through the hull will make these plants completely inviable, albeit very dangerous.
			seed.chems -= null // Setting to null does not actually remove the entry, which is weird.
		seed.set_trait(TRAIT_IDEAL_HEAT,293)
		seed.set_trait(TRAIT_HEAT_TOLERANCE,20)
		seed.set_trait(TRAIT_IDEAL_LIGHT,8)
		seed.set_trait(TRAIT_LIGHT_TOLERANCE,5)
		seed.set_trait(TRAIT_LOWKPA_TOLERANCE,25)
		seed.set_trait(TRAIT_HIGHKPA_TOLERANCE,200)
	return seed

/datum/controller/subsystem/plants/fire()
	if(plant_queue.len)
		var/target_to_process = min(plant_queue.len,plants_per_tick)
		for(var/x=0;x<target_to_process;x++)
			if(!plant_queue.len)
				break
			var/obj/effect/plant/plant = pick(plant_queue)
			plant_queue -= plant
			if(!istype(plant))
				continue
			plant.Process()
			processed++

/datum/controller/subsystem/plants/proc/add_plant(obj/effect/plant/plant)
	plant_queue |= plant

/datum/controller/subsystem/plants/proc/remove_plant(obj/effect/plant/plant)
	plant_queue -= plant
