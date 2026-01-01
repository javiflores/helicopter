extends Node3D

@export var room_size: Vector2 = Vector2(20, 20)
@export var spawners: Array[Node3D]

func _ready():
	# Auto-find spawn points if not assigned
	if spawners.is_empty():
		for child in get_children():
			if child is Marker3D:
				spawners.append(child)

func get_spawn_points() -> Array[Vector3]:
	var points: Array[Vector3] = []
	for s in spawners:
		points.append(s.global_position)
	return points
