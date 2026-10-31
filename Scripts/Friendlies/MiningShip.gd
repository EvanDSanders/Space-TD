extends StationShip


var Target: Node3D
var target: Vector3
@onready var home: Vector3 = G.StarStation.global_position

@onready var turretL: TurretController = $TurretControllerL
@onready var turretR: TurretController = $TurretControllerR


@onready var EngineL: StationShipEngine = $"Mining Ship/Origin Mining Ship/Mining Ship Engine L/StationShip Engine"
@onready var EngineR: StationShipEngine = $"Mining Ship/Origin Mining Ship/Mining Ship Engine R/StationShip Engine"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	
	turretL.onHit.Shooter = self
	turretR.onHit.Shooter = self

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if State == SysState.Parked: pass
	elif energy.Energy <= energy.EnergyMax * 0.1:
		State = SysState.LowPwr
		
	elif crystal.Crystals >= crystal.CrystalsMax:
		State = SysState.Full
	
	else: 
		State = SysState.Normal
		
	
	match State:
		SysState.Normal:
			if Engine.get_physics_frames() % 60 == 0 or not Target: 
				Target = E.getTarget(E.Ore, self.global_position, 200)
				if not Target:
					Target = E.getTarget(E.Ore, self.home, 200)
				
		SysState.Full, SysState.LowPwr:
			Target = G.StarStation.GetExchange(self)
			
		
	if Target:
		target = Target.global_position
		if State == SysState.Normal:
			if Target is PhysicsBody3D: 
				turretL.Target = Target
				turretR.Target = Target
			else:
				turretL.Target = null
				turretR.Target = null
			Nav.AI.isAbsolute = not is_instance_valid(Target)
			Nav.AI.AltAltitude = -INF
			
		else: 
			turretL.Target = null
			turretR.Target = null
			Nav.AI.isAbsolute = true
			Nav.AI.AltAltitude = Target.global_position.y
			
	else:
		turretL.Target = null
		turretR.Target = null
		target = self.home
		Nav.AI.AltAltitude = -INF
		
	Nav.Target = target
	
