extends Control

@onready var health_bar = $HealthBar
@onready var scrap_label = $ScrapLabel
@onready var dash_bar = $DashBar
@onready var objective_label = $ObjectiveLabel
@onready var debug_label = $DebugLabel

var player = null

@onready var boss_hud = $BossHUD
@onready var boss_bar = $BossHUD/ProgressBar
@onready var boss_name_label = $BossHUD/BossName

func _ready():
	# Try finding player immediately (might fail if order is wrong)
	find_player()
	
	# Connect to GameManager for objective updates
	GameManager.objective_updated.connect(_on_objective_updated)
	GameManager.boss_activated.connect(_on_boss_activated)
	GameManager.boss_health_updated.connect(_on_boss_health_updated)
	
	# Initial update for any already registered
	_on_objective_updated(GameManager.completed_objectives, GameManager.total_objectives)
	boss_hud.visible = false

func _on_boss_activated(boss):
	boss_hud.visible = true
	boss_name_label.text = boss.boss_name.to_upper()
	boss_bar.max_value = boss.max_health
	boss_bar.value = boss.health

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
		
		# Debug Info
		var speed = player.velocity.length()
		debug_label.text = "Speed: %.1f\nAccel: %.1f\nRotSpd: %.1f" % [speed, player.acceleration, player.rotation_speed]
		
		# Dash Cooldown Logic
		if player.can_dash:
			dash_bar.value = dash_bar.max_value
		else:
			dash_bar.value = player.dash_cooldown - player.dash_cooldown_timer

func find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		health_bar.max_value = player.max_health
		health_bar.value = player.health
		dash_bar.max_value = player.dash_cooldown
