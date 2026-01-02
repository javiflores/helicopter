extends StaticBody3D

@export var max_health: float = 50.0
var health: float = 50.0

signal block_destroyed

func _ready():
	health = max_health
	# Setup visuals (Basalt Column)
	var mesh = MeshInstance3D.new()
	var rock = CylinderMesh.new()
	rock.top_radius = 2.0
	rock.bottom_radius = 2.5
	rock.height = 6.0
	rock.radial_segments = 5 # Pentagonal prism
	mesh.mesh = rock
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.35, 0.3, 1.0) # Earthy Rock Color
	mat.roughness = 1.0
	mesh.set_surface_override_material(0, mat)
	add_child(mesh)
	
	var col = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 2.5
	shape.height = 6.0
	col.shape = shape
	add_child(col)
	
	add_to_group("destructible")
	add_to_group("rock_blocks")
	
	# Raise Animation
	position.y = -5
	var tween = create_tween()
	tween.tween_property(self, "position:y", 0.0, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func take_damage(amount: float):
	health -= amount
	if health <= 0:
		destroy()

func destroy():
	block_destroyed.emit()
	queue_free()

func arm_explosive(delay: float):
	# Optional: Timer logic if handled locally, but Boss currently controls timing.
	pass
