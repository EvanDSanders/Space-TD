extends CharacterBody3D


var speed := 500.
var origin : Vector3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# This will make it move forward
	velocity = -global_transform.basis.z * speed * delta

	var collision:KinematicCollision3D = move_and_collide(velocity)
	if collision:
		queue_free()
		var c = collision.get_collider()
		if c.has_method('_hit'):
			c._hit()
