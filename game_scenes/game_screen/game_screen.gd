extends Node2D

# Enhanced game_screen.gd - Connected Attack Chain System Integration

# Core game references
var aCards = []
var dCards = []
var attackbuttons = []
var defendbuttons = []
var timers = []

# Game state variables
var save_path = OS.get_user_data_dir() + "/seacat_connected_game_data.csv"
var currenttimer = 0
var timeTaken = 0
var game_won = false

# Connected attack chain system variables
var current_roll_results = []
var attack_progress_bars = []

# UI icons
var playIcon = preload("res://images/UI_images/play_button.png")
var pauseIcon = preload("res://images/UI_images/pause_button.png")

# Enhanced dice system
var use_dice_system = true
var dice_popup_scene = preload("res://game_scenes/dice_screen/dice_popup.tscn")
var active_dice_popup = null

# Round tracking
var round_number = 1

func _ready():
	initialize_connected_game()
	setup_connections()

func initialize_connected_game():
	"""Initialize the game with connected attack chain system"""
	# Initialize card arrays with null checks
	aCards = []
	dCards = []
	
	# Safely get attack cards
	for i in range(1, 4):
		var card_node = get_node_or_null("a_" + str(i))
		if card_node:
			aCards.append(card_node)
			card_node.cardType = "a"
			var card_back = card_node.get_node_or_null("card/card_back")
			if card_back:
				card_back.frame = 4
		else:
			print("Warning: Attack card a_", i, " not found")
	
	# Safely get defense cards
	for i in range(1, 4):
		var card_node = get_node_or_null("d_" + str(i))
		if card_node:
			dCards.append(card_node)
			card_node.cardType = "d"
			var card_back = card_node.get_node_or_null("card/card_back")
			if card_back:
				card_back.frame = 3
		else:
			print("Warning: Defense card d_", i, " not found")
	
	# Setup button arrays
	setup_button_arrays()
	
	# Connect dropdown to card arrays
	var dropdown = get_node_or_null("dropdown")
	if dropdown and dropdown.has_method("set_card_references"):
		dropdown.set_card_references(aCards, dCards)
	
	# Initialize timers
	setup_timers()
	
	# Initial states
	disable_attack_buttons(true)
	disable_defend_buttons(true)
	
	var window = get_node_or_null("Window")
	if window:
		window.visible = false
	var end_game = get_node_or_null("EndGame")
	if end_game:
		end_game.visible = false
	
	currenttimer = 0
	
	# Setup enhanced save file for connected system
	setup_connected_save_file()
	
	# Setup connected attack chain progress UI
	setup_connected_attack_chain_progress_ui()
	
	# Initialize GameData connected attack chains
	if GameData:
		GameData.reset_attack_chains()
		print("=== CONNECTED ATTACK CHAIN SYSTEM INITIALIZED ===")
		print("Round: ", round_number)
		GameData.debug_show_game_state()
	
	# Start background music
	if has_node("/root/Music"):
		var music = get_node("/root/Music")
		if music.has_method("play_music"):
			music.play_music()

func setup_button_arrays():
	"""Setup attack and defense button arrays"""
	attackbuttons = []
	defendbuttons = []
	
	var attack_dropdown = get_node_or_null("dropdown/attack_option")
	var attack_submit = get_node_or_null("AttackSubmit")
	var defend_dropdown = get_node_or_null("dropdown/defend_option")
	var defend_submit = get_node_or_null("DefenseSubmit")
	
	if attack_dropdown:
		attackbuttons.append(attack_dropdown)
	if attack_submit:
		attackbuttons.append(attack_submit)
	if defend_dropdown:
		defendbuttons.append(defend_dropdown)
	if defend_submit:
		defendbuttons.append(defend_submit)

