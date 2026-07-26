extends GPUParticles3D

class_name GPUParticles3DFix

@onready var last_global_position := global_position

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_process_internal(false)
	set_physics_process_internal(false)


func _physics_process(delta : float) -> void:
	RenderingServer.particles_set_emitter_velocity(get_base(), (global_position - last_global_position) / delta)
	last_global_position = global_position
