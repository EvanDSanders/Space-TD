extends Camera3D

@onready var StarShip: RigidBody3D = get_node("/root/Main/Friendlies/The Star Ship")




@onready var Evade:		Node3D = $"../CShipMount/CEvade"
@onready var Attack:	Node3D = $"../CShipMount/CAttack"
@onready var Move:		Node3D = $"../CShipMount/CMove"
@onready var Build:		Node3D = $"../CBuild"

@onready var Current : Node3D = Move

@onready var Tw = create_tween()

@onready var NodeStart : Node3D = Move.Post
@onready var NodeEnd   : Node3D = Move.Post

var TwT := 3.
var TwE := Tween.EASE_OUT
var TwR := Tween.TRANS_SINE

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	call_deferred( "reparent", $"../Camera Start" )
	call_deferred( "onChange" )
	call_deferred( "_ready2" )

func _ready2():
	TwT = 1.
	TwE = Tween.EASE_IN_OUT
	TwR = Tween.TRANS_EXPO

func doMove(fac: float):
	var startPos := NodeStart.global_position
	var endPos := NodeEnd.global_position
	
	var startRot := NodeStart.global_rotation
	var endRot := NodeEnd.global_rotation
	
	self.global_position = startPos*(1-fac) + endPos*fac
	self.global_rotation = startRot*(1-fac) + endRot*fac

func endMove():
	reparent(NodeEnd)

func setMove():
	reparent(NodeStart)
	
	Tw.kill()
	Tw = self.create_tween()
	
	Tw.tween_method(doMove, 0., 1., TwT).set_ease(TwE).set_trans(TwR)
	
	$Timer.start(TwT)
	$Timer.timeout.connect(endMove)

var EvadeStyle: StringName = "Attack"

func setEvadeStyle(style: StringName): 
	EvadeStyle = style

func onChange():
	NodeStart = self.get_parent_node_3d()
	match StarShip.ShipMode:
		StarShip.ShipModes.Build:
			Build.global_position = StarShip.global_position
			NodeEnd = Build.Post
			Current = Build
			setMove()
			
		StarShip.ShipModes.Maneuver:
			NodeEnd = Move.Post
			Current = Move
			setMove()
			
		StarShip.ShipModes.Warp:
			NodeEnd = Build.Post
			Current = Build
			setMove()
			
		StarShip.ShipModes.Evasion:
			match EvadeStyle:
				"Evade":
					NodeEnd = Evade.Post
					Current = Evade
					StarShip.faceWithCamera = false
				"Attack":
					NodeEnd = Attack.Post
					Current = Attack
					StarShip.faceWithCamera = true
			setMove()
			


enum NavMode { NONE, ORBIT, PAN }
var _nav_mode: NavMode

func _orbit(relative: Vector2) -> void:
	if StarShip.ShipMode == StarShip.ShipModes.Evasion and StarShip.faceWithCamera == false: return
	Current.doYaw(relative.x * -0.005)
	Current.doPitch(relative.y * -0.005)

func _pan(relative: Vector2) -> void:
	Current.doPan(relative)
	
func _dolly(factor: float) -> void:
	Current.doZoom(factor)
	


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_MIDDLE:
				if event.pressed:
					_nav_mode = NavMode.PAN if event.shift_pressed else NavMode.ORBIT
				else:
					_nav_mode = NavMode.NONE
				get_viewport().set_input_as_handled()
			MOUSE_BUTTON_WHEEL_UP:
				_dolly(-event.factor)
				get_viewport().set_input_as_handled()
			MOUSE_BUTTON_WHEEL_DOWN:
				_dolly(event.factor)
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _nav_mode != NavMode.NONE:
		match _nav_mode:
			NavMode.ORBIT:
				_orbit(event.relative)
			NavMode.PAN:
				_pan(event.relative)
		get_viewport().set_input_as_handled()





# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	StarShip.CameraHeading = Current.Yaw.rotation.y
	match StarShip.ShipMode:
		StarShip.ShipModes.Build, StarShip.ShipModes.Warp:
			Current.doPan(Vector2(Input.get_axis("Left", "Right"), Input.get_axis("Forward", "Backward")), true)
			
			
			pass
		StarShip.ShipModes.Maneuver:
			Move.global_position = StarShip.global_position
			
			
			
		StarShip.ShipModes.Evasion:
			Evade.global_position  = StarShip.global_position
			Attack.global_position = StarShip.global_position
			
			
