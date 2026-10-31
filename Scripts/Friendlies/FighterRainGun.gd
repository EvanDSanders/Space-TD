extends StationShip
class_name RailgunShip

var Target: Node3D
var target: Vector3
@onready var home: Vector3 = G.StarStation.global_position

@onready var turret: TurretController = $TurretControllerL


@onready var EngineL: StationShipEngine = $"RailGun Ship/Origin Railgun Ship Track/Railgun Ship Engine L/StationShip Engine"
@onready var EngineR: StationShipEngine = $"RailGun Ship/Origin Railgun Ship Track/Railgun Ship Engine R/StationShip Engine"
@onready var EngineF: StationShipEngine = $"RailGun Ship/Origin Railgun Ship Track/Railgun Ship Engine F/StationShip Engine"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	
	#turret.onHit.Shooter = self

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
				Target = E.getTarget(E.Enemy, self.global_position, -1)
				if not Target:
					Target = E.getTarget(E.Enemy, self.home, -1)
				
		SysState.Full, SysState.LowPwr:
			Target = G.StarStation.GetExchange(self)
			
		
	if Target:
		target = Target.global_position
		if State == SysState.Normal:
			if Target is PhysicsBody3D: 
				turret.Target = Target
			else:
				turret.Target = null
			Nav.AI.isAbsolute = not is_instance_valid(Target)
			Nav.AI.AltAltitude = -INF
			
		else: 
			turret.Target = null
			Nav.AI.isAbsolute = true
			Nav.AI.AltAltitude = Target.global_position.y
			
	else:
		turret.Target = null
		target = self.home
		Nav.AI.AltAltitude = -INF
		
	Nav.Target = target
	
