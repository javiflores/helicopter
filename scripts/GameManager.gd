extends Node

var game_data: Dictionary = {}

# Objective Tracking
var total_objectives: int = 0
var completed_objectives: int = 0
signal objective_updated(completed, total)
signal all_objectives_completed
signal boss_activated(boss_node)
signal boss_health_updated(current, max)

var active_objective_nodes: Array[Node3D] = []
signal objective_registered(node)
signal objective_completed(node)

var run_time: float = 0.0

func _process(delta):
	run_time += delta

func reset_objectives():
	total_objectives = 0
	completed_objectives = 0
	active_objective_nodes.clear()
	objective_updated.emit(0, 0)
	print("Objectives reset.")

func register_objective(node: Node3D = null):
	total_objectives += 1
	if node:
		active_objective_nodes.append(node)
		objective_registered.emit(node)
	objective_updated.emit(completed_objectives, total_objectives)

func complete_objective(node: Node3D = null):
	completed_objectives += 1
	if node:
		if node in active_objective_nodes:
			active_objective_nodes.erase(node)
		objective_completed.emit(node)
	
	objective_updated.emit(completed_objectives, total_objectives)
	
	if completed_objectives >= total_objectives and total_objectives > 0:
		all_objectives_completed.emit()
		print("All Objectives Completed! Boss Activation sequence initiated.")

func notify_boss_health(current, m):
	boss_health_updated.emit(current, m)

func notify_boss_activated(boss):
	boss_activated.emit(boss)

func _ready():
	reset_objectives()
	load_config()
	setup_default_inputs()
	print_game_info()

func setup_default_inputs():
	# Keyboard/Mouse Defaults
	var kbm_inputs = {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_forward": [KEY_W, KEY_UP],
		"move_back": [KEY_S, KEY_DOWN],
		"dash": [KEY_SPACE],
		"fire_primary": [MOUSE_BUTTON_LEFT],
		"fire_secondary": [MOUSE_BUTTON_RIGHT],
		"interact": [KEY_E],
		"ultimate": [KEY_F]
	}

	# Controller Defaults
	var joy_inputs = {
		"dash": [JOY_BUTTON_A, JOY_BUTTON_LEFT_SHOULDER], # A or LB
		"fire_primary": [JOY_BUTTON_RIGHT_SHOULDER], # RB
		"fire_secondary": [JOY_BUTTON_LEFT_SHOULDER], 
		"interact": [JOY_BUTTON_X], # X / Square
		"ultimate": [JOY_BUTTON_Y] # Y / Triangle
	}
	
	# Axis Mappings (Action, Axis, Value)
	var joy_axes = [
		["move_left", JOY_AXIS_LEFT_X, -1.0],
		["move_right", JOY_AXIS_LEFT_X, 1.0],
		["move_forward", JOY_AXIS_LEFT_Y, -1.0],
		["move_back", JOY_AXIS_LEFT_Y, 1.0],
		["aim_left", JOY_AXIS_RIGHT_X, -1.0],
		["aim_right", JOY_AXIS_RIGHT_X, 1.0],
		["aim_forward", JOY_AXIS_RIGHT_Y, -1.0],
		["aim_back", JOY_AXIS_RIGHT_Y, 1.0],
		["fire_primary", JOY_AXIS_TRIGGER_RIGHT, 1.0] # RT as Fire
	]
	
	# Register Actions
	var all_actions = kbm_inputs.keys() + ["aim_left", "aim_right", "aim_forward", "aim_back"]
	
	for action in all_actions:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			# Add Deadzone for stick actions
			if action.begins_with("move_") or action.begins_with("aim_"):
				InputMap.action_set_deadzone(action, 0.2)
	
	# add KBM
	for action in kbm_inputs:
		for key in kbm_inputs[action]:
			var event
			if typeof(key) == TYPE_INT:
				if key < 10:
					event = InputEventMouseButton.new()
					event.button_index = key
				else:
					event = InputEventKey.new()
					event.keycode = key
			if event: InputMap.action_add_event(action, event)
			
	# Add Joy Buttons
	for action in joy_inputs:
		if InputMap.has_action(action):
			for btn in joy_inputs[action]:
				var event = InputEventJoypadButton.new()
				event.button_index = btn
				InputMap.action_add_event(action, event)
				
	# Add Joy Axes
	for entry in joy_axes:
		var action = entry[0]
		var axis = entry[1]
		var val = entry[2]
		
		if InputMap.has_action(action):
			var event = InputEventJoypadMotion.new()
			event.axis = axis
			event.axis_value = val
			InputMap.action_add_event(action, event)
	
	print("InputMap initialized.")

func load_config():
	var file = FileAccess.open("res://game_skeleton.json", FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		var json = JSON.new()
		var error = json.parse(json_text)
		if error == OK:
			game_data = json.data
			print("Config loaded successfully.")
		else:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_text, " at line ", json.get_error_line())
	else:
		print("Could not open game_skeleton.json")

func print_game_info():
	if "game" in game_data and "info" in game_data["game"]:
		var info = game_data["game"]["info"]
		print("Game Name: ", info.get("name", "Unknown"))
		print("Version: ", info.get("version", "Unknown"))
		print("Description: ", info.get("description", "No description"))
