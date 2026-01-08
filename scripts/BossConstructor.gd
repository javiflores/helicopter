extends CharacterBody3D

@export var max_health: float = 1200.0
var health: float = 1200.0
var boss_name: String = "The Constructor"

var speed: float = 3.0 # Slow movement as per design (Phase 1)
var phase: int = 1
var target: Node3D = null

var drone_scene = preload("res://scenes/MobDroneScout.tscn")
var projectile_scene = preload("res://scenes/Projectile.tscn")
var wall_scene = preload("res://scenes/RockBlock.tscn")

var spawn_timer: float = 0.0
var fire_timer: float = 0.0
var ult_timer: float = 0.0
var ult_cooldown: float = 10.0 # Faster Ultimate frequency

signal boss_died

func _ready():
	add_to_group("enemy")
	load_stats()
	find_target()
	GameManager.notify_boss_activated(self)
	
	motion_mode = MOTION_MODE_FLOATING
	wall_min_slide_angle = 0

func load_stats():
	var boss_data = GameManager.game_data.get("enemies", {}).get("bosses", {}).get("boss_city", {})
	if not boss_data.is_empty():
		boss_name = boss_data.get("name", "The Constructor")
		var stats = boss_data.get("stats", {})
		max_health = float(stats.get("health", 1200.0))
		health = max_health
	else:
		health = max_health

func find_target():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]

func _physics_process(delta):
	# Height Constraint (Keep Boss at Y=1.5 to hover above walls but stay hittable)
	# Use 1.5 so it doesn't clip into ground but projectiles (often at y=1.0 with radius) should hit it.
	# Actually, if projectile is at 1.0, and boss at 1.5, assuming Boss has height ~2, it works.
	# If boss goes too high, force it down.
	var target_height = 1.0
	if abs(global_position.y - target_height) > 0.1:
		global_position.y = move_toward(global_position.y, target_height, 5.0 * delta)
	velocity.y = 0

	if health <= 0: return
	if not target:
		find_target()
		return

	# Phase Logic
	if phase == 1 and health < max_health * 0.5:
		enter_phase_2()

	if phase == 1:
		handle_phase_1(delta)
	elif phase == 2:
		handle_phase_2(delta)
	elif phase == 3:
		handle_phase_3(delta)
		
func handle_phase_1(delta):
	# "Builder": Moves slowly, constructs 'Blast Walls' that block fire, summons Scout Drones.
	
	# Movement
	var dir = (target.global_position - global_position).normalized()
	dir.y = 0
	velocity = dir * speed
	move_and_slide()
	
	# Facing
	if dir.length_squared() > 0.01:
		look_at(global_position + dir, Vector3.UP)
	
	# Summon Drones & Walls
	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_timer = 3.0 # Faster spawn rate (was 5.0)
		spawn_minions()
		build_wall()

	# Fire Slow Projectile
	fire_timer -= delta
	if fire_timer <= 0:
		fire_timer = 2.5 # Slow rate of fire
		fire_single_projectile()

func fire_single_projectile():
	var proj = projectile_scene.instantiate()
	get_tree().root.add_child(proj)
	proj.global_position = global_position + Vector3(0, 2, 0)
	
	# Configure(damage, range, speed, owner)
	proj.configure(10.0, 40.0, 20.0, self) 
	
	var aim_dir = (target.global_position - proj.global_position).normalized()
	proj.velocity = aim_dir * 20.0
	proj.look_at(proj.global_position + aim_dir, Vector3.UP)

func handle_phase_2(delta):
	# "Intermediate": Stops moving, spawns 10 walls, waits 10s, then ULTIMATE.
	velocity = Vector3.ZERO
	
	# Rotate to face player
	var dir = (target.global_position - global_position).normalized()
	if dir.length_squared() > 0.01:
		look_at(global_position + dir, Vector3.UP)
	
	# Countdown to destruction
	ult_timer -= delta
	if ult_timer <= 0:
		perform_ultimate()
		enter_phase_3()

func handle_phase_3(delta):
	# "Fortress": Stationary, Dual Turrets, BUT calls Minions/Walls too.
	velocity = Vector3.ZERO
	
	# Face Player
	var dir = (target.global_position - global_position).normalized()
	if dir.length_squared() > 0.01:
		look_at(global_position + dir, Vector3.UP)
	
	# Dual Fire
	fire_timer -= delta
	if fire_timer <= 0:
		fire_timer = 0.5 # Fast fire rate
		fire_dual_turrets()
		
	# Spawn Mechanics (Retained from Phase 1)
	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_timer = 3.0 # Faster spawn rate (Phase 3)
		spawn_minions()
		build_wall()

