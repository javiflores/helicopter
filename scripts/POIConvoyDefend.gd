extends Node3D

@export var vehicle_count: int = 4
@export var trigger_distance: float = 20.0
@export var spawn_interval: float = 4.0
@export var reward_per_survivor: int = 150

var vehicles: Array = []
var vehicles_finished: int = 0
var vehicles_destroyed: int = 0
var is_active: bool = true
var is_triggered: bool = false
var spawn_timer: float = 0.0

var vehicle_scene = preload("res://scenes/ConvoyVehicle.tscn")
var enemy_scene = preload("res://scenes/MobDroneScout.tscn")

@onready var start_point = $StartPoint
@onready var end_point = $EndPoint

signal convoy_completed

func _ready():
	# Register with GameManager
	if GameManager.has_method("register_objective"):
		GameManager.register_objective(self)
	
	# Defer setup to ensure DungeonGenerator has finished moving us to the correct spot
	# otherwise global_position calculations will be wrong (at 0,0,0)
	call_deferred("setup_convoy")

func setup_convoy():
	var garage_scene = load("res://scenes/structures/Garage.tscn")
	if garage_scene:
		# Direction vector (Start -> End) flattened
		var flat_start = Vector3(global_position.x, 0, global_position.z)
		var flat_end = Vector3(end_point.global_position.x, 0, end_point.global_position.z)
		var dir_to_end = (flat_end - flat_start).normalized()
		
		# START GARAGE
		var start_garage = garage_scene.instantiate()
		add_child(start_garage)
		start_garage.global_position = global_position
		start_garage.look_at(global_position + dir_to_end, Vector3.UP)
		start_garage.rotate_y(PI) # Flip so open side faces destination
		
		# END GARAGE
		var end_garage = garage_scene.instantiate()
		add_child(end_garage)
		# Place garage CENTERED on the EndPoint
		end_garage.global_position = end_point.global_position
		
		# Orient to Face Start
		# Opening (+Z) faces Start (-dir).
		# Back (-Z) faces End (+dir).
		end_garage.look_at(end_point.global_position + dir_to_end, Vector3.UP)

	for i in range(vehicle_count):
		var vehicle = vehicle_scene.instantiate()
		add_child(vehicle)
		
		var flat_start = Vector3(global_position.x, 0, global_position.z)
		var flat_end = Vector3(end_point.global_position.x, 0, end_point.global_position.z)
		var dir_to_end = (flat_end - flat_start).normalized()
		var right = dir_to_end.cross(Vector3.UP).normalized()
		
		# SPAWN Formation (2x2) inside Start Garage
		# i=0: left front, i=1: right front, i=2: left back, i=3: right back
		var row = floor(i / 2.0)
		var col = i % 2
		var col_offset = (col * 3.0) - 1.5
		var row_offset = - row * 3.0
		
		# Move start slightly towards end so we aren't completely in wall?
		# Actually center is fine.
		var spawn_pos_rel = (right * col_offset) + (dir_to_end * (row_offset + 1.5))
		vehicle.global_position = global_position + spawn_pos_rel
		
		vehicle.look_at(end_point.global_position, Vector3.UP)
		
		# PARK Formation (2x2) CENTERED inside End Garage
		# The End Garage is centered at EndPoint. 
		# We want vehicles to park around that center point.
		
		# Row 0 (Front relative to move dir) -> +1.5m along dir
		# Row 1 (Back relative to move dir) -> -1.5m along dir
		var park_dist_from_center = 0.0
		if row == 0: park_dist_from_center = 1.5
		else: park_dist_from_center = -1.5
		
		var park_offset = (dir_to_end * park_dist_from_center) + (right * col_offset)
		
		vehicle.target_pos = end_point.global_position + park_offset
		
		vehicle.vehicle_destroyed.connect(_on_vehicle_destroyed)
		vehicles.append(vehicle)

func _process(delta):
	if not is_active:
		return
		
	if not is_triggered:
		check_trigger()
	else:
		handle_escort(delta)

func check_trigger():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var p = players[0]
		if global_position.distance_to(p.global_position) < trigger_distance:
			start_escort()

func start_escort():
	is_triggered = true
	print("Convoy Escort Triggered!")
	for v in vehicles:
		if is_instance_valid(v):
			v.moving = true
	
	spawn_timer = spawn_interval

func handle_escort(delta):
	# Spawn pressure
	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_timer = spawn_interval
		spawn_enemy_wave()
	
	# Check for completion
	var all_idle = true
	var current_survivors = 0
	
	for v in vehicles:
		if is_instance_valid(v):
			current_survivors += 1
			if v.moving:
				all_idle = false
	
	if all_idle and current_survivors > 0:
		# Check if they really reached (using their individual targets)
		var reached = true
		for v in vehicles:
			if is_instance_valid(v):
				# Check distance to THEIR target, not the global endpoint
				if v.global_position.distance_to(v.target_pos) > 8.0:
					reached = false
					break
		
		if reached:
			# Hide survivors to simulate entering garage fully
			for v in vehicles:
				if is_instance_valid(v) and v.current_health > 0:
					v.visible = false
					v.set_collision_layer_value(1, false)
			
			# Retarget all enemies to player
			get_tree().call_group("enemies", "reset_target")
			
			complete_objective(current_survivors)

func spawn_enemy_wave():
	# Spawn 2-3 enemies
	var count = randi_range(2, 3)
	
	for i in range(count):
		# Spawn CLOSE to convoy: 10-15 units away
		# Pick a random live vehicle as anchor
		var valid_vehicles = []
		for v in vehicles:
			if is_instance_valid(v) and v.current_health > 0:
				valid_vehicles.append(v)
		
		if valid_vehicles.is_empty(): return
		
		var anchor = valid_vehicles.pick_random()
		var angle = randf() * PI * 2.0
		var spawn_pos = anchor.global_position + Vector3(cos(angle) * 12.0, 0, sin(angle) * 12.0)
		
		var enemy = enemy_scene.instantiate()
		get_parent().add_child(enemy)
		enemy.global_position = spawn_pos
		
		# Assign target: 70% chance to attack convoy, 30% player
		if randf() < 0.7:
			enemy.target_override = anchor # Attack random vehicle
		else:
			# Let it default to player if available
			pass

func _on_vehicle_destroyed():
	vehicles_destroyed += 1
	var survivors = 0
	for v in vehicles:
		if is_instance_valid(v): survivors += 1
	
	if survivors == 0:
		fail_objective()

func complete_objective(survivors: int):
	is_active = false
	var total_reward = survivors * reward_per_survivor
	print("Convoy reached destination! Survivors: ", survivors, " Reward: ", total_reward)
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		players[0].collect_loot(0, total_reward)
		
	if GameManager.has_method("complete_objective"):
		GameManager.complete_objective(self)
	
	convoy_completed.emit()
	# Clean up logic or stay as landmark

func fail_objective():
	is_active = false
	print("Convoy failed. All vehicles destroyed.")
	# We still might want to call complete_objective in GameManager to not softlock?
	# Or just let it go if the player can't finish the level.
	# For now, let's just mark it done but with 0 reward.
	if GameManager.has_method("complete_objective"):
		GameManager.complete_objective(self)
