competitive_rules_array = [
	faceoff
	momentum
	momentum_plus
	streakers
	do_or_die
	perfectionist
	elimination
	solo_fest_mode
	team_faceoff
	team_momentum
	team_streakers
	team_do_or_die
	team_perfectionist
	team_elimination
	team_fest_mode
	band_vs_band
]

do_or_die = {
	text = qs(0xc86fae2a)
	upper_text = qs(0xbd8a86e3)
	description = qs(0xeaf8cc07)
	full_rules = qs(0x1af46706)
	image = GR_competitive_elimination
	condition = band_lobby_is_private_vs_state
	difficulty = any
	ranking_criteria = Score
	starpower = invincible
	team = 0
	highway_glow = 0
	section_timer = 5
	elimination_rules = {
		criteria = notes_missed
		criteria_value = 1
		status_display = notes_missed
		interval = instant
		interval_value = 1
		revive_interval = none
		revive_interval_value = 1
		vocals_revive_interval_value = 1
	}
	bonus_rules = {
		criteria = alive
		criteria_value = 1
		interval = instant
		interval_value = 1
		vocals_interval_value = 1
		reward = performance_value
		reward_value = 1
	}
}

script is_game_rule_playable 
	RequireParams \{[
			game_rule
		]
		all}
	reason = default_reason
	is_valid = 0
	switch <game_rule>
		case elimination
		case do_or_die
		case momentum
		case momentum_plus
		case solo_fest_mode
		case perfectionist
		case streakers
		case faceoff
		if band_lobby_is_matching_instruments
			if ($g_lobby_net_state = net_public)
				is_valid = 1
			else
				if band_lobby_satisfy_min_players team = 0 game_rule = <game_rule>
					is_valid = 1
				else
					reason = not_enough_players
				endif
			endif
		else
			reason = need_matching_instruments
		endif
		case team_do_or_die
		case team_momentum
		case team_perfectionist
		case team_elimination
		case team_streakers
		case team_fest_mode
		if ($g_lobby_net_state = net_public)
			if band_lobby_is_matching_instruments
				is_valid = 1
			else
				reason = need_matching_instruments
			endif
		else
			if band_lobby_is_matching_instruments
				if band_lobby_is_even_number_of_instruments
					if band_lobby_satisfy_min_players \{team = 1}
						is_valid = 1
					else
						reason = not_enough_players
					endif
				else
					reason = need_even_number_of_instruments
				endif
			else
				reason = need_matching_instruments
			endif
		endif
		case team_faceoff
		if ($g_lobby_net_state = net_public)
			is_valid = 1
		else
			if band_lobby_is_even_number_of_instruments
				if band_lobby_satisfy_min_players \{team = 1}
					is_valid = 1
				else
					reason = not_enough_players
				endif
			else
				reason = need_even_number_of_instruments
			endif
		endif
		case band_vs_band
		if band_lobby_is_traditional_band
			if ($g_lobby_net_state = net_public)
				is_valid = 1
			else
				if band_lobby_is_even_number_of_instruments
					if band_lobby_satisfy_min_players \{team = 1}
						is_valid = 1
					else
						reason = not_enough_players
					endif
				else
					reason = need_even_number_of_instruments
				endif
			endif
		endif
		default
		<is_valid> = 0
	endswitch
	if (<is_valid> = 1)
		return game_rule_playable = <is_valid>
	else
		return game_rule_playable = <is_valid> not_playable_reason = <reason>
	endif
endscript

script competitive_main_elimination_watcher_varUpdated 
	<ruleset> = ($competitive_rules)
	competitive_update_band_meter
	getplayerinfo <player> is_onscreen
	getplayerinfo <player> part
	if (<is_onscreen> = 1)
		if (<part> = vocals)
			if (<current_value> = 1)
				hud_vocal_dead_script player = <player>
				SetPlayerInfo <player> scoring = 0
				FormatText checksumname = event_name 'competitive_player_eliminated_p%p' p = <player>
				broadcastevent type = <event_name> Data = {player = <player>}
			else
				hud_vocal_revive player = <player>
				SetPlayerInfo <player> scoring = 1
			endif
		else
			if (<current_value> = 1)
				get_highway_hud_root_id player = <player>
				if ScreenElementExists id = <highway_hud_root>
					SetScreenElementProps id = <highway_hud_root> skull_alpha = 1.0
				endif
				LaunchGemEvent event = kill_objects_and_switch_player_non_interactive player = <player>
				WhammyFXOffAll player = <player>
				FormatText checksumname = event_name 'competitive_player_eliminated_p%p' p = <player>
				broadcastevent type = <event_name> Data = {player = <player>}
			else
				get_highway_hud_root_id player = <player>
				if ScreenElementExists id = <highway_hud_root>
					SetScreenElementProps id = <highway_hud_root> skull_alpha = 0.0
				endif
				getsongtimems
				SetPlayerInfo <player> interactive = 1
				SetPlayerInfo <player> last_noninteractive_end_time = <time>
			endif
		endif
	endif
	if (<part> != vocals)
		if StructureContains structure = $<ruleset> bonus_rules
			<bonus_ruleset> = ($<ruleset>.bonus_rules)
			if StructureContains structure = <bonus_ruleset> criteria
				if (<bonus_ruleset>.criteria = alive)
					competitive_check_all_players_eliminated
					if (<all_players_eliminated> = 1)
						if (<ruleset> = do_or_die)
							GuitarEvent_SongWon
						endif
						GMan_TimerFunc goal = <goal_id> tool = section_timer func = get_precise_time
						if (<time> > 10000)
							KillSpawnedScript \{name = competitive_delayed_revive}
							SpawnScript \{id = competitive
								competitive_delayed_revive
								params = {
									delay = 2
								}}
						else
						endif
					endif
				endif
			endif
		endif
	endif
	if ($<ruleset>.ranking_criteria = elimination_order)
		competitive_elimination_check_for_winner
	endif
endscript