#define ICON_NOT_SET "Not Set"

//This is stored as a nested list instead of datums or whatever because it json encodes nicely for usage in tgui
GLOBAL_LIST_INIT(master_filter_info, list(
	"alpha" = list(
		"defaults" = list(
			"x" = 0,
			"y" = 0,
			"icon" = ICON_NOT_SET,
			"render_source" = "",
			"flags" = 0
		),
		"flags" = list(
			"MASK_INVERSE" = MASK_INVERSE,
			"MASK_SWAP" = MASK_SWAP
		)
	),
	"angular_blur" = list(
		"defaults" = list(
			"x" = 0,
			"y" = 0,
			"size" = 1
		)
	),
	/* Not supported because making a proper matrix editor on the frontend would be a huge dick pain.
		Uncomment if you ever implement it
	"color" = list(
		"defaults" = list(
			"color" = matrix(),
			"space" = FILTER_COLOR_RGB
		)
	),
	*/
	"displace" = list(
		"defaults" = list(
			"x" = 0,
			"y" = 0,
			"size" = null,
			"icon" = ICON_NOT_SET,
			"render_source" = ""
		)
	),
	"drop_shadow" = list(
		"defaults" = list(
			"x" = 1,
			"y" = -1,
			"size" = 1,
			"offset" = 0,
			"color" = COLOR_HALF_TRANSPARENT_BLACK
		)
	),
	"blur" = list(
		"defaults" = list(
			"size" = 1
		)
	),
	"layer" = list(
		"defaults" = list(
			"x" = 0,
			"y" = 0,
			"icon" = ICON_NOT_SET,
			"render_source" = "",
			"flags" = FILTER_OVERLAY,
			"color" = "",
			"transform" = null,
			"blend_mode" = BLEND_DEFAULT
		)
	),
	"motion_blur" = list(
		"defaults" = list(
			"x" = 0,
			"y" = 0
		)
	),
	"outline" = list(
		"defaults" = list(
			"size" = 0,
			"color" = COLOR_BLACK,
			"flags" = NONE
		),
		"flags" = list(
			"OUTLINE_SHARP" = OUTLINE_SHARP,
			"OUTLINE_SQUARE" = OUTLINE_SQUARE
		)
	),
	"radial_blur" = list(
		"defaults" = list(
			"x" = 0,
			"y" = 0,
			"size" = 0.01
		)
	),
	"rays" = list(
		"defaults" = list(
			"x" = 0,
			"y" = 0,
			"size" = 16,
			"color" = COLOR_WHITE,
			"offset" = 0,
			"density" = 10,
			"threshold" = 0.5,
			"factor" = 0,
			"flags" = FILTER_OVERLAY | FILTER_UNDERLAY
		),
		"flags" = list(
			"FILTER_OVERLAY" = FILTER_OVERLAY,
			"FILTER_UNDERLAY" = FILTER_UNDERLAY
		)
	),
	"ripple" = list(
		"defaults" = list(
			"x" = 0,
			"y" = 0,
			"size" = 1,
			"repeat" = 2,
			"radius" = 0,
			"falloff" = 1,
			"flags" = NONE
		),
		"flags" = list(
			"WAVE_BOUNDED" = WAVE_BOUNDED
		)
	),
	"wave" = list(
		"defaults" = list(
			"x" = 0,
			"y" = 0,
			"size" = 1,
			"offset" = 0,
			"flags" = NONE
		),
		"flags" = list(
			"WAVE_SIDEWAYS" = WAVE_SIDEWAYS,
			"WAVE_BOUNDED" = WAVE_BOUNDED
		)
	)
))

#undef ICON_NOT_SET

//Helpers to generate lists for filter helpers
//This is the only practical way of writing these that actually produces sane lists
/proc/alpha_mask_filter(x, y, icon/icon, render_source, flags)
	. = list("type" = "alpha")
	if(!isnull(x))
		.["x"] = x
	if(!isnull(y))
		.["y"] = y
	if(!isnull(icon))
		.["icon"] = icon
	if(!isnull(render_source))
		.["render_source"] = render_source
	if(!isnull(flags))
		.["flags"] = flags

/proc/angular_blur_filter(x, y, size)
	. = list("type" = "angular_blur")
	if(!isnull(x))
		.["x"] = x
	if(!isnull(y))
		.["y"] = y
	if(!isnull(size))
		.["size"] = size

/proc/color_matrix_filter(matrix/in_matrix, space)
	. = list("type" = "color")
	.["color"] = in_matrix
	if(!isnull(space))
		.["space"] = space

/proc/displacement_map_filter(icon, render_source, x, y, size = 32)
	. = list("type" = "displace")
	if(!isnull(icon))
		.["icon"] = icon
	if(!isnull(render_source))
		.["render_source"] = render_source
	if(!isnull(x))
		.["x"] = x
	if(!isnull(y))
		.["y"] = y
	if(!isnull(size))
		.["size"] = size

