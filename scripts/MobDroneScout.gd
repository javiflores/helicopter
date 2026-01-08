extends CharacterBody3D

# MobDroneScout: Fast, low health, agile.

var mob_id: String = "mob_drone_scout"
var stats: Dictionary = {}

var health: float = 30.0
var move_speed: float = 10.0
var detection_range: float = 30.0
var attack_range: float = 18.0
var attack_cooldown: float = 0.0
var fire_rate: float = 1.0 # Standard fire rate
var damage: float = 5.0
var burst_count: int = 3
var current_burst_shots: int = 0
var burst_delay: float = 0.15
var burst_timer: float = 0.0

enum State { IDLE, CHASE, ATTACK, SEEK_COVER }
var current_state = State.IDLE
var player: Node3D = null
var target_override: Node3D = null
var cover_tank: Node3D = null

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
	# Load stats from JSON if needed, or just hardcode for specific script
	var mobs_db = GameManager.game_data.get("enemies", {}).get("mobs", {})
	if mob_id in mobs_db:
		var data = mobs_db[mob_id]
		var stat_data = data.get("stats", {})
		health = float(stat_data.get("health", 30.0))
		damage = float(stat_data.get("damage", 5.0))
		move_speed = float(data.get("speed", "10"))
		is_elite = data.get("elite", false)
		print("Scout Configured: HP:", health, " IsElite:", is_elite)
		setup_visuals()

func _physics_process(delta):
	if is_stunned: return
	
	var target = player
	if is_instance_valid(target_override):
		target = target_override
	elif not is_instance_valid(player):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0: player = players[0]
		return
	
	if not is_instance_valid(target): return

	var dist = global_position.distance_to(target.global_position)
	
	# Logic to switch to SEEK_COVER
	if current_state != State.SEEK_COVER and randf() < 0.05:
		var tank = find_nearby_tank()
		if tank and tank.has_method("can_provide_cover") and tank.can_provide_cover():
			cover_tank = tank
			if tank.has_method("register_cover_occupant"):
				tank.register_cover_occupant(self, 0) # Priority 0
			else:
				tank.register_cover()
			current_state = State.SEEK_COVER
	
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
				move_towards(target.global_position, move_speed)
				face_target(target.global_position)
				
		State.ATTACK:
			if dist > attack_range * 1.2:
				current_state = State.CHASE
			else:
				velocity = Vector3.ZERO
				face_target(target.global_position)
				
				attack_cooldown -= delta
				if attack_cooldown <= 0:
					attack_cooldown = fire_rate
					fire_weapon(target)
		
		State.SEEK_COVER:
			if not is_instance_valid(cover_tank) or not is_instance_valid(target):
				if is_instance_valid(cover_tank):
					if cover_tank.has_method("unregister_cover_occupant"):
						cover_tank.unregister_cover_occupant(self)
					elif cover_tank.has_method("unregister_cover"):
						cover_tank.unregister_cover()
				current_state = State.CHASE
				cover_tank = null
			else:
				# Always reduce cooldown so we engage eventually
				if attack_cooldown > 0:
					attack_cooldown -= delta
					# Reset burst state while cooling down
					current_burst_shots = 0
					burst_timer = 0.0

				var tank_pos = cover_tank.global_position
				var threat_pos = target.global_position
				var dir_threat_to_tank = (tank_pos - threat_pos).normalized()
				
				var desired_pos = Vector3.ZERO
				var is_peeking = (attack_cooldown <= 0) # Ready to fire sequence
				
				if is_peeking:
					# PEEK: Move to the side of the tank
					var right = dir_threat_to_tank.cross(Vector3.UP).normalized()
					var peek_offset = right * 2.0 
					desired_pos = tank_pos + peek_offset + (dir_threat_to_tank * 0.5)
				else:
					# COVER: Move behind the tank
					desired_pos = tank_pos + (dir_threat_to_tank * 2.5) 
				
				if global_position.distance_to(desired_pos) > 0.5:
					move_towards(desired_pos, move_speed)
				else:
					velocity = Vector3.ZERO
					face_target(threat_pos)
					
					# BURST FIRE LOGIC
					if is_peeking and dist < attack_range:
						burst_timer -= delta
						if burst_timer <= 0:
							fire_weapon(target)
							current_burst_shots += 1
							burst_timer = burst_delay
							
							if current_burst_shots >= burst_count:
								# Burst complete, trigger cooldown to hide
								attack_cooldown = fire_rate
				
				# If Tank dies or moves too far logic handles implicitly by re-check loop or physics

	# Apply Knockback
	if knockback_velocity.length_squared() > 0.1:
		velocity += knockback_velocity
		# Increase friction for knockback to stop sliding feeling "delayed" or "floaty"
		knockback_velocity = knockback_velocity.lerp(Vector3.ZERO, delta * 10.0)
	
	move_and_slide()

