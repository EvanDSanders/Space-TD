extends LoadableResource
class_name GameLevelResource

enum LevelType { MINING, BATTLE, SCRIPTED, MINING_ALT }

@export var levelType : LevelType

@export var entities : Array[EntityResource]
@export var spawner : SpawnerResource
@export var asteroidSpawner : AsteroidGenResource

var isMain : bool
var level : String


func PreLoad() -> Array[LoadableResource]: 
	self.resource_name = "Game Level"
	isMain = levelType != LevelType.MINING_ALT
	G.isMainLevel = isMain
	print("IsMain ", isMain)
	var list : Array[LoadableResource] = []
	
	list.append_array(entities)
	if spawner: list.append(spawner)
	if asteroidSpawner: list.append(asteroidSpawner)
	
	return list
	
func Resources() -> Array[StringName]: 
	if isMain:
		level = "res://Scenes/Game/GameWorld.tscn"
	else:
		level = "res://Scenes/Game/GameWorldAlt.tscn"
	var r := [level]
	if isMain:
		r.append_array([
			"res://Scenes/Ship/TheStarShip.tscn",
			"res://Scenes/Ship/StarShip Cannon.tscn",
			"res://Scenes/Towers/LaserTurret.tscn",
		])
	return r;
	
func Load() -> Binder: 
		#PackedScene.new().instantiate()
	print("Level: ", level)
	var world = load(level).instantiate()
	G.get_tree().change_scene_to_node(world)
	G.Main = world
	G.Cursor = world.get_node("Cursor")
	if isMain:
		G.StarShip = world.get_node("Friendlies/The Star Ship")
	
	match levelType:
		LevelType.MINING:
			G.StarShip.ShipMode = TheStarShip.ShipModes.Build
		LevelType.BATTLE:
			G.StarShip.ShipMode = TheStarShip.ShipModes.Evasion
		LevelType.SCRIPTED:
			G.StarShip.ShipMode = TheStarShip.ShipModes.Warp
		LevelType.MINING_ALT:
			G.StarStation = world.get_node("Friendlies/Prospector")

	return null
	#return world

func Bound(_none:Node) -> Node: return null
