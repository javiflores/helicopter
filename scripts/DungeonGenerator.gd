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
