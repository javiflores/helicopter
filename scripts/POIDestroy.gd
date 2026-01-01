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
	
	# Find Dish/Head dynamically in the hierarchy
	var visual_model = get_node_or_null("VisualModel")
	if visual_model:
		# Use a more specific search priority
		var dish = find_node_by_pattern(visual_model, ["dish", "head"])
		if not dish:
			dish = find_node_by_pattern(visual_model, ["rotor", "satelit"])
			
		if dish:
			var tween = create_tween()
			tween.set_loops()
			# Some models need rotation on different axes, Y is common for dishes
			tween.tween_property(dish, "rotation:y", PI * 2, 4.0).as_relative()
			print("Found and Rotating: ", dish.name)

func print_tree_recursive(node: Node, indent: String = ""):
	print(indent + node.name + " (" + node.get_class() + ")")
	for child in node.get_children():
		print_tree_recursive(child, indent + "  ")

func find_node_by_pattern(node: Node, patterns: Array) -> Node:
	var node_name = node.name.to_lower()
	for p in patterns:
		if p in node_name:
			return node
	for child in node.get_children():
		var res = find_node_by_pattern(child, patterns)
		if res: return res
	return null

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
	
	# Flash any mesh found in VisualModel
	var visual_model = get_node_or_null("VisualModel")
	if visual_model:
		_flash_meshes_recursive(visual_model)

func _flash_meshes_recursive(node: Node):
	if node is MeshInstance3D:
		var mat = node.get_active_material(0)
		if mat:
			mat.emission_enabled = true
			mat.emission = Color.RED
			# Simple way to flash without awaiting everything (might be messy with multiple)
			# Better: use a timer or tween
	for child in node.get_children():
		_flash_meshes_recursive(child)

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
	var visual_model = get_node_or_null("VisualModel")
	if visual_model:
		_set_meshes_color_recursive(visual_model, Color.DARK_SLATE_GRAY)
		
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

func _set_meshes_color_recursive(node: Node, color: Color):
	if node is MeshInstance3D:
		var mat = node.get_active_material(0)
		if mat:
			# Duplicate to avoid affecting other shared instances
			if not mat.resource_name.contains("unique"):
				mat = mat.duplicate()
				mat.resource_name += "_unique"
				node.set_surface_override_material(0, mat)
			mat.albedo_color = color
	for child in node.get_children():
		_set_meshes_color_recursive(child, color)

func _on_area_3d_body_entered(body):
	if body.is_in_group("player") and not ambush_triggered:
		trigger_ambush()
