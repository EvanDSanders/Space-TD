extends ShipControllerBase
class_name ShipUpCorrector

func ready() -> void: pass


@export var P : int = 300
@export var D : int = 100

@export var doCorrectPitch := true


func proc(delta: float):
	if isCharging(): return AIChoice.new()
	
	#return AIChoice.new()
	return AIChoice.new(TurnWorld(Vector3( 
				PD(
					Parent.global_transform.basis.y.cross(Vector3.UP).x, 
					Parent.angular_velocity.x, 
					P,
					D, 
				) * Parent.mass if doCorrectPitch else 0., 
				0,
				PD(
					Parent.global_transform.basis.y.cross(Vector3.UP).z, 
					Parent.angular_velocity.z, 
					P,
					D, 
				) * Parent.mass
			))
		)
