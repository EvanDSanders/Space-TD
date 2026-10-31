extends Control
class_name LoadingScreenMain

@onready var Ship: Control = $StarShip
@onready var Meter: = $PanelContainer/Control/VBoxContainer/LoadBar
@onready var Gauge: = $PanelContainer/Control/VBoxContainer/LoadBar/Fill
@onready var Marker: Control = $PanelContainer/Control/VBoxContainer/LoadBar/Marker
@onready var TravelEffect: GPUParticles2D = $Control/GPUParticles2D

@onready var BarEffectMount: Control = $PanelContainer/Control/VBoxContainer/LoadBar/BarEffectMount
@onready var BarEffectHub: Control = $PanelContainer/Control/VBoxContainer/LoadBar/Fill/BarEffectHub
@onready var BarEffect: GPUParticles2D = $PanelContainer/Control/VBoxContainer/LoadBar/Fill/BarEffectHub/BarEffect


var Tw : Tween

var Value : float
var ValuePrior : float
var done : bool = false

@onready var Title: Label = $PanelContainer/Control/VBoxContainer/Title
@onready var Text: Label = $PanelContainer/Control/VBoxContainer/Text
@onready var Info: Label = $PanelContainer/Control/VBoxContainer/Info

func progress(val:float):
	Value = val
	Text.text = "" + str( clamp( round( Value*1000 ) / 10, 0, 100 ) ) + "%"

func task(doing:String):
	Info.text = doing



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	BarEffectHub.global_position = BarEffectMount.global_position
	
	TravelEffect.process_material.emission_shape_scale.y = self.size.y / 2
	TravelEffect.amount = int(self.size.y / 20)
	
	#if randi_range(0, 40) > 39:
		#Value += randf()/5
		#Text.text = "" + str( clamp( round( Value*1000 ) / 10, 0, 100 ) ) + "%"
		
	Ship.global_position.y = Meter.global_position.y + 8
	
	var targ = G.remap(0, 1, Meter.global_position.x + 6, Meter.global_position.x + Meter.size.x - 6, Value)
	if ( Value >= 1. or is_equal_approx(Value, 1.) ) and not done:
		done = true
		targ = self.size.x + 500
		Title.text = "Yay!"
		$"../../..".Complete()
	
	Gauge.size.x = clamp(Ship.global_position.x - Gauge.global_position.x, 0, Meter.size.x)
	Gauge.visible = Gauge.size.x >= 10
	
	delta *= 2
	Ship.global_position.x = Ship.global_position.x * (1-delta) + targ * (delta)
	
	
