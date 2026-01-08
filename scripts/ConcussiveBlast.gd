extends Node3D

func _ready():
	$GPUParticles3D.emitting = true
	# Wait for lifetime + a bit
	get_tree().create_timer(1.0).timeout.connect(queue_free)
