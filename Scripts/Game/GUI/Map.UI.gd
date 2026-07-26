extends Panel

@onready var StarShip := $"../../../Friendlies/The Star Ship"
@onready var health: Destructible = StarShip.find_child("Destructible")
@onready var mana: ManaStore = StarShip.find_child("ManaStore")
@onready var crystal: CrystalStore = StarShip.find_child("CrystalStore")


@onready var StarShipIcon := $StarShip

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func drawPin(isKillable:bool, node:Node3D, radius:float, color:Color, filled = true, width = -1):
	if not node: return
	if isKillable:
		if not node.get('health'): return
		if not node.health.isAlive: return
	self.draw_circle(Vector2(
			G.remap(-3000/2, 3000/2, 0, 300, node.global_position.x),
			G.remap(-2000/2, 2000/2, 0, 200, node.global_position.z),
		), radius, color, filled, width)


func _draw() -> void:
	for each in E.GetList(E.Enemy):
		drawPin(true, each, 1, Color.RED)
	for each in E.GetList(E.Friend):
		if not is_instance_valid(each): continue
		if each == StarShip: continue
		if each is Prospector: 
			drawPin(true, each, 5, Color.GREEN_YELLOW)
			drawPin(true, each, 10, Color.GREEN_YELLOW, false, 2)
		else:
			drawPin(true, each, 1, Color.GREEN)
	for each in E.GetList(E.Ore):
		drawPin(false, each, 1, Color.MEDIUM_PURPLE)
	
	drawPin(false, G.camera, 1, Color.DODGER_BLUE)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	self.queue_redraw()
	StarShipIcon.position = Vector2(
				G.remap(-3000/2, 3000/2, 0, 300, StarShip.global_position.x),
				G.remap(-2000/2, 2000/2, 0, 200, StarShip.global_position.z),
			)
	StarShipIcon.rotation = -StarShip.global_rotation.y
	
	
	$Compass/CompassDial.offset_transform_rotation = StarShip.CameraHeading
	$Compass/CompassShip.offset_transform_rotation = StarShip.CameraHeading - StarShip.rotation.y
	
	#var array = []
	#
	#for each in mapCastMount.corners:
		#var caster : RayCast3D = each.caster
		#var pos := Vector3.ZERO
		#
		#if caster and caster.is_colliding():
			#pos = caster.get_collision_point()
			#
			#array.append(Vector2(
				#G.remap(-3000, 3000, 0, 300, pos.x),
				#G.remap(-2000, 2000, 0, 200, pos.z),
			#))
		#else: array.append(Vector2.ZERO)
		#
	#cameraProjected.polygon = array
