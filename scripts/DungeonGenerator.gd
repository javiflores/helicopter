extends Node3D

@export var room_scene: PackedScene
@export var enemy_scene: PackedScene
@export var enemy_tank_scene: PackedScene

var current_rooms: Array = []

func generate_dungeon(biome_id: String):
	print("Generating Dungeon for Biome: ", biome_id)
	
	clear_dungeon()
	
	# Dynamic Generation based on JSON
	var rules = GameManager.game_data.get("game", {}).get("rules", {})
	var poi_count = int(rules.get("pois_to_complete", 3))
	
	var world_data = GameManager.game_data.get("world", {})
	var biomes = world_data.get("biomes", {})
	var biome_data = biomes.get(biome_id, {})
	var available_pois = biome_data.get("available_pois", [])
	
	if available_pois.is_empty():
		print("Warning: No POIs found for biome ", biome_id, ". Using default.")
		available_pois = ["poi_destroy"]
	
	# Generate Start Room (Safe)
	var start_room = room_scene.instantiate()
	add_child(start_room)
	start_room.global_position = Vector3(0, 0, 0)
	current_rooms.append(start_room)
	decorate_room(start_room)
	
	var current_z = -50.0
	
	# Shuffle the available POIs to ensure uniqueness first
	var distinct_pois = available_pois.duplicate()
	distinct_pois.shuffle()
	
	# Generate POI Rooms
	for i in range(poi_count):
		var room = room_scene.instantiate()
		add_child(room)
		room.global_position = Vector3(0, 0, current_z)
		current_rooms.append(room)
		
		# Pick unique POI if possible, otherwise refill logic (simple wrap for now)
		var poi_key = ""
		if not distinct_pois.is_empty():
			poi_key = distinct_pois.pop_front()
		else:
			# Fallback if we requested more POIs than available unique types
			poi_key = available_pois.pick_random()
			
		var poi_path = get_poi_scene_path(poi_key)
		spawn_poi_in_room(room, i, poi_path)
		
		# Also spawn some ambient enemies
		spawn_enemies_in_room(room, biome_id, i)
		decorate_room(room)
		
		current_z -= 50.0
		
	# Boss Room (Final)
	# (Logic to be added later or just leave space for now)
	var boss_room = room_scene.instantiate()
	add_child(boss_room)
	boss_room.global_position = Vector3(0, 0, current_z)
	current_rooms.append(boss_room)
	# Boss spawning handled by GameLevel or separately
	decorate_room(boss_room)

func get_poi_scene_path(key: String) -> String:
	match key:
		"poi_rescue": return "res://scenes/POIRescue.tscn"
		"poi_destroy": return "res://scenes/POIDestroy.tscn"
		"poi_convoy_defend": return "res://scenes/POIConvoyDefend.tscn"
		_: return "res://scenes/POIDestroy.tscn"

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
		# 30% chance for Tank if configured, else Standard
		var chosen_scene = enemy_scene
		if enemy_tank_scene and randf() < 0.3:
			chosen_scene = enemy_tank_scene
			
		var enemy = chosen_scene.instantiate()
		add_child(enemy)
		enemy.global_position = point
		# Optional: configure enemy type based on biome in future

func clear_dungeon():
	for child in get_children():
		child.queue_free()
	current_rooms.clear()
