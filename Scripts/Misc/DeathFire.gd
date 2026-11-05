extends GPUParticles3D

@export var useRandom := true

var host : Node3D
var rot := Vector3(randfn(0,TAU),randfn(0,TAU),randfn(0,TAU))

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.host = self.get_parent_node_3d()
	self.reparent(G.Main)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	if emitting and host and useRandom:
		self.global_transform = host.global_transform
		self.rotation += rot
	
		
	elif emitting:
		emitting = false
		self.finished.connect(func(): queue_free)
