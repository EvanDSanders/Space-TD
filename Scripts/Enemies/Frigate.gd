extends "res://Scripts/Enemies/Scout.gd"


func _ready() -> void:
	pass
#
#
#func _physics_process(delta: float) -> void:
	#if not health.isAlive: return
	#target = E.getTarget(E.TargetType.Friend, self.global_position)
	#
	#if target:
		#Nav.Target = target
		#
		#if self.global_position.distance_to(target.global_position) <= 80 and CoolDown <= 0:
			#CoolDown = CoolDownTime
			##laser_base.global_transform = scout_laser.global_transform
			##laser_base.look_at(target.global_position)
			##laser_base.scale.z = laser_base.global_position.distance_to(target.global_position)
			##if Tw: Tw.kill()
			##Tw = create_tween()
			##Tw.tween_method( lerpLaser, 5, 0, .5 )
			#target.health.Hit(damage)
	#
	#CoolDown -= delta
