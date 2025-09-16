/proc/get_game_time()
	var/global/time_offset = 0
	var/global/last_time = 0
	var/global/last_usage = 0

	var/wtime = world.time
	var/wusage = world.tick_usage * 0.01

	if(last_time < wtime && last_usage > 1)
		time_offset += last_usage - 1

	last_time = wtime
	last_usage = wusage

	return wtime + (time_offset + wusage) * world.tick_lag

var/roundstart_hour = 0
var/station_date = ""
var/next_station_date_change = 1 DAYS

#define station_adjusted_time(time) time2text(time + station_time_in_ticks, "hh:mm")
#define worldtime2stationtime(time) time2text(roundstart_hour HOURS + time, "hh:mm")
#define roundduration2text_in_ticks (SSticker?.round_start_time ? world.time - SSticker.round_start_time : 0)
#define station_time_in_ticks (roundstart_hour HOURS + roundduration2text_in_ticks)

/proc/stationtime2text()
	if(!roundstart_hour) roundstart_hour = pick(2, 7, 12, 17)
	return time2text(station_time_in_ticks, "hh:mm")

/proc/stationdate2text()
	var/update_time = FALSE
	if(station_time_in_ticks > next_station_date_change)
		next_station_date_change += 1 DAYS
		update_time = TRUE
	if(!station_date || update_time)
		var/extra_days = round(station_time_in_ticks / (1 DAYS)) DAYS
		var/timeofday = world.timeofday + extra_days
		station_date = num2text((text2num(time2text(timeofday, "YYYY")) + 544)) + "-" + time2text(timeofday, "MM-DD")
	return station_date

/proc/time_stamp()
	return time2text(world.timeofday, "hh:mm:ss")


//Returns the world time in english
/proc/worldtime2text(time = world.time, timeshift = 1)
	if(!roundstart_hour) roundstart_hour = rand(0, 23)
	return timeshift ? time2text(time+(roundstart_hour HOURS), "hh:mm") : time2text(time, "hh:mm")

/proc/worldtime2hours()
	if (!roundstart_hour)
		worldtime2text()
	. = text2num(time2text(world.time + (roundstart_hour HOURS), "hh"))

/proc/worlddate2text()
	return num2text(CURRENT_SHIP_YEAR) + "-" + time2text(world.timeofday, "MM-DD", NO_TIMEZONE)


/* Returns 1 if it is the selected month and day */
/proc/isDay(month, day)
	if(isnum(month) && isnum(day))
		var/MM = text2num(time2text(world.timeofday, "MM")) // get the current month
		var/DD = text2num(time2text(world.timeofday, "DD")) // get the current day
		if(month == MM && day == DD)
			return 1

		// Uncomment this out when debugging!
		//else
			//return 1

var/next_duration_update = 0
var/last_roundduration2text = 0

/proc/roundduration2text()
	if(!SSticker?.round_start_time)
		return "00:00"
	if(last_roundduration2text && world.time < next_duration_update)
		return last_roundduration2text

	var/mills = roundduration2text_in_ticks // 1/10 of a second, not real milliseconds but whatever
	//var/secs = ((mills % 36000) % 600) / 10 //Not really needed, but I'll leave it here for refrence.. or something
	var/mins = round((mills % 36000) / 600)
	var/hours = round(mills / 36000)

	mins = mins < 10 ? add_zero(mins, 1) : mins
	hours = hours < 10 ? add_zero(hours, 1) : hours

	last_roundduration2text = "[hours]:[mins]"
	next_duration_update = world.time + 1 MINUTES
	return last_roundduration2text

/proc/gameTimestamp(format = "hh:mm:ss", wtime=null)
	if(!wtime)
		wtime = world.time - (SSticker?.round_start_time || 0)
	var/hour = round(wtime / 36000)
	var/minute = round(((wtime) - (hour * 36000)) / 600)
	var/second = round(((wtime) - (hour * 36000) - (minute * 600)) / 10)


	if(hour < 10)
		hour = "0[hour]"
	if(minute < 10)
		minute = "0[minute]"
	if(second < 10)
		second = "0[second]"

	return "[hour]:[minute]:[second]"


//Takes a value of time in deciseconds.
//Returns a text value of that number in hours, minutes, or seconds.
/proc/DisplayTimeText(time_value, round_seconds_to = 0.1)
	var/second = FLOOR(time_value * 0.1, round_seconds_to)
	if(!second)
		return "right now"
	if(second < 60)
		return "[second] second[(second != 1)? "s":""]"
	var/minute = FLOOR(second / 60, 1)
	second = FLOOR(MODULUS(second, 60), round_seconds_to)
	var/secondT
	if(second)
		secondT = " and [second] second[(second != 1)? "s":""]"
	if(minute < 60)
		return "[minute] minute[(minute != 1)? "s":""][secondT]"
	var/hour = FLOOR(minute / 60, 1)
	minute = MODULUS(minute, 60)
	var/minuteT
	if(minute)
		minuteT = " and [minute] minute[(minute != 1)? "s":""]"
	if(hour < 24)
		return "[hour] hour[(hour != 1)? "s":""][minuteT][secondT]"
	var/day = FLOOR(hour / 24, 1)
	hour = MODULUS(hour, 24)
	var/hourT
	if(hour)
		hourT = " and [hour] hour[(hour != 1)? "s":""]"
	return "[day] day[(day != 1)? "s":""][hourT][minuteT][secondT]"

//returns timestamp in a sql and a not-quite-compliant ISO 8601 friendly format
/proc/SQLtime(timevar)
	return time2text(timevar || world.timeofday, "YYYY-MM-DD hh:mm:ss")

var/global/midnight_rollovers = 0
var/global/rollovercheck_last_timeofday = 0

/proc/update_midnight_rollover()
	if (world.timeofday < rollovercheck_last_timeofday) //TIME IS GOING BACKWARDS!
		return midnight_rollovers++
	return midnight_rollovers

/proc/ticks_to_text(ticks)
	if(ticks%1 != 0)
		return "ERROR"
	var/response = ""
	var/counter = 0
	while(ticks >= 1 DAYS)
		ticks -= 1 DAYS
		counter++
	if(counter)
		response += "[counter] Day[counter>1 ? "s" : ""][ticks ? ", " : ""]"
	counter=0
	while(ticks >= 1 HOURS)
		ticks -= 1 HOURS
		counter++
	if(counter)
		response += "[counter] Hour[counter>1 ? "s" : ""][ticks?", ":""]"
	counter=0
	while(ticks >= 1 MINUTES)
		ticks -= 1 MINUTES
		counter++
	if(counter)
		response += "[counter] Minute[counter>1 ? "s" : ""][ticks?", ":""]"
		counter=0
	while(ticks >= 1 SECONDS)
		ticks -= 1 SECONDS
		counter++
	if(counter)
		response += "[counter][ticks?".[ticks]" : ""] Second[counter>1 ? "s" : ""]"
	return response

//Increases delay as the server gets more overloaded,
//as sleeps aren't cheap and sleeping only to wake up and sleep again is wasteful
#define DELTA_CALC max(((max(world.tick_usage, world.cpu) / 100) * max(Master.sleep_delta,1)), 1)

/proc/stoplag()
	if (!Master || !(Master.current_runlevel & RUNLEVELS_DEFAULT))
		sleep(world.tick_lag)
		return 1
	. = 0
	var/i = 1
	do
		. += round(i*DELTA_CALC)
		sleep(i*world.tick_lag*DELTA_CALC)
		i *= 2
	while (world.tick_usage > min(TICK_LIMIT_TO_RUN, Master.current_ticklimit))

#undef DELTA_CALC
