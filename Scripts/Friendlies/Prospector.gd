@icon("res://EditorIcons/prospector.svg")
extends RigidBody3D
class_name Prospector


var TargetingRange = 1000
@onready var dmgTex = preload("res://Materials/Common/DamageTexture.tres")
@onready var health: Destructible = $Destructible
@onready var energy: EnergyStore = $EnergyStore
@onready var crystal: CrystalStore = $CrystalStore

var Geometries : Array[MeshInstance3D] = []

var coolDown := 1.
var CDown := coolDown
var fireID := 0

@onready var Turrets : Array[TurretBase] = []

@onready var TurretHubs : Array[Node3D] = [
	$"Star Station/Central Pillar/GatlingTurret1",
	$"Star Station/Central Pillar/GatlingTurret2",
	$"Star Station/Central Pillar/GatlingTurret3",
	$"Star Station/Central Pillar/GatlingTurret4",
	$"Star Station/Central Pillar/GatlingTurret5",
] 

@onready var hangerCenter: Marker3D = $HangerCenter


var Exchanges : Array[Node3D]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for ext in self.find_children("Station Exchange Point*", "Area3D", false):
		Exchanges.append(ext)
	
	for inst: MeshInstance3D in find_children("*", "MeshInstance3D"):
		inst.material_overlay = dmgTex
		inst.set_instance_shader_parameter("DamageSpaceScale", 60)
		Geometries.append(inst)
		
	health.HPChange.connect(self.updateHull)
	
	for part: GPUParticles3DFix in find_children("*Smoke*", "GPUParticles3DFix"):
		part.visible = true; part.emitting = false
		
	call_deferred('modifyMeter')
	
	for x in range(5):
		var T := load("res://Scenes/Station/GatlingTurret.tscn").instantiate() as GatlingTurret
		Turrets.append(T)
		TurretHubs[x].add_child(T)
		T.global_transform = TurretHubs[x].global_transform
		T.Station = self
		
		
func modifyMeter():
	G.schedule(func(): health.Meter.size.x = 400; health.Meter.position.x = -200, .1)
	if not G.isMainLevel:
		var stats: MarginContainer = $"../../GUI Mount/ResourceContainer"
		energy.EnergyChange.connect(stats.updateEnergy)
		health.HPChange.connect(stats.updateHealth)
		crystal.CrystalsChange.connect(stats.updateCrystals)
	pass
	
func updateHull(float):
	for inst in Geometries:
		if not inst: continue
		inst.set_instance_shader_parameter("DamageScale", G.remap(0, health.HPMax, 1, 0, health.HP))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$"Star Station/Origin Star Station/Radar Mount".rotate_object_local(Vector3.UP, delta)
	

func destroy():
	G.Main.GameOver()
	G.Main.gameOver.Expand()

func isEmpty(obj: Node3D) -> bool: return not obj.Ship
func GetExchange(caller: StationShip) -> Area3D:
	return E.getTargetWith(Exchanges as Array[Node3D], caller.global_position, -1, isEmpty)

func _physics_process(delta: float) -> void:
	CDown -= delta
	var isInRange = E.getTarget(E.TargetType.Enemy, self.global_position, 1000)
	#for T in Turrets:
		#T.TargetingRange = 10000 if isInRange else 0
	
