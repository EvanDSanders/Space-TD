extends RigidBody3D
class_name CollectorShip3D

@onready var Bones := $"Cargo Shiplet/Collector Bones/Skeleton3D"
@onready var EngineTrailLoader = preload("res://Scenes/Ship/StarShipEngineTrail.tscn")
@onready var trailShader = load("res://Shaders/Trail.tres")
@onready var store: CrystalStore = $CrystalStore

@onready var health: Destructible = $Destructible

@onready var Nav: ShipNavigator = $ShipNavigator

var target : Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for x in [0, 1]:
		var trail: BoneAttachment3D = EngineTrailLoader.instantiate()
		trail.get_node("EngineCrystal").queue_free()
		Bones.add_child(trail)
		var vt: VaporTrail = trail.get_node("VaporTrail")
		vt.set_material(trailShader)
		vt.set_size(.5)
		vt.position.y = 0
		trail.bone_idx = x
		
	E.UnRegister(self, E.Friend)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	#var point = G.getNearest( self.global_position, get_node("/root/Main/Collectibles").find_children("Raw Crystal*") )
	


func _physics_process(delta: float) -> void:
	target = E.getTarget(E.TargetType.Collectible, self.global_position)

	if target and store.Crystals < 200:
		Nav.Target = target.global_position
	else:
		Nav.Target = G.StarShip.get_node("CrystalDeposit").global_position
	
	
	var v = linear_velocity / 150
	v = self.to_local(v+self.global_position)
	
		
	
	var x = v.x 
	var z = v.z 
	
	#G.BoneRotated(Bones, 2, Vector3(0, 0, 0))
	G.BoneRotate(Bones, 0, "Z", -x + z)
	G.BoneRotate(Bones, 1, "Z", -x - z)
