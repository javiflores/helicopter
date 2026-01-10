extends Control

var target_node: Node3D = null
var cam: Camera3D = null

@onready var texture_rect = $TextureRect

func configure(target: Node3D):
	target_node = target
	# Optionally set color based on target type
	
func _process(_delta):
	if not is_instance_valid(target_node):
		queue_free()
		return
		
	if not cam:
		cam = get_viewport().get_camera_3d()
		return

	# Check if target is in front of camera
	var screen_pos = cam.unproject_position(target_node.global_position)
	var is_behind = cam.is_position_behind(target_node.global_position)
	
	var viewport_rect = get_viewport_rect()
	var center = viewport_rect.size / 2.0
	
	# Clamp to screen edges
	var margin = 15.0
	
	if is_behind:
		# If behind, we invert the position relative to center to flip it to the correct edge
		screen_pos = center - (screen_pos - center)
	
	# Clamp vector from center
	var dir = (screen_pos - center).normalized()
	
	# If on screen and not behind, just follow
	if viewport_rect.has_point(screen_pos) and not is_behind:
		global_position = screen_pos - size / 2.0
		rotation = 0 # Or point down? Usually simple markers don't rotate if on target
		modulate.a = 0.5 # Fade out when looking directly at it
	else:
		# Clamp to edge
		var angle = dir.angle()
		var edge_pos = center + dir * (min(viewport_rect.size.x, viewport_rect.size.y) / 2.0 - margin)
		
		# Better rectangle clamping
		var _t = dir * (center - Vector2(margin, margin))
		# (Simplified circular clamp for now, usually good enough for "Compass")
		
		global_position = edge_pos - size / 2.0
		rotation = dir.angle() + PI / 2.0 # Rotate to point outwards
		modulate.a = 1.0
