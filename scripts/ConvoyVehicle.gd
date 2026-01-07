extends CharacterBody3D

@export var max_health: float = 150.0
var current_health: float = 150.0
var speed: float = 4.0
var target_pos: Vector3 = Vector3.ZERO
var moving: bool = false

@onready var health_bar = $HealthBar
@onready var health_fill = $HealthBar/BarFill

signal vehicle_destroyed

func _ready():
	current_health = max_health
	add_to_group("convoy")
	update_ui()

func _physics_process(delta):
	if not moving or current_health <= 0:
		return
		
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0.0

	if global_position.distance_to(target_pos) > 1.0:
		var move_speed = speed
		var horizontal_dir = (target_pos - global_position)
		horizontal_dir.y = 0
		horizontal_dir = horizontal_dir.normalized()
		
		velocity.x = horizontal_dir.x * move_speed
		velocity.z = horizontal_dir.z * move_speed
		
		move_and_slide()
		
		# Look at target
		if Vector2(velocity.x, velocity.z).length() > 0.1:
			var target_look = global_position + horizontal_dir
			look_at(target_look, Vector3.UP)
	else:
		moving = false
		velocity.x = 0
		velocity.z = 0
		move_and_slide()

func take_damage(amount: float, _source_pos: Vector3 = Vector3.ZERO):
	current_health -= amount
	update_ui()
	if current_health <= 0:
		die()

func update_ui():
	if health_fill:
		var ratio = clamp(current_health / max_health, 0.0, 1.0)
		health_fill.scale.x = ratio
		
		# Change color based on health
		if ratio < 0.3:
			health_fill.get_active_material(0).albedo_color = Color.RED
		elif ratio < 0.6:
			health_fill.get_active_material(0).albedo_color = Color.ORANGE
		else:
			health_fill.get_active_material(0).albedo_color = Color.GREEN

func die():
	print("Convoy vehicle destroyed!")
	vehicle_destroyed.emit()
	# Optional explosion VFX
	queue_free()
