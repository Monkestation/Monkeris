/obj/item/organ_module/debugger
	name = "debug organ module"
	desc = "Embedded organ module."
	allowed_organs = BP_ALL_LIMBS

/obj/item/organ_module/debugger/onInstall(obj/item/organ/external/E)
	to_chat(usr, "Module installed")

/obj/item/organ_module/debugger/onRemove(obj/item/organ/external/E)
	to_chat(usr, "Module removed")

/obj/item/organ_module/debugger/organ_removed(obj/item/organ/external/E, mob/living/carbon/human/H)
	to_chat(usr, "Organ with module installed")

/obj/item/organ_module/debugger/organ_installed(obj/item/organ/external/E, mob/living/carbon/human/H)
	to_chat(usr, "Organ with module removed")

