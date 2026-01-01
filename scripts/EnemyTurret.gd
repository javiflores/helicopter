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
		
	# Look at player (smoothly)
	var target_pos = target.global_position
	target_pos.y = global_position.y # Keep horizontal
	
	# Rotate head/barrel towards player
	# Assuming there's a node called "Head" or we rotate the whole thing if it's just a turret
	var head = get_node_or_null("Head")
	if head:
		head.look_at(target.global_position, Vector3.UP)
	else:
		look_at(target.global_position, Vector3.UP)
	
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
	if not projectile_scene: return
	
	var proj = projectile_scene.instantiate()
	get_tree().root.add_child(proj)
	
	# Spawn at head position or slightly forward
	var head = get_node_or_null("Head")
	var spawn_pos = global_position + Vector3.UP * 1.5
	if head:
		spawn_pos = head.global_position
		
	proj.global_position = spawn_pos
	proj.configure(damage, detection_range, projectile_speed, self)
	
	# Calculate direction
	var dir = (target.global_position - spawn_pos).normalized()
	proj.velocity = dir * projectile_speed

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
