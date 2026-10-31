extends TurretReaction
class_name TurretReactionRecoil

@export var coolDown : float = 0.1
var cd := coolDown
@export var PushDistance : float = 0.1

var startPos : float
func ready() -> void:
	startPos = Parent.Reactor.position.z
	
	
func proc(_delta: float):
	Parent.Reactor.position.z = G.remap( 0, coolDown, startPos, startPos + PushDistance, clamp(cd, 0, coolDown) )
	cd -= _delta
	
func procHasTarget(_delta: float) -> void:
	proc(_delta)
	
	
func procNoTarget(_delta: float) -> void:
	proc(_delta)
	
	
func procFire() -> void:
	cd = coolDown
	
	
func procIsReady() -> bool:
	return cd <= 0
	
	
