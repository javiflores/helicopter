extends "res://scripts/Projectile.gd"

var blast_radius = 5.0

func configure(dmg, rng, proj_speed = 15.0, owner_node = null):
	super.configure(dmg, rng, proj_speed, owner_node)
	speed = 15.0 # Slower than bullets
	lifetime = 3.0 # Live longer

func _on_body_entered(body):
	if body == shooter:
		return
	
	print("Rocket Hit: ", body.name)
	explode()

func explode():
	print("Rocket Exploding! Radius: ", blast_radius)
	
	# Visual Debug (Optional)
	
	# AOE Damage Check
	# Ideally use PhysicsDirectSpaceState.intersect_shape, but iteration is fine for prototype
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if global_position.distance_to(enemy.global_position) <= blast_radius:
			print("Rocket hit enemy in blast: ", enemy.name)
			if enemy.has_method("take_damage"):
				# Falloff? No, full damage for now
				enemy.take_damage(damage)
				
	queue_free()
