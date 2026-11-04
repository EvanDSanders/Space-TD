extends Node
class_name StarShipFighter

# Forward:      moves on X/Y, faces -Z
# SideScroller: moves on Z/Y, faces direction of travel (camera on +X)
# SideFire:     moves on Z/Y, nose points into the screen (-X)
# TopDown:      moves on X/Z, ship turns to face its movement
#
# The ship is frozen (kinematic) while this module is active. Its position is
# always FighterModeOrigin.position + _rel, so it can't drift from the origin.
enum FlightModes { Forward, SideScroller, SideFire, TopDown }

@export var FlightMode: FlightModes = FlightModes.Forward:
	set(v):
		if v == FlightMode: return
		FlightMode = v
		if active: _applyFlightMode()

@export var ForwardSpeed := 60.  # FighterModeOrigin's constant -Z speed, all modes except TopDown

# Origin-relative play area per mode. Vector2(x = width axis, y = height axis).
# Forward: X/Y | SideScroller/SideFire: Z/Y | TopDown: X/Z
@export var Limits: Dictionary = {
	FlightModes.Forward:      {"min": Vector2(-60, -35),  "max": Vector2(60, 35)},
	FlightModes.SideScroller: {"min": Vector2(-80, -35),  "max": Vector2(80, 35)},
	FlightModes.SideFire:     {"min": Vector2(-80, -35),  "max": Vector2(80, 35)},
	FlightModes.TopDown:      {"min": Vector2(-80, -60),  "max": Vector2(80, 60)},
}
@export var MaxSpeed := 150.
@export var Acceleration := 14.   # higher = snappier
@export var TurnRate := 12.
@export var BoostMultiplier := 2.0
@export var EngineColors: Gradient

var ship: TheStarShip
var active := false

var boost := 0.
var boostActive := false
var BTw: Tween
var STw: Tween
var engineHeat := 0.

var _facing := 0.          # target yaw for modes that turn freely
var _pinAxis := -1         # axis slid to 0 (relative to origin) and held: 0 X, 1 Y, 2 Z
var _origin: Node3D
var _rel := Vector3.ZERO   # ship position relative to the origin
var _relVel := Vector3.ZERO
var _yawVel := 0.


func setup(p_ship: TheStarShip) -> void:
	ship = p_ship
	if not EngineColors:
		EngineColors = ship.EngineColors
	set_physics_process(false)


func activate() -> void:
	active = true
	ship.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	ship.freeze = true
	_relVel = ship.linear_velocity
	_yawVel = 0.
	set_physics_process(true)
	_applyFlightMode()
	
		
	$"../../../GUI Mount/Warnings"
	$"../../../GUI Mount/Defender"



func deactivate() -> void:
	active = false
	set_physics_process(false)
	ship.freeze = false
	ship.linear_velocity = _relVel
	ship.angular_velocity = Vector3.ZERO
	_pinAxis = -1
	if STw: STw.kill()
	if BTw: BTw.kill()
	boost = 0.
	boostActive = false
	engineHeat = 0.
	ship.animator.writeShader(0.0, "StarShipEngineOverheat")
	ship.animator.setBoostScale(0.001)


func _applyFlightMode() -> void:
	match FlightMode:
		FlightModes.Forward: _pinAxis = 2 # Z belongs to the origin's travel
		FlightModes.SideScroller, FlightModes.SideFire: _pinAxis = 0
		FlightModes.TopDown: _pinAxis = 1
	SetSpeed(0.0 if FlightMode == FlightModes.TopDown else 300.0, 2.0)
	_placeOrigin()
	_rel = ship.global_position - _originPos()
	match FlightMode:
		FlightModes.Forward, FlightModes.SideScroller: _facing = 0.
		FlightModes.SideFire: _facing = PI / 2
		FlightModes.TopDown: _facing = ship.rotation.y


func _getOrigin() -> Node3D:
	if not is_instance_valid(_origin):
		_origin = G.Main.get_node_or_null("FighterModeOrigin")
	return _origin


func _originPos() -> Vector3:
	var o := _getOrigin()
	return o.global_position if o else Vector3.ZERO


func _originVelocity() -> Vector3:
	return Vector3(0, 0, -ForwardSpeed)


# Tween the origin's forward speed
func SetSpeed(speed: float, time: float = 2.0) -> void:
	if STw: STw.kill()
	STw = create_tween()
	STw.tween_property(self, "ForwardSpeed", speed, time)


# Place the origin under the ship. Non-TopDown: X/Y exactly 0. TopDown: stays put afterwards.
func _placeOrigin() -> void:
	var o := _getOrigin()
	if not o: return
	var p := ship.global_position
	if FlightMode == FlightModes.TopDown:
		o.global_position = Vector3(p.x, 0.0, p.z)
	else:
		o.global_position = Vector3(0.0, 0.0, p.z)


