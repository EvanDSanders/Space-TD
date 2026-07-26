@icon("res://EditorIcons/starShip.svg")
extends RigidBody3D

# Speed stores for Maneuvering mode (local to ship)
var SpeedForward 	: float = 0.
var SpeedStrafe 	: float = 0.
var SpeedYaw		: float = 0.
var SpeedVert		: float = 0.

@export var faceWithCamera = false

@onready var Bones : Skeleton3D = $"Star Ship/Brmature/Skeleton3D"

	
@onready var EngineL = Bones.find_bone('Engine.Hub.L')
@onready var EngineR = Bones.find_bone('Engine.Hub.R')

@onready var EngineBaseL = Bones.find_bone('Engine.Frame.L')
@onready var EngineBaseR = Bones.find_bone('Engine.Frame.R')

@onready var EngineBoostL = Bones.find_bone('Engine.Boost.L')
@onready var EngineBoostR = Bones.find_bone('Engine.Boost.R')


@onready var EngineDisks = []
@onready var EngineTurbines = []
@onready var EngineFlaps = []

var _turbineAngle := 0.0

@onready var EngineTurnRegEx : RegEx = RegEx.create_from_string("Engine.[A-D].I.[LR]")
@onready var EnginePostRegEx : RegEx = RegEx.create_from_string("Engine.[A-D].[LR]")

enum ShipModes {
	Build,
	Maneuver,
	Warp,	
	Evasion,
};

@export var ShipMode: ShipModes = ShipModes.Maneuver
@onready var ShipModePrior = ShipModes.Maneuver

var ETw : Tween

# See function AxisMovment()
var movementScale := 100
var movementClamp := 0.5

var movementScaleYaw := 50
var movementClampYaw := 0.5


#@onready var EngineTrailLoader = preload("res://Scenes/Ship/StarShipEngineTrail.tscn")
@onready var ShieldMat : ShaderMaterial = load("res://Materials/Shield.tres")
var MeshI3Ds : Array[MeshInstance3D]

@export var TargetingRange: int = 160
@onready var Turrets := [
		$"Star Ship/TurretF",
		$"Star Ship/TurretL",
		$"Star Ship/TurretR"
]

@onready var health: ShieldedDestructible = find_child("Destructible")
@onready var mana: ManaStore = find_child("ManaStore")
@onready var crystal: CrystalStore = find_child("CrystalStore")

# True while LClick held, but only when press wasn't first consumed by a Control (GUI).
var FiringInput: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if G.isBuilding:
		FiringInput = false
		return
	if event.is_action_pressed("LClick"):
		FiringInput = true
		get_viewport().set_input_as_handled()
	elif event.is_action_released("LClick"):
		FiringInput = false

func updateHull(float):
	for i in MeshI3Ds:
		if not i: continue
		i.set_instance_shader_parameter("DamageScale", G.remap(0, health.HPMax, 1, 0, health.HP))


	


# Custom condition check for Ship's turrets (it doesn't work for some reason)
func TurretCheck() -> bool:
	for each in Turrets:
		if not each.Aimed:
			return false
	return true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for x in range(Bones.get_bone_count()):
		var BName : String = Bones.get_bone_name( x )
		# print(BName)
		# Add engine posts to list
		if EngineTurnRegEx.search(BName):
			EngineDisks.append(x)
			
		#if EnginePostRegEx.search(BName):
			# And add mesh trails to them
			#var trail: BoneAttachment3D = EngineTrailLoader.instantiate()
			#Bones.add_child(trail)
			#trail.bone_idx = x
		
		if "Engine.Inlet." in BName:
			EngineTurbines.append(x) 
			
		if "Engine.Flap." in BName:
			EngineFlaps.append(x)
			
	
	
	# Move StarShip Turrets onto the ship's rotating body
	$"Star Ship/TurretF".reparent($"Star Ship/Brmature/Skeleton3D/Frame/TTR Front")
	$"Star Ship/TurretL".reparent($"Star Ship/Brmature/Skeleton3D/Engine_Frame_L/TTR Left")
	$"Star Ship/TurretR".reparent($"Star Ship/Brmature/Skeleton3D/Engine_Frame_R/TTR Right")
	$"Star Ship/Main Cannon".reparent($"Star Ship/Brmature")
	
	# Set turrets targeting origin and extra condition to these
	for T in Turrets:
		T.RangingOrigin = self
		#T.TargetingRange = self.TargetingRange
		T.scanArea3D = $ScanArea3D
		#T.mana.showMeter = false
		T.get_node("CursorDialogue").Parent = self
		#T.ExtraFiringCondition = TurretCheck
	
	for each: MeshInstance3D in find_children("*", "MeshInstance3D"):
		each.set_instance_shader_parameter("StarShipEngineOverheatIsThis", 1)
		if each.name != "Circle 019":
			each.set_instance_shader_parameter("ObjGPos", each.global_position)
			each.material_overlay = ShieldMat
		MeshI3Ds.append(each)

	gravity_scale = 0
	linear_damp = 0
	angular_damp = 0
	axis_lock_angular_x = true
	axis_lock_angular_z = true
	
	self.body_shape_entered.connect(self.collide)
	self.health.HPChange.connect(self.updateHull)
	
	var v = Vector3.ONE * 0.001
	G.BoneScaled(Bones, EngineBoostL, v)
	G.BoneScaled(Bones, EngineBoostR, v)
	
	health.ShieldChange.connect( func(V:float): writeShader(G.remap(0, health.ShieldMax, 0, 1, V), "StarShipShieldV") )

	for part: GPUParticles3DFix in find_children("*Smoke*", "GPUParticles3DFix"):
		part.visible = true; part.emitting = false


	E.Register(self, E.Friend)

