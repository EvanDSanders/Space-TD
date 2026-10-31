extends ShipDecorator
class_name DecoratorFighter

var TRot : Vector3
var TThrustR : float
var TThrustL : float

var CRot : Vector3
var CThrustR : float
var CThrustL : float

#func ThrustF(engine:MeshInstance3D, str:float):
	#engine.set_instance_shader_parameter("ThrustF", str)
	##Nav.debug.drawString(Nav.global_position, Vector2(-30, 0), str(str))
	#
	#
#func ThrustR(engine:MeshInstance3D, str:float):
	#engine.set_instance_shader_parameter("ThrustR", str)
	##Nav.debug.drawString(Nav.global_position, Vector2(30, 30), str(str))
	#
#func Thrust(engine:MeshInstance3D, str:float):
	#if str > 0:
		#ThrustF(engine, str / 2.5)
		#ThrustR(engine, 0)
	#else:
		#ThrustR(engine, -str / 2.5)
		#ThrustF(engine, 0)
		#

static var lerpers : Array[PropLerp] = [
	PropLerp.new(^"TRot:x", ^"CRot:x", 8),
	PropLerp.new(^"TRot:y", ^"CRot:y", 8),
	PropLerp.new(^"TRot:z", ^"CRot:z", 8),
	PropLerp.new(^"TThrustR", ^"CThrustR", 0.6),
	PropLerp.new(^"TThrustL", ^"CThrustL", 0.6),
]

func ready() -> void: pass
func proc(choice: ShipControllerBase.AIChoice) -> void:
	var L = Parent.EngineL
	var R = Parent.EngineR
	
	var dir = choice.Thrust.normalized() * 200
	
	var flip = ( 1 if dir.z <= 1 else -1 )
	
	var thrust : float = (
		-choice.Thrust.z / 100 +
		abs( choice.Thrust.y ) * flip / 100 +
		abs( choice.Thrust.x ) * flip / 100 
	)
	
	TThrustR = thrust / 1.6 + choice.Rotation.y / 500
	TThrustL = thrust / 1.6 - choice.Rotation.y / 500

	TRot = Vector3(
		#dir.y / 2
		choice.Thrust.y / 2
		,
		-dir.x / 5 * flip
		#-choice.Thrust.x / 5 
		, 0
	) * clamp(choice.Thrust.length() / 10, 0, 1)
	
	
	
	PropLerp.excAll(lerpers, self)
	
	L.Thrust(CThrustR)
	R.Thrust(CThrustL)
	
	L.rotation_degrees = CRot
	R.rotation_degrees = L.rotation_degrees
	
