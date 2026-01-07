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

# Loot
var scraps: int = 0
var intel: int = 0

# Dodge (formerly Dash)
var can_dodge: bool = true
var is_dodging: bool = false
var dodge_duration: float = 0.3
var dodge_speed_multiplier: float = 3.0
var dodge_cooldown: float = 1.5
var dodge_timer: float = 0.0
var dodge_cooldown_timer: float = 0.0
var invulnerable: bool = false

# Block / Parry
var is_blocking: bool = false
var parry_window: float = 0.2
var block_timer: float = 0.0

# Skill
var skill_cooldown: float = 5.0
var skill_timer: float = 0.0
var current_skill_id: String = "skill_repair"

# Weapon
# Weapons
var primary_weapon = null
var secondary_weapon = null

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
	
	# Equip from Loadout
	current_skill_id = GameManager.current_loadout.get("skill_id", "skill_repair")
	var weapon_primary = GameManager.current_loadout.get("primary_weapon_id", "weapon_machine_gun")
	var weapon_secondary = GameManager.current_loadout.get("secondary_weapon_id", "weapon_machine_gun")
	
	load_stats()
	setup_visuals()
	
	equip_weapons(weapon_primary, weapon_secondary)
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
	deceleration = physics_params.get("deceleration", 40.0)
	
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
	
	# Load dodge (invulnerability frames)
	var combat_phys = mechanics.get("combat_physics", {}).get("invulnerability_frames", {})
	dodge_duration = float(combat_phys.get("on_dash_duration", 0.3))
	
	# Load Skill Stats
	var skill_data = GameManager.game_data.get("player", {}).get("skills", {}).get(current_skill_id, {})
	skill_cooldown = float(skill_data.get("cooldown", 5.0))
	
	print("Player Stats Loaded: Accel=", acceleration, " Decel=", deceleration, " MaxSpeed=", max_speed, " Health=", health, " Skill=", current_skill_id)

func equip_weapons(id_primary: String, id_secondary: String):
	if primary_weapon: primary_weapon.queue_free()
	if secondary_weapon: secondary_weapon.queue_free()
	
	primary_weapon = WeaponFactory.create_weapon(id_primary)
	if primary_weapon:
		add_child(primary_weapon)
		primary_weapon.position = Vector3(-0.5, 0, -1.5)
		
	secondary_weapon = WeaponFactory.create_weapon(id_secondary)
	if secondary_weapon:
		add_child(secondary_weapon)
		secondary_weapon.position = Vector3(0.5, 0, -1.5)



func _physics_process(delta):
	# Handle Dodge Timers
	if is_dodging:
		dodge_timer -= delta
		if dodge_timer <= 0:
			end_dodge()
	elif not can_dodge:
		dodge_cooldown_timer -= delta
		if dodge_cooldown_timer <= 0:
			can_dodge = true

	# Handle Skill Timer
	if skill_timer > 0:
		skill_timer -= delta

	get_input()
	handle_movement(delta)
	handle_aiming(delta)
	handle_combat(delta)

func get_input():
	# Updated to use custom Input Map actions
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	input_vector = input_dir
	
	# Dodge
	if Input.is_action_just_pressed("dodge") and can_dodge and input_vector != Vector2.ZERO:
		start_dodge()
		
	# Block
	is_blocking = Input.is_action_pressed("block")
	if Input.is_action_just_pressed("block"):
		block_timer = 0.0 # Reset for parry check
	if is_blocking:
		block_timer += get_process_delta_time()
		
	# Skill
	if Input.is_action_just_pressed("skill") and skill_timer <= 0:
		use_skill()

	# Debug Weapon Swap Logic Removed

func start_dodge():
	can_dodge = false
	is_dodging = true
	invulnerable = true
	dodge_timer = dodge_duration * 1.5 
	
	# Visual Feedback: Barrel Roll or Tilt
	var mesh = get_node_or_null("VisualModel")
	if mesh:
		var tween = create_tween()
		# Quick 360 roll on X or Z depending on move dir?
		# Simple "flash" transparency for now
		tween.tween_property(mesh, "scale", Vector3(0.1, 0.1, 0.1), 0.1)
		tween.tween_property(mesh, "scale", Vector3(0.5, 0.5, 0.5), 0.2)
		
	print("Dodge Started!")

func end_dodge():
	is_dodging = false
	invulnerable = false
	dodge_cooldown_timer = dodge_cooldown
	print("Dodge Ended")

func use_skill():
	# Placeholder Skill: Healing Pulse
	print("Used Skill: Repair Pulse")
	health = min(health + 10, max_health)
	skill_timer = skill_cooldown
	
	# Visual
	var mesh = get_node_or_null("VisualModel")
	if mesh:
		var tween = create_tween()
		tween.tween_property(mesh, "scale", Vector3(0.6, 0.6, 0.6), 0.1)
		tween.tween_property(mesh, "scale", Vector3(0.5, 0.5, 0.5), 0.2)

