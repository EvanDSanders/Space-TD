extends Node3D

@onready var Targets	= get_node('/root/Main/Enemies')

func stub(): return true;

@export var CoolDown: float = 0.25
@export var TurretRange: int = 150
@export var Damage: float = 10

@export var YawObject: StringName = "Laser Turret Base"
@export var PitchObject: StringName = "Laser Turret Pitch"
@export var RecoilObject: StringName = "Laser Turret Head"
@export var EmittersObjects: Array = [
	"Turret Emitter L", 
	"Turret Emitter R"
]

@export var ProjectileResource: PackedScene
@export var ExtraFiringCondition: Callable = stub

@onready var Yaw	 : Node3D = find_child(YawObject)
@onready var Pitch	 : Node3D = find_child(PitchObject)
@onready var Head	 : Node3D = find_child(RecoilObject)

@export var idleAngle := 0
@export var idleAngleRange := 360
@export var idleChance := 0.01
@onready var RNG := RandomNumberGenerator.new()

@export var rotationRate := .1

var idleCurrent := 0.

var Emitters : Array

var CDown : float = 0
var Aimed: bool

var RangingOrigin : Node3D = self

@onready var Projectile = ProjectileResource

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for emtr in EmittersObjects:
		Emitters.append(find_child(emtr))


# Function to get the x, y rotations to look at a target, with lead
func get_heading(	shooter_pos:Vector3,
					bullet_speed:float,
					target_position:Vector3,
					target_velocity:Vector3
				) -> Vector2:
	# Store old rotations
	var priorYaw : Vector3 = Yaw.rotation
	var priorPitch : Vector3 = Pitch.rotation
	# Create vars for new angles
	var newAngleY := 0.
	var newAngleX := 0.
	
	# Resample multiple times for acuracy
	for i in range(1):
		# See Globals.gd
		var t = G.get_intercept(Pitch.global_position, bullet_speed, target_position, target_velocity)
		
		# These 3 lines makes it look on only one axis
		Yaw.look_at(t, Vector3(0,1,0))
		Yaw.rotation.x = 0
		Yaw.rotation.z = 0
		
		# Can be used on two objects/axies to make a 3D turret
		Pitch.look_at(t, Vector3(0,1,0))
		Pitch.rotation.y = 0
		Pitch.rotation.z = 0

	# Store New angles
	newAngleY = Yaw.rotation.y
	newAngleX = Pitch.rotation.x
	
	# Restore old angles (so that turrets can rotate over time)
	Yaw.rotation = priorYaw
	Pitch.rotation = priorPitch
	return Vector2(newAngleX, newAngleY)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var Target : Node3D = null
	
	if Targets.get_child_count() != 0:
			
		var dist := 111111111.;
		# Find nearest target
		for trg in Targets.get_children():
			if trg.global_position.distance_to(RangingOrigin.global_position) < dist:
				dist = trg.global_position.distance_to(RangingOrigin.global_position)
				if dist < TurretRange:
					Target = trg
				
	if Target:
	# If the turret is in range:
		var y : float = 0.
		var x : float = 0.
		
		# Get direction to target
		var XY = get_heading(Pitch.global_position, 50, Target.global_position, Target.velocity)
		x = XY.x; y = XY.y;

		# Gradually rotate turret by claping angle change
		Yaw.rotation.y += clamp(angle_difference(Yaw.rotation.y, y), -rotationRate, rotationRate)
		Pitch.rotation.x += clamp(x - Pitch.rotation.x, -rotationRate, rotationRate)

		# Check if the turret is pointed at target
		Aimed = is_zero_approx(angle_difference(Yaw.rotation.y, y)) and is_zero_approx(angle_difference(Pitch.rotation.x, x))
			
		# Check if turret is ready to fire
		if CDown <= 0 and Aimed and ExtraFiringCondition:
			CDown = CoolDown
			
			
			# Shoot a projectile at every emission point
			for emtr in Emitters:
				var projectile : Node3D = Projectile.instantiate()
				G.root.add_child(projectile)
				projectile.global_transform = emtr.global_transform
				if projectile.damage:
					projectile.damage = self.Damage
					
	else:
		# Create a random idle animation
		if RNG.randf() <= idleChance:
			idleCurrent = RNG.randf_range(-idleAngleRange/2., idleAngleRange/2.) + idleAngle
		var y = deg_to_rad(idleCurrent)
		var x = 0

		# Rotate turret to new angle
		Yaw.rotation.y += clamp(angle_difference(Yaw.rotation.y, y), -rotationRate, rotationRate)
		Pitch.rotation.x += clamp(x - Pitch.rotation.x, -rotationRate, rotationRate)

			
	# Subtract the amount of time passed from cooldown
	CDown -= _delta;
		