func setup_timers():
	"""Setup timer references and initial states"""
	timers = []
	var timer1 = get_node_or_null("Timer_Label")
	var timer2 = get_node_or_null("Timer_Label2")
	
	if timer1:
		timers.append(timer1)
		var pause_button = timer1.get_node_or_null("pause")
		if pause_button:
			pause_button.disabled = true
		
		# Initialize timer display
		if timer1.has_method("get") and timer1.initialTime != null:
			var initialTime = timer1.initialTime
			var minutes = int(initialTime) / 60
			var seconds = int(initialTime) % 60
			timer1.text = str(minutes) + (":%02d" % seconds)
	
	if timer2:
		timers.append(timer2)
		if timer2.has_method("get") and timer2.initialTime != null:
			var initialTime = timer2.initialTime
			var minutes = int(initialTime) / 60
			var seconds = int(initialTime) % 60
			timer2.text = str(minutes) + (":%02d" % seconds)

func setup_connections():
	"""Setup signal connections for connected attack chain system"""
	if GameData:
		# Connect attack chain signals
		if not GameData.dice_roll_completed_signal.is_connected(_on_dice_roll_completed):
			GameData.dice_roll_completed_signal.connect(_on_dice_roll_completed)
		if not GameData.attack_chain_victory.is_connected(_on_attack_chain_victory):
			GameData.attack_chain_victory.connect(_on_attack_chain_victory)
		if not GameData.timeline_victory.is_connected(_on_timeline_victory):
			GameData.timeline_victory.connect(_on_timeline_victory)
		# Connect discussion time signal for enhanced dice system
		if not GameData.discussion_time_needed.is_connected(_on_discussion_time_completed):
			GameData.discussion_time_needed.connect(_on_discussion_time_completed)

func setup_connected_save_file():
	"""Setup CSV with headers for connected attack chain tracking"""
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		var headers = [
			"Round", "Timestamp", "Position_1_Start", "Position_2_Start", "Position_3_Start",
			"Attack_1", "Attack_1_Cost", "Attack_1_Time", "Attack_1_Type", 
			"Attack_2", "Attack_2_Cost", "Attack_2_Time", "Attack_2_Type",
			"Attack_3", "Attack_3_Cost", "Attack_3_Time", "Attack_3_Type",
			"Defense_1", "Defense_1_Maturity", "Defense_1_Eviction",
			"Defense_2", "Defense_2_Maturity", "Defense_2_Eviction",
			"Defense_3", "Defense_3_Maturity", "Defense_3_Eviction",
			"Result_1", "Roll_1", "Success_1", "New_State_1",
			"Result_2", "Roll_2", "Success_2", "New_State_2",
			"Result_3", "Roll_3", "Success_3", "New_State_3",
			"Position_1_End", "Position_2_End", "Position_3_End",
			"Red_Victory", "Round_Notes"
		]
		file.store_csv_line(headers)
		file.close()
		print("Connected attack chain save file initialized: ", save_path)

func setup_connected_attack_chain_progress_ui():
	"""Setup UI elements for connected attack chain progress tracking"""
	attack_progress_bars = []
	
	# Create or find progress display container
	var progress_display = get_node_or_null("ConnectedAttackProgressDisplay")
	if not progress_display:
		progress_display = VBoxContainer.new()
		progress_display.name = "ConnectedAttackProgressDisplay"
		progress_display.position = Vector2(50, 200)
		add_child(progress_display)
		
		# Add title label
		var title_label = Label.new()
		title_label.text = "Connected Attack Chain Progress:"
		title_label.add_theme_font_size_override("font_size", 16)
		title_label.add_theme_color_override("font_color", Color.WHITE)
		progress_display.add_child(title_label)
		
		# Add explanation label
		var explanation_label = Label.new()
		explanation_label.text = "Red team wins when ANY position reaches E/E"
		explanation_label.add_theme_font_size_override("font_size", 12)
		explanation_label.modulate = Color.YELLOW
		progress_display.add_child(explanation_label)
		
		# Add rules label
		var rules_label = Label.new()
		rules_label.text = "IA → PEP → E/E | Invalid plays auto-fail"
		rules_label.add_theme_font_size_override("font_size", 10)
		rules_label.modulate = Color.CYAN
		progress_display.add_child(rules_label)
	
	# Create progress bars for each position
	for i in range(3):
		var progress_container = create_connected_progress_display(i)
		progress_display.add_child(progress_container)
		attack_progress_bars.append(progress_container)

