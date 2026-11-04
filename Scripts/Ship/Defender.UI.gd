extends Control

@onready var TexR: TextureRect = $TextureRect
@onready var Cont: PanelContainer = $TextureRect/SubViewport2/SubViewport/PanelContainer
@onready var Meter: ProgressBar = $TextureRect/SubViewport2/SubViewport/PanelContainer/HBoxContainer/ProgressBar
@onready var Dbg: Label = $Label

var fuel := 100.0
var maxFuel := 100.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	Meter.custom_maximum_size.x = Cont.size.x * ( maxFuel / 100 )
	Meter.custom_minimum_size.x = Cont.size.x * ( maxFuel / 100 )
	Meter.max_value = maxFuel
	Meter.value = fuel
	Dbg.text = "%f %f" % [fuel, maxFuel]

func useEnergy(amt:float):
	var output = clamp( amt, 0, fuel )
	fuel -= output
	maxFuel -= clamp( output, 0, 100.0 ) * .2
	
	return output
	
func regenEnergy(amt:float):
	fuel = clamp(fuel + amt, 0, maxFuel)
	
var coolDown := 0.

func _physics_process(delta: float) -> void:
	if Input.get_action_strength("Up"):
		useEnergy( 0.8 )
		coolDown = 1.0
	else:
		coolDown -= delta
		if coolDown < 0:
			regenEnergy( 0.3 )
		
	
