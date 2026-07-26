extends Control
class_name WarningInterface

var Tw : Tween
@onready var text: Label = $PanelContainer/Label
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer
@onready var panel: PanelContainer = $PanelContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	G.Warnings = self
	SetScale(0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass

var Scale : float = 0.
func SetScale(scl:float):
	panel.custom_minimum_size.x = scl
	panel.custom_maximum_size.x = scl
	Scale = scl

func Create(message: String):
	audio.play()
	if Tw: Tw.kill()
	Tw = create_tween()

	Tw.parallel()
	Tw.tween_method(SetScale, Scale, 200., .2)
	#Tw.tween_property(text, 'text', "-- Incoming --", 0.2)
	text.text = "-- Incoming --"
	
	Tw.chain()
	Tw.tween_property(text, 'text', message, 0.5).set_delay(.5)
	
	#Tw.tween_property(text, 'text', "", 0.5).set_delay(2)
	#Tw.parallel()
	Tw.tween_method(SetScale, 200., 0., .2).set_delay(2)
