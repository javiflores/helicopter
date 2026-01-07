extends Control

@onready var health_bar = $HealthBar
@onready var scrap_label = $ScrapLabel
@onready var dash_bar = $DashBar
@onready var objective_label = $ObjectiveLabel
@onready var run_timer_label = $RunTimerLabel

var player = null

@onready var boss_hud = $BossHUD
@onready var boss_bar = $BossHUD/ProgressBar
@onready var boss_name_label = $BossHUD/BossName

var primary_label: Label = null
var secondary_label: Label = null
var skill_label: Label = null

func _ready():
	_setup_loadout_ui()
	
	# Try finding player immediately (might fail if order is wrong)
	find_player()
	
	# Connect to GameManager for objective updates
	if not GameManager.objective_updated.is_connected(_on_objective_updated):
		GameManager.objective_updated.connect(_on_objective_updated)
	if not GameManager.boss_activated.is_connected(_on_boss_activated):
		GameManager.boss_activated.connect(_on_boss_activated)
	if not GameManager.boss_health_updated.is_connected(_on_boss_health_updated):
		GameManager.boss_health_updated.connect(_on_boss_health_updated)
	
	# Connect for new node-based tracking
	if not GameManager.objective_registered.is_connected(_on_objective_registered):
		GameManager.objective_registered.connect(_on_objective_registered)
	if not GameManager.objective_completed.is_connected(_on_objective_completed):
		GameManager.objective_completed.connect(_on_objective_completed)
	if not GameManager.all_objectives_completed.is_connected(_on_all_objectives_completed):
		GameManager.all_objectives_completed.connect(_on_all_objectives_completed)
	
	# Initial update for any already registered
	_on_objective_updated(GameManager.completed_objectives, GameManager.total_objectives)
	
	# Spawn indicators for existing valid nodes
	for obj_node in GameManager.active_objective_nodes:
		_spawn_indicator(obj_node)
		
	boss_hud.visible = false

func _setup_loadout_ui():
	# Create container bottom right
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_KEEP_SIZE, 50)
	margin.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	margin.grow_vertical = Control.GROW_DIRECTION_BEGIN
	
	margin.add_theme_constant_override("margin_right", 50)
	margin.add_theme_constant_override("margin_bottom", 50)
	
	var vbox = VBoxContainer.new()
	margin.add_child(vbox)
	
	# Primary
	primary_label = Label.new()
	primary_label.text = "Primary: -"
	vbox.add_child(primary_label)
	
	# Secondary
	secondary_label = Label.new()
	secondary_label.text = "Secondary: -"
	vbox.add_child(secondary_label)
	
	# Skill
	skill_label = Label.new()
	skill_label.text = "Skill: -"
	vbox.add_child(skill_label)
	
	add_child(margin)

var indicator_scene = preload("res://scenes/UI/ObjectiveIndicator.tscn")
var indicators = {} # Map node -> indicator instance

func _on_objective_registered(node: Node3D):
	_spawn_indicator(node)

func _on_objective_completed(node: Node3D):
	if node in indicators:
		if is_instance_valid(indicators[node]):
			indicators[node].queue_free()
		indicators.erase(node)

func _spawn_indicator(target: Node3D):
	if target in indicators and is_instance_valid(indicators[target]):
		return
		
	var ind = indicator_scene.instantiate()
	add_child(ind)
	ind.configure(target)
	indicators[target] = ind

func _on_all_objectives_completed():
	# Maybe point to boss room entrance? 
	# For now, boss activation handles its own UI usually.
	pass

func _on_boss_activated(boss):
	boss_hud.visible = true
	boss_name_label.text = boss.boss_name.to_upper()
	boss_bar.max_value = boss.max_health
	boss_bar.value = boss.health
	
	# Also add indicator for boss
	_spawn_indicator(boss)


func _on_boss_health_updated(current, m):
	boss_hud.visible = true
	boss_bar.max_value = m
	boss_bar.value = current
	if current <= 0:
		boss_hud.visible = false

func _on_objective_updated(completed, total):
	objective_label.text = "Objectives: %d / %d" % [completed, total]

func _process(_delta):
	if not player:
		# Retry finding player if we missed them in _ready
		find_player()
		return

	if player:
		health_bar.value = player.health
		scrap_label.text = "SCRAP: " + str(player.scraps)
		
		# Run Timer
		var time = GameManager.run_time
		var minutes = floor(time / 60)
		var seconds = floor(fmod(time, 60))
		run_timer_label.text = "%02d:%02d" % [minutes, seconds]
		
		# Dodge Cooldown Logic
		if player.can_dodge:
			dash_bar.value = dash_bar.max_value
		else:
			dash_bar.value = player.dodge_cooldown - player.dodge_cooldown_timer
			
		# Update Loadout UI
		_update_loadout_labels()

func _update_loadout_labels():
	if not player: return
	
	# Primary Name
	var p_name = "None"
	if player.primary_weapon:
		# Assuming weapon has 'weapon_name' or we look up ID. 
		# WeaponFactory doesn't set name on node usually, but we can verify.
		# Or looking at GameManager.current_loadout
		var id = GameManager.current_loadout.get("primary_weapon_id", "")
		var data = GameManager.game_data.get("player", {}).get("weapons", {}).get(id, {})
		p_name = data.get("name", "Unknown")
	primary_label.text = "Primary: " + p_name.to_upper()
	
	# Secondary Name
	var s_name = "None"
	if player.secondary_weapon:
		var id = GameManager.current_loadout.get("secondary_weapon_id", "")
		var data = GameManager.game_data.get("player", {}).get("weapons", {}).get(id, {})
		s_name = data.get("name", "Unknown")
	secondary_label.text = "Secondary: " + s_name.to_upper()
	
	# Skill Status
	var skill_txt = "READY"
	if player.skill_timer > 0:
		skill_txt = "%.1f" % player.skill_timer
	skill_label.text = "Skill: " + skill_txt

func find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		health_bar.max_value = player.max_health
		health_bar.value = player.health
		dash_bar.max_value = player.dodge_cooldown
