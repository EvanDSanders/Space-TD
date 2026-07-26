extends Area3D
class_name ScanArea3D

@export var scanFor : E.TargetType = E.Enemy


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for shape : CollisionShape3D in self.find_children("*", "CollisionShape3D"):
		shape.debug_fill = false
		shape.debug_color = Color.TRANSPARENT * 0.8 + shape.debug_color * 0.2


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func scanList():
	return self.get_overlapping_bodies()
