extends "res://scripts/Weapon.gd"

var rocket_scene = preload("res://scenes/RocketProjectile.tscn")

func fire_primary():
	# Standard High-Ex Missile
	var specs = primary_attack.get("specs", {})
	_spawn_rocket(specs, global_position - global_transform.basis.z * 1.5, global_rotation, null)

func fire_secondary():
	# Swarm Salvo: 5 Rockets from the BACK, homing, Staggered
	var specs = secondary_attack.get("specs", {})
	var count = 5
	var max_range = 25.0
	
	# Gather all valid targets in range
	var all_enemies = get_tree().get_nodes_in_group("enemies")
	var valid_targets = []
	for enemy in all_enemies:
		if is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist <= max_range:
				valid_targets.append(enemy)
	
	# Sort by distance (optional but nice)
	valid_targets.sort_custom(func(a, b): 
		return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position)
	)
	
	print("Rocket Swarm Firing! Targets found: ", valid_targets.size())
	
	for i in range(count):
		# Determine target for this specific rocket (Round Robin)
		var this_target = null
		if valid_targets.size() > 0:
			this_target = valid_targets[i % valid_targets.size()]
		
		# Recalculate spawn pos/rot each step if we want them to spawn relative to moving heli, 
		# but "global_transform" captures current state. Since it's async, we should use current heli state inside the loop
		# so they spawn from the heli's NEW position as it moves.
		
		var width = 2.0
		var step = width / (count - 1)
		var offset_x = -width/2.0 + (i * step)
		
		var back_offset = global_transform.basis.z * 2.0
		var side_offset = global_transform.basis.x * offset_x
		var spawn_pos = global_position + back_offset + side_offset
		spawn_pos.y = 1.5
		
		var rot = global_rotation
		
		if this_target:
			# Controlled Spread
			var spread = 60.0 
			var angle = -spread/2.0 + (i * (spread / (count-1)))
			rot.y += deg_to_rad(angle)
		else:
			# Chaotic
			var angle = randf() * 360.0
			rot.y = deg_to_rad(angle)
			
		_spawn_rocket(specs, spawn_pos, rot, this_target, 0.5)
		
		# Stagger Delay
		await get_tree().create_timer(0.1).timeout

func _spawn_rocket(specs, pos, rot, target_node, scale_mod: float = 1.0):
	var rocket = rocket_scene.instantiate()
	get_tree().root.add_child(rocket)
	
	rocket.global_position = pos
	rocket.global_rotation = rot
	rocket.scale = Vector3(scale_mod, scale_mod, scale_mod)
	
	var damage = float(specs.get("damage", 30))
	var range_val = float(specs.get("range", 30))
	var speed = 20.0
	
	rocket.configure(damage, range_val, speed, get_parent())
	
	if target_node and rocket.has_method("set_target"):
		rocket.set_target(target_node)
		rocket.turn_speed = 4.0 # Good turn rate

	# Set velocity
	var forward = -rocket.global_transform.basis.z.normalized()
	forward.y = 0
	rocket.velocity = forward * speed

func _find_nearest_enemy(enemies: Array) -> Node3D:
	var nearest = null
	var min_dist = 99999.0
	var max_range = 25.0 # Swarm targeting radius
	
	for enemy in enemies:
		if not is_instance_valid(enemy): continue
		# Ignore dead enemies logic if needed? 
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= max_range and dist < min_dist:
			min_dist = dist
			nearest = enemy
	return nearest