func handle_movement(delta):
	# ... (Movement logic remains, just ensuring no conflicts)
	# Copied for context
	var camera = get_viewport().get_camera_3d()
	var direction = Vector3.ZERO
	
	if camera:
		var cam_basis = camera.global_transform.basis
		var forward = cam_basis.z
		var right = cam_basis.x
		forward.y = 0
		right.y = 0
		forward = forward.normalized()
		right = right.normalized()
		direction = (right * input_vector.x + forward * input_vector.y).normalized()
	else:
		direction = Vector3(input_vector.x, 0, input_vector.y).normalized()
	
	if is_dodging:
		var dodge_mult = 2.0
		if direction != Vector3.ZERO:
			velocity = direction * max_speed * dodge_mult
		else:
			var forward = -transform.basis.z
			velocity = forward * max_speed * dodge_mult
		move_and_slide()
		return
		
	# Block Movement Penalty
	var current_speed_mult = 1.0
	if is_blocking:
		current_speed_mult = 0.5 # Slow down while blocking/parrying
	
	if direction != Vector3.ZERO:
		velocity.x = move_toward(velocity.x, direction.x * max_speed * current_speed_mult, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * max_speed * current_speed_mult, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0, deceleration * delta)
		
	# Banking Visuals
	var mesh = get_node_or_null("VisualModel")
	if mesh:
		var move_ref = direction
		if move_ref == Vector3.ZERO and velocity.length() > 0.1:
			move_ref = velocity.normalized()
		var local_move = global_transform.basis.inverse() * move_ref
		var target_tilt_z = -local_move.x * 0.4
		var target_tilt_x = local_move.z * 0.4
		
		# Blocking visuals: Tilt up?
		if is_blocking:
			target_tilt_x = -0.2 # Nose up slightly
			
		mesh.rotation.z = lerp_angle(mesh.rotation.z, target_tilt_z, delta * 5.0)
		mesh.rotation.x = lerp_angle(mesh.rotation.x, target_tilt_x, delta * 5.0)
	
	move_and_slide()

	# Constrain Height
	if abs(global_position.y - 1.0) > 0.05:
		global_position.y = move_toward(global_position.y, 1.0, 10.0 * delta)
	velocity.y = 0

# ...

func take_damage(amount: float, source_pos: Vector3 = Vector3.ZERO):
	if invulnerable:
		return
		
	# Check for Directional Block
	if can_block_damage(source_pos):
		# Parry logic is primarily handled by the PROJECTILE collision event returning early.
		# If we are here, it means either:
		# 1. Not a projectile (hitscan/AOE)
		# 2. Parry window missed, but block is active.
		
		# Regular Block Reduction
		amount *= 0.5
		print("Blocked! Damage reduced to ", amount)
		
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
			if primary_weapon:
				primary_weapon.rotation.y = clamp(angle_diff, -cone_half, cone_half)
			if secondary_weapon:
				secondary_weapon.rotation.y = clamp(angle_diff, -cone_half, cone_half)
			
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
		if primary_weapon:
			primary_weapon.rotation.y = lerp_angle(primary_weapon.rotation.y, 0, delta * 5.0)
		if secondary_weapon:
			secondary_weapon.rotation.y = lerp_angle(secondary_weapon.rotation.y, 0, delta * 5.0)

func handle_combat(_delta):
	# Primary Slot -> Linked to Primary Fire (Left Click)
	if primary_weapon and Input.is_action_pressed("fire_primary"):
		primary_weapon.attempt_fire(true) 
		
	# Secondary Slot -> Linked to Secondary Fire (Right Click)
	# Triggers the weapon's "Secondary" mode (false) because it's in the secondary slot.
	if secondary_weapon and Input.is_action_pressed("fire_secondary"):
		secondary_weapon.attempt_fire(false)

	if shield_visual:
		shield_visual.visible = is_blocking
			
func setup_visuals():
	# Load actual Mesh
	var heli_scene = load("res://assets/heli/Military_Helicopter02.fbx")
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
	
	_setup_shield_visual()
	
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

var shield_visual: Node3D = null

