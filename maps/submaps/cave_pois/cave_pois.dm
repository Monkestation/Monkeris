#define PROB_HIGH 15
#define PROB_MID 10
#define PROB_LOW 5
#define PROB_VERY_LOW 3

/datum/map_template/cave_pois
	name = null
	var/description = "Cave point of interest."

	var/prefix = "maps/submaps/cave_pois/"
	var/suffix = null
	template_flags = 0 // No duplicates by default

	var/spawn_prob = 0
	var/min_seismic_lvl = 1  // the poi will start spawning at this seismic level and above
	var/max_seismic_lvl = 6 // the poi will stop spawing above this seismic level
	var/size_x = 0
	var/size_y = 0
	var/size = POI_SIZE_SMALL // determines which spawn pool this poi is added to
/datum/map_template/cave_pois/New()
	mappath += (prefix + suffix)

	..()

// Neutral rooms
// Low-tier ruins with maint lvl. loot
/datum/map_template/cave_pois/neutral
	spawn_prob = PROB_HIGH
	min_seismic_lvl = 1
	max_seismic_lvl = 4
	size_x = 5
	size_y = 5

	name = "neutral 1"
	id = "cave_neutral1"
	suffix = "neutral1.dmm"

/datum/map_template/cave_pois/neutral/neutral2
	name = "neutral 2"
	id = "cave_neutral2"
	suffix = "neutral2.dmm"

/datum/map_template/cave_pois/neutral/neutral3
	name = "neutral 3"
	id = "cave_neutral3"
	suffix = "neutral3.dmm"

/datum/map_template/cave_pois/neutral/neutral4
	name = "neutral 4"
	id = "cave_neutral4"
	suffix = "neutral4.dmm"

/datum/map_template/cave_pois/neutral/neutral5
	name = "neutral 5"
	id = "cave_neutral5"
	suffix = "neutral5.dmm"

/datum/map_template/cave_pois/neutral/neutral6
	name = "neutral 6"
	id = "cave_neutral6"
	suffix = "neutral6.dmm"

/datum/map_template/cave_pois/neutral/neutral7
	name = "neutral 7"
	id = "cave_neutral7"
	suffix = "neutral7.dmm"

//large maint-lvl generic ruins
/datum/map_template/cave_pois/neutral/big
	min_seismic_lvl = 2
	max_seismic_lvl = 5
	spawn_prob = PROB_MID
	size_x = 25
	size_y = 25
	size = POI_SIZE_LARGE
	name = "big neutral 1"
	id = "cave_bigneutral1"
	suffix = "neutral_big1.dmm"

/datum/map_template/cave_pois/neutral/big/bigneutral2
	name = "big neutral 2"
	id = "cave_bigneutral2"
	suffix = "neutral_big2.dmm"

/datum/map_template/cave_pois/neutral/big/bigneutral3
	name = "big neutral 3"
	id = "cave_bigneutral3"
	suffix = "neutral_big3.dmm"

// Huts
// Mid-tier ruins with maint+ level loot
//appears on seismic lvls 2-5
/datum/map_template/cave_pois/hut
	spawn_prob = PROB_MID
	min_seismic_lvl = 2
	max_seismic_lvl = 5
	size_x = 7
	size_y = 7

	name = "hut 1"
	id = "cave_hut1"
	suffix = "hut1.dmm"

/datum/map_template/cave_pois/hut/hut2
	name = "hut 2"
	id = "cave_hut2"
	suffix = "hut2.dmm"

/datum/map_template/cave_pois/hut/hut3
	name = "hut 3"
	id = "cave_hut3"
	suffix = "hut3.dmm"

/datum/map_template/cave_pois/hut/hutnest
	name = "nest hut"
	id = "cave_hut_nest"
	suffix = "hut_nest.dmm"
	spawn_prob = PROB_LOW

/datum/map_template/cave_pois/hut/hutshrine
	name = "shrine hut"
	id = "cave_hut_shrine"
	suffix = "hut_shrine.dmm"
	spawn_prob = PROB_LOW


//spacewrecks
//dangerous mid-tier ruins with deepmaint tier loot
//appears on seismic 4-6
/datum/map_template/cave_pois/spacewreck
	name = "crashed escape shuttle"
	id = "cave_spacewrecks1"
	suffix = "spacewrecks1.dmm"
	spawn_prob = PROB_MID
	size = POI_SIZE_LARGE
	min_seismic_lvl = 4
	size_x = 13
	size_y = 24

/datum/map_template/cave_pois/spacewreck/spacewreck2
	name = "crashed cargo hauler"
	id = "cave_spacewrecks2"
	suffix = "spacewrecks2.dmm"
	size_x = 18