func create_connected_progress_display(position_index: int) -> Control:
	"""Create progress display for a connected attack position"""
	var container = HBoxContainer.new()
	container.name = "AttackProgress" + str(position_index)
	container.add_theme_constant_override("separation", 5)
	
	# Position label
	var label = Label.new()
	label.text = "Position " + str(position_index + 1) + ":"
	label.custom_minimum_size = Vector2(80, 25)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color.WHITE)
	container.add_child(label)
	
	# Progress steps for connected system
	var steps = ["EMPTY", "IA", "PEP", "E/E"]
	for i in range(steps.size()):
		var step_panel = Panel.new()
		step_panel.custom_minimum_size = Vector2(50, 25)
		step_panel.name = "Step" + str(i)
		
		var step_label = Label.new()
		step_label.text = steps[i]
		step_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		step_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		step_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		step_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		step_label.name = "StepLabel"
		step_label.add_theme_color_override("font_color", Color.WHITE)
		
		step_panel.add_child(step_label)
		container.add_child(step_panel)
		
		# Add arrow between steps (except after last step)
		if i < steps.size() - 1:
			var arrow_label = Label.new()
			arrow_label.text = "→"
			arrow_label.custom_minimum_size = Vector2(20, 25)
			arrow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			arrow_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			arrow_label.add_theme_color_override("font_color", Color.WHITE)
			container.add_child(arrow_label)
	
	return container

func _process(_delta):
	"""Main game loop"""
	handle_card_expansion_state()
	update_timer_display()
	update_theme_background()
	update_connected_attack_progress_display()
	check_connected_game_end_conditions()
	
	if Input.is_action_just_pressed("exit"):
		get_tree().quit()

func handle_card_expansion_state():
	"""Handle card expansion logic to prevent multiple expansions"""
	var attack_expanded = false
	var defense_expanded = false
	
	for card in aCards:
		if card and card.expanded:
			attack_expanded = true
			break
	
	for card in dCards:
		if card and card.expanded:
			defense_expanded = true
			break
	
	# Disable other cards when one is expanded
	if attack_expanded:
		for card in aCards:
			if card and not card.expanded:
				if card.has_method("disable_expand"):
					card.disable_expand(true)
	else:
		for card in aCards:
			if card and card.inPlay:
				if card.has_method("disable_expand"):
					card.disable_expand(false)
				if card.has_method("disable_flip"):
					card.disable_flip(false)
	
	if defense_expanded:
		for card in dCards:
			if card and not card.expanded:
				if card.has_method("disable_expand"):
					card.disable_expand(true)
	else:
		for card in dCards:
			if card and card.inPlay:
				if card.has_method("disable_expand"):
					card.disable_expand(false)
				if card.has_method("disable_flip"):
					card.disable_flip(false)

func update_timer_display():
	"""Update timer display and pause button icon"""
	var timer1 = get_node_or_null("Timer_Label")
	var timer2 = get_node_or_null("Timer_Label2")
	
	if timer1 and timer1.play == true:
		currenttimer = 0
	elif timer2 and timer2.play == true:
		currenttimer = 1
	
	# Update pause button icon
	var pause_button = get_node_or_null("Timer_Label/pause")
	if pause_button:
		var timer1_playing = timer1 and timer1.play == true
		var timer2_playing = timer2 and timer2.play == true
		pause_button.icon = playIcon if not (timer1_playing or timer2_playing) else pauseIcon

func update_theme_background():
	"""Update background based on current theme"""
	var background = get_node_or_null("background")
	if background and has_node("/root/Settings"):
		var settings = get_node("/root/Settings")
		match settings.theme:
			0: background.texture = load("res://images/UI_images/progress_bar/underwater/water_background.png")
			1: background.texture = load("res://images/UI_images/progress_bar/air/Air Background.png")
			2: background.texture = load("res://images/UI_images/progress_bar/land/Land Background.png")

