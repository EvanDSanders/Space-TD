extends Node3D

func stub(): return true;

@export var YawObject: StringName = "Laser Turret Base"
@export var PitchObject: StringName = "Laser Turret Pitch"
@export var RecoilObject: StringName = "Laser Turret Head"
@onready var cannon_head_d: MeshInstance3D = $"Main Cannon/Origin Cannon Hub/Cannon Pitch/Cannon Head D"
@onready var Sound: AudioStreamPlayer3D = $"Main Cannon/Origin Cannon Hub/Cannon Pitch/Cannon Head D/AudioStreamPlayer3D"
@onready var FireOrgin: Marker3D = $"Main Cannon/Origin Cannon Hub/Cannon Pitch/Cannon Head D/Marker3D"


@export var EmittersObjects: Array = [
	"Turret Emitter L", 
	"Turret Emitter R"
]
@export var ProjectileResource: Resource 
@export var ExtraFiringCondition: Callable = stub
@export var Damage: float = 10

@onready var Yaw	 = find_child(YawObject)
@onready var Pitch	 = find_child(PitchObject)
@onready var Head	 = find_child(RecoilObject)
var Emitters : Array

var CDown : float = 0
var Aimed: bool

var RangingOrigin : Node3D = self

@onready var the_star_ship: RigidBody3D = $"../.."
@onready var Projectile = ProjectileResource
@onready var Pointer := $"Main Cannon/Origin Cannon Hub/Cannon Pitch/RayCast3D"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for emtr in EmittersObjects:
		Emitters.append(find_child(emtr))
	
	call_deferred('_ready2')
		
func _ready2():
	#Laser.reparent(G.Main)
	Laser.visible = false
		
@onready var Laser: Node3D = $LaserBase


func get_heading(obj: Node3D, axis: StringName, targ) -> float:
	var priorXYZ := obj.rotation
	var newAngle := 0.
	obj.look_at(targ, Vector3(0,1,0))
	match axis:
		"Y":
			obj.rotation.x = 0
			obj.rotation.z = 0
			newAngle = obj.rotation.y
		"X":
			Pitch.rotation.y = 0
			Pitch.rotation.z = 0
			newAngle = obj.rotation.x
		"Z":
			Pitch.rotation.y = 0
			Pitch.rotation.x = 0
			newAngle = obj.rotation.z
	
	obj.rotation = priorXYZ
	return newAngle

var priorY := 0.
var priorX := 0.

var Tw : Tween
@export var MainCannonManaUse : int


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	#return
	if not the_star_ship.health.isAlive: return
	var mouse: RayCast3D = G.Main.get_node('CursorCast3D')
	
	if not mouse.is_colliding(): return
	var Target = mouse.get_collision_point()
	
	var t = G.get_intercept( Pitch.global_position, 50, Target, Vector3.ZERO )
	
	var y = get_heading(Yaw,   "Y", t)
	var x = get_heading(Pitch, "X", t)

	Yaw.rotation.y += clamp(angle_difference(Yaw.rotation.y, y), -.025, .025)
	Pitch.rotation.x += clamp(x - Pitch.rotation.x, -.025, .025)

	priorY = Yaw.rotation.y
	priorX = Pitch.rotation.x
	
	Aimed = is_zero_approx(angle_difference(Yaw.rotation.y, y)) and is_zero_approx(angle_difference(Pitch.rotation.x, x))
		
	if the_star_ship.mana.Mana > MainCannonManaUse and CDown <= 0 and Aimed and the_star_ship.FiringInput and not G.isBuilding:
		var pos = G.Cursor.global_position
		
		if is_instance_valid(Sound): Sound.play()
		
		Laser.visible = true
		var mesh: Mesh = Laser.get_node("MeshInstance3D").mesh
		mesh.height = 0
		mesh.radius = 12
		Laser.global_transform = FireOrgin.global_transform
		
		var dist : = Laser.global_position.distance_to(pos)
		
		if Tw: Tw.kill(); 
		Tw = create_tween();
		Tw.tween_method(func(f:float): Laser.get_child(0).position.z = -f, 0, dist/2, 0.2 * dist * .001 + .15)
		Tw.parallel().tween_property(mesh, "height", dist, 0.2 * dist * .001 + .15)
		Tw.parallel().tween_property(mesh, "radius", 0, 0.4 * dist * .001 + .15)
		G.schedule(func():
			var projectile : Node3D = Projectile.instantiate()
			G.Main.add_child(projectile)
			projectile.global_position = pos
			projectile.activate()
			, .2 * dist * .001 + .15)
		G.schedule(func(): Laser.visible = false, .4 * dist * .001 + .15)
			
			
		
		the_star_ship.mana.pullMana(MainCannonManaUse)
		CDown = 4
		
			
	
	CDown -= _delta;
	
	if Pointer.is_colliding():
		$"Cannon Target".global_position = Pointer.get_collision_point()
