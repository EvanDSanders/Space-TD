extends Node
class_name StarShipAnimator

var ship: TheStarShip

var Bones: Skeleton3D

var EngineL: int
var EngineR: int
var EngineBoostL: int
var EngineBoostR: int

var EngineDisks: Array[int] = []
var EngineTurbines: Array[int] = []
var EngineFlaps: Array[int] = []

var MeshI3Ds: Array[MeshInstance3D] = []

var _turbineAngle := 0.0

var EngineTurnRegEx: RegEx = RegEx.create_from_string("Engine.[A-D].I.[LR]")

# Engine look per ship mode, indexed by TheStarShip.ShipModes
var ModeSets: Array[Dictionary] = [
	{"Brightness": 1., "Color": Color.CHARTREUSE, "Flaps": false}, # Build
	{"Brightness": 1., "Color": Color.FUCHSIA, "Flaps": false},    # Warp
	{"Brightness": 2., "Color": Color.YELLOW, "Flaps": true},      # Fighter
]

var ETw: Tween
var ShieldMat: ShaderMaterial = load("res://Materials/Shield.tres")

var spawnBoomDelay := 1.
var spawnBoomCoolDown := spawnBoomDelay
var spawnBoomLoader = preload("res://Scenes/Misc/ExplosionMagic.tscn")

var _modePrior: int = -1


func setup(p_ship: TheStarShip) -> void:
	ship = p_ship
	Bones = ship.get_node("Star Ship/Brmature/Skeleton3D")

	EngineL = Bones.find_bone('Engine.Hub.L')
	EngineR = Bones.find_bone('Engine.Hub.R')
	EngineBoostL = Bones.find_bone('Engine.Boost.L')
	EngineBoostR = Bones.find_bone('Engine.Boost.R')

	for x in range(Bones.get_bone_count()):
		var BName: String = Bones.get_bone_name(x)
		if EngineTurnRegEx.search(BName):
			EngineDisks.append(x)
		if "Engine.Inlet." in BName:
			EngineTurbines.append(x)
		if "Engine.Flap." in BName:
			EngineFlaps.append(x)

	for each: MeshInstance3D in ship.find_children("*", "MeshInstance3D"):
		each.set_instance_shader_parameter("StarShipEngineOverheatIsThis", 1)
		if each.name != "Circle 019":
			each.set_instance_shader_parameter("ObjGPos", each.global_position)
			each.material_overlay = ShieldMat
		MeshI3Ds.append(each)

	var v := Vector3.ONE * 0.001
	G.BoneScaled(Bones, EngineBoostL, v)
	G.BoneScaled(Bones, EngineBoostR, v)

	ship.health.HPChange.connect(updateHull)
	ship.health.ShieldChange.connect(func(V: float): writeShader(G.remap(0, ship.health.ShieldMax, 0, 1, V), "StarShipShieldV"))

	for part: GPUParticles3DFix in ship.find_children("*Smoke*", "GPUParticles3DFix"):
		part.visible = true
		part.emitting = false


func updateHull(_hp) -> void:
	for i in MeshI3Ds:
		if not i: continue
		i.set_instance_shader_parameter("DamageScale", G.remap(0, ship.health.HPMax, 1, 0, ship.health.HP))


func writeShader(val, strng: String) -> void:
	RenderingServer.global_shader_parameter_set(strng, val)


func writeFlaps(amt: float) -> void:
	for flap in EngineFlaps:
		BoneRotated(flap, Vector3(-amt * 0.8, 0, 0))


func BoneRotate(bone_idx: int, axis: String, angle: float) -> void:
	var pose = Bones.get_bone_pose(bone_idx)
	match axis:
		"X": pose.basis = pose.basis.rotated(Vector3(1, 0, 0), angle)
		"Y": pose.basis = pose.basis.rotated(Vector3(0, 1, 0), angle)
		"Z": pose.basis = pose.basis.rotated(Vector3(0, 0, 1), angle)
	Bones.set_bone_pose(bone_idx, pose)


