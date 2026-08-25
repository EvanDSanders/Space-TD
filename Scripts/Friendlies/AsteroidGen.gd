@tool

extends PhysicsBody3D
class_name Asteroid3D

var Size : int
@export var CrystalsMax : int = 500
@onready var Crystals : int = CrystalsMax

@export var Mat := Material
@export var queueReload := false

var priorSize : int
var priorCrystals : int
var priorCrystalsMax : int
var _debugSize : int = -1

var scaleBase : float
var shards : Array
var base : MeshInstance3D

var DMeter : MeterPin
var TMeter : TextPin

func updateAsteroid():
	shards.clear()
	base = MeshInstance3D.new()
	base.name = "Base ITN"
	var mesh : Mesh
	var mat  := load("res://Materials/Friendlies/AsteroidMaterial.tres") as ShaderMaterial
	var matC := load("res://Materials/Friendlies/AsteroidCrystalMaterial.tres")
	
	
	Size = clamp( remap(CrystalsMax, 1500, 100000, 2, 20), 2, 20 )
	if _debugSize > 0: Size = _debugSize
	
	$CollisionShape3D.shape.radius = Size
	
	mat.set_shader_parameter("Scale", remap(Size, 5, 20, 0.766, 0.14))
	mat.set_shader_parameter("Detail", remap(Size, 5, 20, 8.549, 8.8))
	mat.set_shader_parameter("Roughness", remap(Size, 5, 20, 0.465, 0.6))
	mat.set_shader_parameter("Distortion", 0)
	
	mesh = load("res://Objects/Meshes/Asteroids/e%d.tres" % Size)
	
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
		
		var Cmesh = load("res://Objects/Meshes/RawCrystal.res")
		Cmesh.surface_set_material(0, matC)
		shard.mesh = Cmesh # Cmesh
		self.add_child(shard)
		
		
		shard.rotation = Vector3(CRNG.randf()*TAU, CRNG.randf()*TAU, CRNG.randf()*TAU)
		shard.translate_object_local(Vector3(0, Size, 0))
		var v := 0.1
		shard.rotation += Vector3(CRNG.randf_range(v,v), CRNG.randf_range(v,v), CRNG.randf_range(v,v))
		
		var scl = CRNG.randf_range(0.3, 1.2) * Size/3
		shard.scale = Vector3(scl,scl,scl)
		scaleBase = scl
		
		shards.append(shard)
		
	for each in self.get_children():
			each.owner = self

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	E.Register(self, E.Ore)
	if not Engine.is_editor_hint():
		updateAsteroid()
		DMeter = Pins.Register(self)
		DMeter.max = CrystalsMax
		DMeter.value = Crystals
		DMeter.setColor(Color.SADDLE_BROWN, Color("261305ff"))
		DMeter.VOffset = - 12
		
		
		TMeter = Pins.Register(self, Pins.Type.Text)
		TMeter.text = "%d" % Crystals
		TMeter.textSize = 20
		TMeter.setColor(Color.SADDLE_BROWN)
		
		

func mine(amt: int) -> int:
	var mined = clamp(amt, 0, self.Crystals)
	self.Crystals -= mined
	if self.Crystals == 0: E.UnRegister(self, E.Ore)
	
	for shard in shards:
		shard.scale = Vector3.ONE * G.remap(0, self.CrystalsMax, 0, scaleBase, self.Crystals)
	
	base.set_instance_shader_parameter("Use", G.remap(0, self.CrystalsMax, 1., 0., self.Crystals))
	
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
		
		DMeter.value = Crystals
		DMeter.doShow()
		TMeter.text = "%d" % Crystals
		TMeter.doShow()
		