func update_connected_attack_progress_display():
	"""Update connected attack chain progress displays"""
	if not GameData:
		return
	
	# Get current position states
	var position_states = GameData.get_position_states_snapshot()
	
	for i in range(min(position_states.size(), attack_progress_bars.size())):
		var state_info = position_states[i]
		var display = attack_progress_bars[i]
		
		if not display:
			continue
		
		# Update step highlighting based on position state
		var steps = ["EMPTY", "IA", "PEP", "E/E"]
		var current_state = state_info.state
		var current_step_index = steps.find(current_state)
		
		for j in range(steps.size()):
			var step_panel = display.get_node_or_null("Step" + str(j))
			if step_panel:
				var step_label = step_panel.get_node_or_null("StepLabel")
				if step_label:
					if j <= current_step_index:
						# Current or completed steps
						if j == current_step_index:
							# Current step
							if current_state == "E/E":
								step_label.modulate = Color.GOLD  # Victory state
								step_panel.modulate = Color(1.0, 0.8, 0.0, 0.5)
							else:
								step_label.modulate = Color.YELLOW
								step_panel.modulate = Color(0.8, 0.8, 0.2, 0.3)
						else:
							# Completed steps
							step_label.modulate = Color.GREEN
							step_panel.modulate = Color(0.2, 0.8, 0.2, 0.3)
					else:
						# Future steps
						step_label.modulate = Color.GRAY
						step_panel.modulate = Color(0.5, 0.5, 0.5, 0.1)

func check_connected_game_end_conditions():
	"""Check for connected game end conditions"""
	var timer1 = get_node_or_null("Timer_Label")
	var timer2 = get_node_or_null("Timer_Label2")
	var timeline = get_node_or_null("timeline")
	
	# Check timer expiration (Blue team victory)
	var timer1_expired = timer1 and timer1.initialTime <= 0
	var timer2_expired = timer2 and timer2.initialTime <= 0
	
	# Check timeline completion (Blue team victory)
	var timeline_completed = false
	if timeline:
		var current_round = timeline.current_round if timeline.has_method("get") else 0
		var round_end = timeline.round_end if timeline.has_method("get") else 100
		timeline_completed = current_round >= round_end
	
	# Connected attack chain victory handled by GameData signal
	
	if timer1_expired or timer2_expired or timeline_completed:
		handle_blue_team_victory("Time/Timeline completed")

func handle_red_team_victory(reason: String):
	"""Handle Red Team (connected attack chain) victory"""
	print("🔴 RED TEAM WINS: ", reason)
	game_won = true
	
	# Export final game data
	if GameData and GameData.has_method("export_game_data_to_csv"):
		var final_data = GameData.export_game_data_to_csv()
		var final_path = OS.get_user_data_dir() + "/seacat_connected_final_export.csv"
		var file = FileAccess.open(final_path, FileAccess.WRITE)
		if file:
			file.store_string(final_data)
			file.close()
			print("Final connected game data exported to: ", final_path)
	
	show_victory_screen("🔴 RED TEAM VICTORY!", reason, Color.RED)

func handle_blue_team_victory(reason: String):
	"""Handle Blue Team (defense) victory"""
	print("🔵 BLUE TEAM WINS: ", reason)
	game_won = true
	show_victory_screen("🔵 BLUE TEAM VICTORY!", reason, Color.BLUE)

func show_victory_screen(title: String, reason: String, color: Color):
	"""Show victory screen with team colors"""
	var victory_label = get_node_or_null("VictoryLabel")
	if not victory_label:
		victory_label = Label.new()
		victory_label.name = "VictoryLabel"
		victory_label.position = Vector2(400, 300)
		victory_label.add_theme_font_size_override("font_size", 32)
		victory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		victory_label.add_theme_color_override("font_color", Color.WHITE)
		add_child(victory_label)
	
	victory_label.text = title + "\n" + reason
	victory_label.modulate = color
	victory_label.visible = true
	
	# Auto-transition to game over after delay
	await get_tree().create_timer(3.0).timeout
	_on_quit_button_pressed()

