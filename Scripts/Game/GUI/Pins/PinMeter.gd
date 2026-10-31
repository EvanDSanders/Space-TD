@icon("res://EditorIcons/pinMeter.svg")
extends ScreenPin
class_name MeterPin

@onready var base: Panel = $Base
@onready var fill: Panel = $Base/Fill

@export var VOffset : int:
	set(v):
		offset_transform_position.y = - v

var oldValue : float = -1

var value : float = 0.0:
	set(_value):
		value = _value
		fill.size.x = remap(value, min, max, 0, base.size.x)
		if oldValue != value:
			oldValue = value
			if isPinBoard: queue_redraw()
			doShow()
		
var max   : float = 1.0:
	set(_max):
		max = _max
		value = value
		
var min   : float = 0.0:
	set(_min):
		min = _min
		value = value
		
var width   : float = 60.0:
	set(_width):
		width = _width
		value = value
		applySize()
		
var height   : float = 2.0:
	set(_height):
		height = _height
		value = value
		applySize()

func applySize(): 
	base.custom_minimum_size = Vector2(width, height)
	base.custom_maximum_size = Vector2(width, height)
	value = value

const TrackableProps = [
		^":min",
		^":max",
		^":value",
	]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	applySize()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super(delta)

func _draw() -> void:
	if isPinBoard:
		draw_string(self.get_theme_default_font(), Vector2(-180, 6), "%d%%" % G.remap(min, max, 0, 100, value), 0, -1, 16, fill.self_modulate * 0.8 + base.self_modulate * 0.2)

func setColor(
		Foreground : Color,
		Background := Color.from_hsv(0.0, 0.0, 0.1, 1.0)
	):
		
	fill.self_modulate = Foreground
	base.self_modulate = Background
