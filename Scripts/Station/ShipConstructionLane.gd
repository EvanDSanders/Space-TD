extends PanelContainer
class_name ShipConstructionLane

@onready var Slot: ReferenceRect = $MarginContainer/HBoxContainer/ReferenceRect

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func hasWorker() -> bool:
	return is_instance_valid(Slot.get_node_or_null("ShipConstructionWorker"))



func attach(wrkr: ShipConstructionWorker) -> bool:
	if Slot.get_node_or_null("ShipConstructionWorker"): 
		print(self.name, " Already has a worker! ", Slot.get_child(0).name)
		return false
	
	Slot.add_child(wrkr)
	return true
