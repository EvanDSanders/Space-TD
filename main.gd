extends Node3D

@onready var camera   : Camera3D  = find_child("Camera3D")
@onready var viewport             = get_viewport()

@onready var pointer: RayCast3D = $CursorCast3D
@onready var pointerB: RayCast3D = $BuildCast3D

@onready var spawn_point_test: Node3D = $SpawnPointTest
@onready var GUI: Control = $"GUI Mount"

@onready var StarShip: RigidBody3D = $"Friendlies/The Star Ship"
@onready var Cursor: Marker3D = $Cursor

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	G.Main = self
	G.Friendlies = $Friendlies
	G.Enemies = $Enemies
	G.Ores = $Ores
	G.Collectibles = $Collectibles
	
	if G.isMainLevel: Linker.setUp(StarShip)
	
	#for x in range(500):
		#spawn(spawn_point_test.global_position)
		
		

		
		

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
	if not StarShip: return
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
	
	
var gameOver
func GameOver():
	gameOver = preload('res://Scenes/GUI/GameOver.tscn').instantiate()
	G.Main.add_child(gameOver)
	
