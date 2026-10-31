extends StationShip


var Target: Node3D
var target: Vector3
@onready var home: Vector3 = self.global_position
@onready var turret: TurretController = $TurretController


@onready var EngineL: StationShipEngine = $"Figher Gatling/Origin Figher Gatling Frame/Gatling Fighter Engine L/StationShip Engine"
@onready var EngineR: StationShipEngine = $"Figher Gatling/Origin Figher Gatling Frame/Gatling Fighter Engine R/StationShip Engine"



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if State == SysState.Parked: pass
	elif energy.Energy <= energy.EnergyMax * 0.1:
		State = SysState.LowPwr
	
	match State:
		SysState.Normal:
			if Engine.get_physics_frames() % 60 == 0 or not Target: 
				Target = E.getTarget(E.Enemy, self.global_position, 200)
				if not Target:
					Target = E.getTarget(E.Enemy, self.home, 200)
					
		SysState.LowPwr:
			Target = G.StarStation.GetExchange(self)
		
		
	if Target:
		target = Target.global_position
		if State == SysState.Normal:
			if Target is PhysicsBody3D:
				turret.Target = Target
			else: turret.Target = null
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
	
