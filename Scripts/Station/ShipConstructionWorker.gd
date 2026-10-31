extends PanelContainer
class_name ShipConstructionWorker


@onready var Title: Label = $VBoxContainer/HBoxContainer/Label
@onready var RemoveFill: VBoxContainer = $Control/VBoxContainer2
@onready var blockRows: VBoxContainer = $Grid

var rowLen : int = 16
var colLen : int = 3
@onready var blockCount : int = rowLen * colLen

var data: Dictionary
var cost: int

var built := 0
var building := 0.0
var blocks : Array[Array] = []

static func create(data: Dictionary) -> ShipConstructionWorker:
	var wrkr = preload("res://Scenes/GUI/Station/ShipConstructionWorker.tscn").instantiate()
	wrkr.data = data
	wrkr.cost = data["cost"]
	G.StarStation.crystal.pullCrystal(wrkr.cost)
	
	return wrkr


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	slide = 0.
	Title.text = "Building %s" % data['name']
	for r in range(colLen):
		var row := HBoxContainer.new()
		row.grow_vertical = Control.GROW_DIRECTION_BOTH
		row.size_flags_vertical = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 0)
		blockRows.add_child(row)
		blocks.append( [] )
		
		for c in range(rowLen):
			var block = preload("res://Scenes/GUI/Station/ConstructionBlock.tscn").instantiate()
			row.add_child(block)
			blocks[r].append(block)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _physics_process(delta: float) -> void:
	if building < -0.5: return
	
	building += G.StarStation.energy.pullEnergy( delta * 4 )
	if building >= 1:
		building -= 1;
		built += 1;
		var block : Control = blocks[-1].pick_random()
		blocks[-1].erase( block )
		block.place()
		if blocks[-1].is_empty():
			blocks.pop_back()
			
	if blocks.is_empty():
		building = -1
		if Tw: Tw.kill()
		Tw = create_tween()
		Tw.tween_property(self, ^'position:x', 400, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK).set_delay(0.5)
		Tw.tween_callback(spawnShip)
		#velocity = Vector2(randf_range(-1000, -2000), randf_range(0, 200))
		#cancel()
		self.modulate = Color.from_hsv(0.333, 0.5, 1.0, 1.0)
	

func spawnShip():
	var ship : ShipBase = load(data['scene']).instantiate()
	G.Main.add_child(ship)
	ship.global_position = G.StarStation.hangerCenter.global_position
	var rnd = randf_range(0, TAU)
	ship.global_position  += Vector3( sin(rnd), 0, cos(rnd) ) * 50
	ship.linear_velocity   = Vector3( sin(rnd), 0, cos(rnd) ) * 50
	ship.global_rotation.y = rnd
	self.queue_free()

var Tw : Tween
var grabbed := false
var slide := 0.0: 
	set(s): 
		slide = clampf(s, -200, 0)
		self.position.x = slide
		var scl = clamp(-slide, 0.01, 10000)
		RemoveFill.size.x = scl
		RemoveFill.custom_maximum_size.x = scl
		RemoveFill.custom_minimum_size.x = scl
		RemoveFill.visible = scl > 1
		self.modulate = Color.from_hsv(0.0, 0.5, 1.0, 1.0) if -slide > 150 else Color.WHITE
		
func cancel():
	self.mouse_filter = Control.MOUSE_FILTER_IGNORE
	RemoveFill.queue_free()
	building = -1
	
	var phys := ShipConstructionWorkerRigidBody.fabricate()
	G.Main.add_child(phys)
	phys.linear_velocity = velocity
	phys.angular_velocity = ( 0.4 + 0.2 * velocity.length() ) * 0.01
	phys.setUp( self.global_position + self.size/2., self.size )
	# Only refund if not fully built. Added since reusing for finish
	if building > -0.5: phys.exited.connect(func(): G.StarStation.crystal.pushCrystal(self.cost))
	
	self.reparent(phys)

var velocity := Vector2.ZERO

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			grabbed = event.pressed
			print( self.name, "  ", event.button_index, " ", event.pressed )
			if not event.pressed: 
				if -slide > 150:
					cancel()
				else: 
					if Tw: Tw.kill()
					Tw = create_tween()
					Tw.tween_property(self, 'slide', 0, 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
			
	if event is InputEventMouseMotion:
		if grabbed:
			slide += event.relative.x
			velocity = event.velocity
			
