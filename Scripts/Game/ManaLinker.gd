@icon("res://EditorIcons/manaLink.svg")
extends Node
#class_name ManaLinker

signal ManaChange(float)
signal LinkChange()

class ManaLink:
	var _a: ManaStore
	var _b: ManaStore
	var path: Node3D
	func _init(a: ManaStore, b: ManaStore, showPath:=true) -> void:
		self._a = a
		self._b = b
		
		if showPath:
			self.path = preload("res://Scenes/Towers/ManaPath.tscn").instantiate()
			G.Main.add_child(path)
			path.global_position = a.Parent.global_position
			path.scale.z = a.Parent.global_position.distance_to(b.Parent.global_position)
			path.look_at(b.Parent.global_position, Vector3(0,0,1))
	
	func check(store:ManaStore) -> bool:
		return _a == store or _b == store
		
	func clear():
		if path: path.queue_free()
		call_deferred('free')

enum RequestPurpose {Pull, Push}

class ManaRequest:
	var store: ManaStore
	var purpose: RequestPurpose
	var amount: float
	func _init(_store:ManaStore, _purpose:RequestPurpose, _amount:float):
		store = _store
		purpose = _purpose
		amount = _amount

var StarShip : TheStarShip 
var mana : ManaStore 

var Stores : Array[ManaStore]
var Pools : Array[Array]
var Links : Array[ManaLink]

var InRequests : Array[ManaRequest]
var OutRequests : Array[ManaRequest]

func SortDistance(a:ManaStore, b:ManaStore, center:Vector3) -> bool:
	var A : Node3D = a.Parent
	var B : Node3D = b.Parent
	return ( A.global_position.distance_squared_to(center) <
			 B.global_position.distance_squared_to(center) )


func setUp(starShip: TheStarShip):
	StarShip = starShip
	mana = StarShip.get_node("ManaStore")


func pullMana(charge: float, store:ManaStore) -> float:
	#push_warning( "Linker: legacy pullMana request! No effect.\n" + str(get_stack()) )
	
	# TODO temporary solver
	if StarShip.mana.PoolID != store.PoolID: return 0;
	
	charge = clampf(charge, 0, mana.Mana)
	mana.Mana -= charge
	return charge


func pushMana(amt: float, store:ManaStore):
	#push_warning( "Linker: legacy pushMana request! No effect.\n" + str(get_stack()) )
	
	if StarShip.mana.PoolID != store.PoolID: return 0;
	
	mana.Mana += amt
	mana.Mana = clampf(mana.Mana, 0, mana.ManaMax)

func RequestMana(store:ManaStore, purpose:RequestPurpose, amount:float):
	match purpose:
		RequestPurpose.Push:
			InRequests.append( ManaRequest )
		RequestPurpose.Pull:
			OutRequests.append( ManaRequest )
	
func RequestManaImport(store:ManaStore, amount:float):
	RequestMana(store, RequestPurpose.Pull, amount)
func RequestManaExport(store:ManaStore, amount:float):
	RequestMana(store, RequestPurpose.Push, amount)
	






func Count(store:ManaStore) -> int:
	var c := 0
	for l in Links:
		if l._a == store: c+=1;
		if l._b == store: c+=1;
	return c




func Register(store:ManaStore):
	Stores.append(store)
	LinkChange.emit()


func Destroy(store:ManaStore):
	for i in range(Stores.size() - 1, -1, -1):
		var item = Stores[i]
		if item == store:
			Stores.remove_at(i)
	
	for i in range(Links.size() - 1, -1, -1):
		var link = Links[i]
		if link._a == store or link._b == store:
			Links[i].clear()
			Links.remove_at(i)
	LinkChange.emit()