# Enhanced dice system event handlers
func show_enhanced_dice_popup():
	"""Show enhanced dice popup for connected attack chain system"""
	if active_dice_popup:
		return
	
	print("=== SHOWING ENHANCED DICE POPUP ===")
	print("Round: ", round_number)
	if GameData:
		GameData.debug_show_game_state()
	
	active_dice_popup = dice_popup_scene.instantiate()
	add_child(active_dice_popup)
	
	# Ensure proper size and positioning
	active_dice_popup.position = Vector2.ZERO
	active_dice_popup.size = Vector2(1152, 648)
	active_dice_popup.z_index = 100
	
	# Connect signals
	if active_dice_popup.has_signal("dice_completed"):
		active_dice_popup.dice_completed.connect(_on_enhanced_dice_completed)
	if active_dice_popup.has_signal("dice_cancelled"):
		active_dice_popup.dice_cancelled.connect(_on_dice_popup_cancelled)

func _on_enhanced_dice_completed(results: Array):
	"""Handle completion of enhanced dice rolling with individual results"""
	print("=== ENHANCED DICE COMPLETED ===")
	print("Individual results received: ", results.size())
	
	current_roll_results = results.duplicate()
	
	# Record individual results in GameData (this will process the connected logic)
	if GameData:
		GameData.record_dice_results(results)
	
	close_dice_popup()
	
	# Process results and continue connected game flow
	process_connected_attack_results()

func _on_discussion_time_completed(results: Array):
	"""Handle discussion time completion from GameData"""
	print("=== DISCUSSION TIME COMPLETED ===")
	# The dice popup handles the discussion, so we continue game flow here
	continue_connected_game_flow()

func process_connected_attack_results():
	"""Process the results of connected attack chains"""
	if current_roll_results.size() == 0:
		return
	
	print("=== PROCESSING CONNECTED ATTACK RESULTS ===")
	
	# Show individual result summary
	for result in current_roll_results:
		var status = "SUCCESS" if result.success else "FAILURE"
		if result.has("invalid_play") and result.invalid_play:
			status = "INVALID PLAY"
		elif result.auto_success:
			status = "AUTO SUCCESS"
		
		print("Attack ", result.attack_index + 1, ": ", result.attack_name, " - ", status)
		if result.has("individual_cost"):
			print("  Individual calculation: Cost ", result.individual_cost, "/Time ", result.individual_time, " = ", result.success_percentage, "%")
	
	# Build and save comprehensive CSV data
	var row = build_connected_csv_row()
	save_connected_game_data(row)
	
	# Progress to next round
	round_number += 1
	if GameData:
		GameData.prepare_next_round()
	
	# Reset for next round
	current_roll_results.clear()

