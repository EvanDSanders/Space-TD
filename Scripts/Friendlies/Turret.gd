extends Node3D
class_name TurretBase

func stub(): return true;

@onready var Audio: AudioStreamPlayer3D = $AudioStreamPlayer3D


@onready var health: Destructible = find_child("Destructible")
@onready var mana: ManaStore = find_child("ManaStore")
@onready var crystal: CrystalStore = find_child("CrystalStore")
var constructor: ConstructionWorker


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

var Yaw: Node3D
var Pitch: Node3D
var Head: Node3D

@export var idleAngle := 0
@export var idleAngleRange := 360
@export var idleTimer := 1.
@onready var RNG := RandomNumberGenerator.new()
@onready var TickID : int = randi_range(0, 20)

@export var rotationRate := .2

var idleCurrent := 0.

var Emitters : Array

var Aimed: bool

var RangingOrigin : Node3D = self
@export var isPartOfStarShip := false

@onready var Projectile = ProjectileResource
var Tw : Tween

@onready var FlakParticleLoader = preload("res://Scenes/Misc/MuzzleFlash.tscn") 

@export var scanArea3D : ScanArea3D

var onHit : Callable

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for emtr in EmittersObjects:
		Emitters.append(find_child(emtr))
		
	Yaw = find_child(YawObject)
	Pitch = find_child(PitchObject)
	Head = find_child(RecoilObject)
	
	if not isPartOfStarShip:
		E.Register(self, E.Friend)
	else:
		get_node("Destructible").queue_free()


func destroy():
	G.spawnExplosionAndFree(G.ExplType.Magic, self)


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


var Target : Node3D = null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if constructor: return
	
	if isPartOfStarShip:
		self.mana.pushMana(  RangingOrigin.mana.pullMana( clamp(10 * delta, 0, mana.ManaMax - mana.Mana ))  )
	else:
		self.mana.pushMana(  Linker.pullMana( clamp(10 * delta, 0, mana.ManaMax - mana.Mana ))  )
	
	
	if not Target or TickID == Engine.get_physics_frames() or not Target.health.isAlive:
		
		Target = E.getTargetWith(scanArea3D.scanList(), self.global_position) # RangingOrigin.global_position, -1)
		
				
	if Target:
	# If the turret is in range:
		var y : float = 0.
		var x : float = 0.
		
		# Get direction to target
		var XY = get_heading(Pitch.global_position, 500, Target.global_position, Target.linear_velocity)
		x = XY.x; y = XY.y;

		# Gradually rotate turret by claping angle change
		Yaw.rotation.y += clamp(angle_difference(Yaw.rotation.y, y), -rotationRate, rotationRate)
		Pitch.rotation.x += clamp(x - Pitch.rotation.x, -rotationRate, rotationRate)

		# Check if the turret is pointed at target
		Aimed = is_zero_approx(angle_difference(Yaw.rotation.y, y)) and is_zero_approx(angle_difference(Pitch.rotation.x, x))
			
		# Check if turret is ready to fire
		if (is_equal_approx(mana.Mana, mana.ManaMax) or mana.Mana >= mana.ManaMax) and Aimed and ExtraFiringCondition:
			mana.pullMana(mana.ManaMax)
			if Audio: Audio.play()
			
			if Tw: Tw.kill()
			Tw = create_tween()
			Tw.tween_property(Head, "position", Vector3(0, 0, .6), 0)
			Tw.tween_property(Head, "position", Vector3(0, 0, 0), 0.25)
			
			
			# Shoot a projectile at every emission point
			for emtr in Emitters:
				var part = FlakParticleLoader.instantiate()
				emtr.add_child(part); part.Mute(); part.scale = 0.08 * Vector3.ONE
				var projectile : Node3D = Projectile.instantiate()
				G.root.add_child(projectile)
				projectile.global_transform = emtr.global_transform
				if projectile.damage:
					projectile.damage = self.Damage
				if onHit:
					projectile.onHit = onHit
					
		idleCurrent = rad_to_deg(Yaw.rotation.y)
		
	else:
		# Create a random idle animation
		if idleTimer < 0: # RNG.randf() <= idleChance:
			idleTimer = G.remap(0, 1, 0.5, 4, RNG.randf())
			var idleTarg = RNG.randf_range(-idleAngleRange/2., idleAngleRange/2.) + idleAngle
			
			if Tw: Tw.kill()
			Tw = create_tween()
			Tw.tween_property(self, "idleCurrent", idleTarg, 1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
			
		idleTimer -= delta
		var y = deg_to_rad(idleCurrent)
		var x = 0

		# Rotate turret to new angle
		Yaw.rotation.y += clamp(angle_difference(Yaw.rotation.y, y), -rotationRate, rotationRate)
		Pitch.rotation.x += clamp(x - Pitch.rotation.x, -rotationRate, rotationRate)

			
		