/proc/drop_shadow_filter(x, y, size, offset, color)
	. = list("type" = "drop_shadow")
	if(!isnull(x))
		.["x"] = x
	if(!isnull(y))
		.["y"] = y
	if(!isnull(size))
		.["size"] = size
	if(!isnull(offset))
		.["offset"] = offset
	if(!isnull(color))
		.["color"] = color

/proc/gauss_blur_filter(size)
	. = list("type" = "blur")
	if(!isnull(size))
		.["size"] = size

/proc/layering_filter(icon, render_source, x, y, flags, color, transform, blend_mode)
	. = list("type" = "layer")
	if(!isnull(icon))
		.["icon"] = icon
	if(!isnull(render_source))
		.["render_source"] = render_source
	if(!isnull(x))
		.["x"] = x
	if(!isnull(y))
		.["y"] = y
	if(!isnull(color))
		.["color"] = color
	if(!isnull(flags))
		.["flags"] = flags
	if(!isnull(transform))
		.["transform"] = transform
	if(!isnull(blend_mode))
		.["blend_mode"] = blend_mode

/proc/motion_blur_filter(x, y)
	. = list("type" = "motion_blur")
	if(!isnull(x))
		.["x"] = x
	if(!isnull(y))
		.["y"] = y

/proc/outline_filter(size, color, flags)
	. = list("type" = "outline")
	if(!isnull(size))
		.["size"] = size
	if(!isnull(color))
		.["color"] = color
	if(!isnull(flags))
		.["flags"] = flags

/proc/radial_blur_filter(size, x, y)
	. = list("type" = "radial_blur")
	if(!isnull(size))
		.["size"] = size
	if(!isnull(x))
		.["x"] = x
	if(!isnull(y))
		.["y"] = y

/proc/rays_filter(size, color, offset, density, threshold, factor, x, y, flags)
	. = list("type" = "rays")
	if(!isnull(size))
		.["size"] = size
	if(!isnull(color))
		.["color"] = color
	if(!isnull(offset))
		.["offset"] = offset
	if(!isnull(density))
		.["density"] = density
	if(!isnull(threshold))
		.["threshold"] = threshold
	if(!isnull(factor))
		.["factor"] = factor
	if(!isnull(x))
		.["x"] = x
	if(!isnull(y))
		.["y"] = y
	if(!isnull(flags))
		.["flags"] = flags

/proc/ripple_filter(radius, size, falloff, repeat, x, y, flags)
	. = list("type" = "ripple")
	if(!isnull(radius))
		.["radius"] = radius
	if(!isnull(size))
		.["size"] = size
	if(!isnull(falloff))
		.["falloff"] = falloff
	if(!isnull(repeat))
		.["repeat"] = repeat
	if(!isnull(flags))
		.["flags"] = flags
	if(!isnull(x))
		.["x"] = x
	if(!isnull(y))
		.["y"] = y

/proc/wave_filter(x, y, size, offset, flags)
	. = list("type" = "wave")
	if(!isnull(size))
		.["size"] = size
	if(!isnull(x))
		.["x"] = x
	if(!isnull(y))
		.["y"] = y
	if(!isnull(offset))
		.["offset"] = offset
	if(!isnull(flags))
		.["flags"] = flags



//filter procs & elements, including distortion elements(using the distortion filter on the game plate. See render_plate.dm)


///produces a heavy warping effect that displaces an object across multiple axes simutaneously.
///incredibly necrotic old code I don't fully understand. But tg uses it so it must be fine :D
/atom/proc/apply_wibbly_filters(length)
	for(var/i in 1 to 7)
		//This is a very baffling and strange way of doing this but I am just preserving old functionality
		var/X
		var/Y
		var/rsq
		do
			X = 60*rand() - 30
			Y = 60*rand() - 30
			rsq = X*X + Y*Y
		while(rsq<100 || rsq>900) // Yeah let's just loop infinitely due to bad luck what's the worst that could happen?
		var/random_roll = rand()
		add_filter("wibbly-[i]", 5, wave_filter(x = X, y = Y, size = rand() * 2.5 + 0.5, offset = random_roll))
		var/filter = get_filter("wibbly-[i]")
		animate(filter, offset = random_roll, time = 0, loop = -1, flags = ANIMATION_PARALLEL)
		animate(offset = random_roll - 1, time = rand() * 20 + 10)

///removes the 'wibbling' effect(see apply_wibbly_filters)
/atom/proc/remove_wibbly_filters()
	var/filter
	for(var/i in 1 to 7)
		filter = get_filter("wibbly-[i]")
		animate(filter)
		remove_filter("wibbly-[i]")

