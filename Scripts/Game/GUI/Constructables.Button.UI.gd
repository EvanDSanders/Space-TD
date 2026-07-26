extends Button
class_name ConstructableButton

var loadingScene : String
var buildingScene : String
var data : Dictionary
var Parent : Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	G.StarShip.crystal.CrystalsChange.connect(amtCheck)

func amtCheck(amt:int):
	self.disabled = amt < int(data["cost"])
	$TextureRect.modulate = Color.DIM_GRAY if self.disabled else Color.WHITE
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if not loadingScene:
		assert(not loadingScene, "To-Build Structure not given a loadingScene!")
		self.queue_free()
	if not buildingScene:
		assert(not buildingScene, "To-Build Structure not given a buildingScene!")
		self.queue_free()
	
	
func _pressed() -> void:
	Parent.Build( self )
