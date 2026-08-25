@tool
extends SubViewportContainer
class_name LoadingScreenBase

@onready var Main: LoadingScreenMain = $"SubViewport/Loading Screen"

signal fullyDisplayed
signal fullyDissipated

#@export_range(-1, 1, 0.01, "prefer_slider") var offset : float = 0
#@export_range(0, 1, 0.01, "prefer_slider") var phase : float = 0

var offset : PackedFloat32Array = range(50)
var phase : PackedFloat32Array = range(50)
var Tw : Tween

# Called when the node enters the scene tree for the first time.
func _ready() -> void: 
	doRun = true

@export var doRun : bool = false
@export var running : bool = false

func run(rev:bool=false):
	if Tw: Tw.kill()
	Tw = create_tween().set_parallel()
	
	for i:int in range(50):
		var id : int = i
		offset[i] = randf_range(-1, 1)
		phase[i]  = 0. if not rev else 1.
		if not rev:
			Tw.tween_method(func(val:float): phase[id] = val, 0., 1., .3).set_delay(randf()*.3+(50-i)/80.).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		else:
			Tw.tween_method(func(val:float): phase[id] = val, 1., 0., .3).set_delay(randf()*.3+(50-i)/80.).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	
	if not rev:
		Tw.chain().tween_callback(fullyDisplayed.emit)
	else:
		Tw.chain().tween_callback(fullyDissipated.emit)
		Tw.chain().tween_callback(queue_free)
	

func Complete(): run(true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	
	$SubViewport.size = $".".size
	
	if doRun:
		doRun = false
		run()
	
	self.material.set_shader_parameter("offset", offset)
	self.material.set_shader_parameter("phase", phase)
