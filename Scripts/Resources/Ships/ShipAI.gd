extends ShipControllerBase
class_name ShipAI

@export var Distance : int = 50
@export var ThrustP = 0.13
@export var ThrustD = 0.3
@export var MaxSpeed : float = 40.0
@export var StrafeRange : float = 25.0
@export var StrafeRate : float = 50.0

@export var Altitude := 10.
@export var AltAltitude := -INF


@export var TurnP = 25
@export var TurnD = 10

@export var StrafeP = 0.13
@export var StrafeD = 0.3

@export var LiftP = 0.13
@export var LiftD = 0.3

func ready(): pass

func proc(delta: float):
	if isCharging(): return AIChoice.new()
	if not Parent: Nav.db.clear(); return # Prevent accsess on free crash
	var targetDir := target - Parent.global_position
	var forwardDir := - Parent.global_transform.basis.z
	var dot := forwardDir.dot( targetDir.normalized() ) 
	
	var heading : float = atan2(-targetDir.x, -targetDir.z)
	
	var forward : float = 0.
	var lift : float = 0.
	var strafe : float = 0.
	
	var distTo = Parent.global_position.distance_to(target) 
	if not isAbsolute:
		distTo -= Distance
	
	var choise = AIChoice.new()
	
	ThrustP = 1
	ThrustD = 0.8

	
	choise.Rotation = Turn(Vector3( 
		0, 
		PD(
			angle_difference(Parent.global_rotation.y, heading), 
			Parent.angular_velocity.y, 
			TurnP,
			TurnD, 
		) / PhysicsServer3D.body_get_direct_state(Parent.get_rid()).inverse_inertia.y, 
		0
	))
	
	
	
	var localVelocity := Parent.global_transform.basis.inverse() * Parent.linear_velocity

	forward = PD(
			#clamp(-distTo * dot, -10, 10),
			- distTo * (dot / 1),
			localVelocity.z,
			ThrustP,
			ThrustD,
		)

	var localTargetDir := Parent.global_transform.basis.inverse() * targetDir
	
	
	var doStrafe = 0
	if not isAbsolute:
		doStrafe = clamp( G.remap( StrafeRange, 0, 0, StrafeRate, abs(distTo) ), 0, 1000 )
	
	strafe = PD(
			doStrafe,
			localVelocity.x,
			StrafeP,
			StrafeD,
		)
		

	lift = PD(
			- (Parent.global_position.y - ( Altitude if AltAltitude < -10000 else AltAltitude )),
			#distTo * dot,
			localVelocity.y,
			LiftP,
			LiftD,
		)

	# Soft speed cap: taper horizontal thrust as speed nears MaxSpeed instead of hard-clamping velocity
	var horizSpeed := Vector2(Parent.linear_velocity.x, Parent.linear_velocity.z).length()
	var throttle := 1.0 - smoothstep(MaxSpeed * 0.75, MaxSpeed, horizSpeed)
	forward *= throttle
	strafe *= throttle

	Nav.debug.drawVector( Nav.global_position, Nav.global_position + Nav.global_basis.z * forward, Color.ROYAL_BLUE )
	Nav.debug.drawVector( Nav.global_position, Nav.global_position + Nav.global_basis.x * strafe,  Color.RED )
	Nav.debug.drawVector( Nav.global_position, Nav.global_position + Nav.global_basis.y * lift,    Color.WEB_GREEN )
	#Nav.debug.drawString( Nav.global_position, Vector2(0, 30), str(localVelocity.z))
	#Nav.debug.drawString( Nav.global_position, Vector2(0, 50), str(distTo) + "  " + str(doStrafe))

	
	choise.Thrust = ThrustLocked(Vector3(strafe, lift, forward) * Parent.mass)
	
	return choise
