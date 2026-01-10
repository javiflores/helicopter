extends "res://scripts/Projectile.gd"

var blast_radius = 5.0
var blast_scene = preload("res://scenes/BlastEffect.tscn")

var target: Node3D = null
var turn_speed: float = 5.0 # Radians per second

func configure(dmg, rng, proj_speed = 15.0, owner_node = null, _pierce = 0, team = "neutral"):
	super.configure(dmg, rng, proj_speed, owner_node, _pierce, team)
	speed = 15.0
	lifetime = 5.0 # Longer life for homing

func set_target(new_target):
	target = new_target

func _physics_process(delta):
	# Retargeting Logic
	if target and not is_instance_valid(target):
		target = _find_new_target()

	if is_instance_valid(target):
		var direction = (target.global_position - global_position).normalized()
		var current_dir = velocity.normalized()
		var new_dir = current_dir.slerp(direction, turn_speed * delta).normalized()
		velocity = new_dir * speed
		
		if velocity.length_squared() > 0.01:
			look_at(global_position + velocity, Vector3.UP)
			
	# Apply movement
	position += velocity * delta
	
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _find_new_target() -> Node3D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest = null
	var min_dist = 99999.0
	var scan_range = 30.0
	
	for enemy in enemies:
		if not is_instance_valid(enemy): continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= scan_range and dist < min_dist:
			min_dist = dist
			nearest = enemy
			
	if nearest:
		print("Rocket retargeted: ", nearest.name)
		
	return nearest

func _on_body_entered(body):
	if body == shooter:
		return
	
	# Parry Check
	if body.has_method("attempt_parry") and body.attempt_parry(global_position):
		print("Rocket Parried/Reflected!")
		shooter = body
		velocity = - velocity * 1.5
		if velocity.length_squared() > 0.01:
			look_at(global_position + velocity, Vector3.UP)
		lifetime = 5.0
		damage *= 2.0
		
		# Reset target so it doesn't try to loop back to the player immediately
		target = null
		# Ideally find a NEW target (enemy)
		target = _find_new_target()
		
		return

	print("Rocket Hit: ", body.name)
	explode()

func explode():
	print("Rocket Exploding! Radius: ", blast_radius)
	
	if blast_scene:
		var blast = blast_scene.instantiate()
		get_parent().add_child(blast)
		blast.global_position = global_position
	
	# Visual Debug (Optional)
	
	# AOE Damage using Physics Query
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var shape = SphereShape3D.new()
	shape.radius = blast_radius
	query.shape = shape
	query.transform = Transform3D(Basis(), global_position)
	query.collision_mask = 4 | 8 # Layers: Enemy(4) + Destructible/Building(8 if defined, or assume part of world 1? Let's check mask)
	# Safest is to check layers commonly used for damageable info. 
	# Let's use the projectile's mask (7 = World(1)+Player(2)+Enemy(4)) - Player(2) = 5
	# Actually, usually we want to mask explicit damage layers.
	# Or just intersect_shape on commonly used layers.
	query.collision_mask = 4 # Enemies
	# If buildings are static bodies on Layer 1 (World), we should include 1.
	query.collision_mask = 5 # Enemies (4) + World (1)
	
	var results = space_state.intersect_shape(query, 32) # Max 32 hits
	
	for result in results:
		var body = result["collider"]
		if body == shooter: continue
		
		# Avoid hitting same body multiple times (unlikely with shape query but good practice if multiple shapes)
		# Shape query returns Dictionary.
		
		print("Rocket Blast Hit: ", body.name)
		if body.has_method("take_damage"):
			body.take_damage(damage, global_position, attacker_team)
			
	queue_free()
