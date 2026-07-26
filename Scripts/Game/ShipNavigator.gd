@icon("res://EditorIcons/shipNavigator.svg")
extends Node3D
class_name ShipNavigator

@onready var TickID : int = randi_range(0, 20)
@export var TargType : E.TargetType = E.TargetType.Friend
@export var Parent : RigidBody3D
var Target : Node3D

@export var Distance : int = 50

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.



	
func Turn(torque: Vector3) -> void:
	Parent.apply_torque(Parent.global_transform.basis * torque)

func Thrust(force: Vector3, pos: Vector3 = Vector3.ZERO) -> void:
	Parent.apply_central_force(Parent.global_transform.basis * force)

func ThrustLocked(force: Vector3, pos: Vector3 = Vector3.ZERO) -> void:
	var yaw := Parent.rotation.y
	var world_force := Vector3(force.x, 0.0, force.z).rotated(Vector3.UP, yaw)
	world_force.y = force.y
	Parent.apply_central_force(world_force)
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if not Parent.health.isAlive: return
	
	var hasTarg : bool = is_instance_valid(Target)
	var target : Node3D
	if hasTarg:
		target = Target
	else:
		target = Parent
	
	
	var dir := self.global_transform.origin - target.global_transform.origin
	var dot := dir.normalized().dot(self.global_transform.basis.z)
	
	var heading : float = atan2(dir.x, dir.z)
	
	Turn(Vector3( 0, angle_difference(global_rotation.y, heading) * 40 * Parent.mass, 0 ))
	
	
	var forward : float = 0.
	var lift : float = 0.
	var strafe : float = 0.
	
	match TargType:
		E.Friend, E.Enemy:
			
			if hasTarg and dot > 0.5:
			
				if Parent.global_position.distance_to(target.global_position) >  50:
					forward = -(dot-.5) * 40
				elif Parent.global_position.distance_to(target.global_position) < 30:
					forward = - -(dot-.5) * 40
				else: 
					strafe = 10
				
			lift = 10 - Parent.global_position.y
			
			
		E.Collectible:
			if dot > 0.5:
				forward = -(dot-.5) * 40 * 5
				
			if Parent.global_position.distance_to(target.global_position) >  50:
				lift = 15 - Parent.global_position.y
			else:
				lift  = target.global_position.y - Parent.global_position.y
			
				
	ThrustLocked(Vector3(strafe, lift, forward) * Parent.mass)
	
	if get_node("../DebugPin"):
		$"../DebugPin".get_node("Label").text  = "%f" % Parent.global_position.y 
		
	
