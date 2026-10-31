extends TurretReaction
class_name TurretReactionSpinner

@export var chargeTime : float = 1
@export var SpinRateMultiplier : float = 0.25

@export var coolDown : float = 0.1
var cd := coolDown

var spinRate: float = 0.:
	set(s):
		spinRate = clamp(s, 0, chargeTime)

func ready() -> void:
	pass
	
func proc(delta: float):
	Parent.Reactor.rotation.z += spinRate * delta * 60 * SpinRateMultiplier
	cd -= delta
	
func procHasTarget(delta: float) -> void:
	spinRate += delta
	proc(delta)
	

func procNoTarget(delta: float) -> void:
	spinRate -= delta / 4
	proc(delta)
	
	
func procFire() -> void:
	cd = coolDown
	pass
	
	
func procIsReady() -> bool:
	return cd <= 0 and is_equal_approx(spinRate, chargeTime)
	
	