func build_connected_csv_row() -> Array:
	"""Build CSV row for connected attack chain system"""
	var timestamp = Time.get_time_string_from_system()
	var row = [str(round_number - 1), timestamp]  # -1 because we increment after
	
	# Get position states from GameData
	var starting_positions = []
	var ending_positions = []
	
	if GameData:
		var history = GameData.game_history
		if history.size() > 0:
			var latest_round = history[history.size() - 1]
			starting_positions = latest_round.get("starting_positions", [])
			ending_positions = latest_round.get("ending_positions", [])
	
	# Add starting positions
	for i in range(3):
		if i < starting_positions.size():
			row.append(starting_positions[i].state)
		else:
			row.append("EMPTY")
	
	# Add individual attack card data
	for i in range(3):
		var found_result = false
		for result in current_roll_results:
			if result.attack_index == i:
				row.append(result.attack_name)
				row.append(result.individual_cost if result.has("individual_cost") else "N/A")
				row.append(result.individual_time if result.has("individual_time") else "N/A")
				# Determine attack type from GameData
				var attack_type = "IA"  # Default
				if GameData and GameData.current_attack_cards.size() > i:
					attack_type = GameData.current_attack_cards[i].get("card_type", "IA")
				row.append(attack_type)
				found_result = true
				break
		
		if not found_result:
			row.append_array(["---", "---", "---", "---"])
	
	# Add defense data
	for i in range(3):
		if i < dCards.size() and dCards[i] and dCards[i].card_index != -1:
			var card = dCards[i]
			row.append(get_defense_name_safe(card))
			row.append(card.getMaturityValue() if card.has_method("getMaturityValue") else 1)
			# Check if eviction card
			var is_eviction = false
			if GameData:
				is_eviction = GameData.is_eviction_card(card)
			row.append("Yes" if is_eviction else "No")
		else:
			row.append_array(["---", "---", "---"])
	
	# Add individual results
	for i in range(3):
		var found_result = false
		for result in current_roll_results:
			if result.attack_index == i:
				row.append("Success" if result.success else "Failure")
				row.append("AUTO" if result.auto_success else result.roll_result)
				row.append("Yes" if result.success else "No")
				# Determine new state
				var new_state = "Unknown"
				if ending_positions.size() > i:
					new_state = ending_positions[i].state
				row.append(new_state)
				found_result = true
				break
		
		if not found_result:
			row.append_array(["---", "---", "---", "---"])
	
	# Add ending positions
	for i in range(3):
		if i < ending_positions.size():
			row.append(ending_positions[i].state)
		else:
			row.append("EMPTY")
	
	# Check for red team victory
	var red_victory = false
	for pos in ending_positions:
		if pos.state == "E/E":
			red_victory = true
			break
	row.append("Yes" if red_victory else "No")
	
	# Add round notes
	var notes = "Round " + str(round_number - 1) + " completed. "
	var successes = 0
	for result in current_roll_results:
		if result.success:
			successes += 1
	notes += str(successes) + "/" + str(current_roll_results.size()) + " attacks succeeded."
	row.append(notes)
	
	return row

func save_connected_game_data(row: Array):
	"""Save connected game data to CSV file"""
	var file = FileAccess.open(save_path, FileAccess.READ_WRITE)
	if file:
		file.seek_end()
		file.store_csv_line(row)
		file.close()
		print("Connected game data saved for round ", round_number - 1)

func get_defense_name_safe(defense_card) -> String:
	"""Get defense card name safely"""
	if not defense_card:
		return "No Defense"
	
	var card_index = defense_card.card_index
	if has_node("/root/Mitre"):
		var mitre = get_node("/root/Mitre")
		if mitre.defend_dict.has(card_index + 1):
			return mitre.defend_dict[card_index + 1][3]  # Defense: index 3 = Name
	return "Defense Card"

func continue_connected_game_flow():
	"""Continue game flow after connected attack resolution"""
	var timer1 = get_node_or_null("Timer_Label")
	var pause_button = get_node_or_null("Timer_Label/pause")
	var timeline = get_node_or_null("timeline")
	var attack_dropdown = get_node_or_null("dropdown/attack_option")
	var defend_dropdown = get_node_or_null("dropdown/defend_option")
	
	# Reset and prepare for next round
	reset_cards_for_next_round()
	
	# Resume attack phase
	disable_attack_buttons(false)
	for card in aCards:
		if card and card.has_method("disable_buttons"):
			card.disable_buttons(true)
	
	if pause_button:
		pause_button.disabled = false
	if timer1:
		timer1.play = true
	
	# Progress timeline (if applicable)
	var total_time = calculate_total_time_used()
	if timeline and timeline.has_method("_progress"):
		timeline._progress(total_time * 25)
	if timeline and timeline.has_method("increase_time"):
		timeline.increase_time()
	
	# Reset dropdowns
	if attack_dropdown and attack_dropdown.has_method("select"):
		attack_dropdown.select(-1)
	if defend_dropdown and defend_dropdown.has_method("select"):
		defend_dropdown.select(-1)
	
	print("=== ROUND ", round_number, " READY ===")
	if GameData:
		GameData.debug_show_game_state()

