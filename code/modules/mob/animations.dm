/*
adds a dizziness amount to a mob
use this rather than directly changing var/dizziness
since this ensures that the dizzy_process proc is started
currently only humans get dizzy

value of dizziness ranges from 0 to 1000
below 100 is not dizzy
*/
/mob/proc/make_dizzy(amount)
	return

// for the moment, only humans get dizzy
/mob/living/carbon/human/make_dizzy(amount)
	dizziness = min(1000, dizziness + amount)	// store what will be new value
													// clamped to max 1000
	if(dizziness > 100 && !is_dizzy)
		spawn(0)
			dizzy_process()

/*
dizzy process - wiggles the client's pixel offset over time
spawned from make_dizzy(), will terminate automatically when dizziness gets <100
note dizziness decrements automatically in the mob's Life() proc.
*/
/mob/living/carbon/human/proc/dizzy_process()
	is_dizzy = 1
	while(dizziness > 100)
		if(client)
			var/amplitude = dizziness * (sin(dizziness * 0.044 * world.time) + 1) / 70
			var/iforgor = 0.004
			if(resting)
				iforgor *= 1.5
				dizziness -= 2

			var/target_x = amplitude * sin(iforgor * dizziness * world.time)
			var/target_y = amplitude * cos(iforgor * dizziness * world.time)
			animate(client, pixel_x = target_x, pixel_y = target_y, time = 1, easing = QUAD_EASING | EASE_OUT)
		sleep(1)
	//endwhile - reset the pixel offsets to zero
	is_dizzy = 0
	if(client)
		animate(client, pixel_x = 0, pixel_y = 0, time = 2, easing = QUAD_EASING | EASE_OUT)


// jitteriness - copy+paste of dizziness
/mob/proc/make_jittery(amount)
	return

/mob/living/carbon/human/make_jittery(amount)
	jitteriness = min(1000, jitteriness + amount)	// store what will be new value
													// clamped to max 1000
	if(jitteriness > 100 && !is_jittery)
		spawn(0)
			jittery_process()


// Typo from the oriignal coder here, below lies the jitteriness process. So make of his code what you will, the previous comment here was just a copypaste of the above.
/mob/living/carbon/human/proc/jittery_process()
	is_jittery = 1
	while(jitteriness > 100)
		var/amplitude = min(4, jitteriness / 100)
		pixel_x = default_pixel_x + rand(-amplitude, amplitude)
		pixel_y = default_pixel_y + rand(-amplitude/3, amplitude/3)

		sleep(1)
	//endwhile - reset the pixel offsets to zero
	is_jittery = 0
	pixel_x = default_pixel_x
	pixel_y = default_pixel_y


//handles up-down floaty effect in space and zero-gravity
/mob/var/is_floating = 0
/mob/var/floatiness = 0

/**
 * You can pass in true or false in a case where you've already done the calculations and can skip some checking here
 * Its perfectly fine to call this proc with no input, it will figure out what it needs to do
 */
/mob/proc/update_floating(setstate = null)
	if (!isnull(setstate))
		make_floating(setstate)
		return

	if(anchored || buckled || check_gravity())
		make_floating(0)
		return

	if(check_shoegrip() && check_solid_ground())
		make_floating(0)
		return

	make_floating(1)
	return

/mob/proc/make_floating(n)
	floatiness = n

	if(floatiness && !is_floating)
		start_floating()
	else if(!floatiness && is_floating)
		stop_floating()

/mob/proc/start_floating()

	is_floating = 1

	/// maximum displacement from original position
	var/amplitude = 2
	/// time taken for the mob to go up >> down >> original position, in deciseconds. Should be multiple of 4
	var/period = 36

	var/top = default_pixel_y + amplitude
	var/bottom = default_pixel_y - amplitude
	var/half_period = period / 2
	var/quarter_period = period / 4

	animate(src, pixel_y = top, time = quarter_period, easing = SINE_EASING | EASE_OUT, loop = -1)		//up
	animate(pixel_y = bottom, time = half_period, easing = SINE_EASING, loop = -1)						//down
	animate(pixel_y = default_pixel_y, time = quarter_period, easing = SINE_EASING | EASE_IN, loop = -1)			//back

