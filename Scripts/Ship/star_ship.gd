extends RigidBody3D

# Speed stores for Maneuvering mode (local to ship)
var SpeedForward 	: float = 0.
var SpeedStrafe 	: float = 0.
var SpeedYaw		: float = 0.
var SpeedVert		: float = 0.

# Speed store for Evasion mode (global)
var Velocity : Vector3

@export var faceWithCamera = false
var currentShipHeading := 0.

@onready var Bones : Skeleton3D = $"Star Ship/Brmature/Skeleton3D"
@export var Targetable : bool = true

	
@onready var EngineL = Bones.find_bone('Engine.Hub.L')
@onready var EngineR = Bones.find_bone('Engine.Hub.R')

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

@onready var ETw = self.create_tween()

# See function AxisMovment()
var movementScale := 100
var movementClamp := 0.5

var movementScaleYaw := 50
var movementClampYaw := 0.5

@onready var EngineTrailLoader = preload("res://Scenes/Ship/StarShipEngineTrail.tscn")
@onready var ShieldMat : ShaderMaterial = load("res://Materials/Shield.tres")
var MeshI3Ds : Array[MeshInstance3D]

@onready var Turrets := [
		$"Star Ship/TurretF",
		$"Star Ship/TurretL",
		$"Star Ship/TurretR"
]

@export var ManaMax := 500.
@export var HPMax := 400.

var Crystals := 200
var Mana := ManaMax
var HP := HPMax

signal CrystalsChange(int)
signal ManaChange(float)
signal HPChange(float)

func updateHull(float):
	for i in MeshI3Ds:
		i.set_instance_shader_parameter("DamageScale", G.remap(0, HPMax, 1, 0, HP))

func _hit(damage: float):
	HP -= damage
	HPChange.emit(HP)
	if HP <= 0:
		self.Targetable = false
		print("dead")

func _heal(amt: float):
	HP += amt
	HPChange.emit(HP)
	HP = clampf(HP, 0, HPMax)

func pullCrystal(charge: int) -> bool:
	if charge > Crystals: return false
	Crystals -= charge
	CrystalsChange.emit(Crystals)
	return true;

func pushCrystal(amt: int):
	Crystals += amt
	CrystalsChange.emit(Crystals)
	
func pullMana(charge: float) -> float:
	charge = clampf(charge, 0, Mana)
	Mana -= charge
	ManaChange.emit(Mana)
	return charge

func pushMana(amt: int):
	Mana += amt
	Mana = clampf(HP, 0, ManaMax)
	ManaChange.emit(Mana)
	
	
	


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
		print(BName)
		# Add engine posts to list
		if EngineTurnRegEx.search(BName):
			EngineDisks.append(x)
			
		if EnginePostRegEx.search(BName):
			# And add mesh trails to them
			var trail: BoneAttachment3D = EngineTrailLoader.instantiate()
			Bones.add_child(trail)
			trail.bone_idx = x
		
		if "Engine.Inlet." in BName:
			EngineTurbines.append(x) 
			
		if "Engine.Flap." in BName:
			EngineFlaps.append(x)
			
	# Move StarShip Turrets onto the ship's rotating body
	$"Star Ship/TurretF".reparent($"Star Ship/Brmature/Skeleton3D/Frame/TTR Front")
	$"Star Ship/TurretL".reparent($"Star Ship/Brmature/Skeleton3D/Frame/TTR Left")
	$"Star Ship/TurretR".reparent($"Star Ship/Brmature/Skeleton3D/Frame/TTR Right")
	$"Star Ship/Main Cannon".reparent($"Star Ship/Brmature")
	
	# Set turrets targeting origin and extra condition to these
	for T in Turrets:
		T.RangingOrigin = self
		T.ExtraFiringCondition = TurretCheck
	
	for each: MeshInstance3D in find_children("*", "MeshInstance3D"):
		each.material_overlay = ShieldMat
		MeshI3Ds.append(each)

	gravity_scale = 0
	linear_damp = 0
	angular_damp = 0
	axis_lock_angular_x = true
	axis_lock_angular_z = true
	
	self.body_shape_entered.connect(self.collide)
	self.HPChange.connect(self.updateHull)

# For slow and acurate, per-axis movent
func AxisMovment(DirectionVar: StringName, AxisA: StringName, AxisB: StringName, delta: float):
	var speed := 0.
	if not ETw.is_running() and ShipMode == ShipModes.Maneuver:
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
		"Color": Color.RED, 
	}, 
]

# Tween function for setting global shader props
func writeShader(val, str: String):
	RenderingServer.global_shader_parameter_set(str, val)
	#print(str, val)
	
# Tween function to rotate engine flaps
func writeFlaps(amt:float):
	for flap in EngineFlaps:
		BoneRotated(flap, Vector3(-amt*0.8, 0, 0))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if ShipMode != ShipModePrior:
		print(ShipMode, " <- ", ShipModePrior)
		# Reset Tween
		ETw.kill()
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
	BoneRotate(EngineL, "Y", ( SpeedForward + SpeedStrafe)*delta*5)
	BoneRotate(EngineR, "Y", (-SpeedForward + SpeedStrafe)*delta*5)
	for each in EngineDisks:
		BoneRotate(each, "Y", -SpeedYaw*delta*5)

	# Turbines: accumulate angle as a float, set absolute rotation to avoid basis drift
	_turbineAngle = fmod(_turbineAngle + 2.0, TAU)
	BoneRotated(EngineTurbines[0], Vector3(0, -_turbineAngle, 0))
	BoneRotated(EngineTurbines[1], Vector3(0,  _turbineAngle, 0))


var CameraHeading : float

func _physics_process(delta: float) -> void:
	match ShipMode:
		ShipModes.Evasion:
			if ETw.is_running(): return
			
			var heading := CameraHeading
			var headingCam := heading
			
			# Get inputs
			var f = Input.get_axis("Forward", "Backward")
			var s = Input.get_axis("Left", "Right")
			
			# Convert them to a global Vector3
			var v = Vector3(
				f * sin(heading) + s * cos(heading),
				0,
				f * cos(heading) + s * sin(-heading),
			)
			
			# If rotating towards direction of movment, use that instead
			if not self.faceWithCamera:
				# currentShipHeading is used to prevent snapping on the turn tilt
				headingCam = currentShipHeading
				
			# Calulate movment direction and rotate twards it
			if not self.faceWithCamera and not is_zero_approx(v.length()):
				var h = atan2(-v.x, -v.z)
				currentShipHeading += clamp(angle_difference(currentShipHeading, h), -0.1, 0.1)
			
			# Rotate the ship
			var y = angle_difference(self.rotation.y, headingCam) / 35
			angular_velocity.y = y / delta
			# Set the per-axis methods to show to visuals
			SpeedYaw = y*-movementScaleYaw


			# Scale down and add velocity
			Velocity += v * 0.1
			Velocity *= 0.98 # Drag

			linear_velocity = Velocity / delta
			
			# Set the per-axis methods to show to visuals
			SpeedForward = Velocity.rotated(Vector3.UP, -self.rotation.y).z
			SpeedStrafe = -Velocity.rotated(Vector3.UP, -self.rotation.y).x
			
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
	var S2 : Vector3 = body.linear_velocity
	var rate = S1.distance_to(S2)
	var dmg = G.remap(5, 20, 0, 1, rate)
	self._hit(dmg/20)
	if body.has_method("_hit"):
		body._hit(dmg*10)
		
	print(self.name, " at ", S1.length(),  " m/s hit ", body.name, " at ", S2.length(), " m/s")
	
	
