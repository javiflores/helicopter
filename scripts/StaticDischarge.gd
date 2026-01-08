extends Area3D

var max_radius: float = 10.0
var expansion_speed: float = 20.0
var stun_duration: float = 2.0
var current_radius: float = 0.5

var expanding: bool = true
var lifetime: float = 1.0 # Safety fallback to cleanup

func _ready():
	collision_mask = 4 # Enemies layer
	collision_layer = 0 # Don't be hit by things
	
	# Initial scale
	update_radius_visuals()
	
	# Connect signal
	body_entered.connect(_on_body_entered)

func configure(rad: float, dur: float):
	max_radius = rad
	stun_duration = dur

func _process(delta):
	if expanding:
		current_radius += expansion_speed * delta
		if current_radius >= max_radius:
			current_radius = max_radius
			expanding = false
	else:
		# Contracting
		current_radius -= expansion_speed * delta
		if current_radius <= 0.5:
			queue_free()
	
	update_radius_visuals()
	
	# Update collision shape
	$CollisionShape3D.shape.radius = current_radius

func update_radius_visuals():
	var mesh_inst = $RingMesh
	if mesh_inst and mesh_inst.mesh is TorusMesh:
		mesh_inst.mesh.outer_radius = current_radius
		mesh_inst.mesh.inner_radius = max(0.1, current_radius - 0.5)

func _on_body_entered(body):
	if body.has_method("apply_stun"):
		body.apply_stun(stun_duration)