/datum/map_template/cave_pois/spacewreck/spacewreck3
	name = "survival pod"
	id = "cave_spacewrecks3"
	suffix = "spacewrecks3.dmm"
	size_x = 12
	size_y = 16

/datum/map_template/cave_pois/spacewreck/spacewreck4
	name = "overrun mining trawler"
	id = "cave_spacewrecks4"
	suffix = "spacewrecks4.dmm"
	size_x = 18
	size_y = 23

/datum/map_template/cave_pois/spacewreck/spacewreck5
	name = "intercepted smuggler"
	id = "cave_spacewrecks5"
	suffix = "spacewrecks5.dmm"
	size_x = 26
	size_y = 19

/datum/map_template/cave_pois/spacewreck/spacewreck6
	name = "crashed military frigate"
	id = "cave_spacewrecks6"
	suffix = "spacewrecks6.dmm"
	size_x = 27
	size_y = 17


// Serbian (military) wrecks
//rare and dangerous ruins with uncommon combat-themed loot
//appears on seismic 5-6
/datum/map_template/cave_pois/serbian
	name = "military wreck"
	id = "cave_serbian1"
	suffix = "serbian1.dmm"
	spawn_prob = PROB_LOW
	min_seismic_lvl = 5
	size_x = 25
	size_y = 25
	size = POI_SIZE_LARGE

/datum/map_template/cave_pois/serbian/serbian2
	name = "military wreck 2"
	id = "cave_serbian2"
	suffix = "serbian2.dmm"

/datum/map_template/cave_pois/serbian/serbian3
	name = "military wreck 3"
	id = "cave_serbian3"
	suffix = "serbian3.dmm"

//small serbian chunks
//spawns alongside other ruins on seismic 4, replaces other chunks on seismic 5
/datum/map_template/cave_pois/serbian_small
	name = "small military 1"
	id = "cave_serbian_tiny1"
	suffix = "serbian_tiny1.dmm"
	spawn_prob = PROB_MID
	min_seismic_lvl = 4
	size_x = 5
	size_y = 5

/datum/map_template/cave_pois/serbian_small/small2
	name = "small military 2"
	id = "cave_serbian_tiny2"
	suffix = "serbian_tiny2.dmm"

/datum/map_template/cave_pois/serbian_small/small3
	name = "small military 3"
	id = "cave_serbian_tiny3"
	suffix = "serbian_tiny3.dmm"

/datum/map_template/cave_pois/serbian_small/small4
	name = "small military 4"
	id = "cave_serbian_tiny4"
	suffix = "serbian_tiny4.dmm"

// Onestar ruins
//rare and very dangerous ruins with onestar loot
//only appears on seismic lvl. 6
/datum/map_template/cave_pois/onestar
	name = "onestar reeducation camp"
	id = "cave_onestar1"
	suffix = "onestar1.dmm"
	spawn_prob = PROB_VERY_LOW
	min_seismic_lvl = 6
	size_x = 25
	size_y = 25
	size = POI_SIZE_LARGE

/datum/map_template/cave_pois/onestar/security
	name = "onestar security checkpoint"
	id = "cave_onestar2"
	suffix = "onestar2.dmm"

/datum/map_template/cave_pois/onestar/monitor
	name = "onestar monitoring outpost"
	id = "cave_onestar3"
	suffix = "onestar3.dmm"

/datum/map_template/cave_pois/onestar/med
	name = "onestar medical clinic"
	id = "cave_onestar4"
	suffix = "onestar4.dmm"

//tiny, low loot onestar chunks that replace contemporary small chunks at depth 6
/datum/map_template/cave_pois/onestar_small
	name = "small onestar chunk"
	id = "cave_onestar_tiny1"
	suffix = "onestar_tiny1.dmm"
	spawn_prob = PROB_MID
	min_seismic_lvl = 6
	size_x = 5
	size_y = 5

/datum/map_template/cave_pois/onestar_small/small2
	name = "small onestar chunk 2"
	id = "cave_onestar_tiny2"
	suffix = "onestar_tiny2.dmm"

/datum/map_template/cave_pois/onestar_small/small3
	name = "small onestar chunk 3"
	id = "cave_onestar_tiny3"
	suffix = "onestar_tiny3.dmm"

/datum/map_template/cave_pois/onestar_small/small4
	name = "small onestar chunk 4"
	id = "cave_onestar_tiny4"
	suffix = "onestar_tiny4.dmm"

#undef PROB_HIGH
#undef PROB_MID
#undef PROB_LOW
