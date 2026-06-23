extends Node3D

@onready var Targets	= get_node('/root/Main/Targets')

func stub(): return true;

@export var YawObject: StringName = "Laser Turret Base"
@export var PitchObject: StringName = "Laser Turret Pitch"
@export var RecoilObject: StringName = "Laser Turret Head"
@export var EmittersObjects: Array = [
	"Turret Emitter L", 
	"Turret Emitter R"
]
@export var ProjectileResource: Resource 
@export var ExtraFiringCondition: Callable = stub

@onready var Yaw	 = find_child(YawObject)
@onready var Pitch	 = find_child(PitchObject)
@onready var Head	 = find_child(RecoilObject)
var Emitters : Array

var CDown : float = 0
var Aimed: bool

var RangingOrigin : Node3D = self

@onready var Projectile = ProjectileResource
@onready var Pointer := $"Main Cannon/Origin Cannon Hub/Cannon Pitch/RayCast3D"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for emtr in EmittersObjects:
		Emitters.append(find_child(emtr))


func get_heading(obj: Node3D, axis: StringName, targ) -> float:
	var priorXYZ := obj.rotation
	var newAngle := 0.
	obj.look_at(targ, Vector3(0,1,0))
	match axis:
		"Y":
			obj.rotation.x = 0
			obj.rotation.z = 0
			newAngle = obj.rotation.y
		"X":
			Pitch.rotation.y = 0
			Pitch.rotation.z = 0
			newAngle = obj.rotation.x
		"Z":
			Pitch.rotation.y = 0
			Pitch.rotation.x = 0
			newAngle = obj.rotation.z
	
	obj.rotation = priorXYZ
	return newAngle

var priorY := 0.
var priorX := 0.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Targets.get_child_count() != 0:
		
		var mouse: RayCast3D = get_node('/root/Main/CursorCast3D')
		
		if not mouse.is_colliding(): return
		var Target = mouse.get_collision_point()
		
		var t = G.get_intercept( Pitch.global_position, 50, Target, Vector3.ZERO )
		
		var y = get_heading(Yaw,   "Y", t)
		var x = get_heading(Pitch, "X", t)

		Yaw.rotation.y += clamp(angle_difference(Yaw.rotation.y, y), -.025, .025)
		Pitch.rotation.x += clamp(x - Pitch.rotation.x, -.025, .025)

		priorY = Yaw.rotation.y
		priorX = Pitch.rotation.x	
		
		Aimed = is_zero_approx(angle_difference(Yaw.rotation.y, y)) and is_zero_approx(angle_difference(Pitch.rotation.x, x))
			
		if CDown <= 0 and Aimed:
			CDown = 10
			
			#for emtr in Emitters:
				#
				#var projectile : Node3D = Projectile.instantiate()
				#G.root.add_child(projectile)
				#projectile.global_transform = emtr.global_transform
		
	CDown -= _delta;
	
	if Pointer.is_colliding():
		$"Cannon Target".global_position = Pointer.get_collision_point()
