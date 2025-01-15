competitive_rules_array = [
	faceoff
    permadeath
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

permadeath = {
	text = qs(0x3CE58FD7)
	upper_text = qs(0xbd8a86e3)
	description = qs(0xB1420734)
	full_rules = qs(0x1af46706)
	image = GR_competitive_elimination
	condition = band_lobby_is_private_vs_state
	difficulty = any
	ranking_criteria = Score
	starpower = invincible
	team = 0
	highway_glow = 0
	section_timer = every_section
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
		interval = section
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
		case permadeath
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

script competitive_rank_section_alive \{vocals = 0}
	<local_players_survived> = []
	if (<section> < 0)
		return
	endif
	GetNumPlayersInGame \{local}
	if (<num_players> > 0)
		GetFirstPlayer \{local}
		begin
		getplayerinfo <player> interactive
		getplayerinfo <player> part
		if ((<vocals> = 1) && (<part> = vocals))
			if (<interactive> = 1)
				GMan_GetData goal = competitive player = <player> name = performance_value
				<performance_value> = (<performance_value> + 1)
				GMan_SetData goal = competitive player = <player> params = {performance_value = <performance_value>}
				<local_players_survived> = (<local_players_survived> + <player>)
			endif
		elseif ((<vocals> = 0) && (<part> != vocals))
			if (<interactive> = 1)
				getplayerinfo <player> current_detailedstats_array
				<notes_hit> = (($<current_detailedstats_array>) [<section>])
				GMan_GetData goal = competitive player = <player> name = performance_value
				<performance_value> = (<performance_value> + 1)
				GMan_SetData goal = competitive player = <player> params = {performance_value = <performance_value>}
				<local_players_survived> = (<local_players_survived> + <player>)
			endif
		endif
		GetNextPlayer local player = <player>
		repeat <num_players>
	endif
	GetArraySize <local_players_survived>
	if (<array_size> > 0)
		if (<array_size> = 1)
			sfx_do_or_die_section_won player = (<local_players_survived> [0]) pan_wide = 0
		endif
		elseif (<array_size> = 0)
			GuitarEvent_SongWon
		else
			sfx_do_or_die_section_won player = (<local_players_survived> [0]) pan_wide = 1
		endif
	endif
endscript

