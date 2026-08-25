@icon ("res://EditorIcons/crystals.svg")
extends Node
class_name CrystalStore

@export var Crystals := 0.
@export var CrystalsMax := -1
@export var HardLimit := false

signal CrystalsChange(int)



func pullCrystal(charge: int) -> bool:
	if charge > Crystals: return false
	Crystals -= charge
	CrystalsChange.emit(Crystals)
	return true;

func pushCrystal(amt: int):
	Crystals += amt
	if amt > 0:
		CrystalsChange.emit(Crystals)
	


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
