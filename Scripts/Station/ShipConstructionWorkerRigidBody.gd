extends RigidBody2D
class_name ShipConstructionWorkerRigidBody


static func fabricate() -> ShipConstructionWorkerRigidBody:
	return preload("res://Scenes/GUI/Station/ShipConstructionWorkerBody.tscn").instantiate()

func setUp(pos: Vector2, size: Vector2):
	self.global_position = pos
	$CollisionShape2D.shape.size = size


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

signal exited
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	self.queue_free()
	exited.emit()
