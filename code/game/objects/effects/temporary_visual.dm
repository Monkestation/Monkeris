//temporary visual effects
/obj/effect/temp_visual
	icon_state = "nothing"
	anchored = TRUE
	layer = ABOVE_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	unacidable = 1
	var/duration = 10 //in deciseconds
	var/randomdir = TRUE

/obj/effect/temp_visual/Initialize()
	. = ..()
	if(randomdir)
		dir = (pick(GLOB.cardinal))

	QDEL_IN(src, duration)

/obj/effect/temp_visual/Destroy()
	. = ..()

/obj/effect/temp_visual/singularity_act()
	return

/obj/effect/temp_visual/singularity_pull()
	return

/obj/effect/temp_visual/explosion_act(target_power, datum/explosion_handler/handler)
	return 0

/obj/effect/temp_visual/dir_setting
	randomdir = FALSE

/obj/effect/temp_visual/dir_setting/Initialize(mapload, set_dir)
	if(set_dir)
		dir = set_dir
	. = ..()

/obj/effect/temp_visual/long //temp visual with longer duration
	randomdir = FALSE
	duration = 25

/obj/effect/temp_visual/space_warp
	icon = 'icons/effects/light_overlays/light_128.dmi'
	icon_state = "light"
	plane = GRAVITY_PULSE_PLANE
	pixel_x = -48
	pixel_y = -48
	duration = 4

/obj/effect/temp_visual/space_warp/Initialize()
	. = ..()
	animate(src, time=duration, transform=matrix().Scale(0.1,0.1))


/atom/movable/static_distortion
	plane = GRAVITY_PULSE_PLANE
	appearance_flags = PIXEL_SCALE|LONG_GLIDE // no tile bound so you can see it around corners and so
	icon = 'icons/effects/light_overlays/light_352.dmi'
	icon_state = "light"
	pixel_x = -176
	pixel_y = -176

/obj/effect/temp_visual/blink_drive
	icon = 'icons/effects/light_overlays/light_128.dmi'
	icon_state = "light"
	plane = GRAVITY_PULSE_PLANE
	duration = 8
	appearance_flags = PIXEL_SCALE|LONG_GLIDE

/obj/effect/temp_visual/blink_drive/Initialize(mapload)
	. = ..()
	var/image/I = image(icon, src, icon_state, 10, pixel_x = -48, pixel_y = -48)
	overlays += I //we use an overlay so the icon and light source are both in the correct location
	icon_state = null
	animate(src, time=duration, transform=matrix().Scale(0.1,0.1))
	set_light(2, 2, COLOR_LIGHTING_BLUE_DARK)

/obj/effect/temp_visual/bluespace_pulse
	icon = 'icons/effects/light_overlays/light_320.dmi'
	icon_state = "light"
	plane = GRAVITY_PULSE_PLANE
	duration = 4

/obj/effect/temp_visual/bluespace_pulse/Initialize(mapload)
	. = ..()
	var/image/I = image(icon, src, icon_state, 10, pixel_x = -144, pixel_y = -144)
	overlays += I //we use an overlay so the icon and light source are both in the correct location
	icon_state = null
	animate(src, time=(duration+0.1), transform=matrix().Scale(0.1,0.1))
	set_light(4, 4, COLOR_LIGHTING_BLUE_DARK)


/**
 * Visual shockwave effect using a displacement filter applied to the game world plate
 * Args:
 * * radius: visual max radius of the effect
 * * speed_rate: propagation rate of the effect as a ratio (0.5 is twice as fast)
 * * easing_type: easing type to use in the anim
 * * y_offset: additional pixel_y offsets
 * * x_offset: additional pixel_x offsets
 */
/obj/effect/temp_visual/shockwave
	icon = 'icons/effects/light_overlays/shockwave.dmi'
	icon_state = "shockwave"
	plane = GRAVITY_PULSE_PLANE
	pixel_x = -496
	pixel_y = -496

/obj/effect/temp_visual/shockwave/Initialize(mapload, radius=12, direction, speed_rate=1, easing_type = LINEAR_EASING, y_offset=0, x_offset=0)
	. = ..()
	pixel_x += x_offset
	pixel_y += y_offset
	duration = 0.5 * radius * speed_rate
	transform = matrix().Scale(32 / 1024, 32 / 1024)
	animate(src, time = 1/2 * radius * speed_rate, transform=matrix().Scale((32 / 1024) * radius * 1.5, (32 / 1024) * radius * 1.5), easing=easing_type)
