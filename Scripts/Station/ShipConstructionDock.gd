extends VBoxContainer
class_name ShipConstructionDock

func isFull() -> bool:
	for each: ShipConstructionLane in get_children():
		if not each.hasWorker():
			return false
	return true

func build(data: Dictionary):
	for each: ShipConstructionLane in get_children():
		if not each.hasWorker():
			each.attach( ShipConstructionWorker.create(data) )
			break



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
