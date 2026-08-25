extends LoadableResource
class_name AsteroidGenResource


var list : Array[LoadableResource]

func PreLoad() -> Array[LoadableResource]:
	self.resource_name = "Asteroid Generator"

	for x in range(randi_range(10, 15)):
		list.append( AsteroidResource.new() )
		
	return list;

func Resources() -> Array[StringName]: return []
func Load() -> Binder: return null
func Bound(_none:Node) -> Node: return null
