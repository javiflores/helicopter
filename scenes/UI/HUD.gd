extends Control

@onready var main_layout = $MainLayout
@onready var health_bar = $MainLayout/HealthBar
@onready var scrap_label = $MainLayout/ScrapLabel
@onready var dash_bar = $MainLayout/DashBar
@onready var objective_label = $ObjectiveLabel
@onready var run_timer_label = $MainLayout/RunTimerLabel

var player = null

@onready var boss_hud = $BossHUD
@onready var boss_bar = $BossHUD/ProgressBar
@onready var boss_name_label = $BossHUD/BossName

var primary_label: Label = null
var primary_bar: ProgressBar = null
var secondary_label: Label = null
var secondary_bar: ProgressBar = null
var skill_label: Label = null
var skill_bar: ProgressBar = null

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
	# We want to inject the loadout UI into the MainLayout VBox
	# Order: Health -> Scrap -> Dash -> [Primary -> Secondary -> Skill] -> RunTimer
	
	# Primary
	primary_label = Label.new()
	primary_label.text = "Primary: -"
	main_layout.add_child(primary_label)
	
	primary_bar = ProgressBar.new()
	primary_bar.custom_minimum_size = Vector2(150, 10)
	primary_bar.show_percentage = false
	var styles_p = StyleBoxFlat.new()
	styles_p.bg_color = Color(1.0, 0.8, 0.2) # Yellow/Gold
	primary_bar.add_theme_stylebox_override("fill", styles_p)
	main_layout.add_child(primary_bar)
	
	# Secondary
	secondary_label = Label.new()
	secondary_label.text = "Secondary: -"
	main_layout.add_child(secondary_label)
	
	secondary_bar = ProgressBar.new()
	secondary_bar.custom_minimum_size = Vector2(150, 10)
	secondary_bar.show_percentage = false
	var styles_s = StyleBoxFlat.new()
	styles_s.bg_color = Color(1.0, 0.4, 0.0) # Orange
	secondary_bar.add_theme_stylebox_override("fill", styles_s)
	main_layout.add_child(secondary_bar)
	
	# Skill
	skill_label = Label.new()
	skill_label.text = "Skill: -"
	main_layout.add_child(skill_label)
	
	skill_bar = ProgressBar.new()
	skill_bar.custom_minimum_size = Vector2(150, 10)
	skill_bar.show_percentage = false
	var styles_k = StyleBoxFlat.new()
	styles_k.bg_color = Color(0.2, 0.8, 1.0) # Cyan
	skill_bar.add_theme_stylebox_override("fill", styles_k)
	main_layout.add_child(skill_bar)
	
	# Re-order: Ensure RunTimer is last
	main_layout.move_child(run_timer_label, main_layout.get_child_count() - 1)

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
	var p_cur = 0.0
	var p_max = 1.0

	if player.primary_weapon:
		var id = GameManager.current_loadout.get("primary_weapon_id", "")
		var data = GameManager.game_data.get("player", {}).get("weapons", {}).get(id, {})
		p_name = data.get("name", "Unknown")
		
		p_cur = player.primary_weapon.primary_cooldown
		p_max = player.primary_weapon.primary_cooldown_max
		if p_max == 0: p_max = 0.1 # Avoid div/0
	
	primary_bar.max_value = p_max
	primary_bar.value = p_max - p_cur
	primary_label.text = "Primary: " + p_name.to_upper()
	
	# Secondary Name
	var s_name = "None"
	if player.secondary_weapon:
		var id = GameManager.current_loadout.get("secondary_weapon_id", "")
		var data = GameManager.game_data.get("player", {}).get("weapons", {}).get(id, {})
		s_name = data.get("name", "Unknown")
		
		# Bar Logic
		var s_cur = player.secondary_weapon.secondary_cooldown
		var s_max = player.secondary_weapon.secondary_cooldown_max
		if s_max == 0: s_max = 0.1
		
		secondary_bar.max_value = s_max
		secondary_bar.value = s_max - s_cur
	else:
		secondary_bar.value = 0
		
	secondary_label.text = "Secondary: " + s_name.to_upper()
	
	# Skill Status
	var sk_cur = player.skill_timer
	var sk_max = player.skill_cooldown
	if sk_max == 0: sk_max = 1.0
	
	skill_bar.max_value = sk_max
	skill_bar.value = sk_max - sk_cur
	
	# Fetch Skill Name
	var sk_id = player.current_skill_id
	var sk_data = GameManager.game_data.get("player", {}).get("skills", {}).get(sk_id, {})
	var sk_name = sk_data.get("name", "Skill")
	
	skill_label.text = "Skill: " + sk_name.to_upper()

func find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		health_bar.max_value = player.max_health
		health_bar.value = player.health
		dash_bar.max_value = player.dodge_cooldown
