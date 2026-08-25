extends StaticBody3D
class_name StructureBase3D

@onready var health: Destructible = find_child("Destructible")
@onready var mana: ManaStore = find_child("ManaStore")
@onready var crystal: CrystalStore = find_child("CrystalStore")
var constructor: ConstructionWorker

func destroy():
	G.spawnExplosionAndFree(G.ExplType.Magic, self)
