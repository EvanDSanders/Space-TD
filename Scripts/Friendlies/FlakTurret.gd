extends TurretBase

@onready var FlakParticleEmitter : Node3D = $"Star Station/Flak Turret Yaw/Flak Turret Pitch/FlakParticleEmitter"
@onready var FlakTraceLoader = preload("res://Scenes/Projectiles/ProjectileTrace.tscn") 

@export var coolDown : float = 1
var CDown = coolDown

@export var FlakID := 0
@export var Station : Prospector



func _physics_process(delta: float) -> void:
	if constructor or not Station.health.isAlive: return
	
	if not Target or TickID == E.TickID or not Target.health.isAlive:
		Target = E.getTarget(E.TargetType.Enemy, RangingOrigin.global_position, -1)
		
				
	if Target:
	# If the turret is in range:
		var y : float = 0.
		var x : float = 0.
		
		# Get direction to target
		var XY = get_heading(Pitch.global_position, 500, Target.global_position, Target.linear_velocity)
		x = XY.x; y = XY.y;

		# Gradually rotate turret by claping angle change
		Yaw.rotation.y += clamp(angle_difference(Yaw.rotation.y, y), -rotationRate, rotationRate)
		Pitch.rotation.x += clamp(x - Pitch.rotation.x, -rotationRate, rotationRate)

		# Check if the turret is pointed at target
		Aimed = is_zero_approx(angle_difference(Yaw.rotation.y, y)) and is_zero_approx(angle_difference(Pitch.rotation.x, x))
			
		# Check if turret is ready to fire
		if (	(is_zero_approx(CDown) or CDown < 0) and 
				(is_zero_approx(Station.CDown) or Station.CDown < 0) and
				Aimed and Station.fireID == self.FlakID   ):
			Station.fireID +=1; if Station.fireID > 2: Station.fireID = 0;
			Station.CDown = Station.coolDown
			CDown = coolDown
			if Audio: Audio.play()
			
			if Tw: Tw.kill()
			Tw = create_tween()
			Tw.tween_property(Head, "position", Vector3(0, 0, -42.0 + 21),  .1)
			Tw.tween_property(Head, "position", Vector3(0, 0, -42.0), coolDown-.1)
			
			var part = FlakParticleLoader.instantiate()
			FlakParticleEmitter.add_child(part)
			
			for p in range(6):
				self.launch(FlakParticleEmitter.global_position, Target.global_position)
				
					
		idleCurrent = rad_to_deg(Yaw.rotation.y)
		
	else:
		# Create a random idle animation
		if idleTimer < 0: # RNG.randf() <= idleChance:
			idleTimer = G.remap(0, 1, 2, 10, RNG.randf())
			var idleTarg = RNG.randf_range(-idleAngleRange/2., idleAngleRange/2.) + idleAngle
			
			if Tw: Tw.kill()
			Tw = create_tween()
			Tw.tween_property(self, "idleCurrent", idleTarg, 4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			
		idleTimer -= delta
		var y = deg_to_rad(idleCurrent)
		var x = 0

		# Rotate turret to new angle
		Yaw.rotation.y += clamp(angle_difference(Yaw.rotation.y, y), -rotationRate, rotationRate)
		Pitch.rotation.x += clamp(x - Pitch.rotation.x, -rotationRate, rotationRate)

	CDown -= delta

## Uniform random points inside a sphere (volume).
static func point_in_sphere_volume(radius: float, center: Vector3 = Vector3.ZERO) -> Vector3:
	var dir := Vector3(randfn(0, 1), randfn(0, 1), randfn(0, 1)).normalized()
	# cube root of uniform [0,1] gives uniform volume density, not surface bias
	var r := radius * pow(randf(), 1.0 / 3.0)
	return center + dir * r

func launch(start:Vector3, end:Vector3):
	end = point_in_sphere_volume(G.remap(0, 1000, 10, 100, start.distance_to(end)), end)
	var dist := start.distance_to(end)
	
	var time = RNG.randf_range(0.0, 0.3) + G.remap(0, 1000, 0, 1, dist)
	var trace = FlakTraceLoader.instantiate()
	G.Main.add_child(trace)
	trace.global_position = FlakParticleEmitter.global_position
	trace.create_tween().tween_property(trace, 'global_position', end, time)
	
	G.schedule(detonate.bind(start, end, trace), time)
	
	
func detonate(start:Vector3, end:Vector3, trace:VaporTrail):
	G.spawnExplosion(G.ExplType.SciFi, G.Main, G.Main, 1.0, end)
	E.splashDamage(E.TargetType.Enemy, end, 30, 60, 1000)
	G.schedule(trace.queue_free, .2)
	
	
	
	
	
	
	
	
	
