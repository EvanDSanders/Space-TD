extends Node3D

@onready var Hub: 	Node3D = $"."
@onready var Yaw: 	Node3D = $Yaw
@onready var Pitch: Node3D = $Yaw/Pitch
@onready var Post: 	Node3D = $Yaw/Pitch/Post


@export var canPan: bool = true

@export var canOrbitPitch: bool = true
@export var canOrbitYaw: bool = true

@onready var ZoomOrigin: float = Post.position.z
@onready var Zoom : float = ZoomOrigin

var PanSpeed : Vector2

@onready var PTw := create_tween()

func doPan(offset: Vector2, isContinuous: bool = false):
	if not canPan: return
	if not isContinuous:
		Yaw.position += Yaw.basis.x * -offset.x * 0.3
		Yaw.position += Yaw.basis.z * -offset.y * 0.3
	
	else:
		if offset != PanSpeed:
			PTw.kill()
			PTw = create_tween()
			PTw.tween_property(self, "PanSpeed", offset, 0.3)
		
		Yaw.position += Yaw.basis.x * PanSpeed.x
		Yaw.position += Yaw.basis.z * PanSpeed.y


func setYaw(radians: float):
	if not canOrbitYaw: return
	self.Yaw.rotation.y = radians

func doYaw(radians: float):
	if not canOrbitYaw: return
	self.Yaw.rotation.y += radians

func setPitch(radians: float):
	if not canOrbitPitch: return
	self.Pitch.rotation.x = radians

func doPitch(radians: float):
	if not canOrbitPitch: return
	self.Pitch.rotation.x += radians

func evalZoom():
	Zoom = clamp(Zoom, 10, 200)
	$Yaw/Pitch/Post.position.z = Zoom

func setZoom(fac: float, isContinuous: bool = false):
	Zoom  = fac
	evalZoom()

func doZoom(fac: float, isContinuous: bool = false):
	Zoom += fac * 5
	evalZoom()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
