extends CharacterBody3D

# MobDroneSupport: Healer, weak, prioritizes cover.

var mob_id: String = "mob_drone_support"

var health: float = 60.0
var move_speed: float = 12.0
var detection_range: float = 25.0
# Healing mechanics
var heal_range: float = 8.0
var heal_amount_per_tick: float = 5.0
var heal_tick_rate: float = 1.0
var heal_timer: float = 0.0

var is_healing: bool = false

enum State { IDLE, FOLLOW_ALLY, SUPPORT, FLEE, SEEK_COVER }
var current_state = State.IDLE
var player: Node3D = null
var target_ally: Node3D = null
var cover_tank: Node3D = null

var pickup_scene = preload("res://scenes/Pickup.tscn")
# No projectile scene, this drone doesn't shoot

# Visuals for healing
var heal_radius_indicator: MeshInstance3D = null

func _ready():
	add_to_group("enemies")
	configure()
	
	# Find player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		
	# Collision Settings
	collision_layer = 4 
	collision_mask = 7 
	motion_mode = MOTION_MODE_FLOATING
	
	setup_heal_visuals()

func configure():
	var mobs_db = GameManager.game_data.get("enemies", {}).get("mobs", {})
	if mob_id in mobs_db:
		var data = mobs_db[mob_id]
		var stat_data = data.get("stats", {})
		health = float(stat_data.get("health", 60.0))
		move_speed = float(data.get("speed", "12"))
		
		print("Support Drone Configured: HP:", health, " Spd:", move_speed)
		setup_visuals()

func _physics_process(delta):
	# Refresh player ref if needed
	if not is_instance_valid(player):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0: player = players[0]
	
	# 1. State Transitions & Logic
	match current_state:
		State.IDLE:
			# Look for allies to support
			target_ally = find_best_ally()
			if target_ally:
				current_state = State.FOLLOW_ALLY
			elif is_instance_valid(player) and global_position.distance_to(player.global_position) < detection_range:
				# Alone and threatened? Flee.
				current_state = State.FLEE
				
		State.FOLLOW_ALLY:
			if not is_instance_valid(target_ally):
				current_state = State.IDLE
				target_ally = null
				return
			
			# Check for cover opportunity while following
			if not is_instance_valid(cover_tank):
				find_and_request_cover()
			
			if is_instance_valid(cover_tank):
				current_state = State.SEEK_COVER
				return
				
			# If ally is hurt/combat starts, switch to SUPPORT
			if is_ally_hurt(target_ally) or (is_instance_valid(player) and global_position.distance_to(player.global_position) < detection_range):
				current_state = State.SUPPORT
			else:
				# Just follow
				var desired_pos = target_ally.global_position - (target_ally.global_transform.basis.z * -3.0) # Follow behind
				if global_position.distance_to(desired_pos) > 2.0:
					move_towards(desired_pos, move_speed)
				else:
					velocity = Vector3.ZERO
		
		State.SUPPORT:
			# Activate Healing Field
			is_healing = true
			if not is_instance_valid(target_ally) and not find_best_ally():
				is_healing = false
				current_state = State.FLEE # Everyone dead
			else:
				# Try to stay near allies, but keep distance from player
				var center_mass = get_allies_center_mass()
				if global_position.distance_to(center_mass) > 3.0:
					move_towards(center_mass, move_speed)
				else:
					velocity = Vector3.ZERO
				
				# Healing Logic
				heal_timer -= delta
				if heal_timer <= 0:
					heal_timer = heal_tick_rate
					perform_aoe_heal()

		State.SEEK_COVER:
			if not is_instance_valid(cover_tank):
				cover_tank = null
				current_state = State.IDLE
				return
				
			var tank_pos = cover_tank.global_position
			var threat_pos = Vector3.ZERO
			if is_instance_valid(player):
				threat_pos = player.global_position
			else:
				# Default threat direction if no player seen, maybe just behind tank relative to its facing?
				threat_pos = tank_pos + (cover_tank.global_transform.basis.z * 10.0)

			var dir_threat_to_tank = (tank_pos - threat_pos).normalized()
			
			# Hiding spot is further behind tank
			var desired_pos = tank_pos + (dir_threat_to_tank * 3.0) 
			
			if global_position.distance_to(desired_pos) > 0.5:
				move_towards(desired_pos, move_speed)
			else:
				velocity = Vector3.ZERO
			
			# Can still heal while in cover!
			is_healing = true
			heal_timer -= delta
			if heal_timer <= 0:
				heal_timer = heal_tick_rate
				perform_aoe_heal()

		State.FLEE:
			if not is_instance_valid(player):
				current_state = State.IDLE
				return
				
			var dir_away = (global_position - player.global_position).normalized()
			velocity = dir_away * move_speed
			
			# If far enough, go back to IDLE
			if global_position.distance_to(player.global_position) > detection_range * 1.5:
				current_state = State.IDLE

	move_and_slide()
	update_visuals()

