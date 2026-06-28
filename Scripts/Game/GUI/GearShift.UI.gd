extends PanelContainer


@onready var StarShip := $"../../Friendlies/The Star Ship"
@onready var Camera := $"../../Camera Rig Main/".find_child("Camera3D")
@onready var T := $Timer

var isMoving := false

var isLocked := false

@onready var startX = self.size.x

@onready var Tw = create_tween()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	T.one_shot = true
	T.wait_time = 1.0
	T.timeout.connect(onReady)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var speed
	if StarShip.ShipMode == StarShip.ShipModes.Evasion:
		speed = StarShip.Velocity.length()
	else:
		speed = ( abs(StarShip.SpeedForward) 
				+ abs(StarShip.SpeedStrafe) 
				+ abs(StarShip.SpeedVert) 
				+ abs(StarShip.SpeedYaw) )
				
	$"../../Label".text = str(speed)
	$"../../Label".text += "\n"
	
	if abs(speed) < 0.02:
		$"../../Label".text += "Stopped"
		if isMoving : # and T.is_stopped():
			isMoving = false
			onChange(false)
	else:
		$"../../Label".text += "Moving"
		if not isMoving : # and not T.is_stopped():
			isMoving = true
			onChange(true)
		
func loc(fac):
	self.position.x = G.remap(0, 1, 0, -startX, fac)

func onChange(isLocked: bool):
	startX = self.size.x
	if Tw:
		Tw.kill()
		Tw = create_tween()
	Tw.set_ease(Tw.EASE_IN_OUT)
	
	Tw.tween_method(loc, float(isLocked), float(not isLocked), .25)
		
	self.isLocked = isLocked
	for each : Button in $VBoxContainer.find_children("*", "Button"):
		each.disabled = isLocked


func onSet():
	T.start()
	Camera.onChange()
	onChange(true)
	
func onReady():
	onChange(false)


func _on_build_button_up() -> void:
	StarShip.ShipMode = StarShip.ShipModes.Build
	onSet()

func _on_maneuver_button_up() -> void:
	StarShip.ShipMode = StarShip.ShipModes.Maneuver
	onSet()

func _on_warp_button_up() -> void:
	StarShip.ShipMode = StarShip.ShipModes.Warp
	onSet()

func _on_evasion_button_up() -> void:
	StarShip.ShipMode = StarShip.ShipModes.Evasion
	Camera.setEvadeStyle("Evade")
	onSet()

func _on_attack_button_up() -> void:
	StarShip.ShipMode = StarShip.ShipModes.Evasion
	Camera.setEvadeStyle("Attack")
	onSet()
