extends CharacterBody3D

# MobDroneTank: Slow, high health, heavy shooter.

var mob_id: String = "mob_drone_tank"
var stats: Dictionary = {}

var health: float = 120.0
var move_speed: float = 5.0
var detection_range: float = 25.0
var attack_range: float = 14.0 # Longer range
var attack_cooldown: float = 0.0
var fire_rate: float = 0.25 # FAST fire rate
var damage: float = 10.0

enum State { IDLE, CHASE, ATTACK, PROTECT }
var current_state = State.IDLE
var player: Node3D = null
var target_override: Node3D = null
var protect_target: Node3D = null

var max_cover_slots: int = 2
var current_cover_slots: int = 0

var pickup_scene = preload("res://scenes/Pickup.tscn")
var projectile_scene = preload("res://scenes/Projectile.tscn")

func _ready():
	add_to_group("enemies")
	configure()
	
	# Find player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		
	# Collision Settings
	collision_layer = 4 
	collision_mask = 7 
	motion_mode = MOTION_MODE_FLOATING

func configure():
	var mobs_db = GameManager.game_data.get("enemies", {}).get("mobs", {})
	if mob_id in mobs_db:
		var data = mobs_db[mob_id]
		var stat_data = data.get("stats", {})
		health = float(stat_data.get("health", 120.0))
		damage = float(stat_data.get("damage", 10.0))
		move_speed = float(data.get("speed", "5"))
		
		print("Tank Configured: HP:", health, " Spd:", move_speed)
		setup_visuals()

func _physics_process(delta):
	var target = player
	if is_instance_valid(target_override):
		target = target_override
	elif not is_instance_valid(player):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0: player = players[0]
		return
	
	if not is_instance_valid(target): return

	var dist = global_position.distance_to(target.global_position)
	
	# 1. Bunker Mode: If we have cover slots used, stop to provide stable cover.
	# 2. Re-engage: If target gets too far (> 1.5x range), break bunker and move.
	var is_bunkered = (current_cover_slots > 0)
	var needs_reengage = (dist > attack_range * 1.5)
	
	# Chance to switch to PROTECT
	if current_state != State.PROTECT and randf() < 0.02: 
		# If bunkered, only switch if we really need to move
		if not is_bunkered or needs_reengage:
			var ally = find_ally_to_protect()
			if ally:
				protect_target = ally
				current_state = State.PROTECT

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
				# If Bunkered and in range, HOLD POSITION
				if is_bunkered and not needs_reengage:
					velocity = Vector3.ZERO
					face_target(target.global_position)
				else:
					move_towards(target.global_position, move_speed)
					face_target(target.global_position)
				
		State.ATTACK:
			if dist > attack_range * 1.5: 
				current_state = State.CHASE
			else:
				velocity = Vector3.ZERO
				face_target(target.global_position)
				
				attack_cooldown -= delta
				if attack_cooldown <= 0:
					attack_cooldown = fire_rate
					fire_weapon(target)
					
		State.PROTECT:
			if not is_instance_valid(protect_target) or not is_instance_valid(target):
				current_state = State.CHASE
				protect_target = null
			else:
				# If Bunkered and in range, HOLD POSITION
				if is_bunkered and not needs_reengage:
					velocity = Vector3.ZERO
					face_target(target.global_position)
				else:
					# Interpose: Midpoint between Ally and Threat
					var ally_pos = protect_target.global_position
					var threat_pos = target.global_position
					var protect_pos = ally_pos.lerp(threat_pos, 0.4)
					
					if global_position.distance_to(protect_pos) > 1.0:
						move_towards(protect_pos, move_speed)
					else:
						velocity = Vector3.ZERO
					
					face_target(threat_pos)
				
				if dist < attack_range:
					attack_cooldown -= delta
					if attack_cooldown <= 0:
						attack_cooldown = fire_rate
						fire_weapon(target)

	move_and_slide()

func move_towards(target_pos, speed):
	var direction = (target_pos - global_position).normalized()
	direction.y = 0 
	velocity = direction * speed

func face_target(target_pos):
	var target_look = Vector3(target_pos.x, global_position.y, target_pos.z)
	if global_position.distance_squared_to(target_look) > 0.1:
		look_at(target_look, Vector3.UP)

func find_ally_to_protect() -> Node3D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest_ally = null
	var min_dist = 15.0
	
	for enemy in enemies:
		if enemy == self or not is_instance_valid(enemy): continue
		if enemy.get("mob_id") == "mob_drone_scout":
			var d = global_position.distance_to(enemy.global_position)
			if d < min_dist:
				min_dist = d
				closest_ally = enemy
	return closest_ally

func can_provide_cover() -> bool:
	return current_cover_slots < max_cover_slots

func register_cover():
	current_cover_slots += 1

func unregister_cover():
	current_cover_slots = max(0, current_cover_slots - 1)

func fire_weapon(target_node):
	var proj = projectile_scene.instantiate()
	get_parent().add_child(proj)
	
	var spawn_pos = global_position - global_transform.basis.z * 1.5
	spawn_pos.y = 1.5
	proj.global_position = spawn_pos
	
	# Tank projectiles: Slower (12) but hit harder
	proj.configure(damage, 25.0, 12.0, self)
	
	var target_vector = (target_node.global_position - spawn_pos).normalized()
	proj.velocity = target_vector * 12.0

func take_damage(amount: float):
	health -= amount
	if health <= 0:
		die()

func die():
	if pickup_scene:
		var pickup = pickup_scene.instantiate()
		get_parent().add_child(pickup)
		pickup.global_position = global_position
		pickup.amount = randi_range(3, 8) # Tank drops more
	queue_free()

func reset_target():
	target_override = null

func setup_visuals():
	# Visuals for Tank (Blue, Large)
	var mesh_inst = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1, 1, 1)
	mesh_inst.mesh = box
	mesh_inst.scale = Vector3(2.5, 1.2, 1.5) # Wider (2.5) for better cover
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.BLUE
	mesh_inst.set_surface_override_material(0, material)
	
	add_child(mesh_inst)
	
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(2.5, 2, 1.5) # Wider collision
	col.shape = shape
	add_child(col)
