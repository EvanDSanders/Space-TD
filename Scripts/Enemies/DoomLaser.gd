extends RayCast3D

@onready var pivot: Node3D = $Node3D
@onready var laser: MeshInstance3D = $Node3D/MeshInstance3D
@onready var end: Node3D = $End

@onready var flash: Panel = $Panel
@onready var beep: AudioStreamPlayer3D = $AudioStreamPlayer3D

@export var curve : Curve

var t : float = 0

var rX : float = 0.0
var rY : float = 0.0

var Pw : float = 0.0
var Tw : Tween

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	G.MegaLaser = self
	startBlast()

func startBlast():
	end.visible = true
	pivot.visible = true
	if Tw: Tw.kill()
	Tw = create_tween()
	Pw = 0.0
	Tw.tween_property(self, "Pw", 1.0, 6.0)
	
	var ef : AudioEffectPitchShift = AudioServer.get_bus_effect(1,0) 
	ef.pitch_scale = 0.5
	Tw.parallel().tween_property(ef, "pitch_scale", 2.0, 8.0)
	beep.play()
	
	Tw.chain().tween_callback(fullBlast) # .set_delay(2.)

	

func fullBlast():
	end.visible = false
	pivot.visible = false
	beep.stop()
	if Tw: Tw.kill()
	Tw = create_tween()
	flash.modulate = Color.WHITE
	Tw.tween_property(flash, "modulate", Color.TRANSPARENT, 2.0).set_delay(1.)
	if is_colliding() and get_collider() is TheStarShip:
		G.StarShip.health.Hit( 1000000, self.global_position.direction_to(G.StarShip.global_position) * 1000000)
	elif is_colliding() and get_collider() == G.MegaSheild:
		G.MegaSheild.hit()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	t += delta * 1.5
	
	var distance := -10000.
	if is_colliding():
		distance = -self.global_position.distance_to(get_collision_point())
	
	end.position.z    = distance
	laser.position.z  = distance/2
	laser.mesh.height = distance
	
	self.look_at(G.StarShip.MegaShieldMount.global_position)
	
	self.rotation.y += sin(rY) / 8 * curve.sample( 1 - Pw )
	self.rotation.x += cos(rX) / 8 * curve.sample( 1 - Pw )
	
	rY += delta * 4.3210987 * lerpf(1.5, .5, Pw)
	rX += delta * 4.9220409 * lerpf(1.5, .5, Pw)
	
	var c = 1
	for each:MeshInstance3D in $End.get_children():
		each.scale = Vector3.ONE * ( 1 - fmod( c/3. + t, 1. ) )
		c += 1