func spawn_minions():
	# Spawn 1-2 Scout Drones
	print("Constructor summoning drones...")
	for i in range(2):
		var angle = randf() * PI * 2.0
		var offset = Vector3(cos(angle) * 8, 0, sin(angle) * 8)
		var drone = drone_scene.instantiate()
		get_parent().add_child(drone)
		drone.global_position = global_position + offset
		drone.global_position.y = 1.0 
		drone.add_to_group("enemy")
		
		# Drone self-configures in _ready()
		# if drone.has_method("configure"):
		# 	drone.configure("mob_drone_scout")

func build_wall():
	# Renamed concept: Raise Rock Block
	# Phase 1/3 Logic: Raises a block near player or directional.
	raise_rock_block(false)

func raise_rock_block(is_cluster: bool = false):
	if not wall_scene: return
	
	# In Phase 3, we spawn blocks that explode after 1.5 seconds
	var should_explode_soon = (phase == 3)
	
	var block = wall_scene.instantiate()
	
	var spawn_pos = Vector3.ZERO
	
	if is_cluster:
		# Random position around boss
		var angle = randf() * PI * 2.0
		var dist = randf_range(5.0, 20.0)
		spawn_pos = global_position + Vector3(cos(angle) * dist, 0, sin(angle) * dist)
	elif phase == 3:
		# Phase 3: Flank the player to block movement (Attack Mode)
		# Calculate Left/Right of player relative to Boss
		var dir_to_player = (target.global_position - global_position).normalized()
		var right_vec = dir_to_player.cross(Vector3.UP).normalized()
		
		# Randomly pick Left or Right side, close range (3-5 units)
		var side_dir = right_vec if randf() > 0.5 else -right_vec
		
		# Add some forward/backward noise so it's not a perfect line
		var noise = dir_to_player * randf_range(-2.0, 2.0)
		
		spawn_pos = target.global_position + (side_dir * randf_range(3.0, 5.0)) + noise
	else:
		# Phase 1: Raise close to player randomly (Setting up environment/Prison)
		# Random point within 3-8 units of player
		var angle = randf() * PI * 2.0
		var dist = randf_range(3.0, 8.0)
		spawn_pos = target.global_position + Vector3(cos(angle) * dist, 0, sin(angle) * dist)
	
	# Set position BEFORE adding to tree so _ready() logic works correctly (starts at -5 relative to this)
	spawn_pos.y = 0 
	block.position = spawn_pos
	
	get_parent().add_child(block)
	
	if should_explode_soon:
		# Delayed fuse for Phase 3 (tuned to 1.5s)
		get_tree().create_timer(1.5).timeout.connect(func():
			if is_instance_valid(block):
				spawn_shrapnel(block.global_position)
				block.destroy()
		)

func spawn_cluster_walls():
	# Spawns 10 rock blocks randomly
	print("Constructor raising ROCK CLUSTER!")
	for i in range(10):
		raise_rock_block(true)

func fire_dual_turrets():
	var offsets = [Vector3(-1, 2, -1), Vector3(1, 2, -1)]
	for offset in offsets:
		var spawn_pos = to_global(offset)
		var proj = projectile_scene.instantiate()
		get_tree().root.add_child(proj)
		proj.global_position = spawn_pos
		proj.configure(15.0, 50.0, 35.0, self) 
		var dir = (target.global_position - spawn_pos).normalized()
		proj.velocity = dir * 35.0
		proj.look_at(spawn_pos + dir, Vector3.UP)

func perform_ultimate():
	print("BOSS ULTIMATE: ROCK DETONATION!")
	var blocks = get_tree().get_nodes_in_group("rock_blocks")
	for block in blocks:
		if is_instance_valid(block):
			spawn_shrapnel(block.global_position)
			block.destroy()
	spawn_shrapnel(global_position, 8)

func spawn_shrapnel(origin: Vector3, count: int = 4):
	for i in range(count):
		var angle = (PI * 2.0 * i) / count
		var dir = Vector3(cos(angle), 0, sin(angle))
		var proj = projectile_scene.instantiate()
		get_tree().root.add_child(proj)
		proj.global_position = origin + Vector3(0, 1, 0)
		proj.configure(10.0, 20.0, 20.0, self)
		proj.velocity = dir * 20.0
		proj.look_at(proj.global_position + dir, Vector3.UP)

func enter_phase_2():
	phase = 2
	print("BOSS PHASE 2: ROCK CLUSTER CHARGE")
	spawn_cluster_walls()
	ult_timer = 5.0 # Reduced to 5 seconds
	GameManager.notify_boss_health(health, max_health)

func enter_phase_3():
	phase = 3
	print("BOSS PHASE 3: FORTRESS + SPAWN MODE")
	spawn_timer = 5.0 # Reset spawn timer: Start immediately with a full cycle or 3s? 
	# Let's keep it consistent with the logic in P3
	
func take_damage(amount, _source_pos=Vector3.ZERO):
	health -= amount
	GameManager.notify_boss_health(health, max_health)
	if health <= 0:
		die()

func die():
	print("Boss Defeated!")
	boss_died.emit()
	queue_free()
