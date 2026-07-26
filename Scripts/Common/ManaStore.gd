@icon ("res://EditorIcons/manaStore.svg")
extends Node
class_name ManaStore

@onready var Parent = $".."
@onready var Meter : Control = preload("res://Scenes/GUI/Waypoint.tscn").instantiate()



signal ManaChange(float)
@export var ManaMax := 500.
@export var color := Color.ROYAL_BLUE

@onready var Mana := ManaMax
@onready var priorMana := Mana
@export var showMeter := true

@export var generationRate : float = 0

@export var MaxLinks = 1
@export var isPylon = false


func _ready() -> void: call_deferred("ready")
func ready() -> void:
	Meter.parent = Parent
	get_tree().root.add_child(Meter)

	Meter.get_child(0).max_value = ManaMax
	Meter.get_child(0).value = Mana
	Meter.get_child(0).position.y -= (10-2)
	Meter.modulate = color
	if showMeter:
		self.ManaChange.connect(Meter.doShow)

func pullMana(charge: float) -> float:
	charge = clampf(charge, 0, Mana)
	Mana -= charge
	Meter.get_child(0).value = Mana
	return charge

func pushMana(amt: float):
	Mana += amt
	Mana = clampf(Mana, 0, ManaMax)
	Meter.get_child(0).value = Mana
	
	
	
func _physics_process(delta: float) -> void:
	pushMana(delta*generationRate)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if priorMana != Mana:
		priorMana = Mana
		ManaChange.emit(Mana)
