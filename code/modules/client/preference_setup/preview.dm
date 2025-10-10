#define BG_WIDTH 96.0
#define BG_HEIGHT 64.0
/datum/preferences
	var/icon/preview_icon
	var/icon/preview_south
	var/icon/preview_north
	var/icon/preview_east
	var/icon/preview_west
	var/preview_dir = SOUTH	//for augmentation

/datum/preferences/proc/update_preview_icon(naked = FALSE)
	var/mob/living/carbon/human/dummy/mannequin/mannequin = get_mannequin(client_ckey)
	mannequin.delete_inventory(TRUE)
	preview_icon = icon('icons/effects/96x64.dmi', bgstate)

	dress_preview_mob(mannequin, naked)

	preview_east = getFlatIcon(mannequin, EAST)

	mannequin.dir = WEST
	var/icon/stamp = getFlatIcon(mannequin, WEST)
	preview_icon.Blend(stamp, ICON_OVERLAY, BG_WIDTH * 3 / 100.0, BG_HEIGHT * 29 / 100.0)
	preview_west = stamp

	mannequin.dir = NORTH
	stamp = getFlatIcon(mannequin, NORTH)
	preview_icon.Blend(stamp, ICON_OVERLAY, BG_WIDTH * 35 / 100.0, BG_HEIGHT * 53 / 100.0)
	preview_north = stamp

	mannequin.dir = SOUTH
	stamp = getFlatIcon(mannequin, SOUTH)
	preview_icon.Blend(stamp, ICON_OVERLAY, BG_WIDTH * 68 / 100.0, BG_HEIGHT / 100.0)
	preview_south = stamp

	return mannequin.icon

#undef BG_WIDTH
#undef BG_HEIGHT
