extends CharacterBody3D

# Config values will be loaded here
var movement_speed = 1.5
var acceleration = 10.0
var deceleration = 3.0
var max_speed = 1.0
var rotation_speed = 5.0

# Current State
var input_vector = Vector2.ZERO
var health: float = 100.0
var max_health: float = 100.0

# Dash
var can_dash: bool = true
var is_dashing: bool = false
var dash_duration: float = 0.3
var dash_speed_multiplier: float = 3.0
var dash_cooldown: float = 2.0
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var invulnerable: bool = false

# Weapon
var current_weapon = null

var main_rotor: Node3D = null
var tail_rotor: Node3D = null
var aim_reticle: Node3D = null

func _ready():
	add_to_group("player")
	
	# Collision Settings
	collision_layer = 2 # Layer 2: Player
	collision_mask = 5  # Mask 1 (World) + 4 (Enemy). Collide with enemies.
	motion_mode = MOTION_MODE_FLOATING # Smoother physics for flying
	wall_min_slide_angle = 0 # Slide off everything
	
	load_stats()
	setup_visuals()
	equip_weapon("weapon_machine_gun")
	setup_reticle()

func setup_reticle():
	var reticle_scene = load("res://scenes/AimReticle.tscn")
	if reticle_scene:
		aim_reticle = reticle_scene.instantiate()
		# Add to tree, top_level makes it world-space independent of parent rotation
		add_child(aim_reticle)
		aim_reticle.set_as_top_level(true)
		aim_reticle.visible = false

func load_stats():
	if GameManager.game_data.is_empty():
		print("GameManager data not loaded yet!")
		return
		
	var mechanics = GameManager.game_data.get("player", {}).get("mechanics", {})
	var physics_params = mechanics.get("movement_physics", {}).get("tuning_parameters", {})
	
	acceleration = physics_params.get("acceleration", 60.0)
	#acceleration = physics_params.get("acceleration", 120.0)
	deceleration = physics_params.get("deceleration", 40.0)
	#deceleration = physics_params.get("deceleration", 100.0)
	# max_speed is "defined_by_heli_specs", let's defaults to 100 for now or read from starter heli
	var starter_heli = GameManager.game_data.get("player", {}).get("helicopters", {}).get("heli_starter", {})
	var specs = starter_heli.get("specs", {})
	max_speed = float(specs.get("speed", 30.0))
	
	health = float(specs.get("health", 100))
	max_health = health
	
	# Load rotation smoothing
	var smoothing = float(physics_params.get("rotation_smoothing", 0.1))
	# Convert smoothing to speed (higher smoothing = slower rotation)
	rotation_speed = 1.0 / max(0.01, smoothing) * 2.0 # Adjusted for "feel"
	
	# Load dash (invulnerability frames)
	var combat_phys = mechanics.get("combat_physics", {}).get("invulnerability_frames", {})
	dash_duration = float(combat_phys.get("on_dash_duration", 0.3))
	
	print("Player Stats Loaded: Accel=", acceleration, " Decel=", deceleration, " MaxSpeed=", max_speed, " Health=", health)

func equip_weapon(id: String):
	if current_weapon:
		current_weapon.queue_free()
	
	current_weapon = WeaponFactory.create_weapon(id)
	if current_weapon:
		add_child(current_weapon)
		# Position it slightly forward
		current_weapon.position = Vector3(0, 0, -1.5)

func _physics_process(delta):
	# Handle Dash Timers
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			end_dash()
	elif not can_dash:
		dash_cooldown_timer -= delta
		if dash_cooldown_timer <= 0:
			can_dash = true

	get_input()
	handle_movement(delta)
	handle_aiming(delta)
	handle_combat(delta)

func get_input():
	# Updated to use custom Input Map actions
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	input_vector = input_dir
	
	if Input.is_action_just_pressed("dash") and can_dash and input_vector != Vector2.ZERO:
		start_dash()

	# Debug Weapon Swap
	if Input.is_key_pressed(KEY_1):
		equip_weapon("weapon_machine_gun")
	if Input.is_key_pressed(KEY_2):
		equip_weapon("weapon_rocket")

