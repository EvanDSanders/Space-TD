extends Node3D

@export var CamFlip := true
@export var CamIsShip := true

#@onready var Target := $"../The Star Ship".find_child("Brmature")
@onready var Target := $".."



func _process(_delta: float) -> void:
	if not Target:
		return

	if Input.is_action_just_pressed("CamSwap"):
		if CamFlip:
			_prepare_follow_plane(Target)
		else:
			_prepare_free_orbit(Target)
		CamFlip = not CamFlip
		
		
	if Input.is_action_just_pressed("CamSwitch"):
		if CamIsShip:
			Target = $"../The Star Ship"
		else:
			Target = $".."
		CamIsShip = not CamIsShip


	if CamFlip:
		global_position = Target.global_position
	else:
		global_transform = Target.global_transform



func _pivot() -> Node3D:
	return get_child(0) as Node3D


func _global_look() -> Vector3:
	var pivot := _pivot()
	if not pivot:
		return -global_transform.basis.z
	return -(global_transform.basis * pivot.basis).z.normalized()


func _flat_horizontal(v: Vector3) -> Vector3:
	var flat := Vector3(v.x, 0.0, v.z)
	return flat.normalized() if flat.length_squared() > 0.0001 else Vector3(0.0, 0.0, -1.0)


func _pitched_look(flat: Vector3, pitch: float) -> Vector3:
	return Vector3(flat.x * cos(pitch), sin(pitch), flat.z * cos(pitch)).normalized()


func _sync_camera_angles(pivot: Node3D) -> void:
	if pivot.has_method("apply_orbit_angles"):
		var euler := pivot.basis.get_euler(EULER_ORDER_YXZ)
		pivot.apply_orbit_angles(euler.y, euler.x)


func _prepare_free_orbit(_plane: Node3D) -> void:
	var look := _global_look()
	var flat := _flat_horizontal(look)
	var pitch := asin(clampf(look.y, -1.0, 1.0))
	var hub_yaw := Basis.from_euler(Vector3(0.0, atan2(flat.x, -flat.z), 0.0), EULER_ORDER_YXZ)
	global_transform = Transform3D(hub_yaw, global_position)

	var pivot := _pivot()
	if not pivot:
		return

	pivot.basis = hub_yaw.inverse() * Basis.looking_at(_pitched_look(flat, pitch), Vector3.UP)
	_sync_camera_angles(pivot)


func _prepare_follow_plane(Target: Node3D) -> void:
	var pivot := _pivot()
	if not pivot:
		return

	var look := _global_look()
	var flat := _flat_horizontal(look)
	var pitch := asin(clampf(look.y, -1.0, 1.0))
	pivot.basis = Target.global_transform.basis.inverse() * Basis.looking_at(
		_pitched_look(flat, pitch), Vector3.UP
	)
	_sync_camera_angles(pivot)
