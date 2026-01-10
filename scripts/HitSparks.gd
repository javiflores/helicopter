extends GPUParticles3D

func _ready():
	emitting = true
	# Wait for lifetime then destroy
	get_tree().create_timer(lifetime + 0.1).timeout.connect(queue_free)
