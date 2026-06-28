extends RigidBody3D


const SPEED = 8.0
@export var health := 200.
@onready var healthMax := health



var target: Node3D

@export var Targetable : bool = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	var point = G.getNearest( self.global_position, get_node("/root/Main/Friendlies").get_children(), G.checkTargable )
	if point:
		target = point


func _physics_process(delta: float) -> void:
	
	if target:
		var dir = self.global_position.direction_to(target.global_position)
		self.apply_impulse(dir)

func _hit(damage: float):
	health -= damage
	$"Main/Origin Scout".set_instance_shader_parameter("DamageScale", G.remap(0, healthMax, 1.2, 0.4, health))
	if health <= 0: queue_free()