func start_dash():
	can_dash = false
	is_dashing = true
	invulnerable = true
	dash_timer = dash_duration * 1.5 # Slightly longer duration for feel
	# Store initial burst logic?
	# Simple tweak: Less multiplier, clearer feedback

func end_dash():
	is_dashing = false
	invulnerable = false
	dash_cooldown_timer = dash_cooldown

func handle_movement(delta):
	# Calculate direction relative to camera
	var camera = get_viewport().get_camera_3d()
	var direction = Vector3.ZERO
	
	if camera:
		var cam_basis = camera.global_transform.basis
		var forward = cam_basis.z
		var right = cam_basis.x
		
		# Project onto horizontal plane
		forward.y = 0
		right.y = 0
		forward = forward.normalized()
		right = right.normalized()
		
		# Input Vector Y is Forward(-1)/Back(1), so multiply by forward
		# Input Vector X is Left(-1)/Right(1), so multiply by right
		direction = (right * input_vector.x + forward * input_vector.y).normalized()
	else:
		# Fallback to world space
		direction = Vector3(input_vector.x, 0, input_vector.y).normalized()
	
	if is_dashing:
		# Smooth Dash: Force velocity but let it decay or just be a constant high speed
		var dash_mult = 2.0 # Reduced from 3.0
		if direction != Vector3.ZERO:
			velocity = direction * max_speed * dash_mult
		else:
			# Dash forward if no input? Or just stop?
			# Usually dash goes in facing direction if no input
			# For now, if no input, dash checks velocity or forward
			var forward = -transform.basis.z
			velocity = forward * max_speed * dash_mult
			
		move_and_slide()
		return

	if direction != Vector3.ZERO:
		# Accelerate
		velocity.x = move_toward(velocity.x, direction.x * max_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * max_speed, acceleration * delta)
	else:
		# Decelerate
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0, deceleration * delta)
		
	# Banking Visuals (Apply to Mesh, not Root)
	var mesh = get_node_or_null("VisualModel")
	if mesh:
		# Use direction if we have input, otherwise use velocity for banking while sliding to a stop
		var move_ref = direction
		if move_ref == Vector3.ZERO and velocity.length() > 0.1:
			move_ref = velocity.normalized()
			
		# Transform movement into Local Space of the Helicopter for banking tilt
		var local_move = global_transform.basis.inverse() * move_ref
		
		# If no input and no velocity, local_move is zero, so target tilt will be zero (resetting stance)
		var target_tilt_z = -local_move.x * 0.4
		var target_tilt_x = local_move.z * 0.4 # Pitch forward/back
		
		mesh.rotation.z = lerp_angle(mesh.rotation.z, target_tilt_z, delta * 5.0)
		mesh.rotation.x = lerp_angle(mesh.rotation.x, target_tilt_x, delta * 5.0)
	
	move_and_slide()

	# Constrain Height to avoid drift
	if abs(global_position.y - 1.0) > 0.05:
		var target_y = 1.0
		# Soft correct or hard snap? Hard snap for robustness
		global_position.y = move_toward(global_position.y, target_y, 10.0 * delta)
	velocity.y = 0

# Loot
var scraps: int = 0
var intel: int = 0
var scraps_since_upgrade: int = 0

func collect_loot(type: int, amount: float):
	match type:
		0: # SCRAP
			var int_amount = int(amount)
			scraps += int_amount
			scraps_since_upgrade += int_amount
			print("Collected Scraps: ", amount, " Total: ", scraps)
			
			if scraps_since_upgrade >= 100:
				scraps_since_upgrade -= 100
				trigger_upgrade()
		1: # INTEL
			intel += int(amount)
			print("Collected Intel: ", amount, " Total: ", intel)
		2: # HEALTH
			health = min(health + amount, max_health)
			print("Healed: ", amount, " HP: ", health)

