extends SubViewport


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	for layer : Panel in get_children():
		self.size = G.get_viewport().size
		layer.material.set_shader_parameter("Size", G.get_viewport().size)
		
		layer.material.set_shader_parameter("Offset", Vector2( 
				G.Camera.global_position.x,
				G.Camera.global_position.z,
			))
		
	