# For slow and acurate, per-axis movent
func AxisMovment(DirectionVar: StringName, AxisA: StringName, AxisB: StringName, delta: float):
	var speed := 0.
	if (not ETw or not ETw.is_running()) and ShipMode == ShipModes.Maneuver:
		speed = Input.get_axis(AxisA, AxisB)
		
	var moveScale = movementScale if not DirectionVar == "SpeedYaw" else movementScaleYaw
	var moveClamp = movementClamp if not DirectionVar == "SpeedYaw" else movementClampYaw
		
	if not is_zero_approx(speed): # Input: Speed up
		self.set(DirectionVar, (self.get(DirectionVar)*moveScale + (speed*2))/moveScale)
		
	else: # No input: slow down
		speed = self.get(DirectionVar)*moveScale
		var speedABS = abs(speed)
		
		speed += clamp(speedABS, 0,1) * (-1 if speed > 0 else 1)
		#if Print: print("%f, %f" % [speed, speedABS])
		
		self.set(DirectionVar, speed/moveScale)
		
	self.set( DirectionVar, clamp(self.get(DirectionVar), -moveClamp, moveClamp) )
	

func BoneRotate(bone_idx:int, axis:String, angle:float):
	# Apply rotation in bone's local space using the specified axis.
	var pose = Bones.get_bone_pose(bone_idx)
	match axis:
		"X":
			pose.basis = pose.basis.rotated(Vector3(1,0,0), angle)
		"Y":
			pose.basis = pose.basis.rotated(Vector3(0,1,0), angle)
		"Z":
			pose.basis = pose.basis.rotated(Vector3(0,0,1), angle)
	Bones.set_bone_pose(bone_idx, pose)


func BoneRotated(bone_idx:int, rotation:Vector3):
	# Set the bone's rotation directly in XYZ axes (local space).
	var pose = Bones.get_bone_pose(bone_idx)
	pose.basis = Basis.from_euler(rotation)
	Bones.set_bone_pose(bone_idx, pose)


# Settings for each Ship Mode
var ShipModeSets: Array[Dictionary] = [
	{
		"Name": "Construction Anchor", 
		"Brightness": 1, 
		"Color": Color.CHARTREUSE, 
	}, {
		"Name": "High Precision Maneuver", 
		"Brightness": 1, 
		"Color": Color.DODGER_BLUE, 
	}, {
		"Name": "Warp Drive", 
		"Brightness": 1, 
		"Color": Color.FUCHSIA, 
	}, {
		"Name": "Evasion & Combat", 
		"Brightness": 2, 
		"Color": Color.YELLOW, 
	}, 
]

# Tween function for setting global shader props
func writeShader(val, str: String):
	RenderingServer.global_shader_parameter_set(str, val)
	
