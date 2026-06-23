extends Node3D

enum NavMode { NONE, ORBIT, PAN }

@export var camera: Camera3D
@export var orbit_sensitivity := 0.005
@export var pan_sensitivity := 0.1
@export var zoom_sensitivity := 1.5
@export var controller_orbit_speed := 200 * 2
@export var controller_zoom_speed := 400 * 2
@export var min_distance := 0.1

var _nav_mode := NavMode.NONE
var _camera: Camera3D
var _yaw := 0.0
var _pitch := 0.0
var _distance := 1.0


func _ready() -> void:
	_camera = camera if camera else _find_camera()
	_sync_from_transform()
	
	G.camera = $Camera3D


func _process(delta: float) -> void:
	if not _camera:
		return
	_handle_controller(delta)
	_apply_pivot_rotation()
	_apply_camera_distance()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_MIDDLE:
				if event.pressed:
					_nav_mode = NavMode.PAN if event.shift_pressed else NavMode.ORBIT
				else:
					_nav_mode = NavMode.NONE
				get_viewport().set_input_as_handled()
			MOUSE_BUTTON_WHEEL_UP:
				_dolly(event.factor)
				get_viewport().set_input_as_handled()
			MOUSE_BUTTON_WHEEL_DOWN:
				_dolly(-event.factor)
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _nav_mode != NavMode.NONE:
		match _nav_mode:
			NavMode.ORBIT:
				_orbit(event.relative)
			NavMode.PAN:
				_pan(event.relative)
		get_viewport().set_input_as_handled()


func _find_camera() -> Camera3D:
	for child in get_children():
		if child is Camera3D:
			return child
	return null


func _handle_controller(delta: float) -> void:
	var orbit_x := Input.get_action_strength("CamRight") - Input.get_action_strength("CamLeft")
	var orbit_y := Input.get_action_strength("CamDown") - Input.get_action_strength("CamUp")
	if orbit_x != 0.0 or orbit_y != 0.0:
		_orbit(Vector2(orbit_x, orbit_y) * controller_orbit_speed * delta)

	var zoom := Input.get_action_strength("CamOut") - Input.get_action_strength("CamIn")
	if zoom != 0.0:
		_dolly(zoom * controller_zoom_speed * delta)


func _orbit(relative: Vector2) -> void:
	_yaw -= relative.x * orbit_sensitivity
	_pitch -= relative.y * orbit_sensitivity
	_pitch = clampf(_pitch, deg_to_rad(-89.0), deg_to_rad(89.0))


func _pan(relative: Vector2) -> void:
	position += basis.x * -relative.x * pan_sensitivity
	position += basis.y * relative.y * pan_sensitivity


func _dolly(factor: float) -> void:
	_distance -= factor * zoom_sensitivity
	_distance = maxf(_distance, min_distance)


func _sync_from_transform() -> void:
	if not _camera:
		return
	var look := -_camera.global_transform.basis.z
	var pivot_parent := get_parent() as Node3D
	if pivot_parent:
		look = pivot_parent.global_transform.basis.inverse() * look
	look.y = clampf(look.y, -1.0, 1.0)
	_yaw = atan2(look.x, -look.z)
	_pitch = asin(look.y)
	_distance = maxf(_camera.position.length(), min_distance)


func _apply_pivot_rotation() -> void:
	basis = Basis.from_euler(Vector3(_pitch, _yaw, 0.0), EULER_ORDER_YXZ)


func apply_orbit_angles(yaw: float, pitch: float) -> void:
	_yaw = yaw
	_pitch = clampf(pitch, deg_to_rad(-89.0), deg_to_rad(89.0))
	_apply_pivot_rotation()


func _apply_camera_distance() -> void:
	_camera.position = Vector3(0.0, 0.0, _distance)
	_camera.rotation = Vector3.ZERO