func trigger_upgrade():
	var upgrade_scene = load("res://scenes/UI/UpgradeScreen.tscn")
	if upgrade_scene:
		var upgrade_ui = upgrade_scene.instantiate()
		# Add to HUD layer or just root
		var canvas = get_tree().root.find_child("CanvasLayer", true, false)
		if canvas:
			canvas.add_child(upgrade_ui)
		else:
			get_tree().root.add_child(upgrade_ui)
		upgrade_ui.setup(self)

func take_damage(amount: float):
	if invulnerable:
		print("Player dodged damage (I-Frames)")
		return
		
	health -= amount
	print("Player took damage: ", amount, " Current HP: ", health)
	if health <= 0:
		die()

signal player_died

func die():
	print("Player Died!")
	player_died.emit()
	queue_free()

func handle_aiming(delta):
	var target_pos = Vector3.ZERO
	var has_target = false
	var camera = get_viewport().get_camera_3d()
	
	# Gamepad Aiming (Priority)
	var aim_input = Input.get_vector("aim_left", "aim_right", "aim_forward", "aim_back")
	if aim_input.length() > 0.1:
		if camera:
			var cam_basis = camera.global_transform.basis
			var forward = cam_basis.z
			var right = cam_basis.x
			forward.y = 0
			right.y = 0
			forward = forward.normalized()
			right = right.normalized()
			
			var aim_dir = (right * aim_input.x + forward * aim_input.y).normalized()
			target_pos = global_position + aim_dir * 10.0
		else:
			var target_offset = Vector3(aim_input.x, 0, aim_input.y) * 10.0
			target_pos = global_position + target_offset
		has_target = true
	else:
		# Mouse Aiming (Fallback)
		if camera:
			var mouse_pos = get_viewport().get_mouse_position()
			var ray_origin = camera.project_ray_origin(mouse_pos)
			var ray_normal = camera.project_ray_normal(mouse_pos)
			var plane = Plane(Vector3.UP, global_position.y) # Use heli height
			var intersection = plane.intersects_ray(ray_origin, ray_normal)
			if intersection:
				target_pos = intersection
				has_target = true
	
	if has_target:
		var target_dir = (target_pos - global_position).normalized()
		target_dir.y = 0
		
		if target_dir.length_squared() > 0.001:
			var forward = -global_transform.basis.z
			var angle_diff = forward.signed_angle_to(target_dir, Vector3.UP)
			var cone_half = deg_to_rad(15.0) # 30 degree total cone
			
			# 1. Weapon pivots freely within the cone
			if current_weapon:
				current_weapon.rotation.y = clamp(angle_diff, -cone_half, cone_half)
			
			# 2. Body only turns if target is outside the 30deg cone
			if abs(angle_diff) > cone_half:
				var current_quat = global_transform.basis.get_rotation_quaternion()
				var target_basis = Basis.looking_at(target_dir, Vector3.UP)
				var target_quat = target_basis.get_rotation_quaternion()
				
				# Smoothly interpolate body rotation
				var new_quat = current_quat.slerp(target_quat, delta * rotation_speed)
				global_basis = Basis(new_quat)
			
		# Update reticle position
		if aim_reticle:
			aim_reticle.global_position = target_pos
			aim_reticle.global_position.y = 0.05
			aim_reticle.visible = true
	else:
		if aim_reticle:
			aim_reticle.visible = false
		if current_weapon:
			current_weapon.rotation.y = lerp_angle(current_weapon.rotation.y, 0, delta * 5.0)

func handle_combat(_delta):
	if current_weapon:
		if Input.is_action_pressed("fire_primary"):
			current_weapon.attempt_fire()
			
