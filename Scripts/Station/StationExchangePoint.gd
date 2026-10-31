extends Area3D

@onready var Station := G.StarStation
var Ship : StationShip
var Pin : Generic6DOFJoint3D
var Connected := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Ship and Connected:
		Ship.energy.pushFuel( Station.energy.pullFuel( 
				clamp( abs( Ship.energy.EnergyMax - Ship.energy.Energy ), 0, 10) * delta
			) )
		
		if Ship.crystal and Engine.get_physics_frames() % 3 == 0:
			Station.crystal.pushCrystal( Ship.crystal.pullCrystal( 
					clamp( 1, 0, Ship.crystal.Crystals)
				) )

		if	(
				( Ship.crystal.Crystals == 0 if Ship.crystal else true ) and
				( Ship.energy.Energy / Ship.energy.EnergyMax > 0.95 if Ship.energy else true )
			):
			#Ship.Nav.AI.ThrustLocked(Vector3(0, 100, -200))
			Ship.popOff()
			Ship = null
			Connected = false
			if Pin: Pin.queue_free()

@export var curve : Curve
func snappingEase(p:float) -> float:
	return curve.sample(p)

func _on_body_entered(body: Node3D) -> void:
	if body is StationShip and not self.Ship:
		if body.State == StationShip.SysState.LowPwr or body.State == StationShip.SysState.Full:
			Ship = body
			Ship.State = StationShip.SysState.Parked
			var Tw = create_tween()
			Tw.tween_property(Ship, "global_transform", self.global_transform, 0.5).set_custom_interpolator(snappingEase)
			Tw.chain().tween_callback(func(): 
				Connected = true
				Pin = Generic6DOFJoint3D.new()
				G.Main.add_child( Pin )
				Pin.global_transform = self.global_transform
				Pin.node_a = Pin.get_path_to(Ship)
				Pin.node_b = Pin.get_path_to(Station)
			)
