extends Node


var loadingScreen := preload("res://Scenes/GUI/LoadingScreen.tscn")
var Base : LoadingScreenBase
var Main : LoadingScreenMain

var loadingPaths : Array[StringName]
var loadingPathsTotal : Dictionary[StringName, float]
var loadingTasks : Array[LoadableResource]
var cacheKeeper  : Array[Resource]

var loaderSize : int = 0
var loaderAt   : int = 0

enum LoadingState {INIT, LOADING, BUILDING, IDLE}
var State : LoadingState = LoadingState.IDLE



func LoadDisk(_level:String):
	Load( load(_level) )

func Load(_level:GameLevelResource):
	loaded = _level
	#var level:LoadableResource = load(_level)
	var level:GameLevelResource = _level
	assert( is_instance_valid(level), "Failed to Load Level! (not valid)" )
	assert( level is GameLevelResource, "Failed to Load Level! (not GameLevelResource)" )
	
	State = LoadingState.INIT
	Base = loadingScreen.instantiate()
	$".".add_child(Base)
	
	cacheKeeper.clear()
	currentLoading = []
	
	G.setGameSpeed(1.0)
	
	Main = Base.Main
	
	Base.fullyDisplayed.connect(func(): 
		get_tree().paused = true
		get_tree().root.get_node("Main").queue_free()
		Pins.Clear()
		E.Clear()
		State = LoadingState.LOADING
		
		
		_load(level) 
		
		loaderSize = len(loadingTasks)
		
		print(loadingTasks)
		print(loadingPaths)
		
	)


func _load(loadable:LoadableResource):
	print("preloading ", typeof(loadable), " : ", loadable)
	loadingTasks.append(loadable)
	
	
	for each in loadable.PreLoad():
		_load(each)
	
	for each in loadable.Resources():
		if not loadingPaths.has(each):
			loadingPaths.append(each)
			loadingPathsTotal[each] = 0.
	

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Load("res://Resources/TitleScreen.tres")
	self.process_mode = Node.PROCESS_MODE_ALWAYS


#var loaded : StringName
var loaded : GameLevelResource

func Restart():  Load(loaded)
func MainMenu(): LoadDisk("res://Resources/TitleScreen.tres")



var currentLoading : Array[StringName] = []
var maxLoading : int = 2
var Binders : Array[LoadableResource.Binder]


func progress(val:float):
	Main.progress(val)
	
func task(string:String):
	Main.task(string)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	
	if len(currentLoading) < maxLoading and len(loadingPaths) > 0:
		var toLoad = loadingPaths.pop_front()
		currentLoading.append( toLoad )
		ResourceLoader.load_threaded_request(toLoad)
	
	if len(currentLoading) == 0 and len(loadingPaths) == 0 and State == LoadingState.LOADING:
		State = LoadingState.BUILDING
		loadingTasks.reverse()
		
	
	match State:
		LoadingState.LOADING:
			
			var prgs := []
			
			for each in currentLoading:
				var prg : Array[float]
				var state = ResourceLoader.load_threaded_get_status(each, prg)
				
				match state: 
					ResourceLoader.ThreadLoadStatus.THREAD_LOAD_IN_PROGRESS: 
						prgs.append("%s, %10.1f%%" % [each, prg[0]*100])
						loadingPathsTotal[each] = prg[0]
					ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED: 
						cacheKeeper.append(ResourceLoader.load_threaded_get(each))
						currentLoading.erase(each)
						loadingPathsTotal[each] = 1.
						
					ResourceLoader.ThreadLoadStatus.THREAD_LOAD_INVALID_RESOURCE: 
						prgs.append("%s, %s" % [each, "UNKNOWN"])
						
					ResourceLoader.ThreadLoadStatus.THREAD_LOAD_FAILED: 
						prgs.append("%s, %s" % [each, "FAILED"])
				
			task(
				"\n".join(prgs)
			)
			var P := 0.
			for p in loadingPathsTotal.values(): P+=p
			
			progress( G.remap(0, loadingPathsTotal.size(), 0, 0.5, P) )
			
		LoadingState.BUILDING:
			if not Engine.get_physics_frames() % 10 == 0:
				if len(loadingTasks) > 0 and len(Binders) == 0:
					
					var _task = loadingTasks.pop_back()
					task("Building: " + str(_task.resource_name))
					var binder : LoadableResource.Binder = _task.Load()
					if binder:
						Binders.append( binder )
						binder._caller = _task
					progress( G.remap(0, loaderSize, 0.5, 1.0, loaderAt) )
					loaderAt += 1;
				
				elif len(Binders) > 0:
					var _binder = Binders.pop_back()
					if _binder:
						var _node = _binder.Bind()
						_binder._caller.Bound(_binder._child)
						
				else: 
					task("Complete")
					progress(1.0)
					State = LoadingState.IDLE
					get_tree().paused = false
					G.setGameSpeed(1.0)
					
					
					loadingPathsTotal.clear()
					loadingPaths.clear()
					loadingTasks.clear()
					currentLoading.clear()
			
		LoadingState.IDLE: 
			if Input.is_action_just_pressed("R"):
				Restart()
		
	
	
	
	
	
	
	
	
pass
