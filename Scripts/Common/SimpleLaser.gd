extends Node3D
class_name SimpleLaserBlast

@export var Start: Node3D = self
var 		End  : Node3D
var Offset : Vector3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.process_mode = Node.PROCESS_MODE_DISABLED


func lerpLaser(f: float):
	#self.scale.x = f
	self.scale.y = f
	pass

var Tw : Tween

func Fire(target:Node3D):
	End = target
	self.visible = true
	self.process_mode = Node.PROCESS_MODE_INHERIT
	
	print("Fire! ", self.get_parent().name, " : ", Start.global_position, " ", End.global_position)
	
	if Tw: Tw.kill()
	Tw = create_tween()
	Tw.tween_method(lerpLaser, 1., 0., .4)
	Tw.tween_callback(func():
		self.visible = false
		self.process_mode = Node.PROCESS_MODE_DISABLED
	)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if not End or not Start:  self.process_mode = Node.PROCESS_MODE_DISABLED; visible = false; return

	var mid = 0.5 * Start.global_position + 0.5 * End.global_position
	var diff = End.global_position - Start.global_position
	var len = diff.length()
	var x_axis = diff / len

	var to_cam = (G.camera.global_position - mid)
	var z_axis = (to_cam - x_axis * to_cam.dot(x_axis)).normalized()  # orthogonalize vs x
	var y_axis = z_axis.cross(x_axis).normalized()

	self.global_position = mid
	self.global_transform.basis = Basis(x_axis, y_axis, z_axis)
	self.scale.x = len
