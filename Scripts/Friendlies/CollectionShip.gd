extends RigidBody3D

@onready var Bones := $"Cargo Shiplet/Collector Bones/Skeleton3D"
@onready var EngineTrailLoader = preload("res://Scenes/Ship/StarShipEngineTrail.tscn")
@onready var trailShader = load("res://Shaders/Trail.tres")

var target : Vector3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for x in [0, 1]:
		var trail: BoneAttachment3D = EngineTrailLoader.instantiate()
		Bones.add_child(trail)
		var vt: VaporTrail = trail.get_node("VaporTrail")
		vt.set_material(trailShader)
		vt.set_size(.5)
		vt.position.y = 0
		trail.bone_idx = x

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	var point = G.getNearest( self.global_position, get_node("/root/Main/Friendlies").find_children("Raw Crystal*") )
	if point:
		target = point.global_position


func _physics_process(delta: float) -> void:
	if target:
		
		var dir = self.global_position.direction_to(target)
		self.apply_impulse(dir)
		
	
	var v = linear_velocity / 150
	v = self.to_local(v+self.global_position)
	
		
	
	var x = v.x 
	var z = v.z 
	
	#G.BoneRotated(Bones, 2, Vector3(0, 0, 0))
	G.BoneRotate(Bones, 0, "Z", -x + z)
	G.BoneRotate(Bones, 1, "Z", -x - z)
