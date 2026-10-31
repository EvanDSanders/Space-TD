extends RigidBody3D
class_name ShipBase

@export var ViewerName: String

@onready var health: Destructible = find_child("Destructible")
@onready var mana: ManaStore = find_child("ManaStore")
@onready var energy: EnergyStore = find_child("EnergyStore")
@onready var crystal: CrystalStore = find_child("CrystalStore")
@onready var cursorDialogue: CursorDialogue = find_child("CursorDialogue")
@onready var Nav: ShipNavigator = $ShipNavigator

var meshes : Array[MeshInstance3D]

@export var faction: E.TargetType

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	health.HPChange.connect(_hit)

	E.Register(self, faction)



func remove(_discard=null): 
	G.spawnExplosionAndFree(G.ExplType.SciFi, self, G.Main, 0.6)


func destroy():
	G.spawnExplosionAndFree(G.ExplType.SciFi, self, G.Main, 0.6)
	E.UnRegister(self, faction)
	G.schedule(remove, 2 + G.RNG.randf_range(-.2, .2))


func _hit(damage: float, impulse: Vector3 = Vector3.ZERO):
	for each in meshes:
		each.set_instance_shader_parameter("DamageScale", G.remap(0, health.HPMax, 1, 0, health.HP))

	if impulse:
		self.apply_impulse(impulse)



#func _unhandled_input(event: InputEvent) -> void:
func _input_event(camera: Camera3D, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if cursorDialogue:
		cursorDialogue._unhandled_input_pass(event)
