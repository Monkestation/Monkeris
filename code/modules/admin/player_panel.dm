/datum/admins/proc/player_panel_new()//The new one
	if(!check_rights())
		return
	log_admin("[key_name(usr)] checked the player panel.")
	var/dat = "<html><head><meta http-equiv='X-UA-Compatible' content='IE=edge' charset='UTF-8'/><title>Player Panel</title></head>"

	var/ui_scale = owner.get_preference_value(/datum/client_preference/ui_scale)

	//javascript, the part that does most of the work~
	dat += {"

		<head>
			[!ui_scale && owner.window_scaling ? "<style>body {zoom: [100 / owner.window_scaling]%;}</style>" : ""]
			<script type='text/javascript'>

				var locked_tabs = new Array();

				function updateSearch(){


					var filter_text = document.getElementById('filter');
					var filter = filter_text.value.toLowerCase();

					if(complete_list != null && complete_list != ""){
						var mtbl = document.getElementById("maintable_data_archive");
						mtbl.innerHTML = complete_list;
					}

					if(filter.value == ""){
						return;
					}else{

						var maintable_data = document.getElementById('maintable_data');
						var ltr = maintable_data.getElementsByTagName("tr");
						for ( var i = 0; i < ltr.length; ++i )
						{
							try{
								var tr = ltr\[i\];
								if(tr.getAttribute("id").indexOf("data") != 0){
									continue;
								}
								var ltd = tr.getElementsByTagName("td");
								var td = ltd\[0\];
								var lsearch = td.getElementsByClassName("filter_data");
								var search = lsearch\[0\];
								if ( search.innerText.toLowerCase().indexOf(filter) == -1 )
								{
									tr.innerHTML = "";
									i--;
								}
							}catch(err) {   }
						}
					}

					var count = 0;
					var index = -1;
					var debug = document.getElementById("debug");

					locked_tabs = new Array();
				}

				function expand(data_id,target_id){

					job = document.getElementById(data_id+"_job").textContent
					name = document.getElementById(data_id+"_name").textContent
					real_name = document.getElementById(data_id+"_rname").textContent
					old_names = document.getElementById(data_id+"_prevnames").textContent
					key = document.getElementById(data_id+"_key").textContent
					ip = document.getElementById(data_id+"_lastip").textContent
					antagonist = document.getElementById(data_id+"_isantag").textContent
					ref = document.getElementById(data_id+"_ref").textContent

					clearAll();

					var span = document.getElementById(target_id);
					var ckey = key.toLowerCase().replace(/\[^a-z@0-9\]+/g,"");

					body = "<table><tr><td>";

					body += "</td><td align='center'>";

					body += "<font size='2'><b>"+job+" "+name+"</b><br><b>Real name "+real_name+"</b><br><b>Played by "+key+" ("+ip+")</b><br><b>Old names :"+old_names+"</b></font>";

					body += "</td><td align='center'>";

					body += "<a href='byond://?_src_=holder;[HrefToken()];adminplayeropts="+ref+"'>PP</a> - "
					body += "<a href='byond://?_src_=holder;[HrefToken()];showmessageckey="+ckey+"'>N</a> - "
					body += "<a href='byond://?_src_=vars;[HrefToken()];Vars="+ref+"'>VV</a> - "
					body += "<a href='byond://?_src_=holder;[HrefToken()];contractor="+ref+"'>TP</a> - "
					body += "<a href='byond://?priv_msg="+ckey+"'>PM</a> - "
					body += "<a href='byond://?_src_=holder;[HrefToken()];subtlemessage="+ref+"'>SM</a> - "
					body += "<a href='byond://?_src_=holder;[HrefToken()];manup="+ref+"'>MAN_UP</a> - "
					body += "<a href='byond://?_src_=holder;[HrefToken()];viewlogs="+ref+"'>LOGS</a> - "
					body += "<a href='byond://?_src_=holder;[HrefToken()];paralyze="+ref+"'>PARA</a> - "
					body += "<a href='byond://?_src_=holder;[HrefToken()];adminobservejump="+ref+"'>JMP</a><br>"
					if(antagonist > 1)
						body += "<font size='2'><a href='byond://?_src_=holder;[HrefToken()];check_antagonist=1'><font color='red'><b>Antagonist</b></font></a></font>";
					else if(antagonist > 0)
						body += "<font size='2'><font color='red'><b>Limited Antagonist</b></font></font>";
					body += "</td></tr></table>";


					span.innerHTML = body
				}

				function clearAll(){
					var spans = document.getElementsByTagName('span');
					for(var i = 0; i < spans.length; i++){
						var span = spans\[i\];

						var id = span.getAttribute("id");

						if(!id || !(id.indexOf("item") == 0))
							continue;

						var pass = 1;

						for(var j = 0; j < locked_tabs.length; j++){
							if(locked_tabs\[j\] == id){
								pass = 0;
								break;
							}
						}

						if(pass != 1)
							continue;




						span.innerHTML = "";
					}
				}

				function addToLocked(id,link_id,notice_span_id){
					var link = document.getElementById(link_id);
					var decision = link.getAttribute("name");
					if(decision == "1"){
						link.setAttribute("name","2");
					}else{
						link.setAttribute("name","1");
						removeFromLocked(id,link_id,notice_span_id);
						return;
					}

					var pass = 1;
					for(var j = 0; j < locked_tabs.length; j++){
						if(locked_tabs\[j\] == id){
							pass = 0;
							break;
						}
					}
					if(!pass)
						return;
					locked_tabs.push(id);
					var notice_span = document.getElementById(notice_span_id);
					notice_span.innerHTML = "<font color='red'>Locked</font> ";
				}

				function attempt(ab){
					return ab;
				}

				function removeFromLocked(id,link_id,notice_span_id){
					//document.write("a");
					var index = 0;
					var pass = 0;
					for(var j = 0; j < locked_tabs.length; j++){
						if(locked_tabs\[j\] == id){
							pass = 1;
							index = j;
							break;
						}
					}
					if(!pass)
						return;
					locked_tabs\[index\] = "";
					var notice_span = document.getElementById(notice_span_id);
					notice_span.innerHTML = "";
				}

				function selectTextField(){
					var filter_text = document.getElementById('filter');
					filter_text.focus();
					filter_text.select();
				}

			</script>
		</head>


	"}

	//body tag start + onload and onkeypress (onkeyup) javascript event calls
	dat += "<body onload='selectTextField(); updateSearch();' onkeyup='updateSearch();'>"

	//title + search bar
	dat += {"

		<table width='560' align='center' cellspacing='0' cellpadding='5' id='maintable'>
			<tr id='title_tr'>
				<td align='center'>
					<font size='5'><b>Player panel</b></font><br>
					Hover over a line to see more information - <a href='byond://?_src_=holder;[HrefToken()];check_antagonist=1'>Check antagonists</a> - Kick <a href='byond://?_src_=holder;[HrefToken()];kick_all_from_lobby=1;afkonly=0'>everyone</a>/<a href='byond://?_src_=holder;[HrefToken()];kick_all_from_lobby=1;afkonly=1'>AFKers</a> in lobby
					<p>
				</td>
			</tr>
			<tr id='search_tr'>
				<td align='center'>
					<b>Search:</b> <input type='text' id='filter' value='' style='width:300px;'>
				</td>
			</tr>
	</table>

	"}

	//player table header
	dat += {"
		<span id='maintable_data_archive'>
		<table width='560' align='center' cellspacing='0' cellpadding='5' id='maintable_data'>"}

	var/list/mobs = sortmobs()
	var/i = 1
	for(var/mob/M in mobs)
		if(M.ckey)

			var/color = "#e6e6e6"
			if(i%2 == 0)
				color = "#f2f2f2"
			var/is_antagonist = is_special_character(M)

			var/M_job = ""

			if(isliving(M))

				if(iscarbon(M)) //Carbon stuff
					if(ishuman(M))
						var/mob/living/carbon/human/H = M
						M_job = H.job
					else if(isslime(M))
						M_job = "Slime"
					else if(issmall(M))
						M_job = "Monkey"
					else
						M_job = "Carbon-based"

				else if(issilicon(M)) //silicon
					if(isAI(M))
						M_job = "AI"
					else if(ispAI(M))
						M_job = ROLE_PAI
					else if(isrobot(M))
						M_job = "Robot"
					else
						M_job = "Silicon-based"

				else if(isanimal(M)) //simple animals
					if(iscorgi(M))
						M_job = "Corgi"
					else if(isslime(M))
						M_job = "slime"
					else
						M_job = "Animal"

				else
					M_job = "Living"

			else if(isnewplayer(M))
				M_job = "New player"

			else if(isghost(M))
				M_job = "Ghost"
			else
				M_job = "Unknown ([M.type])"

			M_job = replacetext(M_job, "'", "")
			M_job = replacetext(M_job, "\"", "")
			M_job = replacetext(M_job, "\\", "")

			var/M_name = M.name
			M_name = replacetext(M_name, "'", "")
			M_name = replacetext(M_name, "\"", "")
			M_name = replacetext(M_name, "\\", "")
			var/M_rname = M.real_name
			M_rname = replacetext(M_rname, "'", "")
			M_rname = replacetext(M_rname, "\"", "")
			M_rname = replacetext(M_rname, "\\", "")

			var/M_key = M.key
			M_key = replacetext(M_key, "'", "")
			M_key = replacetext(M_key, "\"", "")
			M_key = replacetext(M_key, "\\", "")

			var/M_rname_as_key = html_encode(ckey(M.real_name)) // so you can ignore punctuation
			var/previous_names = ""

			if(M_key)
				var/datum/persistent_client/P = GLOB.persistent_clients_by_ckey[ckey(M_key)]
				if(P)
					previous_names = P.get_played_names()

			//output for each mob
			dat += {"

				<tr id='data[i]' name='[i]' onClick="addToLocked('item[i]','data[i]','notice_span[i]')">
					<td align='center' bgcolor='[color]'>
						<span id='notice_span[i]'></span>
						<a id='link[i]'
						onmouseover='expand("data[i]","item[i]")'
						>
						<b id='search[i]'>[M_name] - [M_rname] - [M_key] ([M_job])</b>
						<span hidden class='filter_data'>[M_name] [M_rname] [M_rname_as_key] [M_key] [M_job] [previous_names]</span>
						<span hidden id="data[i]_name">[M_name]</span>
						<span hidden id="data[i]_job">[M_job]</span>
						<span hidden id="data[i]_rname">[M_rname]</span>
						<span hidden id="data[i]_rname_as_key">[M_rname_as_key]</span>
						<span hidden id="data[i]_prevnames">[previous_names]</span>
						<span hidden id="data[i]_key">[M_key]</span>
						<span hidden id="data[i]_lastip">[M.lastKnownIP]</span>
						<span hidden id="data[i]_isantag">[is_antagonist]</span>
						<span hidden id="data[i]_ref">[REF(M)]</span>
						</a>
						<br><span id='item[i]'></span>
					</td>
				</tr>

			"}

			i++


	//player table ending
	dat += {"
		</table>
		</span>

		<script type='text/javascript'>
			var maintable = document.getElementById("maintable_data_archive");
			var complete_list = maintable.innerHTML;
		</script>
	</body></html>
	"}

	var/window_size = "size=600x480"
	if(owner.window_scaling && ui_scale)
		window_size = "size=[600 * owner.window_scaling]x[400 * owner.window_scaling]"

	usr << browse(dat, "window=players;[window_size]")

/datum/admins/proc/storyteller_panel()
	var/datum/storyteller/ST = get_storyteller()
	if(ST)
		ST.storyteller_panel()
	else
		to_chat(usr, span_warning("There is no storyteller."))

/datum/admins/proc/cmd_show_exp_panel(client/client_to_check)
	if(!check_rights(R_ADMIN))
		return
	if(!client_to_check)
		to_chat(usr, span_danger("ERROR: Client not found."), confidential = TRUE)
		return
	if(!CONFIG_GET(flag/use_exp_tracking))
		to_chat(usr, span_warning("Tracking is disabled in the server configuration file."), confidential = TRUE)
		return

	new /datum/job_report_menu(client_to_check, usr)
