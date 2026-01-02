extends CharacterBody3D

var mob_id: String
var stats: Dictionary = {}

var health: float = 10.0

enum State { IDLE, CHASE, ATTACK }
var current_state = State.IDLE
var player: Node3D = null

var move_speed: float = 5.0
var detection_range: float = 20.0
var attack_range: float = 8.0
var attack_cooldown: float = 0.0

var target_override: Node3D = null

@export var start_mob_id: String = "mob_drone_scout"

func _ready():
	add_to_group("enemies")
	if start_mob_id != "":
		configure(start_mob_id)
	
	# Find player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		
	# Collision Settings
	collision_layer = 4 # Layer 3: Enemy (Value 4)
	collision_mask = 7  # Mask 1(World) + 2(Player) + 4(Enemy) = 7. Collide with everything.
	motion_mode = MOTION_MODE_FLOATING

func configure(id: String):
	mob_id = id
	var mobs_db = GameManager.game_data.get("enemies", {}).get("mobs", {})
	if id in mobs_db:
		var data = mobs_db[id]
		stats = data.get("stats", {})
		health = float(stats.get("health", 10.0))
		
		var speed_str = data.get("speed", "5")
		move_speed = float(speed_str)
		
		print("Enemy Configured: ", id, " HP: ", health, " Speed: ", move_speed)
		
		setup_visuals(data)
	else:
		print("Mob ID not found: ", id)

func _physics_process(delta):
	var target = player
	if is_instance_valid(target_override):
		target = target_override
	elif not is_instance_valid(player):
		# Try looking again if player spawned late
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0: player = players[0]
		return
	
	if not is_instance_valid(target): return

	var dist = global_position.distance_to(target.global_position)
	
	match current_state:
		State.IDLE:
			if dist < detection_range:
				current_state = State.CHASE
		
		State.CHASE:
			if dist > detection_range * 1.5:
				current_state = State.IDLE
				velocity = Vector3.ZERO
			elif dist < attack_range:
				current_state = State.ATTACK
			else:
				# Move towards target
				var direction = (target.global_position - global_position).normalized()
				# Ignore Y difference
				direction.y = 0 
				velocity = direction * move_speed
				
				# Face target
				var target_look = Vector3(target.global_position.x, global_position.y, target.global_position.z)
				if global_position.distance_squared_to(target_look) > 0.1:
					look_at(target_look, Vector3.UP)
				
		State.ATTACK:
			if dist > attack_range * 1.2:
				current_state = State.CHASE
			else:
				# Stop and Face target
				velocity = Vector3.ZERO
				var target_look = Vector3(target.global_position.x, global_position.y, target.global_position.z)
				if global_position.distance_squared_to(target_look) > 0.1:
					look_at(target_look, Vector3.UP)
				
				# Fire weapon
				attack_cooldown -= delta
				if attack_cooldown <= 0:
					attack_cooldown = 1.0 # 1 second fire rate
					fire_weapon(target)
				
	move_and_slide()

func setup_visuals(_data):
	# Placeholder Red Cube
	var mesh_inst = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1, 1, 1)
	mesh_inst.mesh = box
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.RED
	mesh_inst.set_surface_override_material(0, material)
	
	add_child(mesh_inst)
	
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1, 2, 1) # Taller collider to catch projectiles
	col.shape = shape
	add_child(col)

func take_damage(amount: float):
	health -= amount
	print(mob_id, " took ", amount, " damage. HP: ", health)
	if health <= 0:
		die()

var pickup_scene = preload("res://scenes/Pickup.tscn")

func die():
	print(mob_id, " DESTROYED.")
	
	# Drop Loot
	if pickup_scene:
		var pickup = pickup_scene.instantiate()
		get_parent().add_child(pickup)
		pickup.global_position = global_position
		# Randomize amount?
		pickup.amount = randi_range(1, 5)
		
	queue_free()

func reset_target():
	target_override = null

func fire_weapon(target_node = null):
	var proj_scene = preload("res://scenes/Projectile.tscn")
	var proj = proj_scene.instantiate()
	get_parent().add_child(proj)
	
	# Spawn at enemy position but slightly forward
	var spawn_pos = global_position - global_transform.basis.z * 1.5 # Forward is -Z
	spawn_pos.y = 1.5 # Match height
	proj.global_position = spawn_pos
	
	var actual_target = player
	if target_node: actual_target = target_node
	
	if not is_instance_valid(actual_target): return
	
	# Configure: damage 5, range 20, speed 15
	proj.configure(5.0, 20.0, 15.0, self)
	
	# Target Player directly
	var target_vector = (actual_target.global_position - spawn_pos).normalized()
	proj.velocity = target_vector * 15.0
