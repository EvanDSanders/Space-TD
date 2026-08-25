extends Node
#extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


enum Type {Meter, Dial, Text}

const TypeDefs := [
	"res://Scenes/GUI/Pins/MeterPin.tscn",
	"res://Scenes/GUI/Pins/DialPin.tscn",
	"res://Scenes/GUI/Pins/TextPin.tscn",
]

func Clear():
	for each in get_children():
		each.queue_free()

func Register(mount:Node3D, type := Type.Meter) -> ScreenPin:
	var pin := load(TypeDefs[type]).instantiate() as ScreenPin
	pin.parent = mount
	self.add_child(pin)
	return pin
