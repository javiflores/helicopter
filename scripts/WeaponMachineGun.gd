extends "res://scripts/Weapon.gd"

var projectile_scene = preload("res://scenes/Projectile.tscn")
var slug_projectile_scene = preload("res://scenes/SlugProjectile.tscn")

func fire_primary():
	# Standard Rapid Fire
	_fire_bullet(primary_attack, 1, 0.0)

func fire_secondary():
	# Heavy Slug
	# Specs: High damage, single shot, piercing
	_fire_bullet(secondary_attack, 1, 0.0)

func _fire_bullet(attack_data: Dictionary, count: int, spread_deg: float):
	print("MG Firing: ", attack_data.get("name"))
	var specs = attack_data.get("specs", {})
	var damage = float(specs.get("damage", 10.0))
	var range_val = float(specs.get("range", 20.0))
	var pierce = int(specs.get("piercing", 0))
	
	# Determine speed based on type? Or just faster for Slug?
	var speed = 50.0 
	var current_scene = projectile_scene
	
	if attack_data.get("name") == "Heavy Slug":
		speed = 80.0
		current_scene = slug_projectile_scene
	
	for i in range(count):
		var proj = current_scene.instantiate()
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
			if spread_deg == 0 and attack_data.get("name") != "Heavy Slug":
				var random_sway = deg_to_rad(randf_range(-2.0, 2.0))
				rot.y += random_sway
				
		proj.global_rotation = rot
		
		# Velocity
		var forward = -proj.global_transform.basis.z.normalized()
		# Flatten Y for top-down logic usually, unless we want to shoot up/down
		forward.y = 0 
		proj.velocity = forward * speed
		
		if proj.has_method("configure"):
			proj.configure(damage, range_val, speed, get_parent(), pierce, "friend")