func Scan(pos, links, exclude:ManaStore=null) -> Array[ManaStore]:

	var stores = Stores.duplicate()
	stores.sort_custom(SortDistance.bind(pos))

	var out : Array[ManaStore] = []
	var visited : Dictionary[ManaStore, bool] = {}

	for store in stores:
		if store == exclude: continue
		var dist = store.Parent.global_position.distance_to(pos)
		if dist > 50: continue
		if Count(store) >= store.MaxLinks: continue
		
		if store is ManaProxy:
			if visited.has(store.manaStore): continue
			visited[store.manaStore] = true
		elif store is ManaStore:
			if visited.has(store): continue
			visited[store] = true
		else:
			push_error("Undefined!\n" + str(get_stack()))
		
		out.append(store)
		if len(out) >= links:
			break
	
	return out

func Connect(store:ManaStore, showPath:=true):
	var pos : Vector3 = store.Parent.global_position
	var links : int = store.MaxLinks
	var toLink := Scan(pos, links, store)

	for each in toLink:
		Links.append(
			ManaLink.new(store, each, showPath)
		)

func ConnectDirect(a:ManaStore, b:ManaStore, showPath:=true):
	Links.append( ManaLink.new(a, b, showPath) )
	LinkChange.emit()


func MapPools():
	Pools.clear()
	
	var adj : Dictionary[ManaStore, Array]
	
	for store in Stores:
		adj[store] = []
	for link in Links:
		if not adj.has(link._a): adj[link._a] = []
		if not adj.has(link._b): adj[link._b] = []
		adj[link._a].append(link._b)
		adj[link._b].append(link._a)
		
	print("Store Len: ", len(Stores), " Links Len: ", len(Links), " adj len: ", len(adj))
	
	var visited : Dictionary[ManaStore, bool] = {} 
	var c := 0
	
	for start in Stores:
		if visited.has(start): continue
		
		var pool : Array[ManaStore] = []
		var queue : Array[ManaStore] = [start]
		visited[start] = true
		
		while not queue.is_empty():
			var cur = queue.pop_front()
			pool.append(cur)
			
			for neighbor in adj[cur]:
				if not visited.has(neighbor):
					visited[neighbor] = true
					queue.append(neighbor)
					
		Pools.append(pool)
		c+=1;
	print("/!\\ Created %d Pools!" % c)
	
	for p in range(len(Pools)):
		#var id = Pools[p].reduce(func(a, s): return min(a, s.get_instance_id()), Pools[p][0].get_instance_id())
		for store in Pools[p]:
			#store.PoolID = id
			store.PoolID = p
		
	
	

	



var Building : ConstructableButton
var VisualLinks : Array[Node3D]
var wasBuilding: bool
var toConnect: StructureBase3D
var scanLinks : Array[ManaStore]


func _ready() -> void:
	LinkChange.connect(MapPools)
	self.process_physics_priority = 1000


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	if G.isBuilding:
		wasBuilding = true
		scanLinks = Linker.Scan(G.Cursor.global_position, Building.data['linksMax'])
		
		for x in range(len(scanLinks)):
			if len(VisualLinks) <= x:
				VisualLinks.append( preload("res://Scenes/Towers/ManaPath.tscn").instantiate() )
				G.Cursor.add_child( VisualLinks[x] )
				VisualLinks[x].global_position = G.Cursor.global_position
				
			VisualLinks[x].look_at(scanLinks[x].Parent.global_position, Vector3(0,0,1))
			VisualLinks[x].scale.z = G.Cursor.global_position.distance_to(scanLinks[x].Parent.global_position)
			
		while len(VisualLinks) > len(scanLinks):
			VisualLinks[ len(VisualLinks) - 1 ].queue_free()
			VisualLinks.remove_at( len(VisualLinks) - 1 )
			
	elif wasBuilding:
		wasBuilding = false
		for each in VisualLinks: each.queue_free()
		VisualLinks.clear()
		self.Connect(toConnect.mana)
		#call_deferred("MapPools")
		LinkChange.emit()
	
	var cost := 0.
	for rq in OutRequests:
		cost += rq.amount
	
