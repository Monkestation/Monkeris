/atom/movable/screen/plane_master
	name = "generic plane master"
	screen_loc = "CENTER"
	icon_state = "blank"
	appearance_flags = PLANE_MASTER|NO_CLIENT_COLOR
	blend_mode = BLEND_OVERLAY
	var/show_alpha = 255
	var/hide_alpha = 0

	plane = LOWEST_EVER_PLANE

	//--rendering relay vars--
	///integer: what plane we will relay this planes render to
	var/render_relay_plane = RENDER_PLANE_MASTER
	///bool: Whether this plane should get a render target automatically generated
	var/generate_render_target = TRUE
	///integer: blend mode to apply to the render relay in case you dont want to use the plane_masters blend_mode
	var/blend_mode_override
	///reference to render relay screen object to avoid backdropping multiple times
	var/atom/movable/render_plane_relay/relay

	/// If our plane master has different offsetting logic
	/// Possible flags are defined in [_DEFINES/_planes+layers.dm]
	var/offsetting_flags = NONE

/atom/movable/screen/plane_master/proc/Show(override)
	alpha = override || show_alpha

/atom/movable/screen/plane_master/proc/Hide(override)
	alpha = override || hide_alpha

//Why do plane masters need a backdrop sometimes? Read https://secure.byond.com/forum/?post=2141928
//Trust me, you need one. Period. If you don't think you do, you're doing something extremely wrong.
/atom/movable/screen/plane_master/proc/backdrop(mob/mymob, ourz)
	SHOULD_CALL_PARENT(TRUE)
	if(!isnull(render_relay_plane))
		relay_render_to_plane(mymob, render_relay_plane, ourz)


/atom/movable/screen/plane_master/floor
	name = "floor plane master"
	plane = FLOOR_PLANE
	appearance_flags = PLANE_MASTER
	blend_mode = BLEND_OVERLAY
	render_relay_plane = RENDER_PLANE_GAME

/atom/movable/screen/plane_master/game_world
	name = "game world plane master"
	plane = GAME_PLANE
	appearance_flags = PLANE_MASTER //should use client color
	blend_mode = BLEND_OVERLAY
	render_relay_plane = RENDER_PLANE_GAME

/atom/movable/screen/plane_master/game_world/backdrop(mob/mymob)
	. = ..()
	remove_filter("ambient_occlusion")

	if(mymob.client && mymob.client.get_preference_value(/datum/client_preference/ambient_occlusion) == GLOB.PREF_YES)
		add_filter("ambient_occlusion", 2, drop_shadow_filter(x=0, y=-2, size=4, color="#04080FAA"))


/atom/movable/screen/plane_master/above_lighting
	name = "above lighting plane master"
	plane = ABOVE_LIGHTING_PLANE
	appearance_flags = PLANE_MASTER //should use client color
	blend_mode = BLEND_OVERLAY
	render_relay_plane = RENDER_PLANE_GAME

/atom/movable/screen/plane_master/lighting
	name = "lighting plane master"
	plane = LIGHTING_PLANE
	//blend_mode = BLEND_MULTIPLY
	blend_mode_override = BLEND_MULTIPLY
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	render_relay_plane = RENDER_PLANE_GAME
/*
/atom/movable/screen/plane_master/lighting/backdrop(mob/mymob)
	. = ..()
	mymob.overlay_fullscreen("lighting_backdrop_lit", /atom/movable/screen/fullscreen/lighting_backdrop/lit)
	mymob.overlay_fullscreen("lighting_backdrop_unlit", /atom/movable/screen/fullscreen/lighting_backdrop/unlit)
*/

/atom/movable/screen/plane_master/parallax
	name = "parallax plane master"
	plane = PLANE_SPACE_PARALLAX
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	render_relay_plane = RENDER_PLANE_GAME


/atom/movable/screen/plane_master/parallax_white
	name = "parallax whitifier plane master"
	plane = PLANE_SPACE
	blend_mode = BLEND_MULTIPLY
	render_relay_plane = RENDER_PLANE_GAME

/atom/movable/screen/plane_master/open_space_plane
	name = "open space shadow plane"
	plane = OPENSPACE_PLANE
	appearance_flags = PLANE_MASTER
	render_relay_plane = RENDER_PLANE_NON_GAME

