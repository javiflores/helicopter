extends CharacterBody3D

@export var max_health: float = 1200.0
var health: float = 1200.0
var boss_name: String = "The Constructor"

var speed: float = 5.0
var phase: int = 1
var target: Node3D = null

var drone_scene = preload("res://scenes/Enemy.tscn")
var projectile_scene = preload("res://scenes/Projectile.tscn")

var spawn_timer: float = 0.0
var fire_timer: float = 0.0

signal boss_died

func _ready():
	add_to_group("enemy")
	load_stats()
	find_target()
	GameManager.notify_boss_activated(self)

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
	if health <= 0: return
	if not target:
		find_target()
		return

	# Phase Logic
	if phase == 1 and health < max_health * 0.5:
		enter_phase_2()

	if phase == 1:
		handle_phase_1(delta)
	else:
		handle_phase_2(delta)

func handle_phase_1(delta):
	# Move slowly towards player
	var dir = (target.global_position - global_position).normalized()
	dir.y = 0
	velocity = dir * speed
	move_and_slide()
	
	look_at(global_position + dir, Vector3.UP)
	
	# Summon Drones
	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_timer = 8.0
		spawn_minions()

func handle_phase_2(delta):
	# Stationary but shoots rapidly
	var dir = (target.global_position - global_position).normalized()
	dir.y = 0
	look_at(global_position + dir, Vector3.UP)
	
	fire_timer -= delta
	if fire_timer <= 0:
		fire_timer = 0.5
		fire_projectile()

func spawn_minions():
	for i in range(2):
		var angle = randf() * PI * 2.0
		var offset = Vector3(cos(angle) * 10, 0, sin(angle) * 10)
		var drone = drone_scene.instantiate()
		get_parent().add_child(drone)
		drone.global_position = global_position + offset
		drone.global_position.y = 1.0 # Ensure they are at flight height
		drone.add_to_group("enemy") # Ensure consistent groups

func fire_projectile():
	var proj = projectile_scene.instantiate()
	get_tree().root.add_child(proj)
	proj.global_position = global_position + Vector3.UP * 2.0
	proj.configure(20.0, 50.0, 30.0, self)
	
	var dir = (target.global_position - proj.global_position).normalized()
	proj.velocity = dir * 30.0

func enter_phase_2():
	phase = 2
	print("BOSS PHASE 2: FORTRESS MODE")
	# Maybe visual change or sound

func take_damage(amount):
	health -= amount
	print("Boss hit! HP: ", health)
	GameManager.notify_boss_health(health, max_health)
	if health <= 0:
		die()

func die():
	print("Boss Defeated!")
	boss_died.emit()
	# Spawn explosions?
	queue_free()
