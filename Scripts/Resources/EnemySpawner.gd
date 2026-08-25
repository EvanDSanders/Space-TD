extends LoadableResource
class_name SpawnerResource

var timer : Timer 

var RNG = RandomNumberGenerator.new()

const scoutLoader := "res://Scenes/Enemies/Scout.tscn"
const frigateLoader := "res://Scenes/Enemies/Frigate.tscn"

const n := "EnemySpawner: "

func PreLoad() -> Array[LoadableResource]: self.resource_name = "Enemy Spawner"; return []

func Resources() -> Array[StringName]: return [
			scoutLoader,
			frigateLoader,
		]

func Load() -> Binder: 
	print(n, "Load() ")
	timer = Timer.new()
	return Binder.new(G.Main, timer)
	

func Bound(_none:Node) -> Node: 
	print(n, "Bound() ")
	timer.start(8)
	timer.timeout.connect(spawnDo)
	timer.timeout.connect(print.bind("EnemySpawner.Timer"))
	G.EnemySpawner = self
	return null

func spawn(ship, pos = null):
	print(n, "spawn() ", ship, " | ", pos)
	#return
	#var rot = RNG.randf_range(0, TAU)
	if not pos:
		var rot = Time.get_ticks_msec()/1000.
		pos = Vector3(sin(rot), 0, cos(rot)) * 500
	
	var e : Node3D = ship.instantiate()
	G.Enemies.add_child(e)
	e.global_position = pos
	
	#print(pos, "  ", e)
	


func spawnDo() -> void:
	if G.Main.gameOver: timer.queue_free(); return;
	print(n, "spawnDo() ")
	timer.wait_time -= randf_range(0.1, 0.3)
	timer.wait_time = clamp(timer.wait_time, 1, INF)
	
	var rot = RNG.randf_range(0, TAU)
	var pos = Vector3(sin(rot), 0, cos(rot)) * RNG.randi_range(400, 500)
	#for x in range( RNG.randi_range(30, 60) ):
	var amt := RNG.randi_range(1, 4)
	
	var ship : PackedScene
	var shipName : StringName
	
	var str : float = randf()
	if str < G.remap(8, 1, 0.4, 0.8, timer.wait_time):
		ship = load(scoutLoader)
		shipName = "Scout"
	else:
		ship = load(frigateLoader)
		shipName = "Frigate"
		
	
	G.Warnings.Create("%s :: %d" % [shipName, amt])
	for x in range( amt ):
		
		var posS = pos + Vector3(RNG.randf_range(-30,30),RNG.randf_range(-10,10),RNG.randf_range(-30,30)) * 1.4
		spawn(ship, posS)
