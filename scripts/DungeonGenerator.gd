extends Node3D

@export var room_scene: PackedScene
@export var enemy_scene: PackedScene

var current_rooms: Array = []

func generate_dungeon(biome_id: String):
	print("Generating Dungeon for Biome: ", biome_id)
	
	clear_dungeon()
	
	# Simple Linear Generation for Prototype
	# Start Room (0,0) -> Combat Room (0,1) -> Combat Room (0,2) -> Boss Room (0,3)
	
	var room_positions = [
		Vector3(0, 0, 0),
		Vector3(0, 0, -50),
		Vector3(0, 0, -100),
		Vector3(0, 0, -150)
	]
	
	for i in range(room_positions.size()):
		var pos = room_positions[i]
		var room = room_scene.instantiate()
		add_child(room)
		room.global_position = pos
		current_rooms.append(room)
		
		# Room Distribution:
		# 0: Start
		# 1: Combat
		# 2: Rescue POI
		# 3: Destroy POI
		if i == 1:
			spawn_enemies_in_room(room, biome_id, i)
		elif i == 2:
			spawn_poi_in_room(room, i, "res://scenes/POIRescue.tscn")
		elif i == 3:
			spawn_poi_in_room(room, i, "res://scenes/POIDestroy.tscn")
			
		# Decorate every room
		decorate_room(room)

func decorate_room(room):
	var rock_scene = load("res://scenes/environment/Rock.tscn")
	var tree_scene = load("res://scenes/environment/Tree.tscn")
	var hill_scene = load("res://scenes/environment/Hill.tscn")
	var river_scene = load("res://scenes/environment/River.tscn")
	
	# Rare River (30% chance)
	if randf() < 0.3:
		var pos = Vector3(randf_range(-5, 5), 0, 0)
		_spawn_clutter(room, river_scene, pos, 1.0, randf() * PI)
	
	# Spawn 1-2 Hills
	for h in range(randi_range(1, 2)):
		var pos = Vector3(randf_range(-20, 20), 0, randf_range(-20, 20))
		_spawn_clutter(room, hill_scene, pos, randf_range(1.0, 2.5), randf() * PI * 2)
		
	# Spawn 5-10 Trees
	for t in range(randi_range(5, 10)):
		var pos = Vector3(randf_range(-22, 22), 0, randf_range(-22, 22))
		_spawn_clutter(room, tree_scene, pos, randf_range(0.8, 1.5), randf() * PI * 2)
		
	# Spawn 3-6 Rocks
	for r in range(randi_range(3, 6)):
		var pos = Vector3(randf_range(-22, 22), 0, randf_range(-22, 22))
		_spawn_clutter(room, rock_scene, pos, randf_range(0.5, 2.0), randf() * PI * 2)

func _spawn_clutter(room, scene, local_pos, scale_mult, rot):
	if not scene: return
	var obj = scene.instantiate()
	room.add_child(obj)
	obj.position = local_pos
	obj.scale = Vector3.ONE * scale_mult
	obj.rotation.y = rot

func spawn_poi_in_room(room, _room_idx, scene_path: String):
	var poi_scene = load(scene_path)
	var points = room.get_spawn_points()
	if points.is_empty(): return
	
	var point = points.pick_random()
	var poi = poi_scene.instantiate()
	add_child(poi)
	poi.global_position = point
	print("Spawned POI (", scene_path, ") in Room ", _room_idx)

func spawn_enemies_in_room(room, _biome_id, _room_idx):
	var points = room.get_spawn_points()
	if points.is_empty(): return
	
	# Spawn 1-2 enemies per room
	var count = randi() % 2 + 1
	for j in range(count):
		var point = points.pick_random()
		var enemy = enemy_scene.instantiate()
		add_child(enemy)
		enemy.global_position = point
		# Optional: configure enemy type based on biome in future

func clear_dungeon():
	for child in get_children():
		child.queue_free()
	current_rooms.clear()
