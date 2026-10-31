extends CharacterBody3D
class_name ProjectileBase

@export var speed := 500. * 4
@export var damage := 10.
@export var life := 2.

@export var onHit : TurretOnHitBase

var importedVelocity := Vector3.ZERO

@export var hitsLeft := 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# This will make it move forward
	velocity = -global_transform.basis.z * speed * delta + importedVelocity * delta

	var collision:KinematicCollision3D 
	#if hitsLeft > 1: 
		##collision = move_and_slide(velocity)
	#else:
	collision = move_and_collide(velocity)
	
	
	if collision:
		var c = collision.get_collider()
		if hitsLeft <= 1:
			queue_free()
		else: 
			hitsLeft -= 1
			if c is ShipBase:
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
