extends Area3D

var speed = 30.0
var damage = 10.0
var lifetime = 2.0
var velocity = Vector3.ZERO

var shooter = null
var pierce_count = 0

var attacker_team: String = "neutral"

func configure(dmg, _rng, proj_speed = 50.0, _owner_node = null, _pierce = 0, team = "neutral"):
	damage = dmg
	speed = proj_speed
	shooter = _owner_node
	pierce_count = _pierce
	attacker_team = team

func _ready():
	# Mask Layers: 1(World) + 2(Player) + 3(Enemy) = 1+2+4 = 7
	collision_mask = 7 
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	position += velocity * delta
	
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _on_body_entered(body):
	# Ignore self (shooter)
	if body == shooter:
		return
	
	# Parry Check
	if body.has_method("attempt_parry") and body.attempt_parry(global_position):
		print("Projectile Parried/Reflected!")
		shooter = body # Now owned by the parrier
		# Update team if the parrier has one
		if body.has_method("get_team"):
			attacker_team = body.get_team()
		else:
			attacker_team = "friend" # Default to friend if player parries
			
		velocity = -velocity * 1.5 # Reflect back faster
		if velocity.length_squared() > 0.01:
			look_at(global_position + velocity, Vector3.UP)
		lifetime = 2.0 # Reset lifetime
		damage *= 2.0 # Bonus damage
		
		# Optional: Change layer to player layer or ignore mask?
		# Currently mask relies on shooter-based filtering or layer physics.
		# If we change shooter, we might hit enemies now if mask allows.
		return

	print("Projectile hit: ", body.name)
	
	# Spawn Sparks
	var sparks = load("res://scenes/HitSparks.tscn").instantiate()
	get_parent().add_child(sparks)
	sparks.global_position = global_position
	
	if body.has_method("take_damage"):
		body.take_damage(damage, global_position, attacker_team)
	
	# Handle Piercing
	if body is PhysicsBody3D:
		# Walls (StaticBody) always stop projectiles.
		if body is StaticBody3D:
			queue_free()
		else:
			if pierce_count > 0:
				pierce_count -= 1
				print("Pierced! Remaining: ", pierce_count)
			else:
				queue_free()
