extends Node3D

@export var max_health: float = 200.0
@export var reward_amount: int = 150

var current_health: float = 0.0
var is_destroyed: bool = false
var ambush_triggered: bool = false
var rotation_tween: Tween = null

var enemy_scene = preload("res://scenes/MobDroneScout.tscn")
var turret_scene = preload("res://scenes/EnemyTurret.tscn")
var blast_scene = preload("res://scenes/BlastEffect.tscn")

var active_turrets: int = 0
var shield_active: bool = false
var shield_mesh: MeshInstance3D = null

signal destroy_completed

func _ready():
	current_health = max_health
	$Label3D.text = "DESTROY RADAR"
	$HealthBar.visible = false
	
	# Register with GameManager
	if GameManager.has_method("register_objective"):
		GameManager.register_objective(self)
	
	# Find Dish/Head dynamically in the hierarchy
	var visual_model = get_node_or_null("VisualModel")
	if visual_model:
		var root = visual_model
		if visual_model.get_child_count() > 0:
			root = visual_model.get_child(0) # often FBX importer adds a wrapper
			
		# Look for children first to avoid rotating the entire root
		var dish = null
		for child in root.get_children():
			dish = find_node_by_pattern(child, ["dish", "head"])
			if dish: break
			
		if not dish:
			# Fallback but still avoid the topmost visual node
			for child in root.get_children():
				dish = find_node_by_pattern(child, ["rotor", "satelit", "antenna"])
				if dish: break
			
		if dish:
			rotation_tween = create_tween()
			rotation_tween.set_loops()
			rotation_tween.tween_property(dish, "rotation:y", PI * 2, 4.0).as_relative()
			print("Found and Rotating: ", dish.name)

			rotation_tween.tween_property(dish, "rotation:y", PI * 2, 4.0).as_relative()
			print("Found and Rotating: ", dish.name)

	_setup_shield_visual()
	_chk_existing_turrets()

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

func get_team() -> String:
	return "foe"

func take_damage(amount: float, _source_pos: Vector3 = Vector3.ZERO, attacker_team: String = "neutral"):
	if attacker_team == "foe":
		return
	if is_destroyed: return
	
	if shield_active:
		# Shield absorbs damage
		if shield_mesh:
			_flash_shield()
		return

	
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
			if not mat.resource_name.contains("unique"):
				mat = mat.duplicate()
				mat.resource_name += "_unique"
				node.set_surface_override_material(0, mat)
			
			mat.emission_enabled = true
			mat.emission = Color.RED
			mat.emission_energy_multiplier = 1.0
			
			# Use a one-shot tween to flash and then turn off
			var flash = create_tween()
			flash.tween_property(mat, "emission_energy_multiplier", 0.0, 0.2)
			flash.finished.connect(func(): mat.emission_enabled = false)
	for child in node.get_children():
		_flash_meshes_recursive(child)

func trigger_ambush():
	ambush_triggered = true
	print("Radar Ambush Triggered!")
	# spawn_wave(3) # Removed to keep defender count at 4 Turrets only
	spawn_turrets()
	
	spawn_turrets()
	
func spawn_turrets():
	# If we already have turrets (pre-placed), don't spawn more
	if active_turrets > 0:
		print("Using ", active_turrets, " pre-placed turrets.")
		return

	# Spawn 4 Turrets to activate shield
	active_turrets = 4
	activate_shield()
	
	var radius = 15.0
	for i in range(4):
		var angle = (float(i) / 4.0) * PI * 2.0
		var offset = Vector3(cos(angle) * radius, 0, sin(angle) * radius)
		
		# If we have a turret scene, use it. Otherwise use placeholder?
		# Turret scene wasn't preloaded in original code, assumed existence or generic enemy.
		# Let's use the preloaded `turret_scene` if valid, else fallback to `enemy_scene` but that's a drone.
		# Ideally we need a Turret.
		var t = null
		if turret_scene:
			t = turret_scene.instantiate()
		else:
			# Fallback if no turret scene, just use drone as "turret" for logic
			t = enemy_scene.instantiate()
			
		get_parent().add_child(t)
		t.global_position = global_position + offset
		
		# Connect destruction
		# Turrets free themselves on death.
		t.tree_exited.connect(_on_turret_destroyed)

func _on_turret_destroyed():
	if not shield_active: return
	
	active_turrets -= 1
	if active_turrets <= 0:
		deactivate_shield()

func activate_shield():
	shield_active = true
	if shield_mesh:
		shield_mesh.visible = true
		shield_mesh.scale = Vector3(0.1, 0.1, 0.1)
		var tween = create_tween()
		tween.tween_property(shield_mesh, "scale", Vector3(1, 1, 1), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
func deactivate_shield():
	shield_active = false
	if shield_mesh:
		var tween = create_tween()
		tween.tween_property(shield_mesh, "scale", Vector3(0.1, 0.1, 0.1), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.finished.connect(func(): shield_mesh.visible = false)
	print("Radar Shield Down!")

func _setup_shield_visual():
	var mesh = SphereMesh.new()
	mesh.radius = 8.0 # Large enough to cover Radar
	mesh.height = 16.0
	
	shield_mesh = MeshInstance3D.new()
	shield_mesh.mesh = mesh
	shield_mesh.name = "ShieldVisual"
	add_child(shield_mesh)
	
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.1, 0.3, 1.0, 0.3)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.4, 1.0)
	mat.emission_energy_multiplier = 1.0
	mat.cull_mode = BaseMaterial3D.CULL_BACK
	
	shield_mesh.set_surface_override_material(0, mat)
	shield_mesh.visible = false # Hidden initially
	
func _flash_shield():
	if not shield_mesh: return
	var mat = shield_mesh.get_active_material(0)
	if mat:
		var tween = create_tween()
		tween.tween_property(mat, "albedo_color:a", 0.8, 0.05)
		tween.tween_property(mat, "albedo_color:a", 0.3, 0.2)


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
	
	if rotation_tween:
		rotation_tween.kill()
		
	# Spawn explosion effect if we had one
	if blast_scene:
		var blast = blast_scene.instantiate()
		get_parent().add_child(blast)
		blast.global_position = global_position
		# Scale up for big building
		blast.scale = Vector3(3, 3, 3)
	print("Radar Destroyed!")
	
	# Reward
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		players[0].collect_loot(0, reward_amount)
		
	destroy_completed.emit()
	if GameManager.has_method("complete_objective"):
		GameManager.complete_objective(self)
	
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

func _chk_existing_turrets():
	# Check if Turrets were placed in the editor
	for child in get_children():
		# Heuristic check: Name contains "Turret" or is in group "enemies"
		if child.name.contains("Turret") or child.is_in_group("enemies") or child.is_in_group("enemy"):
			active_turrets += 1
			if not child.tree_exited.is_connected(_on_turret_destroyed):
				child.tree_exited.connect(_on_turret_destroyed)
				
	if active_turrets > 0:
		print("Found ", active_turrets, " existing turrets. Shield Active.")
		activate_shield()
