extends CharacterBody3D
class_name ProjectileBase

@export var speed := 500. * 4
@export var damage := 10.
@export var life := 2.

@export var onHit : TurretOnHitBase

## Object that fired this projectile
var attacker: Node3D
## If true, the projectile can be deflected back to its attacker
@export var canParry := false
## If true, a failed deflection disables the defender's shield (not implemented yet)
@export var strong := false

## If true, a deflected projectile tweens to its attacker and is guaranteed to hit,
## instead of flying back with velocity
@export var homingDeflect := false
## Minimum duration of the homing tween, in seconds
@export var homingMinTime := 0.15

var _homing := false
var _homingTween: Tween

var importedVelocity := Vector3.ZERO

@export var hitsLeft := 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


func ToEnemy():
	set_collision_mask_value(13, false)
	set_collision_layer_value(13, false)
	set_collision_mask_value(14, true)
	set_collision_layer_value(14, true)
	
func ToFriendly():
	set_collision_mask_value(13, true)
	set_collision_layer_value(13, true)
	set_collision_mask_value(14, false)
	set_collision_layer_value(14, false)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if _homing:
		return

	# This will make it move forward
	velocity = -global_transform.basis.z * speed * delta + importedVelocity * delta

	var collision:KinematicCollision3D 
	#if hitsLeft > 1: 
		##collision = move_and_slide(velocity)
	#else:
	collision = move_and_collide(velocity)
	
	
	if collision:
		var c = collision.get_collider()
		if canParry and is_instance_valid(attacker) and c.get("isDeflecting") == true:
			_deflect(c)
			c.onParry(collision.get_position())
			return
			
		if hitsLeft <= 1:
			queue_free()
		else: 
			hitsLeft -= 1
			if c is ShipBase and not TheStarShip:
				c.set_collision_mask_value(10, false)
				c.set_collision_mask_value(14, false)
				c.set_collision_layer_value(10, false)
				c.set_collision_layer_value(14, false)
			
		if onHit:
			onHit.onHit(self, c)
		if c.find_child("Destructible"):
			c.find_child("Destructible").Hit(damage)

	life -= delta
	if life <= 0.: queue_free()


func _deflect(defender: Node3D) -> void:
	ToEnemy()

	if homingDeflect:
		_start_homing(attacker)
		attacker = defender
		canParry = false
		return

	var target_vel := Vector3.ZERO
	var v = attacker.get("velocity")
	if v is Vector3:
		target_vel = v
	var aim: Vector3 = G.get_intercept(global_position, speed, attacker.global_position, target_vel, G.StarShip.linear_velocity)
	# var aim = G.get_intercept( self.global_position, proj.speed, G.StarShip.global_position, G.StarShip.linear_velocity, Vector3.ZERO )
	if not aim.is_equal_approx(global_position):
		look_at(aim)
	importedVelocity = Vector3.ZERO
	attacker = defender
	canParry = false


func _start_homing(target: Node3D) -> void:
	_homing = true
	var from := target.to_local(global_position)
	var duration := maxf(homingMinTime, global_position.distance_to(target.global_position) / speed)
	_homingTween = create_tween()
	_homingTween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_homingTween.tween_method(_home_step.bind(from, target), 0.0, 1.0, duration)
	_homingTween.tween_callback(_guaranteed_hit.bind(target))


func _home_step(t: float, from: Vector3, target: Node3D) -> void:
	if not is_instance_valid(target):
		return
	# from is in the target's local space, so the path follows its motion and rotation
	var to := target.global_position
	global_position = target.to_global(from.lerp(Vector3.ZERO, t))
	if not global_position.is_equal_approx(to):
		look_at(to)


func _guaranteed_hit(c: Node3D) -> void:
	if is_instance_valid(c):
		if onHit:
			onHit.onHit(self, c)
		var d = c.find_child("Destructible")
		if d:
			d.Hit(damage)
	queue_free()