/mob/proc/stop_floating()
	animate(src, pixel_y = default_pixel_y, time = 5, easing = SINE_EASING | EASE_IN) //halt animation
	//reset the pixel offsets to zero
	is_floating = 0

/atom/movable/proc/do_attack_animation(atom/A, use_item = TRUE, depth = 8)
	var/prev_x = pixel_x
	var/prev_y = pixel_y
	var/pixel_x_diff = 0
	var/pixel_y_diff = 0
	var/direction = get_dir(src, A)
	switch(direction)
		if(NORTH)
			pixel_y_diff = depth
		if(SOUTH)
			pixel_y_diff = -depth
		if(EAST)
			pixel_x_diff = depth
		if(WEST)
			pixel_x_diff = -depth
		if(NORTHEAST)
			pixel_x_diff = depth
			pixel_y_diff = depth
		if(NORTHWEST)
			pixel_x_diff = -depth
			pixel_y_diff = depth
		if(SOUTHEAST)
			pixel_x_diff = depth
			pixel_y_diff = -depth
		if(SOUTHWEST)
			pixel_x_diff = -depth
			pixel_y_diff = -depth
	animate(src, pixel_x = pixel_x + pixel_x_diff, pixel_y = pixel_y + pixel_y_diff, time = 2)
	animate(pixel_x = prev_x, pixel_y = prev_y, time = 2)

/mob/do_attack_animation(atom/A, use_item = TRUE)
	..()
	is_floating = 0 // If we were without gravity, the bouncing animation got stopped, so we make sure we restart the bouncing after the next movement.

	if (!use_item)
		//The use item flag governs whether or not we'll add a little weapon image to the animation
		return

	// What icon do we use for the attack?
	var/image/I
	var/obj/item/T = get_active_held_item()
	if (T && T.icon)
		I = image(T.icon, A, T.icon_state, A.layer + 1)
	else // Attacked with a fist?
		return

	// Who can see the attack?
	var/list/viewing = list()
	for (var/mob/M in viewers(A))
		if (M.client)
			viewing |= M.client
	flick_overlay(I, viewing, 5) // 5 ticks/half a second

	// Scale the icon.
	I.transform *= 0.75
	// Set the direction of the icon animation.
	var/direction = get_dir(src, A)
	if(direction & NORTH)
		I.pixel_y = -16
	else if(direction & SOUTH)
		I.pixel_y = 16

	if(direction & EAST)
		I.pixel_x = -16
	else if(direction & WEST)
		I.pixel_x = 16

	if(!direction) // Attacked self?!
		I.pixel_z = 16

	// And animate the attack!
	animate(I, alpha = 175, pixel_x = 0, pixel_y = 0, pixel_z = 0, time = 3)

#define TILES_PER_SECOND 0.7
///Shake the camera of the person viewing the mob SO REAL!
///Takes the mob to shake, the time span to shake for, and the amount of tiles we're allowed to shake by in tiles
///Duration isn't taken as a strict limit, since we don't trust our coders to not make things feel shitty. So it's more like a soft cap.
/proc/shake_camera(mob/M, duration, strength=1)
	if(!M || !M.client || duration < 1)
		return
	var/client/C = M.client
	var/oldx = C.pixel_x
	var/oldy = C.pixel_y
	var/max = strength*world.icon_size
	var/min = -(strength*world.icon_size)

	//How much time to allot for each pixel moved
	var/time_scalar = (1 / world.icon_size) * TILES_PER_SECOND
	var/last_x = oldx
	var/last_y = oldy

	var/time_spent = 0
	while(time_spent < duration)
		//Get a random pos in our box
		var/x_pos = rand(min, max) + oldx
		var/y_pos = rand(min, max) + oldy

		//We take the smaller of our two distances so things still have the propencity to feel somewhat jerky
		var/time = round(max(min(abs(last_x - x_pos), abs(last_y - y_pos)) * time_scalar, 1))

		if (time_spent == 0)
			animate(C, pixel_x=x_pos, pixel_y=y_pos, time=time)
		else
			animate(pixel_x=x_pos, pixel_y=y_pos, time=time)

		last_x = x_pos
		last_y = y_pos
		//We go based on time spent, so there is a chance we'll overshoot our duration. Don't care
		time_spent += time

	animate(pixel_x=oldx, pixel_y=oldy, time=3)

