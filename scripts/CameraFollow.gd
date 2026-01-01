extends Camera3D

@export var target_path: NodePath
@export var smooth_speed: float = 5.0
@export var offset: Vector3 = Vector3(0, 20, 10)

var target: Node3D = null

func _ready():
	if target_path:
		target = get_node(target_path)
	
	# If no target assigned manually, try to find "Player"
	if not target:
		target = get_parent().get_node_or_null("Player")
		
	if target:
		# Initialize offset based on current positions if we want, or use exported
		# offset = global_position - target.global_position
		pass

func _physics_process(delta):
	if not target: return
	
	var desired_position = target.global_position + offset
	global_position = global_position.lerp(desired_position, smooth_speed * delta)