func calculate_total_time_used() -> int:
	"""Calculate total time used by all successful attacks"""
	var total_time = 0
	for result in current_roll_results:
		if result.success and result.has("individual_time"):
			total_time += result.individual_time
	return total_time

func reset_cards_for_next_round():
	"""Reset all cards for the next round"""
	for card in aCards:
		if card:
			if card.expanded:
				if card.has_method("make_small_again"):
					card.make_small_again()
			if card.has_method("reset_card"):
				card.reset_card()
	
	for card in dCards:
		if card:
			if card.expanded:
				if card.has_method("make_small_again"):
					card.make_small_again()
			if card.has_method("reset_card"):
				card.reset_card()

# Game flow control functions
func disable_attack_buttons(state: bool):
	"""Disable/enable attack buttons and cards"""
	for button in attackbuttons:
		if button:
			button.disabled = state
	for card in aCards:
		if card and card.inPlay:
			if card.has_method("disable_buttons"):
				card.disable_buttons(state)

func disable_defend_buttons(state: bool):
	"""Disable/enable defense buttons and cards"""
	for button in defendbuttons:
		if button:
			button.disabled = state
	for card in dCards:
		if card and card.has_method("disable_buttons"):
			card.disable_buttons(state)

func collapse_all_cards():
	"""Collapse all expanded cards"""
	for card in aCards + dCards:
		if card and card.expanded:
			if card.has_method("make_small_again"):
				card.make_small_again()

func has_active_attacks() -> bool:
	"""Check if there are active attack cards"""
	for card in aCards:
		if card and card.card_index != -1:
			return true
	return false

func has_active_defenses() -> bool:
	"""Check if there are active defense cards"""
	for card in dCards:
		if card and card.card_index != -1:
			return true
	return false

# Signal handlers for connected attack chain system
func _on_attack_chain_victory():
	"""Handle Red Team victory through connected attack chains"""
	handle_red_team_victory("Connected attack chain reached E/E!")

func _on_timeline_victory():
	"""Handle Blue Team victory through timeline completion"""
	handle_blue_team_victory("Timeline completed")

func _on_dice_roll_completed():
	"""Legacy compatibility for GameData signal"""
	print("Legacy dice roll completed signal received")

func _on_dice_popup_cancelled():
	"""Handle dice popup cancellation"""
	close_dice_popup()
	# Return to defense phase
	disable_defend_buttons(false)
	var pause_button = get_node_or_null("Timer_Label/pause")
	if pause_button:
		pause_button.disabled = false

func close_dice_popup():
	"""Close the active dice popup"""
	if active_dice_popup:
		active_dice_popup.queue_free()
		active_dice_popup = null

# Standard game event handlers
func _on_pause_pressed():
	"""Handle pause button press"""
	var timer1 = get_node_or_null("Timer_Label")
	var timer2 = get_node_or_null("Timer_Label2")
	
	if currenttimer == 0 and timer1:
		timer1.play = !timer1.play
		disable_attack_buttons(!timer1.play)
		if timer1.play:
			disable_defend_buttons(true)
	elif currenttimer == 1 and timer2:
		timer2.play = !timer2.play
		disable_attack_buttons(!timer2.play)
		if timer2.play:
			disable_defend_buttons(false)

func _on_start_game_pressed():
	"""Handle start game button press"""
	var timer1 = get_node_or_null("Timer_Label")
	var pause_button = get_node_or_null("Timer_Label/pause")
	var start_game = get_node_or_null("CanvasLayer/StartGame")
	var color_rect = get_node_or_null("CanvasLayer/ColorRect")
	var end_game = get_node_or_null("EndGame")
	
	if timer1:
		timer1.play = true
	disable_attack_buttons(false)
	for card in aCards:
		if card and card.has_method("disable_buttons"):
			card.disable_buttons(true)
	if pause_button:
		pause_button.disabled = false
	if start_game:
		start_game.visible = false
	if color_rect:
		color_rect.visible = false
	if end_game:
		end_game.visible = true
	
	print("=== CONNECTED ATTACK CHAIN GAME STARTED ===")
	print("Round: ", round_number)

