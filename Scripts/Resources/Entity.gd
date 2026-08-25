extends LoadableResource
class_name EntityResource

@export var path : StringName 


@export var HPMax : float = -1
@export var HP : float = -1

@export var SheildMax : float = -1
@export var Sheild : float = -1

@export var ManaMax : float = -1
@export var Mana : float = -1

@export var Crystals : int = -1
@export var ConstructionProgress : float = -1

@export var TargRange : int = -1

@export var location : Vector3
@export var rotation : Vector3

## # Create an entity with it's defaults as contained on that object
## [br]True: Loads the entity and leaves the attached container nodes alone
## [br]False: Loads the entity and overwites contaner nodes with values stores on this resource
@export var isNew : bool



func PreLoad() -> Array[LoadableResource]: 	self.resource_name = path; return []
func Resources() -> Array[StringName]: return [path]
func Load() -> Binder: 
	var et := load(path).instantiate() as Node3D
	
	if not isNew:
		if et.has_node("Destructible"):
			if HPMax > 0:
				et.get_node("Destructible").HP = HP
				et.get_node("Destructible").HPMax = HPMax
				
			if et.get_node("Destructible") is ShieldedDestructible and SheildMax > 0:
				et.get_node("Destructible").SheildMax = SheildMax
				et.get_node("Destructible").Sheild = Sheild
			
		if et.has_node("ManaStore") and ManaMax > 0:
			et.get_node("ManaStore").Mana = Mana
			et.get_node("ManaStore").ManaMax = ManaMax
			
		if et.has_node("CrystalStore") and Crystals > 0:
			et.get_node("CrystalStore").Crystals = Crystals
			
	if ConstructionProgress > 0:
		var cw := ConstructionWorker.new()
		cw.startHP = ConstructionProgress
		et.add_child( cw )
		
	et.global_position = location
	et.global_rotation = rotation
	
	return Binder.new(G.Main, et)

func Bound(et:Node) -> Node: 
	et.global_position = location
	et.global_rotation = rotation
	return null
