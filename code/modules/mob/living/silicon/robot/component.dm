// TODO: remove the robot.mmi and robot.cell variables and completely rely on the robot component system
/datum/robot_component
	var/name
	var/installed = 0
	var/powered = 0
	var/toggled = 1
	var/brute_damage = 0
	var/electronics_damage = 0
	var/idle_usage = 0   // Amount of power used every MC tick. In joules.
	var/active_usage = 0 // Amount of power used for every action. Actions are module-specific. Actuator for each tile moved, etc.
	var/max_damage = 30  // HP of this component.
	var/mob/living/silicon/robot/owner
	var/installed_by_default = TRUE
	var/robot_trait = null // a cyborg trait to add when this is installed
	var/powered_trait = FALSE // does this module need to be powered for its trait to be active ?


// The actual device object that has to be installed for this.
/datum/robot_component/var/external_type = null

// The wrapped device(e.g. radio), only set if external_type isn't null
/datum/robot_component/var/obj/item/wrapped = null

/datum/robot_component/New(mob/living/silicon/robot/R)
	src.owner = R

/datum/robot_component/proc/install()
	if(!powered_trait)
		owner.AddTrait(robot_trait)
	else
		update_power_state()

/datum/robot_component/proc/uninstall()
	owner.RemoveTrait(robot_trait)

/datum/robot_component/proc/destroy()
	// The thing itself isn't there anymore, but some fried remains are.
	if(wrapped)
		var/obj/item/trash_item = new /obj/item/trash/broken_robot_part

		trash_item.icon = wrapped.icon
		trash_item.matter = wrapped.matter.Copy()
		trash_item.name = "broken [wrapped.name]"
		trash_item.w_class = wrapped.w_class
		if(istype(wrapped, /obj/item/robot_parts/robot_component))
			var/obj/item/robot_parts/robot_component/comp = wrapped
			trash_item.icon_state = comp.icon_state_broken // Module-specific broken icons! Yay!
		else
			trash_item.icon_state = wrapped.icon_state

		qdel(wrapped)
		wrapped = trash_item

	installed = -1
	uninstall()

/datum/robot_component/proc/take_damage(brute, electronics, sharp, edge)
	if(installed != TRUE) return

	brute_damage += brute
	electronics_damage += electronics

	if(brute_damage + electronics_damage >= max_damage) destroy()

/datum/robot_component/proc/heal_damage(brute, electronics)
	if(installed != TRUE)
		// If it's not installed, can't repair it.
		return 0

	brute_damage = max(0, brute_damage - brute)
	electronics_damage = max(0, electronics_damage - electronics)

/datum/robot_component/proc/is_powered()
	return (installed == TRUE) && (brute_damage + electronics_damage < max_damage) && (!idle_usage || powered)

/datum/robot_component/proc/update_power_state()
	if(toggled == FALSE)
		powered = FALSE
		if(powered_trait && robot_trait)
			owner.RemoveTrait(robot_trait)
		return
	if(owner.cell && owner.cell.charge >= idle_usage)
		owner.cell_use_power(idle_usage)
		powered = TRUE
		if(powered_trait && robot_trait)
			owner.AddTrait(robot_trait)
	else
		powered = FALSE
		if(powered_trait && robot_trait)
			owner.RemoveTrait(robot_trait)


// ARMOUR
// Protects the cyborg from damage. Usually first module to be hit
// No power usage
/datum/robot_component/armour
	name = "armour plating"
	external_type = /obj/item/robot_parts/robot_component/armour
	max_damage = 60



// JETPACK
// Allows the cyborg to move in space
// Uses no power when idle. Uses 50J for each tile the cyborg moves.
/datum/robot_component/jetpack
	name = "jetpack"
	external_type = /obj/item/robot_parts/robot_component/jetpack
	max_damage = 60
	installed_by_default = FALSE
	active_usage = 150

	var/obj/item/tank/jetpack/synthetic/tank = null


/datum/robot_component/jetpack/install()
	..()
	tank = new/obj/item/tank/jetpack/synthetic
	//owner.internals = tank
	tank.forceMove(owner)
	owner.jetpack = tank
	tank.component = src

/datum/robot_component/jetpack/uninstall()
	..()
	qdel(tank)
	tank = null
	owner.jetpack = null

//Uses power when the tank is compressing air to refill itself
/datum/robot_component/jetpack/update_power_state()
	if(tank && tank.compressing)
		idle_usage = active_usage
	else
		idle_usage = 0
	.=..()





// ACTUATOR
// Enables movement.
/datum/robot_component/actuator
	name = "actuator"
	idle_usage = 0
	active_usage = 100
	external_type = /obj/item/robot_parts/robot_component/actuator
	max_damage = 50


//A fixed and much cleaner implementation of /tg/'s special snowflake code.
/datum/robot_component/actuator/is_powered()
	return (installed == 1) && (brute_damage + electronics_damage < max_damage)


// POWER CELL
// Stores power (how unexpected..)
// No power usage
/datum/robot_component/cell
	name = "power cell"
	max_damage = 50

/datum/robot_component/cell/destroy()
	..()
	owner.cell = null


// RADIO
// Enables radio communications
// Uses no power when idle. Uses 10J for each received radio message, 50 for each transmitted message.
/datum/robot_component/radio
	name = "radio"
	external_type = /obj/item/robot_parts/robot_component/radio
	idle_usage = 15		//it's not actually possible to tell when we receive a message over our radio, so just use 10W every tick for passive listening
	active_usage = 75	//transmit power
	max_damage = 40


