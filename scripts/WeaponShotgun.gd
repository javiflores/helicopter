extends "res://scripts/Weapon.gd"

var pellet_scene = preload("res://scenes/ShotgunProjectile.tscn")

func fire_primary():
	# Use property directly, not function call
	if not can_fire_primary: return
	
	var specs = primary_attack.get("specs", {})
	var damage = float(specs.get("damage", 6.0))
	var count = int(specs.get("count", 6))
	var spread = float(specs.get("spread", 20.0))
	var range_val = float(specs.get("range", 20.0))
	var rate = float(specs.get("rate of fire", 1.5))
	
	# Set cooldown on parent variable
	primary_cooldown = 1.0 / rate
	
	# Audio/Visuals
	# play_sound(visuals.get("audio", {}).get("sfx_shoot"))
	
	for i in range(count):
		var proj = pellet_scene.instantiate()
		get_tree().root.add_child(proj)
		
		# Position: muzzle offset
		var spawn_pos = global_position - global_transform.basis.z * 1.0
		spawn_pos.y = 1.0
		proj.global_position = spawn_pos
		
		# Rotation with Spread
		var rot = global_rotation
		var spread_rad = deg_to_rad(spread)
		var rand_y = randf_range(-spread_rad / 2.0, spread_rad / 2.0)
		# Maybe some vertical spread too?
		# var rand_x = randf_range(-spread_rad / 4.0, spread_rad / 4.0)
		rot.y += rand_y
		proj.global_rotation = rot
		
		# Velocity
		var speed = 50.0 
		var dir = -proj.global_transform.basis.z.normalized() # Forward
		dir.y = 0
		proj.velocity = dir * speed
		
		proj.configure(damage, range_val, speed, get_parent(), 0, "friend")

func fire_secondary():
	if not can_fire_secondary: return
	
	var specs = secondary_attack.get("specs", {})
	var damage = float(specs.get("damage", 5.0))
	var range_val = float(specs.get("range", 8.0))
	var force = float(specs.get("force", 20.0))
	var cooldown = float(specs.get("cooldown", 4.0))
	
	secondary_cooldown = cooldown
	
	print("Shotgun Blast!")
	
	# Visual Effect for blast: Cone particles
	var blast_vfx = load("res://scenes/ConcussiveBlast.tscn").instantiate()
	add_child(blast_vfx)
	blast_vfx.position = Vector3(0, 1.0, 0) # Local offset
	
	# Concussive Blast: Check enemies in cone/radius
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy): continue
		
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= range_val:
			# Check angle (Cone of 90 degrees?)
			var dir_to_enemy = (enemy.global_position - global_position).normalized()
			var forward = -global_transform.basis.z
			if dir_to_enemy.dot(forward) > 0.5: # ~60 degrees half-angle -> 120 total? 0.707 is 45. 0.5 is 60.
				# Hit!
				if enemy.has_method("take_damage"):
					enemy.take_damage(damage, global_position, "friend")
				
				if enemy.has_method("apply_knockback"):
					enemy.apply_knockback(dir_to_enemy * force)
				elif enemy.has_method("apply_impulse"):
					# RigidBody fallback
					enemy.apply_impulse(dir_to_enemy * force)
