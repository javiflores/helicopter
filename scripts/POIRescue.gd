extends Node3D

@export var rescue_duration: float = 10.0
@export var reward_amount: int = 50

var current_time: float = 0.0
var is_active: bool = true
var player_in_zone: bool = false
var player_ref = null
var ambush_triggered: bool = false

var enemy_scene = preload("res://scenes/Enemy.tscn")

signal rescue_completed

func _ready():
	$Label3D.text = "RESCUE"
	$BarRoot.visible = false
	start_flashing()
	
	# Register with GameManager
	if GameManager.has_method("register_objective"):
		GameManager.register_objective()

func start_flashing():
	var ring_mat = $RingVisual.get_active_material(0)
	if not ring_mat:
		# If using shared resource, duplicate it instance
		if $RingVisual.mesh and $RingVisual.mesh.material:
			$RingVisual.mesh.material = $RingVisual.mesh.material.duplicate()
			ring_mat = $RingVisual.mesh.material
			
	if ring_mat:
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(ring_mat, "albedo_color:a", 0.1, 1.0).set_trans(Tween.TRANS_SINE)
		tween.tween_property(ring_mat, "albedo_color:a", 0.5, 1.0).set_trans(Tween.TRANS_SINE)

@export var spawn_interval: float = 3.0
var spawn_timer: float = 0.0

func _process(delta):
	if not is_active:
		return
		
	if player_in_zone:
		current_time += delta
		update_bar()
		
		# Continuous Spawning Logic
		spawn_timer -= delta
		if spawn_timer <= 0:
			spawn_timer = spawn_interval
			spawn_wave(2) # Spawn 2 enemies every 3 seconds
		
		if current_time >= rescue_duration:
			complete_rescue()
	else:
		if current_time > 0:
			current_time -= delta # Decay progress
			update_bar()
			if current_time <= 0:
				current_time = 0
				$BarRoot.visible = false

func update_bar():
	$BarRoot.visible = true
	var progress = clamp(current_time / rescue_duration, 0.0, 1.0)
	# Scale bar on x axis
	$BarRoot/BarFill.scale.x = progress

func _on_area_3d_body_entered(body):
	if body.is_in_group("player"):
		player_in_zone = true
		player_ref = body
		
		if not ambush_triggered and is_active:
			trigger_ambush()

func trigger_ambush():
	ambush_triggered = true
	print("Rescue Ambush Triggered!")
	spawn_timer = spawn_interval # Reset timer
	spawn_wave(4) # Initial burst

func spawn_wave(count: int):
	var radius = 15.0 # Wider spawn radius
	for i in range(count):
		# Random angle variation
		var angle = randf() * PI * 2.0
		var offset = Vector3(cos(angle) * radius, 0, sin(angle) * radius)
		spawn_enemy(global_position + offset)

func spawn_enemy(pos: Vector3):
	if enemy_scene:
		var enemy = enemy_scene.instantiate()
		get_parent().add_child(enemy) # Add to world/room
		enemy.global_position = pos
		# Force aggro?
		# They have detection range 20, keeping radius 10 ensures they aggro immediately.

func _on_area_3d_body_exited(body):
	if body.is_in_group("player"):
		player_in_zone = false

func complete_rescue():
	is_active = false
	current_time = rescue_duration
	$Label3D.text = "SAVED!"
	
	# Fix: Access material correctly
	var mat = $MeshInstance3D.get_active_material(0)
	if mat:
		mat.albedo_color = Color.GREEN
	else:
		# If no active material found (e.g. on mesh resource), try getting it from mesh
		var mesh = $MeshInstance3D.mesh
		if mesh and mesh.material:
			# Duplicate to avoid affecting other instances sharing the resource
			$MeshInstance3D.mesh.material = mesh.material.duplicate()
			$MeshInstance3D.mesh.material.albedo_color = Color.GREEN
	
	if player_ref:
		if player_ref.has_method("collect_loot"):
			player_ref.collect_loot(0, reward_amount) # 0 = Scraps
			
	print("Rescue Completed! Reward: ", reward_amount)
	rescue_completed.emit()
	if GameManager.has_method("complete_objective"):
		GameManager.complete_objective()
	
	# Optional: Fly away animation or disappear
	# await get_tree().create_timer(1.0).timeout
	# queue_free()
