extends StructureBase3D


@onready var cells :Array[Node3D]= [
	$"ManaStore2/Origin Mana Store/ManaStore Cell A",
	$"ManaStore2/Origin Mana Store/ManaStore Cell B",
	$"ManaStore2/Origin Mana Store/ManaStore Cell C",
]
@onready var fluids :Array[Node3D]= [
	$"ManaStore2/Origin Mana Store/ManaStore Cell A/ManaStore Fluid A",
	$"ManaStore2/Origin Mana Store/ManaStore Cell B/ManaStore Fluid B",
	$"ManaStore2/Origin Mana Store/ManaStore Cell C/ManaStore Fluid C",
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	for x in range(3):
		cells[x].position.y = sin( x + Time.get_ticks_msec()/1000. ) * 0.2
		var val = G.remap(0, mana.ManaMax, 0, 3, mana.Mana)
		fluids[x].scale.y = G.remap(x, x+1, 0, 1, val)
		
	
	
func _physics_process(delta: float) -> void:
	self.rotation_degrees.y += 1