func _on_attack_submit_pressed():
	"""Handle attack submit button press"""
	if not has_active_attacks():
		return
	
	collapse_all_cards()
	var timer1 = get_node_or_null("Timer_Label")
	var timer2 = get_node_or_null("Timer_Label2")
	var defense_submit = get_node_or_null("DefenseSubmit")
	
	if timer1:
		timer1.play = false
	if timer2:
		timer2.play = true
	disable_attack_buttons(true)
	disable_defend_buttons(false)
	for card in dCards:
		if card and card.has_method("disable_buttons"):
			card.disable_buttons(true)
	if defense_submit:
		defense_submit.disabled = false

func _on_defense_submit_pressed():
	"""Handle defense submit button press - start connected attack resolution"""
	collapse_all_cards()
	var timer2 = get_node_or_null("Timer_Label2")
	var pause_button = get_node_or_null("Timer_Label/pause")
	
	if timer2:
		timer2.play = false
	disable_defend_buttons(true)
	if pause_button:
		pause_button.disabled = true
	
	# Capture current card state for connected attack system
	if use_dice_system and GameData:
		print("=== STARTING CONNECTED ATTACK RESOLUTION ===")
		print("Round: ", round_number)
		GameData.capture_current_cards(aCards, dCards)
		
		# Debug output to verify connected calculations
		if GameData.has_method("debug_show_attack_table"):
			GameData.debug_show_attack_table()
		if GameData.has_method("debug_show_game_state"):
			GameData.debug_show_game_state()
		
		# Add a small delay to ensure UI updates
		await get_tree().create_timer(0.1).timeout
		show_enhanced_dice_popup()
	else:
		show_manual_input()

func show_manual_input():
	"""Show manual input window (legacy fallback)"""
	var window = get_node_or_null("Window")
	if window:
		window.visible = true

# Other standard event handlers (end game, quit, etc.) remain the same
func _on_end_game_pressed():
	"""Handle end game button press"""
	_on_pause_pressed()
	var end_game = get_node_or_null("EndGame")
	var pause_button = get_node_or_null("Timer_Label/pause")
	var window2 = get_node_or_null("Window2")
	if end_game:
		end_game.disabled = true
	if pause_button:
		pause_button.disabled = true
	if window2:
		window2.visible = true

func _on_quit_button_pressed():
	"""Handle quit button press"""
	if has_node("/root/Music"):
		var music = get_node("/root/Music")
		if music.has_method("mouse_click"):
			music.mouse_click()
	get_tree().change_scene_to_file("res://game_scenes/game_over_screen/game_over.tscn")

func _on_continue_button_pressed():
	"""Handle continue button press"""
	_on_pause_pressed()
	var end_game = get_node_or_null("EndGame")
	var pause_button = get_node_or_null("Timer_Label/pause")
	var window2 = get_node_or_null("Window2")
	if end_game:
		end_game.disabled = false
	if pause_button:
		pause_button.disabled = false
	if window2:
		window2.visible = false

func _on_help_pressed():
	"""Handle help button press"""
	var window5 = get_node_or_null("Window5")
	if window5:
		window5.visible = true

func _on_window_close_requested():
	"""Handle help window close"""
	var window5 = get_node_or_null("Window5")
	if window5:
		window5.visible = false

# Legacy event handlers for manual input compatibility
func _on_option_button_item_selected(index):
	"""Handle manual option selection (legacy compatibility)"""
	pass

func _on_spin_box_value_changed(value):
	"""Handle manual spin box value change (legacy compatibility)"""
	pass

func _on_button_pressed():
	"""Handle manual button press (legacy compatibility)"""
	pass
