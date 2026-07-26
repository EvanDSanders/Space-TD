extends Node3D
class_name CameraObjectScript


@onready var Hub: 	Node3D = $"."
@onready var Yaw: 	Node3D = $Yaw
@onready var Pitch: Node3D = $Yaw/Pitch
@onready var Post: 	Node3D = $Yaw/Pitch/Post

var RigCamera : Camera3D

@export var canPan: bool = true

@export var canOrbitPitch: bool = true
@export var canOrbitYaw: bool = true

@onready var ZoomOrigin: float = Post.position.z
@onready var Zoom : float = ZoomOrigin
@onready var ZoomOld : float = ZoomOrigin

@onready var ZoomMin : float = 10
@onready var ZoomMax : float = 2000

var PanSpeed : Vector2

var PTw : Tween

func doPan(offset: Vector2, isContinuous: bool = false, delta := 0.):
	if not canPan: return
	var SpeedScale	= G.remap(10, 2000, 1,20, Zoom)
	var BoostFac	= 1 + Input.get_action_strength("Boost")
	
	if not isContinuous:
		Yaw.position += Yaw.basis.x * -offset.x * 0.3 * SpeedScale * BoostFac
		Yaw.position += Yaw.basis.z * -offset.y * 0.3 * SpeedScale * BoostFac
	
	else:
		if offset != PanSpeed:
			if PTw: PTw.kill()
			PTw = create_tween()
			PTw.tween_property(self, "PanSpeed", offset, 0.3)
		
		Yaw.position += Yaw.basis.x * PanSpeed.x * SpeedScale * BoostFac * delta * 100
		Yaw.position += Yaw.basis.z * PanSpeed.y * SpeedScale * BoostFac * delta * 100


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
	Zoom = clamp(Zoom, ZoomMin, ZoomMax)
	$Yaw/Pitch/Post.position.z = Zoom

func setZoom(fac: float, isContinuous: bool = false):
	Zoom  = fac
	evalZoom()

func doZoom(fac: float, isContinuous: bool = false, delta:float = 1):
	var nonLinearScaler: float = RigCamera.ZoomFactorCurve.sample( G.remap(ZoomMin, ZoomMax, 0, 1, Zoom) )
	fac = fac * nonLinearScaler
	RigCamera.get_node("Label").text = "%f" % fac
	Zoom += fac * 5 * delta
	evalZoom()
	if not isContinuous and Zoom != ZoomOld:
		ZoomOld = Zoom
		RigCamera.click(G.remap(ZoomMin, ZoomMax, 0.2, 1.8, Zoom) + (nonLinearScaler))

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
