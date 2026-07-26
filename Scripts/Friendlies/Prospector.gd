@icon("res://EditorIcons/prospector.svg")
extends RigidBody3D
class_name Prospector


var TargetingRange = 1000
@onready var dmgTex = preload("res://Materials/Common/DamageTexture.tres")
@onready var health: Destructible = $Destructible

var Geometries : Array[MeshInstance3D] = []

var coolDown := 1.
var CDown := coolDown
var fireID := 0

@onready var Turrets : Array[TurretBase] = [
	$"Flak TurretF",
	$"Flak TurretL",
	$"Flak TurretR",
]

@onready var TurretHubs : Array[Node3D] = [
	$"Star Station/Central Pillar/FlakF",
	$"Star Station/Central Pillar/FlakL",
	$"Star Station/Central Pillar/FlakR",
] 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for inst: MeshInstance3D in find_children("*", "MeshInstance3D"):
		inst.material_overlay = dmgTex
		inst.set_instance_shader_parameter("DamageSpaceScale", 60)
		Geometries.append(inst)
		
	health.HPChange.connect(self.updateHull)
	
	for part: GPUParticles3DFix in find_children("*Smoke*", "GPUParticles3DFix"):
		part.visible = true; part.emitting = false
		
	call_deferred('modifyMeter')
	
	for x in range(TurretHubs.size()):
		Turrets[x].visible = true
		Turrets[x].reparent( TurretHubs[x] )
		Turrets[x].global_transform = TurretHubs[x].global_transform
	
func modifyMeter():
	G.schedule(func(): health.Meter.Meter.size.x = 400; health.Meter.Meter.position.x = -200, .1)
	
func updateHull(float):
	for inst in Geometries:
		if not inst: continue
		inst.set_instance_shader_parameter("DamageScale", G.remap(0, health.HPMax, 1, 0, health.HP))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$"Star Station/Central Pillar".rotate_object_local(Vector3.UP, delta)
	
func _physics_process(delta: float) -> void:
	CDown -= delta
	var isInRange = E.getTarget(E.TargetType.Enemy, self.global_position, 1000)
	#for T in Turrets:
		#T.TargetingRange = 10000 if isInRange else 0
	
