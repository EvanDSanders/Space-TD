extends StructureBase3D

@onready var cube: MeshInstance3D = $"Pylon/Origin Pylon"
@onready var shell: Node3D = $"Pylon/Pylon Shell Base"
@onready var bottom: MeshInstance3D = $"Pylon/Pylon Shell Base/Pylon Shell B"
@onready var top: MeshInstance3D = $"Pylon/Pylon Shell Base/Pylon Shell T"
@onready var focusMount: Node3D = $"Pylon/Origin Pylon/Focus Mount"

var cycle : float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	cube.rotation_degrees.y += delta * 40
	shell.rotation_degrees.y = -cube.rotation_degrees.y
	focusMount.rotation_degrees.x += delta * 35
	cycle += delta
	cube.position.y = cos(cycle)/2
	bottom.position = Vector3(1, -1, -1) * ( ( 3 + sin(cycle) ) / 3 )
	top.position = -Vector3(1, -1, -1) * ( ( 3 + sin(cycle) ) / 3 )
	