# Tween function to rotate engine flaps
func writeFlaps(amt:float):
	for flap in EngineFlaps:
		BoneRotated(flap, Vector3(-amt*0.8, 0, 0))



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	
	
	#$MeshInstance3D.global_position = Vector3(sin(Time.get_ticks_msec()/100), 20, cos(Time.get_ticks_msec()/100)) * 2
	if health.isAlive:
		
	
		if ShipMode != ShipModePrior:
			# print(ShipMode, " <- ", ShipModePrior)
			# Reset Tween
			if ETw: ETw.kill()
			ETw = self.create_tween()
			# Start Tweening
			ETw.tween_method(writeShader.bind("StarShipEngineColor"), ShipModeSets[ShipModePrior]["Color"], ShipModeSets[ShipMode]["Color"], 1.0)
			ETw.parallel() # Allow multiple effects at once
			ETw.tween_method(writeShader.bind("StarShipEngineBrightness"), ShipModeSets[ShipModePrior]["Brightness"], ShipModeSets[ShipMode]["Brightness"], 1.0)
			ETw.parallel()
			ETw.tween_method(writeFlaps, float(ShipModePrior == ShipModes.Evasion), float(ShipMode == ShipModes.Evasion), 1.0)
		
			ShipModePrior = ShipMode

		# Atchtedic rotation (Vertical Tilt, 0, Horizontal Tilt)
		$"Star Ship".rotation = Vector3(-SpeedVert/12, 0, -SpeedYaw/12 + SpeedStrafe/12)

		# Rotate engines
		BoneRotate(EngineL, "Y", ( SpeedForward + SpeedStrafe) * delta * 3)
		BoneRotate(EngineR, "Y", (-SpeedForward + SpeedStrafe) * delta * 3)
		for each in EngineDisks:
			BoneRotate(each, "Y", -SpeedYaw * delta * 5 / 2)

		# Turbines: accumulate angle as a float, set absolute rotation to avoid basis drift
		_turbineAngle = fmod(_turbineAngle + 2.0, TAU)
		BoneRotated(EngineTurbines[0], Vector3(0, -_turbineAngle, 0))
		BoneRotated(EngineTurbines[1], Vector3(0,  _turbineAngle, 0))

	else:
		#if not spawnBoomRNG: spawnBoomRNG = RandomNumberGenerator.new()
		#if spawnBoomRNG.randf() < 1.0 - pow(1.0 - spawnBoomChance, delta):
		if spawnBoomCoolDown <= 0:
			spawnBoomCoolDown = spawnBoomDelay
			var x = 4 / 2.
			var y = 2 / 2.
			var z = 3 / 2.
			var pos = Vector3(randf_range(-x,x), randf_range(-y,y), randf_range(-z,z))
			
			var boom : Node3D = spawnBoomLoader.instantiate()
			self.add_child(boom)
			boom.position = pos*10
		
		spawnBoomCoolDown -= delta

var CameraHeading : float

var spawnBoomDelay := 1.
var spawnBoomCoolDown := spawnBoomDelay
var spawnBoomLoader = preload("res://Scenes/Misc/ExplosionMagic.tscn")


func destroy(): 
	self.axis_lock_linear_y = false
	self.axis_lock_angular_x = false
	self.axis_lock_angular_z = false
	self.linear_damp = false
	self.angular_damp = false
	var r = 20000
	self.apply_torque_impulse(Vector3(randf_range(-r,r), randf_range(-r,r), randf_range(-r,r)))
	
	#for T in Turrets:
		#T.health.Hit(1111)
	
	# Reset Tween
	if ETw: ETw.kill()
	ETw = self.create_tween()
	# Start Tweening
	ETw.tween_method(writeShader.bind("StarShipEngineColor"), ShipModeSets[ShipMode]["Color"], Color.DIM_GRAY, 1.0)
	ETw.parallel() # Allow multiple effects at once
	ETw.tween_method(writeShader.bind("StarShipEngineBrightness"), ShipModeSets[ShipMode]["Brightness"], 0.2, 1.0)
	ETw.parallel() # Allow multiple effects at once
	ETw.tween_property(self, "spawnBoomDelay", .1, 5)
	
	G.schedule(deathEnd, 8)
	
	

func deathEnd():
	var boom : Node3D = spawnBoomLoader.instantiate()
	self.add_child(boom)
	boom.scale *= 6
	self.spawnBoomDelay = INF
	self.linear_velocity = Vector3.ZERO
	$"Star Ship".scale = Vector3.ZERO

	G.schedule(get_tree().quit, 4)



var boost: float = 0.
var boostActive := false
var BTw : Tween
var engineHeat := 0.