// BINARY RADIO
// Enables binary communications with other cyborgs/AIs
// Uses no power when idle. Uses 10J for each received radio message, 50 for each transmitted message
/datum/robot_component/binary_communication
	name = "binary communication device"
	external_type = /obj/item/robot_parts/robot_component/binary_communication_device
	idle_usage = 5
	active_usage = 25
	max_damage = 30


// CAMERA
// Enables cyborg vision. Can also be remotely accessed via consoles.
// Uses 10J constantly
/datum/robot_component/camera
	name = "camera"
	external_type = /obj/item/robot_parts/robot_component/camera
	idle_usage = 10
	max_damage = 40
	var/obj/machinery/camera/camera

/datum/robot_component/camera/New(mob/living/silicon/robot/R)
	..()
	camera = R.camera

/datum/robot_component/camera/update_power_state()
	..()
	if (camera)
		camera.status = powered

/datum/robot_component/camera/install()
	if (camera)
		camera.status = 1

/datum/robot_component/camera/uninstall()
	if (camera)
		camera.status = 0

/datum/robot_component/camera/destroy()
	if (camera)
		camera.status = 0

// SELF DIAGNOSIS MODULE
// Analyses cyborg's modules, providing damage readouts and basic information
// Uses 1kJ burst when analysis is done
/datum/robot_component/diagnosis_unit
	name = "self-diagnosis unit"
	active_usage = 1000
	external_type = /obj/item/robot_parts/robot_component/diagnosis_unit
	max_damage = 30




// HELPER STUFF



// Initializes cyborg's components. Technically, adds default set of components to new borgs
/mob/living/silicon/robot/proc/initialize_components()
	components["actuator"] = new/datum/robot_component/actuator(src)
	components["radio"] = new/datum/robot_component/radio(src)
	components["power cell"] = new/datum/robot_component/cell(src)
	components["diagnosis unit"] = new/datum/robot_component/diagnosis_unit(src)
	components["camera"] = new/datum/robot_component/camera(src)
	components["comms"] = new/datum/robot_component/binary_communication(src)
	components["armour"] = new/datum/robot_component/armour(src)
	components["jetpack"] = new/datum/robot_component/jetpack(src)

// Checks if component is functioning
/mob/living/silicon/robot/proc/is_component_functioning(module_name)
	var/datum/robot_component/C = components[module_name]
	return C && C.installed == 1 && C.toggled && C.is_powered()

// Returns component by it's string name
/mob/living/silicon/robot/proc/get_component(component_name)
	var/datum/robot_component/C = components[component_name]
	return C



// COMPONENT OBJECTS



// Component Objects
// These objects are visual representation of modules

// Spawned when a robot component breaks
// Has default name/icon/materials, replaced by the component itself when it breaks
/obj/item/trash/broken_robot_part
	name = "broken actuator"
	desc = "A robot part, broken beyond repair. Can be recycled in an autolathe."
	icon = 'icons/obj/robot_component.dmi'
	icon_state = "motor_broken"
	matter = list(MATERIAL_STEEL = 5)

/obj/item/robot_parts/robot_component
	icon = 'icons/obj/robot_component.dmi'
	icon_state = "working"
	var/icon_state_broken = "broken"
	matter = list(MATERIAL_STEEL = 5)

	var/brute = 0
	var/burn = 0
	var/total_dam = 0
	var/max_dam = 30

/obj/item/robot_parts/robot_component/take_damage(brute_amt, burn_amt)
	brute += brute_amt
	burn += burn_amt
	total_dam = brute+burn
	if(total_dam >= max_dam)
		var/obj/item/electronics/circuitboard/broken/broken_device = new (get_turf(src))
		if(icon_state_broken != "broken")
			broken_device.icon = icon
			broken_device.icon_state = icon_state_broken
		broken_device.name = "broken [name]"
		return broken_device
	return 0

/obj/item/robot_parts/robot_component/proc/is_functional()
	return ((brute + burn) < max_dam)

/obj/item/robot_parts/robot_component/binary_communication_device
	name = "binary communication device"
	icon_state = "binradio"
	icon_state_broken = "binradio_broken"

/obj/item/robot_parts/robot_component/actuator
	name = "actuator"
	icon_state = "motor"
	icon_state_broken = "motor_broken"

/obj/item/robot_parts/robot_component/armour
	name = "armour plating"
	icon_state = "armor"
	icon_state_broken = "armor_broken"

/obj/item/robot_parts/robot_component/camera
	name = "camera"
	icon_state = "camera"
	icon_state_broken = "camera_broken"

/obj/item/robot_parts/robot_component/diagnosis_unit
	name = "diagnosis unit"
	icon_state = "analyser"
	icon_state_broken = "analyser_broken"

/obj/item/robot_parts/robot_component/radio
	name = "radio"
	icon_state = "radio"
	icon_state_broken = "radio_broken"

/obj/item/robot_parts/robot_component/jetpack
	name = "jetpack"
	desc = "Self refilling jetpack that makes the unit suitable for EVA work."
	icon = 'icons/obj/tank.dmi'
	icon_state = "jetpack-black"
	icon_state_broken = "jetpack-black"
	matter = list(MATERIAL_STEEL = 10, MATERIAL_PLASMA = 10, MATERIAL_SILVER = 20)
	spawn_tags = SPAWN_TAG_JETPACK
	rarity_value = 66.66
