@icon("res://EditorIcons/cursorDialogue.svg")
extends Node
class_name CursorDialogue

@onready var Parent = $".."

@onready var radarRange
@export var doShowRange = true

var scanRangeGUI = preload("res://Scenes/GUI/ScanRange.tscn")
var scanRange : MeshInstance3D

func enter():
	for each in Parent.get_children():
		if each.get("Meter") and each.get("showMeter"):
			each.Meter.forceShow(true)
		
		if each.has_meta("isMinerMeter") and each.get_meta("isMinerMeter"):
			each.forceShow(true)
	
	
	if not doShowRange: return
	if Parent.get("TargetingRange"): 
		radarRange = Parent.TargetingRange
	
	scanRange = scanRangeGUI.instantiate()
	scanRange.set_instance_shader_parameter("Range", radarRange)
	Parent.add_child(scanRange)
	

func exit():
	if scanRange: scanRange.queue_free()
	
	for each in Parent.get_children():
		if each.get("Meter") and each.get("showMeter"):
			each.Meter.forceShow(false)
	
		if each.has_meta("isMinerMeter") and each.get_meta("isMinerMeter"):
			each.forceShow(false)



func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
