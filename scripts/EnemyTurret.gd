extends StaticBody3D

@export var fire_rate: float = 1.5
@export var damage: float = 10.0
@export var detection_range: float = 25.0
@export var projectile_speed: float = 25.0

var target = null
var fire_timer: float = 0.0

var projectile_scene = preload("res://scenes/Projectile.tscn")

func _ready():
	add_to_group("enemy")
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

func take_damage(amount):
	# Turrets can be destroyed?
	# In POIDestroy, maybe the turrets are separate destructible entities
	# For now, let's give them health
	pass

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
