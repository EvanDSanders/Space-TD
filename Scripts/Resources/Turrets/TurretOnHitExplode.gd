extends TurretOnHitBase
class_name TurretOnHitExplode


var Shooter : ShipBase

func onHit( projectile: ProjectileBase, hit: PhysicsBody3D ) -> void:
	#print('I have been calllllededed')
	G.spawnExplosionAndFree(G.ExplType.SciFi, projectile, G.Main, 3)
