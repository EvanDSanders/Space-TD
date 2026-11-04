@icon("res://EditorIcons/starShip.svg")
extends RigidBody3D
class_name TheStarShip

# Visual speed stores (local to ship). Written by the active mode, read by the animator and UI.
var SpeedForward 	: float = 0.
var SpeedStrafe 	: float = 0.
var SpeedYaw		: float = 0.
var SpeedVert		: float = 0.

@export var faceWithCamera = false

enum ShipModes {
	Build,
	Warp,
	Fighter,
};

@export var ShipMode: ShipModes = ShipModes.Warp:
	set(v):
		if v == ShipMode and _modeActive: return
		ShipMode = v
		if is_node_ready(): _switchMode()

@export var EngineColors : Gradient
@export var TargetingRange: int = 160

@onready var Turrets := [
		$"Star Ship/TurretF",
		$"Star Ship/TurretL",
		$"Star Ship/TurretR"
]

@onready var health: ShieldedDestructible = find_child("Destructible")
@onready var mana: ManaStore = find_child("ManaStore")
@onready var crystal: CrystalStore = find_child("CrystalStore")

@onready var MegaShieldMount: Node3D = $"MegaShield Pivot/MegaShield Mount"
@onready var proxies: Node3D = $ManaProxies


# Modules
var animator: StarShipAnimator
var builder: StarShipBuilder
var fighter: StarShipFighter
var warp: StarShipWarp

var _modeActive := false
var _modePrior: ShipModes = ShipModes.Warp

var CameraHeading : float
var crystalFab := 0.0

# True while LClick held, but only when press wasn't first consumed by a Control (GUI).
var FiringInput: bool = false


var visibilityConfig : Dictionary = {
	ShipModes.Fighter: [
		func(): $"../../GUI Mount/Warnings".visible = false,
		func(): $"../../GUI Mount/SimSpeed Dock".visible = false,
		func(): $"../../GUI Mount/Map".visible = false,
		func(): $"../../GUI Mount/Constructables".visible = false,
		func(): $"../../GUI Mount/Defender".visible = true,
		func(): $"../../GUI Mount/AttackerL".visible = true,
		func(): $"../../GUI Mount/AttackerR".visible = true,
	],
}

func _unhandled_input(event: InputEvent) -> void:
	if G.isBuilding:
		FiringInput = false
		return
	if event.is_action_pressed("LClick"):
		FiringInput = true
		get_viewport().set_input_as_handled()
	elif event.is_action_released("LClick"):
		FiringInput = false


func _addModule(name: String, script: GDScript) -> Node:
	# Reuse a module already placed in the scene (keeps its exported values)
	var m: Node = null
	for c in get_children():
		if is_instance_of(c, script):
			m = c
			break
	if not m:
		m = script.new()
		m.name = name
		add_child(m)
	m.setup(self)
	return m


func _ready() -> void:
	# Move StarShip Turrets onto the ship's rotating body
	$"Star Ship/TurretF".reparent($"Star Ship/Brmature/Skeleton3D/Frame/TTR Front")
	$"Star Ship/TurretL".reparent($"Star Ship/Brmature/Skeleton3D/Engine_Frame_L/TTR Left")
	$"Star Ship/TurretR".reparent($"Star Ship/Brmature/Skeleton3D/Engine_Frame_R/TTR Right")
	$"Star Ship/Main Cannon".reparent($"Star Ship/Brmature")

	# Set turrets targeting origin and link their mana to the ship
	for T:TurretBase in Turrets:
		T.RangingOrigin = self
		T.scanArea3D = $ScanArea3D
		T.get_node("CursorDialogue").Parent = self

		T.set_meta("IsShip", true)
		T.mana.MaxLinks = 0
		Linker.ConnectDirect(T.mana, self.mana, false)

	gravity_scale = 0
	linear_damp = 0
	angular_damp = 0
	axis_lock_angular_x = true
	axis_lock_angular_z = true

	self.body_shape_entered.connect(self.collide)

	animator = _addModule("Animator", StarShipAnimator)
	builder = _addModule("Builder", StarShipBuilder)
	fighter = _addModule("Fighter", StarShipFighter)
	warp = _addModule("Warp", StarShipWarp)

	E.Register(self, E.Friend)

	_modePrior = ShipMode
	_switchMode()


func _switchMode() -> void:
	if _modeActive:
		_moduleFor(_modePrior).deactivate()
	_modePrior = ShipMode
	animator.transitionTo(ShipMode)
	_modeActive = true
	_moduleFor(ShipMode).activate()
	for each in visibilityConfig[ShipMode]:
		each.call()


func _moduleFor(mode: ShipModes) -> Node:
	match mode:
		ShipModes.Build: return builder
		ShipModes.Fighter: return fighter
		_: return warp


# Forwarded for Destructible / ShieldedDestructible which call Parent.writeShader
func writeShader(val, str: String):
	animator.writeShader(val, str)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Cheat"):
		crystal.pushCrystal(99999); print("DEBUG crystals added!!")
		var c = Pins.Register(self, Pins.Type.Text)
		c.text = "Cheating"
		c.textSize = 30
		c.setColor(Color.ORANGE_RED, Color.ORANGE)


func _physics_process(delta: float) -> void:
	if not health.isAlive: return

	crystalFab += delta * 1.25
	if crystalFab > 1:
		crystalFab -= 1
		crystal.pushCrystal(1)


func destroy():
	_moduleFor(ShipMode).deactivate()
	freeze = false
	axis_lock_linear_x = false
	axis_lock_linear_y = false
	axis_lock_linear_z = false
	axis_lock_angular_x = false
	axis_lock_angular_z = false
	linear_damp = 0
	angular_damp = 0
	var r = 20000
	apply_torque_impulse(Vector3(randf_range(-r,r), randf_range(-r,r), randf_range(-r,r)))

	G.Main.GameOver()
	animator.playDeath()


func collide(body_rid: RID, body: Node, body_shape_index: int, local_shape_index: int):
	if body.get_meta("IsShip", false): return
	var S1 : Vector3 = self.linear_velocity
	var S2 : Vector3 = body.linear_velocity if body.get("linear_velocity") else Vector3.ZERO
	var rate = S1.distance_to(S2)
	var dmg = G.remap(5, 20, 0, 1, rate)
	self.health.Hit(dmg/20)
	if body.has_node("Destructible"):
		body.get_node("Destructible").Hit(dmg*10)

	print(self.name, " at ", S1.length(),  " m/s hit ", body.name, " at ", S2.length(), " m/s")