///normal map used for advanced wibbling
/obj/effect/abstract/normalmap_bumpy
	icon = 'icons/effects/light_overlays/normalmap_bumpy.dmi'
	icon_state = "normalmap_bumpy"
	appearance_flags = RESET_COLOR|RESET_TRANSFORM|NO_CLIENT_COLOR|RESET_ALPHA|PIXEL_SCALE
	plane = GRAVITY_PULSE_PLANE


///Proc which replaces an atom's visual appearance with a wobbly distortion mask, using render target
/atom/movable/proc/apply_wibble_invisible(strength=50)
	var/obj/effect/abstract/normalmap_bumpy/normal_bumpy = new(src)
	var/render_tgt = "*warped_invis_[REF(normal_bumpy)]"
	if(render_target)
		render_tgt += "_oldtgt_" + render_target
	normal_bumpy.alpha = (255/100) * strength
	render_target = render_tgt
	normal_bumpy.apply_wibbly_filters()
	normal_bumpy.add_filter("wibble_mask", 1, alpha_mask_filter(-48, -48, render_source = render_target))
	vis_contents += normal_bumpy
	update_overlays()
	update_icon()
	update_filters()

/atom/movable/proc/remove_wibble_invisible()
	var/list/split_result = splittext(render_target, "_oldtgt_")
	var/ref_part = split_result[1]
	if(length(split_result) > 1)
		var/old_part = split_result[2]
		render_target = old_part
	else
		render_target = null
	ref_part = copytext(ref_part, 15)
	var/obj/effect/abstract/normalmap_bumpy/normal_bumpy = locate(ref_part) in vis_contents
	vis_contents -= normal_bumpy
	qdel(normal_bumpy)

///Applies a subtle, vapour-like distortion effect to an atom, but keeps it visible.
/atom/movable/proc/add_mirage_mask(strength=50)
	var/obj/effect/abstract/normalmap_bumpy/normal_bumpy = new(src)
	// var/render_tgt = "*warped_invis_[REF(normal_bumpy)]"
	// if(render_target)
	// 	render_tgt += "_oldtgt_" + render_target
	normal_bumpy.alpha = (255/100) * strength
	// render_target = render_tgt
	normal_bumpy.apply_wibbly_filters()
	normal_bumpy.add_filter("wibble_mask", 1, alpha_mask_filter(-48, -48, render_source="*[REF(src)]"))
	var/mutable_appearance/mask = mutable_appearance()
	mask.appearance = src.appearance
	mask.render_target = "*[REF(src)]"
	//mask.alpha = 125
	normal_bumpy.overlays += mask
	//note: because this doesn't currently produce a searchable ref, it'll need to be manually tracked and removed.
	vis_contents += normal_bumpy

//notes on looping an animate() sequence:
//the inherent 'loop' function on animate() will not directly 'reset' the conditions it created
//in this case, radius = 1 > radius = 32 && size = 2 > size = 4
//a second, immediately following animate command is needed to reset these back to their original conditions
//to make the loop actually do anything the second time onwards
//second animate() will be treated as an extension of the first, if it does not have an obj target

///applies a repeating rippling effect to a target atom.
///args: length(duration of ripple), strength(intensity of ripple)
/atom/proc/apply_ripple_filter(length = 1.5 SECONDS, strength = 4)
	add_filter("basic_ripple", 3, ripple_filter(1, strength, flags = WAVE_BOUNDED))
	animate(get_filter("basic_ripple"), radius = 32, time = length, size = (strength * 2), loop = -1, easing = LINEAR_EASING)
	animate(radius = 0, size = 2)

///removes the affect of apply_ripple_filter()
/atom/proc/remove_ripple_filter()
	remove_filter("basic_ripple")

///A basic temporary displacement effect
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

///A distortion effect which remains in place and effects a wide area through walls. Useful for large, dramatic distortions
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
	alpha = 0

/obj/effect/temp_visual/blink_drive/Initialize(mapload)
	. = ..()
	src.transform *= 0
	var/image/I = image(icon, src, icon_state, 10, pixel_x = -48, pixel_y = -48)
	overlays += I //we use an overlay so the icon and light source are both in the correct location
	icon_state = null
	animate(src, time=(duration), transform=matrix().Scale(1,1))
	// animate(src, time=(duration / 2), alpha = 255)
	// animate(time=(duration / 2), alpha = 0)

/obj/effect/temp_visual/bluespace_pulse
	icon = 'icons/effects/light_overlays/normalmap_bumpy.dmi'
	icon_state = "normalmap_bumpy_circle"
	plane = GRAVITY_PULSE_PLANE
	duration = 4
	alpha = 125

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
	icon = 'icons/effects/light_overlays/normalmap_shockwave.dmi'
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

