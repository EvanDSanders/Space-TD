extends ShipControllerBase
class_name ShipOperatorControl

@export var ThrustP = 1.0
@export var ThrustD = 0.8
@export var MaxSpeed : float = 120.0
@export var SlideSpeed : float = 300.0
@export var SlideDist : float = 80.0

# Keyboard-slid point, X/Z local to ship (snaps back to 0,0 when idle), Y world in [0, 20]
var LocalOffset := Vector2.ZERO
var HeightOffset := 10.0
var Anchor : Vector3

func ready():
	Anchor = Parent.global_position

func proc(delta: float):
	if not Parent: Nav.db.clear(); return # Prevent accsess on free crash

	var moveX := Input.get_axis("Left", "Right")
	var moveZ := -Input.get_axis("Backward", "Forward")

	if not is_zero_approx(moveX):
		LocalOffset.x = clamp(LocalOffset.x + moveX * SlideSpeed * delta, -SlideDist, SlideDist)
	else:
		LocalOffset.x = move_toward(LocalOffset.x, 0, SlideSpeed * delta)

	if not is_zero_approx(moveZ):
		LocalOffset.y = clamp(LocalOffset.y + moveZ * SlideSpeed * delta, -SlideDist, SlideDist)
	else:
		LocalOffset.y = move_toward(LocalOffset.y, 0, SlideSpeed * delta)

	HeightOffset = clamp(HeightOffset + Input.get_axis("Down", "Up") * SlideSpeed * delta, 0, 20)

	var heading : float = G.Camera.Current.Yaw.rotation.y

	var choise = AIChoice.new()

	choise.Rotation = Turn(Vector3(
		0,
		PD(
			angle_difference(Parent.global_rotation.y, heading),
			Parent.angular_velocity.y,
			30,
			10,
		) / PhysicsServer3D.body_get_direct_state(Parent.get_rid()).inverse_inertia.y,
		0
	))

	var localVelocity := Parent.global_transform.basis.inverse() * Parent.linear_velocity
	var localTargetDir := Vector3(LocalOffset.x, Anchor.y + HeightOffset - Parent.global_position.y, LocalOffset.y)
	Nav.debug.drawPoint( Nav.to_global( localTargetDir ) )

	var forward = PD(localTargetDir.z, localVelocity.z, ThrustP, ThrustD)
	var strafe = PD(localTargetDir.x, localVelocity.x, ThrustP, ThrustD)
	var lift = PD(localTargetDir.y, localVelocity.y, ThrustP, ThrustD)

	# Soft speed cap: taper horizontal thrust as speed nears MaxSpeed instead of hard-clamping velocity
	var horizSpeed := Vector2(Parent.linear_velocity.x, Parent.linear_velocity.z).length()
	var throttle := 1.0 - smoothstep(MaxSpeed * 0.75, MaxSpeed, horizSpeed)
	forward *= throttle
	strafe *= throttle

	Nav.debug.drawVector( Nav.global_position, Nav.global_position + Nav.global_basis.z * forward, Color.ROYAL_BLUE )
	Nav.debug.drawVector( Nav.global_position, Nav.global_position + Nav.global_basis.x * strafe,  Color.RED )
	Nav.debug.drawVector( Nav.global_position, Nav.global_position + Nav.global_basis.y * lift,    Color.WEB_GREEN )

	choise.Thrust = ThrustLocked(Vector3(strafe, lift, forward) * Parent.mass)

	return choise
