@abstract
extends Resource
class_name ShipControllerBase


var Parent : ShipBase
var Nav : ShipNavigator

var isAbsolute : bool = false
var target: Vector3

class AIChoice:
	var Rotation: Vector3
	var Thrust: Vector3
	func _init(rotation:=Vector3.ZERO, thrust:=Vector3.ZERO) -> void:
		Rotation = rotation
		Thrust = thrust

	func add(other: AIChoice) -> AIChoice:
		return AIChoice.new(Rotation + other.Rotation, Thrust + other.Thrust)
		
	func charge() -> float:
		return ( 
			clamp(abs(Thrust.x), 0, 1000) + 
			clamp(abs(Thrust.y), 0, 1000) + 
			clamp(abs(Thrust.z), 0, 1000) +
			clamp(abs(Rotation.x), 0, 1000) + 
			clamp(abs(Rotation.y), 0, 1000) + 
			clamp(abs(Rotation.z), 0, 1000)
		) / 6 / 1000


@abstract func ready() -> void
@abstract func proc(delta: float) -> AIChoice

func isCharging() -> bool:
	if Parent:
		var charging = Parent is StationShip and Parent.State == StationShip.SysState.Parked
		return charging
	return false
	
func PD(error:float, velocity:float, P:float, D:float) -> float:
	return (error * P - velocity * D) # * Parent.mass


func Turn(torque: Vector3) -> Vector3:
	Parent.apply_torque(Parent.global_transform.basis * torque)
	return torque

func TurnWorld(torque: Vector3) -> Vector3:
	Parent.apply_torque(torque)
	return Parent.global_transform.basis.inverse() * torque

func Thrust(force: Vector3, pos: Vector3 = Vector3.ZERO) -> Vector3:
	Parent.apply_central_force(Parent.global_transform.basis * force)
	return force

func ThrustLocked(force: Vector3, pos: Vector3 = Vector3.ZERO) -> Vector3:
	var yaw := Parent.rotation.y
	var world_force := Vector3(force.x, 0.0, force.z).rotated(Vector3.UP, yaw)
	world_force.y = force.y
	Parent.apply_central_force(world_force)
	return Parent.global_transform.basis.inverse() * world_force
