extends CharacterBody3D

@onready var enemies: Marker3D = G.Main.get_node("Enemies")

@export var speed := 200.
@export var damage := 1000.


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var mesh : SphereMesh = $MeshInstance3D.mesh
	mesh.radius = 4
	mesh.height = 8
	



func boom(radius: float):
	var c : int = 0
	var dmg : float = 0
	for each in enemies.get_children():
		var dist = self.global_position.distance_to(each.global_position)
		var dir = self.global_position.direction_to(each.global_position)
		if dist > radius: continue
		c += 1
		var d = G.remap(0, radius, 10000, 100, dist)
		dmg += d
		if each.find_child("Destructible"):
			each.find_child("Destructible").Hit(damage, dir*d/100)
		
	print("%d targets found in %f m taken %f damage!" %  [c, radius, dmg])

var upScale := 40

var running := true

func done(f:float=0):
	queue_free()

func _physics_process(delta: float) -> void:
	if not running: return
	return

	velocity = -global_transform.basis.z * speed * delta
	# This will make it move forward
		#queue_free()

	var collision:KinematicCollision3D = move_and_collide(velocity)
	if collision:
		running = false
		var c = collision.get_collider()
		if c.find_child("Destructible"):
			c.find_child("Destructible").Hit(damage)
			
func activate():
	var Tw = create_tween()
	#var mesh : SphereMesh = $MeshInstance3D.mesh
	#Tw.tween_property(mesh, "height", 8*upScale, .2)
	#Tw.parallel().tween_property(mesh, "radius", 4*upScale, .2)
	Tw.parallel().tween_method(boom, 4, 4*upScale, .2)
	G.spawnExplosion(G.ExplType.Magic, self, G.Main, 5)
	Tw.chain().tween_method(done, 0, 0, 0.1)
		
		
