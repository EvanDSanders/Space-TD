extends GPUParticles3DFix


@export var health : Destructible
@export var threshhold : float = 0.8

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	health.HPChange.connect(self.update)

func update(HP: float):
	self.emitting = HP/health.HPMax < threshhold
