extends LoadableResource
class_name AsteroidResource

const resource := "res://Scenes/Friendlies/Asteroid.tscn"

func PreLoad() -> Array[LoadableResource]: self.resource_name = "Asteroid"; return []
func Resources() -> Array[StringName]: return [resource]

func Load() -> Binder:
	var loc = randf_range(0, TAU)
	var pos = Vector3(sin(loc), 0, cos(loc))
	var dist = randf_range(40, 400)
	
	var rock := load(resource).instantiate() as Asteroid3D
	
	var size : int = randi_range(
		G.remap(40, 400, 2, 15, dist) as int,
		G.remap(40, 400, 5, 20, dist) as int,
	)
	var base : int = randi_range(
		G.remap(2, 20, 1500,  80000, size) as int,
		G.remap(2, 20, 2000, 100000, size) as int,
	) # CrystalsMax, 1500, 100000
	
	rock.CrystalsMax = base + randf_range(0, 100) * size/10 as int
	#rock.Size = size
	
	rock.global_position = pos * dist
	
	print("+Rock of %d w/ %dc, %dm away" % [rock.Size, rock.CrystalsMax, dist])
	
	return Binder.new(G.Main, rock)
	
func Bound(rock:Node) -> Node: 
	return null

	
