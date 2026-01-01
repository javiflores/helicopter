extends Area3D

enum PickupType { SCRAP, INTEL, HEALTH }
@export var type: PickupType = PickupType.SCRAP
@export var amount: float = 1.0

func _ready():
	setup_visuals()
	# Bobbing animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property($MeshInstance3D, "position:y", 0.5, 1.0).as_relative().set_trans(Tween.TRANS_SINE)
	tween.tween_property($MeshInstance3D, "position:y", -0.5, 1.0).as_relative().set_trans(Tween.TRANS_SINE)
	
	# Monitor Player Layer (2)
	collision_mask = 2
	body_entered.connect(_on_body_entered)

func setup_visuals():
	var color = Color.GOLD # Scrap
	match type:
		PickupType.INTEL: color = Color.CYAN
		PickupType.HEALTH: color = Color.GREEN
		
	var mesh = $MeshInstance3D
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.set_surface_override_material(0, mat)

func _on_body_entered(body):
	print("Pickup entered by: ", body.name)
	if body.is_in_group("player"):
		print("Body is player")
		if body.has_method("collect_loot"):
			body.collect_loot(type, amount)
			queue_free()
