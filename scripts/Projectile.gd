extends Area3D

var speed = 30.0
var damage = 10.0
var lifetime = 2.0
var velocity = Vector3.ZERO

var shooter = null

func configure(dmg, _rng, proj_speed = 50.0, _owner_node = null):
	damage = dmg
	speed = proj_speed
	shooter = _owner_node

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
	if body.has_method("take_damage"):
		body.take_damage(damage, global_position)
	
	# Don't destroy on pickups or triggers, only physical bodies
	if body is PhysicsBody3D:
		queue_free()