#undef TILES_PER_SECOND

//Deprecated, use SpinAnimation when possible
/mob/proc/spin(spintime, speed)
	set waitfor = 0
	var/D = dir
	if((spintime < 1) || (speed < 1) || !spintime || !speed)
		return
	while(spintime >= speed)
		sleep(speed)
		switch(D)
			if(NORTH)
				D = EAST
			if(SOUTH)
				D = WEST
			if(EAST)
				D = SOUTH
			if(WEST)
				D = NORTH
		set_dir(D)
		spintime -= speed
	return

/atom/movable/proc/do_pickup_animation(atom/target, atom/old_loc)
	set waitfor = FALSE
	if (QDELETED(src))
		return
	if (QDELETED(target))
		return
	if (QDELETED(old_loc))
		return

	var/turf/old_turf = get_turf(old_loc)
	var/image/I = image(icon = src, loc = old_turf)
	I.plane = plane
	I.layer = ABOVE_MOB_LAYER
	I.appearance_flags = APPEARANCE_UI_IGNORE_ALPHA
	if (ismob(target))
		I.dir = target.dir

	if (istype(old_loc,/obj/item/storage))
		I.pixel_x += old_loc.pixel_x
		I.pixel_y += old_loc.pixel_y

	flick_overlay(I, GLOB.clients, 7)

	var/matrix/M = new
	M.Turn(pick(30, -30))

	animate(I, transform = M, time = 1)
	sleep(1)
	animate(I, transform = matrix(), time = 1)
	sleep(1)

	var/to_x = (target.x - old_turf.x) * 32
	var/to_y = (target.y - old_turf.y) * 32

	animate(I, pixel_x = to_x, pixel_y = to_y, time = 3, transform = matrix() * 0, easing = CUBIC_EASING)
	sleep(3)

/atom/movable/proc/do_putdown_animation(atom/target, mob/user)
	spawn()
		if (QDELETED(src))
			return
		if (QDELETED(target))
			return
		if (QDELETED(user))
			return
		var/old_invisibility = invisibility // I don't know, it may be used.
		invisibility = 100
		var/turf/old_turf = get_turf(user)
		if (QDELETED(old_turf))
			return
		var/image/I = image(icon = src, loc = old_turf, layer = layer + 0.1)
		I.plane = get_relative_plane(GAME_PLANE)
		I.layer = ABOVE_MOB_LAYER
		I.transform = matrix() * 0
		I.appearance_flags = APPEARANCE_UI_IGNORE_ALPHA
		I.pixel_x = 0
		I.pixel_y = 0
		if (ismob(target))
			I.dir = target.dir
		flick_overlay(I, GLOB.clients, 4)

		var/to_x = (target.x - old_turf.x) * 32 + pixel_x
		var/to_y = (target.y - old_turf.y) * 32 + pixel_y
		var/old_x = pixel_x
		var/old_y = pixel_y
		pixel_x = 0
		pixel_y = 0

		animate(I, pixel_x = to_x, pixel_y = to_y, time = 3, transform = matrix(), easing = CUBIC_EASING)
		sleep(3)
		if (QDELETED(src))
			return
		invisibility = old_invisibility
		pixel_x = old_x
		pixel_y = old_y

/atom/movable/proc/simple_move_animation(atom/target)
	set waitfor = FALSE

	var/old_invisibility = invisibility // I don't know, it may be used.
	invisibility = 100
	var/turf/old_turf = get_turf(src)
	var/image/I = image(icon = src, loc = src.loc, layer = layer + 0.1)
	I.plane = get_relative_plane(GAME_PLANE)
	I.layer = ABOVE_MOB_LAYER
	I.appearance_flags = APPEARANCE_UI_IGNORE_ALPHA

	flick_overlay(I, GLOB.clients, 4)

	var/to_x = (target.x - old_turf.x) * 32 + pixel_x
	var/to_y = (target.y - old_turf.y) * 32 + pixel_y

	animate(I, pixel_x = to_x, pixel_y = to_y, time = 3, easing = CUBIC_EASING)
	sleep(3)
	if (QDELETED(src))
		return
	invisibility = old_invisibility