func move_towards(target_pos, speed):
	var direction = (target_pos - global_position).normalized()
	direction.y = 0 
	velocity = direction * speed
	if direction.length_squared() > 0.01:
		look_at(global_position + direction, Vector3.UP)

func find_best_ally() -> Node3D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var best = null
	var min_dist = 999.0
	
	for enemy in enemies:
		if enemy == self or not is_instance_valid(enemy): continue
		# Prioritize Tanks or Elites
		var eid = enemy.get("mob_id")
		if eid == "mob_drone_tank" or eid == "mob_elite_hunter":
			var d = global_position.distance_to(enemy.global_position)
			if d < min_dist:
				min_dist = d
				best = enemy
	
	# Fallback to any enemy
	if not best:
		for enemy in enemies:
			if enemy == self: continue
			best = enemy # Just pick one
			break
			
	return best

func is_ally_hurt(ally) -> bool:
	if not ally: return false
	# Assuming enemies have 'health' and maybe 'max_health' or we just guess
	# For now, if they are taking damage they might need help.
	# Simplification: Always support if combat active.
	return true

func find_and_request_cover():
	# Find nearby tank
	var distinct_tanks = []
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.get("mob_id") == "mob_drone_tank":
			distinct_tanks.append(e)
			
	for tank in distinct_tanks:
		if global_position.distance_to(tank.global_position) < 15.0:
			if tank.has_method("request_priority_cover"):
				if tank.request_priority_cover(self):
					cover_tank = tank
					print("Support Drone got priority cover!")
					return

func unregister_cover():
	# Called if we die or leave manually
	if is_instance_valid(cover_tank) and cover_tank.has_method("unregister_cover_occupant"):
		cover_tank.unregister_cover_occupant(self)

func get_allies_center_mass() -> Vector3:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var center = Vector3.ZERO
	var count = 0
	for e in enemies:
		if e == self: continue
		if global_position.distance_to(e.global_position) < heal_range * 1.5:
			center += e.global_position
			count += 1
	if count > 0:
		return center / count
	return global_position

func perform_aoe_heal():
	var enemies = get_tree().get_nodes_in_group("enemies")
	var healed_any = false
	for e in enemies:
		if e == self: continue
		if global_position.distance_to(e.global_position) <= heal_range:
			if e.has_method("heal"):
				e.heal(heal_amount_per_tick)
				healed_any = true
			elif "health" in e:
				# Direct variable access fallback? Safer to rely on method.
				e.health += heal_amount_per_tick
				healed_any = true
				
	if healed_any:
		# Play heal effect
		pulse_heal_visual()

func take_damage(amount: float):
	health -= amount
	if health <= 0:
		die()

func die():
	unregister_cover()
	if pickup_scene:
		var pickup = pickup_scene.instantiate()
		get_parent().add_child(pickup)
		pickup.global_position = global_position
		pickup.amount = randi_range(1, 3)
	queue_free()

func setup_visuals():
	# Visuals for Support (Green, Cross-ish)
	var mesh_inst = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1.2, 0.8, 1.2) # Flatter
	mesh_inst.mesh = box
	mesh_inst.position.y = 1.0 # Hover height offset
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.GREEN
	mesh_inst.set_surface_override_material(0, material)
	add_child(mesh_inst)
	
	# Vertical part of cross
	var v_mesh = MeshInstance3D.new()
	var v_box = BoxMesh.new()
	v_box.size = Vector3(0.4, 0.4, 1.6)
	v_mesh.mesh = v_box
	v_mesh.position.y = 1.0 # Hover height offset
	v_mesh.set_surface_override_material(0, material)
	add_child(v_mesh)
	
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1.2, 1.2, 1.2)
	col.shape = shape
	col.position.y = 1.0 # Match visual hover height
	add_child(col)

func setup_heal_visuals():
	# Transparent green sphere/cylinder for range
	var mesh = CylinderMesh.new()
	mesh.top_radius = heal_range
	mesh.bottom_radius = heal_range
	mesh.height = 0.1
	
	heal_radius_indicator = MeshInstance3D.new()
	heal_radius_indicator.mesh = mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0, 1, 0, 0.1) # Transparent Green
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	heal_radius_indicator.set_surface_override_material(0, mat)
	add_child(heal_radius_indicator)
	heal_radius_indicator.visible = false

func update_visuals():
	if heal_radius_indicator:
		heal_radius_indicator.visible = is_healing

func pulse_heal_visual():
	# Simple tween pulse could go here, for now just toggle visibility logic handles it
	pass
