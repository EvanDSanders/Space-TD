extends Node3D
class_name CameraObjectScript


@onready var Hub: 	Node3D = $"."
@onready var Yaw: 	Node3D = $Yaw
@onready var Pitch: Node3D = $Yaw/Pitch
@onready var Post: 	Node3D = $Yaw/Pitch/Post

var RigCamera : RiggedCamera

@export var canPan: bool = true

@export var canOrbitPitch: bool = true
@export var canOrbitYaw: bool = true
@export var canZoom: bool = true

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
			PTw.tween_property(self, "PanSpeed", offset, 0.3 * Engine.time_scale)
		
		Yaw.position += Yaw.basis.x * PanSpeed.x * SpeedScale * BoostFac * delta * 100
		Yaw.position += Yaw.basis.z * PanSpeed.y * SpeedScale * BoostFac * delta * 100


func setYaw(radians: float):
	if not canOrbitYaw: return
	if G.Main.Flaten: return
	self.Yaw.rotation.y = radians

func doYaw(radians: float):
	if not canOrbitYaw: return
	if G.Main.Flaten: return
	self.Yaw.rotation.y += radians

func setPitch(radians: float):
	if not canOrbitPitch: return
	if G.Main.Flaten: return
	self.Pitch.rotation.x = radians

func doPitch(radians: float):
	if not canOrbitPitch: return
	if G.Main.Flaten: return
	self.Pitch.rotation.x += radians

func evalZoom():
	Zoom = clamp(Zoom, ZoomMin, ZoomMax)
	if G.Main.Flaten:
		G.Camera.size = Zoom / 1
	else:
		$Yaw/Pitch/Post.position.z = Zoom

func setZoom(zoom: float, _isContinuous: bool = false):
	Zoom = zoom
	evalZoom()

func doZoom(fac: float, isContinuous: bool = false, delta:float = 1):
	if not canZoom: return
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


var wasFlat := false
var isFlatReady:= false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:

		
	if G.Main.Flaten != wasFlat:
		wasFlat = G.Main.Flaten
		
		if G.Main.Flaten:
			RigCamera.projection = Camera3D.PROJECTION_ORTHOGONAL
			self.Yaw.rotation.y = 0
			self.Pitch.rotation.x = - PI / 2
			
		else:
			RigCamera.projection = Camera3D.PROJECTION_PERSPECTIVE
			
		evalZoom()
