@icon("res://EditorIcons/spaceTrail.svg")
extends GeometryInstance3D
class_name SpaceTrail



var ID := 0

#
#class spaceNode:
	#var ID : int
	#var pos : Vector3
	#var vel : Vector3
	#var age : int
	#var life := 40
	#
	#func _init(Velocity:Vector3) -> void:
		#ID = self.ID
		#pos = self.global_position
		#vel = Velocity
		#self.ID += 1;
		#
	#
	#func tick():
		#age += 1
		#if age > life: self.queue_free()
		#print(ID)
		#
#



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	_tick(delta)



func _tick(_delta:float)->void:
	pass
