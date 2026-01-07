extends StaticBody3D

@export var fire_rate: float = 1.5
@export var damage: float = 10.0
@export var detection_range: float = 25.0
@export var projectile_speed: float = 25.0
@export var max_health: float = 100.0

var health: float = 100.0
var target = null
var fire_timer: float = 0.0

var projectile_scene = preload("res://scenes/Projectile.tscn")

func _ready():
	add_to_group("enemies")
	health = max_health
	# Basic Mesh Setup if not in tscn
	if get_child_count() == 0:
		_setup_placeholder_visuals()

func _physics_process(delta):
	if not target:
		find_target()
		return
		
	# Check distance
	var dist = global_position.distance_to(target.global_position)
	if dist > detection_range:
		target = null
		return
		
	# Rotate head/barrel towards player (smoothly)
	var head = get_node_or_null("Head")
	if head:
		var target_dir = (target.global_position - head.global_position).normalized()
		target_dir.y = 0 # Keep purely horizontal for the head pivot
		
		# Smooth Slerp the head rotation
		var current_quat = head.global_transform.basis.get_rotation_quaternion()
		var target_basis = Basis.looking_at(target_dir, Vector3.UP)
		var target_quat = target_basis.get_rotation_quaternion()
		
		var smoothing = 5.0 # Slow enough to be dodgeable
		var new_quat = current_quat.slerp(target_quat, delta * smoothing)
		head.global_basis = Basis(new_quat)
	
	# Fire logic
	fire_timer -= delta
	if fire_timer <= 0:
		fire()
		fire_timer = fire_rate

func find_target():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]

func fire():
	if not projectile_scene or not target: return
	
	var proj = projectile_scene.instantiate()
	get_tree().root.add_child(proj)
	
	# Spawn at head position, moved forward along its facing direction
	var head = get_node_or_null("Head")
	var spawn_pos = global_position + Vector3.UP * 1.5
	var fire_dir = (target.global_position - spawn_pos).normalized()
	
	if head:
		# Use head's forward vector (-Z)
		var forward = -head.global_transform.basis.z
		spawn_pos = head.global_position + forward * 2.5 # Offset forward from barrel
		fire_dir = forward
		
	proj.global_position = spawn_pos
	proj.configure(damage, detection_range, projectile_speed, self)
	proj.velocity = fire_dir * projectile_speed
	proj.look_at(spawn_pos + fire_dir, Vector3.UP)

func take_damage(amount: float, _source_pos: Vector3 = Vector3.ZERO):
	health -= amount
	_flash_visuals_recursive(self)
	
	if health <= 0:
		die()

func die():
	print("Turret destroyed!")
	# Optional: spawn explosion
	queue_free()

func _flash_visuals_recursive(node: Node):
	if node is MeshInstance3D:
		var mat = node.get_active_material(0)
		if mat:
			if not mat.resource_name.contains("unique"):
				mat = mat.duplicate()
				mat.resource_name += "_unique"
				node.set_surface_override_material(0, mat)
			
			mat.emission_enabled = true
			mat.emission = Color.RED
			mat.emission_energy_multiplier = 3.0
			
			var flash = create_tween()
			flash.tween_property(mat, "emission_energy_multiplier", 0.0, 0.15)
			flash.finished.connect(func(): if mat: mat.emission_enabled = false)
			
	for child in node.get_children():
		_flash_visuals_recursive(child)


func _setup_placeholder_visuals():
	var body = MeshInstance3D.new()
	body.mesh = BoxMesh.new()
	body.mesh.size = Vector3(1, 1, 1)
	add_child(body)
	
	var head = MeshInstance3D.new()
	head.name = "Head"
	head.mesh = BoxMesh.new()
	head.mesh.size = Vector3(0.5, 0.5, 1.2)
	head.position.y = 1.0
	add_child(head)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.RED
	body.set_surface_override_material(0, mat)
	head.set_surface_override_material(0, mat)