///Things rendered on "openspace"; holes in multi-z
/atom/movable/screen/plane_master/openspace_backdrop
	name = "open space backdrop plane master"
	plane = OVER_OPENSPACE_PLANE
	appearance_flags = PLANE_MASTER
	blend_mode = BLEND_MULTIPLY
	render_relay_plane = RENDER_PLANE_GAME

/**
 * Plane master handling byond internal blackness
 * vars are set as to replicate behavior when rendering to other planes
 * do not touch this unless you know what you are doing
 */
/atom/movable/screen/plane_master/blackness
	name = "darkness plane master"
	plane = BLACKNESS_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	blend_mode = BLEND_MULTIPLY
	appearance_flags = PLANE_MASTER | NO_CLIENT_COLOR | PIXEL_SCALE
	//byond internal code end
	render_relay_plane = RENDER_PLANE_GAME


/atom/movable/screen/plane_master/gravpulse
	name = "gravpulse plane"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = GRAVITY_PULSE_PLANE
	render_target = GRAVITY_PULSE_RENDER_TARGET
	render_relay_plane = null
	appearance_flags = PLANE_MASTER|NO_CLIENT_COLOR

/atom/movable/screen/plane_master/gravpulse/backdrop(mob/mymob, ourz)
	render_target = "[render_target] #[ourz]"
	..()


///baycode sucks. end of statement
/atom/movable/screen/plane_master/mob_plane
	name = "mob plane"
	plane = HIDING_MOB_PLANE
	appearance_flags = PLANE_MASTER
	blend_mode = BLEND_OVERLAY
	render_relay_plane = RENDER_PLANE_GAME

/atom/movable/screen/plane_master/weather
	name = "weather plane"
	plane = WEATHER_PLANE
	render_relay_plane = RENDER_PLANE_GAME
	offsetting_flags = BLOCKS_PLANE_OFFSETTING|OFFSET_RELAYS_MATCH_HIGHEST

/atom/movable/screen/plane_master/balloon
	name = "balloon chat plane"
	plane = BALLOON_CHAT_PLANE
	appearance_flags = PLANE_MASTER|NO_CLIENT_COLOR
	render_relay_plane = RENDER_PLANE_NON_GAME

/atom/movable/screen/plane_master/below_hud
	name = "below hud plane"
	plane = BELOW_HUD_PLANE
	appearance_flags = PLANE_MASTER|NO_CLIENT_COLOR
	render_relay_plane = RENDER_PLANE_NON_GAME
	offsetting_flags = BLOCKS_PLANE_OFFSETTING|OFFSET_RELAYS_MATCH_HIGHEST

/atom/movable/screen/plane_master/hud
	name = "hud plane"
	plane = HUD_PLANE
	appearance_flags = PLANE_MASTER|NO_CLIENT_COLOR
	render_relay_plane = RENDER_PLANE_NON_GAME
	offsetting_flags = BLOCKS_PLANE_OFFSETTING|OFFSET_RELAYS_MATCH_HIGHEST

/atom/movable/screen/plane_master/above_hud
	name = "above hud plane"
	plane = ABOVE_HUD_PLANE
	appearance_flags = PLANE_MASTER|NO_CLIENT_COLOR
	render_relay_plane = RENDER_PLANE_NON_GAME
	offsetting_flags = BLOCKS_PLANE_OFFSETTING|OFFSET_RELAYS_MATCH_HIGHEST

/atom/movable/screen/plane_master/runechat
	name = "runechat plane"
	plane = RUNECHAT_PLANE
	appearance_flags = PLANE_MASTER|NO_CLIENT_COLOR
	render_relay_plane = RENDER_PLANE_NON_GAME
	offsetting_flags = BLOCKS_PLANE_OFFSETTING|OFFSET_RELAYS_MATCH_HIGHEST

/atom/movable/screen/plane_master/cinema
	name = "absolute cinema"
	plane = CINEMATIC_PLANE
	appearance_flags = PLANE_MASTER|NO_CLIENT_COLOR
	render_relay_plane = RENDER_PLANE_NON_GAME
	offsetting_flags = BLOCKS_PLANE_OFFSETTING|OFFSET_RELAYS_MATCH_HIGHEST

/atom/movable/screen/plane_master/fullscreen
	name = "fullscreen alert plane"
	plane = FULLSCREEN_PLANE
	render_relay_plane = RENDER_PLANE_NON_GAME
	offsetting_flags = BLOCKS_PLANE_OFFSETTING|OFFSET_RELAYS_MATCH_HIGHEST

