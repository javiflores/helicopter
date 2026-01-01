extends Node3D

@export var max_health: float = 200.0
@export var reward_amount: int = 150

var current_health: float = 0.0
var is_destroyed: bool = false
var ambush_triggered: bool = false

var enemy_scene = preload("res://scenes/Enemy.tscn")

signal destroy_completed

func _ready():
	current_health = max_health
	$Label3D.text = "DESTROY RADAR"
	$HealthBar.visible = false
	
	# Register with GameManager
	if GameManager.has_method("register_objective"):
		GameManager.register_objective()
	
	# Rotate radar mesh slightly for effect if it's there
	var dish = get_node_or_null("RadarDish")
	if dish:
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(dish, "rotation:y", PI * 2, 4.0).as_relative()

func take_damage(amount: float):
	if is_destroyed: return
	
	current_health -= amount
	update_health_bar()
	
	if not ambush_triggered:
		trigger_ambush()
		
	if current_health <= 0:
		complete_destruction()

func update_health_bar():
	$HealthBar.visible = true
	var progress = clamp(current_health / max_health, 0.0, 1.0)
	$HealthBar/BarFill.scale.x = progress
	
	# Flash the radar building?
	var mat = $RadarBuilding.get_active_material(0)
	if mat:
		mat.emission_enabled = true
		mat.emission = Color.RED
		await get_tree().create_timer(0.1).timeout
		mat.emission_enabled = false

func trigger_ambush():
	ambush_triggered = true
	print("Radar Ambush Triggered!")
	spawn_wave(3) # Initial defenders

func spawn_wave(count: int):
	var radius = 12.0
	for i in range(count):
		var angle = randf() * PI * 2.0
		var offset = Vector3(cos(angle) * radius, 0, sin(angle) * radius)
		var enemy = enemy_scene.instantiate()
		get_parent().add_child(enemy)
		enemy.global_position = global_position + offset

func complete_destruction():
	is_destroyed = true
	$Label3D.text = "DESTROYED!"
	$HealthBar.visible = false
	
	# Visual feedback: Turn grey/black
	var mat = $RadarBuilding.get_active_material(0)
	if mat:
		mat.albedo_color = Color.DARK_SLATE_GRAY
	
	var dish_mat = $RadarDish.get_active_material(0)
	if dish_mat:
		dish_mat.albedo_color = Color.BLACK
		
	# Spawn explosion effect if we had one
	print("Radar Destroyed!")
	
	# Reward
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		players[0].collect_loot(0, reward_amount)
		
	destroy_completed.emit()
	if GameManager.has_method("complete_objective"):
		GameManager.complete_objective()
	
	# Disable turrets?
	for child in get_children():
		if child.is_in_group("enemy") and child.has_method("find_target"):
			child.set_physics_process(false)
			child.target = null

func _on_area_3d_body_entered(body):
	if body.is_in_group("player") and not ambush_triggered:
		trigger_ambush()
