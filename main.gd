extends Node3D

@onready var camera   : Camera3D  = find_child("Camera3D")
@onready var viewport             = get_viewport()

@onready var pointer: RayCast3D = $CursorCast3D
@onready var pointerB: RayCast3D = $BuildCast3D
@onready var scoutLoader = preload("res://Scenes/Enemies/Scout.tscn")
@onready var frigateLoader = preload("res://Scenes/Enemies/Frigate.tscn")

@onready var spawn_point_test: Node3D = $SpawnPointTest
@onready var GUI: Control = $"GUI Mount"

@onready var StarShip: RigidBody3D = $"Friendlies/The Star Ship"
@onready var Cursor: Marker3D = $Cursor

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	G.root = self
	#for x in range(500):
		#spawn(spawn_point_test.global_position)
		
		
	for x in range(randi_range(10, 15)):
		var loc = randf_range(0, TAU)
		var pos = Vector3(sin(loc), 0, cos(loc))
		var dist = randf_range(40, 400)
		
		
		var rock := preload("res://Scenes/Friendlies/Asteroid.tscn").instantiate() as Asteroid3D
		
		var size : int = randi_range(
			G.remap(40, 400, 2, 15, dist),
			G.remap(40, 400, 5, 20, dist),
		)
		var base : int = randi_range(
			G.remap(2, 20, 50,  2000, size),
			G.remap(2, 20, 100, 5000, size),
		)
		rock.CrystalsMax = base + randf_range(0, 100) * size/10
		rock.Size = size
		
		rock.global_position = pos * dist
		
		self.add_child(rock)
		
		print("+Rock of %d w/ %dc, %dm away" % [rock.Size, rock.CrystalsMax, dist])
		
		

var C := 0

var targetedObject : Node3D

func isPointed(object: Node3D, didEnter: bool):
	if object.has_node("CursorDialogue"):
		match didEnter:
			true:
				object.find_child("CursorDialogue").enter()
			false:
				object.find_child("CursorDialogue").exit()
 
var PriorVelRot := Vector3.ZERO
var PriorVelLin := Vector3.ZERO

# Move and point RayCast3D away from camera
func _process(_delta: float) -> void:
	
	viewport = get_viewport()
	
	var mouse_position = viewport.get_mouse_position()

	pointer.global_position = camera.global_position
	pointerB.global_position = camera.global_position
	
	pointer.target_position = camera.project_ray_normal(mouse_position) * 20000
	pointerB.target_position = camera.project_ray_normal(mouse_position) * 20000
	
	pointer.force_raycast_update()
	var current := pointer.get_collider() as Node3D
	if current != targetedObject:
		if targetedObject:
			isPointed(targetedObject, false)
		if current:
			isPointed(current, true)
		targetedObject = current

	GUI.size = viewport.size
	
	if pointerB.is_colliding():
		Cursor.global_position = pointerB.get_collision_point()
	
var Tw : Tween

func _physics_process(delta: float) -> void:
	var VelLin := StarShip.linear_velocity
	var VelRot := StarShip.angular_velocity

	var basis := StarShip.global_transform.basis
	var LocalVelLin := basis.inverse() * VelLin
	var LocalPriorVelLin := basis.inverse() * PriorVelLin

	
	var displayVel = Vector2(
		LocalPriorVelLin.x - LocalVelLin.x,
		LocalPriorVelLin.z - LocalVelLin.z
	) / .2 / 4
	var displayRet = -(
		PriorVelRot.y - VelRot.y
	) / 2 / 4
		
	PriorVelLin = VelLin
	PriorVelRot = VelRot
	
	if Tw: Tw.kill()
	Tw = create_tween()
	Tw.tween_property(GUI, "offset_transform_position", displayVel, 0.2); Tw.parallel()
	Tw.tween_property(GUI, "offset_transform_rotation", displayRet, 0.2)


var RNG = RandomNumberGenerator.new()

func spawn(ship, pos = null):
	#return
	#var rot = RNG.randf_range(0, TAU)
	if not pos:
		var rot = Time.get_ticks_msec()/1000.
		pos = Vector3(sin(rot), 0, cos(rot)) * 500
	
	var e : Node3D = ship.instantiate()
	$Enemies.add_child(e)
	e.global_position = pos
	
	#print(pos, "  ", e)
	


func spawnDo() -> void:
	$Timer.wait_time -= randf_range(0.1, 0.3)
	$Timer.wait_time = clamp($Timer.wait_time, 1, INF)
	
	var rot = RNG.randf_range(0, TAU)
	var pos = Vector3(sin(rot), 0, cos(rot)) * RNG.randi_range(400, 500)
	#for x in range( RNG.randi_range(30, 60) ):
	var amt := RNG.randi_range(1, 4)
	
	var ship : PackedScene
	var shipName : StringName
	
	var str : float = randf()
	if str < G.remap(8, 1, 0.4, 0.8, $Timer.wait_time):
		ship = scoutLoader
		shipName = "Scout"
	else:
		ship = frigateLoader
		shipName = "Frigate"
		
	
	G.Warnings.Create("%s :: %d" % [shipName, amt])
	for x in range( amt ):
		
		var posS = pos + Vector3(RNG.randf_range(-30,30),RNG.randf_range(-10,10),RNG.randf_range(-30,30)) * 1.4
		spawn(ship, posS)
		