func _setup_shield_visual():
	# Procedural Curved Arc Mesh
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Shield Params
	var radius = 2.5
	var height = 2.0
	var arc_angle = 140.0 # Wide arc
	var segments = 16
	
	var half_height = height / 2.0
	
	for i in range(segments + 1):
		var t = float(i) / segments
		var angle_deg = -arc_angle/2.0 + (t * arc_angle)
		var angle_rad = deg_to_rad(angle_deg)
		
		# Normal points INWARDS or OUTWARDS? Shield usually faces out.
		# For -Z forward, 0 degrees is -Z.
		# cos(0) = 1, sin(0) = 0.
		# We want semi-circle around -Z.
		# x = sin(angle), z = -cos(angle)
		
		var x = radius * sin(angle_rad)
		var z = -radius * cos(angle_rad) # Forward is -Z
		
		# UVs
		var u = t
		
		# Top Vertex
		st.set_uv(Vector2(u, 0.0))
		st.set_normal(Vector3(sin(angle_rad), 0, -cos(angle_rad)))
		st.add_vertex(Vector3(x, half_height, z))
		
		# Bottom Vertex
		st.set_uv(Vector2(u, 1.0))
		st.set_normal(Vector3(sin(angle_rad), 0, -cos(angle_rad)))
		st.add_vertex(Vector3(x, -half_height, z))
		
	# Indices
	for i in range(segments):
		var base = i * 2
		# Quad: base, base+1, base+2, base+3
		# Tri 1: base, base+3, base+2 (TopL, BotR, TopR)
		# Tri 2: base, base+1, base+3 (TopL, BotL, BotR)
		# Verify winding order... simple strip logic:
		# 0(T)-1(B)-2(T)-3(B)
		# 0-2-1, 1-2-3
		
		st.add_index(base)
		st.add_index(base + 2)
		st.add_index(base + 1)
		
		st.add_index(base + 1)
		st.add_index(base + 2)
		st.add_index(base + 3)
		
	var mesh = st.commit()
	
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.mesh = mesh
	mesh_inst.name = "ShieldVisual"
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.6, 1.0, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.6, 1.0)
	mat.emission_energy_multiplier = 2.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED # Double Sided visual
	
	mesh_inst.set_surface_override_material(0, mat)
	
	var visual_model = get_node_or_null("VisualModel")
	if visual_model:
		visual_model.add_child(mesh_inst)
		# Mesh generated around origin (0,0,0) with forward arc.
		# Just pull it forward slightly if needed, or leave at pivot?
		# Radius 2.5 is already pushed out, but origin is pivot.
		# Pivot is likely center of heli.
		# So mesh vertices are physically at Z = -2.5.
		# No extra position offset needed if radius is correct.
		mesh_inst.position = Vector3(0, 0.5, 0.8) 
		mesh_inst.rotation_degrees.y = 180 # Flip to face forward (relative to VisualModel which is 180)
		mesh_inst.scale = Vector3(1,1,1)
		
	shield_visual = mesh_inst
	shield_visual.visible = false

func attempt_parry(attacker_pos: Vector3 = Vector3.ZERO) -> bool:
	if not is_blocking: 
		return false
		
	# Directional Block Check (120 degrees = dot product > 0.5)
	if attacker_pos != Vector3.ZERO:
		var dir_to_attacker = (attacker_pos - global_position).normalized()
		# Forward is -Z relative to global transform usually, but let's verify visual model rotation.
		# VisualModel is Y-180 rotated, so its local +Z is model Forward.
		# But global_transform.basis.z is Player's backward vector (Godot standard).
		# So Player's forward is -basis.z.
		var forward = -global_transform.basis.z 
		
		# If blocking, we face the cursor/target.
		# Dot product: 1.0 (dead front), 0.5 (60 deg side), 0 (90 deg side)
		if dir_to_attacker.dot(forward) < 0.5:
			return false # Hit from side or back, Shield ignored.

	if block_timer <= parry_window:
		print("PARRY SUCCESS!")
		# Visual Feedback
		if shield_visual:
			var base_scale = Vector3(1.0, 1.0, 1.0) # Procedural mesh is pre-sized
			var pop_scale = base_scale * 1.2
			
			var tween = create_tween()
			tween.tween_property(shield_visual, "scale", pop_scale, 0.1)
			tween.tween_property(shield_visual, "scale", base_scale, 0.1)
		return true
	return false

func can_block_damage(source_pos: Vector3) -> bool:
	if not is_blocking: return false
	if source_pos == Vector3.ZERO: return true # Unknown source, assume blockable if active? Or unblockable? Usually unblockable (environmental). Let's be generous.
	
	var dir_to_attacker = (source_pos - global_position).normalized()
	var forward = -global_transform.basis.z 
	return dir_to_attacker.dot(forward) >= 0.5

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

func collect_loot(type: int, amount: float):
	match type:
		0: # SCRAP
			var int_amount = int(amount)
			scraps += int_amount
			print("Collected ", int_amount, " scraps. Total: ", scraps)
			# Check for upgrades?
		1: # INTEL
			var int_amount = int(amount)
			intel += int_amount
			print("Collected ", int_amount, " intel.")
