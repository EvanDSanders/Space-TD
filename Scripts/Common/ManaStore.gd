@icon ("res://EditorIcons/manaStore.svg")
extends Node
class_name ManaStore

@onready var Parent = $".."
var Meter : MeterPin

## Enables this [ManaStore] to push overflowing generated mana to the network.
@export var pushesOverflow : bool
## Enables the network to extract mana from this [ManaStore].
@export var exportsMana : bool
## Enables this [ManaStore] to recive mana overflow from other nodes.
@export var importsOverflow : bool
## Fill flow for import-export priority for this [ManaStore].[br]
## Lower priority will be filled first, and stores of equal priority will neturalize.
@export var importPriority : int = 0

signal ManaChange(float)
@export var ManaMax := 500.

@onready var Mana := ManaMax
@onready var priorMana := Mana
@export var showMeter := true

@export var generationRate : float = 0

@export var MaxLinks := 1
@export var LinkableRange : int = 30

var DebugText : TextPin
var PoolID : int:
	set(id): 
		PoolID = id
		if DebugText:
			DebugText.text = "%d" % id


func _ready() -> void: # call_deferred("ready")
# func ready() -> void:
	Meter = Pins.Register(Parent)
	Meter.setColor(Color.from_hsv(0.55, 1.0, 1.0, 1.0), Color.from_hsv(0.667, 1.0, 0.2, 1.0))
	Meter.name = "ManaMeterPin"
	Meter.VOffset = 8
	Meter.max = ManaMax
	Meter.value = Mana
	
	if Parent.has_node("CursorDialogue"):
		Parent.get_node("CursorDialogue").attachMeter(Meter)
	
	ManaChange.connect(func(): Meter.value = Mana)
	
	Linker.Register(self)
	
	tree_exiting.connect(Linker.Destroy.bind(self))
	
	DebugText = Pins.Register(Parent, Pins.Type.Text)
	DebugText.setColor(Color.LIGHT_BLUE, Color.DARK_BLUE)
	DebugText.text = "0"
	DebugText.z_index = -5
	DebugText.textSize = 50
	
	
func pullMana(charge: float) -> float:
	charge = clampf(charge, 0, Mana)
	Mana -= charge
	if Meter and showMeter: Meter.value = Mana
	return charge

func pushMana(amt: float):
	Mana += amt
	Mana = clampf(Mana, 0, ManaMax)
	if Meter and showMeter: Meter.value = Mana
	
	
func _physics_process(delta: float) -> void:
	pushMana(delta * generationRate)
	if DebugText: DebugText.forceShow(true)
	
	if priorMana != Mana:
		priorMana = Mana
		ManaChange.emit(Mana)
