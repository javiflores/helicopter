extends "res://scripts/Weapon.gd"

var projectile_scene = preload("res://scenes/Projectile.tscn")
var rocket_scene = preload("res://scenes/RocketProjectile.tscn") # We will create this

func configure(id, data):
	super.configure(id, data)
	if id == "weapon_rocket":
		projectile_scene = rocket_scene

func fire():
	print("Firing Projectile Weapon: ", weapon_id)
	var projectile = projectile_scene.instantiate()
	
	# Configure based on specs
	var damage = float(specs.get("damage", 10.0))
	var range_val = float(specs.get("range", 10.0))
	var speed = 30.0 
	
	# Assuming parent is the shooter (Player or Enemy)
	projectile.configure(damage, range_val, speed, get_parent())
	
	# Determine spawn position and rotation
	# Spawning at parent's position (Weapon holder) roughly
	# In a real setup, we'd use a "Muzzle" node
	var spawn_pos = global_position 
	spawn_pos.y = 1.5 # Force projectile to fly at standard height
	
	# Move spawn point slightly forward so bullets aren't inside the heli
	#Basis Z is backwards, so we use -transform.basis.z
	var forward_offset = -global_transform.basis.z * 1.5 
	spawn_pos += forward_offset
	
	var spawn_rot = global_rotation
	
	# Add to world (GameWorld or just root)
	get_tree().root.add_child(projectile)
	projectile.global_position = spawn_pos
	projectile.global_rotation = spawn_rot # Align projectile with firing direction
	
	# Calculate velocity based on weapon forward vector
	var forward = -global_transform.basis.z
	forward.y = 0 # Force velocity to be flat
	forward = forward.normalized()
	projectile.velocity = forward * speed
