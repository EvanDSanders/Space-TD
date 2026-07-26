extends TurretBase
class_name MissileTurret


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	
	onHit = MissileTurret.bam

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass



static func bam(projectile: CharacterBody3D, hit: PhysicsBody3D):
	G.spawnExplosion(G.ExplType.Magic, projectile)

	var ExplPos = projectile.global_position
	for each: Node3D in E.GetList(E.Enemy):
		if each.health:
			var dist = ExplPos.distance_to(each.global_position)
			var impulse = clamp( G.remap(50, 80, 2000, 0, dist), 0, 10000 )
			if not is_zero_approx(impulse):
				each.health.Hit(impulse, ExplPos.direction_to(each.global_position) * impulse)