func BoneRotated(bone_idx: int, rotation: Vector3) -> void:
	var pose = Bones.get_bone_pose(bone_idx)
	pose.basis = Basis.from_euler(rotation)
	Bones.set_bone_pose(bone_idx, pose)


func isTransitioning() -> bool:
	return ETw != null and ETw.is_running()


# Tween engine color / brightness / flaps to the look of the new mode
func transitionTo(mode: int) -> void:
	var to: Dictionary = ModeSets[mode]
	var from: Dictionary = ModeSets[_modePrior if _modePrior >= 0 else mode]
	if ETw: ETw.kill()
	ETw = create_tween()
	ETw.tween_method(writeShader.bind("StarShipEngineColor"), from["Color"], to["Color"], 1.0)
	ETw.parallel()
	ETw.tween_method(writeShader.bind("StarShipEngineBrightness"), from["Brightness"], to["Brightness"], 1.0)
	ETw.parallel()
	ETw.tween_method(writeFlaps, float(from["Flaps"]), float(to["Flaps"]), 1.0)
	_modePrior = mode


func setBoostScale(s: float) -> void:
	var B := clampf(s, 0.001, 1.0)
	G.BoneScaled(Bones, EngineBoostL, Vector3(B, B, B))
	G.BoneScaled(Bones, EngineBoostR, Vector3(B, B, B))


func _process(delta: float) -> void:
	if not ship or not ship.health.isAlive:
		_deathProcess(delta)
		return

	# Tilt (Vertical Tilt, 0, Horizontal Tilt)
	ship.get_node("Star Ship").rotation = Vector3(-ship.SpeedVert / 12, 0, -ship.SpeedYaw / 12 + ship.SpeedStrafe / 12)

	BoneRotate(EngineL, "Y", (ship.SpeedForward + ship.SpeedStrafe) * delta * 3)
	BoneRotate(EngineR, "Y", (-ship.SpeedForward + ship.SpeedStrafe) * delta * 3)
	for each in EngineDisks:
		BoneRotate(each, "Y", -ship.SpeedYaw * delta * 5 / 2)

	# Absolute rotation avoids basis drift
	_turbineAngle = fmod(_turbineAngle + 2.0, TAU)
	BoneRotated(EngineTurbines[0], Vector3(0, -_turbineAngle, 0))
	BoneRotated(EngineTurbines[1], Vector3(0, _turbineAngle, 0))


func _deathProcess(delta: float) -> void:
	if not ship or ship.health.isAlive: return
	if spawnBoomCoolDown <= 0:
		spawnBoomCoolDown = spawnBoomDelay
		var pos := Vector3(randf_range(-2, 2), randf_range(-1, 1), randf_range(-1.5, 1.5))
		var boom: Node3D = spawnBoomLoader.instantiate()
		ship.add_child(boom)
		boom.position = pos * 10
	spawnBoomCoolDown -= delta


func playDeath() -> void:
	var cur: Dictionary = ModeSets[ship.ShipMode]
	if ETw: ETw.kill()
	ETw = create_tween()
	ETw.tween_method(writeShader.bind("StarShipEngineColor"), cur["Color"], Color.DIM_GRAY, 1.0)
	ETw.parallel()
	ETw.tween_method(writeShader.bind("StarShipEngineBrightness"), cur["Brightness"], 0.2, 1.0)
	ETw.parallel()
	ETw.tween_property(self, "spawnBoomDelay", .1, 5)
	G.schedule(deathEnd, 8)


func deathEnd() -> void:
	var boom: Node3D = spawnBoomLoader.instantiate()
	ship.add_child(boom)
	boom.scale *= 6
	spawnBoomDelay = INF
	ship.linear_velocity = Vector3.ZERO
	ship.angular_velocity = Vector3.ZERO
	ship.get_node("Star Ship").scale = Vector3.ZERO
	ship.visible = false
	G.Main.gameOver.Expand()
