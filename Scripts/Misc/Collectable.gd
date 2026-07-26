extends RigidBody3D
class_name Collectable

@export var value: int = 1
var isQueued := false

var isShipDeposit : bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not isShipDeposit: E.Register(self, E.Collectible)
	self.scale = 0.1 * value * Vector3.ONE
	self.mass = 0.7 * value

## Marks Crystal as deposit, will be ignored by collectors.
## Run BEFORE adding to scene.
func markDeposit():
	isShipDeposit = true

## Returns False if already queued, otherwise True
func Queue() -> bool:
	if isQueued: return false
	isQueued = true
	E.UnRegister(self, E.Collectible)
	return true

func Collect() -> int:
	self.process_mode = Node.PROCESS_MODE_DISABLED
	return value

func Collected(): queue_free()

func _physics_process(delta: float) -> void:
	if abs(self.global_position.y) > 6.:
		self.apply_impulse(Vector3(0, -self.global_position.y/4, 0))
