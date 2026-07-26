extends Area3D
class_name CollectionArea3D

@export var store : CrystalStore
@export var isShip : bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.body_entered.connect(_on_collection_area_3d_body_entered)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



var TraceLoader = preload("res://Scenes/Projectiles/ProjectileTrace.tscn")

func traceLerp(fac:float, trace:Node3D, targ:Node3D):
	trace.global_position = self.global_position * (1-fac) + targ.global_position * fac


func _physics_process(delta: float) -> void:
	for bodyIn in self.get_overlapping_bodies():
		if isShip and bodyIn is CollectorShip3D:
			while bodyIn.store.Crystals > 0:
				var value = clamp(bodyIn.store.Crystals, 0, 25)
				var drop = MiningLaser.createCrystalNode(bodyIn, value, true)
				
				drop.global_position += Vector3(randf_range(-1, 1),randf_range(-1, 1),randf_range(-1, 1))*10
				drop.global_rotation += Vector3(randf_range(0, TAU),randf_range(0, TAU),randf_range(0, TAU))
				
				self._on_collection_area_3d_body_entered(drop)



func _on_collection_area_3d_body_entered(bodyIn: Node3D) -> void:
	if not bodyIn is Collectable: return
	var body : Collectable = bodyIn
	
	if body.isShipDeposit and not isShip: return
	if not body.Queue(): return
	
	var trace = TraceLoader.instantiate()
	trace.setColor(Color.CHARTREUSE)
	self.add_child(trace)
	
	var Tw := create_tween()
	Tw.tween_method(traceLerp.bind(trace, body), 0., 1., 1.)
	Tw.tween_method(traceLerp.bind(trace, body), 1., 0., 1.)
	Tw.parallel()
	Tw.tween_method(traceLerp.bind(body.get_node("Main"), body), 1., 0., 1.)
	
	print("DEBUG queued push store=%s isShip=%s val=%d" % [store, isShip, body.value])
	G.schedule(func(): print("DEBUG pushing store=%s amt=%d before=%f" % [store, body.value, store.Crystals]); store.pushCrystal(body.Collect()), 1.)
	G.schedule(body.Collected, 2)
	G.schedule(trace.queue_free, 2.1)
	
