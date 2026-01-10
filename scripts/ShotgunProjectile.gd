extends "res://scripts/Projectile.gd"

# Remove duplicate lifetime var
var current_time: float = 0.0

func configure(dmg, rng, proj_speed = 50.0, owner_node = null, _pierce = 0, team = "neutral"):
	# Call super first to set basics
	super.configure(dmg, rng, proj_speed, owner_node, _pierce, team)
	
	# Auto-calculate lifetime based on range/speed
	if speed > 0:
		lifetime = rng / speed
	else:
		lifetime = 0.5

func _process(delta):
	# Parent uses _physics_process for movement/lifetime. 
	# We use _process for visual fading.
	current_time += delta
	# Lifetime check is already in parent _physics_process, but we can do it here too or rely on parent.
	# Actually, parent decrements 'lifetime' var in _physics_process.
	# We want to use 'current_time' for fade ratio.
	
	current_time += delta
	if current_time >= lifetime:
		queue_free()
		
	# Fade out visual?
	var mesh = $MeshInstance3D
	if mesh and current_time > lifetime * 0.7:
		var alpha = 1.0 - ((current_time - lifetime * 0.7) / (lifetime * 0.3))
		mesh.transparency = 1.0 - alpha # Wait, 0 is opaque. 1 is transparent.
		# If material override exists...
