extends "res://scripts/Weapon.gd"

var projectile_scene = preload("res://scenes/Projectile.tscn")

func fire_primary():
	# Standard Rapid Fire
	_fire_bullet(primary_attack, 1, 0.0)

func fire_secondary():
	# Shotgun Blast
	var count = int(secondary_attack.get("specs", {}).get("projectile_count", 6))
	_fire_bullet(secondary_attack, count, 30.0) # 30 degrees total spread

func _fire_bullet(attack_data: Dictionary, count: int, spread_deg: float):
	print("MG Firing: ", attack_data.get("name"))
	var specs = attack_data.get("specs", {})
	var damage = float(specs.get("damage", 10.0))
	var speed = 50.0 # Fast bullet speed
	var range_val = float(specs.get("range", 20.0))
	
	for i in range(count):
		var proj = projectile_scene.instantiate()
		get_tree().root.add_child(proj)
		
		# Position
		var spawn_pos = get_parent().global_position
		spawn_pos.y = 1.0
		var forward_offset = -global_transform.basis.z * 1.5
		spawn_pos += forward_offset
		proj.global_position = spawn_pos
		
		# Rotation / Spread
		var rot = global_rotation
		if count > 1:
			var step = spread_deg / (count - 1)
			var angle = -spread_deg/2.0 + (i * step)
			rot.y += deg_to_rad(angle)
		else:
			# Slight random spread for rapid fire accuracy?
			if spread_deg == 0:
				var random_sway = deg_to_rad(randf_range(-2.0, 2.0))
				rot.y += random_sway
				
		proj.global_rotation = rot
		
		# Velocity
		var forward = -proj.global_transform.basis.z.normalized()
		# Flatten Y for top-down logic usually, unless we want to shoot up/down
		forward.y = 0 
		proj.velocity = forward * speed
		
		proj.configure(damage, range_val, speed, get_parent())
