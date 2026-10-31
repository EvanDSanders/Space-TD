extends ShipBase



@export var CoolDownTime := 1.
var CoolDown := CoolDownTime

@onready var Lasers: Array[Node] = self.find_children("*", "SimpleLaserBlast")


var target: Node3D
@onready var vapor_trail: VaporTrail = $VaporTrail

@onready var Tw : Tween

@export var damage := 10

func _ready() -> void:
	call_deferred('ready')
	meshes.append_array( find_children("*", "MeshInstance3D") )
	
func ready() -> void:
	pass



func _physics_process(delta: float) -> void:
	if not health.isAlive: return
	if not target: 
		target = E.getTarget(E.TargetType.Friend, self.global_position)
	
	if target:
		Nav.Target = target.global_position
		
		if self.global_position.distance_to(target.global_position) <= 80 and CoolDown <= 0:
			CoolDown = CoolDownTime
			for each in Lasers:
				each.Fire(target)
			target.health.Hit(damage)
	
	CoolDown -= delta

func destroy():
	self.set_collision_layer_value(2, false)
	health.Meter.Hide = true
	self.linear_damp = 0
	self.angular_damp = 0
	vapor_trail.top_level = true
	G.schedule(remove, 2 + G.RNG.randf_range(-.2, .2))
