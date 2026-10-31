@icon ("res://EditorIcons/crystals.svg")
extends Node
class_name CrystalStore

@export var Crystals := 0.
@export var CrystalsMax := -1
@export var HardLimit := false

signal CrystalsChange(int)

var Meter : MeterPin
@onready var Parent = $".."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Meter = Pins.Register(Parent)
	Meter.setColor(Color.from_hsv(0.751, 1.0, 1.0, 1.0), Color.from_hsv(0.748, 1.0, 0.2, 1.0))
	Meter.name = "CrystalMeterPin"
	Meter.VOffset = 6
	Meter.max = CrystalsMax
	Meter.value = Crystals
	CrystalsChange.connect(func(c): Meter.value = c)
	
	if Parent.has_node("CursorDialogue"):
		Parent.get_node("CursorDialogue").attachMeter(Meter)

func pullCrystal(charge: int) -> bool:
	if charge > Crystals: return false
	Crystals -= charge
	CrystalsChange.emit(Crystals)
	return true;

func pushCrystal(amt: int):
	Crystals += amt
	if amt > 0:
		CrystalsChange.emit(Crystals)
	




# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
