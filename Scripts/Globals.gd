extends Node


@onready var root: Window = $"/root"
var Warnings : WarningInterface

var Camera: RiggedCamera
var camera: RiggedCamera:
	set(c): Camera = c
	get(): return Camera


@onready var RNG := RandomNumberGenerator.new() 

var StarShip: TheStarShip
var StarStation: Prospector
var isMainLevel: bool

var Main: Node3D
var Cursor: Node3D

var Enemies: Marker3D
var Collectibles: Marker3D
var Ores: Marker3D
var Friendlies: Marker3D

var MegaSheild : Node3D
var MegaLaser  : Node3D

var EnemySpawner : SpawnerResource

func setUp(main):
	Main = main
	camera = Main.find_child("Camera3D")
	Cursor = Main.get_node("Cursor")
	StarShip = Main.get_node("Friendlies/The Star Ship")

	Enemies = Main.get_node("Enemies")
	Collectibles = Main.get_node("Collectibles")
	Ores = Main.get_node("Ores")
	Friendlies = Main.get_node("Friendlies")

var isBuilding := false


# https://gist.github.com/laundmo/b224b1f4c8ef6ca5fe47e132c8deab56
func lerp(a: float, b: float, t: float) -> float:
	"""Linear interpolate on the scale given by a to b, using t as the point on that scale.
	Examples
	--------
		50 == lerp(0, 100, 0.5)
		4.2 == lerp(1, 5, 0.8)
	"""
	return (1 - t) * a + t * b


func inv_lerp(a: float, b: float, v: float) -> float:
	"""Inverse Linar Interpolation, get the fraction between a and b on which v resides.
	Examples
	--------
		0.5 == inv_lerp(0, 100, 50)
		0.8 == inv_lerp(1, 5, 4.2)
	"""
	return (v - a) / (b - a)


func remap(i_min: float, i_max: float, o_min: float, o_max: float, v: float) -> float:
	"""Remap values from one linear scale to another, a combination of lerp and inv_lerp.
	i_min and i_max are the scale on which the original value resides,
	o_min and o_max are the scale to which it should be mapped.
	Examples
	--------
		45 == remap(0, 100, 40, 50, 50)
		6.2 == remap(1, 5, 3, 7, 4.2)
	"""
	return lerp(o_min, o_max, inv_lerp(i_min, i_max, v))

# https://github.com/nealholt/TargetLeadExample/blob/main/Scripts/gun.gd
func get_intercept(shooter_pos:Vector3,
					bullet_speed:float,
					target_position:Vector3,
					target_velocity:Vector3,
					shooter_velocity:=Vector3.ZERO) -> Vector3:
						
	var relitive := target_velocity - shooter_velocity
	
	var a:float = bullet_speed*bullet_speed - relitive.dot(relitive)
	var b:float = 2*relitive.dot(target_position-shooter_pos)
	var c:float = (target_position-shooter_pos).dot(target_position-shooter_pos)
	# Protect against divide by zero and/or imaginary results
	# which occur when bullet speed is slower than target speed
	var time:float = 0.0
	if bullet_speed > relitive.length():
		time = (b+sqrt(b*b+4*a*c)) / (2*a)
	return target_position+time*relitive




## https://easings.net/ [br]
## Cubic easing in/out - acceleration until halfway, then deceleration. [br][br]
## Examples [br]
## [code]
##	0.5 == easeInOutCubic(0.5)
## 	0.896 == easeInOutCubic(0.8)
## [/code]
func EaseIOCubic(x: float) -> float:
	if x < 0.5:
		return 4 * x * x * x
	else:
		return 1 - pow(-2 * x + 2, 3) / 2

# https://medium.com/@fionn.fuchs/easily-call-a-method-after-a-time-delay-in-godot-ee8593d5ef5b
func schedule(function, delay):
	var timer := Timer.new()
	Main.add_child(timer)
	timer.timeout.connect(function)
	timer.timeout.connect(timer.queue_free)
	timer.wait_time = delay
	timer.start()
	




var loadMagicExplosion = preload("res://Scenes/Misc/ExplosionMagic.tscn")
var loadSciFiExplosion = preload("res://Scenes/Misc/ExplosionSciFi.tscn")

enum ExplType {Magic, SciFi}

func spawnExplosion( explosion_type: ExplType, caller: Node3D, parent: Node3D = G.Main, scale: float = 1.0, pos: Vector3 = Vector3.ZERO, local := false ):
	var boomL : Resource
	match explosion_type:
		ExplType.Magic: boomL = loadMagicExplosion
		ExplType.SciFi: boomL = loadSciFiExplosion
		
	var boom : Node3D = boomL.instantiate()
	parent.add_child(boom)
	if local:
		boom.position = caller.to_local(pos)
	else: 
		boom.position = caller.to_global(pos)
	boom.scale = Vector3.ONE * scale

func spawnExplosionAndFree( explosion_type: ExplType, caller: Node3D, parent: Node3D = G.Main, scale: float = 1.0, pos: Vector3 = Vector3.ZERO ):
	spawnExplosion( explosion_type, caller, parent, scale, pos )
	caller.queue_free()





func BoneRotate(armature: Skeleton3D, bone_idx:int, axis:String, angle:float):
	# Apply rotation in bone's local space using the specified axis.
	var pose = armature.get_bone_pose(bone_idx)
	match axis:
		"X":
			pose.basis = pose.basis.rotated(Vector3(1,0,0), angle)
		"Y":
			pose.basis = pose.basis.rotated(Vector3(0,1,0), angle)
		"Z":
			pose.basis = pose.basis.rotated(Vector3(0,0,1), angle)
	armature.set_bone_pose(bone_idx, pose)


func BoneRotated(armature: Skeleton3D, bone_idx:int, rotation:Vector3):
	# Set the bone's rotation directly in XYZ axes (local space).
	var pose = armature.get_bone_pose(bone_idx)
	pose.basis = Basis.from_euler(rotation)
	armature.set_bone_pose(bone_idx, pose)


func BoneScaled(armature: Skeleton3D, bone_idx:int, scale:Vector3):
	# Set bone's scale, keep existing rotation.
	var pose = armature.get_bone_pose(bone_idx)
	pose.basis = pose.basis.orthonormalized().scaled(scale)
	armature.set_bone_pose(bone_idx, pose)

func setGameSpeed(rate:float):
	if rate == 0.0: 
		rate = 1.0
		get_tree().paused = true
	else: 
		get_tree().paused = false
	Engine.time_scale = rate
	Engine.physics_ticks_per_second = 60 * int(rate)

func _ready(): pass