func setup_visuals():
	# Load actual Mesh
	var heli_scene = load("res://resources/heli/Military_Helicopter01.fbx")
	if heli_scene:
		var visual_node = heli_scene.instantiate()
		visual_node.name = "VisualModel"
		add_child(visual_node)
		visual_node.rotation_degrees.y = 180
		visual_node.scale = Vector3(0.5, 0.5, 0.5)
	else:
		print("Failed to load heli mesh, using fallback.")
		var mesh_instance = MeshInstance3D.new()
		var capsule = CapsuleMesh.new()
		capsule.height = 2.0
		capsule.radius = 1.0
		mesh_instance.mesh = capsule
		mesh_instance.rotation_degrees.x = 90
		mesh_instance.name = "VisualModel"
		add_child(mesh_instance)
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color.BLUE
		mesh_instance.set_surface_override_material(0, material)
		
	# Add simple collision (Keep capsule for physics)
	var col_shape = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.height = 2.0
	shape.radius = 1.0
	col_shape.shape = shape
	col_shape.rotation_degrees.x = 90
	add_child(col_shape)
	
	# After setup, find rotors
	if has_node("VisualModel"):
		var visual_node = get_node("VisualModel")
		# We search specifically for the tail one first ("Back" or "Tail")
		var tr_node = _find_child_by_pattern(visual_node, ["Back", "Tail"])
		# Then look for the main rotor
		var mr_node = _find_main_rotor(visual_node, tr_node)
		
		if mr_node:
			print("Found Main Rotor: ", mr_node.name)
			main_rotor = _create_pivot_for_rotor(mr_node)
		if tr_node:
			print("Found Tail Rotor: ", tr_node.name)
			tail_rotor = _create_pivot_for_rotor(tr_node)

func _create_pivot_for_rotor(rotor_node: MeshInstance3D) -> Node3D:
	# To fix "rotating from the edge" without moving the rotor's location:
	# 1. Calculate the center of the mesh in its own local coordinates
	var aabb = rotor_node.get_aabb()
	var center_local = aabb.get_center()
	
	# 2. Create the pivot
	var parent = rotor_node.get_parent()
	var pivot = Node3D.new()
	pivot.name = rotor_node.name + "_Pivot"
	
	# 3. Position the pivot at the mount point PLUS the offset to the center
	# This ensures the rotation happens at the geometric center
	parent.add_child(pivot)
	pivot.transform = rotor_node.transform
	pivot.translate_object_local(center_local)
	
	# 4. Move rotor to be local child of pivot, but offset by -center_local
	# to keep it at the same "Global" position it was before.
	rotor_node.get_parent().remove_child(rotor_node)
	pivot.add_child(rotor_node)
	rotor_node.transform = Transform3D.IDENTITY
	rotor_node.position = -center_local
	
	return pivot

func _process(delta):
	if main_rotor:
		main_rotor.rotate_y(10.0 * delta)
	
	if tail_rotor:
		# Tail rotor usually spins on its local X or Z axis relative to the helicopter
		# Since we matched it to a pivot, we can experiment. Most FBX tail rotors rotate on X.
		tail_rotor.rotate_x(25.0 * delta)

func print_tree_recursive(node: Node, indent: String = ""):
	print(indent + node.name + " (" + node.get_class() + ")")
	for child in node.get_children():
		print_tree_recursive(child, indent + "  ")

func _find_child_by_pattern(root: Node, patterns: Array) -> Node:
	if root.name.find("Rotor") != -1 or root.name.find("Blade") != -1:
		for pattern in patterns:
			if root.name.findn(pattern) != -1:
				return root
	for child in root.get_children():
		var found = _find_child_by_pattern(child, patterns)
		if found: return found
	return null

func _find_main_rotor(root: Node, tail_ref: Node) -> Node:
	if root.name.find("Rotor") != -1 and root != tail_ref:
		if root.name.findn("Back") == -1 and root.name.findn("Tail") == -1:
			return root
	for child in root.get_children():
		var found = _find_main_rotor(child, tail_ref)
		if found: return found
	return null