func move_towards(target_pos, speed):
	var direction = (target_pos - global_position).normalized()
	direction.y = 0 
	velocity = direction * speed

func face_target(target_pos):
	var target_look = Vector3(target_pos.x, global_position.y, target_pos.z)
	if global_position.distance_squared_to(target_look) > 0.1:
		look_at(target_look, Vector3.UP)

func find_nearby_tank() -> Node3D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest_tank = null
	var min_dist = 15.0
	
	for enemy in enemies:
		if enemy == self or not is_instance_valid(enemy): continue
		if enemy.get("mob_id") == "mob_drone_tank":
			var d = global_position.distance_to(enemy.global_position)
			if d < min_dist:
				min_dist = d
				closest_tank = enemy
	return closest_tank

func fire_weapon(target_node):
	var proj = projectile_scene.instantiate()
	get_parent().add_child(proj)
	
	var spawn_pos = global_position - global_transform.basis.z * 1.0 # Forward is -Z
	spawn_pos.y = 1.0
	proj.global_position = spawn_pos
	
	proj.configure(damage, 20.0, 15.0, self)
	
	var target_vector = (target_node.global_position - spawn_pos).normalized()
	proj.velocity = target_vector * 15.0
	proj.look_at(spawn_pos + target_vector, Vector3.UP)

func take_damage(amount: float, _source_pos: Vector3 = Vector3.ZERO):
	health -= amount
	if health <= 0:
		die()

func die():
	if is_instance_valid(cover_tank) and cover_tank.has_method("unregister_cover"):
		cover_tank.unregister_cover()

	if pickup_scene:
		var pickup = pickup_scene.instantiate()
		get_parent().add_child(pickup)
		pickup.global_position = global_position
		pickup.amount = randi_range(1, 3) # Scouts drop less
	queue_free()

func reset_target():
	target_override = null

func setup_visuals():
	# Visuals for Scout (Red, Small)
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
	shape.size = Vector3(1, 2, 1)
	col.shape = shape
	add_child(col)

func yield_cover():
	# Forced out of cover by a higher priority ally
	if current_state == State.SEEK_COVER:
		cover_tank = null
		# Briefly confuse or just return to chase
		current_state = State.CHASE
		# Optional: Add small stun or delay?
		velocity = Vector3.ZERO
		print("Scout yielded cover to superior officer.")

# Stun Logic
var is_stunned: bool = false
var stun_timer: float = 0.0
var is_elite: bool = false # Loaded from JSON effectively by 'elite' property

var knockback_velocity: Vector3 = Vector3.ZERO

func apply_knockback(force: Vector3):
	if is_elite:
		# Elites take reduced knockback
		knockback_velocity += force * 0.2
	else:
		knockback_velocity += force
		# STAGGER: Also briefly stun on big hits?
		if force.length() > 10.0:
			apply_stun(0.5)

func apply_stun(duration: float):
	# Elites/Bosses ignore stun
	# We check if "elite" is true in configuration or property
	if is_elite:
		print(mob_id, " resisted stun (Elite).")
		return
		
	print(mob_id, " stunned for ", duration)
	is_stunned = true
	stun_timer = duration
	velocity = Vector3.ZERO
	# Interrupt attacks
	attack_cooldown = max(attack_cooldown, 0.5)

func _process(delta):
	if is_stunned:
		stun_timer -= delta
		if stun_timer <= 0:
			is_stunned = false
			print(mob_id, " recovered from stun.")
		return # Skip other logic

