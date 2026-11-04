extends CharacterBody3D
@onready var health: Destructible = $Destructible

@onready var pivot: Node3D = $DoomLaser/Node3D
@onready var laser: MeshInstance3D = $DoomLaser/Node3D/MeshInstance3D
@onready var end: Node3D = $DoomLaser/End

@onready var beep: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var cast: RayCast3D = $DoomLaser

@export var curve : Curve

var t : float = 0

var rX : float = 0.0
var rY : float = 0.0

var Pw : float = 0.0
var Tw : Tween

var flip : float = -1 if randi_range(0, 1) else 1

var spinRate := 0.04

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	G.MegaLaser = self

func startBlast():
	cast.visible = true
	end.visible = true
	pivot.visible = true
	if Tw: Tw.kill()
	Tw = create_tween()
	Pw = 0.0
	Tw.tween_property(self, "Pw", 1.0, 3.0) # 6
	Tw.parallel().tween_property(self, "spinRate", 0.8, 5.0)
	
	var ef : AudioEffectPitchShift = AudioServer.get_bus_effect(1,0) 
	ef.pitch_scale = 0.5
	Tw.parallel().tween_property(ef, "pitch_scale", 2.0, 5.0)
	beep.play()
	
	Tw.chain().tween_callback(fullBlast) # .set_delay(2.)

	

func fullBlast():
	cast.visible = false
	end.visible = false
	pivot.visible = false
	beep.stop()
	
	if Tw: Tw.kill()
	Tw = create_tween()
	Tw.tween_property(self, "spinRate", 0.04, 1.0) 
	
	#if Tw: Tw.kill()
	#Tw = create_tween()
	
	var proj : ProjectileBase = preload( "res://Scenes/Projectiles/LaserBeam.tscn" ).instantiate()
	proj.attacker = self
	proj.canParry = true
	proj.strong = true
	proj.ToFriendly()
	proj.speed = 1000
	proj.damage = 1000

	var aim = G.get_intercept( self.global_position, proj.speed, G.StarShip.global_position, G.StarShip.linear_velocity, Vector3.ZERO )

	G.Main.add_child( proj )
	proj.global_position = self.global_position
	proj.look_at( aim )

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if not health.isAlive: return
	
	t += delta * 1.5
	
	$"Boss A Laser/Cylinder 012".rotate_x(  flip * spinRate )
	$"Boss A Laser/Cylinder 014".rotate_x( -flip * spinRate )
	
	var distance := -10000.
	if cast.is_colliding():
		distance = -cast.global_position.distance_to(cast.get_collision_point())
	
	end.position.z    = distance
	laser.position.z  = distance/2
	laser.mesh.height = distance
	
	cast.look_at(G.StarShip.global_position)
	
	cast.rotation.y += sin(rY) / 8 * curve.sample( 1 - Pw )
	cast.rotation.x += cos(rX) / 8 * curve.sample( 1 - Pw )
	
	rY += delta * 4.3210987 * lerpf(1.5, .5, Pw)
	rX += delta * 4.9220409 * lerpf(1.5, .5, Pw)
	
	var c = 1
	for each:MeshInstance3D in end.get_children():
		each.scale = Vector3.ONE * ( 1 - fmod( c/3. + t, 1. ) )
		c += 1

func destroy():
	G.spawnExplosion(G.ExplType.SciFi, self, G.Main, 4)
	$"../..".laserDestroied()
	beep.stop()
	cast.visible = false
	
	$"Boss A Laser/Cylinder 012".queue_free()
	$"Boss A Laser/Cylinder 014".queue_free()
	$"Boss A Laser/Sphere".queue_free()
