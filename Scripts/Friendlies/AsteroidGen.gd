@tool

extends PhysicsBody3D
class_name Asteroid3D
@onready var Meter: Waypoint = $DisplayMeter

@export var Size : int = 5
@export var CrystalsMax : int = 500
@onready var Crystals : int = CrystalsMax

@export var Mat := Material
@export var queueReload := false

var priorSize : int
var priorCrystals : int
var priorCrystalsMax : int

func updateAsteroid():
	var base := MeshInstance3D.new()
	base.name = "Base ITN"
	var mesh := IcoSphereMesh.new()
	var mat  := load("res://Materials/Friendlies/AsteroidMaterial.tres")
	var matC  := load("res://Materials/Friendlies/AsteroidCrystalMaterial.tres")
	
	$CollisionShape3D.shape.radius = Size
	
	base.set_instance_shader_parameter("Scale", remap(Size, 5, 20, 0.766, 0.14))
	base.set_instance_shader_parameter("Detail", remap(Size, 5, 20, 8.549, 8.8))
	base.set_instance_shader_parameter("Roughness", remap(Size, 5, 20, 0.465, 0.6))
	base.set_instance_shader_parameter("Distortion", 0)
	
	mesh.edge_count = clamp( remap(Size, 2, 20, 8, 64), 4, 86 )
	mesh.heigth = Size*2
	mesh.radius = Size
	mesh.surface_set_material(0, mat)
	
	base.mesh = mesh
	self.add_child(base)
	
	var CRNG = RandomNumberGenerator.new()
	CRNG.seed = Size
	
	for x in range(remap(Size, 2, 20, 15, 50)):
		var shard := MeshInstance3D.new()
		shard.name = "Shard ITN %d" % x
		
		#var Cmesh := SphereMesh.new()
		#Cmesh.rings = 2
		#Cmesh.radial_segments = 4
		#Cmesh.height = 3
		#Cmesh.radius = .5
		
		var Cmesh = load("res://Objects/Meshes/RawCrystal.res")
		Cmesh.surface_set_material(0, matC)
		shard.mesh = Cmesh # Cmesh
		self.add_child(shard)
		
		#shard.create_convex_collision_shape(true,true)
		
		
		# print( shard.find_children("*", "*", true, false) )
		
		
		shard.rotation = Vector3(CRNG.randf()*TAU, CRNG.randf()*TAU, CRNG.randf()*TAU)
		shard.translate_object_local(Vector3(0, Size, 0))
		var v := 0.1
		shard.rotation += Vector3(CRNG.randf_range(v,v), CRNG.randf_range(v,v), CRNG.randf_range(v,v))
		
		var scl = CRNG.randf_range(0.3, 1.2) * Size/3
		shard.scale = Vector3(scl,scl,scl)
		
	for each in self.get_children():
			each.owner = self

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	E.Register(self, E.Ore)
	if not Engine.is_editor_hint():
		updateAsteroid()

func mine(amt: int) -> int:
	var mined = clamp(amt, 0, self.Crystals)
	self.Crystals -= mined
	if self.Crystals == 0: E.UnRegister(self, E.Ore)
	return mined


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if priorSize != Size or CrystalsMax != priorCrystalsMax or queueReload:
		priorCrystalsMax = CrystalsMax
		priorSize = Size
		queueReload = false
		
		for node in self.find_children("*", "MeshInstance3D"):
			node.queue_free()
		call_deferred("updateAsteroid")
	
	
	if Engine.is_editor_hint(): return
		
	if Crystals != priorCrystals:
		priorCrystals = Crystals
		Meter.Meter.value = Crystals
		Meter.Meter.max_value = CrystalsMax
		Meter.doShow()
		
