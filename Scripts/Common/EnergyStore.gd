@icon("res://EditorIcons/energyStore.svg")
extends FuelStoreBase
class_name EnergyStore

@onready var Parent = $".."
#@onready var Meter : Control = preload("res://Scenes/GUI/Waypoint.tscn").instantiate()
var Meter : MeterPin



signal EnergyChange(float)
@export var EnergyMax := 500.

var Energy : float:
	set(f):
		Energy = f
		fuel = f
		

var priorEnergy : float
@export var showMeter := true

@export var generationRate : float = 0

@export var MaxLinks = 1
@export var isPylon = false


func _ready() -> void:
	fuelMax = EnergyMax
	Energy = EnergyMax
	priorEnergy = Energy
	call_deferred("ready")
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

	if priorEnergy != Energy:
		priorEnergy = Energy
		EnergyChange.emit()


func pullFuel(charge: float) -> float: return pullEnergy(charge)
func pushFuel(amt: float): pushEnergy(amt)
func isFull() -> bool: return Energy >= EnergyMax or is_equal_approx(Energy, EnergyMax)
