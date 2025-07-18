/mob/living/simple_animal/hostile/syndicate
	name = "\improper Syndicate operative"
	desc = "Death to the Company."
	icon_state = "syndicate"
	icon_dead = "syndicate_dead" //TODO: That icon doesn't exist
	icon_gib = "syndicate_gib"
	speak_chance = 0
	turns_per_move = 5
	response_help = "pokes"
	response_disarm = "shoves"
	response_harm = "hits"
	speed = 4
	stop_automated_movement_when_pulled = 0
	maxHealth = 100
	health = 100
	harm_intent_damage = 5
	melee_damage_lower = 10
	melee_damage_upper = 10
	attacktext = "punched"
	a_intent = I_HURT
	var/corpse = /obj/landmark/corpse/syndicatesoldier
	var/weapon1
	var/weapon2
	min_oxy = 5
	max_oxy = 0
	min_tox = 0
	max_tox = 1
	min_co2 = 0
	max_co2 = 5
	min_n2 = 0
	max_n2 = 0
	unsuitable_atoms_damage = 15
	environment_smash = 1
	faction = "syndicate"
	status_flags = CANPUSH

/mob/living/simple_animal/hostile/syndicate/death()
	..()
	if(corpse)
		new corpse (src.loc)
	if(weapon1)
		new weapon1 (src.loc)
	if(weapon2)
		new weapon2 (src.loc)
	qdel(src)
	return

///////////////Sword and shield////////////

/mob/living/simple_animal/hostile/syndicate/melee
	melee_damage_lower = 20
	melee_damage_upper = 25
	icon_state = "syndicatemelee"
	weapon1 = /obj/item/melee/energy/sword/red
	weapon2 = /obj/item/shield/buckler/energy
	attacktext = "slashed"
	status_flags = 0

/mob/living/simple_animal/hostile/syndicate/melee/attackby(obj/item/O as obj, mob/user as mob)
	if(O.force)
		if(prob(80))
			var/damage = O.force
			if (O.damtype == HALLOSS)
				damage = 0
			health -= damage
			visible_message(span_red("\b [src] has been attacked with the [O] by [user]. "))
		else
			visible_message(span_red("\b [src] blocks the [O] with its shield! "))
		//user.do_attack_animation(src)
	else
		to_chat(usr, span_red("This weapon is ineffective, it does no damage."))
		visible_message(span_red("[user] gently taps [src] with the [O]. "))


/mob/living/simple_animal/hostile/syndicate/melee/bullet_act(obj/item/projectile/Proj)
	if(!Proj)	return
	if(prob(65))
		..()
	else
		visible_message(span_red("<B>[src] blocks [Proj] with its shield!</B>"))
	return 0


/mob/living/simple_animal/hostile/syndicate/melee/space
	min_oxy = 0
	max_oxy = 0
	min_tox = 0
	max_tox = 0
	min_co2 = 0
	max_co2 = 0
	min_n2 = 0
	max_n2 = 0
	minbodytemp = 0
	icon_state = "syndicatemeleespace"
	name = "Syndicate Commando"
	corpse = /obj/landmark/corpse/syndicatecommando
	speed = 0

/mob/living/simple_animal/hostile/syndicate/melee/space/allow_spacemove()
	return ..()

/mob/living/simple_animal/hostile/syndicate/ranged
	ranged = 1
	rapid = 1
	icon_state = "syndicateranged"
	casingtype = /obj/item/ammo_casing/pistol
	projectilesound = 'sound/weapons/Gunshot_light.ogg'
	projectiletype = /obj/item/projectile/bullet/pistol

	weapon1 = /obj/item/gun/projectile/automatic/c20r

/mob/living/simple_animal/hostile/syndicate/ranged/space
	icon_state = "syndicaterangedpsace"
	name = "Syndicate Commando"
	min_oxy = 0
	max_oxy = 0
	min_tox = 0
	max_tox = 0
	min_co2 = 0
	max_co2 = 0
	min_n2 = 0
	max_n2 = 0
	minbodytemp = 0
	corpse = /obj/landmark/corpse/syndicatecommando
	speed = 0

/mob/living/simple_animal/hostile/syndicate/ranged/space/allow_spacemove()
	return ..()



/mob/living/simple_animal/hostile/viscerator
	name = "viscerator"
	desc = "A small, twin-bladed machine capable of inflicting very deadly lacerations."
	icon = 'icons/mob/critter.dmi'
	icon_state = "viscerator_attack"
	pass_flags = PASSTABLE
	health = 50
	maxHealth = 50
	melee_damage_lower = 20
	melee_damage_upper = 20
	attacktext = "cut"
	attack_sound = 'sound/weapons/bladeslice.ogg'
	faction = "syndicate"
	min_oxy = 0
	max_oxy = 0
	min_tox = 0
	max_tox = 0
	min_co2 = 0
	max_co2 = 0
	min_n2 = 0
	max_n2 = 0
	minbodytemp = 0

/mob/living/simple_animal/hostile/viscerator/emp_act(severity)
	health -= 60*severity
/mob/living/simple_animal/hostile/viscerator/death()
	..(null,"is smashed into pieces!")
	qdel(src)
