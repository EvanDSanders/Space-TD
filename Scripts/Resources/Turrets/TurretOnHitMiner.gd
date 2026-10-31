extends TurretOnHitBase
class_name TurretOnHitMiner


var Shooter : ShipBase

func onHit( projectile: ProjectileBase, hit: PhysicsBody3D ) -> void:
	if hit is Asteroid3D:
		var amt = randi_range( 0, 3 )
		
		var extract = hit.mine(amt)
			
		if is_instance_valid(Shooter):
			var node := Shooter.crystal as CrystalStore
			node.pushCrystal(extract)
		
		#
		#if not hit.has_meta("MiningProgress"): 
			#hit.set_meta("MiningProgress", extract)
		#else:
			#hit.set_meta("MiningProgress", hit.get_meta("MiningProgress") + extract)
		#
		#
		#
		#if hit.has_meta("MiningProgress") and hit.get_meta("MiningProgress") > 50:
			#var node = MiningLaser.spawnCrystalNode( hit, hit.get_meta("MiningProgress") )
			#hit.set_meta("MiningProgress", 0)
			#G.Main.add_child(node)
			#node.global_position = projectile.global_position
