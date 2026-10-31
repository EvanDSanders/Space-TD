@icon("res://EditorIcons/turretControl.svg")
extends Node3D
class_name TurretController

@export var Parent : PhysicsBody3D
@export var Store : FuelStoreBase
@export var LinkOverrideManaStore : ManaStore

@export var Yaw : Node3D
@export var Pitch : Node3D
@export var Reactor : Node3D
@export var Emiter : Node3D

@export var IdleRotationRange : float = 360
@export var RotationRange := Vector2(360, 90)
@export var RotationRate := .2

var Target : RigidBody3D

@export var scanArea : ScanArea3D
@export var consumer : TurretAmmoBase
@export var reaction : TurretReaction
@export var projectile : PackedScene
var projSpeed

var db : DrawDebug

@export_range(0, 1, 0.01, "prefer_slider") var VelocityInherit : float = 0.0 

## Name of a Callable on Parrent Object that this turret's projetile will fire on hit. [br]
## Signature (self: ProjectileBase, hit:PhysicsBody3D)
@export var onHit : TurretOnHitBase

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	assert( is_instance_valid(Yaw), "yaw is missing!" )
	assert( is_instance_valid(Pitch), "pitch is missing!" )
	assert( is_instance_valid(Reactor), "reactor is missing!" )
	assert( is_instance_valid(Emiter), "emiter is missing!" )

	assert( is_instance_valid(Parent), "Parent is missing!" )
	assert( is_instance_valid(Store), "Store is missing!" )
	assert( is_instance_valid(reaction), "reaction is missing!" )
	assert( is_instance_valid(projectile), "projectile is missing!" )
	
	projSpeed = projectile.instantiate().speed
	reaction.Parent = self
	reaction.ready()
	
	db = DrawDebug.fabricate(self)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	#if Parent.constructor: return
	if not Parent.health.isAlive: db.clear(); return
	
	var pos = self.global_position

	db.begin()
	var dbUsed : float = 0

	if Target and consumer.consumeAmmo(Store, 0.25 * delta):
		dbUsed += 0.25
		reaction.procHasTarget(delta)
		#db.drawString(pos, Vector2(0, 40), Target.name)
		#db.drawLine(pos, Target.global_position)
	else:
		reaction.procNoTarget(delta)
		#db.drawString(pos, Vector2(0, 40), "Idle")
		
	#db.drawString(pos, Vector2(0, 60), str(Store.fuel))
		
	var y : float = 0.
	var x : float = 0.
	
	if Target:
		# Get direction to target
		var XY = get_heading(Pitch.global_position, projSpeed, Target.global_position, Target.linear_velocity, Parent.linear_velocity * VelocityInherit * 0.5)
		x = XY.x; y = XY.y;
	
	
	# Gradually rotate turret by claping angle change
	Yaw.rotation.y += clamp(angle_difference(Yaw.rotation.y, y), -RotationRate, RotationRate)
	Pitch.rotation.x += clamp(x - Pitch.rotation.x, -RotationRate, RotationRate)

	var Aimed = is_zero_approx(angle_difference(Yaw.rotation.y, y)) and is_zero_approx(angle_difference(Pitch.rotation.x, x))
	
	if Parent is RailgunShip and Target:
		Aimed = -global_transform.basis.z.dot( global_position.direction_to(Target.global_position) ) > 0.9999
		db.drawString(pos, Vector2(0, 40), str( -global_transform.basis.z.dot( global_position.direction_to(Target.global_position) ) ) )
		db.drawLine(Parent.global_position, Parent.global_position - self.global_transform.basis.z * 50, Color.DARK_GOLDENROD, 3, false)

	
	if Target and reaction.procIsReady() and Aimed and consumer.consumeAmmo(Store, 1.0 * delta):
		dbUsed += 1.0
		reaction.procFire()
		var proj : ProjectileBase = projectile.instantiate()
		G.Main.add_child(proj)
		if onHit:
			proj.onHit = onHit
		proj.global_transform = Emiter.global_transform
		proj.importedVelocity = Parent.linear_velocity * VelocityInherit
		
		# ShipAI.new().
		Parent.apply_central_force(Parent.global_transform.basis * Vector3())
		
	
	#db.drawString(pos, Vector2(-100, 60), str(dbUsed))
	db.end()




## Function to get the x, y rotations to look at a target, with lead
func get_heading(	shooter_pos:Vector3,
					bullet_speed:float,
					target_position:Vector3,
					target_velocity:Vector3,
					shooter_velocity:=Vector3.ZERO,
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
		var t = G.get_intercept(Pitch.global_position, bullet_speed, target_position, target_velocity, shooter_velocity)
		
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