func _advanceOrigin(delta: float) -> void:
	var o := _getOrigin()
	if not o: return
	var p := o.global_position + _originVelocity() * delta
	if FlightMode != FlightModes.TopDown:
		p.x = 0.0
		p.y = 0.0
	o.global_position = p


# [width axis, height axis] as vector indices
func _limitAxes() -> Vector2i:
	match FlightMode:
		FlightModes.Forward: return Vector2i(0, 1)
		FlightModes.TopDown: return Vector2i(0, 2)
		_: return Vector2i(2, 1)


# Caps the relative velocity so the next step ends inside [min, max]. If the ship
# starts outside the box it is eased back in at the capped speed.
func _limitRelVelocity(vel: Vector3, delta: float) -> Vector3:
	if not Limits.has(FlightMode): return vel
	var lim: Dictionary = Limits[FlightMode]
	var axes := _limitAxes()
	for i in 2:
		var a: int = axes[i]
		var lo: float = (lim["min"][i] - _rel[a]) / delta
		var hi: float = (lim["max"][i] - _rel[a]) / delta
		vel[a] = clampf(vel[a], minf(lo, hi), maxf(lo, hi))
	return vel


func _updateBoost(want: bool, delta: float) -> void:
	if want != boostActive:
		boostActive = want
		if BTw: BTw.kill()
		BTw = create_tween()
		BTw.tween_property(self, "boost", 1. if want else 0., .2)

	engineHeat += G.remap(0, 1, -.5, 1, boost) * delta
	engineHeat = clampf(engineHeat, 0, 10)
	if EngineColors and not ship.animator.isTransitioning():
		ship.animator.writeShader(EngineColors.sample(engineHeat / 6), 'StarShipEngineColor')
	ship.animator.writeShader(clampf(G.remap(3, 6, 0, 1, engineHeat), 0, 1), "StarShipEngineOverheat")
	ship.animator.setBoostScale(boost)
	if engineHeat > 6:
		ship.health.Hit(G.remap(6, 10, 0, 20 * delta, engineHeat), Vector3.ZERO, true)


func _physics_process(delta: float) -> void:
	if not ship or not ship.health or not ship.health.isAlive: return

	_advanceOrigin(delta)

	# No steering while the mode transition plays, but the ship still rides the origin
	var steer := not ship.animator.isTransitioning()
	var h := Input.get_axis("Left", "Right") if steer else 0.0
	var f := Input.get_axis("Forward", "Backward") if steer else 0.0 # -1 = forward / up
	var dir := Vector3.ZERO
	var turnTarget := _facing

	match FlightMode:
		FlightModes.Forward:
			dir = Vector3(h, -f, 0)
			turnTarget = 0
		FlightModes.SideScroller:
			dir = Vector3(0, -f, -h)
			turnTarget = 0
		FlightModes.SideFire:
			dir = Vector3(0, -f, -h)
			turnTarget = deg_to_rad(35)
		FlightModes.TopDown:
			dir = Vector3(h, 0, f)
			if dir.length() > 0.1:
				_facing = atan2(-dir.x, -dir.z)
			turnTarget = _facing

	dir = dir.limit_length(1.0)

	_updateBoost(Input.is_action_pressed("Boost") and not dir.is_zero_approx(), delta)

	# Same snappy easing as before, but on origin-relative velocity
	var speed := MaxSpeed * lerpf(1.0, BoostMultiplier, boost)
	var t := 1.0 - exp(-Acceleration * delta)
	_relVel = _relVel.lerp(dir * speed, t)
	_relVel = _limitRelVelocity(_relVel, delta)
	_rel += _relVel * delta

	# Unused axis: slide to 0 and hold
	if _pinAxis >= 0:
		var v: float = lerpf(_rel[_pinAxis], 0.0, 1.0 - exp(-8.0 * delta))
		_rel[_pinAxis] = 0.0 if absf(v) < 0.02 else v
		_relVel[_pinAxis] = 0.0

	# Frozen ship: position is purely origin + offset
	ship.global_position = _originPos() + _rel
	# Reported for collision damage math and UI
	ship.linear_velocity = _relVel + _originVelocity()

	var yawDiff := angle_difference(ship.rotation.y, turnTarget)
	_yawVel = lerpf(_yawVel, yawDiff * TurnRate, 0.5)
	ship.rotation.y += _yawVel * delta

	# Visual speed values
	var local := ship.linear_velocity.rotated(Vector3.UP, -ship.rotation.y)
	ship.SpeedForward = local.z / 100
	ship.SpeedStrafe = -local.x / 100
	ship.SpeedVert = -ship.linear_velocity.y / 100
	ship.SpeedYaw = -yawDiff * 1.5
