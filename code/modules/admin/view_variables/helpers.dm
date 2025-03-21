// IMPORTANT! CLIENT IS A SUBTYPE OF DATUM

/datum/proc/get_view_variables_header()
	return "<b>[src]</b>"

/atom/get_view_variables_header()
	return {"
		<a href='byond://?_src_=vars;datumedit=\ref[src];varnameedit=name'><b>[src]</b></a>
		<br><font size='1'>
		<a href='byond://?_src_=vars;rotatedatum=\ref[src];rotatedir=left'><<</a>
		<a href='byond://?_src_=vars;datumedit=\ref[src];varnameedit=dir'>[dir2text(dir)]</a>
		<a href='byond://?_src_=vars;rotatedatum=\ref[src];rotatedir=right'>>></a>
		</font>
	"}

/mob/living/get_view_variables_header()
	return {"
		<a href='byond://?_src_=vars;rename=\ref[src]'><b>[src]</b></a><font size='1'>
		<br><a href='byond://?_src_=vars;rotatedatum=\ref[src];rotatedir=left'><<</a> <a href='byond://?_src_=vars;datumedit=\ref[src];varnameedit=dir'>[dir2text(dir)]</a> <a href='byond://?_src_=vars;rotatedatum=\ref[src];rotatedir=right'>>></a>
		<br><a href='byond://?_src_=vars;datumedit=\ref[src];varnameedit=ckey'>[ckey ? ckey : "No ckey"]</a> / <a href='byond://?_src_=vars;datumedit=\ref[src];varnameedit=real_name'>[real_name ? real_name : "No real name"]</a>
		<br>
		BRUTE:<a href='byond://?_src_=vars;mobToDamage=\ref[src];adjustDamage=brute'>[getBruteLoss()]</a>
		FIRE:<a href='byond://?_src_=vars;mobToDamage=\ref[src];adjustDamage=fire'>[getFireLoss()]</a>
		TOXIN:<a href='byond://?_src_=vars;mobToDamage=\ref[src];adjustDamage=toxin'>[getToxLoss()]</a>
		OXY:<a href='byond://?_src_=vars;mobToDamage=\ref[src];adjustDamage=oxygen'>[getOxyLoss()]</a>
		CLONE:<a href='byond://?_src_=vars;mobToDamage=\ref[src];adjustDamage=clone'>[getCloneLoss()]</a>
		BRAIN:<a href='byond://?_src_=vars;mobToDamage=\ref[src];adjustDamage=brain'>[getBrainLoss()]</a>
		</font>
	"}

/datum/proc/get_view_variables_options()
	return ""

/mob/get_view_variables_options()
	return ..() + {"
		<option value='?_src_=vars;mob_player_panel=\ref[src]'>Show player panel</option>
		<option>---</option>
		<option value='?_src_=vars;give_spell=\ref[src]'>Give Spell</option>
		<option value='?_src_=vars;give_disease2=\ref[src]'>Give Disease</option>
		<option value='?_src_=vars;give_disease=\ref[src]'>Give TG-style Disease</option>
		<option value='?_src_=vars;godmode=\ref[src]'>Toggle Godmode</option>
		<option value='?_src_=vars;build_mode=\ref[src]'>Toggle Build Mode</option>

		<option value='?_src_=vars;make_skeleton=\ref[src]'>Make 2spooky</option>

		<option value='?_src_=vars;direct_control=\ref[src]'>Assume Direct Control</option>
		<option value='?_src_=vars;drop_everything=\ref[src]'>Drop Everything</option>

		<option value='?_src_=vars;regenerateicons=\ref[src]'>Regenerate Icons</option>
		<option value='?_src_=vars;addlanguage=\ref[src]'>Add Language</option>
		<option value='?_src_=vars;remlanguage=\ref[src]'>Remove Language</option>
		<option value='?_src_=vars;addorgan=\ref[src]'>Add Organ</option>
		<option value='?_src_=vars;remorgan=\ref[src]'>Remove Organ</option>

		<option value='?_src_=vars;fix_nano=\ref[src]'>Fix NanoUI</option>

		<option value='?_src_=vars;addverb=\ref[src]'>Add Verb</option>
		<option value='?_src_=vars;remverb=\ref[src]'>Remove Verb</option>
		<option>---</option>
		<option value='?_src_=vars;gib=\ref[src]'>Gib</option>
	"}

/mob/living/carbon/human/get_view_variables_options()
	return ..() + {"
		<option value='?_src_=vars;setspecies=\ref[src]'>Set Species</option>
		<option value='?_src_=vars;makeai=\ref[src]'>Make AI</option>
		<option value='?_src_=vars;makerobot=\ref[src]'>Make cyborg</option>
		<option value='?_src_=vars;makeslime=\ref[src]'>Make slime</option>
	"}

/turf/get_view_variables_options()
	return ..() + {"
		<option value='?_src_=vars;teleport_to=\ref[src]'>Teleport to</option>
		<option value='?_src_=vars;explode=\ref[src]'>Trigger explosion</option>
		<option value='?_src_=vars;emp=\ref[src]'>Trigger EM pulse</option>
	"}

/atom/get_view_variables_options()
	. = ..()
	if(reagents)
		. += "<option value='?_src_=vars;addreagent=\ref[src]'>Add reagent</option>"


/atom/movable/get_view_variables_options()
	return ..() + {"
		<option value='?_src_=vars;teleport_here=\ref[src]'>Teleport here</option>
		<option value='?_src_=vars;teleport_to=\ref[src]'>Teleport to</option>
		<option value='?_src_=vars;delall=\ref[src]'>Delete all of type</option>
		<option value='?_src_=vars;explode=\ref[src]'>Trigger explosion</option>
		<option value='?_src_=vars;emp=\ref[src]'>Trigger EM pulse</option>
	"}

// The following vars cannot be viewed by anyone
/datum/proc/VV_hidden()
	return list()
