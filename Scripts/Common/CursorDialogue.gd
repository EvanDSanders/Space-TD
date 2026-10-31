@icon("res://EditorIcons/cursorDialogue.svg")
extends Node
class_name CursorDialogue

@onready var Parent = $".."

@export var radarRange : int
@export var doShowRange = true

var scanRangeGUI = preload("res://Scenes/GUI/ScanRange.tscn")
var scanRange : MeshInstance3D

signal focused(bool)
signal clicked()

func attachMeter(meter: ScreenPin):
	focused.connect(meter.forceShow)
	clicked.connect(meter.clicked)

func enter():
	focused.emit(true)
	
	if not doShowRange: return
	if Parent.get("TargetingRange"): 
		radarRange = Parent.TargetingRange
	
	scanRange = scanRangeGUI.instantiate()
	scanRange.set_instance_shader_parameter("Range", radarRange)
	Parent.add_child(scanRange)
	

func exit():
	focused.emit(false)
	
	if scanRange: scanRange.queue_free()
	
	for each in Parent.get_children():
		if each.get("Meter") and each.get("showMeter"):
			each.Meter.forceShow(false)
	
		if each.has_meta("isMinerMeter") and each.get_meta("isMinerMeter"):
			each.forceShow(false)


func _unhandled_input_pass(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		Pins.otherClicked.emit()
		clicked.emit()
		get_viewport().set_input_as_handled()
		
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		G.camera.setFollow(Parent)
		if Parent.Nav.Controllable:
			Parent.Nav.ControlStart()


func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
