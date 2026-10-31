extends Node3D
class_name StationShipEngine

@onready var back: MeshInstance3D = $"StationShip Engine/Origin ShipThrusterBase/ShipThrusterBack"
@onready var front: MeshInstance3D = $"StationShip Engine/Origin ShipThrusterBase/ShipThrusterFront"
@onready var hull: MeshInstance3D = $"StationShip Engine/Origin ShipThrusterBase"

@onready var trailR: VaporTrail = $"VaporTrail R"
@onready var trailF: VaporTrail = $"VaporTrail F"

class TrailColorizer:
	pass
	
func _ready() -> void:
	print( trailR.get_children(true) )


func ThrustF(str:float):
	back.set_instance_shader_parameter("Thrust", str)
	trailR.set("visual/size", str * 2)
	
func ThrustR(str:float):
	front.set_instance_shader_parameter("Thrust", str)
	trailF.set("visual/size", str * 2)
	
	
func Thrust(str:float):
	if str > 0:
		ThrustF(str / 2.5)
		ThrustR(0)
	else:
		ThrustR(-str / 2.5)
		ThrustF(0)
