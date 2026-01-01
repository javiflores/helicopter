extends Control

@onready var buttons_container = $Panel/HBoxContainer

var current_options = []
var player_ref = null

func _ready():
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	hide()

func setup(player):
	player_ref = player
	# Pause game
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Generate 3 options
	generate_options()
	
	# Update UI
	for i in range(buttons_container.get_child_count()):
		var btn = buttons_container.get_child(i)
		if i < current_options.size():
			var opt = current_options[i]
			btn.text = opt.name + "\n" + opt.description
			btn.visible = true
			if not btn.pressed.is_connected(_on_upgrade_selected):
				btn.pressed.connect(_on_upgrade_selected.bind(opt))
		else:
			btn.visible = false
	
	show()

func generate_options():
	current_options = []
	if not player_ref or not player_ref.current_weapon:
		# Fallback to generic upgrades
		current_options = [
			{"id": "dmg", "name": "Reinforced Barrels", "description": "Damage +2", "stats": {"damage": 2}},
			{"id": "rof", "name": "Rapid Recoil", "description": "Fire Rate +1", "stats": {"rate of fire": 1}},
			{"id": "spd", "name": "Optimized Thrusters", "description": "Movement Speed +20%", "stats": {"speed": 5}}
		]
		return

	var weapon = player_ref.current_weapon
	var available_upgrades = weapon.upgrades.values()
	
	if available_upgrades.size() >= 3:
		available_upgrades.shuffle()
		current_options = available_upgrades.slice(0, 3)
	else:
		# Blend with generics if not enough
		current_options = available_upgrades
		var generics = [
			{"name": "Enhanced Rounds", "description": "Damage +3", "stats_modifier": {"damage": "+3"}},
			{"name": "Fast Loader", "description": "Fire Rate +2", "stats_modifier": {"rate of fire": "+2"}},
			{"name": "Armor Plating", "description": "Max HP +20", "stats_modifier": {"max_health": "+20"}}
		]
		generics.shuffle()
		while current_options.size() < 3:
			current_options.append(generics.pop_back())

func _on_upgrade_selected(upgrade):
	print("Selected Upgrade: ", upgrade.name)
	
	# Apply to player/weapon
	if player_ref:
		apply_upgrade_to_player(upgrade)
	
	# Resume game
	hide()
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	# Queue free or just keep hidden? 
	# Let's keep it in HUD or Gamelevel
	# If instantiated, queue_free()
	# queue_free()

func apply_upgrade_to_player(upgrade):
	if upgrade.has("stats_modifier"):
		var mods = upgrade["stats_modifier"]
		# Apply to weapon if it has it
		if player_ref.current_weapon:
			player_ref.current_weapon.apply_modifier(mods)
		
		# Apply to player stats directly?
		if "max_health" in mods:
			var val = mods["max_health"].to_int()
			player_ref.max_health += val
			player_ref.health += val
	
	if upgrade.has("mechanics"):
		if player_ref.current_weapon:
			player_ref.current_weapon.apply_mechanic(upgrade["mechanics"])
	
	# Generic stats fallback
	if upgrade.has("stats"):
		var stats = upgrade["stats"]
		if "damage" in stats and player_ref.current_weapon:
			var d = player_ref.current_weapon.specs.get("damage", "0").to_int()
			player_ref.current_weapon.specs["damage"] = str(d + stats["damage"])
		if "rate of fire" in stats and player_ref.current_weapon:
			var r = player_ref.current_weapon.specs.get("rate of fire", "0").to_float()
			player_ref.current_weapon.specs["rate of fire"] = str(r + stats["rate of fire"])
		if "speed" in stats:
			player_ref.max_speed += stats["speed"]
