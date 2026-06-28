extends Node3D

@onready var pointer  : RayCast3D = $CursorCast3D
@onready var camera   : Camera3D  = find_child("Camera3D")
@onready var viewport             = get_viewport()

var RNG = RandomNumberGenerator.new()


@onready var scoutLoader = preload("res://Scenes/Enemies/Scout.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	G.root = self


# Move and point RayCast3D away from camera
func _process(_delta: float) -> void:
	
	var mouse_position = viewport.get_mouse_position()

	pointer.global_position = camera.global_position
	pointer.target_position = camera.project_ray_normal(mouse_position) * 2000
	

func spawn():

	var rot = RNG.randf_range(0, TAU)
	var pos := Vector3(sin(rot), 0, cos(rot)) * 500
	
	var e : Node3D = scoutLoader.instantiate()
	$Enemies.add_child(e)
	e.global_position = pos
	
	#print(pos, "  ", e)
	
