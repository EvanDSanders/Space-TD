extends RigidBody3D


@onready var health: Destructible = find_child("Destructible")
@onready var mana: ManaStore = find_child("ManaStore")
@onready var crystal: CrystalStore = find_child("CrystalStore")
@onready var Nav: ShipNavigator = $ShipNavigator

const SPEED = 8.0

@export var CoolDownTime := 1.
var CoolDown := CoolDownTime

@onready var Lasers: Array[Node] = self.find_children("*", "SimpleLaserBlast")


var target: Node3D
@onready var vapor_trail: VaporTrail = $VaporTrail

@onready var Tw : Tween

@export var damage := 10
var meshes : Array[MeshInstance3D]

func _ready() -> void:
	health.HPChange.connect(_hit)
	E.Register(self, E.Enemy)
	call_deferred('ready')
	meshes.append_array( find_children("*", "MeshInstance3D") )
	
func ready() -> void:
	pass



func _physics_process(delta: float) -> void:
	if not health.isAlive: return
	if not target: 
		target = E.getTarget(E.TargetType.Friend, self.global_position)
	
	if target:
		Nav.Target = target
		
		if self.global_position.distance_to(target.global_position) <= 80 and CoolDown <= 0:
			CoolDown = CoolDownTime
			for each in Lasers:
				each.Fire(target)
			target.health.Hit(damage)
	
	CoolDown -= delta

func remove(_discard=null): 
	G.spawnExplosionAndFree(G.ExplType.SciFi, self, G.Main, 0.6)

func destroy():
	self.set_collision_layer_value(2, false)
	health.Meter.Hide = true
	self.linear_damp = 0
	self.angular_damp = 0
	health.isAlive = false
	vapor_trail.top_level = true
	G.schedule(remove, 2 + G.RNG.randf_range(-.2, .2))


func _hit(damage: float, impulse: Vector3 = Vector3.ZERO):
	for each in meshes:
		each.set_instance_shader_parameter("DamageScale", G.remap(0, health.HPMax, 1, 0, health.HP))

	if impulse:
		self.apply_impulse(impulse)
