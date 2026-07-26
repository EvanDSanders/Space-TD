extends TurretBase
class_name MiningLaser

@onready var Meter: Waypoint = $DisplayMeter


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	
	Meter.get_child(0).position.y -= (20+2)

	crystal.CrystalsChange.connect(Meter.doShow)
	crystal.CrystalsChange.connect(func(amt:int): Meter.Meter.value = amt)
	Meter.Meter.max_value = maxCrystals
	

var maxCrystals = 50

func isMineable(obj: Node3D):
	if not obj is Asteroid3D: return false
	return obj.Crystals > 0
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if self.constructor: return
	
	var targ = E.getTargetWith($Area3D.get_overlapping_bodies(), self.global_position, -1, isMineable)
	var ore : Asteroid3D
	if targ and targ is Asteroid3D:
		ore = targ
	
	if not ore: return
	var heading = super.get_heading(self.global_position, 0, ore.global_position, Vector3.ZERO)
	
	Yaw.rotation.y = heading.y
	Pitch.rotation.x = heading.x
	
	if ore.Crystals > 0 and crystal.Crystals < maxCrystals:
		var mine = clamp(1 if Engine.get_physics_frames() % 8 == 0 else 0, 0, maxCrystals - crystal.Crystals)
		#crystal.Crystals += ore.mine(mine)
		crystal.pushCrystal(ore.mine(mine))
		
	elif crystal.Crystals >= maxCrystals:
		createCrystalNode(self, crystal.Crystals)
		crystal.pullCrystal(crystal.Crystals)
		

static var CrystalNode = preload("res://Scenes/Collectables/RawCrystal.tscn")
static func createCrystalNode(caller:Node3D, value:int, isShipDeposit:bool=false) -> Collectable:
	var drop : Collectable = CrystalNode.instantiate()
	drop.value = value
	caller.get_node("CrystalStore").pullCrystal(value)
	if isShipDeposit: drop.markDeposit()
	G.Main.add_child(drop)
	drop.global_position = caller.global_position
	return drop
