extends GameLevelResource
class_name TitleScreenResource


const TScreen := "res://Scenes/Game/TitleScreen.tscn"

func PreLoad() -> Array[LoadableResource]:
	return []


func Resources() -> Array[StringName]:
	return [TScreen]



func Load() -> Binder:
	
	var ts = load(TScreen).instantiate()
	G.get_tree().change_scene_to_node(ts)

	return null

func Bound(_none:Node) -> Node: return null
