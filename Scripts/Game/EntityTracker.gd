extends Node

enum TargetType { Friend, Enemy, Collectible, Ores }

var Friend := TargetType.Friend
var Enemy := TargetType.Enemy
var Collectible := TargetType.Collectible
var Ore := TargetType.Ores

var pools: Dictionary = {
	  TargetType.Friend: [] as Array[Node3D],
	  TargetType.Enemy: [] as Array[Node3D],
	  TargetType.Collectible: [] as Array[Node3D],
	  TargetType.Ores: [] as Array[Node3D],
}
var TickID : int = 0

func _ready() -> void:
	self.process_physics_priority = -10000
	self.process_priority = -10000
	
func _physics_process(_delta: float) -> void:
	TickID = Engine.get_physics_frames() % 20
	
	for poolID in pools.keys():
		var pool = pools[poolID]
		for i in range(pool.size() - 1, -1, -1):
			var item = pool[i]
			if not is_instance_valid(item) or (not isAlive(item) if (poolID == TargetType.Friend or poolID == TargetType.Enemy) else false):
				pool.remove_at(i)
			
	
func GetList(targetType: TargetType) -> Array[Node3D]: return _pool(targetType)
func _pool(targetType: TargetType) -> Array[Node3D]:
	return pools[targetType]


func Register(node: Node3D, type: TargetType) -> void:
	_pool(type).append(node)

func UnRegister(node: Node3D, type: TargetType):
	_pool(type).erase(node)

func isAlive(obj: Node3D) -> bool:
	if obj.get_parent().name == "Collectibles": return true
	#if obj.get_parent().name == "Ores": return true
	if obj.has_node("Destructible"): return obj.get_child(0).isAlive
	return false # obj.isAlive


func getTargetWith( list: Array[Node3D], origin: Vector3, TRange: float = -1, extraEval: Callable = Callable() ):
	if TRange == 0: return
	var eval := extraEval if extraEval.is_valid() else Callable(self, "isAlive")
	var checkRange := TRange <= 0
	TRange = TRange**2
	var nearest: Node3D = null
	var min_dist := INF

	for obj in list:
		if not eval.call(obj): continue
		var d := origin.distance_squared_to(obj.global_position)
		if d < min_dist:
			min_dist = d
			nearest = obj

	return nearest if (checkRange or min_dist <= TRange) else null

func getTarget( targetType: TargetType, origin: Vector3, TRange: float = -1, extraEval: Callable = Callable() ) -> Node3D:
	if TRange == 0: return
	var eval : Callable = extraEval if extraEval.is_valid() else ( Callable(self, "isAlive") if (targetType == TargetType.Friend or targetType == TargetType.Enemy) else func(_d):return true )
	var checkRange := TRange <= 0
	TRange = TRange**2
	var nearest: Node3D = null
	var min_dist := INF

	for obj in _pool(targetType):
		if not eval.call(obj): continue
		var d := origin.distance_squared_to(obj.global_position)
		if d < min_dist:
			min_dist = d
			nearest = obj

	return nearest if (checkRange or min_dist <= TRange) else null
	
	

func splashDamage(targetType: TargetType, origin: Vector3, DistMin, DistMax, Damage):
	for each: Node3D in _pool(targetType):
		if each.health:
			var dist = origin.distance_to(each.global_position)
			var impulse = clamp( G.remap(DistMin, DistMax, Damage, 0, dist), 0, 10000 )
			if not is_zero_approx(impulse):
				each.health.Hit(impulse, origin.direction_to(each.global_position) * (impulse/40))
