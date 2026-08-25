#@icon ("res://EditorIcons/EnergyStore.svg")
extends Node
class_name EnergyStore

@onready var Parent = $".."
#@onready var Meter : Control = preload("res://Scenes/GUI/Waypoint.tscn").instantiate()
var Meter : MeterPin



signal EnergyChange(float)
@export var EnergyMax := 500.
@export var color := Color.ROYAL_BLUE

@onready var Energy := EnergyMax
@onready var priorEnergy := Energy
@export var showMeter := true

@export var generationRate : float = 0

@export var MaxLinks = 1
@export var isPylon = false


func _ready() -> void: call_deferred("ready")
func ready() -> void:
	Meter = Pins.Register(Parent)
	Meter.setColor(Color.from_hsv(0.167, 1.0, 1.0, 1.0), Color.from_hsv(0.15, 1.0, 0.2, 1.0))
	Meter.name = "EnergyMeterPin"
	Meter.VOffset = 8
	Meter.max = EnergyMax
	Meter.value = Energy
	
	if Parent.has_node("CursorDialogue"):
		Parent.get_node("CursorDialogue").attachMeter(Meter)
	
	EnergyChange.connect(func(): Meter.value = Energy)
	
	
func pullEnergy(charge: float) -> float:
	charge = clampf(charge, 0, Energy)
	Energy -= charge
	if Meter and showMeter: Meter.value = Energy
	return charge

func pushEnergy(amt: float):
	Energy += amt
	Energy = clampf(Energy, 0, EnergyMax)
	if Meter and showMeter: Meter.value = Energy
	
	
func _physics_process(delta: float) -> void:
	pushEnergy(delta * generationRate)

## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	if priorEnergy != Energy:
		priorEnergy = Energy
		EnergyChange.emit(Energy)
