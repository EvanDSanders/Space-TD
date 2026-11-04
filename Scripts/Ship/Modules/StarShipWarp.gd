extends Node
class_name StarShipWarp

var ship: TheStarShip


func setup(p_ship: TheStarShip) -> void:
	ship = p_ship
	set_physics_process(false)


func activate() -> void:
	pass


func deactivate() -> void:
	pass