@export var EngineColors : Gradient
var crystalFab := 0.0


func _physics_process(delta: float) -> void:
	if not health.isAlive: return
	
	crystalFab += delta * 1.25
	if crystalFab > 1: 
		crystalFab -= 1
		crystal.pushCrystal(1)
	
	match ShipMode:
		ShipModes.Evasion:
			if not ETw or ETw.is_running(): return
			
			var heading := CameraHeading
			var headingCam := heading
			
			# Get inputs
			var f = Input.get_axis("Forward", "Backward")
			var s = Input.get_axis("Left", "Right")
			
			if f < 0 and Input.is_action_pressed("Boost"):
				if not boostActive:
					boostActive = true
					if BTw: BTw.kill(); 
					BTw = create_tween()
					BTw.tween_property(self, "boost", 1., .2)
			else:
				if boostActive:
					boostActive = false
					if BTw: BTw.kill(); 
					BTw = create_tween()
					BTw.tween_property(self, "boost", 0., .2)
			
			var b = G.remap(0, 1, 1, 2.2, boost) 
			
			var B = clamp(boost, 0.001, 1)
			
			engineHeat += G.remap(0, 1, -.5, 1, boost) * delta
			engineHeat = clamp(engineHeat, 0, 10)
			writeShader(EngineColors.sample(engineHeat/6), 'StarShipEngineColor')
			
			G.BoneScaled(Bones, EngineBoostL, Vector3(B,B,B))
			G.BoneScaled(Bones, EngineBoostR, Vector3(B,B,B))
			
			# Convert them to a global Vector3f
			var v = Vector3(
				f * b * sin(heading) + s * cos(heading),
				0,
				f * b * cos(heading) + s * sin(-heading),
			)
			$"../../Label".text = "%f" % [engineHeat]
			writeShader(clamp(G.remap(3,6, 0,1, engineHeat), 0, 1), "StarShipEngineOverheat")
			if engineHeat > 6:
				health.Hit( G.remap(6, 10, 0, 20*delta, engineHeat), Vector3.ZERO, true)
			
			# If not facing camera, aim ship at its actual velocity heading instead
			if not self.faceWithCamera and not is_zero_approx(linear_velocity.length()):
				headingCam = atan2(-linear_velocity.x, -linear_velocity.z)

			# Rotate the ship: steer towards target heading instead of
			# hard-setting angular_velocity, so a collision's spin isn't
			# stomped out on the very next frame
			var y = angle_difference(self.rotation.y, headingCam) / 35
			angular_velocity.y = lerp(angular_velocity.y, y / delta, 0.1)
			# Set the per-axis methods to show to visuals
			SpeedYaw = y*-movementScaleYaw


			# Scale down and add velocity directly onto RigidBody's velocity,
			# so collisions (which also act on linear_velocity) aren't stomped
			linear_velocity += v * 0.1 / delta
			linear_velocity *= 0.98 # Drag

			# Set the per-axis methods to show to visuals
			SpeedForward = linear_velocity.rotated(Vector3.UP, -self.rotation.y).z / 100
			SpeedStrafe = -linear_velocity.rotated(Vector3.UP, -self.rotation.y).x / 100
			
		_:
			# Use per-axis methods to move ship
			AxisMovment( "SpeedForward", "Forward", "Backward", delta )
			AxisMovment( "SpeedStrafe", "Right", "Left", delta )
			#AxisMovment( "SpeedVert", "Up", "Down", delta )
			AxisMovment( "SpeedYaw", "YawLeft", "YawRight", delta )
			
			# Move the ship
			linear_velocity = basis * Vector3(-SpeedStrafe, -SpeedVert, SpeedForward) / delta
			angular_velocity.y = -SpeedYaw/(180/PI) / delta
			
	
func collide(body_rid: RID, body: Node, body_shape_index: int, local_shape_index: int):
	var S1 : Vector3 = self.linear_velocity
	var S2 : Vector3 = body.linear_velocity if body.get("linear_velocity") else Vector3.ZERO
	var rate = S1.distance_to(S2)
	var dmg = G.remap(5, 20, 0, 1, rate)
	self.health.Hit(dmg/20)
	if body.has_node("Destructible"):
		body.get_node("Destructible").Hit(dmg*10)
		
	#print(self.name, " at ", S1.length(),  " m/s hit ", body.name, " at ", S2.length(), " m/s")
	
	
