extends Node3D



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if has_node("Boom Particles"):
		$"Boom Particles".one_shot = true
		$"Boom Particles".restart()
	else: 
		$"AudioStreamPlayer3D".finished.connect(_on_boom_spikes_finished)
	$"Boom Spikes".one_shot = true
	$"Boom Spikes".restart()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func Mute():
	#$"AudioStreamPlayer3D".volume_linear = 0
	$"AudioStreamPlayer3D".queue_free()
	$"Boom Spikes".finished.connect(_on_boom_spikes_finished)
	

func _on_boom_spikes_finished() -> void:
	queue_free()

func _on_boom_particles_finished() -> void:
	queue_free()
	
