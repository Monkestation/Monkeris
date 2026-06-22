/datum/asset/simple/directories/nanoui
	dirs = list(
		"nano/js/",
		"nano/css/",
		"nano/templates/",
		"nano/images/",
		"nano/images/status_icons/",
		"nano/images/modular_computers/",
		"nano/images/eris/",
	)

/datum/asset/simple/directories/images_news
	dirs = list("news_articles/images/")

/datum/asset/simple/directories
	keep_local_name = TRUE
	var/list/dirs = list()

/datum/asset/simple/directories/register()
	// Crawl the directories to find files.
	for (var/path in dirs)
		var/list/filenames = flist(path)
		for(var/filename in filenames)
			if(copytext(filename, length(filename)) != "/") // Ignore directories.
				var/realpath = "[path][filename]"
				if(fexists(realpath))
					assets[filename] = file(realpath)
	..()
