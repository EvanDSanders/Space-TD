extends Node3D



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if has_node("Boom Particles"):
		$"Boom Particles".one_shot = true
		$"Boom Particles".restart()
		$"Boom Particles".finished.connect(queue_free)
	else: 
		#$"AudioStreamPlayer3D".finished.connect(_on_boom_spikes_finished)
		$"Boom Spikes".finished.connect(queue_free)
	$"Boom Spikes".one_shot = true
	$"Boom Spikes".restart()
	
