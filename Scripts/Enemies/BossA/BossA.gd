extends CharacterBody3D
class_name BossA

@onready var SideL: Node3D = $"Side L"
@onready var SideR: Node3D = $"Side R"

@onready var final_attack_zone: Area3D = $"Final Attack Zone"
var isFinalAttack := false

var wobbleAmount := 50.0
var wobbleTime := 0.0
@onready var homePosition: Vector3 = position

func pickLaser(side:Node3D):
	var lasers = []
	for each in side.get_children():
		if each.health.isAlive:
			lasers.append(each)
			
	if lasers.size() == 0: return false
	return lasers[ randi_range(0, lasers.size() - 1) ]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	G.schedule.bind( pickLaser(SideR).startBlast, 1).call_deferred()
	G.schedule.bind( func():
		G.StarShip.fighter.FlightMode = StarShipFighter.FlightModes.SideScroller
		G.Camera.setFightStyle('SideFire')
		G.Camera.onChange()
	, 1).call_deferred()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_timer_timeout() -> void:
	var laser = pickLaser(SideR)
	if  laser: laser.startBlast()

func Twr(tw: Tween, pos, rot, scl):
	tw.tween_property(self, 'position', pos, 0.04).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(self, 'rotation', rot, 0.04).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(self, 'scale',    scl, 0.04).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

var Tw : Tween
func laserDestroied():
	if pickLaser(SideR): return
	isFinalAttack = true
	
		
	Tw = create_tween()
	
	for x in range(50):
		var pos = Vector3( randf_range(80, -80), randf_range(80, -80), randf_range(80, -80) ) + self.position
		var rot = Vector3( randf_range(-.1, .1), randf_range(-.1, .1), randf_range(-.1, .1) )
		var scl = Vector3( randf_range(0.7, 1.3), randf_range(0.7, 1.3), randf_range(0.7, 1.3) )
		Twr(Tw, pos, rot, scl)
	
	Twr(Tw, self.position, self.rotation, self.scale)
	
	Tw.tween_property(self, 'position:z', 300, 2).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN_OUT)
	Tw.tween_callback(func():
		G.StarShip.fighter.FlightMode = StarShipFighter.FlightModes.Forward
		G.Camera.setFightStyle('Forward')
		G.Camera.onChange()
	)
	Tw.tween_property(self, 'position:z', -100000, 5).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN)
	
	Tw.tween_callback(func():
		self.position = Vector3(0, 0, -20000)
		self.rotation_degrees.y = 180
	)

	Tw.tween_property(self, 'position:z', 20000, 8).set_trans(Tween.TRANS_LINEAR)
	
func _physics_process(delta: float) -> void:
	if not isFinalAttack:
		
		wobbleTime += delta
		position = homePosition + Vector3(
			sin(wobbleTime * 0.31) * wobbleAmount,
			sin(wobbleTime * 0.23 + 1.7) * wobbleAmount,
			sin(wobbleTime * 0.17 + 3.1) * wobbleAmount
		)
		
	else:
		var bodies = final_attack_zone.get_overlapping_bodies()
		for each in bodies:
			if each is ShieldBubble:
				each.onParry()
				each.onHit(111111111)
				each.defender.useEnergy(111111111, 1)
				if Tw: Tw.kill()
				Tw = create_tween()
				Tw.tween_property(self, 'position', Vector3(300, 200, -1800), 5)
				Tw.parallel().tween_property(self, 'rotation', Vector3(3, -5, 0), 5)
				Tw.tween_callback(destroy)
			

func destroy():
	print("Man, I'm ded!, Noooooooooooooo")
	$"Boss A/Cylinder 010".visible = false
	self.scale = Vector3.ZERO
	G.spawnExplosion(G.ExplType.SciFi, self, G.Main, 90)
	G.spawnExplosion(G.ExplType.SciFi, self, G.Main, 90)
	G.spawnExplosion(G.ExplType.SciFi, self, G.Main, 90)
	G.spawnExplosion(G.ExplType.SciFi, self, G.Main, 90)
	
	
